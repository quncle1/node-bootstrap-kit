$R="C:\Windows\TEMP\s30.txt"
function W($s){Add-Content -Path $R -Value $s}
del $R 2>$null
$AK="LTAI5tNkyqfuTvSfb2cMbfGV"; $SK="zbzy3qIcTYzZJGIZZyRQ8ElZJxbSV"
function PEEncode($s){
  $out=""
  $bytes=[System.Text.Encoding]::UTF8.GetBytes($s)
  foreach($b in $bytes){
    $c=[char]$b
    if(($c -ge 'A' -and $c -le 'Z') -or ($c -ge 'a' -and $c -le 'z') -or ($c -ge '0' -and $c -le '9') -or $c -eq '-' -or $c -eq '_' -or $c -eq '.' -or $c -eq '~'){ $out += $c } else { $out += ('%{0:X2}' -f $b) }
  }
  return $out
}
function AliUrl($endpoint,$action,$version,$extra){
  $params=@{"Action"=$action;"Version"=$version;"AccessKeyId"=$AK;"SignatureMethod"="HMAC-SHA1";"SignatureVersion"="1.0";"SignatureNonce"=[guid]::NewGuid().ToString();"Timestamp"=[DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");"Format"="JSON"}
  if($extra){ foreach($k in $extra.Keys){ $params[$k]=$extra[$k] } }
  $sorted=$params.GetEnumerator() | Sort-Object Key
  $pairs=@(); foreach($kv in $sorted){ $pairs += ((PEEncode $kv.Key)+"="+(PEEncode $kv.Value)) }
  $canon=$pairs -join "&"
  $sts="GET&"+(PEEncode "/")+"&"+(PEEncode $canon)
  $hmac=New-Object System.Security.Cryptography.HMACSHA1
  $hmac.Key=[System.Text.Encoding]::UTF8.GetBytes($SK+"&")
  $sig=[Convert]::ToBase64String($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sts)))
  return "https://"+$endpoint+"/?"+$canon+"&Signature="+(PEEncode $sig)
}
function AliGet($url){
  try{ $o=& curl.exe -s --max-time 30 $url; if($LASTEXITCODE -eq 0){ return $o } else { return "CURLERR_$LASTEXITCODE $o" } }catch{ return "CURL_EX $($_.Exception.Message)" }
}
W "=== STS ==="
$u=AliUrl "sts.aliyuncs.com" "GetCallerIdentity" "2015-04-01" $null
W (AliGet $u)
W "=== ECS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai","cn-shenzhen")){
  $u=AliUrl ("ecs."+ $rg + ".aliyuncs.com") "DescribeInstances" "2014-05-26" (@{"RegionId"=$rg})
  $r=AliGet $u
  W ("ECS_"+$rg+" "+$r.Substring(0,[Math]::Min(3000,$r.Length)))
}
W "=== RDS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai")){
  $u=AliUrl ("rds."+ $rg + ".aliyuncs.com") "DescribeDBInstances" "2014-08-15" (@{"RegionId"=$rg;"PageNumber"="1";"PageSize"="30"})
  $r=AliGet $u
  W ("RDS_"+$rg+" "+$r.Substring(0,[Math]::Min(2500,$r.Length)))
}
W "=== SMS ==="
$u=AliUrl "dysmsapi.aliyuncs.com" "QuerySmsTemplate" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
W ("SMS_TPL "+(AliGet $u).Substring(0,2000))
$u=AliUrl "dysmsapi.aliyuncs.com" "QuerySmsSign" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
W ("SMS_SIGN "+(AliGet $u).Substring(0,1500))
W "DONE"
exit 0
