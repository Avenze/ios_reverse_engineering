---活动开启条件远程配置
---@class ActivityRemoteConfigManager
local ActivityRemoteConfigManager = GameTableDefine.ActivityRemoteConfigManager
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local ShopManager = GameTableDefine.ShopManager
local ClockOutDataManager = GameTableDefine.ClockOutDataManager

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

ActivityRemoteConfigManager.CompareValueType =
{
    EQ = 0, -- 等于，条件到达时开启
    LT = 10, -- 小于, 条件直接开
    LTE = 11, -- 小于等于，条件直接开
    GT = 20, -- 大于，条件到达时开启
    GTE = 21, -- 大于等于，条件到达时开启
}

ActivityRemoteConfigManager.ActivityEnableType =
{
    STAR = 10,
    SCENE = 20,
}

--- 条件值
function ActivityRemoteConfigManager:GetLocalValueByActivityType(type)
    if math.floor(type) == self.ActivityEnableType.STAR then
        return GameTableDefine.StarMode.GetStar()
    elseif math.floor(type) == self.ActivityEnableType.SCENE then
        return math.floor((GameTableDefine.CityMode:GetCurrentBuilding() or 0) / 100)
    end

    return nil
end

--- 条件比较
function ActivityRemoteConfigManager:CompareValue(open_conditions)
    local enable = true
    local thresholdValue
    if open_conditions and #open_conditions > 0 then
        for _, open_condition in ipairs(open_conditions) do
            if not enable then
                break
            end

            local status, result = pcall(function()
                local type = math.floor(tonumber(open_condition.type))
                local value = math.floor(tonumber(open_condition.value))
                local compareType = math.floor(tonumber(open_condition.compareType))
            end)

            if not status then
                print("捕获到错误:", result)
                return false, nil
            else
                --print("执行成功:", result)
            end

            local type = math.floor(tonumber(open_condition.type))
            local value = math.floor(tonumber(open_condition.value))
            local compareType = math.floor(tonumber(open_condition.compareType))
            if type and value and compareType then
                local localValue = self:GetLocalValueByActivityType(type)
                if localValue then
                    if compareType == ActivityRemoteConfigManager.CompareValueType.EQ then -- 等于，条件到达时开启
                        if localValue < value then
                            enable = true
                            thresholdValue = value
                        elseif localValue == value then
                            enable = true
                        else
                            enable = false
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.LT then -- 小于, 条件直接开
                        enable = localValue < value
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.LTE then -- 小于等于，条件直接开
                        enable = localValue <= value
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.GT then -- 大于，条件到达时开启
                        enable = true
                        if localValue <= value then
                            thresholdValue = value + 1
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.GTE then -- 大于等于，条件到达时开启
                        enable = true
                        if localValue < value then
                            thresholdValue = value
                        end
                    end
                else
                    enable = false
                end
            else
                enable = false
            end
        end
    else
        -- 没有配置条件时，采用默认条件
        if GameTableDefine.StarMode:GetStar() < 3 then
            enable = true
            thresholdValue = 3
        end
    end
    
    return enable, thresholdValue
end

--[[
    @desc: 增加一个检测当前条件是否满足的接口用于检测与开放条件是否达成的调用
    author:{author}
    time:2025-05-06 15:51:37
    --@open_conditions: 
    @return:
]]
function ActivityRemoteConfigManager:CheckNowConditionIsEnable(open_conditions)
    local enable = true
    local thresholdValue
    if open_conditions and #open_conditions > 0 then
        for _, open_condition in ipairs(open_conditions) do
            if not enable then
                break
            end

            local status, result = pcall(function()
                local type = math.floor(tonumber(open_condition.type))
                local value = math.floor(tonumber(open_condition.value))
                local compareType = math.floor(tonumber(open_condition.compareType))
            end)

            if not status then
                print("捕获到错误:", result)
                return false
            else
                --print("执行成功:", result)
            end

            local type = math.floor(tonumber(open_condition.type))
            local value = math.floor(tonumber(open_condition.value))
            local compareType = math.floor(tonumber(open_condition.compareType))
            if type and value and compareType then
                local localValue = self:GetLocalValueByActivityType(type)
                if localValue then
                    if compareType == ActivityRemoteConfigManager.CompareValueType.EQ then -- 等于，条件到达时开启
                        if localValue ~= value then
                            return false
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.LT then -- 小于, 条件直接开
                        if localValue >= value then
                            return false
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.LTE then -- 小于等于，条件直接开
                        if localValue > value then
                            return false
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.GT then -- 大于，条件到达时开启
                        if localValue <= value then
                            return false
                        end
                    elseif compareType == ActivityRemoteConfigManager.CompareValueType.GTE then -- 大于等于，条件到达时开启
                        if localValue < value then
                            return false
                        end
                    end
                else
                    enable = false
                end
            else
                enable = false
            end
        end
    else
        -- 没有配置条件时，采用默认条件
        if GameTableDefine.StarMode:GetStar() < 3 then
            enable = true
            -- thresholdValue = 3
        end
    end
    
    return enable
end

--- 副本活动, 初始化条件判断
function ActivityRemoteConfigManager:CheckCycleInstanceEnable()
    local state = CycleInstanceDataManager:GetInstanceState()
    if state > 1 then -- 2,   --解锁后/活动中 3,   --可领奖 4,  --预告
        local enable, thresholdValue = ActivityRemoteConfigManager:CompareValue(CycleInstanceDataManager:GetInstanceOpenCondition())
        if enable then
            if thresholdValue then
                CycleInstanceDataManager.InstanceEnableValue = thresholdValue
            else
                CycleInstanceDataManager:SetInstanceEnable()
                LocalDataManager:WriteToFileInmmediately()

                CycleInstanceDataManager.InstanceEnableValue = nil
                GameTableDefine.MainUI:RefreshInstanceentrance()
            end
        end
    else
        CycleInstanceDataManager.InstanceEnableValue = nil
    end
end

--- 限时礼包, 初始化条件判断
function ActivityRemoteConfigManager:CheckLimitPackEnable()
    local curTime = GameTimeManager:GetCurrentServerTime(true)
    local tLAData = TimeLimitedActivitiesManager:GetTLAData()
    local limitPackData = tLAData.limitPack
    if limitPackData and limitPackData.startTime and limitPackData.endTime then
        if limitPackData.endTime > curTime and limitPackData.startTime <= curTime then
            local enable, thresholdValue = ActivityRemoteConfigManager:CompareValue(limitPackData.open_conditions)
            if enable then
                if thresholdValue then
                    TimeLimitedActivitiesManager.LimitPackEnableValue = thresholdValue
                else
                    limitPackData.LimitPackEnable = true
                    LocalDataManager:WriteToFileInmmediately()

                    TimeLimitedActivitiesManager.LimitPackEnableValue = nil
                    GameTableDefine.MainUI:LimitPackActivity(GameStateManager:IsInFloor())
                end
            end
        else
            TimeLimitedActivitiesManager.LimitPackEnableValue = nil
        end
    else
        TimeLimitedActivitiesManager.LimitPackEnableValue = nil
    end
end

--- 三选一礼包, 初始化条件判断
function ActivityRemoteConfigManager:CheckLimitPackChooseEnable()
    local curTime = GameTimeManager:GetCurrentServerTime(true)
    local tLAData = TimeLimitedActivitiesManager:GetTLAData()
    local limitPackChooseData = tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose]
    if limitPackChooseData and limitPackChooseData.startTime and limitPackChooseData.endTime then
        if limitPackChooseData.endTime > curTime and limitPackChooseData.startTime <= curTime then
            local enable, thresholdValue = ActivityRemoteConfigManager:CompareValue(limitPackChooseData.open_conditions)
            if enable then
                if thresholdValue then
                    TimeLimitedActivitiesManager.LimitPackChooseEnableValue = thresholdValue
                else
                    limitPackChooseData.LimitPackChooseEnable = true
                    LocalDataManager:WriteToFileInmmediately()

                    TimeLimitedActivitiesManager.LimitPackChooseEnableValue = nil
                    GameTableDefine.MainUI:LimitChooseActivity(GameStateManager:IsInFloor())
                end
            end
        else
            TimeLimitedActivitiesManager.LimitPackChooseEnableValue = nil
        end
    else
        TimeLimitedActivitiesManager.LimitPackChooseEnableValue = nil
    end
end

--- 累充活动, 初始化条件判断
function ActivityRemoteConfigManager:CheckAccumulatedChargePackEnable()
    local curTime = GameTimeManager:GetCurrentServerTime(true)
    local AccumulatedChargeData = LocalDataManager:GetDataByKey("acc_charge_activity_data")
    if AccumulatedChargeData.start_time and AccumulatedChargeData.end_time then
        if AccumulatedChargeData.end_time > curTime and AccumulatedChargeData.start_time <= curTime then
            local enable, thresholdValue = ActivityRemoteConfigManager:CompareValue(AccumulatedChargeData.open_conditions)
            if enable then
                if thresholdValue then
                    AccumulatedChargeActivityDataManager.AccumulatedChargeEnableValue = thresholdValue
                else
                    AccumulatedChargeActivityDataManager.m_accChargeACData.AccumulatedChargeEnable = true
                    LocalDataManager:WriteToFileInmmediately()

                    AccumulatedChargeActivityDataManager.AccumulatedChargeEnableValue = nil
                    GameTableDefine.MainUI:OpenAccumulatedChargeActivity()
                end
            end
        else
            AccumulatedChargeActivityDataManager.AccumulatedChargeEnableValue = nil
        end
    else
        AccumulatedChargeActivityDataManager.AccumulatedChargeEnableValue = nil
    end
end

--- 首充双倍, 初始化条件判断
function ActivityRemoteConfigManager:CheckResetDoubleEnable()
    local curTime = GameTimeManager:GetCurrentServerTime(true)
    local resetDoubleData = GameTableDefine.FirstPurchaseUI:GetSaveData()
    if resetDoubleData.startTime then
        resetDoubleData.startTime = tonumber(resetDoubleData.startTime)
    end
    
    if resetDoubleData.endTime then
        resetDoubleData.endTime = tonumber(resetDoubleData.endTime)
    end
    if resetDoubleData and resetDoubleData.startTime and resetDoubleData.endTime then
        if resetDoubleData.endTime > curTime and resetDoubleData.startTime <= curTime then
            local enable, thresholdValue = ActivityRemoteConfigManager:CompareValue(resetDoubleData.open_conditions)
            if enable then
                if thresholdValue then
                    ShopManager.ResetDoubleEnableValue = thresholdValue
                else
                    resetDoubleData.ResetDoubleEnable = true
                    LocalDataManager:WriteToFileInmmediately()

                    ShopManager.ResetDoubleEnableValue = nil
                    GameTableDefine.MainUI:RefreshFirstPurchaseBtn()
                end
            end
        else
            ShopManager.ResetDoubleEnableValue = nil
        end
    else
        ShopManager.ResetDoubleEnableValue = nil
    end
end

--- 进程中条件判断
function ActivityRemoteConfigManager:CheckActivityCondition()
    -- 副本活动
    if CycleInstanceDataManager.InstanceEnableValue then
        ActivityRemoteConfigManager:CheckCycleInstanceEnable()
    end
    
    -- 限时礼包
    if TimeLimitedActivitiesManager.LimitPackEnableValue then
        ActivityRemoteConfigManager:CheckLimitPackEnable()
    end

    -- 三选一
    if TimeLimitedActivitiesManager.LimitPackChooseEnableValue then
        ActivityRemoteConfigManager:CheckLimitPackChooseEnable()
    end

    -- 累充活动
    if AccumulatedChargeActivityDataManager.AccumulatedChargeEnableValue then
        ActivityRemoteConfigManager:CheckAccumulatedChargePackEnable()
    end

    -- 首充双倍
    if ShopManager.ResetDoubleEnableValue then
        ActivityRemoteConfigManager:CheckResetDoubleEnable()
    end

    --下班打卡活动 2025-3-27 fy
    if ClockOutDataManager.m_ClockOutEnableValue then
        ActivityRemoteConfigManager:CheckClockOutEnable()
    end
end

--- 条件满足统一判断
function ActivityRemoteConfigManager:CheckPackEnable(type)
    -- 副本活动
    if type == TimeLimitedActivitiesManager.CycleInstanceActivity then
        return CycleInstanceDataManager:GetInstanceEnable()
    end

    -- 限时礼包
    if type == TimeLimitedActivitiesManager.GiftPackType.LimitPack then
        local tLAData = TimeLimitedActivitiesManager:GetTLAData()
        return tLAData.limitPack and tLAData.limitPack.LimitPackEnable
    end

    -- 三选一
    if type == TimeLimitedActivitiesManager.GiftPackType.LimitChoose then
        local tLAData = TimeLimitedActivitiesManager:GetTLAData()
        return tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose] and tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose].LimitPackChooseEnable
    end

    -- 累充活动
    if type == TimeLimitedActivitiesManager.GiftPackType.AccumulatedCharge then
        return AccumulatedChargeActivityDataManager.m_accChargeACData and AccumulatedChargeActivityDataManager.m_accChargeACData.AccumulatedChargeEnable
    end

    -- 首充双倍
    if type == TimeLimitedActivitiesManager.ActivityList[3] then
        local resetDoubleData = GameTableDefine.FirstPurchaseUI:GetSaveData()
        return resetDoubleData and resetDoubleData.ResetDoubleEnable
    end

    --下班打开活动
    if type == TimeLimitedActivitiesManager.ClockOut then
        return ClockOutDataManager.m_ClockOutData and ClockOutDataManager.m_ClockOutData.m_ClockOutEnable
    end
    return false
end

--[[
    @desc: 检测判断下班打卡活动是否开启,这里有三种情况会调用到开启，第一个初始化，第二个是星级达到要求，第三个是建筑达到要求
    author:{author}
    time:2025-03-27 11:33:05
    @return:
]]
function ActivityRemoteConfigManager:CheckClockOutEnable()
    local curTime = GameTimeManager:GetCurrentServerTime(true)
    local clockOutData = LocalDataManager:GetDataByKey("clock_out_activity_data")
    if clockOutData.start_time and clockOutData.end_time then
        if clockOutData.end_time > curTime and clockOutData.start_time <= curTime then
            local enable, thresholdValue = self:CompareValue(clockOutData.m_openConditions)
            if enable then
                if thresholdValue and (not ClockOutDataManager.m_ClockOutEnableValue or ClockOutDataManager.m_ClockOutEnableValue ~= thresholdValue) then
                    ClockOutDataManager.m_ClockOutEnableValue = thresholdValue
                else 
                    if self:CheckNowConditionIsEnable(clockOutData.m_openConditions) then
                        clockOutData.m_ClockOutEnable  = true
                        LocalDataManager:WriteToFileInmmediately()
                        ClockOutDataManager.m_ClockOutEnableValue = nil
                        GameTableDefine.MainUI:OpenClockOutActivity()
                    end
                end
            end
        else
            ClockOutDataManager.m_ClockOutEnableValue = nil
        end
    else
        ClockOutDataManager.m_ClockOutEnableValue = nil
    end
end
