---处理网络数据, 初始化副本, 统一管理副本的生命周期
---@class CycleInstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local configManager = GameTableDefine.ConfigMgr
local LocalDataManager = LocalDataManager
local Application = CS.UnityEngine.Application
local MainUI = GameTableDefine.MainUI
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local GameTimeManager = GameTimeManager
local GameTools = GameTools
local DeeplinkManager = GameTableDefine.DeeplinkManager

local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local ActivityRemoteConfigManager = GameTableDefine.ActivityRemoteConfigManager

CycleInstanceDataManager.instanceState = {
    overtime = 1,   --已超时/未开启
    isActive = 2,   --解锁后/活动中
    awartable =3,   --可领奖
    isPreview = 4,  --预告

}

function CycleInstanceDataManager:ctor()
    self.m_instanceModel = nil ---@type CycleInstanceModelBase 正在运行的Model
end

function CycleInstanceDataManager:Init()
    self:DeclareVariable()
    self.saveBaseData = LocalDataManager:GetDataByKey("CycleInstance")
    if not self.saveBaseData then   -- 避免在LocalDataManager初始化之前就调用导致的报错
        return
    end
    self:ControlStartAndStopOfInstance()

    --检测一次数据表配置的内容，如果配置表中没有对应的副本配置数据,先把存档的无效数据删除，避免配置出错导致进不了游戏2024-7-22,fy
    if self.saveBaseData then
        for k, v in pairs(self.saveBaseData) do
            if not self.config_instance_bind[tonumber(k)] then
                self.saveBaseData[k] = nil
            end
        end
    end

    GameTools:AddTimePoint("CycleInstanceDataManager:Init()")
    --如果检测到本地副本活动中或者领奖结算中
    local curActiveInstanceID = self:GetCurActivityInstance()
    local isRunSaveDataActive = false
    if curActiveInstanceID then
        isRunSaveDataActive = true

        local instance_data = self.saveBaseData[tostring(self.instance_id)]
        if not instance_data.m_InstanceEnable then
            GameTableDefine.ActivityRemoteConfigManager:CheckCycleInstanceEnable()
        end
    end
    GameTools:CalcTimePointCost("CycleInstanceDataManager:Init()")
    if isRunSaveDataActive then
        self:InitModel(self.instance_id)
    else -- 当前既没有deeplink开启的副本, 也没有运营活动开启的副本
        local dpData = DeeplinkManager:HaveActiveInstance()
        if dpData then
            self:DeeplinkOpenInstanceActivity(dpData)
        else
            --step2.如果本地没有活动数据，或者时间已经操过当次活动的奖励领取结算时间了，再次请求服务器是否有活动
            --print("InstanceDataManager====================================================================================")

            GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = 1, desc = "请求SDK获取活动数据" })

            GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.CycleInstanceActivity)
        end
        
    end
end

function CycleInstanceDataManager:InitModel(instance_id)
    local modelClass = require(CycleInstanceDefine.InstanceClass[tonumber(instance_id)].Model)
    self.m_instanceModel = modelClass.new()
    self.m_instanceModel:Init(self.saveBaseData[tostring(instance_id)])

    -- 初始化排行榜
    local rankManagerClass = CycleInstanceDefine.InstanceClass[tonumber(instance_id)].Rank
    if rankManagerClass then
        rankManagerClass:Init(self.saveBaseData[tostring(instance_id)])
    end
end

function CycleInstanceDataManager:OnPause()
    if self.m_instanceModel then
        self.m_instanceModel:OnPause()
    end
end

function CycleInstanceDataManager:OnResume()
    if self.m_instanceModel then
        self.m_instanceModel:OnResume()
    end
end

---声明变量的方法,所有的变量再次声明,单纯为了查找变量方便
function CycleInstanceDataManager:DeclareVariable()
    self.instance_id = nil   ---@type number
    self.activeInstance = nil --活动中的副本
    self.saveBaseData = nil --副本存档数据
    self.instanceTable = {}
    self.config_instance_bind = configManager.config_instance_bind
    self.remoteAwardData = nil
end

function CycleInstanceDataManager:ControlStartAndStopOfInstance()
    
end

---处理warriorSDK请求的返回数据内容
function CycleInstanceDataManager:ProcessSDKCallbackData(warriorMsgData)
    if not warriorMsgData then return end
    if tonumber(warriorMsgData.activityType) ~= TimeLimitedActivitiesManager.CycleInstanceActivity then
        return
    end

    GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = 5, desc = "循环副本，数据解析开始" })

    --instanceID 为每次开启活动时自增的id序号; instance_id 为活动类型ID,其不随活动的反复开启而变化
    --joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ",instance_id = "this.instance_id +"+ ",duration = "this.duration +", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
    local previewTime = tonumber(warriorMsgData.previewTime)
    local startTime = tonumber(warriorMsgData.startTime)
    -- warrior 把結算時間當作最後的活動結束時間，settlementTime > endTime by Gxy 2023/12/13, 
    -- 受碎片活动的影响再把这里反一遍 by gxy 2024-10-24 14:52:42
    local endTime = tonumber(warriorMsgData.endTime)
    local rewardTime = tonumber(warriorMsgData.settlementTime)
    
    local instanceID = tonumber(warriorMsgData.instanceID)
    local id = tostring(warriorMsgData.instance_id)

    --local duration = warriorMsgData.duration * 3600
    if not startTime or not endTime or not rewardTime or not instanceID then
        GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = -1, desc = "循环副本，时间、instanceID参数不全" })
        return
    end

    if self.saveBaseData[id] and self.saveBaseData[id].m_InstanceID == instanceID then
        GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = -2, desc = "循环副本，instanceID重复" })
        return
    end

    local now = GameTimeManager:GetTheoryTime()
    if previewTime > startTime or startTime > endTime or endTime < now or rewardTime > endTime or rewardTime < now then
        GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = -3, desc = "循环副本，时间不对" })
        return
    end
    self:InitRemoteRewardCfg(warriorMsgData)

    -- 获取到新的副本数据, 初始化副本Model
    self.saveBaseData[id] = {}

    --self.instance_id = tonumber(warriorMsgData.instance_id) -- SDK传过来的时字符串
    self.saveBaseData[id].m_IsDeeplink = false
    
    self.saveBaseData[id].m_previewTime = previewTime
    self.saveBaseData[id].m_StartTime = startTime
    self.saveBaseData[id].m_EndTime = rewardTime    
    self.saveBaseData[id].m_RewardOverTime = endTime
    self.saveBaseData[id].m_InstanceID = instanceID
    self.saveBaseData[id].m_Instance_id = tonumber(warriorMsgData.instance_id)
    self.saveBaseData[id].m_RemoveAwardData = self.remoteAwardData
    self.saveBaseData[id].m_tag = warriorMsgData.tag

    if not warriorMsgData.open_conditions or #warriorMsgData.open_conditions ~= 1 or math.floor(tonumber(warriorMsgData.open_conditions[1].type)) ~= ActivityRemoteConfigManager.ActivityEnableType.SCENE then -- 副本只有一个配置条件，且只能是场景条件，否则默认2号场景开启
        warriorMsgData.open_conditions = {
            { type = ActivityRemoteConfigManager.ActivityEnableType.SCENE, value = 2, compareType = ActivityRemoteConfigManager.CompareValueType.GTE }
        }
    end
    
    self.saveBaseData[id].open_conditions = warriorMsgData.open_conditions   -- 开启条件
    self.saveBaseData[id].m_InstanceEnable = nil -- 拉到新活动时，重置开启状态

    self.saveBaseData[id].m_cyInstanceGiftsConfigs = warriorMsgData.instance_gift
    self.saveBaseData[id].m_cyInstanceRankAwardConfigs = warriorMsgData.instance_rank -- 排行榜奖励远程配置

    LocalDataManager:WriteToFile()

    if self:GetInstanceIsActive(tonumber(warriorMsgData.instance_id)) or self:GetInstanceRewardIsActive(tonumber(warriorMsgData.instance_id)) then
        self.instance_id = tonumber(warriorMsgData.instance_id) -- SDK传过来的时字符串
        self:InitModel(self.instance_id)
    end
    
    --GameTableDefine.ConfigMgr:ReloadConfig(warriorMsgData.tag)

    --MainUI:RefreshInstanceentrance()
    GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = 6, desc = "循环副本，数据解析完成" })
    
    GameTableDefine.ActivityRemoteConfigManager:CheckCycleInstanceEnable()

    GameSDKs:TrackForeign("warrior_get_activity_data", { activityType = TimeLimitedActivitiesManager.CycleInstanceActivity, step = 7, desc = "循环副本，开启条件判断完成" })
end

-- 根据副本开启条件，判断副本是否开启
function CycleInstanceDataManager:SetInstanceEnable()
    local saveData = self.saveBaseData[tostring(self.instance_id)]
    if saveData then
        saveData.m_InstanceEnable = true
    end
end

-- 根据副本开启条件，判断副本是否开启
function CycleInstanceDataManager:GetInstanceEnable()
    local saveData = self.saveBaseData[tostring(self.instance_id)]
    if saveData then
        return saveData.m_InstanceEnable
    end

    return false
end

-- 副本开启条件
function CycleInstanceDataManager:GetInstanceOpenCondition()
    if not self.instance_id then
        return false
    end

    local saveData = self.saveBaseData[tostring(self.instance_id)]
    if not saveData then
        return false
    end

    return saveData.open_conditions
end

-- 副本活动是否在预告
function CycleInstanceDataManager:GetInstanceIsPreview(id)
    local instance_id = id or self.instance_id
    if not instance_id then
        return false
    end
    instance_id = tostring(instance_id)
    local saveData = self.saveBaseData[instance_id]
    if not saveData then
        return false
    end
    local now = GameTimeManager:GetTheoryTime()
    local startTime = saveData.m_StartTime
    local previewTime = saveData.m_previewTime or math.maxinteger
    if previewTime <= now and now < startTime then
        return true
    else
        return false
    end
end

---副本活动是否还在进行中 
function CycleInstanceDataManager:GetInstanceIsActive(id)
    local instance_id = id or self.instance_id
    if not instance_id then
        return false
    end
    instance_id = tostring(instance_id)
    local saveData = self.saveBaseData[instance_id]
    --local endTime = self.saveBaseData[instance_id] and self.saveBaseData[instance_id].m_EndTime
    if not saveData then
        return false
    end
    local now = GameTimeManager:GetTheoryTime()
    local endTime = saveData.m_EndTime
    if not endTime or endTime < now then
        return false
    end
    local startTime = saveData.m_StartTime
    if startTime <= now and endTime > now then
        return true
    end
    --CS.UnityEngine.Debug.LogWarning("save:" .. (save and save.m_Instance_id or "nil") .. "    endTime:" .. (endTime or "nil") .. "    timeOver:" .. tostring(timeOver) .. "    now:" .. tostring(now) .. "\n" .. debug.traceback())
    return false
end

---当前是否在奖励结算中
function CycleInstanceDataManager:GetInstanceRewardIsActive(instance_id)
    instance_id = instance_id or self.instance_id
    instance_id = tostring(instance_id)
    if self:GetInstanceIsActive(instance_id) then
        return false
    end
    local saveData = self.saveBaseData[instance_id]
    if not saveData then
        return false
    end
    local rewardTime = saveData.m_RewardOverTime
    if not rewardTime then
        return false
    end
    local endTime = saveData.m_EndTime
    if not endTime then
        return false
    end
    local now = GameTimeManager:GetTheoryTime()
    if endTime < now and rewardTime > now then
        if not saveData.m_IsGetCurReward or (GameTableDefine.CycleNightClubRankManager:IsInit() and #GameTableDefine.CycleNightClubRankManager:GetRankReward() > 0) then
            return true
        end
    end

    return false
end

function CycleInstanceDataManager:GMOpenInstanceActivity(openMin, id, previewMin)
    local activityTime = openMin or 5
    self.instance_id = id
    id = tostring(id)
    self.saveBaseData[id] = {} 
    if previewMin then
        self.saveBaseData[id].m_previewTime = math.floor(GameTimeManager:GetTheoryTime())
    end
    self.saveBaseData[id].m_IsDeeplink = false
    self.saveBaseData[id].m_StartTime = math.floor(GameTimeManager:GetTheoryTime()) + ((previewMin and previewMin * 60) or 0)
    self.saveBaseData[id].m_EndTime = self.saveBaseData[id].m_StartTime + (activityTime * 60) + ((previewMin and previewMin * 60) or 0)
    self.saveBaseData[id].m_RewardOverTime = self.saveBaseData[id].m_EndTime + (5 * 60) + ((previewMin and previewMin * 60) or 0)
    self.saveBaseData[id].m_InstanceID = 1
    self.saveBaseData[id].m_Instance_id = id
    LocalDataManager:WriteToFile()
    GameTableDefine.CheatUI:CloseView()
    self:InitModel(self.instance_id)

    GameTableDefine.ActivityRemoteConfigManager:CheckCycleInstanceEnable()
end

---@param dpData DeeplinkData
function CycleInstanceDataManager:DeeplinkOpenInstanceActivity(dpData)
    local activityTime = dpData.endtime or 24
    local rewardTime = dpData.settlementtime or 1
    self.instance_id = dpData.instance_id
    local id = tostring(dpData.instance_id)
    self.saveBaseData[id] = {}
    if previewMin then
        self.saveBaseData[id].m_previewTime = math.floor(GameTimeManager:GetTheoryTime())
    end
    self.saveBaseData[id].m_IsDeeplink = true
    self.saveBaseData[id].m_StartTime = math.floor(GameTimeManager:GetTheoryTime()) + ((previewMin and previewMin * 60) or 0)
    self.saveBaseData[id].m_EndTime = self.saveBaseData[id].m_StartTime + (activityTime * 3600) + ((previewMin and previewMin * 60) or 0)
    self.saveBaseData[id].m_RewardOverTime = self.saveBaseData[id].m_EndTime + (rewardTime * 3600) + ((previewMin and previewMin * 60) or 0)
    --self.saveBaseData[id].m_InstanceID = 1
    self.saveBaseData[id].m_Instance_id = id
    LocalDataManager:WriteToFile()
    GameTableDefine.CheatUI:CloseView()
    self:InitModel(self.instance_id)
end

function CycleInstanceDataManager:GetInstanceBind(instance_id)
    local curActivityInstance = instance_id or self.instance_id or self:GetCurActivityInstance()
    return self.config_instance_bind[tonumber(curActivityInstance) or 4]
end

function CycleInstanceDataManager:GetCurActivityInstance()
    for k,v in pairs(self.saveBaseData) do
        if self:GetInstanceIsActive(k) or self:GetInstanceRewardIsActive(k) then
            self.instance_id = tonumber(k)
            return k
        end
    end
end

--- 获取正在提前预览的副本
function CycleInstanceDataManager:GetCurPreviewInstance()
    for k,v in pairs(self.saveBaseData) do
        if self:GetInstanceIsPreview(k) then
            return Tools:CopyTable(v)
        end
    end
end

function CycleInstanceDataManager:CheckCanOpen()
    local model = self:GetCurActivityInstance()
    return model and self:GetCurrentModel():CanDisplayEnterUI()
end

--region 为了让MainView运行起来添加的


--获取活动状态
function CycleInstanceDataManager:GetInstanceState(instance_id)
    if self:GetInstanceIsPreview(instance_id) then
        return self.instanceState.isPreview
    end
    if self:GetInstanceIsActive(instance_id) then
        return self.instanceState.isActive
    end
    if self:GetInstanceRewardIsActive(instance_id) then
        return self.instanceState.awartable
    end

    --解锁状态是进入时检测的一个条件不应感作为副本的一个状态出现
    return self.instanceState.overtime
end

---副本活动开启剩余时间，0就是活动已经结束或者没有活动
---@return number 返回当前副本活动剩余时间，秒计
function CycleInstanceDataManager:GetLeftInstanceTime(instance_id)
    instance_id = instance_id or self:GetInstanceBind().id
    instance_id = tostring(instance_id)
    local saveData = self.saveBaseData[instance_id]
    local now = GameTimeManager:GetTheoryTime()
    if saveData and saveData.m_StartTime and saveData.m_EndTime and saveData.m_EndTime - saveData.m_StartTime > 0 and saveData.m_EndTime - now > 0 then
        return math.floor(saveData.m_EndTime - now)
    end
    return 0
end

--[[
    @desc: 返回当前副本活动结束时间，秒计
    author:{author}
    time:2023-03-20 20:27:44
    @return:副本活动开启结束时间，0就是活动已经结束或者没有活动
]]
function CycleInstanceDataManager:GetInstanceEndTime()
    local instance_id = tostring(self:GetInstanceBind().id)
    local saveData = self.saveBaseData[instance_id]
    if saveData.m_EndTime then
        return saveData.m_EndTime
    end

    return 0
end


---返回当前活动剩余时间,按秒计算，如果当前活动在继续中则返回0
function CycleInstanceDataManager:GetInstanceRewardTime(instance_id)
    instance_id = instance_id or self:GetInstanceBind().id
    instance_id = tostring(instance_id)
    local saveData = self.saveBaseData[instance_id]
    local now = GameTimeManager:GetTheoryTime()
    if saveData.m_EndTime and saveData.m_EndTime > now then
        return 0
    end
    if saveData.m_RewardOverTime and saveData.m_RewardOverTime > now then
        return math.floor(saveData.m_RewardOverTime - now)
    end
    return 0
end
--endregion

---将某个副本标记为没有奖励领取，不要显示
function CycleInstanceDataManager:SetNoRewardFlag(instance_id)
    instance_id = instance_id or self:GetInstanceBind().id
    instance_id = tostring(instance_id)
    local saveData = self.saveBaseData[instance_id]
    if saveData then
        saveData.m_IsGetCurReward = true
        LocalDataManager:WriteToFile()
    end
end

---@return CycleInstanceModelBase
function CycleInstanceDataManager:GetCurrentModel()
    if not self.m_instanceModel then
        self:Init()
    end
    return self.m_instanceModel
end
function CycleInstanceDataManager:GetTrackUseCurrentModel()
    return self.m_instanceModel
end
function CycleInstanceDataManager:GetCycleInstanceMilepostUI(instance_id)
    if not instance_id then
        if not self.m_instanceModel then
            printError("没有对m_instanceModel初始化")
            return nil
        end
        instance_id = self.m_instanceModel.instance_id
    end
    if instance_id == 4 then
        return GameTableDefine.CycleInstanceMilepostUI
    elseif instance_id == 5 then
        return GameTableDefine.CycleCastleMilepostUI
    elseif instance_id == 6 then
        return GameTableDefine.CycleToyMilepostUI
    elseif instance_id == 7 then
        return GameTableDefine.CycleNightClubMilepostUI
    end
    return nil
end

function CycleInstanceDataManager:GetCycleInstanceUI()
    if not self.m_instanceModel then
        printError("没有对m_instanceModel初始化")
        return nil
    end
    if self.m_instanceModel.instance_id == 4 then
        return GameTableDefine.CycleIslandViewUI
    elseif self.m_instanceModel.instance_id == 5 then
        return GameTableDefine.CycleCastleViewUI
    elseif self.m_instanceModel.instance_id == 6 then
        return GameTableDefine.CycleToyViewUI
    elseif self.m_instanceModel.instance_id == 7 then
        return GameTableDefine.CycleNightClubViewUI
    end
    return nil
end

function CycleInstanceDataManager:GetCycleInstanceMainViewUI()
    if not self.m_instanceModel then
        printError("没有对m_instanceModel初始化")
        return nil
    end
    if self.m_instanceModel.instance_id == 4 then
        return GameTableDefine.CycleIslandMainViewUI
    elseif self.m_instanceModel.instance_id == 5 then
        return GameTableDefine.CycleCastleMainViewUI
    elseif self.m_instanceModel.instance_id == 6 then
        return GameTableDefine.CycleToyMainViewUI
    elseif self.m_instanceModel.instance_id == 7 then
        return GameTableDefine.CycleNightClubMainViewUI
    end
    return nil
end

function CycleInstanceDataManager:GetCycleInstanceADUI()
    if not self.m_instanceModel then
        printError("没有对m_instanceModel初始化")
        return nil
    end
    if self.m_instanceModel.instance_id == 4 then
        return GameTableDefine.CycleInstanceAdUI
    elseif self.m_instanceModel.instance_id == 5 then
        return GameTableDefine.CycleCastleAdUI
    elseif self.m_instanceModel.instance_id == 6 then
        return GameTableDefine.CycleToyAdUI
    elseif self.m_instanceModel.instance_id == 7 then
        return GameTableDefine.CycleNightClubAdUI
    else
        return GameTableDefine.CycleInstanceAdUI
    end
    return nil
end

---离线推送
function CycleInstanceDataManager:SendNotification()

    local now = GameTimeManager:GetTheoryTime()
    --1.副本开始
    do
        for k,v in pairs(self.saveBaseData) do
            if v.m_StartTime > now then
                local title = GameTextLoader:ReadText("TXT_INSTANCE_Notify_open_title")
                local content = GameTextLoader:ReadText("TXT_INSTANCE_Notify_open_desc")
                local countdown = v.m_StartTime - now
                GameDeviceManager:AddNotification(title, countdown, content,nil,2001)
                break
            end
        end
    end
    --2.副本结束
    do
        for k,v in pairs(self.saveBaseData) do
            if v.m_CurKSLevel and v.m_CurKSLevel > 0 then
                if v.m_StartTime < now and v.m_EndTime > now then
                    local title = GameTextLoader:ReadText("TXT_INSTANCE_Notify_over_title")
                    local content = GameTextLoader:ReadText("TXT_INSTANCE_Notify_over_desc")
                    local countdown = v.m_EndTime - now
                    GameDeviceManager:AddNotification(title, countdown, content,nil,2002)
                    break
                end
            end
        end
    end

    --3,4
    if self.m_instanceModel then
        self.m_instanceModel:SendNotification()
    end
end

---@class CycleInstanceRemoteAward
---@field level number
---@field shop_id number
---@field count number
---@field sp_sign boolean
---@field experience string
local CycleInstanceRemoteAward

function CycleInstanceDataManager:InitRemoteRewardCfg(warriorMsgData)
    local rewards = warriorMsgData.awards
    if (not rewards) or #rewards <= 0 then
        return
    end
    self.remoteAwardData = {}
    for k, v in pairs(rewards) do
        local data = string:split(v, ",", true)
        ---@type CycleInstanceRemoteAward

        local level = data[1]
        local shop_id = data[2]
        local count = data[3]
        local sp_sign = data[4]
        local remoteAwardData = GameTableDefine.ConfigMgr.config_cy_instance_reward[math.floor(warriorMsgData.instance_id)][level] or {}
        remoteAwardData.level = level
        remoteAwardData.shop_id = shop_id
        remoteAwardData.count = count
        remoteAwardData.sp_sign = sp_sign
        self.remoteAwardData[remoteAwardData.level] = remoteAwardData
    end
end
