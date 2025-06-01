local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local CountryMode = GameTableDefine.CountryMode
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ShopManager = GameTableDefine.ShopManager
local MainUI = GameTableDefine.MainUI
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local FeelUtil = CS.Common.Utils.FeelUtil

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ResourceManger = GameTableDefine.ResourceManger
local ResMgr = GameTableDefine.ResourceManger
local GameObject = CS.UnityEngine.GameObject
local CarShopUI = GameTableDefine.BuyCarShopUI

---@class PurchaseSuccessUIView:UIBaseView
local PurchaseSuccessUIView = Class("PurchaseSuccessUIView", UIView)

function PurchaseSuccessUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function PurchaseSuccessUIView:OnEnter()
    
end

--显示效果
function PurchaseSuccessUIView:SuccessBuy(shopId, allShow, cb, isGift, exitCb, extendNum)--{showValue, type}
    self.exitCb = exitCb
    if self.successData then
        --if self.successData[shopId] then
        --    self.successData[shopId] = Tools:MergeTable(self.successData[shopId], allShow)
        --else
        --    self.successData[shopId] = allShow
        --end
        self.successData[shopId] = { data = allShow, callback = cb }
        
        return
    else
        self.successData = {}
        self.successData[shopId] = { data = allShow, callback = cb }
        self:SetText("title/text", GameTextLoader:ReadText(isGift and "TXT_WHEEL_CONGRAT" or "TXT_TIP_BUY_SUCCESS"))
    end

    local root = self:GetGo("")
    local openFeel = self:GetGo(root, "PurchaseFeedback")
    local closeFeel = self:GetGo(root, "CloseFeedback")
    local allType = {"income", "offline", "mood", "exp", "cash", "diamond", "ad", "monthd", "fund" , "snack" , "boost",
                     "realcash", "dressup", "instance_time", "instance_landmark", "instance_cash","pass_game_ticket",
                     "ticket", "Wheel_Ticket", "ceoChest"}
    local showSuccess = nil
    showSuccess = function()
        local id,data = next(self.successData)
        if data == nil then
            --if cb then cb() end
            InstanceMainViewUI:Refresh()
            MainUI:UpdateResourceUI()
            EventManager:UnregEvent("purchase_success_close")
            self:DestroyModeUIObject()
            return
        end
        local currData = table.remove(data.data, 1)
        if currData == nil then
            self.successData[id] = nil
            if data.callback then
                data.callback()
            end
            showSuccess()
            return
        end

        local cfg = ShopManager:GetCfg(id)
        
        local title
        --旧版标题
        -- if cfg.param3 and cfg.param3[1] then
        --     title = ShopManager:GetTilet(cfg.type, id, cfg.param3[1])
        -- else
        --     title = ShopManager:GetTilet(cfg.type, id)
        -- end
        --改版
        if cfg.name then
            title = cfg.name
        end

        local closeBtn = self:GetComp(root, "bg", "Button")
        self:SetButtonClickHandler(closeBtn, function()
            EventManager:RegEvent("purchase_success_close", function()
                if showSuccess then showSuccess() end
            end)
            FeelUtil.PlayFeel(closeFeel, "purchase_success_close")
        end)

        local icon = self:GetComp(root, "sale/icon", "Image")
        self:SetSprite(icon, "UI_Shop", currData.icon, nil, true)

        self:GetGo(root, "reward/title"):SetActive(title and title ~= "")
        
        if title and title ~= "" then
            self:SetText(root, "reward/title/text", GameTextLoader:ReadText(title))
        else
            self:GetGo(root, "reward/title"):SetActive(false)
        end

        local currType = currData.typeName

        local rewardRoot = self:GetGo(root, "reward")
        for k,v in pairs(allType) do
            self:GetGo(rewardRoot, v):SetActive(currType == v)
        end

        if currType and currType ~= "pet" and currType ~= "emplo" then
            local currRoot = self:GetGo(rewardRoot, currType)
            if currData.show and currType ~= "instance_landmark" then
                if tonumber(currData.show) then
                    self:SetText(currRoot, "num", Tools:SeparateNumberWithComma(currData.show))
                else
                    self:SetText(currRoot, "num", currData.show)
                end
                if currData.icon and (currType == "snack" or currType == "boost" or currType == "dressup") then
                    self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop",currData.icon)            
                end
            end
            if currType == "cash" then
                --self:SetSprite(self:GetComp(currRoot, "icon", "Image"), "UI_Main", CountryMode.cash_icon)
                
                local str = string.gsub(currData.icon,"%d", 2)
                self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop", str)    
            elseif currType and currType == "instance_time" then
                local currRoot = self:GetGo(rewardRoot, currType)
                --这里要把产出给算出来然后逐个显示,这里有问题是如果是礼包中的单个物品是没有id的，所以强制加了一个id属性
                local totalTime = 0
                if cfg.type == 12 then
                    if currData.shopId then
                        local childCfg = GameTableDefine.ConfigMgr.config_shop[currData.shopId]
                        if childCfg then
                            totalTime = tonumber(childCfg.param[1]) * 60
                        end
                    end
                else
                    totalTime = cfg.param[1] * 60
                end
                local instanceProduction = GameTableDefine.InstanceModel:GetCurProductionsByTime(totalTime)
                if instanceProduction and Tools:GetTableSize(instanceProduction) > 0 then
                    self.m_instanceProItemGos = {}
                    local itemGo = self:GetGoOrNil(currRoot, "1")
                    if itemGo then
                        table.insert(self.m_instanceProItemGos, itemGo)
                    end
                    if Tools:GetTableSize(instanceProduction) > 1 then
                        for i = 2, Tools:GetTableSize(instanceProduction) do
                            local tmpItemGo = GameObject.Instantiate(itemGo, currRoot.transform)
                            tmpItemGo.name = tostring(i)
                            table.insert(self.m_instanceProItemGos, tmpItemGo)
                        end
                    end
                    for k, v in pairs(instanceProduction) do
                        local resCfg =  GameTableDefine.InstanceDataManager.config_resource_instance[v.resourcesID]
                        -- if i <= Tools:GetTableSize(self.m_detailItemGo) and resCfg then
                        --     local resItemGo = self.m_detailItemGo[i]
                        --     self:SetSprite(self:GetComp(resItemGo, "icon", "Image"), "UI_Common", resCfg.icon)
                        --     self:SetText(resItemGo, "bg/num", Tools:SeparateNumberWithComma(v.amount))    
                        -- end
                        if k <= Tools:GetTableSize(self.m_instanceProItemGos) and resCfg then
                            local curItemGo = self.m_instanceProItemGos[k]
                            self:SetSprite(self:GetComp(curItemGo, "icon", "Image"), "UI_Common", resCfg.icon)
                            self:SetText(curItemGo, "num", "+"..Tools:SeparateNumberWithComma(v.amount))
                        end
                    end
                end
            elseif currType and currType == "instance_cash" then
                local currRoot = self:GetGo(rewardRoot, currType)
                local cashIcon = GameTableDefine.InstanceDataManager:GetInstanceBind().cashIcon
                local image = self:GetComp(currRoot,"icon","Image")
                self:SetSprite(image, "UI_Common",cashIcon)
            elseif currType and currType == "ceoChest" then
                local currRoot = self:GetGo(rewardRoot, currType)
                self:SetSprite(self:GetComp(currRoot, "icon", "Image"), "UI_Shop", currData.icon)
            end
            
        else
            local currRoot = nil
            if currData.show and type(currData.show) == "table" then
                for k,v in pairs(currData.show or {}) do
                    currRoot = self:GetGo(rewardRoot, k)
                    currRoot:SetActive(true)
                    self:SetText(currRoot, "num", v)
                end
            elseif currData.show then
                currRoot = self:GetGo(rewardRoot, "income")
                self:SetText(currRoot, "num", currData.show)
                currRoot:SetActive(true)
            end
            
        end
        FeelUtil.PlayFeel(openFeel)
    end

    showSuccess()
end


--显示买车效果 todo 可简化
function PurchaseSuccessUIView:SuccessBuyCar(carId, cb)

    self:SetText("title/text", GameTextLoader:ReadText( "TXT_TIP_BUY_SUCCESS"))

    local root = self:GetGo("")
    local openFeel = self:GetGo(root, "PurchaseFeedback")
    local closeFeel = self:GetGo(root, "CloseFeedback")
    local allType = {"income", "offline", "mood", "exp", "cash", "diamond", "ad", "monthd", "fund" , "snack" , "boost", "realcash" ,"forbes", "dressup", "instance_time", "instance_landmark", "instance_cash"}
    local showSuccess = nil
    showSuccess = function()
        local cfg = GameTableDefine.BuyCarShopUI:GetCarConfig(carId)
        local title = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_NAME")
        local carSprite = "icon_"..cfg["pfb"]

        local closeBtn = self:GetComp(root, "bg", "Button")
        self:SetButtonClickHandler(closeBtn, function()
            EventManager:RegEvent("purchase_success_close", function()
                if cb then cb() end
                MainUI:UpdateResourceUI()
                EventManager:UnregEvent("purchase_success_close")
                self:DestroyModeUIObject()
            end)
            FeelUtil.PlayFeel(closeFeel, "purchase_success_close")
        end)

        local icon = self:GetComp(root, "sale/icon", "Image")
        self:SetSprite(icon, "UI_Common", carSprite, nil, true)

        self:GetGo(root, "reward/title"):SetActive(title and title ~= "")

        if title and title ~= "" then
            self:SetText(root, "reward/title/text", title)
        else
            self:GetGo(root, "reward/title"):SetActive(false)
        end

        local currType = "forbes"
        local forbesNum = cfg["wealth_buff"]
        self:SetText(root, "reward/forbes/num", tostring(forbesNum))
        local rewardRoot = self:GetGo(root, "reward")
        for k,v in pairs(allType) do
            self:GetGo(rewardRoot, v):SetActive(currType == v)
        end
        local buyCarEffect = self:GetGoOrNil(root,"VFX_buy_car")
        if buyCarEffect then
            buyCarEffect:SetActive(true)
        end
        FeelUtil.PlayFeel(openFeel)
    end

    showSuccess()
end
--播放playList中存入的商品
-- function PurchaseSuccessUIView:PlayList()
--     local currData =  PurchaseSuccessUI.playList[1]
--     if not PurchaseSuccessUI.playList[1] then
--         self:DestroyModeUIObject()
--         return
--     end
--     local closeBtn = self:GetComp("bg", "Button")
--     local openFeel = self:GetGo("PurchaseFeedback")
--     local closeFeel = self:GetGo("CloseFeedback")
--     local allType = {"income", "offline", "mood", "exp", "cash", "diamond", "ad", "monthd", "fund" , "snack" , "boost", "realcash", "dressup"}
--     local id,data = next(currData)
--     local cfg = ShopManager:GetCfg(id)
--     local title = ShopManager:GetTilet(cfg.type, id)
--     local rewardRoot = self:GetGo("reward")
--     local currType = data.typeName
--     local icon = self:GetComp("sale/icon", "Image")
--     self:SetSprite(icon, "UI_Shop", data.icon, nil, true)
--     self:SetText("reward/title/text", GameTextLoader:ReadText(title))
--     for k,v in pairs(allType) do
--         self:GetGo(rewardRoot, v):SetActive(currType == v)
--     end
--     if currType ~= "pet" and currType ~= "emplo" then
--         local currRoot = self:GetGo(rewardRoot, currType)
--         if data.show then
--             self:SetText(currRoot, "num", data.show)
--             if data.icon and currType == "snack" then
--                 self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop",data.icon)
--             end
--             if data.icon and currType == "boost" then
--                 self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop",data.icon)
--             end
--             if data.icon and currType == "cash" then
--                 local str = string.gsub(data.icon,"%d", 2)
--                 self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop", str)
--             end
--             if data.icon and currType == "dressup" then
--                 str = data.icon
--                 self:SetSprite(self:GetComp(currRoot, "icon", "Image"),  "UI_Shop", str)
--             end
--             -- if data.icon and currType == "dressup" then
--             --     local str = string.gsub(data.icon)
--             -- end
--         end
--     else
--         local currRoot = nil
--         for k,v in pairs(data.show) do
--             currRoot = self:GetGo(rewardRoot, k)
--             currRoot:SetActive(true)
--             self:SetText(currRoot, "num", v)
--         end
--     end    
--     if Tools:GetTableSize(PurchaseSuccessUI.playList) <= 1 then
--         local feel = self:GetComp(closeFeel, "", "MMFeedbacks")
--         feel.Events.OnComplete:AddListener(function()
--             self:DestroyModeUIObject()
--         end)
--         self:SetButtonClickHandler(closeBtn, function()       
--             feel:PlayFeedbacks()                        
--         end)
--     else
--         local feel = self:GetComp(closeFeel, "", "MMFeedbacks")
--         feel.Events.OnComplete:AddListener(function()
--             self:PlayList()
--         end)
--         self:SetButtonClickHandler(closeBtn, function()            
--             feel:PlayFeedbacks()            
--         end) 
--     end
--     FeelUtil.PlayFeel(openFeel)
--     table.remove(PurchaseSuccessUI.playList, 1)
-- end


function PurchaseSuccessUIView:OnExit()
	self.super:OnExit(self)
    self.successData = nil
    if self.m_instanceProItemGos then
        for k, go in ipairs(self.m_instanceProItemGos) do
            if k ~= 1 then
                GameObject.Destroy(go)
            end
        end
        self.m_instanceProItemGos = nil
    end
    if self.exitCb then
        self.exitCb()
    end
end

return PurchaseSuccessUIView