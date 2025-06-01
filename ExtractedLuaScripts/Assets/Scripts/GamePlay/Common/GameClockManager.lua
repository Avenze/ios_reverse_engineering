---@class GameClockManager
local GameClockManager = GameTableDefine.GameClockManager
local ActorEventManger = GameTableDefine.ActorEventManger
local EventManager = require("Framework.Event.Manager")
local ConfigMgr = GameTableDefine.ConfigMgr

local GAME_CLOCK = "game_clock"

local isDeepNight

--游戏的时钟,界面右上角显示的事件就是这里的
--第一次进游戏保留一个时间戳,再以后任意时间,始终根据与这个时间戳的距离,计算当前时间
--游戏里跑的速度与显示有一定的比例,并且分白天和黑夜,各自的比例也不同
--另外第一次进游戏,会调整为8点(还是9点来着..)
--加速,跳过黑夜的方法,就是一点点前移初始的那个时间戳

function GameClockManager:Init()--还是说直接改成存 时,分两个数据算了,别这么麻烦
    local data = ConfigMgr.config_global.game_clock
    local showDay = data[1]--5开始出现白天表现的时间
    local showNight = data[2]--22黑夜xxx

    local beginDay = data[3]--9白天开始的时间 beginDay:00(逻辑上的)
    local beginNight = data[4]--18夜晚xxx

    local stepDay = data[5]--60现实世界1s表示游戏白天stepDay秒
    local stepNight = data[6]--180夜晚xxx

    local lenDay = (beginNight - beginDay) * 3600 / stepDay--游戏中白天的时长(现实,秒)
    local lenNight = (24 - beginNight + beginDay) * 3600 / stepNight
    self.lenClock = lenDay + lenNight
    self.currDay = 0

    self.save = LocalDataManager:GetDataByKey(GAME_CLOCK)
    if not self.save.beginTime then
        local currTime = GameTimeManager:GetCurrentServerTime()
        local currHour = tonumber(os.date("%H", currTime))

        if currHour < 9 then
            currTime  = currTime - 86400
        end

        local currYear = tonumber(os.date("%Y", currTime))
        local currMonth = tonumber(os.date("%m", currTime))
        local currDay = tonumber(os.date("%d", currTime))

        self.save.beginTime = os.time{year = currYear, month = currMonth, day = currDay, hour = 8}
        --保留玩家第一次进入的时间戳,后面每次计算,就是通过当前时间与这个时间戳的距离,计算当前时间
        self.save.beginOffset = self.save.beginTime - currTime
        --时间戳的偏移量,用来让第一次进入游戏的时间为8点
        LocalDataManager:WriteToFile()
    end
    self.beginOffest = self.save.beginOffset

    self.offsetTime = self.offsetTime or 0
    --local SetOffsetTime = function(hour, min)
    --    local cur = GameTimeManager:GetCurrentServerTime()
    --    local h = tonumber(os.date("%H", cur))
    --    local m = tonumber(os.date("%M", cur))
    --    local offset = (hour * 60 + min) - (h * 60 + m)
    --    self.offsetTime = offset * 60
    --end
    -- SetOffsetTime(22,0)

    self.starTime = self.save.beginTime
    self.starHour = tonumber(os.date("%H", self.starTime))
    self.starMin = tonumber(os.date("%M", self.starTime))

    self.begin = {beginDay, beginNight}
    self.step = {stepDay, stepNight}
    self.len = {lenDay, lenNight}
    self.show = {showDay, showNight}

    self.batCome = {ConfigMgr.config_global.skipNightEvent["begin"], ConfigMgr.config_global.skipNightEvent["end"]}

    self.beginFromDay = false
    if self.starHour >= beginDay and 
        self.starHour < beginNight then
            self.beginFromDay = true
    end

    local nearType = self.beginFromDay and 1 or 2
    local farType = self.beginFromDay and 2 or 1

    local minDis = 60 - self.starMin
    local hourDis = self.begin[farType] - 1 - self.starHour
    if hourDis < 0 then
        hourDis = 24 + hourDis
    end

    local nearDis = (minDis*60 + hourDis*3600) / self.step[nearType]
    local farDis = nearDis + self.len[farType]
    self.distance = {nearDis, farDis} --开始游戏时间戳与两个昼夜变化节点的距离(现实,秒)

    self.stepShort = 0.2--(self.step[1] > self.step[2]) and (60 / self.step[1]) or (60 / self.step[2])
    
    self.stepAction = 1

    self.currTime = 0
    self.currTime2 = 0

    isDeepNight = false
end

function GameClockManager:CalculateCurrGameTime()
    -- TODO 因未知原因  CalculateCurrGameTime()会在  Init()前调用，因self.offsetTime不存在而报错
    if not self.offsetTime then
        self:Init()
        --printError("GameClockManager:CalculateCurrGameTime() 在 GameClockManager:Init() 之前调用")
    end

    local currTime = GameTimeManager:GetCurrentServerTimeInMilliSec() + (self.offsetTime * 1000) + (self.beginOffest * 1000)
    local timePass = (currTime - self.starTime * 1000) / 1000--现实经过了多少秒

    self.currDay = math.floor(timePass / self.lenClock)

    timePass = timePass % self.lenClock
    --timePass始终是当前时间与第一次进游戏之间的距离
    --所以timePass到后面会特别大
    --但是玩家在游戏内经过1天整,和经过100天整,它的 时:分也是一样的
    --所以进行一个模除操作

    local type = self.beginFromDay and 1 or 2
    local typeNext = self.beginFromDay and 2 or 1

    --下面这个就是在一天内,根据当前是早上还是晚上,以及经过多长时间
    --来判断现在的 时:分
    isDeepNight = self.step[type] == ConfigMgr.config_global.game_clock[6]
    if timePass > self.distance[2] then--经过两个变化又回来
        timePass = timePass - self.distance[2]--现实世界过了多少秒
        timePass = timePass * self.step[type] / 60--对应游戏过了多少分钟
        self.currMin = 0
        self.currHour = self.begin[type]
    elseif timePass > self.distance[1] then--刚好变天
        timePass = timePass - self.distance[1]
        timePass = timePass * self.step[typeNext] / 60
        self.currMin = 0
        self.currHour = self.begin[typeNext]
        isDeepNight = self.step[typeNext] == ConfigMgr.config_global.game_clock[6]
    else--不变
        timePass = timePass * self.step[type] / 60
        self.currMin = self.starMin
        self.currHour = self.starHour
    end

    self.currMin = self.currMin + timePass
    local hourPass = self.currMin / 60
    self.currMin = self.currMin % 60

    self.currHour = self.currHour + hourPass
    self.currHour = self.currHour % 24

    self.currHour = math.floor(self.currHour)
    self.currMin = math.floor(self.currMin)
    -- if self.currHour == 0 and self.currMin == 0 then
    --     self.currDay = (self.currDay or 0) + 1
    -- end

    return self.currHour,self.currMin,self.currDay
end

function GameClockManager:GetCurrGameTime()
    if self.currHour == nil then
        self:CalculateCurrGameTime()
    end
    return self.currHour,self.currMin,self.currDay
end

function GameClockManager:IsDay()
    if self.currHour == nil then
        self:CalculateCurrGameTime()
    end
    local disNight = self.show[2] - self.currHour
    if disNight <= 0 then
        disNight = disNight + 24
    end
    local temp = self.show[2] - self.show[1]
    return disNight <= temp
end

function GameClockManager:skipTheNightAway()--加速度过黑夜
    if self:Inside(self.currHour*3600 + self.currMin*60, self.begin[1]*3600, self.begin[2]*3600) then
        --还是逻辑上的白天
        EventManager:DispatchEvent("UI_NOTE", "now is day")
        return
    end

    local disToDay = 0
    local currV = self.currHour * 3600 + self.currMin*60
    local goalV = self.begin[1]*3600
    if currV < goalV then
        disToDay = goalV - currV
    else
        disToDay = goalV + 86400 - currV
    end

    disToDay = math.floor(disToDay / self.step[2])

    self.offsetGoal = self.save.beginTime - disToDay

    self.skipStep = math.floor(disToDay / 18)

    self.skipNight = true
end

function GameClockManager:Update(dt)
    if not self.save then
        return
    end

    local returnNormal = false
    local returnAction = false

    if self.currTime < self.stepShort then--每0.2s执行一次
        self.currTime = self.currTime + dt
    else
        self.currTime = 0
        returnNormal = true
    end

    if self.currTime2 < self.stepAction then--每1秒执行一次
        self.currTime2 = self.currTime2 + dt
    else
        self.currTime2 = 0
        returnAction = true
    end

    if returnNormal then
        if self.skipNight then
            self.save.beginTime = math.floor(self.save.beginTime - self.skipStep)
            self.starTime = math.floor(self.starTime - self.skipStep)

            if self.save.beginTime <= self.offsetGoal then
                self.skipNight = false
            end
        end

        local currH,currMin = self:CalculateCurrGameTime()
    end

    if returnAction then
        local nowIsDay,canChange = self:ChangeDayNight()
        if canChange then
            if nowIsDay then
                self.BatComeBefor = false
                EventManager:DispatchEvent("DAY_COME")
            else
                EventManager:DispatchEvent("NIGHT_COME")
            end
            self.isDay = nowIsDay
        end

        local needCome,isCome = self:ChangeBatMan()
        if needCome and not isCome and not self.BatComeBefor then
            self.BatComeBefor = true
            EventManager:DispatchEvent("BATMAN_COME")
        elseif isCome and not needCome then
            EventManager:DispatchEvent("BATMAN_LEAVE")
        end
    end
end

function GameClockManager:ChangeDayNight()--昼夜表现的
    local currValue = self.currHour * 3600 + self.currMin*60
    local isDay = false--表现上是否为白天
    if self:Inside(currValue, self.show[1]*3600, self.show[2]*3600) then
        isDay = true
    end
    
    if self.isDay == nil then
        self.isDay = isDay
    end

    return isDay,self.isDay ~= isDay
end

function GameClockManager:ChangeBatMan()--蝙蝠侠的出现
    -- if GameStateManager:IsInCity() then
    --     return false,false
    -- end
    if GameStateManager:IsInstanceState() or GameStateManager:IsCycleInstanceState() then
        return false, false
    end
    local currValue = self.currHour * 3600 + self.currMin*60
    local needBatManCome = false
    if self:Inside(currValue, self.batCome[1], self.batCome[2]) then
        needBatManCome = true
    end

    local isOn = ActorEventManger:IsBatmanCome()--是否有

    return needBatManCome, isOn
end

function GameClockManager:Inside(currValue, leftValue, rightValue)
    if not currValue then
        currValue = self.currHour * 3600 + self.currMin*60
    end
    
    if rightValue > leftValue then
        return currValue > leftValue and currValue < rightValue
    end

    return currValue > leftValue or currValue < rightValue
end

function GameClockManager:IsDeepNight()
    return isDeepNight
end