FROM openjdk:8-jdk-slim

WORKDIR /app

# 创建配置目录
RUN mkdir -p /app/conf

# 复制构建产物和配置文件
COPY leaf-server/target/leaf.jar /app/
COPY leaf-server/src/main/resources/leaf.properties /app/conf/leaf.properties
COPY docker/entrypoint.sh /app/

# 设置执行权限
RUN chmod +x /app/entrypoint.sh

# 设置默认端口
ENV SERVER_PORT=6348
EXPOSE ${SERVER_PORT}

ENTRYPOINT ["/app/entrypoint.sh"]
