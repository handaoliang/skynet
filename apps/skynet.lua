--[[
 * Lua SkyNet System initialize Script
 * Author: handaoliang <handaoliang@gmail.com>
 * LastModified: 2015-05-15
]]


local Conf = require "conf"
local Func = require "func"
local Core = require "core"

local method = ngx.req.get_method()

-- 先取得客户端的IP地址
local ClientIPAddress = Func.GetClientIpAddress()

-- 如果是白名单的IP，则忽略后面的检查。
if Core.WhiteIPAddress(Conf.IPWhitelist, ClientIPAddress) then
    return
end

-- 如果是系统黑名单的IP，则直接返回403。
Core.BlockIPAddress(Conf.IPBlocklist, ClientIPAddress)

-- 当前时间
local CurrentTimestamp = os.time()

-- 读取URL白名单规则
local WhiteURIRule = Func.ReadRules(Conf.FilterRulePath, "WhiteURL")
-- 判断请求是否在URL白名单里面，如果在，则忽略后面的检查。
if Core.WhiteURL(WhiteURIRule, ngx.var.uri) then
    return
end

-- 读取相关的Rules
local UserAgentRule = Func.ReadRules(Conf.FilterRulePath, "UserAgent")
local URLRule = Func.ReadRules(Conf.FilterRulePath, "URL")

-- 针对相关的Filter Rules 进行过滤
Core.CheckUserAgent(UserAgentRule)
Core.CheckURL(URLRule)

-- 防止CC攻击。
Core.CheckCCAttack(ClientIPAddress, ngx.var.request_uri)

-- 检查是否启用智能分析。
if not Func.CheckOption(Conf.CheckWhiteURL) then
    return
end

-- Initialize Redis Module
local Redis = require "resty.redis"
local cjson = require "cjson"

-- 取得被Block掉的IP的数据
local IPBlockRedisObj = Redis:new()
local ok, err = IPBlockRedisObj:connect(Conf.RedisConf.IPBlockDBHost, Conf.RedisConf.IPBlockDBPort)
-- 如果连接Redis错误，则需要记录LOG及报警，直接返回。
if not ok then
    local LogMessage = "System Error:[Can not connect IP block redis: "..Conf.RedisConf.IPBlockDBHost..":"..Conf.RedisConf.IPBlockDBPort.."]"
    Func.SystemLog("Error", LogMessage)
    -- @todo: Need send a message to system administrator phone
    return
end

-- Redis Key
local IPBlockKey = 'ip:'..ClientIPAddress
-- 取得该IP的过期时间
local ExpirationTime, err = IPBlockRedisObj:hget(IPBlockKey, 'expiration_time')

-- 如果该IP处于Block期，则直接就不让它访问任何页面，也不关心他的行为。
if ExpirationTime ~= ngx.null and ExpirationTime > CurrentTimestamp then
    Core.DenyVisit()
end

IPBlockRedisObj:close()

-- 如果是POST请求，首先要判断这个当前IP是否频繁发送数据，如果是，则要按照规则进行BLOCK
if method == "POST" then
    local IPRecordsKey = 'ip:'..ClientIPAddress

    local IPRecordRedisObj = Redis:new()
    local ok, err = IPRecordRedisObj:connect(Conf.RedisConf.IPRecordsDBHost, Conf.RedisConf.IPRecordsDBPort)

    if not ok then
        local LogMessage = "System Error:[Can not connect IP block redis: "..Conf.RedisConf.IPRecordsDBHost..":"..Conf.RedisConf.IPRecordsDBPort.."]"
        Func.SystemLog("Error", LogMessage)
        -- @todo: Need send a message to system administrator phone
        return
    end

    local OperationTime, err = IPRecordRedisObj:hget(IPRecordsKey, 'update_time')

    -- 如果当前IP没有记录，则记录一下。
    if OperationTime == ngx.null then
        IPRecordRedisObj:hmset(IPRecordsKey, 'post_number', 1, 'update_time', CurrentTimestamp)
    else
        IPRecordRedisObj:hincrby(IPRecordsKey, 'post_number', 1)
        -- 更新最后操作时间
        IPRecordRedisObj:hset(IPRecordsKey, 'update_time', CurrentTimestamp)
    end

    -- 关闭数据库连接。
    IPRecordRedisObj:close()

    -- 将当前IP的请求扔到队列里面去供后台智能分析。

    local IPQueueRedisObj = Redis:new()
    local ok, err = IPQueueRedisObj:connect(Conf.RedisConf.IPQueueDBHost, Conf.RedisConf.IPQueueDBPort)

    if not ok then
        local LogMessage = "System Error:[Can not connect IP Queue redis: "..Conf.RedisConf.IPQueueDBHost..":"..Conf.RedisConf.IPQueueDBPort.."]"
        Func.SystemLog("Error", LogMessage)
        -- @todo: Need send a message to system administrator phone
        return
    end

    IPQueueRedisObj:lpush("ip.queue.main", cjson.encode({actions="spam_analyze", ip=ClientIPAddress}))
    IPQueueRedisObj:close()

    -- 判断最后操作时间与当前时间的时间差，如果超过了配置设定的时间，则返回403
    if OperationTime ~= ngx.null then
        local _t = CurrentTimestamp-OperationTime
        if _t < Conf.PostDataInterval then
            Core.DenyVisit()
        end
    end

    -- 将当前IP的操作放入到一个队列，交由后台程序去异步分析是否要对当前IP进行长时间封禁

end
