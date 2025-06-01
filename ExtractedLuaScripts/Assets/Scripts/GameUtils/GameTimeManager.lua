

GameTimeManager = {
    m_timeOffset = 0,
    _serverTimeZone = 0,
    m_fallbackShowDeviceTime = GameDeviceManager:IsEditor()
}
local GameTimeManager = GameTimeManager
local UnityTime = CS.UnityEngine.Time

local socket = require "socket"
local TimeHelper = CS.Common.Utils.TimeHelper
local SERVER_TIME_URL = {
    -- {url = "https://api.m.jd.com/client.action?functionId=queryMaterialProducts&client=wh5", GetTime = function(content) return content.currentTime2 end },
    {url = "http://api.m.taobao.com/rest/api3.do?api=mtop.common.getTimestamp",              GetTime = function(content) return content.data.t end },
    {url = "http://47.98.100.208:8080/get_timestamp",                                        GetTime = function(content) return content end }, -- 国内
}

local SECONDS_PER_DAY = 86400

if GameConfig:IsWarriorVersion() then
    table.insert(SERVER_TIME_URL, 1, {url = "https://guigu1.loveballs.club/gameapi/v1/getTimeStamp?appId=officebuilding_warrior_ioshw",  GetTime = function(content)
        if content and tonumber(content.data) then
            return content.data
        end
        return 0
    end })
elseif GameConfig:IsLeyoHKVersion() then
    table.insert(SERVER_TIME_URL, 1, {url = "http://hw.3yoqu.com/get_timestamp", GetTime = function(content) return content end })
end


local offset = 0    ---从游戏启动到登录返回结果的时间
local loginTime = 0
local GMOffset = 0

function GameTimeManager:Init(login)
    loginTime = tonumber(login)
    offset = UnityTime.realtimeSinceStartup
    local now = self:GetNetWorkTimeSync()
    print("LoginTime: ", now, loginTime)
end

---2024-11-27 15:09:58 新增获取当前时间的方法, 用这个方法替代当前游戏中所有的获取时间方法
function GameTimeManager:GetCurLocalTime(isSecond, cb)
    local time
    if GameDeviceManager:IsPCDevice() then
        if isSecond then
            time = self:GetDeviceTime() + GMOffset
            if cb then cb(time) end 
            return time
        else
            time = self:GetDeviceTimeInMilliSec() + GMOffset * 1000
            if cb then cb(time) end
            return time
        end
    end
    loginTime = loginTime == 0 and self:GetDeviceTime() or loginTime
    if isSecond then
        time = math.floor((loginTime + UnityTime.realtimeSinceStartup - offset + GMOffset))
        if cb then cb(time) end
        return time
    else
        time = math.floor((loginTime + UnityTime.realtimeSinceStartup - offset + GMOffset) * 1000)
        if cb then cb(time) end
        return time
    end
end

function GameTimeManager:GMChangeTime(minute)
    GMOffset = GMOffset + minute * 60
end

function GameTimeManager:GetNetWorkTimeSync(isSecond, isSync, i) -- 默认单位毫毛
    --return self:GetNetWorkTime(nil, isSecond, true, i)
    
    ---new
    return self:GetCurLocalTime(isSecond)
end

function GameTimeManager:GetNetWorkTime(cb, isSecond, isSync, i) -- 默认单位毫毛
    ----注釋掉，只要麽有網連不上時間服務器游戲就會卡住
    --if self.m_useLocalSystemTime then
    --    if isSync then
    --        return isSecond and self:GetCurrentServerTime() or self:GetCurrentServerTimeInMilliSec()
    --    else
    --        cb(isSecond and self:GetCurrentServerTime() or self:GetCurrentServerTimeInMilliSec())
    --    end
    --    return
    --end
    --
    ---- local index = i or 1
    --local index = i or 1
    --local urlInfo = SERVER_TIME_URL[index]
    --if not urlInfo then
    --    GameTableDefine.ChooseUI:CommonChoose("TXT_TIP_INTERNET_ISSUE")
    --    if isSync then
    --        return 0
    --    else
    --        if cb then cb(0) end
    --        return
    --    end
    --end
    --local requestTable = {
	--	callback = function(response)
    --        local time = nil
    --        pcall(function() time = tonumber(urlInfo.GetTime(response)) end)
    --        if time and time > 1639624011867 then -- 1639624011867 是时间点 +8UTC 2021-12-16 11:06:51
    --            if math.abs(math.ceil(time / 1000) - GameTimeManager:GetCurrentServerTime()) < 60 * 5 then
    --                self.m_useLocalSystemTime = true
    --                -- self.m_useLocalSystemTime = nil
    --            end
    --            self.m_theoryTime = {
    --                osTime = socket.gettime(),
    --                netTime = time * 0.001,
    --                netMilliTime = time
    --            }
    --            if isSecond then 
    --                time = math.ceil(time / 1000) 
    --            end
    --            if isSync then 
    --                return time
    --            else
    --                if cb then cb(time) end
    --            end
    --        else
    --            return self:GetNetWorkTime(cb, isSecond, isSync, index + 1)
    --        end
	--	end,
    --    errorCallback = function(response)
    --        return self:GetNetWorkTime(cb, isSecond, isSync, index + 1)
    --    end,
	--}
    --return GameNetwork:HTTP_PublicSendRequest(urlInfo.url, requestTable, isSync, "GET", nil, nil, 3)
    
    ---new
    return self:GetCurLocalTime(isSecond, cb)
end

function GameTimeManager:VerifySystemTimeModification()
    local lastOfflineTime = LocalDataManager:GetDataByKey("last_game_time") or {}
    lastOfflineTime = tonumber(lastOfflineTime.time) or 0
    if self:GetCurrentServerTime() < lastOfflineTime or math.abs(self:GetCurrentServerTime() - lastOfflineTime) > 60 * 5 then
        self.m_useLocalSystemTime = nil
    end
end

-- the return value is in seconds since 1970
function GameTimeManager:GetCurrentServerTime(uesNetTime)
    --if uesNetTime then
    --    return self:GetNetWorkTimeSync(true)
    --end
    --return self:GetDeviceTime() 

    ---new
    return self:GetCurLocalTime(true)
end


function GameTimeManager:GetCurrentServerTimeInMilliSec()
    --return self:GetDeviceTimeInMilliSec()

    ---new
    return self:GetCurLocalTime()
end

--- return (s)
function GameTimeManager:GetDeviceTime()
    return os.time()
end

--- return (ms)
function GameTimeManager:GetDeviceTimeInMilliSec()
    return math.floor(socket.gettime() * 1000)
end

function GameTimeManager:GetSocketTime()
    --return socket.gettime()

    ---new
    return self:GetCurLocalTime(true)
end

function GameTimeManager:GetFloatSocketTime()
    return socket.gettime()
end

function GameTimeManager:GetRemainingTime(end_time)
    local endtime = end_time or self:GetCurrentServerTime()
    local leftTime = tonumber(endtime) - self:GetCurrentServerTime()
    leftTime = math.max(0, leftTime)
    return tonumber(leftTime)
end

function GameTimeManager:FormatTimeToDHM(secondsSince1970)
    local time, date = self:GetFormatedServerTimeString(secondsSince1970)
    return date .. " " .. time,time
end

function GameTimeManager:FormatTimeToHM(secondsSince1970)
    local secondsSince1970 = math.max(secondsSince1970, 0);
    return os.date("%H", secondsSince1970) .. ":" .. os.date("%M", secondsSince1970)
end

function GameTimeManager:FormatTimeToHMS(secondsSince1970)
    local secondsSince1970 = math.max(secondsSince1970, 0);
    return os.date("%H", secondsSince1970) .. ":" .. os.date("%M", secondsSince1970) .. ":" .. os.date("%S", secondsSince1970)
end

function GameTimeManager:FormatTimeToD(secondsSince1970)
    local secondsSince1970 = math.max(secondsSince1970, 0);
    -- print("GameTimeManager GetFormatedServerTimeString", secondsSince1970);
    return os.date("%Y/%m/%d", secondsSince1970)
end

function GameTimeManager:GetFormatedCurrentServerTime(formatFun)
    local currentServerTime = self:GetCurrentServerTime()
    return self:GetFormatedServerTimeString(currentServerTime, formatFun)
end

function GameTimeManager:GetDeviceTimeZone()
    if GameDeviceManager:IsAndroidDevice() then 
        local timeZone = 24 - os.time{year=1970, month=1, day=2, hour=0}/3600
        return timeZone
    else
        local timeZone = TimeHelper.GetSysGMTTimeZone()
        return timeZone
    end
end

function GameTimeManager:GetServerTimeZone()
    return self._serverTimeZone
end

function GameTimeManager:GetFormatedServerTimeString(secondsSince1970, formatFun)
    -- local serverTimeZone = self:GetServerTimeZone()
    -- local deviceTimeZone = self:GetDeviceTimeZone()

    -- local timeDifferInSeconds = (deviceTimeZone - serverTimeZone) * 3600

    local newTimsStamp = secondsSince1970  -- - tonumber(timeDifferInSeconds)
    local date = self:FormatTimeToD(newTimsStamp)
    local time = formatFun and formatFun(newTimsStamp) or self:FormatTimeToHM(newTimsStamp)--os.date("%X", newTimsStamp)
    return time, date
end

function GameTimeManager:FormatTimeLength(timeLengthInSecond,showDay)
    local secondsLeft = timeLengthInSecond or 0
    local hourAmount = math.floor(secondsLeft / 3600);
    secondsLeft = secondsLeft % 3600;

    local minuteAmount = math.floor(secondsLeft / 60);
    secondsLeft = secondsLeft % 60;

    local secondAmount = math.floor(secondsLeft);

    local resultString = ""

    if showDay and hourAmount > 24 then
        local day = math.floor(hourAmount/24)
        resultString =  day.. "d"
        hourAmount = hourAmount - 24 * day
    end
    if hourAmount < 10 then
        resultString = resultString .. "0"
    end

    resultString = resultString .. (hourAmount .. ":");

    if minuteAmount < 10 then
        resultString = resultString .. "0"
    end

    resultString = resultString .. (minuteAmount .. ":");

    if secondAmount < 10 then
        resultString = resultString .. "0"
    end

    resultString = resultString .. secondAmount;

    return resultString;
end

---格式化为分钟和秒，分钟超过60显示跟多位数
function GameTimeManager:FormatTimeLengthMS(timeLengthInSecond)
    local secondsLeft = timeLengthInSecond or 0

    local minuteAmount = math.floor(secondsLeft / 60)

    secondsLeft = secondsLeft % 60

    local secondAmount = math.floor(secondsLeft)

    local resultString = ""

    if minuteAmount < 10 then
        resultString = resultString .. "0"
    end

    resultString = resultString .. (minuteAmount .. ":")

    if secondAmount < 10 then
        resultString = resultString .. "0"
    end

    resultString = resultString .. secondAmount

    return resultString
end

function GameTimeManager:GetTimeLengthDate(timeLengthInSecond)
    local timeDate = {}
    timeDate.d = timeLengthInSecond // (24* 60 * 60)
    timeDate.h = timeLengthInSecond % (24* 60 * 60) // (60* 60)
    timeDate.m = timeLengthInSecond % (60* 60) // 60
    timeDate.s = timeLengthInSecond % 60
    return timeDate
end

function GameTimeManager:GetTimeLengthDescription(timeStamp)
	local timeDesc = ""
	local currentServerTime = GameTimeManager:GetCurrentServerTime()
	local timeLength = currentServerTime - timeStamp
	local phaseIndex = 0
	if timeLength > 3600 * 8 then
		local time, date = GameTimeManager:GetFormatedServerTimeString(timeStamp)
		timeDesc = date .. " " .. time
		phaseIndex = 4
	else
		local hours = math.floor(timeLength / 3600)
		local mins = math.floor(timeLength % 3600 / 60)

		if timeLength >= 3600 and timeLength < 3600 * 8 then
			timeDesc = GameTextLoader:ReadText("LC_WORD_REPORT_GATHER_TIME_3")
			timeDesc = LuaTools:FormatString(timeDesc, hours, mins)
			phaseIndex = 3
		elseif timeLength >= 300 and timeLength < 3600 then
			timeDesc = GameTextLoader:ReadText("LC_WORD_REPORT_GATHER_TIME_2")
			timeDesc = LuaTools:FormatString(timeDesc, mins)
			phaseIndex = 2
		elseif timeLength < 300 then
			timeDesc = GameTextLoader:ReadText("LC_WORD_REPORT_GATHER_TIME_1")
			phaseIndex = 1
		end
	end

	return timeDesc, phaseIndex
end

function GameTimeManager:ToMiliSecond(timeInSec)
    return timeInSec * 1000
end

--首先获取服务器时间，获取不到使用客户端时间，避免程序卡住
function GameTimeManager:GetCurServerOrLocalTime()
    --local resultTime = self:GetCurrentServerTime(true)
    --if not resultTime or resultTime == 0 then
    --    return self:GetDeviceTime()
    --end
    --return resultTime

    ---new
    return self:GetCurLocalTime(true)
end

function GameTimeManager:PrintDateTime(time)
    -- 获取当前时间戳
    local timestamp = time

    -- 将时间戳转换为整数秒和小数部分
    local seconds = math.floor(timestamp)
    local milliseconds = math.floor((timestamp - seconds) * 1000)

    -- 格式化日期和时间
    local date = os.date("%Y-%m-%d %H:%M:%S", seconds)
    local formattedDate = string.format("%s.%03d", date, milliseconds)

    --print("当前日期和时间（精确到毫秒）:", formattedDate)

    printf("当前理论时间是",formattedDate)
end

---获取理论上的网络时间
function GameTimeManager:GetTheoryTime()
    --if self.m_theoryTime then
    --    local curOSTime = socket.gettime()
    --    local now = self.m_theoryTime.netTime + curOSTime - self.m_theoryTime.osTime
    --    --self:PrintDateTime(now)
    --    return now
    --else
    --    local netTime = self:GetNetWorkTimeSync(true)
    --    if netTime > 0 then
    --        return netTime
    --    else
    --        if GameTimeManager.m_fallbackShowDeviceTime then
    --            local curOSTime = socket.gettime()
    --            self.m_theoryTime = {
    --                osTime = curOSTime,
    --                netTime = curOSTime,
    --                netMilliTime = curOSTime * 1000
    --            }
    --            return curOSTime
    --        end
    --        return netTime
    --    end
    --end
    
    ---new
    return self:GetCurLocalTime(true)
end

--[[
    @desc: 判断两个时间戳是不是同一天
    author:{author}
    time:2024-12-19 15:27:06
    --@time1:
	--@time2:
    @return:
]] 
function GameTimeManager:IsSameDay(time1, time2)
    --local date1 = os.date("*t", time1)
    --local date2 = os.date("*t", time2)
    --
    --return date1.year == date2.year and date1.month == date2.month and date1.day == date2.day
    -- 计算天数基数（避免浮点数运算）
    local day1 = time1 // SECONDS_PER_DAY
    local day2 = time2 // SECONDS_PER_DAY
    return day1 == day2
end

--[[
    @desc: 判断某个是对应的周几
    author:{author}
    time:2024-12-19 16:03:02
    --@time:
	--@day: 
    @return:
]]
function GameTimeManager:IsWeekDay(time, day)
    if day < 1 or day > 7 then
        return false
    end
    local date = os.date("*t", time)
    return date.wday == day
end

--[[
    @desc: 调整当前时间返回，周几1-7，7是周日
    author:{author}
    time:2024-12-19 16:53:58
    --@time: 
    @return:
]]
function GameTimeManager:GetDayOfWeekAdjusted(time)
    local date = os.date("*t", time)

    local dayOfWeek = date.wday

    if dayOfWeek == 1 then
        dayOfWeek = 7
    else
        dayOfWeek = dayOfWeek - 1
    end

    return dayOfWeek
end
--[[
    @desc: 矫正时间，把周日当成每周最后一天处理
    author:{author}
    time:2024-12-19 16:43:07
    --@time1: 
    @return:
]]
function GameTimeManager:GetStartOfWeek(timestamp)
    -- 获取时间戳对应的日期信息
    local date = os.date("*t", timestamp)
    
    -- 计算当前日期距离周一的天数偏移
    -- Lua 的 wday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    local offset = 1  -- 1（周日）到 7（周六），调整为周一为第一天

    -- 如果 wday == 1 (周日)，则应该偏移 -6 天，将周日作为周末最后一天
    if date.wday == 1 then
        offset = -6
    end
    
    -- 将日期调整为当前日期的周一
    date.day = date.day - offset

    -- 将调整后的日期转换回时间戳
    return os.time(date)
end

--[[
    @desc: 矫正周日为每周最后一天然后比较2个时间戳是否在同一周
    author:{author}
    time:2024-12-19 16:52:53
    --@timestamp1:
	--@timestamp2: 
    @return:
]]
function GameTimeManager:IsSameWeek(timestamp1, timestamp2)
    -- 获取两个时间戳对应的周一时间戳
    local startOfWeek1 = self:GetStartOfWeek(timestamp1)
    local startOfWeek2 = self:GetStartOfWeek(timestamp2)
    
    -- 判断两者的周一时间戳是否相同
    local day1 = self:GetDayOfWeekAdjusted(startOfWeek1)
    local day2 = self:GetDayOfWeekAdjusted(startOfWeek2)
    if math.abs(timestamp1 - timestamp2) >= 24 * 60 * 60 then
        if day1 == day2 then
            return false
        end
    end
    if day1 == day2 then
        return true
    else
        return false
    end
    return day1 == day2
end

function GameTimeManager:IsUpdateMonday(time1, time2)
    local local_time = os.date("*t")
    local utc_time = os.date("!*t")
    local timezone_offset = os.time(local_time) - os.time(utc_time)


    local timestamp1 = time1 - timezone_offset
    local timestamp2 = time2 - timezone_offset

    if math.abs(timestamp1 - timestamp2) >= 7 * 24 * 60 * 60 then
        return true
    end
    local date1 = os.date("*t", timestamp1)
    local date2 = os.date("*t", timestamp2)
    if date1.year ~= date2.year then
        return true
    end
    --找到结束时间当周的周一
    local offdays1 = 0
    if date1.wday == 1 then
        --如果是周日的对应的周一就是上一周的
        offdays1 = -6
    else
        offdays1 = 2 - date1.wday
    end
    local calTime1 = timestamp1 + (offdays1*24*60*60)
    local newDate1 = os.date("*t", calTime1)

    local offdays2 = 0
    if date2.wday == 1 then
        --如果是周日的对应的周一就是上一周的
        offdays2 = -6
    else
        offdays2 = 2 - date2.wday
    end
    local calTime2 = timestamp2 + (offdays2*24*60*60)
    local newDate2 = os.date("*t", calTime2)

    return newDate1.day ~= newDate2.day
end

--[[
    @desc: 当前时间距离下个周一还有多少秒
    author:{author}
    time:2024-12-19 17:09:46
    --@timestamp: 
    @return:
]]
function GameTimeManager:SecondsUntilNextMonday(time)
    local local_time = os.date("*t")
    local utc_time = os.date("!*t")
    local timezone_offset = os.time(local_time) - os.time(utc_time)
    local timestamp = time - timezone_offset
    -- 获取当前时间戳对应的日期信息
    local date = os.date("*t", timestamp)
    
    -- 获取星期几（1 = Sunday, 2 = Monday, ..., 7 = Saturday）
    local dayOfWeek = date.wday
    
    -- 如果是周日（wday == 1），那么需要调整到下一个周一（wday == s2）
    local daysUntilMonday = 0
    if dayOfWeek == 1 then
        daysUntilMonday = 1  -- 周日到下周一的天数差是 1 天
    else
        daysUntilMonday = 8 - dayOfWeek + 1 -- 当前天到下周一的天数差
    end

    -- 将当前日期加上 daysUntilMonday 的天数，得到下一个周一的时间戳
    date.day = date.day + daysUntilMonday
    date.hour = 0
    date.min = 0
    date.sec = 0
    -- 重新获取下一个周一的时间戳
    local nextMondayTimestamp = os.time(date)
    
    -- 计算当前时间戳与下一个周一之间的秒数差
    return nextMondayTimestamp - timestamp
end

--[[
    @desc: 当前传入的时间戳距离第二天还有多少秒
    author:{author}
    time:2024-12-19 17:10:13
    --@timestamp: 
    @return:
]]
function GameTimeManager:SecondsUntilTomorrow(time)
    local local_time = os.date("*t")
    local utc_time = os.date("!*t")
    local timezone_offset = os.time(local_time) - os.time(utc_time)
    local timestamp = time - timezone_offset
    -- 获取当前时间戳对应的日期信息
    local date = os.date("*t", time)
    
    -- 构造当前日期的零点时间戳
    local todayMidnight = os.time{year = date.year, month = date.month, day = date.day, hour = 0, min = 0, sec = 0}
    
    -- 明天的零点时间戳
    local tomorrowMidnight = todayMidnight + 24 * 60 * 60

    -- 计算当前时间到明天零点的秒数差
    return tomorrowMidnight - timestamp
end

function GameTimeManager:SecondsUntilTomorrowLocal(time)
    local currentTime = os.time()
    local today = os.date("*t", currentTime)
    local nextDay = {year=today.year,month=today.month, day=today.day + 1, hour =0, min =0, sec = 0}
    local nextDayTime = os.time(nextDay)
    return nextDayTime - currentTime
end


