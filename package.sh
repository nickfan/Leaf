#!/bin/bash
set -e

# 检查并载入.env文件
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "No .env file found, copying from .env.example..."
        cp .env.example .env
    fi
fi

# 如果.env文件存在，则载入环境变量
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    set -a
    source .env
    set +a
fi

# 配置文件路径
RESOURCES_DIR="leaf-server/src/main/resources"
LEAF_PROPERTIES="${RESOURCES_DIR}/leaf.properties"

# 配置文件处理函数
update_or_add_property() {
    local key=$1
    local value=$2
    local file=$3
    
    echo "Updating property: ${key}"
    
    # 移除可能存在的注释版本
    sed -i "s|^#${key}=.*||" "$file"
    
    # 移除空行
    sed -i '/^[[:space:]]*$/d' "$file"
    
    # JDBC URL 和 ZooKeeper 地址特殊处理：确保不添加额外的引号
    if [[ "$key" == "leaf.jdbc.url" ]] || [[ "$key" == "leaf.snowflake.zk.address" ]]; then
        value=$(echo "$value" | sed 's/^"//;s/"$//')  # 移除首尾的引号
    else
        # 其他属性的常规处理
        if [[ ! "$value" =~ ^\".*\"$ ]]; then
            if [[ ! "$value" =~ ^(true|false)$ ]]; then
                value=$(echo "$value" | sed 's/[\/&]/\\&/g')
                if [[ "$value" =~ [[:space:]] || "$value" =~ [\&\|\$\;\"\'\`\:\/\\] ]]; then
                    value="\"$value\""
                fi
            fi
        fi
    fi
    
    echo "Final value to be set: ${value}"
    
    # 检查属性是否已存在
    if grep -q "^[[:space:]]*${key}=" "$file"; then
        # 使用 awk 进行更精确的替换
        awk -v k="$key" -v v="$value" '
        $0 ~ "^[[:space:]]*"k"=" { print k"="v; next }
        { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    else
        # 如果属性不存在，则添加到文件末尾
        echo "${key}=${value}" >> "$file"
    fi
}

## 备份原始配置文件
#if [ -f "${LEAF_PROPERTIES}" ]; then
#    echo "Backing up original leaf.properties..."
#    cp "${LEAF_PROPERTIES}" "${LEAF_PROPERTIES}.bak"
#fi

echo "Updating leaf.properties with environment variables..."

# 使用环境变量更新配置文件
if [ -n "$LEAF_NAME" ]; then
    update_or_add_property "leaf.name" "${LEAF_NAME}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_SEGMENT_ENABLE" ]; then
    update_or_add_property "leaf.segment.enable" "${LEAF_SEGMENT_ENABLE}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_SNOWFLAKE_ENABLE" ]; then
    update_or_add_property "leaf.snowflake.enable" "${LEAF_SNOWFLAKE_ENABLE}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_JDBC_URL" ]; then
    update_or_add_property "leaf.jdbc.url" "${LEAF_JDBC_URL}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_JDBC_USERNAME" ]; then
    update_or_add_property "leaf.jdbc.username" "${LEAF_JDBC_USERNAME}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_JDBC_PASSWORD" ]; then
    update_or_add_property "leaf.jdbc.password" "${LEAF_JDBC_PASSWORD}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_SNOWFLAKE_ZK_ADDRESS" ]; then
    update_or_add_property "leaf.snowflake.zk.address" "${LEAF_SNOWFLAKE_ZK_ADDRESS}" "${LEAF_PROPERTIES}"
fi

if [ -n "$LEAF_SNOWFLAKE_PORT" ]; then
    update_or_add_property "leaf.snowflake.port" "${LEAF_SNOWFLAKE_PORT}" "${LEAF_PROPERTIES}"
fi

echo "Building project..."
mvn clean package -DskipTests

## 构建完成后恢复原始配置文件
#if [ -f "${LEAF_PROPERTIES}.bak" ]; then
#    echo "Restoring original leaf.properties..."
#    mv "${LEAF_PROPERTIES}.bak" "${LEAF_PROPERTIES}"
#fi

echo "Build completed successfully!" 