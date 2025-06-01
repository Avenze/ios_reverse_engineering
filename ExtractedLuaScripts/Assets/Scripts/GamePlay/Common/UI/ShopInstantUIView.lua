--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-06-14 16:41:17
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local Shop = GameTableDefine.Shop
local IAP = GameTableDefine.IAP
local InstanceDataManager = GameTableDefine.InstanceDataManager
local DeviceUtil = CS.Game.Plat.DeviceUtil
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local FeelUtil = CS.Common.Utils.FeelUtil
local ShopInstantUI = GameTableDefine.ShopInstantUI
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI

local ShopInstantUIView = Class("ShopInstantUIView", UIView)

function ShopInstantUIView:ctor()
    self.super:ctor()
end


function ShopInstantUIView:OnEnter()
    FirstPurchaseUI:LockEnterShopUITime()
    print("ShopInstantUIView:OnEnter")
    self.cashPanelGo = self:GetGoOrNil("RootPanel/cash")
    self.diamondPanelGo = self:GetGoOrNil("RootPanel/diamond")
    self.pesoPanelGo = self:GetGoOrNil("RootPanel/instance")
    --1 现金进入方式，
    --2 钻石购买进入方式
    --3 比索(副本货币)进入当时
    self.enterType = 0  
    ShopManager:refreshBuySuccess(function(shopId)
        ShopManager:Buy(shopId, false, function()
            -- if self.cashPanelGo and self.cashPanelGo.activeSelf then
            if self.enterType and self.enterType == 1 then
                self:EnterToCashBuy()
            end

            -- if self.diamondPanelGo and self.diamondPanelGo.activeSelf then
            if self.enterType and self.enterType == 2 then
                self:EnterToDiamondBuy()
            end

            if self.enterType and self.enterType == 3 then
                self:EnterToPesoBuy()
            end
        end,
        function()
            local data = ConfigMgr.config_shop[shopId]
            if data then
                GameTableDefine.InstanceFlyIconManager:StorageShopItem(shopId)
                PurchaseSuccessUI:SuccessBuy(shopId,nil,nil,nil,nil,function()
                    GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                    ShopInstantUI:SuccessBuy()
                end)
            end
        end, true)
    end)
    self.m_data = {}
    -- 从shop_frame表中添加
    local shopFrameCfg = ConfigMgr.config_shop_frame
    local shopCfg = ConfigMgr.config_shop
    for i, v in ipairs(shopFrameCfg or {}) do
        local isAdd = false
        if v.frame == "frame2" then
            isAdd = true
        elseif v.frame == "frameCash" and v.country ~= 0 and GameTableDefine.CountryMode:GetCurrCountry() == v.country then
            isAdd = true
        end
        if isAdd then
            local item = {}
            for k, m in pairs(v) do
                item[k] = m
            end
            table.insert(self.m_data, item)
        end
        
    end
    -- 从shop_frame_instance表中添加
    local shopFrameInsCfg = InstanceDataManager.config_shop_frame_instance
    for i, v in pairs(shopFrameInsCfg or {}) do
        local isAdd = false
        if v.frame == "framePeso" then
            isAdd = true
        end
        if isAdd then
            local item = {}
            for k, m in pairs(v) do
                item[k] = m
            end
            table.insert(self.m_data, item)
        end
        
    end
    self:SetButtonClickHandler(self:GetComp("RootPanel/top/QuitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
end


function ShopInstantUIView:EnterToDiamondBuy(needOpen)
    if not needOpen then
        self.enterType = 2
        self.cashPanelGo:SetActive(false)
        self.pesoPanelGo:SetActive(false)
    else
        if needOpen == 1 then
            self.cashPanelGo:SetActive(true)
        elseif needOpen == 3 then
            self.pesoPanelGo:SetActive(true)
        end
    end
    self.diamondPanelGo:SetActive(true)
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/diamond/title/QuitBtn", "Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
    --根据数据进行初始化了
    local diamondData = nil
    if self.m_data and Tools:GetTableSize(self.m_data) > 0 then
        for k, data in pairs(self.m_data) do
            if data.frame == "frame2" then
                diamondData = data
                break
            end
        end
    end
    if not diamondData then
        self:DestroyModeUIObject()
        return
    end
    local temp = self:GetGoOrNil(self.diamondPanelGo, "sale/temp")
    if not temp then
        return
    end
    for k = 1, Tools:GetTableSize(diamondData.contents) do
        local v = diamondData.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempDetails(centGo, diamondData, v)
        end
    end
end

function ShopInstantUIView:EnterToCashBuy()
    self.enterType = 1
    self.cashPanelGo:SetActive(true)
    self.diamondPanelGo:SetActive(false)
    self.pesoPanelGo:SetActive(false)
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/cash/title/QuitBtn", "Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
    --根据数据进行初始化了
    local cashData = nil
    if self.m_data and Tools:GetTableSize(self.m_data) > 0 then
        for k, data in pairs(self.m_data) do
            if data.frame == "frameCash" then
                cashData = data
                break
            end
        end
    end
    if not cashData then
        self:DestroyModeUIObject()
        return
    end
    local temp = self:GetGoOrNil(self.cashPanelGo, "sale/temp")
    if not temp then
        return
    end
    local isNeedOpenDiamond = true
    for k = 1, Tools:GetTableSize(cashData.contents) do
        local v = cashData.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        local canBuy = ShopManager:Buy(v.id, true)
        if canBuy then
            isNeedOpenDiamond = false
        end
        if centGo then
            self:SetTempDetails(centGo, cashData, v)
        end
    end
    --检测是否需要打开钻石购买界面
    if isNeedOpenDiamond then
        self:EnterToDiamondBuy(1)
    end
end

function ShopInstantUIView:EnterToPesoBuy()
    self.enterType = 3
    self.cashPanelGo:SetActive(false)
    self.diamondPanelGo:SetActive(false)
    self.pesoPanelGo:SetActive(true)
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/cash/title/QuitBtn", "Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
    --根据数据进行初始化了
    local pesoData = nil
    if self.m_data and Tools:GetTableSize(self.m_data) > 0 then
        for k, data in pairs(self.m_data) do
            if data.frame == "framePeso" then
                pesoData = data
                break
            end
        end
    end
    if not pesoData then
        self:DestroyModeUIObject()
        return
    end
    local temp = self:GetGoOrNil(self.pesoPanelGo, "sale/temp")
    if not temp then
        return
    end
    local isNeedOpenDiamond = true
    local isLastOneDay = GameTableDefine.InstanceDataManager:IsLastOneDay()

    for k = 1, Tools:GetTableSize(pesoData.content) do
        local v = pesoData.content[k]
        local shopCfg = ConfigMgr.config_shop[v.shopID]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        local canBuy,value = ShopManager:Buy(shopCfg.id, true)
        if canBuy then
            isNeedOpenDiamond = false
        end
        if centGo then
            self:SetTempDetails(centGo, pesoData, shopCfg)
        end
        self:GetGo(centGo, "offvalue"):SetActive(isLastOneDay)
        self:GetGo(centGo, "dBtn"):SetActive(not isLastOneDay)
        self:GetGo(centGo, "dBtn_sale"):SetActive(isLastOneDay)
        self:SetText(centGo, "offvalue/num", "-"..math.ceil(GameTableDefine.InstanceDataManager:GetLastOneDayDiscount() * 100) .. "%")
        self:SetText(centGo, "dBtn_sale/price_old/text", shopCfg.diamond )
        self:SetText(centGo, "dBtn_sale/price_new/text", math.ceil(shopCfg.diamond * (1 - GameTableDefine.InstanceDataManager:GetLastOneDayDiscount())))
    end
    --检测是否需要打开钻石购买界面
    if isNeedOpenDiamond then
        self:EnterToDiamondBuy(3)
    end
    -- print("========================",GameTimeManager:GetCurrentServerTimeInMilliSec())

end

function ShopInstantUIView:SetTempDetails(centGo, rootData, data, isNewNum)
    --绑定具体某个商品的显示以及点击的效果
    local v = ConfigMgr.config_shop[data.id]
    if v.name then
        self:SetText(centGo, "name", GameTextLoader:ReadText(v.name))
    end
    if v.desc then
        self:SetText(centGo, "desc", GameTextLoader:ReadText(v.desc))
    end

    local value = ShopManager:GetValueByShopId(data.id)

    if v.type == 3 then
        local isFirstDouble = FirstPurchaseUI:IsFirstDouble(data.id)
        if isFirstDouble then
            value = math.floor(value / 2)
        end
        self:GetGo(centGo, "double"):SetActive(isFirstDouble)
    end

    local valueShow = ShopManager:SetValueToShow(value, v)

    if v.type == 13 or v.type == 14 then
        for k,v in pairs(valueShow) do
            valueShow = v
            break
        end
    end
    local cashIcon = nil
    if GameStateManager:IsInstanceState() then
        cashIcon = InstanceDataManager:GetInstanceBind().cashIcon

    else
        if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
            cashIcon = "icon_cash_002"
        elseif GameTableDefine.CountryMode:GetCurrCountry() == 1 then
            cashIcon = "icon_cash_001"
        end

    end
    self:SetText(centGo, "num/num", valueShow)
    local cashImage = self:GetComp(centGo, "num/icon", "Image")

    if cashImage and cashIcon then
        self:SetSprite(cashImage, "UI_Shop", cashIcon)
    end
    
    self:SetSprite(self:GetComp(centGo, "icon", "Image"), "UI_Shop", v.icon)


    local btn = nil
    local btnDiamond = self:GetComp(centGo, "dBtn", "Button")
    local btnCash = self:GetComp(centGo, "mBtn", "Button")
    local btnAd = self:GetComp(centGo, "aBtn", "Button")
    local btnDiamondSale = self:GetComp(centGo, "dBtn_sale", "Button")

    btnDiamond.gameObject:SetActive(v.diamond ~= nil)
    btnCash.gameObject:SetActive(v.iap_id ~= nil)
    btnAd.gameObject:SetActive(v.adTime ~= nil)
    
    local btn = btnDiamond
    if v.iap_id then
        btn = btnCash
    elseif v.adTime then
        btn = btnAd
    elseif v.type == 25 and GameTableDefine.InstanceDataManager:IsLastOneDay() then
        btn = btnDiamondSale
    end

    local amountEnough = ShopManager:CheckBuyTimes(data.id, data.amount)--起名不太好,和shop表的amount一样了,实际上是另外的,表示数量限制的    
    btn.interactable = amountEnough
    
    if v.iap_id then
        local price = Shop:GetShopItemPrice(v.id)
        local priceOriginal, priceNum, comma = IAP:GetPriceDouble(v.id)
        local trackPrice = Shop:GetShopItemPrice(v.id, true)--美元单位
        local discount = GameTableDefine.IntroduceUI:GetDiscountByShopId(v.id)
        if discount <= 0 then
            discount = 0
        end
        self:SetText(centGo ,"content/offvalue/num", math.floor(discount * 100) .. "%" .. "\n" .. "Off")

        local cheatPrice = 0
        if priceNum then
            cheatPrice = tonumber(priceNum) / (1 - discount)
        end
        if GameDeviceManager:IsiOSDevice() then
            if cheatPrice == 0 then
                cheatPrice = priceOriginal
            elseif tonumber(cheatPrice) then
                cheatPrice = DeviceUtil.InvokeNativeMethod("formaterPrice", cheatPrice)
            end
        else
            --cheatPrice = string.format("%.2f", cheatPrice)  --保留两位小数
            -- if comma ~= "." then
            --     cheatPrice = string.gsub(cheatPrice, '%.', ',')
            -- end
            -- if priceNumFormat then
            --     cheatPrice = string.gsub(price, priceNumFormat, cheatPrice)
            -- end
            if priceNum then
                local head = string.gsub(priceOriginal,"%p","")
                head = string.gsub(head,"%d","")
                local back = ""
                if comma then
                    local cheatPriceInt = math.floor( cheatPrice )
                    local cheatPriceStr = tostring(cheatPriceInt)
                    local digitDiff = #cheatPriceStr - #priceNum
                    back = cheatPriceStr
    
                    for k,v in pairs(comma) do 
                        local front = string.sub(back, 1, k +digitDiff -1 )
                        local after = string.sub(back, k +digitDiff -1 +1)
        
                        back = front..v..after
                    end
                end
                cheatPrice = head..back
            else
                cheatPrice = priceOriginal
            end
           
        end
        self:SetText(btn.gameObject, "common", cheatPrice)
        self:SetText(btn.gameObject, "text", price)
        --GameSDKs:TrackForeign("store", {operation_type = 0, product_id = IAP:GetPurchaseId(v.iap_id), pay_type = 1, cost_num = trackPrice})
        -- 瓦瑞尔要求"ad_view"和"purchase" state为0事件不上传了2022-10-13
        -- GameSDKs:TrackForeign("purchase", {product_id = IAP:GetPurchaseId(v.iap_id), price = trackPrice, state = 0})

        self:SetButtonClickHandler(btn, function()
            btn.interactable = false
            if v.type == 12 and v.param3[1] == 1 then--新手礼包
                local canBuy = ShopManager:canBuyNewGift(v.id)
                if not canBuy then
                    --TODO:提示礼包已过期
                    return
                end
            end           
            GameSDKs:TrackForeign("store", {source = 2, operation_type = 2, product_id = IAP:GetPurchaseId(v.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice)})
            Shop:CreateShopItemOrder(data.id, btn, 3)
        end)
    elseif v.diamond then
        self:SetText(btn.gameObject, "text", Tools:SeparateNumberWithComma(v.diamond))
       
        local canBuy,value,type = ShopManager:Buy(data.id, true)
        local cost = v.diamond 
        if (v.type == 22 or v.type == 25) and GameTableDefine.InstanceDataManager:IsLastOneDay() then
            local discount = GameTableDefine.InstanceDataManager:GetLastOneDayDiscount() or 0
            if discount > 0 and discount <= 1 then
                cost = v.diamond * (1 - discount)
            end
        end
        btn.interactable = canBuy
        self:SetButtonClickHandler(btn, function()
            
            GameSDKs:TrackForeign("store", {source = 2, operation_type = 2, product_id = data.id, pay_type = 3, cost_num_new = tonumber(cost)})
            if canBuy then
                ShopManager:Buy(data.id, false, function()
                    btn.interactable = true
                    -- if self.cashPanelGo and self.cashPanelGo.activeSelf then
                    if self.enterType and self.enterType == 1 then
                        self:EnterToCashBuy()
                    end
        
                    -- if self.diamondPanelGo and self.diamondPanelGo.activeSelf then
                    if self.enterType and self.enterType == 2 then
                        self:EnterToDiamondBuy()
                    end

                    if self.enterType and self.enterType == 3 then
                        InstanceDataManager:AddCurInstanceCoin(value)
                        self:EnterToPesoBuy()
                    end
                end,function()
                    local data = ConfigMgr.config_shop[data.id]
                    if data then
                        GameTableDefine.InstanceFlyIconManager:StorageShopItem(data.id)
                        PurchaseSuccessUI:SuccessBuy(data.id,nil,nil,nil,nil,function()
                            GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                            ShopInstantUI:SuccessBuy()
                        end)
                    end
                end, true
                )    
            else
                GameSDKs:TrackForeign("store", {source = 2, operation_type = 3, product_id = IAP:GetPurchaseId(data.diamond), pay_type = 3, cost_num_new = tonumber(data.diamond)})
            end
        end)
    end
end

function ShopInstantUIView:CheckDataAndGameObject(temp, data, index)
    local tarans = temp.transform.parent
    local go = tarans.gameObject
    local centTrans = self:GetTrans(go, "temp_"..index)
    temp:SetActive(false)
    if data then
        if not centTrans or centTrans:IsNull() then
            local newGo = GameObject.Instantiate(temp, tarans)
            newGo.name = "temp_"..index
            newGo:SetActive(true)
            return newGo
        else
            centTrans.gameObject:SetActive(true)
        end
        return centTrans.gameObject
    else
        if centTrans and not centTrans:IsNull() then
            centTrans.gameObject:SetActive(false)
        end
        return nil
    end
end

function ShopInstantUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    self.super:OnExit(self)
    FirstPurchaseUI:UnlockEnterShopUITime()
end
return ShopInstantUIView