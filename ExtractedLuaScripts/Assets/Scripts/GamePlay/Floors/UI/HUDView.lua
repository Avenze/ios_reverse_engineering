local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local GameUIManager = GameTableDefine.GameUIManager

local HUDView = Class("HUDView", UIView)

function HUDView:ctor()
    self.super:ctor()
end

function HUDView:OnEnter()
    print("HUDView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("return", "Button"), function()
        self:DestroyModeUIObject()
        GameStateManager:EnterCity()
    end)
end

function HUDView:OnPause()
    print("HUDView:OnPause")
end

function HUDView:OnResume()
    print("HUDView:OnResume")
end

function HUDView:OnExit()
    self.super:OnExit(self)
    print("HUDView:OnExit")
end

return HUDView