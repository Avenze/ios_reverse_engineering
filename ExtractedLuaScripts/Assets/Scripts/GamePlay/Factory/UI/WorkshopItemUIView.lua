local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local ChooseUI = GameTableDefine.ChooseUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local WorkshopItemUI = GameTableDefine.WorkshopItemUI
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local CfgMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local FactoryMode = GameTableDefine.FactoryMode
local ResMgr = GameTableDefine.ResourceManger
local TimerMgr = GameTimeManager
local Shop = GameTableDefine.Shop

local GameObject = CS.UnityEngine.GameObject
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local WorkshopItemUIView = Class("WorkshopItemUIView", UIView)

function WorkshopItemUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function WorkshopItemUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
    
    self:Init()
    self:refresh()
end

function WorkshopItemUIView:OpenUI(workshopId)
    self.workshopId = workshopId    
    self.workshopData = FactoryMode:GetWorkShopdata(self.workshopId)
end

function WorkshopItemUIView:Init()
    self.cfgBoots = CfgMgr.config_boost
    self.CurSelection = 1
end

function WorkshopItemUIView:refresh()
    self:SetTempGo("RootPanel/frame/sale/temp", Tools:GetTableSize(self.cfgBoots), function(num,go)
        self:SetTemp(num,go)
    end) 
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function WorkshopItemUIView:SetTempGo(path ,num, cb)    
    local temp = self:GetGo(path)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    for i=1,num do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        go:SetActive(true)
        go.name = "temp" .. i
        cb(i, go)        
    end          
end

--对单个temp进行设置
function WorkshopItemUIView:SetTemp(type, go)
    local cfg = self.cfgBoots[type]
    local useBtn = self:GetComp(go, "mBtn", "Button")
    local buyBtn = self:GetComp(go, "dBtn", "Button")
    local diamondNeed = ShopManager:GetCfg(cfg.shopId).diamond
    --self:GetGo(go, "light"):SetActive(self.CurSelection == type)
    self:SetText(go, "count/num", WorkshopItemUI:GetBuffPropNum(type))
    self:SetText(go, "name", GameTextLoader:ReadText(cfg.name))
    local exist = WorkshopItemUI:GetBuffPropNum(type) and WorkshopItemUI:GetBuffPropNum(type) > 0 
    useBtn.gameObject:SetActive(exist)    
    buyBtn.gameObject:SetActive(not exist)
    local icon = self:GetComp(go,"icon","Image")
    self:SetSprite(icon, "UI_Shop", cfg.icon)
    self:SetText(go, "dBtn/text", diamondNeed)     
    if cfg.category == 1 then
        self:GetGo(go, "state/buff"):SetActive(true)
        self:SetText(go, "state/buff", "+" .. cfg.buff * 100 .. "%")
        --self:GetGo(go,"1/icon/clock"):SetActive(true)
        self:SetText(go, "state/time/num", cfg.duration)
        local UseBuffProp = function()
            WorkshopItemUI:SpendBuffProps(type, 1, function(isEnough)       
                if isEnough  then
                    WorkshopItemUI:AccelerateProduction(type, self.workshopId)
                    self:DestroyModeUIObject()
                    WorkShopInfoUI:PlayBuffAnim()
                    GameSDKs:TrackForeign("factory_item_use", {id = cfg.id, type = 1})
                end                 
            end)
        end
        self:SetButtonClickHandler(useBtn, function()
            if self.workshopData.state ~= 2 then
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_WORKSHOP_IDLE"))            
            elseif FactoryMode:CheckBuffUsefor(self.workshopData) then
                ChooseUI:Choose("TXT_TIP_BOOST_OVERRIDE", function()
                    UseBuffProp()
                end)
            else
                UseBuffProp()
            end
        end)
    elseif cfg.category == 2 then
        self:GetGo(go, "state/buff"):SetActive(false)
        self:SetText(go, "state/time/num", cfg.accelerate)
        --self:GetGo(go,"1/icon/clock"):SetActive(false)
        self:SetButtonClickHandler(useBtn, function()
            if self.workshopData.state == 2 then
                WorkshopItemUI:SpendBuffProps(type, 1, function(isEnough)       
                    if isEnough  then
                        FactoryMode:Airdrop(self.workshopId, cfg.accelerate, function(isEnough)
                            self:DestroyModeUIObject()
                            WorkShopInfoUI:CloseView()
                            local view = FactoryMode.m_floatUI[self.workshopId].view                    
                            view:ShowFactorySuperSpeedBoost(cfg, self.workshopId)
                            GameSDKs:TrackForeign("factory_item_use", {id = cfg.id, type = 2})
                        end)                                       
                    end                 
                end)
            else                
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_WORKSHOP_IDLE"))
            end            
        end)
    end
    buyBtn.interactable = (ResMgr:GetDiamond() >= diamondNeed)   
    self:SetButtonClickHandler(buyBtn, function()
        if diamondNeed <= ResMgr:GetDiamond() then
            ShopManager:Buy(cfg.shopId, false, function()                                        
            end,function()
                --WorkshopItemUI:AddBuffProps(WorkshopItemUI:GetTypeByShopId(cfg.shopId), 1)
                PurchaseSuccessUI:SuccessBuy(cfg.shopId)
                self:refresh()
            end)                
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "购买工厂的加速道具", behaviour = 2, num_new = tonumber(diamondNeed)})
        end           
    end)
end


function WorkshopItemUIView:OnExit()
	self.super:OnExit(self)
end

return WorkshopItemUIView