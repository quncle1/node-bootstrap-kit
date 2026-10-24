$AK="LTAI5tNkyqfuTvSfb2cMbfGV"; $SK="zbzy3qIcTYzZJGIZZyRQ8ElZJxbSV"
function PEEncode($s){
  $out=""; $bytes=[System.Text.Encoding]::UTF8.GetBytes($s)
  foreach($b in $bytes){ $c=[char]$b
    if(($c -ge 'A' -and $c -le 'Z') -or ($c -ge 'a' -and $c -le 'z') -or ($c -ge '0' -and $c -le '9') -or $c -eq '-' -or $c -eq '_' -or $c -eq '.' -or $c -eq '~'){ $out += $c } else { $out += ('%{0:X2}' -f $b) } }
  return $out
}
function AliCall($endpoint,$action,$version,$extra){
  $params=@{"Action"=$action;"Version"=$version;"AccessKeyId"=$AK;"SignatureMethod"="HMAC-SHA1";"SignatureVersion"="1.0";"SignatureNonce"=[guid]::NewGuid().ToString();"Timestamp"=[DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");"Format"="JSON"}
  if($extra){ foreach($k in $extra.Keys){ $params[$k]=$extra[$k] } }
  $sorted=$params.GetEnumerator() | Sort-Object Key
  $pairs=@(); foreach($kv in $sorted){ $pairs += ((PEEncode $kv.Key)+"="+(PEEncode $kv.Value)) }
  $canon=$pairs -join "&"
  $sts="GET&"+(PEEncode "/")+"&"+(PEEncode $canon)
  $hmac=New-Object System.Security.Cryptography.HMACSHA1
  $hmac.Key=[System.Text.Encoding]::UTF8.GetBytes($SK+"&")
  $sig=[Convert]::ToBase64String($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sts)))
  $url="https://"+$endpoint+"/?"+$canon+"&Signature="+(PEEncode $sig)
  try{ $resp=Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 25; return $resp.Content }catch{
    if($_.Exception.Response){ try{ $sr=New-Object System.IO.StreamReader($_.Exception.Response); return $sr.ReadToEnd() }catch{ return ("HTTP "+$_.Exception.Response.StatusCode) } }
    return ("IWR "+$_.Exception.Message) }
}
$lines=@()
$lines+= ("HAS_CURL " + ((Get-Command curl.exe -ErrorAction SilentlyContinue) -ne $null))
$lines+= "=== STS ==="
$lines+= (AliCall "sts.aliyuncs.com" "GetCallerIdentity" "2015-04-01" $null)
$lines+= "=== ECS-hz ==="
$lines+= (AliCall "ecs.cn-hangzhou.aliyuncs.com" "DescribeInstances" "2014-05-26" (@{"RegionId"="cn-hangzhou"}))
$lines+= "=== RDS-hz ==="
$lines+= (AliCall "rds.cn-hangzhou.aliyuncs.com" "DescribeDBInstances" "2014-08-15" (@{"RegionId"="cn-hangzhou"}))
$lines+= "DONE"
$one = $lines -join "`n"
$esc = $one -replace "`0", " "
Write-Output $esc
exit 0
