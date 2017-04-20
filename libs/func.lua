--[[
 * SkyNet System Common Function Script
 * Author: handaoliang <handaoliang@gmail.com>
 * LastModified: 2015-05-15
]]

local _Conf = require "conf"

local _Func = {
    _VERSION = _Conf._VERSION,
    RegMatch = ngx.re.find,
}

-- 解析字符串到一个Table里
-- 
function _Func.Split(str, delimiter)
    assert(type(delimiter) == "string" and string.len(delimiter) > 0, "Error: Bad delimiter.")

    local start = 1
    local result = {}

    while true do
        local pos = string.find(str, delimiter, start, true)
        if not pos then
            break
        end
        table.insert(result, string.sub(str, start, pos-1))
        start = pos + string.len(delimiter)
    end

    table.insert(result, string.sub(str, start))
    return result
end

-- 分隔时间为秒数
--
function _Func.GetTimeByDate(r)
    local str = _Func.Split(r, " ")
    local ymd = _Func.Split(str[1], "-")
    local his = _Func.Split(str[2], ":")
    local rel = os.time({year=ymd[1],month=ymd[2],day=ymd[3], hour=his[1], min=his[2], sec=his[3]})
    return rel
end

-- 判断一个Table里是否包含某元素
-- 
function _Func.IsInTable(item, list)
    if (not item or not list) then
        return false   
    end 
    if list then
        for k, v in pairs(list) do
            if v == item then
                return true
            end
        end
    end
    return false
end 

-- Redis方法，将通过zrange 或者 zrangebyscore 取出来的数据转化成Table，必须是带withscores的数据
--
function _Func.ConvertZrangeDataToTable(list)
    local result = {}
    for k, v in pairs(list) do
        result[list[k+1]] = list[k]
        table.remove(list, k+1)
    end
    return result
end

-- 将通过hget取出来的数据转化成Table
--
function _Func.ConvertHashDataToTable(list)
    local result = {}
    for k, v in pairs(list) do
        result[list[k]] = list[k+1]
        table.remove(list, k)
    end
    return result
end

-- 取得客户端IP
--
function _Func.GetClientIpAddress()
    IP = ngx.req.get_headers()["X-Real-IP"]
    if IP == nil then
        IP  = ngx.var.remote_addr 
    end
    if IP == nil then
        IP  = "unknown"
    end
    return IP
end

-- 检查选项是否打开。
--
function _Func.CheckOption(options)
    return options == "on" and true or false
end

-- 写文件
--
function _Func.WriteFile(FileName, Message)
    local FileHandler = io.open(FileName,"ab")
    if FileHandler == nil then return end
    FileHandler:write(Message)
    FileHandler:flush()
    FileHandler:close()
end

-- 记录系统日志
--
function _Func.SystemLog(LogType, LogMessage)
    local time = ngx.localtime()
    LogLine = time.." ["..LogType.."] \""..LogMessage.."\"\n"
    local FileName = _Conf.SkynetSystemLogDir.."/skynet_system_"..ngx.today()..".log"
    _Func.WriteFile(FileName, LogLine)
end


-- 记录攻击日志
--
function _Func.AttackLog(Method, URL, Data, RuleTag)
    if _Func.CheckOption(_Conf.AttackLog) then
        local RealIPAddress = _Func.GetClientIpAddress()
        local UserAgent = ngx.var.http_user_agent
        local ServerName = ngx.var.server_name
        local time = ngx.localtime()
        local LogLine = ""

        if UserAgent then
            LogLine = RealIPAddress.." ["..time.."] \""..Method.." "..ServerName..URL.."\" \""..Data.."\"  \""..UserAgent.."\" \""..RuleTag.."\"\n"
        else
            LogLine = RealIPAddress.." ["..time.."] \""..Method.." "..ServerName..URL.."\" \""..Data.."\" - \""..RuleTag.."\"\n"
        end
        local FileName = _Conf.AttackLogDir..'/'..ServerName.."_"..ngx.today().."_sec.log"
        _Func.WriteFile(FileName, LogLine)
    end
end

-- 读取匹配规则
--
function _Func.ReadRules(RulesPath, RulesFileName)
    file = io.open(RulesPath..'/'..RulesFileName, "r")
    if file==nil then
        return
    end
    t = {}
    for line in file:lines() do
        table.insert(t,line)
    end
    file:close()
    return(t)
end

-- Debug 函数
function _Func.DEBUG(DebugInfo)
    ngx.header["X-Powered-By"] = 'SkyNet/'.._Conf._VERSION
    ngx.print(DebugInfo)
    ngx.exit(200)
end

--
return _Func
