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
    echo "With value: ${value}"

    # 移除可能存在的注释版本和空行
    sed -i -e "s|^#${key}=.*||" -e '/^[[:space:]]*$/d' "$file"

    echo "After removing comments:"
    grep -n "${key}" "$file" || echo "No ${key} entries found after comment removal"

    # 处理值中的引号
    if [[ ! "$value" =~ ^\".*\"$ && ! "$value" =~ ^(true|false)$ && ("$value" =~ [[:space:]] || "$value" =~ [\&\|\$\;\"\'\`\:\/]) ]]; then
        value="\"$value\""
    fi
    echo "Final value to be set: ${value}"

    # 检查属性是否存在（忽略注释行）
    if grep -q "^[[:space:]]*${key}=" "$file"; then
        # 如果存在，更新值
        echo "Property exists, updating..."
        sed -i "s|^[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
        # 如果不存在，添加新的配置行
        echo "Property doesn't exist, adding..."
        echo -e "\n${key}=${value}" >> "$file"
    fi

    echo "Current state of ${key}:"
    grep -n "${key}" "$file" || echo "No ${key} entries found in final state"
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