local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local Shop = GameTableDefine.Shop
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local ConfigMgr = GameTableDefine.ConfigMgr
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local LimitPackUI = GameTableDefine.LimitPackUI
local ShopManager = GameTableDefine.ShopManager
local CountryMode = GameTableDefine.CountryMode
---@class LimitPackUIView:UIBaseView
local LimitPackUIView = Class("LimitPackUIView", UIView)

function LimitPackUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.rootGO = nil
end

function LimitPackUIView:OnEnter()
    GameTableDefine.TimeLimitedActivitiesManager:SetEnterLimitPack()
    
    -- 根据主题初始化根节点
    local packData = LimitPackUI:GetLimitPackData()
    self.rootGO = self:GetGo("background/" .. packData.theme)
    self.rootGO:SetActive(true)

    self:SetButtonClickHandler(self:GetComp(self.rootGO, "bg/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    --购买成功事件注册
    ShopManager:refreshBuySuccess(function(shopId)      
        ShopManager:Buy(shopId, false, function()
            self:RefreshAllBuyBtnState()
        end)
    end)
    --购买失败事件注册
    ShopManager:refreshBuyFail(function(shopId)
        
    end)
    self.countDown = GameTimer:CreateNewMilliSecTimer(1000,function()
        self:SetText(self.rootGO, "time/time_txt", GameTimeManager:FormatTimeLength(LimitPackUI:GetTimeRemaining()))
    end, true, true)
    
    -- 标题
    self:SetText(self.rootGO, "title/title_txt", packData.title_str)
    --self:SetSprite(self:GetComp(self.rootGO, "title", "Image"), "UI_Common", packData.background)
    
    -- 礼包内容
    local activePackConfigs = LimitPackUI:GetAllActivePack()
    local packCount = #activePackConfigs
    if packCount < 2 then
        error("限时礼包配置少于2个，限时礼包每个group下应该配刚好2个")
    elseif packCount >2 then
        error("限时礼包配置大于2个，限时礼包每个group下应该配刚好2个")
    end
    for i,config in ipairs(activePackConfigs) do
        -- 前景图
        --local bannerPath = self.rootGO, "Reward/item".. i .."/banner_" .. CountryMode.m_currCountry
        --self:GetGo(bannerPath):SetActive(true)
        --local bgImage = self:GetComp(bannerPath,"Image")
        --if bgImage then
        --    self:SetSprite(bgImage,"UI_Shop",config.banner)
        --end
        -- 背景图
        --local pack_bgPath = self.rootGO, "Reward/item".. i
        --self:GetGo(pack_bgPath):SetActive(true)
        --local bgImage = self:GetComp(pack_bgPath,"Image")
        --if bgImage then
        --    self:SetSprite(bgImage,"UI_Common",config.pack_bg)
        --end
        -- 商品区域背景图
        --local items_bgPath = self.rootGO, "Reward/item".. i .. "/icon"
        --self:GetGo(items_bgPath):SetActive(true)
        --local bgImage = self:GetComp(items_bgPath,"Image")
        --if bgImage then
        --    self:SetSprite(bgImage,"UI_Common",config.items_bg)
        --end
        
        local path = "Reward/item".. i .."/icon/item1"
        self:SetTempGo(self:GetGo(self.rootGO, path), #config.items, function(index, go)
            local itemConfig = config.items[index]
            local itemCount = itemConfig.count or 1
            local itemShopID = itemConfig.id ---这个道具的ShopID
            local cfgShop = ConfigMgr.config_shop[itemShopID]
            local icon = self:GetComp(go, "bg/icon", "Image")
            self:SetSprite(icon, "UI_Shop", cfgShop.icon)
            --local bg = self:GetComp(go,"", "Image")
            --self:SetSprite(bg, "UI_Common", itemConfig.bg)
            local value,typeName = ShopManager:GetValueByShopId(itemShopID)
            if tonumber(value) ~= nil then
                value = value * itemCount
            end
            local showValue = ShopManager:SetValueToShow(value, cfgShop)
            if tonumber(value) == nil or typeName == "offline" or typeName == "income"then
                showValue = 1
                self:SetText(go, "bg2/txt","x" .. showValue)
            elseif typeName == "cash" then
                if CountryMode.m_currCountry == 1 then
                    self:SetSprite(icon, "UI_Shop", cfgShop.icon)
                elseif CountryMode.m_currCountry == 2 then
                    self:SetSprite(icon, "UI_Shop", cfgShop.icon .. "_" .. "euro")
                end
                self:SetText(go, "bg2/txt", showValue)
            else
                self:SetText(go, "bg2/txt","x" .. showValue)
            end
            
            local tip = self:GetGo(go, "bg/tip")
            if typeName == "pet" or typeName == "dressup" or typeName == "emplo" or typeName == "offline" or typeName == "income"then
                tip:SetActive(true)
                self:SetButtonClickHandler(self:GetComp(go,"bg/icon" ,"Button"), function()
                    self:SetInfoPanel(cfgShop, go,itemCount)
                end)
            else
                tip:SetActive(false)
            end
            self:SetButtonClickHandler(self:GetComp(go, "bg","Button"), function()
                tip:SetActive(false)
            end)
        end)
        local price,originPrice,discount = LimitPackUI:GetPrice(config)
        self:SetText(self.rootGO, "Reward/item".. i .."/buy/btn_claim/txt", price)
        self:SetText(self.rootGO, "Reward/item".. i .."/buy/btn_claim/common", originPrice)
        self:SetText(self.rootGO, "Reward/item".. i .."/offvalue/num", "-"..(math.floor((1-discount)*100)).."%")
        local buyBtn = self:GetComp(self.rootGO, "Reward/item".. i .."/buy/btn_claim","Button")
        self:RefreshBtnState(buyBtn, config.sku_id,config.buy_num)
        self:SetButtonClickHandler(buyBtn, function()
            local realItemsData = {}
            for realKey, realItem in pairs(config.items) do
                local realData = {}
                realData.shopId = realItem.id
                realData.num = realItem.count
                table.insert(realItemsData, realData)
            end
            Shop:CreateShopItemOrder(config.sku_id, nil, "", realItemsData)
        end)
    end
    --打开限时礼包的埋点
    GameSDKs:TrackForeign("rank_activity", {name = "LimitPack", operation = "1"})

    --加载在线图片，暂时不用
    --UnityHelper.LoadInternetSprite("https://XXXXXX",self,function(sprite)
    --    local image = self:GetComp(self.m_uiObj,self.rootGO, "Image","Image")
    --    if image then
    --        if sprite then
    --            image.sprite = sprite
    --        else
    --            image.sprite = nil
    --        end
    --    end
    --end)
end

--刷新所有按钮的可交互
function LimitPackUIView:RefreshAllBuyBtnState()
    local activePackConfigs = LimitPackUI:GetAllActivePack()
    for k,v in pairs(activePackConfigs) do
        local canBuy = ShopManager:CheckLimitPackBuyTimes(v.sku_id,v.buy_num)
        local buyBtn = self:GetComp(self.rootGO, "Reward/item".. k .."/buy/btn_claim","Button")
        buyBtn.interactable = canBuy
    end
end

--刷新对应按钮的可交互
function LimitPackUIView:RefreshBtnState(buyBtn, shop_id, available_num)
    local canBuy = ShopManager:CheckLimitPackBuyTimes(shop_id,available_num)
    buyBtn.interactable = canBuy
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function LimitPackUIView:SetTempGo(temp, num, cb)      
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    for i = 1,num do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        go:SetActive(true)
        go.name = "temp" .. i
        if cb then
            cb(i, go) 
        end              
    end          
end

--设置详细信息界面
---@param complex number 数量
function LimitPackUIView:SetInfoPanel(cfgShop , go,complex)
    
    local value,typeName = ShopManager:GetValueByShopId(cfgShop.id)
    if tonumber(value) ~= nil then
        value = value * complex
    end
    local showValue = ShopManager:SetValueToShow(value, cfgShop) 
    
    local confirmPanel = self:GetGo(self.rootGO, "confirmPanel")
    local info = self:GetGo(self.rootGO, "confirmPanel/info")
    info.transform.position = go.transform.position
    self:SetText(confirmPanel, "info/title/txt", GameTextLoader:ReadText(cfgShop.name))

    local reward = self:GetComp(confirmPanel, "info/content/reward/icon", "Image")
    self:SetSprite(reward, "UI_Shop", cfgShop.icon)

    self:SetText(confirmPanel, "info/content/txt", GameTextLoader:ReadText(cfgShop.desc))
    self:GetGo(confirmPanel, "info/content/txt"):SetActive(true)
    if tonumber(value) == nil then
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        for k,v in pairs(showValue) do
            if k == "income" then
                self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_income")
                self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. v)
            elseif k == "offline" then
                self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_offline")
                self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. v .. "H")
            elseif k == "mood" then
                self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_mood")
                self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. v)
            end
        end
        --elseif typeName == "cash" then
        --    self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        --    self:GetGo(confirmPanel, "info/content/txt"):SetActive(false)
        --    self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Main", CountryMode.cash_icon)
        --    self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. showValue)
        --    if CountryMode.m_currCountry == 1 then
        --        self:SetSprite(reward, "UI_Shop", cfgShop.icon)
        --    elseif CountryMode.m_currCountry == 2 then
        --        self:SetSprite(reward, "UI_Shop", cfgShop.icon  .. "_" .. "euro")
        --    end
    elseif typeName == "offline" then
        --离线经理
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_offline")
        self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. showValue .. "H")
    elseif typeName == "income" then
        --收益经理
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_income")
        self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. showValue)
    else
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(false)
    end

    confirmPanel:SetActive(true)
end

function LimitPackUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
	self.super:OnExit(self)
    GameTimer:StopTimer(self.countDown)
end

function LimitPackUIView:OnPause()
    if self.m_uiObj then
        self.m_uiObj:SetActive(false)
    end
end

function LimitPackUIView:OnResume()
    if self.m_uiObj then
        self.m_uiObj:SetActive(true)
    end
end

return LimitPackUIView