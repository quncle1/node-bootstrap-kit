$R="C:\Windows\TEMP\s34.txt"
function W($s){Add-Content -Path $R -Value $s}
del $R 2>$null
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
  for($t=0;$t -lt 4;$t++){
    try{ $resp=Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 20
      if($resp.Content -match "^\s*\{"){ return $resp.Content }
    }catch{
      if($_.Exception.Response){ try{ $sr=New-Object System.IO.StreamReader($_.Exception.Response); $c=$sr.ReadToEnd(); if($c -match "^\s*\{"){ return $c } }catch{} }
    }
    Start-Sleep -Seconds 1
  }
  return "IWRFAIL"
}
function J($r,$k){ try{ return ((($r|ConvertFrom-Json).$k)) }catch{ return $null } }
W "=== STS ==="
$r=AliCall "sts.aliyuncs.com" "GetCallerIdentity" "2015-04-01" $null
$arn=J $r "Arn"; $pn=J $r "PrincipalName"
if($arn){ W ("ARN="+$arn+" USER="+$pn) } else { W ("STS="+($r.Substring(0,[Math]::Min(250,$r.Length)))) }
W "=== ECS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai","cn-shenzhen")){
  $r=AliCall ("ecs."+ $rg + ".aliyuncs.com") "DescribeInstances" "2014-05-26" (@{"RegionId"=$rg})
  $j=$r|ConvertFrom-Json 2>$null
  if($j -and $j.Instances){ $n=$j.TotalCount; W ("ECS_"+$rg+" total="+$n)
    foreach($i in $j.Instances.Instance){ $ip=""; if($i.VpcAttributes -and $i.VpcAttributes.PrivateIpAddress){ $ip=($i.VpcAttributes.PrivateIpAddress.IpAddress -join ",") }; W ("  "+$i.InstanceId+" "+$i.InstanceName+" "+$i.InstanceType+" ip="+$ip) } }
  else { W ("ECS_"+$rg+" "+($r.Substring(0,[Math]::Min(220,$r.Length)))) }
}
W "=== RDS ==="
foreach($rg in @("cn-hangzhou","cn-beijing","cn-shanghai")){
  $r=AliCall ("rds."+ $rg + ".aliyuncs.com") "DescribeDBInstances" "2014-08-15" (@{"RegionId"=$rg;"PageNumber"="1";"PageSize"="30"})
  $j=$r|ConvertFrom-Json 2>$null
  if($j -and $j.Items){ W ("RDS_"+$rg+" total="+$j.TotalRecordCount)
    foreach($d in $j.Items.DBInstance){ W ("  "+$d.DBInstanceId+" "+$d.DBInstanceDescription+" "+$d.Engine+" "+$d.ConnectionString+" "+$d.DBInstanceStatus) } }
  else { W ("RDS_"+$rg+" "+($r.Substring(0,[Math]::Min(220,$r.Length)))) }
}
W "=== SMS ==="
$r=AliCall "dysmsapi.aliyuncs.com" "QuerySmsTemplate" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
$j=$r|ConvertFrom-Json 2>$null
if($j -and $j.Templates){ foreach($t in $j.Templates.Template){ W ("T "+$t.TemplateId+" "+$t.TemplateName) } } else { W ("SMSTPL "+($r.Substring(0,[Math]::Min(200,$r.Length)))) }
$r=AliCall "dysmsapi.aliyuncs.com" "QuerySmsSign" "2017-05-25" (@{"PageSize"="30";"PageIndex"="1"})
$j=$r|ConvertFrom-Json 2>$null
if($j -and $j.SignNames){ foreach($s in $j.SignNames.SignName){ W ("SIGN "+($s -join "")) } } else { W ("SIGNS "+($r.Substring(0,[Math]::Min(200,$r.Length)))) }
W "DONE"
exit 0
