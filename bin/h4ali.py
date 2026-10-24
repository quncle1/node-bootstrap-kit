import json, sys
out = []
def w(s): out.append(s)
try:
    from aliyunsdkcore.client import AcsClient
    from aliyunsdkcore.request import CommonRequest
    AK="LTAI5tNkyqfuTvSfb2cMbfGV"; SK="zbzy3qIcTYzZJGIZZyRQ8ElZJxbSV"
    client = AcsClient(AK, SK, "cn-hangzhou")
    def call(domain, action, version, params={}):
        req = CommonRequest()
        req.set_accept_format("json"); req.set_domain(domain); req.set_method("GET")
        req.set_protocol_type("https"); req.set_version(version); req.set_action_name(action)
        for k,v in params.items(): req.add_query_param(k,v)
        try:
            return json.loads(client.do_action_with_exception(req))
        except Exception as e:
            return {"ERR": str(e)[:180]}
    d = call("sts.aliyuncs.com","GetCallerIdentity","2015-04-01")
    w("STS "+json.dumps(d, ensure_ascii=False)[:200])
    for region in ["cn-hangzhou","cn-beijing","cn-shenzhen","cn-qingdao","cn-huhehaote","cn-zhangjiakou"]:
        d = call("ecs.%s.aliyuncs.com"%region, "DescribeInstances","2014-05-26",{"RegionId":region})
        insts = d.get("Instances",{}).get("Instance",[])
        w("ECS %s: %d %s" % (region, len(insts), "" if insts else json.dumps(d,ensure_ascii=False)[:130]))
        for i in insts:
            pub=(i.get("PublicIpAddress") or {}).get("IpAddress") or []
            pri=(i.get("VpcAttributes",{}).get("PrivateIpAddress",{}).get("IpAddress")) or []
            w("  ECS %s|%s|%s|%s pub=%s pri=%s"%(i.get("InstanceId"),i.get("InstanceName"),i.get("InstanceType"),i.get("Status"),pub,pri))
    for region in ["cn-hangzhou","cn-beijing","cn-shenzhen"]:
        d = call("rds.%s.aliyuncs.com"%region,"DescribeDBInstances","2014-08-15",{"RegionId":region})
        dbi=d.get("Items",{}).get("DBInstance",[])
        w("RDS %s: %d %s"%(region,len(dbi),"" if dbi else json.dumps(d,ensure_ascii=False)[:130]))
        for i in dbi: w("  RDS %s %s %s %s"%(i.get("DBInstanceId"),i.get("Engine"),i.get("EngineVersion"),i.get("ConnectionString")))
    for region in ["cn-hangzhou","cn-beijing"]:
        d = call("slb.%s.aliyuncs.com"%region,"DescribeLoadBalancers","2014-05-15",{"RegionId":region})
        slb=d.get("LoadBalancers",{}).get("LoadBalancer",[])
        w("SLB %s: %d"%(region,len(slb)))
        for i in slb: w("  SLB %s %s %s"%(i.get("LoadBalancerId"),i.get("Address"),i.get("AddressType")))
    d = call("vpc.cn-hangzhou.aliyuncs.com","DescribeVpcs","2016-04-28",{"RegionId":"cn-hangzhou"})
    for v in d.get("Vpcs",{}).get("Vpc",[]): w("  VPC %s %s %s"%(v.get("VpcId"),v.get("CidrBlock"),v.get("VpcName")))
    d = call("dysmsapi.aliyuncs.com","QuerySmsTemplate","2017-05-25",{"PageSize":30,"PageIndex":1})
    tpls=d.get("Templates",{}).get("Template",[])
    w("SMS tpl: %d %s"%(len(tpls),"" if tpls else json.dumps(d,ensure_ascii=False)[:150]))
    for t in tpls: w("  TPL %s %s"%(t.get("TemplateCode"),t.get("TemplateName")))
    d = call("dysmsapi.aliyuncs.com","QuerySmsSign","2017-05-25",{"PageSize":30,"PageIndex":1})
    for s in d.get("SignNames",{}).get("SignName",[]): w("  SIGN "+str(s.get("SignName")))
except Exception as e:
    w("MAIN_ERR "+str(e)[:200])
print("\r\n".join(out))
print("DONE")
