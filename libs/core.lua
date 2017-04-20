--[[
 * SkyNet System Core Script
 * Author: handaoliang <handaoliang@gmail.com>
 * LastModified: 2015-05-15
]]

local _Func = require "func"
local _Conf = require "conf"

local _Core = {
    _VERSION = _Conf._VERSION,
}

-- IP白名单判断
--
function _Core.WhiteIPAddress(IPAddrWhiteList, ClientIPAddress)
    if next(IPAddrWhiteList) ~= nil then
        for _, ip in pairs(IPAddrWhiteList) do
            if ClientIPAddress == ip then
                return true
            end
        end
    end
    return false
end

-- URL白名单判断
--
function _Core.WhiteURL(WhiteURIList, ClientRequestURI)
    if _Func.CheckOption(_Conf.CheckWhiteURL) then
        if WhiteURIList ~= nil and next(WhiteURIList) ~= nil then
            for _, rule in pairs(WhiteURIList) do
                if _Func.RegMatch(ClientRequestURI, rule, "isjo") then
                    return true
                 end
            end
        end
    end
    return false
end

-- IP黑名单操作
--
function _Core.BlockIPAddress(IPAddrBlockList, ClientIPAddress)
    if next(IPAddrBlockList) ~= nil then
        for _,ip in pairs(IPAddrBlockList) do
            if ClientIPAddress == ip then
                _Core.DenyVisit()
            end
        end
    end
end

-- 检查UserAgent是否合法
--
function _Core.CheckUserAgent(UARules)
    local UserAgent = ngx.var.http_user_agent
    if UserAgent ~= nil then
        for _, rule in pairs(UARules) do
            if rule ~= "" and _Func.RegMatch(UserAgent, rule, "isjo") then
                _Func.AttackLog('UA', ngx.var.request_uri, "-", rule)
                _Core.DenyVisit()
            end
        end
    end
end

-- 检查请求的URL是否合法
--
function _Core.CheckURL(URLRules)
    if _Func.CheckOption(_Conf.DenyURLAttack) then
        for _, rule in pairs(URLRules) do
            if rule ~="" and _Func.RegMatch(ngx.var.request_uri, rule, "isjo") then
                _Func.AttackLog('GET', ngx.var.request_uri, "-", rule)
                _Core.DenyVisit()
            end
        end
    end
end

-- 拒绝恶意CC攻击。
--
function _Core.CheckCCAttack(ClientIPAddress, ClientRequestURI)
    if _Func.CheckOption(_Conf.DenyCCAttack) then
        CCAttackLimitNumber = tonumber(string.match(_Conf.CCAttackRate, '(.*)/'))
        CCAttackLimitSeconds = tonumber(string.match(_Conf.CCAttackRate,'/(.*)'))
        local CCToken = ngx.md5(ClientIPAddress..ClientRequestURI)
        local CCLogSaveDict = ngx.shared.cc_attack_dict
        local req,_ = CCLogSaveDict:get(CCToken)
        if req then
            if req > CCAttackLimitNumber then
                _Func.AttackLog('GET', ClientRequestURI, "-", "-")
                _Core.DenyVisit()
            else
                 CCLogSaveDict:incr(CCToken, 1)
            end
        else
            CCLogSaveDict:set(CCToken, 1, CCAttackLimitSeconds)
        end
    end
end

-- 拒绝访问并输出相关信息
--
function _Core.DenyVisit()
    ngx.header["X-Powered-By"] = 'SkyNet/'.._Conf._VERSION
    ngx.exit(403)
end

--
return _Core
