local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")


local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local CityMode = GameTableDefine.CityMode

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local OrderFinishUIView = Class("OrderFinishUIView", UIView)

function OrderFinishUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function OrderFinishUIView:OnEnter()
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button","Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
    --取消按钮
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/returnBtn/Button","Button"), function()
        self:DestroyModeUIObject()
    end)
    --前往按钮
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/gotoBtn/Button","Button"), function()
        self:DestroyModeUIObject()
        -- MainUI:BackToCity()        
        -- CityMode:EnterHouseOrCarShop(40001)
        FloorMode:GotoSpecialBuilding(40001)
    end)
end

function OrderFinishUIView:OnExit()
	self.super:OnExit(self)
end

return OrderFinishUIView