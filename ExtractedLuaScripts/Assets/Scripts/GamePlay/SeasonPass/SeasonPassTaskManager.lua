
---@class SeasonPassTaskManager
local SeasonPassTaskManager = GameTableDefine.SeasonPassTaskManager
local ConfigMgr = GameTableDefine.ConfigMgr
local GameTimeManager = GameTimeManager
local Timer = GameTimer
local EventManager = require("Framework.Event.Manager")

function SeasonPassTaskManager:ctor()
    self.isInit = false
end


function SeasonPassTaskManager:Reset(isGM)
    --活动结束或者活动重开时需要重置一下存档数据
    if self.passTaskData then
        self.passTaskData = {}
    else
        self.passTaskData = LocalDataManager:GetDataByKey("season_pass_task")
        self.passTaskData = {}
    end
    self.isInit = false
    LocalDataManager:Save("season_pass_task", self.passTaskData)
    if isGM then
        self:Init(5, "tuibiji")
    end
end

--[[
    @desc: 
    author:{author}
    time:2024-12-19 14:38:09
    --@seasonID:
	--@typeID: 类型id，用来匹配配置表中的不同类型需要获取的数据
    @return:
]]
function SeasonPassTaskManager:Init(seasonID, typeID)
    if self.isInit then
        return
    end
    local curTypeID = tostring(typeID)
    local isNewSeason = false
    self.gmDayOffTime = 0
    self.gmWeekOffTime = 0
    self.passTaskData = LocalDataManager:GetDataByKey("season_pass_task")
    if not self.passTaskData.season_id then
        self.passTaskData.season_id = seasonID
        self.passTaskData.curTaskData = {}
        self.passTaskData.curTaskData.Day = {}
        self.passTaskData.curTaskData.Week = {}
        self.passTaskData.curBeginDayTime = GameTimeManager:GetCurrentServerTime(true)
        self.passTaskData.curBeginWeekTime = GameTimeManager:GetCurrentServerTime(true)
        self.passTaskData.curType = curTypeID ---初始化当前的类型，用于配置表的对应获取数据
        isNewSeason = true
    else
        if self.passTaskData.season_id and self.passTaskData.season_id ~= seasonID then
            self.passTaskData.season_id = seasonID
            self.passTaskData.curTaskData = {}
            self.passTaskData.curTaskData.Day = {}
            self.passTaskData.curTaskData.Week = {}
            self.passTaskData.curType = curTypeID
            self.passTaskData.curBeginDayTime = GameTimeManager:GetCurrentServerTime(true)
            self.passTaskData.curBeginWeekTime = GameTimeManager:GetCurrentServerTime(true)
            isNewSeason = true
        else
            if Tools:GetTableSize(self.passTaskData.curTaskData.Day) > 0 then
                for group, v in pairs(self.passTaskData.curTaskData.Day) do
                    v.curTaskCfg = ConfigMgr.config_pass_task[self.passTaskData.curType].DayTasks[group]
                end
            end
            if Tools:GetTableSize(self.passTaskData.curTaskData.Week) > 0 then
                for key, v in pairs(self.passTaskData.curTaskData.Week) do
                    v.curTaskCfg = ConfigMgr.config_pass_task[self.passTaskData.curType].WeekTasks[key]
                end
            end
        end
    end
    if not self.passTaskData.curTaskData then
        self.passTaskData.curTaskData = {}
    end
    if not self.passTaskData.curTaskData.Day then
        self.passTaskData.curTaskData.Day = {}
    end
    if not self.passTaskData.curTaskData.Week then
        self.passTaskData.curTaskData.Week = {}
    end
    if isNewSeason then
        self:_initDayTask()
        self:_initWeekTask()
    else
        if Tools:GetTableSize(self.passTaskData.curTaskData.Day) <= 0 then
            self:_initDayTask()
        end
        if Tools:GetTableSize(self.passTaskData.curTaskData.Week) <= 0 then
            self:_initWeekTask()
        end
    end

    if self.refreshTimer then
        Timer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
    --自动执行一次登录任务
    self.isInit = true
    self:GetDayTaskProgress(2, 1)
    self.refreshTimer = Timer:CreateNewTimer(1, function()
        self:RefreshDayTaskData()
        self:RefreshWeekTaskData()
    end, true, true)
    
end

--[[
    @desc: 通过配置初始化每日任务数据内容
    author:{author}
    time:2024-12-19 17:34:00
    @return:
]]
function SeasonPassTaskManager:_initDayTask()
    self.passTaskData.curTaskData.Day = {}
    
    if not self.passTaskData.curType or not ConfigMgr.config_pass_task[self.passTaskData.curType] then
        return
    end

    for key, value in pairs(ConfigMgr.config_pass_task[self.passTaskData.curType].DayTasks or {}) do
        if not self.passTaskData.curTaskData.Day[value.group] then
            local taskItem = {}
            taskItem.curProgress = 0
            taskItem.curTaskCfg = value
            taskItem.curState = 0 --0进行中，1-完成未领取，2-完成已领取
            self.passTaskData.curTaskData.Day[value.group] = taskItem
        end
    end
end

--[[
    @desc: 初始化每周任务内容
    author:{author}
    time:2024-12-19 17:42:02
    @return:
]]
function SeasonPassTaskManager:_initWeekTask()
    self.passTaskData.curTaskData.Week = {}
    if not self.passTaskData.curType or not ConfigMgr.config_pass_task[self.passTaskData.curType] then
        return
    end
    for key, value in pairs(ConfigMgr.config_pass_task[self.passTaskData.curType].WeekTasks or {}) do
        if not self.passTaskData.curTaskData.Week[key] then
            local taskItem = {}
            taskItem.curProgress = 0
            taskItem.curTaskCfg = value
            taskItem.curStep = 1
            taskItem.curState = 0 --0进行中，1-完成未领取，2-完成已领取
            self.passTaskData.curTaskData.Week[key] = taskItem
        end
    end
end

function SeasonPassTaskManager:RefreshDayTaskData()
    if not self.isInit then
        return
    end
    if not self.passTaskData or not self.passTaskData.curBeginDayTime then
        return
    end
    if not GameTimeManager:IsSameDay(self.passTaskData.curBeginDayTime, GameTimeManager:GetCurrentServerTime(true) + self.gmDayOffTime or 0) then
        self:_initDayTask()
        self.gmDayOffTime = 0
        self.passTaskData.curBeginDayTime = GameTimeManager:GetCurrentServerTime(true)
        --自动执行一次登录任务
        self:GetDayTaskProgress(2, 1)
        EventManager:DispatchEvent("EVENT_SEASONTASK_DAY_REFRESH")
    end
end

function SeasonPassTaskManager:RefreshWeekTaskData()
    if not self.isInit then
        return
    end
    ---周更新需要判断两个时间戳是否同一周即可
    if not self.passTaskData or not self.passTaskData.curBeginWeekTime then
        return
    end
    if GameTimeManager:IsUpdateMonday(self.passTaskData.curBeginWeekTime, GameTimeManager:GetCurrentServerTime(true) + self.gmWeekOffTime or 0) then
        self:_initWeekTask()
        self.gmWeekOffTime = 0
        self.passTaskData.curBeginWeekTime = GameTimeManager:GetCurrentServerTime(true)
        EventManager:DispatchEvent("EVENT_SEASONTASK_WEEK_REFRESH")
    end
end

function SeasonPassTaskManager:OnPause()
    if not self.isInit then
        return
    end
    if self.refreshTimer then
        Timer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
end

function SeasonPassTaskManager:OnResume()
    if not self.isInit then
        return
    end
    if self.refreshTimer then
        Timer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
    self.refreshTimer = Timer:CreateNewTimer(1, function()
        self:RefreshDayTaskData()
        self:RefreshWeekTaskData()
    end, true, true)
end

--[[
    @desc: 返回当前每日刷新剩余时间
    author:{author}
    time:2024-12-19 15:15:20
    @return:
]]
function SeasonPassTaskManager:GetDayRefreshTimeLeft()
    if not self.isInit or not self.passTaskData or not self.passTaskData.curBeginDayTime then
        return 0
    end
    -- print("Day Refresh time, beginDayTime:"..tostring(self.passTaskData.curBeginDayTime).."gmDayOffTime:"..tostring(self.gmDayOffTime).." curTime:"..GameTimeManager:GetCurrentServerTime(true))
    local refreshTime = GameTimeManager:SecondsUntilTomorrow(self.passTaskData.curBeginDayTime + self.gmDayOffTime)
    local curTimeLeft = GameTimeManager:SecondsUntilTomorrow(GameTimeManager:GetCurrentServerTime(true)+ self.gmDayOffTime)
    -- local leftTime = refreshTime - (GameTimeManager:GetCurrentServerTime(true) - (self.passTaskData.curBeginDayTime + self.gmDayOffTime))
    return curTimeLeft
end


--[[
    @desc: 返回当前每周的刷新时间
    author:{author}
    time:2024-12-19 15:15:55
    @return:
]]
function SeasonPassTaskManager:GetWeekRefreshTimeLeft()
    if not self.isInit or not self.passTaskData or not self.passTaskData.curBeginWeekTime then
        return 0
    end
    local refreshTime = GameTimeManager:SecondsUntilNextMonday(self.passTaskData.curBeginWeekTime + self.gmWeekOffTime)
    local leftTime = GameTimeManager:SecondsUntilNextMonday(GameTimeManager:GetCurrentServerTime(true) + self.gmWeekOffTime)
    -- local leftTime = refreshTime - (GameTimeManager:GetCurrentServerTime(true) - (self.passTaskData.curBeginWeekTime + self.gmWeekOffTime))
    return leftTime
end

--[[
    @desc: 完成日常任务的类型
    author:{author}
    time:2024-12-19 17:17:25
    --@taskType:
	--@value: 
    @return:
]]
function SeasonPassTaskManager:GetDayTaskProgress(taskType, value)
    if not self.isInit then
        return
    end
    if not self.passTaskData or not self.passTaskData.curType 
    or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Day then
        return
    end
    
    if not self.passTaskData.curTaskData.Day[taskType] or not self.passTaskData.curTaskData.Day[taskType].curTaskCfg then
        return
    end
    if self.passTaskData.curTaskData.Day[taskType].curState == 0 then
        self.passTaskData.curTaskData.Day[taskType].curProgress  = self.passTaskData.curTaskData.Day[taskType].curProgress + value
        if self.passTaskData.curTaskData.Day[taskType].curProgress >= self.passTaskData.curTaskData.Day[taskType].curTaskCfg.threhold then
            -- self.passTaskData.curTaskData.Day[taskType].curProgress = self.passTaskData.curTaskData.Day[taskType].curTaskCfg.threhold
            self.passTaskData.curTaskData.Day[taskType].curState = 1
        end
    end
end

function SeasonPassTaskManager:GetWeekTaskProgress(taskType, value)
    if not self.isInit then
        return
    end
    if not self.passTaskData or not self.passTaskData.curType 
    or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Week then
        return
    end
    if not self.passTaskData.curTaskData.Week[taskType] or not self.passTaskData.curTaskData.Week[taskType].curTaskCfg
    or not self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep] then
        return
    end
    local curCfg = self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep]
    self.passTaskData.curTaskData.Week[taskType].curProgress  = self.passTaskData.curTaskData.Week[taskType].curProgress + value
    if self.passTaskData.curTaskData.Week[taskType].curState == 0 then
        if self.passTaskData.curTaskData.Week[taskType].curProgress >= curCfg.threhold then
            -- self.passTaskData.curTaskData.Week[taskType].curProgress = curCfg.threhold
            self.passTaskData.curTaskData.Week[taskType].curState = 1
        end
    end
    EventManager:DispatchEvent("EVENT_SEASONTASK_WEEK_REFRESH")
end

function SeasonPassTaskManager:ClaimedDayTask(taskType, cb)
    if not self.isInit then
        return
    end
    if not self.passTaskData or not self.passTaskData.curType 
    or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Day then
        return
    end
    
    if not self.passTaskData.curTaskData.Day[taskType] or not self.passTaskData.curTaskData.Day[taskType].curTaskCfg then
        return
    end
    if self.passTaskData.curTaskData.Day[taskType].curState == 1 then
        self.passTaskData.curTaskData.Day[taskType].curState = 2
        GameTableDefine.SeasonPassManager:AddExp(self.passTaskData.curTaskData.Day[taskType].curTaskCfg.reward, self.passTaskData.curTaskData.Day[taskType].curTaskCfg.id)
        if cb then
            cb(self.passTaskData.curTaskData.Day[taskType].curTaskCfg.reward)
        end
        return
    end
    if cb then
        cb(0)
    end
end

function SeasonPassTaskManager:ClaimedWeekTask(taskType, cb)
    if not self.passTaskData or not self.passTaskData.curType 
    or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Week then
        return
    end
    if not self.passTaskData.curTaskData.Week[taskType] or not self.passTaskData.curTaskData.Week[taskType].curTaskCfg
    or not self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep] then
        return
    end
    local curCfg = self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep]
    local reward = curCfg.reward
    if self.passTaskData.curTaskData.Week[taskType].curState == 1 then
        GameTableDefine.SeasonPassManager:AddExp(reward, curCfg.id)
        if not self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep + 1] then
            --最大等级了
            self.passTaskData.curTaskData.Week[taskType].curState = 2
        else
            -- self.passTaskData.curTaskData.Week[taskType].curProgress = 0
            self.passTaskData.curTaskData.Week[taskType].curState = 0
            self.passTaskData.curTaskData.Week[taskType].curStep = self.passTaskData.curTaskData.Week[taskType].curStep + 1
            --还要判断一下下一次的任务是否也是完成状态了
            local updateCfg = self.passTaskData.curTaskData.Week[taskType].curTaskCfg[self.passTaskData.curTaskData.Week[taskType].curStep]
            if self.passTaskData.curTaskData.Week[taskType].curProgress >= updateCfg.threhold then
                self.passTaskData.curTaskData.Week[taskType].curState = 1
            end
        end
        
    end
    if cb then
        cb(reward)
    end
end

--[[
    @desc: GM命令调整刷新冷却时间
    author:{author}
    time:2024-12-19 17:58:24
    --@type:
	--@leftTime: leftime还需要多少秒即可完成冷却刷新，最短只能调成60秒
    @return:
]]
function SeasonPassTaskManager:GMModifyTaskTime(type, leftTime)
    local useLeftTime = leftTime
    if useLeftTime < 60 then
        useLeftTime = 60
    end
    if type == 1 then
        --修改日常任务的刷新时间
        -- self.gmDayOffTime =  (GameTimeManager:SecondsUntilTomorrow(self.passTaskData.curBeginDayTime) - useLeftTime)
        self.gmDayOffTime =  (GameTimeManager:SecondsUntilTomorrow(GameTimeManager:GetCurrentServerTime(true)) - useLeftTime)
    elseif type == 2 then
        -- self.gmWeekOffTime =  (GameTimeManager:SecondsUntilNextMonday(self.passTaskData.curBeginWeekTime) - useLeftTime)
        self.gmWeekOffTime =  (GameTimeManager:SecondsUntilNextMonday(GameTimeManager:GetCurrentServerTime(true)) - useLeftTime)
    end
end

function SeasonPassTaskManager:GetDayTaskData()
    if not self.passTaskData or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Day then
        return {}
    end
    return self.passTaskData.curTaskData.Day
end

function SeasonPassTaskManager:GetWeekTaskData()
    if not self.passTaskData or not self.passTaskData.curTaskData or not self.passTaskData.curTaskData.Week then
        return {}
    end
    return self.passTaskData.curTaskData.Week
end

--[[
    @desc: 获取当前所有可领取的任务数量
    author:{author}
    time:2024-12-25 11:26:37
    @return:
]]
function SeasonPassTaskManager:GetCanClaimTaskTotalNum()
    local result = 0
    if not self.passTaskData or not self.passTaskData.curTaskData or (not self.passTaskData.curTaskData.Week and not self.passTaskData.curTaskData.Day) then
        return {}
    end
    for _, v in pairs(self.passTaskData.curTaskData.Day) do
        if v.curState == 1 then
            result = result + 1
        end
    end
    for _, v in pairs(self.passTaskData.curTaskData.Week) do
        if v.curState == 1 then
            result  = result + 1
        end
    end
    return result
end

return SeasonPassTaskManager