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
    
    # 移除可能存在的注释版本和空行
    sed -i -e "s|^#${key}=.*||" -e '/^[[:space:]]*$/d' "$file"
    
    # 处理值中的特殊字符
    # 1. 如果值已经被引号包围，保持原样
    # 2. 如果是布尔值，保持原样
    # 3. 如果包含特殊字符或空格，添加引号并转义特殊字符
    if [[ ! "$value" =~ ^\".*\"$ ]]; then
        if [[ ! "$value" =~ ^(true|false)$ ]]; then
            # 转义值中的特殊字符
            value=$(echo "$value" | sed 's/[\/&]/\\&/g')
            # 如果包含特殊字符或空格，添加引号
            if [[ "$value" =~ [[:space:]] || "$value" =~ [\&\|\$\;\"\'\`\:\/\\] ]]; then
                value="\"$value\""
            fi
        fi
    fi
    
    echo "Final value to be set: ${value}"
    
    # 使用精确的模式匹配来更新或添加属性
    if grep -q "^[[:space:]]*${key}=" "$file"; then
        # 使用 | 作为分隔符来避免 URL 中的 / 符号造成问题
        sed -i "s|^[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
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