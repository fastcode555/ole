#!/bin/bash

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 检查 node 是否安装
if ! command -v node &> /dev/null; then
  osascript -e 'display alert "启动失败" message "未找到 Node.js，请先安装：https://nodejs.org"'
  exit 1
fi

# 检查依赖是否安装
if [ ! -d "node_modules" ]; then
  echo "首次运行，安装依赖..."
  npm install
fi

# 检查端口是否已占用，如果是则先杀掉
PORT=3000
PID=$(lsof -ti tcp:$PORT)
if [ -n "$PID" ]; then
  echo "端口 $PORT 已被占用，正在关闭旧进程..."
  kill -9 $PID
  sleep 1
fi

echo "启动影视服务..."
node server.js &
SERVER_PID=$!

# 等待服务启动
sleep 2

# 自动打开浏览器
open "http://localhost:$PORT"

echo "服务已启动，访问 http://localhost:$PORT"
echo "关闭此窗口将停止服务"

# 等待服务进程
wait $SERVER_PID
