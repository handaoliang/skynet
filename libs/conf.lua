--[[
 * SkyNet System Config Script
 * Author: handaoliang <handaoliang@gmail.com>
 * LastModified: 2015-05-15
]]

local _Conf = {

    -- 版本信息
    --
    _VERSION = "1.0.1",

    -- 加密Public Key
    --
    EncryptPublicKey = "3e16b4759d11631a75545f8016cb9994",

    -- 同一个IP Post数据的时间间隔，单位：秒
    --
    PostDataInterval = 5,

    -- 过滤规则匹配路径
    FilterRulePath = "/data//skynet/rules",

    -- 是否开启攻击日志，如果为开启，则需要设置路径
    AttackLog = "on",

    -- 攻击日志路径
    AttackLogDir = "/data/nginx_hack_logs",

    -- SkyNet System 日志路径
    SkynetSystemLogDir = "/data/skynet_system_logs",

    -- 拒绝URL攻击
    DenyURLAttack = "on",

    -- 拒绝Cookies攻击
    DenyCookiesAttack = "on",

    -- 是否检查URL白名单
    CheckWhiteURL = "on",

    -- 拒绝CC攻击
    DenyCCAttack = "on",

    -- CC攻击的频率设置，默认60秒内100次。
    CCAttackRate = "2/60",

    -- 是否启用智能分析
    IntelligentAnalysis = "off",
}

-- IP白名单，如果设置了，则白名单IP地址的请求不进行任何过滤。
-- Example: _Conf.IPWhitelist = {"127.0.0.1", "192.168.0.1"}
--
_Conf.IPWhitelist = {}

-- IP黑名单，如果设置了，则黑名单IP地址的请求直接被重置为403。
-- Example: _Conf.IPBlocklist = {"127.0.0.1", "192.168.0.1"}
--
_Conf.IPBlocklist = {}

-- Redis 配置
--
_Conf.RedisConf = {
    -- 被Block掉的IP储存表
    IPBlockDBHost = "127.0.0.1",
    IPBlockDBPort = "6379",

    -- IP的操作记录表。
    IPRecordsDBHost = "127.0.0.1",
    IPRecordsDBPort = "6380",

    -- IP队列表。
    IPQueueDBHost = "127.0.0.1",
    IPQueueDBPort = "6381",
}

return _Conf
