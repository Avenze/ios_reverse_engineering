local ConfigMgr = GameTableDefine.ConfigMgr
---@class TimeLimitedActivitiesManager
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local TimerMgr = GameTimeManager
local FragmentActivityUI = GameTableDefine.FragmentActivityUI
local TLA_DATA = "TLAData"
local json = require("rapidjson")
local EventManager = require("Framework.Event.Manager")
local ActivityUI = GameTableDefine.ActivityUI
local MainUI = GameTableDefine.MainUI
local ShopManager = GameTableDefine.ShopManager
local SeasonPassManager = GameTableDefine.SeasonPassManager

local Application = CS.UnityEngine.Application

local TLAState = --活动的状态
{
    END = 1,      --活动结束
    ONGOING = 2,  --活动进行
    SETTLEMENT= 3,--活动领奖
}
---活动的类型 
--碎片活动
TimeLimitedActivitiesManager.FRAGMENT = 1
--首充双倍活动
TimeLimitedActivitiesManager.DoubleDiamond = 3
--限时礼包活动
TimeLimitedActivitiesManager.LIMITPACK = 4
--累积充值活动类型
TimeLimitedActivitiesManager.AccRechargeActivity = 5



TimeLimitedActivitiesManager.GiftPackType = 
{
    LimitPack = "limitpack",
    AccumulatedCharge = "diamondrush",
    LimitChoose = "bundlepack",
}

--副本活动类型
TimeLimitedActivitiesManager.InstanceActivity = 6

--循环副本活动类型
TimeLimitedActivitiesManager.CycleInstanceActivity = 9
--赛季通行证活动类型
TimeLimitedActivitiesManager.SeasonPass = 10

--下班打开活动类型
TimeLimitedActivitiesManager.ClockOut = 11

TimeLimitedActivitiesManager.ActivityList = 
{
    [1] = "fragment",
    [3] = "doublediamond",
    --[4] = "limitPack",
}

---
function TimeLimitedActivitiesManager:Init()
    local tLAData = self:GetTLAData()
    ActivityUI:Init()

    if tLAData["limitPack"] and not tLAData["limitPack"].LimitPackEnable then
        GameTableDefine.ActivityRemoteConfigManager:CheckLimitPackEnable()
    end

    if tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose] and not tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose].LimitPackChooseEnable then
        GameTableDefine.ActivityRemoteConfigManager:CheckLimitPackChooseEnable()
    end
end

--处理 和 获取 限时活动的网络列表数据
function TimeLimitedActivitiesManager:GetTLANetCfg()
    if not self.tLANetCfg then
        local params = {
            callback = function(response)
                --处理本地的存档中的活动
                local tLAData = self:GetTLAData()                
                self:ProcessingActivityEffect()
                --处理网络来的数据
                if not response then return end
                local orCfg = json.decode(response.data)
                local cfg
                if GameDeviceManager:IsiOSDevice() then
                    cfg = orCfg["FragmentCollection_ios"]
                    for k,v in pairs(cfg) do
                        local swicth = v.duration
                        cfg[k].duration = v.endTime
                        cfg[k].endTime = swicth
                    end                    
                else
                    cfg = orCfg["FragmentCollection_android"]
                    for k,v in pairs(cfg) do
                        local swicth = v.duration
                        cfg[k].duration = v.endTime
                        cfg[k].endTime = swicth
                    end
                end
                self.tLANetCfg = cfg                                  
                --对需要写入存档的活动进行写入
                for k,v in pairs(self.tLANetCfg) do
                    if self.ActivityList[v.type] and not tLAData[self.ActivityList[v.type]] then
                        if self:GetTLAStateByCfg(v) ~= TLAState.END then
                            local curr = {}
                            -- local list = {
                            --     [1] = v.startTime,
                            --     [2] = v.duration,
                            --     [3] = v.endTime
                            -- }                                                                               
                            -- table.sort(list,function(a,b)
                            --     return a > b
                            -- end)                                                                                                           
                            curr.type = v.type
                            curr.id = v.id                                                 
                            curr.startTime = v.startTime                         
                            curr.duration = v.duration
                            curr.endTime = v.endTime
                            tLAData[self.ActivityList[v.type]] = curr
                            LocalDataManager:WriteToFile()
                            if v.type  == 1 then
                                MainUI:FragmentActivity(GameStateManager:IsInFloor())
                            end
                        end
                    end
                end
            end
        }
        GameNetwork:HTTP_PublicSendRequest(GameNetwork.GET_TIMELIMITED_ACTIVITES_URL, params, nil, "GET")
    end                  
    return self.tLANetCfg
end

--通过SDK请求活动数据
function TimeLimitedActivitiesManager:RequestActivityData()
    --检查是否升级首充双倍的存档
    GameTableDefine.FirstPurchaseUI:CheckUpgradeSaveData()
    --处理本地的存档中的活动
    self:ProcessingActivityEffect()
    local tLAData = self:GetTLAData()
    --碎片和双倍
    for k,v in pairs(self.ActivityList) do
        if tLAData[v] and self:GetTLAStateByCfg(tLAData[v]) == TLAState.END then   
            GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, k)
        else
            if tLAData[v] and tLAData[v].type == 1 then
                MainUI:FragmentActivity(GameStateManager:IsInFloor())
                FragmentActivityUI:OpenGuidePanel()
            end
            if not tLAData[v] then
                GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, k)
            end
        end
    end
    --赛季通行证
    if SeasonPassManager:NeedRequestActivity() then
        GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.SeasonPass)
    end

    local needRequestLimitPackAndAccumulated = false
    --限时礼包，数据结构不同单独处理
    if tLAData["limitPack"] and self:GetTLAStateByCfg(tLAData["limitPack"]) == TLAState.END then
        LocalDataManager:GetDataByKey("shop").group_tag = nil
        needRequestLimitPackAndAccumulated = true
        --GameSDKs:WarriorGetLimitPackData()
    else
        if not tLAData["limitPack"] then
            LocalDataManager:GetDataByKey("shop").group_tag = nil
            --GameSDKs:WarriorGetLimitPackData()
            needRequestLimitPackAndAccumulated = true
        end
    end
    --限时多选一礼包
    if not needRequestLimitPackAndAccumulated then
        if tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose] and
                self:GetTLAStateByCfg(tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose]) == TLAState.END then
            needRequestLimitPackAndAccumulated = true
        else
            if not tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose] then
                needRequestLimitPackAndAccumulated = true
            end
        end
    end
    --累充
    if not needRequestLimitPackAndAccumulated and GameTableDefine.AccumulatedChargeActivityDataManager:NeedRequestActivityData() then
        needRequestLimitPackAndAccumulated = true
    end
    --请求 限时礼包和累充
    if needRequestLimitPackAndAccumulated then
        GameSDKs:WarriorGetLimitPackData()
    end

    --检测下班打卡活动的初始化以及是否需要请求SDK拉取活动数据
    GameTableDefine.ClockOutDataManager:Init()
end

--处理 和 获取 SDK传来的活动数据
function TimeLimitedActivitiesManager:GetTLASDKCfg(SDKCfg)
    local tLAData = self:GetTLAData()    
    --处理网络来的数据
    if not SDKCfg then return end                               
    --对需要写入存档的活动进行写入
    SDKCfg.activityType = tonumber(SDKCfg.activityType)
    SDKCfg.instanceID = tonumber(SDKCfg.instanceID)
    SDKCfg.startTime = tonumber(SDKCfg.startTime)
    -- SDKCfg.settlementTime = tonumber(SDKCfg.settlementTime)
    -- SDKCfg.endTime = tonumber(SDKCfg.endTime)
    local realEndTime = SDKCfg.settlementTime
    local realSettleTime = SDKCfg.endTime
    SDKCfg.settlementTime = tonumber(realSettleTime)
    SDKCfg.endTime = tonumber(realEndTime)
    if self.ActivityList[SDKCfg.activityType] and not tLAData[self.ActivityList[SDKCfg.activityType]] then
        if self:GetTLAStateByCfg(SDKCfg) ~= TLAState.END then
            local curr = {}                                                                                                        
            curr.type = SDKCfg.activityType
            curr.id = SDKCfg.instanceID                                                 
            curr.startTime = SDKCfg.startTime                         
            curr.duration = SDKCfg.settlementTime
            curr.endTime = SDKCfg.endTime
            tLAData[self.ActivityList[SDKCfg.activityType]] = curr
            LocalDataManager:WriteToFile()
            if SDKCfg.activityType  == 1 then
                MainUI:FragmentActivity(GameStateManager:IsInFloor())
                FragmentActivityUI:OpenGuidePanel()
                
            end
        end                
    end          
end

--处理一个活动的表现效果(需要清空的清空,需要得奖的得奖...)
function TimeLimitedActivitiesManager:ProcessingActivityEffect()
    local tLAData = self:GetTLAData()     
    for k,v in pairs(tLAData) do
        local state = self:GetTLAStateByCfg(v) 
        if state == TLAState.END then
    
        elseif state == TLAState.ONGOING then
             
        elseif state == TLAState.SETTLEMENT then
             -- if value ~= 0 then
             --     --使玩家获得奖励
     
             -- end
        end
    end     
end

--通过活动cfg去获取一个活动的状态
function TimeLimitedActivitiesManager:GetTLAStateByCfg(cfg)
    if not cfg or not cfg.startTime or not cfg.endTime then
        return TLAState.END
    end
    local currTime = TimerMgr:GetCurrentServerTime(true)
    if currTime > cfg.startTime and currTime < cfg.endTime then
        if cfg.duration and currTime > cfg.duration then
            return  TLAState.SETTLEMENT
        end
        return  TLAState.ONGOING
    end
    return TLAState.END  --没有表示为活动结束的状态
end

--通过id去获取这个活动的存档
function TimeLimitedActivitiesManager:GetTLADatabyCfg(cfg)


end

--通过cfg去获取玩家在这个活动中能拿到的奖励
function TimeLimitedActivitiesManager:GetRewardByCfg(cfg)
    if cfg.type == 1 then
    
    elseif cfg.type == 2 then
    
    elseif cfg.type == 3 then

    end
    return 0        
end

--获得限时活动的总的存档
function TimeLimitedActivitiesManager:GetTLAData()
    local tLAData = LocalDataManager:GetDataByKey(TLA_DATA)
    return tLAData
end

--控制游戏中的活动入口显示开启

--天重置和周重置
function TimeLimitedActivitiesManager:ResetData()
    local activity = LocalDataManager:GetDataByKey("activity")
    local cfg =  ConfigMgr.config_global
    local isNewPlayer = true 
    if activity.timePoint == nil then
        activity.timePoint = TimerMgr:GetCurrentServerTime(true)
    else
        isNewPlayer = false
    end
    local originalDay = math.floor((activity.timePoint + ((cfg.daily_reset - 8) * 3600)) / 86400)
    local originalWeek = math.floor((activity.timePoint + 259200 + ((cfg.daily_reset - 8) * 3600) + ((cfg.weekly_reset[1] -1) * 86400)) / 604800)     
    local daily_reset = cfg.daily_reset or 0
    local weekly_reset = cfg.weekly_reset[1] or 0
    if self.m_UpData then
        GameTimer:StopTimer(self.m_UpData)
    end
    self.m_UpData = GameTimer:CreateNewMilliSecTimer(1000, function()
        if ConfigMgr.config_global.fragment_task_refresh == 0 then
            local currtime = TimerMgr:GetCurrentServerTime(true)
            local currDay = math.floor((currtime + ((daily_reset - 8) * 3600)) / 86400)
            local currentWeek = math.floor((currtime + 259200 + ((daily_reset - 8) * 3600) + ((weekly_reset -1) * 86400)) / 604800)

            if currDay ~= originalDay then
                GameTimer:StopTimer(self.m_UpData)
                --------------------周重置--------------------
                if currentWeek ~= originalWeek and currentWeek >= originalWeek then
                    --重置活跃度任务
                    ActivityUI:ClearWeeklyActivity()
                    MainUI:RefreshActivityHint()


                end
                --------------------天重置--------------------
                --重置时间点
                activity.timePoint = TimerMgr:GetCurrentServerTime(true)
                --重置活跃度任务
                ActivityUI:ClearDayActivity()
                MainUI:RefreshActivityHint()
                --重置碎片活动任务
                FragmentActivityUI:ClearFragment(function()
                    FragmentActivityUI:UpdateDataAndItems()
                end)
                LocalDataManager:WriteToFile()
                self:ResetData()
            end
        else
            local TLAData = self:GetTLAData()
            if not TLAData.fragment then
                return
            end
            local start = TLAData.fragment.startTime
            local remaining, needRefresh =  FragmentActivityUI:CountDownToTheTime(start,3600 * ConfigMgr.config_global.fragment_task_refresh_cd)
            if remaining < 1 then
                --重置碎片活动任务
                FragmentActivityUI:ClearFragment(function()
                    FragmentActivityUI:UpdateDataAndItems()
                end)
                self:ResetData()
            elseif needRefresh and not self.enterRefresh then
                self.enterRefresh = true
                --重置碎片活动任务
                FragmentActivityUI:ClearFragment(function()
                    FragmentActivityUI:UpdateDataAndItems()
                end)
            end
        end
       
    end, true, true)
end

--监听事件发生
function TimeLimitedActivitiesManager:InitActiveEvents()
    --购买/升级办公楼设施
    EventManager:RegEvent("UPGRADE_FACILITIES", function()
        ActivityUI:AddActivityData(1001)
        FragmentActivityUI:TaskEventTrigger(1001)
    end)
    --升级办公楼公司
    EventManager:RegEvent("UPGRADE_COMPANY", function()
        ActivityUI:AddActivityData(1002)
        FragmentActivityUI:TaskEventTrigger(1002)
    end)
    --喂食宠物
    EventManager:RegEvent("FEED_PET", function()
        ActivityUI:AddActivityData(1003)
        FragmentActivityUI:TaskEventTrigger(1003)
    end)
    --完成工厂订单
    EventManager:RegEvent("FACTORY_ORDER", function()
        ActivityUI:AddActivityData(1004)
        FragmentActivityUI:TaskEventTrigger(1004)
    end)
    --购买/升级工厂建筑
    EventManager:RegEvent("UPGRADE_FACTORY", function()
        --活跃度--参数填config_activity 的 id
        ActivityUI:AddActivityData(1005)
        FragmentActivityUI:TaskEventTrigger(1005)
    end)
    --观看任意广告
    EventManager:RegEvent("WATCH_ADS", function()
        ActivityUI:AddActivityData(1006)
        FragmentActivityUI:TaskEventTrigger(1006)
    end)
    --参与转盘抽奖
    EventManager:RegEvent("ROTARY_TABLE_LOTTERY", function()
        ActivityUI:AddActivityData(1007)
        FragmentActivityUI:TaskEventTrigger(1007)
    end)
    --完成任意内购行为
    EventManager:RegEvent("DOMESTIC_PURCHASE", function()
        ActivityUI:AddActivityData(1008)
        FragmentActivityUI:TaskEventTrigger(1008)
    end)
end

--GM开一个碎片活动
function TimeLimitedActivitiesManager:EnableFragmentActivity(durationNum, endTimeNum)
    local tLAData = self:GetTLAData()
    local curr = {}
    durationNum = durationNum or 5
    endTimeNum = endTimeNum + durationNum or 10
    curr.type = 1
    curr.id = 0
    curr.startTime = TimerMgr:GetCurrentServerTime(true)
    curr.duration = TimerMgr:GetCurrentServerTime(true) + (60 * durationNum)    
    curr.endTime = TimerMgr:GetCurrentServerTime(true) + (60 * endTimeNum)
    tLAData["fragment"] = curr
    LocalDataManager:WriteToFile()    
    MainUI:FragmentActivity(GameStateManager:IsInFloor())
    FragmentActivityUI:OpenGuidePanel()
end

--GM开一个限时礼包活动
function TimeLimitedActivitiesManager:EnableLimitPackActivity(endTimeNum)
    local tLAData = self:GetTLAData()
    local curr = {}
    curr.type = 4
    curr.id = 0
    curr.packs = {}
    curr.startTime = TimerMgr:GetCurrentServerTime(true)
    curr.endTime = TimerMgr:GetCurrentServerTime(true) + (60 * endTimeNum)
    curr.theme = "normal" -- 礼包主题
    curr.title_str = "Happy Halloween" -- 礼包标题str
    curr.background = "bg_limitpack_christmas_5"   -- 礼包标题背景
    curr.icon = "btn_limitpack_valentineday"   -- 礼包入口icon
    
    for i = 1, 2 do
        local config = ConfigMgr.config_limitpack[i]
        local packConfig = {}
        packConfig.index = i
        packConfig.buy_num = 1
        packConfig.sku_id = config.shop_id
        packConfig.discount_rate = config.offvalue or 1
        packConfig.pack_bg = "ui_limitedTime_common_bottom"
        packConfig.banner = "ui_limitedTime_hallowmas_bg_1"
        packConfig.items_bg = "bg_limitpack_valentinesday_2"   -- 礼包前景图
        packConfig.items = {}
        local itemLen = #config.content
        if itemLen>0 then
            for i=1,itemLen do
                local v = config.content[i]
                table.insert(packConfig.items,i,{id = v,count = 1,bg = "ui_limitedTime_common_bottom_purple",})
            end
        end
        packConfig.open_conditions = {}

        packConfig.startTime = curr.startTime
        packConfig.endTime = curr.endTime
        table.insert(curr.packs,i,packConfig)
        ShopManager:ClearLimitPackBuyTimes(packConfig.sku_id)
    end

    tLAData["limitPack"] = curr
    LocalDataManager:WriteToFile()
    MainUI:LimitPackActivity(GameStateManager:IsInFloor())
end

--SDK限时礼包活动回调
function TimeLimitedActivitiesManager:EnableLimitPackActivityFromSDK(packData)
    local tLAData = self:GetTLAData()
    --如果现在正在上次活动期间，那就不覆盖本地活动
    local curTime = TimerMgr:GetCurrentServerTime(true)
    if tLAData and tLAData.limitPack then
        if tLAData.limitPack.startTime and tLAData.limitPack.endTime then
            if tLAData.limitPack.endTime > curTime and tLAData.limitPack.startTime <= curTime then
                return
            end
        end
    end

    local curr = {}
    curr.type = 4
    curr.theme = packData.theme -- 礼包主题
    curr.title_str = packData.title_str -- 礼包标题str
    curr.background = packData.background   -- 礼包标题背景
    curr.icon = packData.icon   -- 礼包入口icon
    curr.open_conditions = packData.open_conditions   -- 开启条件
    curr.LimitPackEnable = nil -- 拉到新活动时，重置开启状态
    --用于整体时间计算
    curr.startTime = packData.start_time/1000
    curr.endTime = packData.end_time/1000
    curr.packs = {}
    local packCount = #packData.sub_gift
    if packCount > 0 then
        for j = 1, packCount do
            local SDKCfg = packData.sub_gift[j]
            local packConfig = {}
            packConfig.index = SDKCfg.index
            packConfig.buy_num = SDKCfg.buy_num
            packConfig.sku_id = tonumber(SDKCfg.sku_id)
            packConfig.discount_rate = tonumber(SDKCfg.discount_rate)
            packConfig.pack_bg = SDKCfg.pack_bg -- 礼包背景图
            packConfig.banner = SDKCfg.banner   -- 礼包前景图
            packConfig.items_bg = SDKCfg.items_bg   -- 礼包前景图
            packConfig.items = {}
            local itemLen = #SDKCfg.items
            if itemLen > 0 then
                for i=1, itemLen do
                    local v = SDKCfg.items[i]
                    table.insert(packConfig.items,i,{
                        id = tonumber(v.id),
                        count = v.count, 
                        bg = SDKCfg.product_bg,
                    })
                end
            end
            -- 这个条件判断放到对整个礼包生效，K134改为星级条件决定, 判断规则有变化, 判断规则有变化, 判断规则有变化
            --packConfig.open_conditions = {}
            --local conditionLen = #packConfig.open_conditions
            --if conditionLen>0 then
            --    for i = 1, conditionLen do
            --        local v = SDKCfg.open_conditions[i]
            --        table.insert(packConfig.open_conditions,i,{type = v.type,value = v.value,compare_type = v.compare_type})
            --    end
            --end

            packConfig.startTime = curr.startTime
            packConfig.endTime = curr.endTime
            table.insert(curr.packs,j,packConfig)
            ShopManager:ClearLimitPackBuyTimes(packConfig.sku_id)
 
            LocalDataManager:GetDataByKey("shop").group_tag = packConfig.group_tag
        end
    end
    tLAData["limitPack"] = curr
    LocalDataManager:WriteToFile()

    GameTableDefine.LimitPackUI:InitLimitPackData(true)
    GameTableDefine.ActivityRemoteConfigManager:CheckLimitPackEnable()
end

--SDK限时多选一礼包活动回调
function TimeLimitedActivitiesManager:EnableLimitChooseActivityFromSDK(packData)
    local tLAData = self:GetTLAData()
    --如果现在正在上次活动期间，那就不覆盖本地活动
    local curTime = TimerMgr:GetTheoryTime(true)
    local saveData = tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose]
    if saveData then
        if saveData.startTime and saveData.endTime then
            if saveData.endTime > curTime and saveData.startTime <= curTime then
                return
            end
        end
    end
    --已过时的活动
    local endTime = packData.end_time or 0
    endTime = endTime/1000
    if endTime < curTime then
        return
    end

    local curr = {}
    curr.type = 4
    curr.theme = packData.theme -- 礼包主题
    if not curr.theme or curr.theme == "" then
        curr.theme = "normal"
    end
    curr.title_str = packData.title_str -- 礼包标题str
    curr.background = packData.background   -- 礼包标题背景
    curr.icon = packData.icon   -- 礼包入口icon
    curr.open_conditions = packData.open_conditions   -- 开启条件
    curr.LimitPackChooseEnable = nil -- 拉到新活动时，重置开启状态
    --用于整体时间计算
    curr.startTime = packData.start_time/1000
    curr.endTime = packData.end_time/1000
    curr.packs = {}
    curr.shopID = tonumber(packData.shop_id or 0) --打包购买价格
    curr.discount_rate = tonumber(packData.discount_rate or 0.5) --打包购买折扣率
    local packCount = #packData.sub_gift
    if packCount > 0 then
        for j = 1, packCount do
            local SDKCfg = packData.sub_gift[j]
            local packConfig = {}
            packConfig.index = SDKCfg.index
            packConfig.buy_num = SDKCfg.buy_num
            packConfig.sku_id = tonumber(SDKCfg.sku_id)
            packConfig.discount_rate = tonumber(SDKCfg.discount_rate)
            packConfig.pack_bg = SDKCfg.pack_bg -- 礼包背景图
            packConfig.banner = SDKCfg.banner   -- 礼包前景图
            packConfig.items_bg = SDKCfg.items_bg   -- 礼包前景图
            packConfig.items = {}
            local itemLen = #SDKCfg.items
            if itemLen > 0 then
                for i=1, itemLen do
                    local v = SDKCfg.items[i]
                    table.insert(packConfig.items,i,{
                        id = tonumber(v.id),
                        count = v.count,
                        bg = SDKCfg.product_bg,
                    })
                end
            end

            -- 这个条件判断放到对整个礼包生效，K134改为星级条件决定, 判断规则有变化, 判断规则有变化, 判断规则有变化
            --packConfig.open_conditions = {}
            --local conditionLen = #packConfig.open_conditions
            --if conditionLen>0 then
            --    for i = 1, conditionLen do
            --        local v = SDKCfg.open_conditions[i]
            --        table.insert(packConfig.open_conditions,i,{type = v.type,value = v.value,compare_type = v.compare_type})
            --    end
            --end

            packConfig.startTime = curr.startTime
            packConfig.endTime = curr.endTime
            table.insert(curr.packs,j,packConfig)
        end
    end
    tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose] = curr
    LocalDataManager:WriteToFile()

    GameTableDefine.LimitChooseUI:InitLimitChooseData(true)
    GameTableDefine.ActivityRemoteConfigManager:CheckLimitPackChooseEnable()
end

function TimeLimitedActivitiesManager:CheckIsFirstEnterFragment()
    local tLAData = self:GetTLAData()
    local fragmentData = tLAData["fragment"]
    if not fragmentData then
        return nil, nil 
    end

    return fragmentData.firstEnter, fragmentData.enterDay
end

function TimeLimitedActivitiesManager:SetIsFirstEnterFragment()
    local tLAData = self:GetTLAData()
    local fragmentData = tLAData["fragment"]
    if fragmentData then
        fragmentData.firstEnter = true
    end
end

function TimeLimitedActivitiesManager:SetEnterFragment()
    local tLAData = self:GetTLAData()
    local fragmentData = tLAData["fragment"]
    if fragmentData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        fragmentData.enterDay = day
    end
end

function TimeLimitedActivitiesManager:GetLimitPackEnterDay()
    local tLAData = self:GetTLAData()
    local limitPackData = tLAData["limitPack"]
    return limitPackData and limitPackData.enterDay or nil
end

function TimeLimitedActivitiesManager:SetEnterLimitPack()
    local tLAData = self:GetTLAData()
    local limitPackData = tLAData["limitPack"]
    if limitPackData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        limitPackData.enterDay = day
    end
end

function TimeLimitedActivitiesManager:GetLimitChooseEnterDay()
    local tLAData = self:GetTLAData()
    local limitChooseData = tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose]
    return limitChooseData and limitChooseData.enterDay or nil
end

function TimeLimitedActivitiesManager:SetEnterLimitChoose()
    local tLAData = self:GetTLAData()
    local limitChooseData = tLAData[TimeLimitedActivitiesManager.GiftPackType.LimitChoose]
    if limitChooseData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        limitChooseData.enterDay = day
    end
end