#!/bin/bash
cd "$(dirname "$0")"

echo "停止影视服务..."

# 通过 launchctl 停止
launchctl unload ~/Library/LaunchAgents/com.mysite.videoserver.plist 2>/dev/null

# 强制杀掉占用 3000 端口的进程
PID=$(lsof -ti tcp:3000)
if [ -n "$PID" ]; then
  kill -9 $PID
  echo "已停止进程 $PID"
else
  echo "服务未在运行"
fi

echo "完成"
