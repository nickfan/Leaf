#!/bin/bash
set -e

# 默认JVM参数
DEFAULT_JAVA_OPTS="-server -Xms2g -Xmx2g -Xmn1g -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
DEFAULT_JAVA_GC_OPTS="-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled -XX:+CMSScavengeBeforeRemark -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:/app/logs/gc.log"

# 使用环境变量中的参数，如果没有则使用默认值
JAVA_OPTS=${JAVA_OPTS:-"${DEFAULT_JAVA_OPTS}"}
JAVA_GC_OPTS=${JAVA_GC_OPTS:-"${DEFAULT_JAVA_GC_OPTS}"}
SERVER_PORT=${SERVER_PORT:-6348}
JAVA_CMD=${JAVA_CMD:-"java"}
CONFIG_DIR=${CONFIG_DIR:-"conf/"}

# 创建日志目录
mkdir -p /app/logs

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

## 如果没有配置文件，从示例配置创建
if [ ! -f "/app/conf/leaf.properties" ]; then
    echo "No leaf.properties found, copying from example..."
    cp /app/conf/leaf.example.properties /app/conf/leaf.properties
fi

# 使用环境变量更新配置文件
if [ -n "$LEAF_NAME" ]; then
    update_or_add_property "leaf.name" "${LEAF_NAME}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_SEGMENT_ENABLE" ]; then
    update_or_add_property "leaf.segment.enable" "${LEAF_SEGMENT_ENABLE}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_SNOWFLAKE_ENABLE" ]; then
    update_or_add_property "leaf.snowflake.enable" "${LEAF_SNOWFLAKE_ENABLE}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_JDBC_URL" ]; then
    echo "Updating leaf.jdbc.url with value: ${LEAF_JDBC_URL}"
    echo "Before update:"
    grep -n "leaf.jdbc.url" "/app/conf/leaf.properties" || echo "No existing leaf.jdbc.url entry found"
    update_or_add_property "leaf.jdbc.url" "${LEAF_JDBC_URL}" "/app/conf/leaf.properties"
    echo "After update:"
    grep -n "leaf.jdbc.url" "/app/conf/leaf.properties" || echo "Still no leaf.jdbc.url entry found"
fi

if [ -n "$LEAF_JDBC_USERNAME" ]; then
    update_or_add_property "leaf.jdbc.username" "${LEAF_JDBC_USERNAME}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_JDBC_PASSWORD" ]; then
    update_or_add_property "leaf.jdbc.password" "${LEAF_JDBC_PASSWORD}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_SNOWFLAKE_ZK_ADDRESS" ]; then
    update_or_add_property "leaf.snowflake.zk.address" "${LEAF_SNOWFLAKE_ZK_ADDRESS}" "/app/conf/leaf.properties"
fi

if [ -n "$LEAF_SNOWFLAKE_PORT" ]; then
    update_or_add_property "leaf.snowflake.port" "${LEAF_SNOWFLAKE_PORT}" "/app/conf/leaf.properties"
fi

# 输出配置文件
echo "Using leaf.properties:"
echo "File contents with line numbers:"
cat -n /app/conf/leaf.properties
echo "Grep for jdbc url:"
grep -n "leaf.jdbc.url" "/app/conf/leaf.properties" || echo "No leaf.jdbc.url entry found in final check"

# 启动应用
exec ${JAVA_CMD} ${JAVA_OPTS} ${JAVA_GC_OPTS} \
    -Dlogging.level.com.sankuai.leaf=INFO \
    -Dleaf.print.config=true \
    -jar /app/leaf.jar \
    --server.port=${SERVER_PORT} \
    --spring.config.location=classpath:/application.properties,classpath:/leaf.properties,file:/app/${CONFIG_DIR}leaf.properties \
    "$@"
