--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-16 10:34:52
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local GameResMgr = require("GameUtils.GameResManager")
local Shop = GameTableDefine.Shop
local ShopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceDataManager = GameTableDefine.InstanceDataManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI

local InstancePopUIView = Class("InstancePopUIView", UIView)

function InstancePopUIView:ctor()
    self.super:ctor()
end

function InstancePopUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/btn/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    ShopManager:refreshBuySuccess(function(shopId)
        ShopManager:Buy(shopId, false, function()
            
            -- self.m_list:UpdateData(true)
            local cfgShop = ConfigMgr.config_shop[shopId]
            if cfgShop.type == 12 then
                for _, childId in ipairs(cfgShop.param) do
                    InstanceDataManager:InstanceShopBuySccess(tonumber(childId))
                    GameTableDefine.InstanceFlyIconManager:StorageShopItem(childId)
                    GameTableDefine.InstanceMainViewUI:RefreshPackButton()
                end
            end
        end,
        function()
            local data = ConfigMgr.config_shop[shopId]
            if data then
                PurchaseSuccessUI:SuccessBuy(shopId, function()
                    self:DestroyModeUIObject()
                    GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                end)
            end
        end)
    end)
    ShopManager:refreshBuyFail(function(shopId)
        self:DestroyModeUIObject()
    end)
    local childNames = {"1184", "1185", "1186", "1187"}
    for _, name in ipairs(childNames) do
        local tmpGo = self:GetGoOrNil("RootPanel/"..name)
        if tmpGo then
            tmpGo:SetActive(false)
        end
    end
end

function InstancePopUIView:ShowGiftPop(shopID)
    local curDispGo = self:GetGoOrNil("RootPanel/"..tostring(shopID))
    if not curDispGo or not ShopManager:CheckBuyTimes(shopID) then
        self:DestroyModeUIObject()
        return
    end
    self.curShopID = shopID
    curDispGo:SetActive(true)
    local shopCfg = ConfigMgr.config_shop[shopID]
    if not shopCfg then
        self:DestroyModeUIObject()
        return
    end
    if not shopCfg.iap_id then
        self:DestroyModeUIObject()
        return
    end
    InstanceDataManager:SetInstanceOpenGiftMaxID(shopID)
    local price = Shop:GetShopItemPrice(shopCfg.id)
    local trackPrice = Shop:GetShopItemPrice(shopCfg.id, true)
    self:SetText("RootPanel/btn/goBtn/text", tostring(price))
    local btn = self:GetComp("RootPanel/btn/goBtn", "Button")
    btn.interactable = true
    self:SetButtonClickHandler(btn, function()
        btn.interactable = false
        GameSDKs:TrackForeign("store", {operation_type = 1, product_id = GameTableDefine.IAP:GetPurchaseId(shopCfg.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) or 0})
        local realItemsData = {shopId = shopID, num = 1}
        Shop:CreateShopItemOrder(shopCfg.id, btn, "", realItemsData)
    end)
    self:SetText("RootPanel/title/txt", GameTextLoader:ReadText(shopCfg.name))
end

function InstancePopUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    self.super:OnExit(self)
end

return InstancePopUIView