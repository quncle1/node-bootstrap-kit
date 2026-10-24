$R="C:\Windows\TEMP\s31.txt"
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
function AliEnum($endpoint,$action,$version,$extra){
  $params=@{"Action"=$action;"Version"=$version;"AccessKeyId"=$AK;"SignatureMethod"="HMAC-SHA1";"SignatureVersion"="1.0";"SignatureNonce"=[guid]::NewGuid().ToString();"Timestamp"=[DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");"Format"="JSON"}
  if($extra){ foreach($k in $extra.Keys){ $params[$k]=$extra[$k] } }
  $sorted=$params.GetEnumerator() | Sort-Object Key
  $pairs=@(); foreach($kv in $sorted){ $pairs += ((PEEncode $kv.Key)+"="+(PEEncode $kv.Value)) }
  $canon=$pairs -join "&"
  $sts="GET&"+(PEEncode "/")+"&"+(PEEncode $canon)
  $hmac=New-Object System.Security.Cryptography.HMACSHA1
  $hmac.Key=[System.Text.Encoding]::UTF8.GetBytes($SK+"&")
  $sig=[Convert]::ToBase64String($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sts)))
  $args2=@("-s","-G","--max-time","30","https://"+$endpoint+"/")
  foreach($kv in $sorted){ $args2 += ("--data-urlencode" + "=" + $kv.Key + "=" + $kv.Value) }
  $args2 += ("--data-urlencode" + "=" + "Signature=" + $sig)
  $o=& curl.exe @args2
  if($LASTEXITCODE -eq 0){ return $o } else { return "CERR" }
}
W "=== STS ==="
$r=AliEnum "sts.aliyuncs.com" "GetCallerIdentity" "2015-04-01" $null
try{ $j=$r|ConvertFrom-Json; if($j.Arn){ W ("ARN "+$j.Arn+" USER "+$j.PrincipalName) } else { W ("CODE "+$j.Code+" "+$j.Message) } }catch{ W ("RAW "+$r.Substring(0,[Math]::Min(300,$r.Length))) }
W "=== ECS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai","cn-shenzhen")){
  $r=AliEnum ("ecs."+ $rg + ".aliyuncs.com") "DescribeInstances" "2014-05-26" (@{"RegionId"=$rg})
  try{ $j=$r|ConvertFrom-Json; $n=$j.TotalCount; W ("ECS_"+$rg+" total="+$n); if($j.Instances){ foreach($i in $j.Instances.Instance){ W ("  "+$i.InstanceId+" "+$i.InstanceName+" "+$i.InstanceType+" "+$i.Status+" ip="+((($i.VpcAttributes|ForEach-Object{$_.PrivateIpAddress|ForEach-Object{$_.IpAddress}})|Join-String ",") )) } } }catch{ W ("ECS_"+$rg+" "+$r.Substring(0,[Math]::Min(200,$r.Length))) }
}
W "=== RDS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai")){
  $r=AliEnum ("rds."+ $rg + ".aliyuncs.com") "DescribeDBInstances" "2014-08-15" (@{"RegionId"=$rg;"PageNumber"="1";"PageSize"="30"})
  try{ $j=$r|ConvertFrom-Json; $n=$j.TotalRecordCount; W ("RDS_"+$rg+" total="+$n); if($j.Items){ foreach($i in $j.Items.DBInstance){ W ("  "+$i.DBInstanceId+" "+$i.DBInstanceDescription+" "+$i.Engine+" "+$i.ConnectionString+" "+$i.DBInstanceStatus) } } }catch{ W ("RDS_"+$rg+" "+$r.Substring(0,[Math]::Min(200,$r.Length))) }
}
W "=== SMS ==="
$r=AliEnum "dysmsapi.aliyuncs.com" "QuerySmsTemplate" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
try{ $j=$r|ConvertFrom-Json; if($j.Templates){ foreach($t in $j.Templates.Template){ W ("T "+$t.TemplateId+" "+$t.TemplateName+" "+$t.TemplateType) } } else { W ("SMSTPL "+$j.Code) } }catch{ W ("SMSTPL "+$r.Substring(0,[Math]::Min(150,$r.Length))) }
$r=AliEnum "dysmsapi.aliyuncs.com" "QuerySmsSign" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
try{ $j=$r|ConvertFrom-Json; if($j.SignNames){ foreach($s in $j.SignNames.SignName){ W ("SIGN "+$s) } } else { W ("SIGNS "+$j.Code) } }catch{ W ("SIGNS "+$r.Substring(0,[Math]::Min(150,$r.Length))) }
W "DONE"
exit 0
