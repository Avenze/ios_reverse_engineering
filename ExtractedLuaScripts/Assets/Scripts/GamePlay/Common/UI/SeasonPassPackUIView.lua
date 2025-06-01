local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local SeasonPassPackUIView = Class("SeasonPassPackUIView", UIView)
local configMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local SeasonPassManager = GameTableDefine.SeasonPassManager
local Shop = GameTableDefine.Shop

local curShopID = nil

function SeasonPassPackUIView:ctor()
    self.m_saveData = nil
    self.m_buyBtn = nil
    self.m_packFlyIcon = nil
end

function SeasonPassPackUIView:OnEnter()

    self.m_buyBtn = self:GetComp("RootPanelr/buyBtn", "Button")

    self.m_packTimer = GameTimer:CreateNewTimer(1, function()
        local countDown = SeasonPassManager:GetActivityLeftTime()
        local timeStr
        --self:SetText("RootPanelr/title/timer/num", timeStr)
        if countDown > 86400 then
            local timeDate = GameTimeManager:GetTimeLengthDate(countDown)
            timeStr = string.format("%dd %dh",timeDate.d,timeDate.h)
        else
            timeStr = GameTimeManager:FormatTimeLength(countDown)
        end
        self:SetText("RootPanelr/title/timer/num", timeStr)
    end, true, true)
    
    self:SetButtonClickHandler(self.m_buyBtn, function()
        Shop:CreateShopItemOrder(curShopID, self.m_buyBtn)
    end)
    
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    
    --购买成功
    ShopManager:refreshBuySuccess(function(shopId)
        local shopCfg = ShopManager:GetCfg(shopId)
        ShopManager:Buy_LimitPackReward(shopId, function()
            --通行证小游戏票数量变化埋点
            local ticketNum = 0
            if shopId == curShopID then
                for i = 1, #shopCfg.param do
                    local childShopCfg = ShopManager:GetCfg(shopCfg.param[i])
                    if childShopCfg.type == 37 then
                        ticketNum = ticketNum + childShopCfg.amount
                    end
                    --2025-1-7 fy  通行证门票礼包获取钻石埋点 
                    if childShopCfg and childShopCfg.type == 3 then
                        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证门票礼包", behaviour = 1, num_new = tonumber(childShopCfg.amount)})
                    end
                end
            end
            if ticketNum > 0 then
                local leftTicket = SeasonPassManager:GetCurGameManager():GetTicketNum()
                GameSDKs:TrackForeign("pass_ticket", {behavior = 1,num = ticketNum,left = leftTicket,source = 5})
            end
        end, nil)
        GameTableDefine.SeasonPassUI:FlyIcon(self.m_packFlyIcon, function()
            self.m_packFlyIcon = {}
            GameTableDefine.SeasonPassUI:RefreshGameView()
        end)
        SeasonPassManager:AddBuyPackTimes(shopId, 1)
        self:DestroyModeUIObject()
    end)
    --构面失败
    ShopManager:refreshBuyFail(function(shopId)
        self:Init(shopId)
    end)
end

function SeasonPassPackUIView:Init(shopID)
    curShopID = shopID or configMgr.config_global.pass_cnYear_ticketPack
    
    self:ShowPacks()
    
    local price = Shop:GetShopItemPrice(curShopID)
    self:SetText("RootPanelr/buyBtn/text", price)
    self.m_buyBtn.interactable = SeasonPassManager:CanBuyPack(curShopID)
    
    local buyTime = SeasonPassManager:GetPackBuyTime(curShopID)
    local curShopCfg = ShopManager:GetCfg(curShopID)
    self:SetText("RootPanelr/restrictBuy/num", curShopCfg.numLimit or 0 - buyTime)
end

function SeasonPassPackUIView:RefreshPackView()
    
end

function SeasonPassPackUIView:OnExit(isCloseView)
    
end

function SeasonPassPackUIView:ShowPacks()
    local packs = curShopID
    local packShopCfg = ShopManager:GetCfg(packs)
    local root = self:GetGo("RootPanelr/reward")
    local rewardsFlyIcon = {} ---@type SeasonPassFlyIconResInfo
    for i = 1, #packShopCfg.param do
        local itemName = "item_" .. i
        local go = self:GetGo(root, itemName)
        local shopCfg = ShopManager:GetCfg(packShopCfg.param[i])
        self:SetText(go, "bg/Num_Landmark/num_1", shopCfg.amount)
        self:SetText(go, "bg/Num_Landmark/num_2", shopCfg.amount)
        self:SetText(go, "bg/Num_Landmark/num_3", shopCfg.amount)
        
        table.insert(rewardsFlyIcon, { id = shopCfg.id, num = 1 })
    end
    self.m_packFlyIcon = rewardsFlyIcon
end


return SeasonPassPackUIView
