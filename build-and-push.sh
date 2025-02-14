#!/bin/bash

# 设置版本号（可以通过参数传入）
VERSION=${1:-latest}

# 构建镜像
echo "Building image version: $VERSION"
IMAGE_TAG=$VERSION docker-compose build

# 推送镜像
echo "Pushing image version: $VERSION"
docker push nickfan/leaf-server:$VERSION

# 如果不是latest版本，同时更新latest标签
if [ "$VERSION" != "latest" ]; then
    echo "Tagging and pushing as latest"
    docker tag nickfan/leaf-server:$VERSION nickfan/leaf-server:latest
    docker push nickfan/leaf-server:latest
fi

echo "Build and push completed successfully" 