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
    
    # 移除可能存在的注释版本
    sed -i "s|^#${key}=.*||" "$file"
    
    # 处理值中的引号
    if [[ ! "$value" =~ ^\".*\"$ && ! "$value" =~ ^(true|false)$ && ("$value" =~ [[:space:]] || "$value" =~ [\&\|\$\;\"\'\`\:\/]) ]]; then
        value="\"$value\""
    fi
    
    # 检查属性是否存在（忽略注释行）
    if grep -q "^[^#]*${key}=" "$file"; then
        # 如果存在，更新值
        sed -i "s|^[^#]*${key}=.*|${key}=${value}|" "$file"
    else
        # 如果不存在，添加新的配置行
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
    update_or_add_property "leaf.jdbc.url" "${LEAF_JDBC_URL}" "/app/conf/leaf.properties"
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

# 启动应用
exec ${JAVA_CMD} ${JAVA_OPTS} ${JAVA_GC_OPTS} \
    -Dlogging.level.com.sankuai.leaf=INFO \
    -Dleaf.print.config=true \
    -jar /app/leaf.jar \
    --server.port=${SERVER_PORT} \
    --spring.config.location=classpath:/application.properties,classpath:/leaf.properties,file:/app/${CONFIG_DIR}leaf.properties \
    "$@"
