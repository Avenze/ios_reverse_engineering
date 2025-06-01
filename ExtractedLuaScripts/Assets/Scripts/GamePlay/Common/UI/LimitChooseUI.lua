---@class LimitChooseUI
local LimitChooseUI = GameTableDefine.LimitChooseUI

local GameUIManager = GameTableDefine.GameUIManager
local TLAManager = GameTableDefine.TimeLimitedActivitiesManager
local ConfigMgr = GameTableDefine.ConfigMgr
local DataName = "bundlepack"
local ShopManager = GameTableDefine.ShopManager
local CommonRewardUI = GameTableDefine.CommonRewardUI
local StarMode = GameTableDefine.StarMode
local GameLauncher = CS.Game.GameLauncher
local IAP = GameTableDefine.IAP
local Shop = GameTableDefine.Shop
local DeviceUtil = CS.Game.Plat.DeviceUtil
local UIPopManager = GameTableDefine.UIPopupManager
local CountryMode = GameTableDefine.CountryMode
local ResourceManger = GameTableDefine.ResourceManger

---此类型不使用ShopManager返回的数值
local IgnoreNumType = {
    ["pet"] = "1",
    ["emplo"] = "1",
}

function LimitChooseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.LIMIT_CHOOSE_UI, self.m_view, require("GamePlay.Common.UI.LimitChooseUIView"), self, self.CloseView)
    return self.m_view
end

function LimitChooseUI:OpenView()
    self:GetView():Invoke("Init")
end

function LimitChooseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.LIMIT_CHOOSE_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

--初始化存档数据
function LimitChooseUI:InitLimitChooseData(force)
    if not self.m_data or force then
        local tLAData = TLAManager:GetTLAData()
        if not tLAData[DataName] then
            return
        end
        self.m_data = tLAData[DataName]
        LocalDataManager:WriteToFile()
    end
    return self.m_data
end

--获取限时礼包存档数据
function LimitChooseUI:GetLimitChooseData()
    return self:InitLimitChooseData()
end

---获取限时礼包图标
function LimitChooseUI:GetLimitChooseIcon()
    local tLGiftData = self:InitLimitChooseData()
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

---活动是否正在开启中
function LimitChooseUI:IsActive()
    return self:GetTimeRemaining() > 0
end

---是否已经购买过了
function LimitChooseUI:IsBought()
    local tLGiftData = self:GetLimitChooseData()
    return tLGiftData.isBought and true or false
end

---标记为已购买
function LimitChooseUI:SetIsBought()
    local tLGiftData = self:GetLimitChooseData()
    tLGiftData.isBought = true
    LocalDataManager:WriteToFile()
    GameTableDefine.MainUI:LimitChooseActivity(GameStateManager:IsInFloor())
end

---满足开启条件的所有Pack,(其实现在必须有三个Pack，而且starTime,EndTime都一样)
function LimitChooseUI:GetAllActivePack()
    local tLGiftData = self:GetLimitChooseData()
    if tLGiftData then
        local packCount = tLGiftData.packs and #tLGiftData.packs or 0
        if packCount > 0 then
            local activePacks = {}
            for i = 1, packCount do
                local packConfig = tLGiftData.packs[i]
                table.insert(activePacks,#activePacks+1,packConfig)
            end
            return activePacks
        end
    end
    return nil
end

---剩余的时间值
function LimitChooseUI:GetTimeRemaining()
    local tLGiftData = self:GetLimitChooseData()
    local endTime = tLGiftData and tLGiftData.endTime or 0
    local value = endTime - GameTimeManager:GetTheoryTime()
    if value > 0 then
        return value
    else
        return 0
    end
end

---获取道具，以及超出购买次数后转换为钻石
function LimitChooseUI:GetPackReward(packCfg, rewardDatas)
    for k,v in ipairs(packCfg.items) do
        local itemID = v.id
        local itemCount = v.count
        ShopManager:Buy_LimitPackReward(itemID , nil,function(buySuccess)
            local showValue,showIcon = self:GetShowValueString(itemID,itemCount)
            local rewardData = {icon = showIcon,num = showValue}
            if not ShopManager:CheckBuyTimes(itemID) then
                local backDiamond = 0
                local currCfg = ShopManager:GetCfg(itemID)
                --超过购买次数，转换为钻石
                if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
                    backDiamond = backDiamond + currCfg.param2[1]
                elseif currCfg.type == 6 or currCfg.type == 7 then--npc
                    backDiamond = backDiamond + currCfg.param[1]
                elseif currCfg.type == 5 then--免广告
                    backDiamond = backDiamond + currCfg.param[1]
                end
                if backDiamond > 0 then
                    rewardData.backDiamond = backDiamond
                    ResourceManger:AddDiamond(backDiamond, nil, nil, true)
                end
            end
            rewardDatas[#rewardDatas+1] = rewardData
        end,false,itemCount)
    end
end

---领取礼包奖励的方法
function LimitChooseUI:GetLimitChooseReward(rewardConfig)
    --活动过期购买了，也给奖励
    --if not self:IsActive() then
    --    return false
    --end
    local tLGiftData = self:GetLimitChooseData()
    GameSDKs:TrackForeign("debugger", { system = "LimitChoosePack", desc = "领取礼包奖励, 检查存档数据",
        value = "tLGiftData.packs: " .. (tLGiftData and tLGiftData.packs and "true" or "nil") .. " self:IsBought " .. (self:IsBought() and "true" or "false") })
    if not tLGiftData.packs or self:IsBought() then
        return false
    end
    local rewardID = rewardConfig.id
    local packConfigs
    for k,v in pairs(tLGiftData.packs) do
        if v.sku_id == rewardID then
            packConfigs = {v}
            GameSDKs:TrackForeign("debugger", { system = "LimitChoosePack", desc = "领取礼包奖励, packID", 
                value = v.sku_id })
            break
        end
    end
    if not packConfigs then
        --打包购买
        if tLGiftData.shopID == rewardID then
            packConfigs = {}
            for K,v in pairs(tLGiftData.packs) do
                packConfigs[#packConfigs+1] = v
            end
        end
        GameSDKs:TrackForeign("debugger", { system = "LimitChoosePack", desc = "领取礼包奖励, 全部领取ShopID", 
            value = tLGiftData.shopID }) 
    end
    if packConfigs then
        local rewardDatas = {}
        for i,v in ipairs(packConfigs) do
            self:GetPackReward(v,rewardDatas)
        end
        GameSDKs:TrackForeign("rank_activity", {name = "bundlepack", operation = "2", reward = rewardID})
        self:SetIsBought()
        CommonRewardUI:ShowRewardsOneByOne(rewardDatas,function()
            GameTableDefine.MainUI:UpdateResourceUI()
        end)
        return true
    else
        GameSDKs:TrackForeign("debugger", { system = "LimitChoosePack", desc = "领取礼包奖励, 存档中没有适配的商品ID" })
        return false
    end
end

function LimitChooseUI:OpenPanel()
    if not self:IsActive() or self:IsBought() then
        return
    end

    local tLAData = TLAManager:GetTLAData()
    local limitChooseData = tLAData[DataName]
    local enterDay = TLAManager:GetLimitChooseEnterDay()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not limitChooseData or (enterDay == day) then
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
    if enterDay ~= day and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_CHOOSE_UI) then
        self:OpenView()
    end
end

function LimitChooseUI:CheckCanOpen()
    if not self:IsActive() or self:IsBought() then
        return
    end

    local tLAData = TLAManager:GetTLAData()
    local limitChooseData = tLAData[DataName]
    local enterDay = TLAManager:GetLimitChooseEnterDay()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not limitChooseData or (enterDay == day) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_CHOOSE_UI) then
        return
    end
    if not GameTableDefine.ActivityRemoteConfigManager:CheckPackEnable(GameTableDefine.TimeLimitedActivitiesManager.GiftPackType.LimitChoose) then
        return
    end

    return true
end

---@return number,number,number 现价,原价,折扣比例
function LimitChooseUI:GetPrice(shopID,discountRate)
    local discount = discountRate or 0.5
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

function LimitChooseUI:GetShowValueString(itemShopID,itemCount)
    local value,typeName = ShopManager:GetValueByShopId(itemShopID)
    local cfgShop = ConfigMgr.config_shop[itemShopID]
    if tonumber(value) ~= nil then
        value = value * itemCount
    end
    local showValue = ShopManager:SetValueToShow(value, cfgShop)
    local showIcon = cfgShop.icon
    if tonumber(value) == nil or typeName == "offline" or typeName == "income"then
        showValue = "x1"
    elseif typeName == "cash" then
        --local minutesStr = "x"..math.floor(itemCount * cfgShop.amount * 60) .. "Min"
        --showValue = minutesStr
        if CountryMode.m_currCountry == 1 then
            showIcon = cfgShop.icon
        elseif CountryMode.m_currCountry == 2 then
            showIcon = cfgShop.icon .. "_euro"
        end
    elseif typeName == "exp" then
    --    local minutesStr = "x"..math.floor(itemCount * cfgShop.amount * 60) .. "Min"
    --    showValue = minutesStr
    else
        showValue = "x"..showValue
    end

    return showValue,showIcon
end