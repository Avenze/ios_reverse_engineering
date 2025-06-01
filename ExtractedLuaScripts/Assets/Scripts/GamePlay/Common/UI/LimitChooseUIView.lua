local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local Shop = GameTableDefine.Shop
local ConfigMgr = GameTableDefine.ConfigMgr
local GameObject = CS.UnityEngine.GameObject
local LimitChooseUI = GameTableDefine.LimitChooseUI
local ShopManager = GameTableDefine.ShopManager
local CountryMode = GameTableDefine.CountryMode
---@class LimitChooseUIView:UIBaseView
local LimitChooseUIView = Class("LimitChooseUIView", UIView)

function LimitChooseUIView:ctor()
    self.super:ctor()
    self.m_rootGO = nil
    self.m_countDown = nil
    self.m_rewardsDetailPanel = nil ---@type UnityEngine.GameObject
end

function LimitChooseUIView:OnEnter()
    GameTableDefine.TimeLimitedActivitiesManager:SetEnterLimitChoose()
    --购买成功事件注册
    ShopManager:refreshBuySuccess(function(shopId)
        --购买成功,关闭界面,并发奖
        self:DestroyModeUIObject(false,function()
            ShopManager:Buy(shopId, false, nil)
        end)
    end)
    --购买失败事件注册
    ShopManager:refreshBuyFail(function(shopId)
        
    end)

    --打开限时多选一礼包的埋点
    GameSDKs:TrackForeign("rank_activity", {name = "bundlepack", operation = "1"})
end

function LimitChooseUIView:Init()
    self.m_saveData = LimitChooseUI:GetLimitChooseData()

    -- 根据主题初始化根节点
    if self.m_saveData.theme ~= "normal" then
        local normalNodeGO = self:GetGoOrNil("background/normal")
        if normalNodeGO then
            normalNodeGO:SetActive(false)
        end
    end

    self.m_rootGO = self:GetGo("background/" .. self.m_saveData.theme)
    self.m_rootGO:SetActive(true)

    self:SetButtonClickHandler(self:GetComp(self.m_rootGO, "bg/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self.m_rewardsDetailPanel = self:GetGo(self.m_rootGO,"confirmPanel")
    local detailPanelBtn = self:GetComp(self.m_rewardsDetailPanel,"bg", "Button")
    --self:SetButtonClickHandler(detailPanelBtn,function()
    --    self.m_rewardsDetailPanel:SetActive(false)
    --end)
    detailPanelBtn.interactable = true

    self:InitTitle()
    self:InitTotalPrice()
    self:InitPacks()
end

function LimitChooseUIView:InitTitle()

    self.m_countDown = GameTimer:CreateNewMilliSecTimer(1000,function()
        self:SetText(self.m_rootGO, "time/time_txt", GameTimeManager:FormatTimeLength(LimitChooseUI:GetTimeRemaining()))
    end, true, true)

    -- 标题
    self:SetText(self.m_rootGO, "title/title_txt", self.m_saveData.title_str)
end

function LimitChooseUIView:InitTotalPrice()
    --打包价格显示
    local price,originPrice,discount  = LimitChooseUI:GetPrice(self.m_saveData.shopID,self.m_saveData.discount_rate)

    self:SetText(self.m_rootGO, "Reward/btn_buyall/num", price)
    self:SetText(self.m_rootGO, "Reward/btn_buyall/num_1", originPrice)
    self:SetText(self.m_rootGO, "Reward/btn_buyall/offvalue/num", (math.floor((1-discount)*100)).."%")
    local buyBtn = self:GetComp(self.m_rootGO, "Reward/btn_buyall","Button")
    self:SetButtonClickHandler(buyBtn, function()
        --2025-1-8fy添加补单需要的相关附加数据
        local activePackConfigs = LimitChooseUI:GetAllActivePack()
        local realItemsData = {}
        for _, config in pairs(activePackConfigs) do
            for _k, item in pairs(config.items) do
                local realData = {}
                realData.shopId  = item.id
                realData.num = item.count
                table.insert(realItemsData, realData)
            end
        end
        Shop:CreateShopItemOrder(self.m_saveData.shopID, nil, "", realItemsData)
    end)
end

function LimitChooseUIView:InitPacks()
    -- 礼包内容
    local activePackConfigs = LimitChooseUI:GetAllActivePack()
    local packCount = #activePackConfigs
    if packCount < 3 then
        error("限时多选一礼包配置少于3个，限时多选一礼包每个group下应该配刚好3个")
    elseif packCount > 3 then
        error("限时多选一礼包配置大于3个，限时多选一礼包每个group下应该配刚好3个")
    end

    for i,config in ipairs(activePackConfigs) do
        local path = "Reward/item".. i .."/icon/item"
        local tempGO = self:GetGo(self.m_rootGO, path)
        self:SetTempGo(tempGO, #config.items, function(index, go)
            local itemConfig = config.items[index]
            local itemCount = itemConfig.count or 1
            local itemShopID = itemConfig.id ---这个道具的ShopID
            local cfgShop = ConfigMgr.config_shop[itemShopID]
            local icon = self:GetComp(go, "bg/icon", "Image")
            local showValue,showIcon = LimitChooseUI:GetShowValueString(itemShopID,itemCount)
            self:SetSprite(icon, "UI_Shop", showIcon,nil,false,true)
            self:SetText(go, "bg2/txt",showValue)
            self:SetText(go, "bg2/txt_2",showValue)
            local value,typeName = ShopManager:GetValueByShopId(itemShopID)
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
        local price,originPrice,discount = LimitChooseUI:GetPrice(config.sku_id,config.discount_rate)
        self:SetText(self.m_rootGO, "Reward/item".. i .."/btn_buy/num", price)
        --self:SetText(self.m_rootGO, "Reward/item".. i .."/buy/btn_claim/common", originPrice)
        --self:SetText(self.m_rootGO, "Reward/item".. i .."/offvalue/num", "-"..(math.floor((1-discount)*100)).."%")
        local buyBtn = self:GetComp(self.m_rootGO, "Reward/item".. i .."/btn_buy","Button")
        self:SetButtonClickHandler(buyBtn, function()
            --2025-1-8fy添加补单需要的相关附加数据
            local realItemsData = {}
            for _, item in pairs(config.items) do
                local realData = {}
                realData.shopId = item.id
                realData.num = item.count
                table.insert(realItemsData, realData)
            end
            Shop:CreateShopItemOrder(config.sku_id, nil, "", realItemsData)
        end)
    end
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function LimitChooseUIView:SetTempGo(temp, num, cb)
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
function LimitChooseUIView:SetInfoPanel(cfgShop , go,complex)
    
    local value,typeName = ShopManager:GetValueByShopId(cfgShop.id)
    if tonumber(value) ~= nil then
        value = value * complex
    end
    local showValue = ShopManager:SetValueToShow(value, cfgShop) 
    
    local confirmPanel = self.m_rewardsDetailPanel
    local info = self:GetGo(confirmPanel, "info")
    info.transform.position = go.transform.position
    self:SetText(confirmPanel, "info/title/txt", GameTextLoader:ReadText(cfgShop.name))

    local reward = self:GetComp(confirmPanel, "info/content/reward/icon", "Image")
    self:SetSprite(reward, "UI_Shop", cfgShop.icon,nil,false,true)

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

function LimitChooseUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
	self.super:OnExit(self)
    GameTimer:StopTimer(self.m_countDown)
end

function LimitChooseUIView:OnPause()
    if self.m_uiObj then
        self.m_uiObj:SetActive(false)
    end
end

function LimitChooseUIView:OnResume()
    if self.m_uiObj then
        self.m_uiObj:SetActive(true)
    end
end

return LimitChooseUIView