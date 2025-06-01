--[[
    累积充值活动的相关数据逻辑管理器
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-12-21 10:00:11
]]

---@class AccumulatedChargeActivityDataManager
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local CfgMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local MainUI = GameTableDefine.MainUI
local json = require("rapidjson")
local ShopManager = GameTableDefine.ShopManager
local Shop = GameTableDefine.Shop
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local Application = CS.UnityEngine.Application
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager

--[[
    @desc: 初始化，如果有存档且活动还存在，使用存档活动时间
    author:{author}
    time:2022-12-21 10:10:40
    @return:
]]
function AccumulatedChargeActivityDataManager:Init()
    if self.isInit then
        return
    end
    self.m_accChargeACData = LocalDataManager:GetDataByKey("acc_charge_activity_data")
    local isNeedSave = false
    if not self.m_accChargeACData or Tools:GetTableSize(self.m_accChargeACData) <= 0 then
        --没有活动向服务器请求活动
        self.m_isActivityOpen = false
        isNeedSave = true
    elseif self.m_accChargeACData["start_time"] and self.m_accChargeACData["end_time"] then
        if self.m_accChargeACData["start_time"] > 0 and self.m_accChargeACData["start_time"] < GameTimeManager:GetCurServerOrLocalTime() and
        self.m_accChargeACData["end_time"] > 0 and self.m_accChargeACData["end_time"] > GameTimeManager:GetCurServerOrLocalTime() then
            --存档记录的活动在进行中,获取看看存档已经购买的商品的数据ID,如果没有创建存档
            if not self.m_accChargeACData["have_recharge_ids"] then
                self.m_accChargeACData["have_recharge_ids"] = {}
                isNeedSave = true
            end
            self.m_isActivityOpen = true
            -- if self:CheckIsGetAllProducts() then
            --     self:RefreshAllProductsCanBuy()
            -- end
        end
    else
        if self.m_accChargeACData["have_recharge_ids"] then
            self.m_accChargeACData["have_recharge_ids"] = {}
        end
        if not self.m_accChargeACData["have_recharge_ids"] then
            self.m_accChargeACData["have_recharge_ids"] = {}
        end
        self.m_isActivityOpen = false
        isNeedSave = true
    end
    if not self.m_isActivityOpen then
        -- 向服务器请求活动    K119 活动请求放在和限时礼包一起了
        --GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.AccRechargeActivity)
    else
        AccumulatedChargeActivityDataManager:OpenAccumulatedChargeActivity()
    end
    if isNeedSave then
        LocalDataManager:WriteToFile()
    end
    EventManager:RegEvent("ACCUMULATED_CHARGE_BUY_MSG", handler(AccumulatedChargeActivityDataManager, AccumulatedChargeActivityDataManager.BuyProductCallback))
    self.isInit = true
end

function AccumulatedChargeActivityDataManager:OpenAccumulatedChargeActivity()
    if AccumulatedChargeActivityDataManager.m_accChargeACData then
        if not AccumulatedChargeActivityDataManager.m_accChargeACData.AccumulatedChargeEnable then
            GameTableDefine.ActivityRemoteConfigManager:CheckAccumulatedChargePackEnable()
        else
            MainUI:OpenAccumulatedChargeActivity()
        end
    end
end

--example- "WarriorGiftPackData": [
--        {
--            "gift_id": 313,
--            "group_tag": "DEFAULT_LABEL",
--            "shop_id": "1",
--            "type": "diamondrush",
--            "icon": "btn_limitpack_valentineday",
--            "background": "bg_limitpack_easter_5",
--            "available_num": 1,
--            "items": [],
--            "open_conditions": [],
--            "start_time": 1716163200000,
--            "end_time": 1716249600000,
--            "discount": "",
--            "steps": [
--                {
--                    "sku_id": "1305",
--                    "items": [
--                        {
--                            "id": "1290",
--                            "count": 1000
--                        },
--                        {
--                            "id": "1296",
--                            "count": 1
--                        }
--                    ]
--                },
--                {
--                    "sku_id": "0",
--                    "items": [
--                        {
--                            "id": "1290",
--                            "count": 10
--                        },
--                        {
--                            "id": "1296",
--                            "count": 2
--                        }
--                    ]
--                },
--            ]
--        }
--    ]
---累充活动开启入口. K119 修改 warriorActivityData-> WarriorGiftPackData
function AccumulatedChargeActivityDataManager:ProcessSDKCallbackData(WarriorGiftPackData)

    if not WarriorGiftPackData then return end
    if WarriorGiftPackData.type ~= TimeLimitedActivitiesManager.GiftPackType.AccumulatedCharge then
        return
    end
    if not WarriorGiftPackData.start_time and not WarriorGiftPackData.end_time then
        return
    end
    local startTime = tonumber(WarriorGiftPackData.start_time)
    local endTime = tonumber(WarriorGiftPackData.end_time)
    if not startTime or not endTime then
        return
    end
    startTime = startTime/1000
    endTime = endTime/1000
    local curTime = GameTimeManager:GetCurServerOrLocalTime()
    if startTime > curTime or endTime < curTime then
        return
    end
    if self.m_accChargeACData then
        --如果现在正在上次活动期间，那就不覆盖本地活动
        if self.m_accChargeACData.end_time and self.m_accChargeACData.start_time then
            if self.m_accChargeACData.end_time > curTime and self.m_accChargeACData.start_time <= curTime then
                return
            end
        end

        self.m_accChargeACData.have_recharge_ids = {}
        self.m_accChargeACData.start_time = startTime
        self.m_accChargeACData.end_time = endTime
        self.m_accChargeACData.open_conditions = WarriorGiftPackData.open_conditions   -- 开启条件
        self.m_accChargeACData.AccumulatedChargeEnable = nil -- 拉到新活动时，重置开启状态
        self.m_isActivityOpen = true

        --组装Config
        local configs = {}
        self.m_accChargeACData.m_configs = configs
        if WarriorGiftPackData.steps then
            local configLen = #WarriorGiftPackData.steps
            for i = 1, configLen do
                local configData = WarriorGiftPackData.steps[i]
                local accConfig = {}
                configs[i] = accConfig
                accConfig.id = i
                accConfig.reward = {}
                local rewardLen = #configData.items
                for j=1,rewardLen do
                    local item = configData.items[j]
                    accConfig.reward[j] ={id = tonumber(item.id),count = item.count or 1}
                end
                accConfig.iap_id = tonumber(configData.sku_id or 0)
            end
        end

        AccumulatedChargeActivityDataManager:OpenAccumulatedChargeActivity()
    else
        return
    end

    --joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
    --if not WarriorActivityData then return end
    --if tonumber(WarriorActivityData.activityType) ~= TimeLimitedActivitiesManager.AccRechargeActivity then
    --    return
    --end
    --if not WarriorActivityData.startTime and not WarriorActivityData.endTime then
    --    return
    --end
    --local startTime = tonumber(WarriorActivityData.startTime)
    --local endTime = tonumber(WarriorActivityData.endTime)
    --if not startTime or not endTime then
    --    return
    --end
    --if startTime > GameTimeManager:GetCurServerOrLocalTime() or endTime < GameTimeManager:GetCurServerOrLocalTime() then
    --    return
    --end
    --if self.m_accChargeACData then
    --    self.m_accChargeACData.have_recharge_ids = {}
    --    self.m_accChargeACData.start_time = startTime
    --    self.m_accChargeACData.end_time = endTime
    --    self.m_isActivityOpen = true
    --    AccumulatedChargeActivityDataManager:OpenAccumulatedChargeActivity()
    --    --TO-DO:这里可以做一个消息通知来通知MainUI显示活动开启了
    --
    --else
    --    return
    --end
end

---K119 获取累充活动配置，配置由SDK给
function AccumulatedChargeActivityDataManager:GetAccumulatedConfigs()
    if self.m_accChargeACData and self.m_accChargeACData.m_configs then
        return self.m_accChargeACData.m_configs
    else
        return nil
    end
end

---K119 是否需要请求活动数据
function AccumulatedChargeActivityDataManager:NeedRequestActivityData()
    return not self:GetActivityIsOpen()
end

---K134 判断累充是否开启
function AccumulatedChargeActivityDataManager:AccumulatedChargeEnable()
    return AccumulatedChargeActivityDataManager.m_accChargeACData and AccumulatedChargeActivityDataManager.m_accChargeACData.AccumulatedChargeEnable and AccumulatedChargeActivityDataManager:GetActivityLeftTime() > 0
end

function AccumulatedChargeActivityDataManager:GetActivityIsOpen()
    self:GetActivityLeftTime()
    return self.m_isActivityOpen
end

function AccumulatedChargeActivityDataManager:GetActivityLeftTime()
    if not self.m_accChargeACData then
        self.m_isActivityOpen = false
        return 0
    end
    if self.m_accChargeACData.end_time and self.m_accChargeACData.end_time > 0 and self.m_accChargeACData.end_time > GameTimeManager:GetCurServerOrLocalTime() then
        return self.m_accChargeACData.end_time - GameTimeManager:GetCurServerOrLocalTime()
    end
    self.m_isActivityOpen = false
    return 0
end

function AccumulatedChargeActivityDataManager:CheckIsHaveBuy(configID)
    if not self.m_accChargeACData or not self.m_accChargeACData.have_recharge_ids or Tools:GetTableSize(self.m_accChargeACData.have_recharge_ids) <= 0 then
        return false
    end
    for _, v in pairs(self.m_accChargeACData.have_recharge_ids) do
        if v == configID then
            return true
        end
    end
    return false
end

function AccumulatedChargeActivityDataManager:CheckCanBuy(configID)
    if configID == 1 then
        return true
    else
        if self:CheckIsHaveBuy(configID) then
            return false
        else
            if configID - 1 > 0 then
                if self:CheckIsHaveBuy(configID - 1) then
                    return true
                end
            end
        end 
    end
    return false
end

function AccumulatedChargeActivityDataManager:BuyProduct(configID, cb, btn)
    self.buyCallback = nil
    if not self:CheckCanBuy(configID) then
        if cb then
            cb(configID, false)
        end
        return
    end
    local configs = self:GetAccumulatedConfigs()
    if not configs then
        if cb then
            cb(configID, false)
        end
        return
    end
    local cfgItem =  configs[configID]
    if not cfgItem then
        if cb then
            cb(configID, false)
        end
        return
    end

    self.buyCallback = cb
    if cfgItem.iap_id > 0 then
        --现金购买的东西,需要创建订单等待订单回调
        Shop:CreateAccumulatedRechargeItemOrder(configID, btn)
    else
        --免费购买的东西
        self:BuyProductCallback(configID, true)
    end
end

--[[
    @desc: fy增加补单恢复的相关内容
    author:{author}
    time:2025-01-13 16:48:23
    --@iapid:
	--@isSuccess: 
    @return:
]]
function AccumulatedChargeActivityDataManager:BuyProductCallbackByRestore(iapid, isSuccess)
    local configs = self:GetAccumulatedConfigs()
    if not configs then
        return
    end
    local itemID = 0
    local itemCfg = nil
    for k, v in pairs(configs) do
        if iapid ~= 0 and v.iap_id == iapid then
            itemID = k
            itemCfg = v
            break
        end
    end
    self:BuyProductCallback(itemID, isSuccess)
end

function AccumulatedChargeActivityDataManager:BuyProductCallback(itemID, isSuccess)
    --给东西然后回调
    local configs = self:GetAccumulatedConfigs()
    if not configs then
        GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, false)
        return
    end
    local itemCfg = configs[itemID]
    if not itemCfg or not isSuccess then
        -- if self.buyCallback then
        --     self.buyCallback(itemID, false)
        --     self.buyCallback = nil
        -- end
        GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, false)
        return
    end

    GameSDKs:TrackForeign("rank_activity", {name = "AccCharge", operation = "2", reward = itemID})

    local rewards = {}
    for k, reward in pairs(itemCfg.reward) do
       table.insert(rewards, reward)
    end
    
    if not self.m_accChargeACData.have_recharge_ids then
        self.m_accChargeACData.have_recharge_ids = {}
    end
    table.insert(self.m_accChargeACData.have_recharge_ids, itemID)
    
    -- local function buyProcess(shopID)
    --     ShopManager:Buy(shopID, false, nil, function ()
    --         PurchaseSuccessUI:SuccessBuy(shopID, function ()
    --             if Tools:GetTableSize(rewardIDs) > 0 then
    --                 local newItemID = table.remove(rewardIDs, 1)
    --                 buyProcess(newItemID)
    --             else
    --                 GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, isSuccess)
    --             end
    --         end)
    --     end)
    -- end
    local isLast = false
    if Tools:GetTableSize(rewards) > 0 then
        --local rewardCount = #rewards
        for k,v in ipairs(rewards) do
            local rewardID = v.id
            local itemCount = v.count
            ShopManager:Buy_LimitPackReward(rewardID , nil,function()
                PurchaseSuccessUI:SuccessBuy(rewardID, function()
                    --rewardCount = rewardCount - 1
                    --if rewardCount == 0 then
                    --end
                    GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, isSuccess)
                end,false,itemCount)
            end,false,itemCount)
        end
        -- local index = table.remove(rewardIDs, 1)
        -- buyProcess(index)
        --self.buyTimer = GameTimer:CreateNewMilliSecTimer(200, function()
        --    local reward = table.remove(rewards, 1)
        --    if reward then
        --        ShopManager:Buy_LimitPackReward(reward.id, nil, function ()
        --            PurchaseSuccessUI:SuccessBuy(reward.id, function()
        --                if Tools:GetTableSize(rewards) <= 0 then
        --                    if self.buyTimer then
        --                        GameTimer:StopTimer(self.buyTimer)
        --                        self.buyTimer = nil
        --                    end
        --                    GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, isSuccess)
        --                end
        --            end,false,reward.count)
        --        end,false,reward.count)
        --    else
        --        if self.buyTimer then
        --            GameTimer:StopTimer(self.buyTimer)
        --            self.buyTimer = nil
        --        end
        --    end
        --end, true, true)
    else
        GameTableDefine.AccumulatedChargeACUI:AfterBuyCallback(itemID, isSuccess)
    end
    
    -- ShopManager:Buy(id, false, nil, function()
    --     PurchaseSuccessUI:SuccessBuy(id)
    -- end);
    
end

--[[
    @desc: 检测是不是已经购买完了
    author:{author}
    time:2022-12-23 14:38:41
    @return:
]]
function AccumulatedChargeActivityDataManager:CheckIsGetAllProducts()
    if not self.m_accChargeACData.have_recharge_ids or Tools:GetTableSize(self.m_accChargeACData.have_recharge_ids) <= 0 then
        return false
    end
    local configs = self:GetAccumulatedConfigs()
    local configsCount = configs and Tools:GetTableSize(configs) or 0
    return Tools:GetTableSize(self.m_accChargeACData.have_recharge_ids) >= configsCount
end

function AccumulatedChargeActivityDataManager:RefreshAllProductsCanBuy()
    if self:GetActivityIsOpen() then
        if self.m_accChargeACData.have_recharge_ids then
            self.m_accChargeACData.have_recharge_ids = {}
            LocalDataManager:WriteToFile()
            GameTableDefine.AccumulatedChargeACUI:RefreshAllItems()
        end
    end
end

function AccumulatedChargeActivityDataManager:GMOpenAccumulatedChargeAC(duration)
    if not self:GetActivityIsOpen() then
        self.m_accChargeACData.start_time = GameTimeManager:GetCurServerOrLocalTime()
        self.m_accChargeACData.end_time = self.m_accChargeACData.start_time + (duration * 60)
        self.m_accChargeACData.have_recharge_ids = {}
        self.m_isActivityOpen = true

        --组装Config
        local configs = {}
        self.m_accChargeACData.m_configs = configs
        if CfgMgr.config_payment then
            local configLen = #CfgMgr.config_payment
            for i = 1, configLen do
                local configData = CfgMgr.config_payment[i]
                local accConfig = {}
                configs[i] = accConfig
                accConfig.id = configData.id
                accConfig.reward = {}
                local rewardLen = #configData.reward
                for j=1,rewardLen do
                    accConfig.reward[j] ={id = configData.reward[j],count = 1}
                end
                accConfig.iap_id = configData.iap_id
            end
        end

        LocalDataManager:WriteToFile()
        AccumulatedChargeActivityDataManager:OpenAccumulatedChargeActivity()
    end
end

---当前可买的物品是否是免费的
function AccumulatedChargeActivityDataManager:IsCurItemFree()
    local configs = self:GetAccumulatedConfigs()
    if not configs then
        return false
    end
    local len = #configs
    for i = 1, len do
        local v = configs[i]
        if not self:CheckIsHaveBuy(v.id) then
            return v.iap_id == 0
        end
    end
    return false
end


function AccumulatedChargeActivityDataManager:CheckIsFirstEnterAccCharge()
    local accChargeACData = self.m_accChargeACData
    if not accChargeACData then
        return nil
    end

    return accChargeACData.enterDay
end


function AccumulatedChargeActivityDataManager:SetEnterAccCharge()
    local accChargeACData = self.m_accChargeACData
    if accChargeACData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        accChargeACData.enterDay = day
    end
end