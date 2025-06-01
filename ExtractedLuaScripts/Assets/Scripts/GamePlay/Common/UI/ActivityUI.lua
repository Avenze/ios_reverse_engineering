local ActivityUI = GameTableDefine.ActivityUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local EventManager = require("Framework.Event.Manager")
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local TimerMgr = GameTimeManager
local CfgMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
function ActivityUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ACTIVITY_UI, self.m_view, require("GamePlay.Common.UI.ActivityUIView"), self, self.CloseView)
    return self.m_view
end

function ActivityUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ACTIVITY_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ActivityUI:Init()
    local activity = LocalDataManager:GetDataByKey("activity")
    if activity.timePoint == nil then
        activity.timePoint = TimerMgr:GetCurrentServerTime(true)
    end
    self.Timer = GameTimer:CreateNewTimer(1, function()
        self:Update()
    end, true, true)
end


function ActivityUI:Update()
    local activity = LocalDataManager:GetDataByKey("activity")
    --2025-1-5fy修改用新的封装的函数判断刷新
    --step1.不是同一天
    if not TimerMgr:IsSameDay(activity.timePoint,TimerMgr:GetCurrentServerTime(true)) then
        --step2是不是夸周一了，周任务刷新
        if TimerMgr:IsUpdateMonday(activity.timePoint, TimerMgr:GetCurrentServerTime(true)) then
            activity.timePoint = TimerMgr:GetCurrentServerTime(true)
            ActivityUI:ClearWeeklyActivity()
            self:ClearDayActivity()
            if self.m_view then
                self.m_view:Invoke("Init")
                self.m_view:Invoke("Refresh")
            end
            MainUI:RefreshActivityHint()
            return
        end
        activity.timePoint = TimerMgr:GetCurrentServerTime(true)
        self:ClearDayActivity()
        if self.m_view then
            self.m_view:Invoke("Init")
            self.m_view:Invoke("Refresh")
        end
        MainUI:RefreshActivityHint()
    end
    -- if math.floor(activity.timePoint / 86400) ~= math.floor(TimerMgr:GetCurrentServerTime(true) / 86400) then --86400
    --     -- 这里计算周的时候+259200是因为时间戳是从1970/1/1开始计算的, 当天为周四, 加三天的时间好算周数
    --     local originalWeek = math.floor((activity.timePoint + 259200) / 604800) --604800
    --     local currentWeek = math.floor((TimerMgr:GetCurrentServerTime(true) + 259200) / 604800)
    --     if originalWeek ~= currentWeek then
    --         activity.timePoint = TimerMgr:GetCurrentServerTime(true)
    --         ActivityUI:ClearWeeklyActivity()
    --         if self.m_view then
    --             self.m_view:Invoke("Init")
    --             self.m_view:Invoke("Refresh")
    --         end
    --         MainUI:RefreshActivityHint()
    --         return
    --     end
    --     activity.timePoint = TimerMgr:GetCurrentServerTime(true)
    --     self:ClearDayActivity()
    --     if self.m_view then
    --         self.m_view:Invoke("Init")
    --         self.m_view:Invoke("Refresh")
    --     end
    --     MainUI:RefreshActivityHint()
    -- end
end

--计算一天的倒计时或者周
function ActivityUI:CountDownToTheDay(type)
    local cfg =  CfgMgr.config_global   
    if type == "day" or nil then
        -- local dayTime = (TimerMgr:GetCurrentServerTime(true) + ((cfg.daily_reset - 8) * 3600)) % 86400 -- 修正时间差
        -- return (86400 - dayTime)
        return TimerMgr:SecondsUntilTomorrow(TimerMgr:GetCurrentServerTime(true))
        
    elseif type == "week" then
        -- local weekTime = (TimerMgr:GetCurrentServerTime(true) + ((cfg.daily_reset - 8) * 28800) + 259200) % 604800 --修正时间差调整为周一
        -- return (604800 - weekTime) 
        return TimerMgr:SecondsUntilNextMonday(TimerMgr:GetCurrentServerTime(true))        
    end    
end

--清空周的活跃度
function ActivityUI:ClearWeeklyActivity()
    local activity = LocalDataManager:GetDataByKey("activity")
    local cfgActivityReward = self:GetActivityReward()
    if not activity.weekActivity then 
        activity.weekActivity = 0
    end
    activity.weekActivity = 0    
    for k,v in pairs(cfgActivityReward.week) do
        if not activity.gift then
            activity.gift = {}
            activity.gift[tostring(v.id)] = true
        else
            activity.gift[tostring(v.id)] = true
        end        
    end
    self:ClearDayActivity()
    LocalDataManager:WriteToFile()    
end

--清空天的活跃度
function ActivityUI:ClearDayActivity()
    local activity = LocalDataManager:GetDataByKey("activity")
    local cfgActivityReward = self:GetActivityReward()
    local cfgActivity = CfgMgr.config_activity
    if not activity.dayActivity then 
        activity.dayActivity = 0
    end
    activity.dayActivity = 0
    activity.value = {}
    for k,v in pairs(cfgActivityReward.day) do
        if not activity.gift then
            activity.gift = {}
            activity.gift[tostring(v.id)] = true
        else
            activity.gift[tostring(v.id)] = true
        end        
    end
    for k,v in pairs(cfgActivity) do
        activity[tostring(v.id)] = 0
    end
    LocalDataManager:WriteToFile()    
end

--获取天活跃度
function ActivityUI:GetDayActivity()
    local activity = LocalDataManager:GetDataByKey("activity")
    if not activity.dayActivity then 
        activity.dayActivity = 0
    end   
    LocalDataManager:WriteToFile()
    return activity.dayActivity
end

--获取周活跃度
function ActivityUI:GetWeeklyActivity()
    local activity = LocalDataManager:GetDataByKey("activity")
    if not activity.weekActivity then 
        activity.weekActivity = 0
    end
    LocalDataManager:WriteToFile()
    return activity.weekActivity
end

--获取指定的事件的活跃度
function ActivityUI:GetEventNum(activityId)
    local activity = LocalDataManager:GetDataByKey("activity")   
    LocalDataManager:WriteToFile()
    return activity[tostring(activityId)] or 0
end

--增加事件的累计次数
function ActivityUI:AddActivityData(activityId)
    local cfg = CfgMgr.config_activity
    local activityNum = nil
    local activity = LocalDataManager:GetDataByKey("activity")    
    for k,v in pairs(cfg) do
       if activityId == v.id then
            activityNum = activityId
            break
       end 
    end
    if activityNum == nil then 
        return
    end
    if not activity[tostring(activityNum)] then
        activity[tostring(activityNum)] = 0
    end
    if activity[tostring(activityNum)] >= cfg[activityNum].threhold then
        return
    end 
    activity[tostring(activityNum)] = activity[tostring(activityNum)] + 1   
    LocalDataManager:WriteToFile()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.ACTIVITY_UI) then
        self:GetView():Invoke("Refresh")
    end
    MainUI:RefreshActivityHint()--活跃度的红点
end

--增加周与天的活跃度
function ActivityUI:AddDWActivity(num)
    local activity = LocalDataManager:GetDataByKey("activity")
    if not activity.dayActivity then
        activity.dayActivity = 0
    end
    if not activity.weekActivity then
        activity.weekActivity = 0
    end
    activity.dayActivity = activity.dayActivity + num
    activity.weekActivity = activity.weekActivity + num
    LocalDataManager:WriteToFile()
end

--检测特定事件的发生
function ActivityUI:CheckSpecificEvent()
    EventManager:RegEvent("ADD_ACTIVITY_DATA", function(activityId)
        ActivityUI:AddActivityData(activityId)
    end);
end

--获取存档中某种礼物的存档 type(活跃度礼物,还是奖品礼物)
function ActivityUI:GetActivityData(type, id , spend)
    local activity = LocalDataManager:GetDataByKey("activity")
    id = tostring(id)
    if type == "value" then
        if not activity.value then
            activity.value = {}
        end
        if activity.value[id] == nil then
            activity.value[id] = true
        end
        if spend then
            activity.value[id] = false
        end
        LocalDataManager:WriteToFile()      
        return activity.value[id]
    elseif type == "gift" then
        if not activity.gift then
            activity.gift = {}
        end
        if activity.gift[id] == nil then
            activity.gift[id] = true
        end
        if spend then
            activity.gift[id] = false
        end
        LocalDataManager:WriteToFile()
        return activity.gift[id]
    end    
end

--获取活跃度礼物
function ActivityUI:GetActivityGife(type, activityId)
    local giftIdList = self:GetActivityReward()[type][activityId].reward
    local realGiftIDlist = {}
    local allShow = {}
    local afterBuy = function(cfg)
        if cfg.type == 13 then
            local save = ShopManager:GetLocalData()
            save["times"] = save["times"] or {}
            local times = save["times"]
            times[""..cfg.id] = (times[""..cfg.id] or 0) + 1
            LocalDataManager:WriteToFile()
        end        
    end
    for _, id in pairs(giftIdList) do
        table.insert(realGiftIDlist, id)
    end
    local ceoRewardDatas = self:GetActivityReward()[type][activityId].ceo_reward
    local extendParam = {}
    local addIDList = {}
    if GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
        for _, rewardItem in pairs(ceoRewardDatas) do
            if not extendParam[rewardItem[1]] then
                extendParam[rewardItem[1]] = rewardItem[2]
            else
                extendParam[rewardItem[1]]  = extendParam[rewardItem[1]] + rewardItem[2]
            end
            local needAddFlag = true
            for _, shopID in pairs(giftIdList) do
                if shopID == rewardItem[1] then
                    needAddFlag = false
                end
            end
            if needAddFlag then
                table.insert(addIDList, rewardItem[1])
            end
        end
    end
    for _, id in pairs(addIDList) do
        table.insert(realGiftIDlist, id)
    end
    -- self:GetActivityCEORewards(type, activityId)
    local getIsCeoRewardNum = function(shopID)
        return extendParam[shopID] or 0
    end
    for k,v in pairs(realGiftIDlist) do 
        -- PurchaseSuccessUI:SuccessBuy(shopId, cb, isGift, complex, ignoreCompensate, exitCb, extendParam)

        PurchaseSuccessUI:SuccessBuy(v,function()
            local cfg = CfgMgr.config_shop[v]
            local value = ShopManager:GetValue(cfg)
            local cb = ShopManager:GetCB(cfg) 
            if cb and cfg.type ~= 43 then     
                cb(value , cfg, afterBuy(cfg))
            end
            if cfg.type == 43 then
                GameSDKs:TrackForeign("ceo_key_change", {type = cfg.param[1], source = "活跃任务奖励", num = tonumber(getIsCeoRewardNum(v))})
                GameTableDefine.CEODataManager:AddCEOKey(cfg.param[1], getIsCeoRewardNum(v))
            end
            if self.m_view then
                self.m_view:Refresh()
            end
        end, false, false, false, nil,getIsCeoRewardNum(v))
    end
    
    MainUI:RefreshActivityHint()--活跃度的红点
    MainUI:UpdateResourceUI()
end

---comment :获取当前奖励中的CEO奖励相关的内容2025-2-24 fy添加
---@param type any
---@param activityId any
function ActivityUI:GetActivityCEORewards(type, activityId)
    if not GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
        return
    end
    local rewardDatas = self:GetActivityReward()[type][activityId].ceo_reward
    --先把东西给了，在调用purchase的UI显示获得内容
    for _, rewardItem in pairs(rewardDatas) do
        local shopCfg = CfgMgr.config_shop[rewardItem[1]]
        if shopCfg then
            local num = shopCfg.amount * rewardItem[2]
            --钥匙
            if 43 == shopCfg.type then
                GameSDKs:TrackForeign("ceo_key_change", {type = shopCfg.param[1], source = "活跃任务奖励", num = tonumber(num)}) 
                GameTableDefine.CEODataManager:AddCEOKey(shopCfg.param[1], num)
            end
            --TODO:等待后续版本确认后制作宝箱相关的
        end
    end
end

--获取礼物config_activity_reward,因为获取的礼品需要根据情况发生改变所以需要处理
function ActivityUI:GetActivityReward()    
    local cfgActivityReward= CfgMgr.config_activity_reward
    local cfgGlobal = CfgMgr.config_global   
    if not ShopManager:BoughtBefor(cfgGlobal.special_reward) then
        cfgActivityReward.week[1005]["reward"][1] = cfgGlobal.special_reward     
    else 
                
    end
    return cfgActivityReward
end

--检测是否有奖励可以领取(用于MainUI红点)
function ActivityUI:CheckGiftCanGet()
    local bool  = false
    local cfgActivityReward = self:GetActivityReward()  
    local cfgActivity = CfgMgr.config_activity
    --检测任务是否有可以完成的    
    for k,v in pairs(cfgActivity) do
        if self:GetEventNum(k) >= v.threhold and self:GetActivityData("value", k) then
            local bool  = true
            return bool
        end
    end
    --检测天奖励是否有可以完成的
    for k,v in pairs(cfgActivityReward.day) do
        if v.require <= self:GetDayActivity() and ActivityUI:GetActivityData("gift", v.id) then
            local bool  = true
            return bool
        end
    end
    --检测周奖励是否有可以完成的
    for k,v in pairs(cfgActivityReward.week) do
        if v.require <= self:GetWeeklyActivity() and ActivityUI:GetActivityData("gift", v.id) then
            local bool  = true
            return bool
        end
    end
    return bool
end

--检测()
-- function ActivityUI:CheckTimeRe()
--     local activity = LocalDataManager:GetDataByKey("activity")
--     if activity.timePoint == nil then
--         activity.timePoint = TimerMgr:GetCurrentServerTime(true)
--     end
--     local originalDay = math.floor(activity.timePoint / 86400)
--     local currDay = math.floor(TimerMgr:GetCurrentServerTime(true) / 86400)
--     if math.floor(activity.timePoint / 86400) ~= math.floor(TimerMgr:GetCurrentServerTime(true) / 86400) then  
--         local originalWeek = math.floor((activity.timePoint + 259200) / 604800)
--         local currentWeek = math.floor((TimerMgr:GetCurrentServerTime(true) + 259200) / 604800)                   
--         if originalWeek ~= currentWeek then
--             activity.timePoint = TimerMgr:GetCurrentServerTime(true)
--             self:ClearWeeklyActivity()
--             MainUI:RefreshActivityHint()
--             return
--         end
--         activity.timePoint = TimerMgr:GetCurrentServerTime(true)
--         self:ClearDayActivity()
--         MainUI:RefreshActivityHint()
--     end
-- end