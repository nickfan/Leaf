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

# 如果没有配置文件，从示例配置创建
if [ ! -f "/app/conf/leaf.properties" ]; then
    echo "No leaf.properties found, copying from example..."
    cp /app/conf/leaf.example.properties /app/conf/leaf.properties
    
    # 使用环境变量更新配置文件
    if [ -n "$LEAF_NAME" ]; then
        sed -i "s/^leaf\.name=.*/leaf.name=${LEAF_NAME}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_SEGMENT_ENABLE" ]; then
        sed -i "s/^leaf\.segment\.enable=.*/leaf.segment.enable=${LEAF_SEGMENT_ENABLE}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_SNOWFLAKE_ENABLE" ]; then
        sed -i "s/^leaf\.snowflake\.enable=.*/leaf.snowflake.enable=${LEAF_SNOWFLAKE_ENABLE}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_JDBC_URL" ]; then
        sed -i "s|^leaf\.jdbc\.url=.*|leaf.jdbc.url=${LEAF_JDBC_URL}|" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_JDBC_USERNAME" ]; then
        sed -i "s/^leaf\.jdbc\.username=.*/leaf.jdbc.username=${LEAF_JDBC_USERNAME}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_JDBC_PASSWORD" ]; then
        sed -i "s/^leaf\.jdbc\.password=.*/leaf.jdbc.password=${LEAF_JDBC_PASSWORD}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_SNOWFLAKE_ZK_ADDRESS" ]; then
        sed -i "s/^leaf\.snowflake\.zk\.address=.*/leaf.snowflake.zk.address=${LEAF_SNOWFLAKE_ZK_ADDRESS}/" /app/conf/leaf.properties
    fi
    if [ -n "$LEAF_SNOWFLAKE_PORT" ]; then
        sed -i "s/^leaf\.snowflake\.port=.*/leaf.snowflake.port=${LEAF_SNOWFLAKE_PORT}/" /app/conf/leaf.properties
    fi
fi

# 启动应用
exec ${JAVA_CMD} ${JAVA_OPTS} ${JAVA_GC_OPTS} \
    -jar /app/leaf.jar \
    --server.port=${SERVER_PORT} \
    --spring.config.additional-location=${CONFIG_DIR} \
    "$@"
