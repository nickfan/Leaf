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
