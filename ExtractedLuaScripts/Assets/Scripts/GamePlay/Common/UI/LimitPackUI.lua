---@class LimitPackUI
local LimitPackUI = GameTableDefine.LimitPackUI

local GameUIManager = GameTableDefine.GameUIManager
local TLAManager = GameTableDefine.TimeLimitedActivitiesManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local DataName = "limitPack"--TLAManager.ActivityList[TLAManager.LIMITPACK]
local ShopManager = GameTableDefine.ShopManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local StarMode = GameTableDefine.StarMode
local GameLauncher = CS.Game.GameLauncher
local IAP = GameTableDefine.IAP
local Shop = GameTableDefine.Shop
local IntroduceUI = GameTableDefine.IntroduceUI
local DeviceUtil = CS.Game.Plat.DeviceUtil
local shopId2Discount = nil
local UIPopManager = GameTableDefine.UIPopupManager

function LimitPackUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.LIMIT_PACK_UI, self.m_view, require("GamePlay.Common.UI.LimitPackUIView"), self, self.CloseView)
    return self.m_view
end

function LimitPackUI:OpenView()
    self:GetView()
end

function LimitPackUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.LIMIT_PACK_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

--初始化存档数据
function LimitPackUI:InitLimitPackData(force)
    if (not self.m_data) or force then
        local tLAData = TLAManager:GetTLAData()
        if not tLAData[DataName] then return end
        self.m_data = tLAData[DataName]
        LocalDataManager:WriteToFile()
    end    
    return self.m_data
end

--获取限时礼包存档数据
function LimitPackUI:GetLimitPackData()
    return self:InitLimitPackData()
end

---获取限时礼包图标
function LimitPackUI:GetLimitPackIcon()
    local tLGiftData = self:InitLimitPackData()
    if tLGiftData then
        local len = tLGiftData.packs and #tLGiftData.packs or 0
        if len>0 then
            for i = 1, len do
                local packConfig = tLGiftData.packs[i]
                return packConfig.icon
            end
        end
    end
    return nil
end

---剩余的时间值
function LimitPackUI:GetTimeRemaining()
    local tLGiftData = self:GetLimitPackData()
    local endTime = tLGiftData and tLGiftData.endTime or 0
    local value = endTime - GameTimeManager:GetCurrentServerTime()
    if value > 0 then
        return value
    else
        return 0
    end
end

function LimitPackUI:CompareValue(a,b,compare_type)
    if compare_type == 0 then --等于
        return a == b
    elseif compare_type == 10 then --小于
        return a < b
    elseif compare_type == 11 then --小于等于
        return a <= b
    elseif compare_type == 20 then --大于
        return a > b
    elseif compare_type == 21 then --大于等于
        return a >= b
    end
    return false
end

---根据CompareType做比较
function LimitPackUI:CompareCondition(condition)
    local type = condition.type
    local value = condition.value
    local compareType = condition.compare_type

    if type == 10 then --比较星级
        local currStar = StarMode:GetStar()
        return self:CompareValue(currStar,value,compareType)
    end

    return true
end

---满足开启条件的第一个Pack,(其实现在必须有两个Pack，而且conditions和StarTime,EndTime都一样)
function LimitPackUI:GetFirstActivePack()
    local tLGiftData = self:GetLimitPackData()
    if tLGiftData then
        local packCount = tLGiftData.packs and #tLGiftData.packs or 0
        if packCount>0 then
            local curTime = GameTimeManager:GetCurrentServerTime()
            for i = 1, packCount do
                local packConfig = tLGiftData.packs[i]
                if packConfig.endTime>curTime then
                    --local canActive = true
                    -- 这个条件判断放到对整个礼包生效，K134改为星级条件决定, 判断规则有变化, 判断规则有变化, 判断规则有变化
                    --if packConfig.open_conditions then
                    --    local len = #packConfig.open_conditions
                    --    for j = 1, len do
                    --        local condition = packConfig.open_conditions[j]
                    --        if not self:CompareCondition(condition) then
                    --            canActive = false
                    --            break
                    --        end
                    --    end
                    --end
                    --if canActive then
                        return packConfig
                    --end
                end
            end
        end
        return nil
    else
        return nil
    end
end

---满足开启条件的所有Pack,(其实现在必须有两个Pack，而且conditions和StarTime,EndTime都一样)
function LimitPackUI:GetAllActivePack()
    local activePacks = {}
    local tLGiftData = self:GetLimitPackData()
    if tLGiftData then
        local packCount = tLGiftData.packs and #tLGiftData.packs or 0
        if packCount>0 then
            local curTime = GameTimeManager:GetCurrentServerTime()
            for i = 1, packCount do
                local packConfig = tLGiftData.packs[i]
                if packConfig.endTime>curTime then
                    --local canActive = true
                    -- 这个条件判断放到对整个礼包生效，K134改为星级条件决定, 判断规则有变化, 判断规则有变化, 判断规则有变化
                    --if packConfig.open_conditions then
                    --    local len = #packConfig.open_conditions
                    --    for j = 1, len do
                    --        local condition = packConfig.open_conditions[j]
                    --        if not self:CompareCondition(condition) then
                    --            canActive = false
                    --            break
                    --        end
                    --    end
                    --end
                    --if canActive then
                        table.insert(activePacks,#activePacks+1,packConfig)
                    --end
                end
            end
        end
    end
    return activePacks
end

--获取礼包的数据
function LimitPackUI:GetCfgLimitpack()
    if not self.cfgLimitpack then
        self.cfgLimitpack = ConfigMgr.config_limitpack
    end
    return self.cfgLimitpack
end

---活动是否正在开启中
function LimitPackUI:IsActive()
    return self:GetTimeRemaining() > 0
end

--领取礼包奖励的方法
function LimitPackUI:GetLimitPackReward(rewardcfg)
    if not self:IsActive() then
        return false
    end
    local tLGiftData = self:GetLimitPackData()
    GameSDKs:TrackForeign("debugger", { system = "LimitPack", desc = "领取礼包奖励, 检查存档数据",
        value = "tLGiftData.packs: " .. (tLGiftData and tLGiftData.packs and "true" or "nil") })
    if not tLGiftData.packs then
        return false
    end

    local cfg
    for k,v in pairs(tLGiftData.packs) do
        if v.sku_id == rewardcfg.id then
            cfg = v
            GameSDKs:TrackForeign("debugger", { system = "LimitPack", desc = "领取礼包奖励, packID", value = v.sku_id })
        end
    end
    if not cfg then
        GameSDKs:TrackForeign("debugger", { system = "LimitPack", desc = "领取礼包奖励, 存档中没有适配的商品ID" })
        return false
    end
    for k,v in ipairs(cfg.items) do
        local itemID = v.id
        local itemCount = v.count
        ShopManager:Buy_LimitPackReward(itemID , nil,function()
            PurchaseSuccessUI:SuccessBuy(itemID, nil,false,itemCount)
        end,false,itemCount)
    end
    GameSDKs:TrackForeign("rank_activity", {name = "LimitPack", operation = "2", reward = cfg.sku_id})
    return true
end


function LimitPackUI:OpenPanel()
    local tLAData = TLAManager:GetTLAData()
    local limitPackData = tLAData["limitPack"]
    local enterDay = TLAManager:GetLimitPackEnterDay()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not limitPackData or (enterDay == day) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
            GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI) then
        self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(1000,function()
            --GameTimer:StopTimer(self.waitOpenTimer)
            self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(100,function()
                if not (StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
                        GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI)) then
                    if enterDay ~= day then
                        self:OpenView()
                    end
                    GameTimer:StopTimer(self.waitOpenTimer)
                    self.waitOpenTimer = nil
                end
            end, true)
        end)
        return
    end
    if enterDay ~= day and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_PACK_UI) then
        self:OpenView()
    end

end

function LimitPackUI:CheckCanOpen()
    local tLAData = TLAManager:GetTLAData()
    local limitPackData = tLAData["limitPack"]
    local enterDay = TLAManager:GetLimitPackEnterDay()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not limitPackData or (enterDay == day) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_PACK_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if not GameTableDefine.ActivityRemoteConfigManager:CheckPackEnable(GameTableDefine.TimeLimitedActivitiesManager.GiftPackType.LimitPack) then
        return
    end
    return true
end

---@return number,number,number 现价,原价,折扣比例
function LimitPackUI:GetPrice(activityConfig)
    local shopID = activityConfig.sku_id
    local discount = activityConfig.discount_rate or 0.5
    local price = Shop:GetShopItemPrice(shopID)
    local priceOriginal, priceNum, comma = IAP:GetPriceDouble(shopID)
    local cheatPrice = 0
    if priceNum then
        cheatPrice = tonumber(priceNum) / discount
    end
    if GameDeviceManager:IsiOSDevice() then
        if cheatPrice == 0 then
            cheatPrice = priceOriginal
        elseif tonumber(cheatPrice) then
            cheatPrice = DeviceUtil.InvokeNativeMethod("formaterPrice", cheatPrice)
        end
    else
        if priceNum then
            local isHaveUSDSymbol = string.find(priceOriginal, "%$")
            local head = string.gsub(priceOriginal,"%p","")
            head = string.gsub(head,"%d","")
            local back = ""

            local cheatPriceInt = math.floor( cheatPrice )
            local cheatPriceStr = tostring(cheatPriceInt)
            local digitDiff = #cheatPriceStr - #priceNum
            back = cheatPriceStr
            if comma then
                for k,v in pairs(comma) do
                    local front = string.sub(back, 1, k +digitDiff -1 )
                    local after = string.sub(back, k +digitDiff -1 +1)

                    back = front..v..after
                end
            end
            if isHaveUSDSymbol then
                cheatPrice = head.."$"..back
            else
                cheatPrice = head..back
            end
        else
            cheatPrice = priceOriginal
        end
    end
    if price == "loading..." then
        cheatPrice = price
    end
    return price,cheatPrice,discount
end