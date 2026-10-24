$R="C:\Windows\TEMP\s32.txt"
function W($s){Add-Content -Path $R -Value $s}
del $R 2>$null
W "PS " + $PSVersionTable.PSVersion.ToString()
$cx = Get-Command curl.exe -ErrorAction SilentlyContinue
if($cx){ W ("CURL " + $cx.Source) } else { W "CURL_MISSING" }
# 最简测试: curl -G --data-urlencode 基本行为
try{
  $o = & curl.exe -s -G --max-time 20 "https://httpbin.org/get" "--data-urlencode"="foo=bar baz" "--data-urlencode"="x=y~z"
  W ("T1 " + (($o -join " ").Substring(0,[Math]::Min(300,$o.Length))))
}catch{ W ("T1_EX " + $_.Exception.Message) }
# 直接 GET 一个 aliyun 端点看连通性
try{
  $o = & curl.exe -s --max-time 20 "https://sts.aliyuncs.com/"
  W ("T2 " + (($o -join " ").Substring(0,[Math]::Min(200,$o.Length))))
}catch{ W ("T2_EX " + $_.Exception.Message) }
W "DONE"
exit 0
