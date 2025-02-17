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
    export $(cat .env | grep -v '^#' | xargs)
fi

# 默认端口
SERVER_PORT=${SERVER_PORT:-6348}

# PID文件路径
PID_FILE="logs/leaf.pid"
mkdir -p logs

# 查找进程ID的函数
find_pid() {
    # 首先尝试从PID文件获取
    if [ -f "${PID_FILE}" ]; then
        local pid=$(cat "${PID_FILE}")
        if ps -p "${pid}" > /dev/null 2>&1; then
            echo "${pid}"
            return 0
        fi
    fi
    
    # 如果PID文件不存在或无效，则通过端口查找
    local pid=$(lsof -t -i:"${SERVER_PORT}" 2>/dev/null)
    if [ -n "${pid}" ]; then
        echo "${pid}"
        return 0
    fi
    
    # 如果都找不到，返回空
    echo ""
    return 1
}

# 停止进程的函数
stop_process() {
    local pid=$1
    local timeout=${2:-60} # 默认超时时间60秒
    
    echo "Stopping Leaf server (PID: ${pid})..."
    kill "${pid}" 2>/dev/null || true
    
    # 等待进程结束
    local counter=0
    while kill -0 "${pid}" 2>/dev/null; do
        if [ ${counter} -ge ${timeout} ]; then
            echo "Timeout waiting for process to end, forcing shutdown..."
            kill -9 "${pid}" 2>/dev/null || true
            break
        fi
        echo "Waiting for process to end..."
        sleep 1
        counter=$((counter + 1))
    done
    
    # 清理PID文件
    rm -f "${PID_FILE}"
}

# 主逻辑
pid=$(find_pid)

if [ -z "${pid}" ]; then
    echo "No Leaf server process found on port ${SERVER_PORT}"
    exit 0
fi

echo "Found Leaf server process: ${pid}"
stop_process "${pid}"
echo "Leaf server stopped successfully" 