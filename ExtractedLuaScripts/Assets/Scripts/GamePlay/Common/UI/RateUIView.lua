local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local RateUI = GameTableDefine.RateUI

local RateUIView = Class("RateUIView", UIView)

function RateUIView:ctor()
    self.super:ctor()
end

function RateUIView:OnEnter()
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function(go, data)
    --     self:DestroyModeUIObject()
    -- end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/ExcellentBtn","Button"), function(go, data)
        RateUI:CollectRewards(self:GetTrans("RootPanel/ExcellentBtn").position, 4)
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/GoodBtn","Button"), function(go, data)
        RateUI:CollectRewards(self:GetTrans("RootPanel/GoodBtn").position, 3)
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/NormalBtn","Button"), function(go, data)
        RateUI:CollectRewards(self:GetTrans("RootPanel/NormalBtn").position, 2)
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/BadBtn","Button"), function(go, data)
        RateUI:CollectRewards(self:GetTrans("RootPanel/BadBtn").position, 1)
        self:DestroyModeUIObject()
    end)
end

function RateUIView:OnExit()
    self.super:OnExit(self)
end

return RateUIView