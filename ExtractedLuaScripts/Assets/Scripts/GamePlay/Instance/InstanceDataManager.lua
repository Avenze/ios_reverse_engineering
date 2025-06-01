--[[
    @desc: 副本数据管理类,负责获取或设置副本存档数据和全局信息.
    author:{author}
    time:2023-04-17 14:17:16
    @return:
]]
---@class InstanceDataManager
local InstanceDataManager = GameTableDefine.InstanceDataManager
local configManager = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local UIRedirect = GameTableDefine.UIRedirect
local ResourceManger = GameTableDefine.ResourceManger
local LocalDataManager = LocalDataManager

local EventManager = require("Framework.Event.Manager")

local Application = CS.UnityEngine.Application
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local CoinFieldName = "m_CurInstanceCoin" ---存档中副本钞票存款名
local ScoreFieldName = "m_CurScore" ---存档中副本积分名

InstanceDataManager.instanceState = {
    overtime = 1,   --已超时/未开启
    isActive = 2,   --解锁后/活动中
    awartable = 3,  --可领奖

}
InstanceDataManager.timeType = {
    sleep = 1,  --睡觉
    eat = 2,  --吃饭
    work = 3,  --工作
}


--声明变量的方法,所有的变量再次声明,单纯为了查找变量方便
function InstanceDataManager:DeclareVariable()
    self.config_global = nil --config全局表数据
    self.config_instance_bind = nil
    self.config_rooms_instance = nil 
    self.config_furniture_instance = nil
    self.config_furniture_level_instance = nil 
    self.config_resource_instance = nil
    self.config_shop_frame_instance = nil 
    self.config_achievement_instance = nil 
    self.config_rewardType_instance = nil
    self.config_rewardID_instance = nil
    

    self.activeInstance = nil --活动中的副本
    self.callback = nil --初始化结束回调
    self.saveBaseData = nil --副本存档数据
    self.m_InstanceTimeScale = nil --副本的timeScale
    self.timer = nil --副本循环timer
    self.lastTimeType = 0   --上一个时间状态
end

function InstanceDataManager:Init(callback)
    self:DeclareVariable()
    self.callback = callback
    self.saveBaseData = LocalDataManager:GetDataByKey("InstanceBase")
    self:InitCfgData()
    
    --设置UI重定向
    UIRedirect:Redirect(self.config_instance_bind[self.saveBaseData.m_Instance_id or 1].redirect)
    
    --===特殊处理一下当次的活动有奖励的情况下，领奖时间延长3天后面是要删除掉的
    -- if self.saveBaseData.m_CurScore and self.saveBaseData.m_CurScore > 0 and not self.saveBaseData.m_IsGetCurReward and not self:GetInstanceRewardIsActive() then
    --     local threeDays = 3 * 24 * 3600
    --     self.saveBaseData.m_RewardOverTime = GameTimeManager:GetCurServerOrLocalTime() + threeDays
    --     LocalDataManager:WriteToFileInmmediately()
    -- end
    --========特殊处理结束，后面是要删除掉的

    local isRunSaveDataActive = false
    --如果检测到本地副本活动中或者领奖结算中
    if self:GetInstanceIsActive() or self:GetInstanceRewardIsActive() then
        isRunSaveDataActive = true
    end
    if isRunSaveDataActive then
        --step1.检测本地存档的活动数据
        --获取离线时间，加入到Offset Time中去，计算离线奖励
        if self:GetInstanceRewardIsActive() then
            --计算离线奖励
            -- self:CalculateInstanceOfflineReward()
        end
        --如果现在还在游戏中的话离线奖励时进入副本时再进行计算
        if self.callback then
            self.callback()
            self.callback = nil
        end
        self.lastTimeType =  self:GetCurInstanceTimeType()
        if self.timer then
            GameTimer:StopTimer(self.timer)
            self.timer = nil
        end
        --创建Timer,更新副本时间并发送事件
        self.timer = GameTimer:CreateNewTimer(1,function()
            if not self:GetInstanceIsActive() then
                GameTimer:StopTimer(self.timer)
                self.timer = nil
                return
            end
            local curTimeType = self:GetCurInstanceTimeType()
            if curTimeType ~= self.lastTimeType then
                EventManager:DispatchEvent("INSTANCE_TIME_TYPE_CHANGE", self.lastTimeType, curTimeType)
                self.lastTimeType = curTimeType
            end
            LocalDataManager:WriteToFile()
        end,true,true)

    else
        --step2.如果本地没有活动数据，或者时间已经操过当次活动的奖励领取结算时间了，再次请求服务器是否有活动
        --print("InstanceDataManager====================================================================================")
        GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.InstanceActivity)
        return
    end
    --gxy 2023-8-11 11:53:07 异常处理,有的人存档里有InstanceBase,但这里面是空的导致进不去副本
    if next(self.saveBaseData) == nil then
        GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.InstanceActivity)
    end
end

function InstanceDataManager:GetCurInstanceTimeType()
    local curTime = self:GetCurInstanceTime()
    for k,v in pairs(self.config_global.timeArrange) do
        if curTime.Hour >= v.range[1] and curTime.Hour < v.range[2] then
            return v.timeType
        end
    end    
end

function InstanceDataManager:InitCfgData()
    local globalCfg = configManager.config_global
    self.config_global = {
        startCash = globalCfg.instance_cash,    --副本初始资金
        startTime = globalCfg.instance_initial_time,    --副本初始时间
        oneDayDuration = globalCfg.instance_duration,   --副本时间（一天的持续时间,单位:分钟）
        shipCD = globalCfg.instance_ship_cooltime,  --运输船初始CD（秒）
        shipLoadTime = globalCfg.instance_ship_loadtime,    --运输船装货时长（秒）
        -- timeArrange = globalCfg.instance_time_arrange,  --副本时间安排（1睡觉2吃饭3工作）
        employeeUpperLimit = globalCfg.instance_employee_upperlimit,    --副本员工属性上限
        stateWeaken = globalCfg.instance_state_weaken,  --副本员工工作时属性衰减速率（分钟）
        timeNode = globalCfg.instance_timenode,     --副本时间节点（白天，黑夜）
        instanceBGM = globalCfg.instance_bgm,
        stateThreshold = globalCfg.instance_state_threshold,    --副本员工debuff阈值
        stateDebuff = globalCfg.instance_state_debuff   --副本员工debuff效果（产量衰减）
    }

    if not self.m_InstanceTimeScale then
        self.m_InstanceTimeScale = (24 * 60) / self.config_global.oneDayDuration
    end
    
    --将副本表全都加载进来,所有用到副本表的地方从这里取
    local instance_id = self.saveBaseData.m_Instance_id or 1
    self.config_instance_bind = configManager.config_instance_bind
    self.config_rooms_instance = configManager.config_rooms_instance[instance_id]
    self.config_furniture_instance = configManager.config_furniture_instance
    self.config_furniture_level_instance = configManager.config_furniture_level_instance
    self.config_resource_instance = configManager.config_resource_instance[instance_id]
    self.config_shop_frame_instance = configManager.config_shop_frame_instance[instance_id]
    self.config_achievement_instance = configManager.config_achievement_instance[instance_id]
    self.config_rewardType_instance = configManager.config_rewardType_instance[instance_id]
    self.config_rewardID_instance = configManager.config_rewardID_instance[instance_id]

    self.config_global.timeArrange = self.config_instance_bind[instance_id].instance_time_arrange
end

function InstanceDataManager:GetInstanceArchiveDataByID(id)
    if not self.saveBaseData then
        return nil
    end
    for k, v in pairs(self.saveBaseData) do
        if v.instanceID == id then
            return v
        end
    end
end


--获取活动状态
function InstanceDataManager:GetInstanceState()
    if self:GetInstanceIsActive() then
        return self.instanceState.isActive
    end
    if self:GetInstanceRewardIsActive() then
        return self.instanceState.awartable
    end

    --解锁状态是进入时检测的一个条件不应感作为副本的一个状态出现
    return self.instanceState.overtime
end


--[[
    @desc: 在活动结束且在奖励结算时间进入的接口调用
    author:{author}
    time:2023-03-20 20:38:45
    @return:
]]
function InstanceDataManager:EnterInstanceInRewardTime()
end

--[[
    @desc: 游戏暂停，调用离线保存时间，退出副本和在副本中切换app到后台
    author:{author}
    time:2023-03-20 20:41:56
    @return:
]]
function InstanceDataManager:OnPause()
    GameTableDefine.InstanceOfflineRewardUI:CloseView()
    self.m_CurOfflineRewardData = nil
    if self.saveBaseData and self:GetInstanceIsActive() then
        self.saveBaseData.m_CurLastOfflineTime = GameTimeManager:GetCurServerOrLocalTime()
        LocalDataManager:WriteToFile()
    end
end

--[[
    @desc: 游戏恢复，调用离线的计算，主要用于在副本中切到app后台
    author:{author}
    time:2023-03-20 20:42:29
    @return:
]]
function InstanceDataManager:OnResume()
    self:CalculateInstanceOfflineReward()
    GameTableDefine.InstanceOfflineRewardUI:GetView()
end

--[[
    @desc: 处理warriorSDK请求的返回数据内容
    author:{author}
    time:2023-03-20 20:10:20
    --@warriorMsgData: --joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ",instance_id = "this.instance_id +", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
    @return:
]]
function InstanceDataManager:ProcessSDKCallbackData(warriorMsgData)
    if not warriorMsgData then return end
    if tonumber(warriorMsgData.activityType) ~= TimeLimitedActivitiesManager.InstanceActivity then
        return
    end
    --instanceID 为每次开启活动时自增的id序号; instance_id 为活动类型ID,其不随活动的反复开启而变化
    --joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ",instance_id = "this.instance_id +"+ ",duration = "this.duration +", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
    local startTime = tonumber(warriorMsgData.startTime) 
    -- warrior 把結算時間當作最後的活動結束時間，settlementTime > endTime by Gxy 2023/12/13
    local endTime = tonumber(warriorMsgData.settlementTime) 
    local rewardTime = tonumber(warriorMsgData.endTime)

    local instanceID = tonumber(warriorMsgData.instanceID)
    local instance_id = tonumber(warriorMsgData.instance_id)
    local duration = warriorMsgData.duration * 3600
    if not startTime or not endTime or not rewardTime or not instanceID then
        return
    end

    if startTime > endTime or startTime > GameTimeManager:GetCurServerOrLocalTime() or 
    endTime < GameTimeManager:GetCurServerOrLocalTime() or endTime > rewardTime or rewardTime < GameTimeManager:GetCurServerOrLocalTime() then
        return
    end

    if not self.saveBaseData then
        self.saveBaseData = LocalDataManager:GetDataByKey("InstanceBase")
    end
    local now = GameTimeManager:GetCurrentServerTime(true)
    self.saveBaseData.m_StartTime = now
    self.saveBaseData.m_EndTime = now + duration
    self.saveBaseData.m_RewardOverTime = now + duration + (rewardTime - endTime)
    self.saveBaseData.m_InstanceID = instanceID
    self.saveBaseData.m_Instance_id = instance_id
    
    self:InitCfgData()  -- 刷新saveDataBase后需要更新初始化配置表数据
    self:ClearSaveData()
    self:AddCurInstanceCoin(self.config_global.startCash )
    GameTableDefine.InstanceTaskManager:InitTaskData(instance_id)
    --设置UI重定向
    UIRedirect:Redirect(self.config_instance_bind[self.saveBaseData.m_Instance_id or 1].redirect)

    -- self.saveBaseData.m_IsGetCurReward = false
    -- self.saveBaseData.m_RoomData = {}
    -- self.saveBaseData.m_CurKSLevel = 0
    -- self.saveBaseData.m_CurInstanceCoin = self.config_global.startCash
    -- self.saveBaseData.m_CurScore = 0
    -- self.saveBaseData.m_CurLastOfflineTime = 0
    -- self.saveBaseData.m_CurOfflineOffsetTime = 0
    -- self.saveBaseData.m_AddBuffData = {}
    -- self.saveBaseData.curMaxGiftID = 0
    self.lastTimeType =  self:GetCurInstanceTimeType()
    if self.timer then
        GameTimer:StopTimer(self.timer)
        self.timer = nil
    end
    --创建Timer,更新副本时间并发送事件
    self.timer = GameTimer:CreateNewTimer(1,function()
        if not self:GetInstanceIsActive() then
            GameTimer:StopTimer(self.timer)
            self.timer = nil
            return
        end
        local curTimeType = self:GetCurInstanceTimeType()
        if curTimeType ~= self.lastTimeType then
            EventManager:DispatchEvent("INSTANCE_TIME_TYPE_CHANGE", self.lastTimeType, curTimeType)
            self.lastTimeType = curTimeType
        end
        LocalDataManager:WriteToFile()
    end,true,true)
    LocalDataManager:WriteToFile()
    if self.callback then
        self.callback()
        self.callback = nil
    end
end

--[[
    @desc: 返回当前副本活动剩余时间，秒计
    author:{author}
    time:2023-03-20 20:27:44
    @return:副本活动开启剩余时间，0就是活动已经结束或者没有活动
]]
function InstanceDataManager:GetLeftInstanceTime()
    if self.saveBaseData.m_StartTime and self.saveBaseData.m_EndTime and self.saveBaseData.m_EndTime - self.saveBaseData.m_StartTime > 0 and self.saveBaseData.m_EndTime - GameTimeManager:GetCurServerOrLocalTime() > 0 then
        return self.saveBaseData.m_EndTime - GameTimeManager:GetCurServerOrLocalTime()
    end
    return 0
end

--[[
    @desc: 返回当前副本活动结束时间，秒计
    author:{author}
    time:2023-03-20 20:27:44
    @return:副本活动开启结束时间，0就是活动已经结束或者没有活动
]]
function InstanceDataManager:GetInstanceEndTime()
    if self.saveBaseData.m_EndTime then
        return self.saveBaseData.m_EndTime
    end
    
    return 0
end

--[[
    @desc: 返回当前活动剩余时间
    author:{author}
    time:2023-03-20 20:30:38
    @return:按秒计算，如果当前活动在继续中则返回0
]]
function InstanceDataManager:GetInstanceRewardTime()
    if self.saveBaseData.m_EndTime and self.saveBaseData.m_EndTime > GameTimeManager:GetCurServerOrLocalTime() then
        return 0
    end
    if self.saveBaseData.m_RewardOverTime and self.saveBaseData.m_RewardOverTime > GameTimeManager:GetCurServerOrLocalTime() then 
        return self.saveBaseData.m_RewardOverTime - GameTimeManager:GetCurServerOrLocalTime()
    end
    return 0
end

--[[
    @desc: 
    author:{author}
    time:2023-03-20 20:55:11
    @return:副本活动是否还在进行中
]]
function InstanceDataManager:GetInstanceIsActive()
    if self.saveBaseData and self.saveBaseData.m_EndTime and self.saveBaseData.m_EndTime > GameTimeManager:GetCurServerOrLocalTime() then
        return true
    end

    return false
end

--[[
    @desc: 
    author:{author}
    time:2023-03-20 20:55:49
    @return:当前是否在奖励结算中
]]
function InstanceDataManager:GetInstanceRewardIsActive()
    if self:GetInstanceIsActive() then
        return false
    end
    if self.saveBaseData and self.saveBaseData.m_RewardOverTime and self.saveBaseData.m_RewardOverTime > GameTimeManager:GetCurServerOrLocalTime() then
        if not self.saveBaseData.m_IsGetCurReward then
            return true
        end
    end

    return false
end

--[[
    @desc: 获取当前副本活动的ID，该ID是请求warrior服务器下发进行中的ID或者结算中的ID
    author:{author}
    time:2023-03-21 09:43:43
    @return:没有活动返回0
]]
function InstanceDataManager:GetCurInstanceID()
    if not self:GetInstanceIsActive() and not self:GetInstanceRewardIsActive() then
        return 0
    end
    if self.saveBaseData and self.saveBaseData.m_InstanceID then
        return self.saveBaseData.m_InstanceID
    end
    return 0
end

--[[
    @desc: 获得当前里程碑
    author:{author}
    time:2023-03-21 09:51:53
    @return:
]]
function InstanceDataManager:GetCurInstanceKSLevel()
    -- return 12
    if self.saveBaseData and self.saveBaseData.m_CurKSLevel then
        return self.saveBaseData.m_CurKSLevel
    end
    return 0
end

---获得当前未领奖的等级
function InstanceDataManager:GetNotClaimedLevel()
    if self.saveBaseData and self.saveBaseData.m_CurKSLevel then
        for i = 1, self.saveBaseData.m_CurKSLevel do
            if not self:IsRewardClaimed(i) then
                return i
            end
        end
        return 0
    end
    return 0
end

--[[
    @desc: 设置积分等级
    author:{author}
    time:2023-04-23 16:39:11
    --@value: 
    @return:
]]
function InstanceDataManager:SetCurInstanceKSLevel(value)
    if self.saveBaseData then
        self.saveBaseData.m_CurKSLevel = value
        GameTableDefine.InstanceMainViewUI:CallNotify(3)
        for k, v in ipairs(self.config_achievement_instance) do
            if self.saveBaseData.m_CurKSLevel >= v.level then
                if v.pack > self.saveBaseData.curMaxGiftID and GameTableDefine.ShopManager:CheckBuyTimes(v.pack) then
                    GameTableDefine.InstancePopUI:SetSaveShowID(v.pack)
                    GameTableDefine.InstanceMainViewUI:RefreshPackButton()
                    -- break
                end
            end
        end

        -- LocalDataManager:WriteToFile()
    end
end

---奖励是否领取
function InstanceDataManager:IsRewardClaimed(level)
    level = tostring(level)
    if self.saveBaseData and self.saveBaseData.m_ObtainRewards and self.saveBaseData.m_ObtainRewards[level] then
        return true
    end
    return false
end

---将某等级以下的所有奖励标记为已领取
function InstanceDataManager:SetAllRewardClaimed()
    if self.saveBaseData then
        if not self.saveBaseData.m_ObtainRewards then
            self.saveBaseData.m_ObtainRewards = {}
        end
        local curLevel = self:GetCurInstanceKSLevel()
        for i = curLevel, 1,-1 do
            self.saveBaseData.m_ObtainRewards[tostring(i)] = true
        end
    end
end

---将某等级奖励标记为已领取
function InstanceDataManager:SetRewardClaimed(level)
    if self.saveBaseData then
        level = tostring(level)
        if not self.saveBaseData.m_ObtainRewards then
            self.saveBaseData.m_ObtainRewards = {}
        end

        if not self.saveBaseData.m_ObtainRewards[level] then
            self.saveBaseData.m_ObtainRewards[level] = true
            return true
        else
            return false
        end
    end
    return false
end

---是否有任何奖励可以领取
function InstanceDataManager:IsAnyRewardCanClaim()
    if self.saveBaseData then
        local curLevel = self:GetCurInstanceKSLevel()
        if curLevel>0 then
            for i = 1, curLevel do
                if not self.saveBaseData.m_ObtainRewards or not self.saveBaseData.m_ObtainRewards[tostring(i)] then
                    return true
                end
            end
        end
    end
    return false
end

--[[
    @desc: 返回当前副本的分数
    author:{author}
    time:2023-03-21 10:33:28
    @return:
]]
function InstanceDataManager:GetCurInstanceScore()
    if self.saveBaseData then
        return LocalDataManager:DecryptField(self.saveBaseData,ScoreFieldName)
    end
    --if self.saveBaseData and self.saveBaseData.m_CurScore then
    --    return self.saveBaseData.m_CurScore
    --end
    return 0
end

--[[
    @desc: 设置积分
    author:{author}
    time:2023-04-23 15:50:17
    --@value: 
    @return:
]]
function InstanceDataManager:SetCurInstanceScore(value)
    if self.saveBaseData then
        LocalDataManager:EncryptField(self.saveBaseData,ScoreFieldName,value)
        --self.saveBaseData.m_CurScore = value
    end

    -- LocalDataManager:WriteToFile()
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:35:19
    @return:返货当前副本中的货币
]]
function InstanceDataManager:GetCurInstanceCoin()
    if self.saveBaseData then
        return LocalDataManager:DecryptField(self.saveBaseData,CoinFieldName)
    end
    --if self.saveBaseData and self.saveBaseData.m_CurInstanceCoin then
    --    return self.saveBaseData.m_CurInstanceCoin
    --end
    return 0
end

---@return number 累计获取的货币
function InstanceDataManager:GetAccumulateCoin()
    if self.saveBaseData and self.saveBaseData.m_AccumulateCoin then
        return self.saveBaseData.m_AccumulateCoin
    end
    return 0
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:36:25
    @return:返回上一次的离线时间戳
]]
function InstanceDataManager:GetLastOfficeTime()
    if self.saveBaseData and self.saveBaseData.m_CurLastOfflineTime then
        return self.saveBaseData.m_CurLastOfflineTime
    end
    return 0
end

--[[
    @desc: 改变副本当前时间,正数为时间向后,负数为时间向前
    author:{author}
    time:2023-07-24 15:30:55
    @return:
]]
function InstanceDataManager:ChangeCurrentTime(value)
    if self.saveBaseData and self.saveBaseData.m_StartTime then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local changeTime = 60 * self.config_global.oneDayDuration / 24 * value
        if self.saveBaseData.m_StartTime - changeTime > now then
            self.saveBaseData.m_StartTime = now
        else
            self.saveBaseData.m_StartTime = self.saveBaseData.m_StartTime - changeTime 
        end
    end
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:38:38
    @return:返回离线时间差累积值
]]
function InstanceDataManager:GetOfflineOffsetTime()
    if self.saveBaseData and self.saveBaseData.m_CurOfflineOffsetTime then
        return self.saveBaseData.m_CurOfflineOffsetTime
    end
    return 0
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:44:50
    @return:返货当前副本的奖励是否已经领取，这个需要判断下当前是否在奖励领取中才用该函数，
    为了避免问题，现在是有异常会直接返回true，不一定代表已经领过
]]
function InstanceDataManager:GetCurInstanceRewardIsGet()
    if self.saveBaseData and self.saveBaseData.m_IsGetCurReward then
        return self.saveBaseData.m_IsGetCurReward
    end
    --如果没有该值就直接返回真，避免逻辑引起可领取的判断
    return true
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:49:57
    --@roomID: 
    @return:返回制定房间的数据，table中的数据结构
]]
function InstanceDataManager:GetCurRoomData(roomID)
    local key = tostring(roomID)
    --TODO:数据结构待定
    if self.saveBaseData and self.saveBaseData.m_RoomData and self.saveBaseData.m_RoomData[key] then
        return self.saveBaseData.m_RoomData[key]
    end
    return {}
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:51:51
    @return:返回当前加成buffer的数据
]]
function InstanceDataManager:GetCurInstanceAddBuffData()
    if self.saveBaseData and self.saveBaseData.m_AddBuffData then
        return self.saveBaseData.m_AddBuffData
    end
    return {}
end

--[[
    @desc: 
    author:{author}
    time:2023-03-21 10:52:34
    @return:获取当前副本的时间，H:M:S
]]
function InstanceDataManager:GetCurInstanceTime()
    --副本中的开始时间globalData.instance_initial_time对应副本的starttime
    --副本的时间流逝频率globalData.instance_duration
    --已流逝时间真实时间
    -- local realOfftime =
    if not self.m_InstanceTimeScale then
         self.m_InstanceTimeScale = (24 * 60) / configManager.config_global.instance_duration
    end
    local result = {}
    result.Hour = 0
    result.Min = 0
    result.Sec = 0
    if self.saveBaseData.m_StartTime and GameTimeManager:GetCurServerOrLocalTime() > self.saveBaseData.m_StartTime then
        local DupOfftime = (GameTimeManager:GetSocketTime() - self.saveBaseData.m_StartTime) * self.m_InstanceTimeScale
        DupOfftime = DupOfftime + 3600 * self.config_global.startTime

        result.Min = math.floor(DupOfftime % 86400 % 3600 / 60)
        result.Hour = math.floor(DupOfftime % 86400 / 3600)
        --print("InstanceTime:",GameTimeManager:GetCurServerOrLocalTime(),self.saveBaseData.m_StartTime,DupOfftime,result.Hour,":",result.Min,":",result.Sec)
    end
    return result
end

--[[
    @desc: 结算离线奖励
    author:{author}
    time:2023-03-21 11:42:47
    @return:
]]
function InstanceDataManager:CalculateInstanceOfflineReward()
    if not self.saveBaseData then
        return
    end
    if self.saveBaseData.m_CurLastOfflineTime and self.saveBaseData.m_CurLastOfflineTime > 0 then
        if not self.saveBaseData.m_CurOfflineOffsetTime then
            self.saveBaseData.m_CurOfflineOffsetTime = 0
        end
        local offsetTime = self.saveBaseData.m_CurOfflineOffsetTime + (GameTimeManager:GetCurServerOrLocalTime() - self.saveBaseData.m_CurLastOfflineTime)
        if offsetTime > 60 then
            if self.saveBaseData.m_CurOfflineOffsetTime then
                self.saveBaseData.m_CurOfflineOffsetTime  = self.saveBaseData.m_CurOfflineOffsetTime + offsetTime
            else
                self.saveBaseData.m_CurOfflineOffsetTime = offsetTime
            end
        end
        --TODO:这里有个礼包需要判断，玩家如果购买过礼包上限是4小时，没有购买，上限是2小时
        local maxTime = self:GetMaxOfflineTime()
        if self.saveBaseData.m_CurOfflineOffsetTime > maxTime then
            self.saveBaseData.m_CurOfflineOffsetTime = maxTime
        end
        self.saveBaseData.m_CurLastOfflineTime = nil
        LocalDataManager:WriteToFile()
    end
    self.m_CurOfflineRewardData = nil

    --累积不满2分钟不计算离线奖励
    if not self.saveBaseData.m_CurOfflineOffsetTime or self.saveBaseData.m_CurOfflineOffsetTime < 2 * 60 then
        return
    end
    --开始计算离线的奖励数据
    local rewardOfflineTime = math.floor(self.saveBaseData.m_CurOfflineOffsetTime * 0.5)
    local productions, money = GameTableDefine.InstanceModel:CalculateOfflineRewards(rewardOfflineTime,false,true)
    if not self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = {}
    end
    self.m_CurOfflineRewardData.productions = productions
    self.m_CurOfflineRewardData.rewardMoney = money
    self.m_CurDisplayOfflinesetTime = self.saveBaseData.m_CurOfflineOffsetTime
    self.saveBaseData.m_CurLastOfflineTime = nil
    self.saveBaseData.m_CurOfflineOffsetTime = 0
    LocalDataManager:WriteToFile()
end

--[[
    @desc: 获取当前离线奖励的数据内容，提供给离线奖励UI显示使用
    author:{author}
    time:2023-03-21 11:55:52
    @return:{xx:xx}
]]
function InstanceDataManager:GetCurInstanceOfflineRewardData()
    return self.m_CurOfflineRewardData
end

--[[
    @desc: 开启一个持续时间为openMin的活动,如果openMin为空即是一个默认5分钟的活动
    author:{author}
    time:2023-03-21 14:39:20
    @return:
]]
function InstanceDataManager:GMOpenInstanceActivity(openMin, id)
    local activityTime = openMin or 5

        if not self.saveBaseData then
            self.saveBaseData = LocalDataManager:GetDataByKey("InstanceBase")
        end
        self.saveBaseData.m_StartTime = GameTimeManager:GetCurServerOrLocalTime()
        self.saveBaseData.m_EndTime = self.saveBaseData.m_StartTime + (activityTime * 60)
        self.saveBaseData.m_RewardOverTime = self.saveBaseData.m_EndTime + (5*60)
        self.saveBaseData.m_InstanceID = 1
        self.saveBaseData.m_Instance_id = id

        LocalDataManager:WriteToFile()
end

--[[
    @desc: 设置一个副本房间的存档数据,不设置的参数传nil(不含设备列表数据)
    author:{author}
    time:2023-03-30 15:25:01
    --@roomID:房间ID
	--@buildTimePoint:开始休息间时间点
	--@state: 房间解锁状态
	--@lastSettlementTime: 上一次结算时间(根据建筑的工作CD计算得出)
    @return:
]]
function InstanceDataManager:SetRoomData(roomID,buildTimePoint,state,lastSettlementTime)
    if not roomID then
        return
    end
    local roomData = nil
    local roomIDStr = tostring(roomID)
    if self.saveBaseData and self.saveBaseData.m_RoomData and self.saveBaseData.m_RoomData[roomIDStr] then
        roomData = self.saveBaseData.m_RoomData[roomIDStr]
    else
        self.saveBaseData.m_RoomData[roomIDStr] = {}
    end
    self.saveBaseData.m_RoomData[roomIDStr].roomID = roomID
    self.saveBaseData.m_RoomData[roomIDStr].buildTimePoint = buildTimePoint or self.saveBaseData.m_RoomData[roomIDStr].buildTimePoint 
    self.saveBaseData.m_RoomData[roomIDStr].state = state or self.saveBaseData.m_RoomData[roomIDStr].state 
    self.saveBaseData.m_RoomData[roomIDStr].lastSettlementTime = lastSettlementTime or self.saveBaseData.m_RoomData[roomIDStr].lastSettlementTime 

    -- LocalDataManager:WriteToFile()
end

--[[
    @desc: 设置一个副本房间的设备存档数据,四个参数每个都必须传值,不能为nil
    author:{author}
    time:2023-03-30 15:41:24
    --@roomID:房间ID
	--@index:设备位置索引
	--@levelID:设备等级ID
	--@furnitureData:要设置的设备数据表,将要要设置的值都放在这里面用"attrName"= xxx,的这种形式设置
    @return:
]]
function InstanceDataManager:SetRoomFurnitureData(roomID,index,levelID,furnitureData)
    --[[
        furnitureData:{
            state:设备状态 1:已解锁  0:未解锁
	        name:设备对应的员工名
	        Attrs:设备对应的员工属性
            prefab:员工预制
	        isOpen:港口开放
	        lastReachTime:上次靠岸时间
	        lastLeaveTime:上次离岸时间
        }
    ]]

    if not roomID then
        return
    end
    local roomIDStr = tostring(roomID)
    local roomData = nil
    if self.saveBaseData and self.saveBaseData.m_RoomData and self.saveBaseData.m_RoomData[roomIDStr] then
        roomData = self.saveBaseData.m_RoomData[roomIDStr]
    else
        return
    end
    if not roomID or not index or not levelID or not furnitureData or next(furnitureData) == nil then
        return
    end

    roomData.furList = roomData.furList or {}
    local indexStr = tostring(index)
    roomData.furList[indexStr] = roomData.furList[indexStr] or {}
    roomData.furList[indexStr].index = index
    roomData.furList[indexStr].id = levelID

    for k,v in pairs(furnitureData) do
        if k == "state" then
            roomData.furList[indexStr].state = v
            
        elseif k == "name" then
            roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}
            roomData.furList[indexStr].worker.name = v    

        elseif k == "Attrs" then
            roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}   
            roomData.furList[indexStr].worker.attrs = v
            if roomData.furList[indexStr].worker.attrs["hungry"] < 0 then
                roomData.furList[indexStr].worker.attrs["hungry"] = 0
            end
            if roomData.furList[indexStr].worker.attrs["hungry"] > 100 then
                roomData.furList[indexStr].worker.attrs["hungry"] = 100
            end
            if roomData.furList[indexStr].worker.attrs["physical"] < 0 then
                roomData.furList[indexStr].worker.attrs["physical"] = 0
            end
            if roomData.furList[indexStr].worker.attrs["physical"] > 100 then
                roomData.furList[indexStr].worker.attrs["physical"] = 100
            end
        elseif  k == "prefab" then
            roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}
            roomData.furList[indexStr].worker.prefab = v   
        elseif k == "isOpen" then
            roomData.furList[indexStr].isOpen = v

        elseif k == "lastReachTime" then
            roomData.furList[indexStr].lastReachTime = v

        elseif k == "lastLeaveTime" then
            roomData.furList[indexStr].lastLeaveTime = v
        end
    end

    -- LocalDataManager:WriteToFile()
end

--[[
    @desc: 增加当前副本金钱
    author:{author}
    time:2023-03-30 16:49:20
    --@num: 
    @return:
]]
function InstanceDataManager:AddCurInstanceCoin(num)
    --local current = self:GetCurInstanceCoin()
    local coin = LocalDataManager:DecryptField(self.saveBaseData,CoinFieldName)
    coin = math.max(0,coin + num)
    LocalDataManager:EncryptField(self.saveBaseData,CoinFieldName,coin)
    --self.saveBaseData.m_CurInstanceCoin = self.saveBaseData.m_CurInstanceCoin + num
    --if self.saveBaseData.m_CurInstanceCoin < 0 then
    --    self.saveBaseData.m_CurInstanceCoin = 0
    --end
    --对积分的处理
    --self:AddScore(num)
    -- LocalDataManager:WriteToFile()
    self:AddAccumulateCoin(num)
    
end

---增加积累副本金钱
function InstanceDataManager:AddAccumulateCoin(num)
    if num>0 then
        local current = self:GetAccumulateCoin()
        self.saveBaseData.m_AccumulateCoin = current + num
        if self.saveBaseData.m_AccumulateCoin < 0 then
            self.saveBaseData.m_AccumulateCoin = 0
        end
    end
end

--[[
    @desc: 增加积分,自动处理越界情况
    author:{author}
    time:2023-04-23 16:56:45
    --@num: 
    @return:
]]
function InstanceDataManager:AddScore(num)
    if num > 0 then
        local isMaxLevel = false
        local curAchievement = self:GetCurInstanceKSLevel()
        local nextLevel = curAchievement + 1

        if curAchievement == #self.config_achievement_instance then
            isMaxLevel = true
        end
        if isMaxLevel then
            nextLevel = curAchievement
        end
        local curAchiCfg = self.config_achievement_instance[nextLevel]
        local currentAchi = self:GetCurInstanceScore()
        local remainder = currentAchi + num - curAchiCfg.condition
        if curAchiCfg.condition <= currentAchi + num then
            if isMaxLevel then
                self:SetCurInstanceScore(curAchiCfg.condition)
                GameTableDefine.InstanceMainViewUI:PlayMilestoneAnim()
                return
            else
                self:SetCurInstanceKSLevel(nextLevel)
                self:SetCurInstanceScore(0)
                self:AddScore(remainder)
            end
        else
            self:SetCurInstanceScore(currentAchi + num)
            GameTableDefine.InstanceMainViewUI:PlayMilestoneAnim()
            return
        end
    end
end
--[[
    @desc: 获取副本产品信息
    author:{author}
    time:2023-04-17 14:22:00
    --@productions: 
    @return:
]]
function InstanceDataManager:GetProdutionsData()

    if self.saveBaseData then
        if not self.saveBaseData.m_Productions then
            return {}
        else
            return self.saveBaseData.m_Productions
        end
    end
end

--[[
    @desc: 设置副本产品信息
    author:{author}
    time:2023-04-17 14:22:00
    --@productions: 
    @return:
]]
function InstanceDataManager:SetProdutionsData(productions)
    if not productions or next(productions) == nil then
        return
    end
    if self.saveBaseData then
        self.saveBaseData.m_Productions = productions
    end
    -- LocalDataManager:WriteToFile()
end

--[[
    @desc: 添加副本产品并保存数据
    author:{author}
    time:2023-05-06 10:14:18
    --@addProductions: {{1=100},{2=100}}
    @return:
]]
function InstanceDataManager:AddProdutionsData(addProductions)
    if not addProductions or next(addProductions) == nil then
        return
    end
    local productions = self:GetProdutionsData()
    for k,v in pairs(addProductions) do
        if v[k] then
            productions[tostring(k)] = (productions[tostring(k)] or 0) + v[k]
        end
    end
    self:SetProdutionsData(productions)
end

--[[
    @desc: 数据管理器进入副本的逻辑，这块逻辑上是由场景加载完成后调用
    author:{author}
    time:2023-03-24 10:08:35
    @return:
]]
function InstanceDataManager:EnterInstance()
    self:CalculateInstanceOfflineReward()
end


--[[
    @desc: 领取离线奖励
    author:{author}
    time:2023-04-24 11:08:40
    @return:
]]
function InstanceDataManager:GetOfflineReward()
    if self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = nil
    end
    self.m_CurDisplayOfflinesetTime = 0
end

function InstanceDataManager:GetMaxOfflineTime()
    local maxTime = 2 * 60 * 60
    if not GameTableDefine.InstanceModel:GetLandMarkCanPurchas() then
        maxTime = 4 * 60 * 60
    end
    return maxTime
end

function InstanceDataManager:GetCurOfflineDisplayTime()
    local time = 0
    if self.m_CurDisplayOfflinesetTime then
        return self.m_CurDisplayOfflinesetTime
    end
    if self.saveBaseData and self.saveBaseData.m_CurOfflineOffsetTime then 
        return self.saveBaseData.m_CurOfflineOffsetTime
    end
    return 0
end

function InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    local productions, money = GameTableDefine.InstanceModel:CalculateOfflineRewards(5000,false,true)
    local resultData = {}
    resultData.productions = productions
    resultData.rewardMoney = money

    return resultData
end

--[[
  @desc: 发放所有里程碑奖励了
    author:{author}
    time:2023-05-01 14:19:25
    --@eggRewards: 获得蛋的数据
    @return:
]]
function InstanceDataManager:OpenAllEggsRewardToGet(eggRewards,notFinalGet)
    if not eggRewards or Tools:GetTableSize(eggRewards) <= 0 then
        return
    end
    --shopID = times
    local onlyOneRewardList = {}
    self.eggsOpenRewards = {}
    for eggType, count in pairs(eggRewards) do
        local curTypeCfg = InstanceDataManager.config_rewardType_instance[eggType]
        local rewards = {}
        if curTypeCfg and Tools:GetTableSize(curTypeCfg) > 0 then
            for i = 1, count do
                local reward = {}
                local weights = {}
                local rewardIds = {}
                local totalWeight = 0
                local weigtIndexs = {}
                --step1收集权重以及对应的值
                for k, v in ipairs(curTypeCfg) do
                    if v.weight == 0 then
                        if v.limit > 0 then
                            -- table.insert(onlyOneRewardList, v.shop_id)
                            if not onlyOneRewardList[v.shop_id] then
                                onlyOneRewardList[v.shop_id] = 1
                            else
                                onlyOneRewardList[v.shop_id]  = onlyOneRewardList[v.shop_id] + 1
                            end
                        end
                        table.insert(reward, v.shop_id)
                    else
                        if v.limit > 0 then
                            local isHave = false
                            for shopID, amount in pairs(onlyOneRewardList) do
                                if shopID == v.shop_id and amount >= v.limit then
                                    isHave = true
                                end
                            end
                            if not isHave then
                                totalWeight  = totalWeight + v.weight 
                                table.insert(weights, v.weight)
                                table.insert(rewardIds, v.shop_id)
                                table.insert(weigtIndexs, k)
                            end
                        else
                            totalWeight  = totalWeight + v.weight
                            table.insert(weights, v.weight)
                            table.insert(rewardIds, v.shop_id)
                            table.insert(weigtIndexs, k)
                        end
                    end

                end
                if totalWeight > 0 then
                    local randValue = math.random(totalWeight)
                    for index, rand in ipairs(weights) do
                        local v = curTypeCfg[weigtIndexs[index]]
                        local shopID = rewardIds[index]
                        if index == 1 and randValue < rand then
                            if v.limit > 0 then
                                if not onlyOneRewardList[v.shop_id] then
                                    onlyOneRewardList[v.shop_id] = 1
                                else
                                    onlyOneRewardList[v.shop_id]  = onlyOneRewardList[v.shop_id] + 1
                                end
                            end
                            table.insert(reward, v.shop_id)
                            break
                        end
                        if index == Tools:GetTableSize(weights) and randValue >= rand then
                            if v.limit > 0 then
                                if not onlyOneRewardList[v.shop_id] then
                                    onlyOneRewardList[v.shop_id] = 1
                                else
                                    onlyOneRewardList[v.shop_id]  = onlyOneRewardList[v.shop_id] + 1
                                end
                            end
                            table.insert(reward, v.shop_id)
                            break
                        end
                        if weights[index-1] and randValue >= weights[index-1] and randValue < rand then
                            if v.limit > 0 then
                                if not onlyOneRewardList[v.shop_id] then
                                    onlyOneRewardList[v.shop_id] = 1
                                else
                                    onlyOneRewardList[v.shop_id]  = onlyOneRewardList[v.shop_id] + 1
                                end
                            end
                            table.insert(reward, v.shop_id)
                            break
                        end
                    end
                end
                
                table.insert(rewards, reward)
            end
        end
        local rewardData = {
            ["type"] = eggType,
            ["count"] = count,
            ["icon"] = "Icon_egg_" .. eggType,
            ["icon_broken"] = "Icon_egg_" .. tostring(eggType) .. "_broken",
            ["name"] = "TXT_INSTANCE_EasterEgg_" .. tostring(eggType),
            ["quality"] = "icon_egg_quality_" .. tostring(eggType),
            ["rewardList"] = rewards,
            ["getRewardList"] = {},
            ["rewardIsGet"] = false
        }
        for i = 1, Tools:GetTableSize(rewards) do
            table.insert(rewardData.getRewardList, false)
        end
        table.insert(self.eggsOpenRewards, rewardData)
    end
    for k, v in pairs(self.eggsOpenRewards) do
        for _, v1 in pairs(v.rewardList) do
            for _, shopID in pairs(v1) do
                local addDiamond = self:GetSameShopItemConverToDiamond(shopID)
                GameTableDefine.ShopManager:Buy(shopID, false, nil, nil)
                if addDiamond > 0 then
                    ResourceManger:AddDiamond(addDiamond)
                    if not self.haveConvertDiamondIDs then
                        self.haveConvertDiamondIDs = {}
                    end
                    table.insert(self.haveConvertDiamondIDs, shopID)
                end
                local shopCfg = configManager.config_shop[shopID]
                if shopCfg.type == 9 then
                    local resType = ResourceManger:GetShopCashType(shopCfg.country)
                    local num = GameTableDefine.FloorMode:GetTotalRent()
                    if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                        num = GameTableDefine.FloorMode:GetTotalRent(nil, 2)
                    end
                    
                    ResourceManger:Add(resType, num, nil, nil, true)
                end
            end
        end
    end
    if not notFinalGet then
        self.saveBaseData.m_IsGetCurReward = true
    end
    LocalDataManager:WriteToFile()
end

function InstanceDataManager:GetCurAllRewardData()
    return self.eggsOpenRewards
end

--获取一个专门转了钻石的物品的ID
function InstanceDataManager:SetConvertDiamondIDs(shop_id)
    if not self.haveConvertDiamondIDs then
        self.haveConvertDiamondIDs = {}
    end

    table.insert(self.haveConvertDiamondIDs, shop_id)
end

--获取一个专门转了钻石的物品的ID
function InstanceDataManager:GetConvertDiamondIDs()
    return self.haveConvertDiamondIDs or {}
end

function InstanceDataManager:GMOpenEggsReward()
    local eggRewards = {}
    eggRewards[1] = 3
    eggRewards[2] = 6
    eggRewards[3] = 7
    eggRewards[4] = 4
    self:OpenAllEggsRewardToGet(eggRewards)
end

function InstanceDataManager:InstanceShopBuySccess(shopID)
    local shopCfg = GameTableDefine.ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return
    end

    if 22 ~= shopCfg.type and 24 ~= shopCfg.type and 23 ~= shopCfg.type then
        return
    end

    if 22 == shopCfg.type then
        local calTime = 0
        if shopCfg.param and Tools:GetTableSize(shopCfg) > 0 and tonumber(shopCfg.param[1]) then
            calTime = tonumber(shopCfg.param[1]) * 60
        end
        if calTime <= 0 then
            return
        end
        local itemInfo = GameTableDefine.InstanceModel:GetCurProductionsByTime(calTime)
        local curResGetData = {}
        for k, v in ipairs(itemInfo) do
            local resEle = {}
            resEle[v.resourcesID] = v.amount
            curResGetData[v.resourcesID] = resEle
        end
        if Tools:GetTableSize(curResGetData) > 0 then
            self:AddProdutionsData(curResGetData)
        end
    end

    if 24 == shopCfg.type then
        self:AddCurInstanceCoin(shopCfg.amount)
    end

    if 23 == shopCfg.type then
        GameTableDefine.InstanceModel:ShowSpecialGameObject(true)
    end
end

function InstanceDataManager:SetInstanceOpenGiftMaxID(shopID)
    if self.saveBaseData and self.saveBaseData.curMaxGiftID then
        if self.saveBaseData.curMaxGiftID < shopID then
            self.saveBaseData.curMaxGiftID = shopID
        end
    else
        self.saveBaseData.curMaxGiftID = shopID
    end
    LocalDataManager:WriteToFile()
end

function InstanceDataManager:GetInstanceOpenGiftMaxID()
    return self.saveBaseData.curMaxGiftID or 0
end

--[[
    @desc: 清除对应的副本保存数据，对于新开活动需要重制保存的数据
    author:{author}
    time:2023-05-17 16:44:05
    @return:
]]
function InstanceDataManager:ClearSaveData()
    if not self.saveBaseData then
        self.saveBaseData = LocalDataManager:GetDataByKey("InstanceBase")
    end
    self.saveBaseData.m_IsGetCurReward = false
    self.saveBaseData.m_RoomData = {}
    self.saveBaseData.m_CurKSLevel = 0
    --self.saveBaseData.m_CurInstanceCoin = 0 -- configManager.config_global.instance_cash
    LocalDataManager:EncryptField(self.saveBaseData,CoinFieldName,0)
    --self.saveBaseData.m_CurScore = 0
    LocalDataManager:EncryptField(self.saveBaseData,ScoreFieldName,0)
    self.saveBaseData.m_CurLastOfflineTime = 0
    self.saveBaseData.m_CurOfflineOffsetTime = 0
    self.saveBaseData.m_AddBuffData = {}
    self.saveBaseData.m_Productions = {}
    self.saveBaseData.curMaxGiftID = 0
    self.saveBaseData.m_CurEnterTime = 0
    self.saveBaseData.m_Guide = nil
    self.saveBaseData.m_task = nil
    self.saveBaseData.m_ObtainRewards = {}
    GameTableDefine.InstanceTaskManager:ClearTaskData()

    -- 清空购买记录
    local shopSaveData = LocalDataManager:GetDataByKey("shop")
    if shopSaveData and shopSaveData.times then
        for _, v in pairs(self.config_shop_frame_instance) do
            if v.frame == "frame4" then
                for i=1, #v.content do
                    if shopSaveData.times[""..v.content[i].shopID] then
                        shopSaveData.times[""..v.content[i].shopID] = 0
                    end
                end
                break
            end
        end
    end
    self:ClearLandMarkBuyRecord()
end

function InstanceDataManager:CanDisplayEnterUI()
    if GameTableDefine.StarMode:GetStar() < 4 then
        return false
    end
    if self:GetInstanceIsActive() or self:GetInstanceRewardIsActive() then
        if not GameTableDefine.FloorMode:IsInOffice() or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CITY_MAP) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.EUROPE_MAP_UI) then
            return false
        end
        if GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_PACK_UI) then
            return false
        end
        local now = GameTimeManager:GetCurrentServerTime()
        if not self.saveBaseData.m_CurEnterTime or self.saveBaseData.m_CurEnterTime == 0 then
            self.saveBaseData.m_CurEnterTime = now
            LocalDataManager:WriteToFile()
            return true
        end

        local today = os.date("%d", now)
        local last = os.date("%d", self.saveBaseData.m_CurEnterTime)

        if today ~= last then
            self.saveBaseData.m_CurEnterTime = now
            return true
        end
    end
    return false
end

function InstanceDataManager:RefreshAutoDisplayEntryTime()
    if self.saveBaseData and self.saveBaseData.m_CurEnterTime and self.saveBaseData.m_CurEnterTime > 0 then
        self.saveBaseData.m_CurEnterTime = 0
    end
end

function InstanceDataManager:SetNoRewardFlag()
    if self.saveBaseData then
        self.saveBaseData.m_IsGetCurReward = true
        LocalDataManager:WriteToFile()
    end
end

function InstanceDataManager:GetGuideID()
    if self.saveBaseData then
        return self.saveBaseData.m_Guide
    end
    return nil
end 

function InstanceDataManager:SetGuideID(value)
    if self.saveBaseData then
        self.saveBaseData.m_Guide = value
        LocalDataManager:WriteToFile()
    end
end 

function InstanceDataManager:GetEventData()
    if self.saveBaseData then
        if not self.saveBaseData.m_Event then
            local now = GameTimeManager:GetCurrentServerTime(true)
            local curDay = GameTimeManager:GetTimeLengthDate(now).d
            self.saveBaseData.m_Event = {}
            self.saveBaseData.m_Event.day = curDay
            self.saveBaseData.m_Event.count = 0
            self.saveBaseData.m_Event.lastTime = 0
        end
        return self.saveBaseData.m_Event
    end
    return nil
end

function InstanceDataManager:AddEventTime()
    if self.saveBaseData then
        self.saveBaseData.m_Event = self:GetEventData()
        local now = GameTimeManager:GetCurrentServerTime(true)
        local curDay = GameTimeManager:GetTimeLengthDate(now).d
        if curDay ~= self.saveBaseData.m_Event.day then
            self.saveBaseData.m_Event.count = 0
        end
        self.saveBaseData.m_Event.count = self.saveBaseData.m_Event.count + 1
        self.saveBaseData.m_Event.lastTime = now
        LocalDataManager:WriteToFile()
    end
end

function InstanceDataManager:IsConvertShopItem(shopID)
    for k, v in pairs(self.haveConvertDiamondIDs or {}) do
        if v == shopID and self:GetSameShopItemConverToDiamond(v) then
            return true
        end
    end
    return false
end
function InstanceDataManager:GetSameShopItemConverToDiamond(shopId)
    local backDiamond = 0
    local currCfg = GameTableDefine.ShopManager:GetCfg(shopId)
    if currCfg and GameTableDefine.ShopManager:BoughtBefor(shopId) then 
        --增加单个商品购买时判断是否转钻石
        if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
            backDiamond = backDiamond + currCfg.param2[1]
        elseif currCfg.type == 6 or currCfg.type == 7 then--npc
            backDiamond = backDiamond + currCfg.param[1]
        elseif currCfg.type == 5 then--免广告
            backDiamond = backDiamond + currCfg.param[1]
        end
        
    end
    return backDiamond
end

function InstanceDataManager:GetInstanceBind()
    return self.config_instance_bind[self.saveBaseData.m_Instance_id or 1]
end 

function InstanceDataManager:ClearLandMarkBuyRecord()
    local shopData = LocalDataManager:GetDataByKey("shop")
    local instanceBind = self.config_instance_bind[self.saveBaseData.m_Instance_id or 1]
    shopData.times[""..instanceBind.landmark_id] = nil
    LocalDataManager:WriteToFile()

end

function InstanceDataManager:IsLastOneDay()
    local timeRemaining = nil
    if self.instanceState.isActive == self:GetInstanceState() then
        timeRemaining = self:GetLeftInstanceTime()
        if timeRemaining <= 3600 * 24 then
            return true
        end
    else
        return false
    end
end

function InstanceDataManager:GetLastOneDayDiscount()
    return configManager.config_global.instance_offvalue or 0
end