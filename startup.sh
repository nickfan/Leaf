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

# 默认配置
DEFAULT_JAVA_OPTS="-server -Xms2g -Xmx2g -Xmn1g -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
DEFAULT_JAVA_GC_OPTS="-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled -XX:+CMSScavengeBeforeRemark -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:logs/gc.log"

# 使用环境变量中的参数，如果没有则使用默认值
JAVA_OPTS=${JAVA_OPTS:-"${DEFAULT_JAVA_OPTS}"}
JAVA_GC_OPTS=${JAVA_GC_OPTS:-"${DEFAULT_JAVA_GC_OPTS}"}
SERVER_PORT=${SERVER_PORT:-6348}
JAVA_CMD=${JAVA_CMD:-"java"}
CONFIG_DIR=${CONFIG_DIR:-"conf/"}

# 程序目标
PROJ_DIR="."
PROJ_TARGET_JAR="${PROJ_DIR}/leaf-server/target/leaf.jar"

# 配置文件处理函数
update_or_add_property() {
    local key=$1
    local value=$2
    local file=$3
    
    # 移除可能存在的注释版本
    sed -i "s|^#${key}=.*||" "$file"
    
    # 检查属性是否存在
    if grep -q "^${key}=" "$file"; then
        # 如果存在，更新值
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        # 如果不存在，添加新的配置行
        echo "${key}=${value}" >> "$file"
    fi
}

# 创建必要的目录
mkdir -p logs
mkdir -p ${CONFIG_DIR}

# 检查JAR文件是否存在
if [ ! -f "${PROJ_TARGET_JAR}" ]; then
    echo "Error: ${PROJ_TARGET_JAR} not found!"
    echo "Please build the project first using: mvn clean package -DskipTests"
    exit 1
fi

# 使用环境变量更新配置文件
if [ -f "${CONFIG_DIR}leaf.properties" ]; then
    if [ -n "$LEAF_NAME" ]; then
        update_or_add_property "leaf.name" "${LEAF_NAME}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_SEGMENT_ENABLE" ]; then
        update_or_add_property "leaf.segment.enable" "${LEAF_SEGMENT_ENABLE}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_SNOWFLAKE_ENABLE" ]; then
        update_or_add_property "leaf.snowflake.enable" "${LEAF_SNOWFLAKE_ENABLE}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_JDBC_URL" ]; then
        update_or_add_property "leaf.jdbc.url" "${LEAF_JDBC_URL}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_JDBC_USERNAME" ]; then
        update_or_add_property "leaf.jdbc.username" "${LEAF_JDBC_USERNAME}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_JDBC_PASSWORD" ]; then
        update_or_add_property "leaf.jdbc.password" "${LEAF_JDBC_PASSWORD}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_SNOWFLAKE_ZK_ADDRESS" ]; then
        update_or_add_property "leaf.snowflake.zk.address" "${LEAF_SNOWFLAKE_ZK_ADDRESS}" "${CONFIG_DIR}leaf.properties"
    fi

    if [ -n "$LEAF_SNOWFLAKE_PORT" ]; then
        update_or_add_property "leaf.snowflake.port" "${LEAF_SNOWFLAKE_PORT}" "${CONFIG_DIR}leaf.properties"
    fi
fi

echo "Leaf Start--------------"
echo "JAVA_OPTS:  ${JAVA_OPTS}"
echo "JAVA_GC_OPTS: ${JAVA_GC_OPTS}"
echo "CONFIG_DIR: ${CONFIG_DIR}"
echo "JAR: ${PROJ_TARGET_JAR}"
echo "------------------------"

# 启动应用
echo $$ > logs/leaf.pid
exec ${JAVA_CMD} ${JAVA_OPTS} ${JAVA_GC_OPTS} \
    -Dlogging.level.com.sankuai.leaf=INFO \
    -Dleaf.print.config=true \
    -jar ${PROJ_TARGET_JAR} \
    --server.port=${SERVER_PORT} \
    --spring.config.location=classpath:/application.properties,classpath:/leaf.properties,file:./${CONFIG_DIR}leaf.properties \
    "$@" 