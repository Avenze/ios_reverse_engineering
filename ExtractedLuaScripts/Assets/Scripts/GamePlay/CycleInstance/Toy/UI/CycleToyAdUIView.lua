--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-09 14:27:30
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local CycleToyAdUI = GameTableDefine.CycleToyAdUI
local CityModel = GameTableDefine.CityMode
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


local CycleToyAdUIView = Class("CycleToyAdUIView", UIView)

function CycleToyAdUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CycleToyAdUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/btn/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    local adBtn = self:GetComp("RootPanel/MidPanel/btn/ConfirmBtn/Button","Button")
    self:SetButtonClickHandler(adBtn,function()
        CycleToyAdUI:ClaimResource(function()
            --通知npc回去
            local currentModel = CycleInstanceDataManager:GetCurrentModel()
            currentModel:EventInstanceBack()
            GameTableDefine.CycleToyMainViewUI:SetEventIAAActive(false)
            GameTableDefine.CycleToyMainViewUI:Refresh()
            self:DestroyModeUIObject()
        end,
        function()
            if adBtn then
                adBtn.interactable = true
            end
        end,
        function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            if adBtn then
                adBtn.interactable = true
            end
        end,CityModel:GetCurrentBuilding())

    end)
    
    self.m_model = CycleToyAdUI:GetUIModel()
    self:ShowView()
end

function CycleToyAdUIView:ShowView()
    
    -- 显示副本货币奖励
    local item = self:GetGo("RootPanel/MidPanel/reward/item")

    Tools:SetTempGo(item , 1 ,true ,function (go, index)
        local instanceBind = GameTableDefine.CycleInstanceDataManager:GetInstanceBind()
        self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Common", instanceBind.cashIcon)
        self:SetText(go,"num",BigNumber:FormatBigNumber(self.m_model.money))
    end )
end

function CycleToyAdUIView:OnExit()
	self.super:OnExit(self)
end

return CycleToyAdUIView