local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local DotweenUtil = CS.Common.Utils.DotweenUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local TipsUIView = Class("TipsUIView", UIView)

function TipsUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function TipsUIView:OnEnter()
end

function TipsUIView:OnExit()
    self.super:OnExit(self)
    self.m_data = nil
end

function TipsUIView:Show(message)
    self:SetText("RootPanel/1/text", message)
    local root = self:GetGo("RootPanel/1")
    
    local animation = self.m_uiObj:GetComponent("Animation")
    AnimationUtil.Play(animation, "TipsUI_open", function()
        self:DestroyModeUIObject()
    end)
    -- DotweenUtil.DoTipsNote(root, self:GetComp(root, "text", "TMPLocalized"),
    -- function()
    --     self:DestroyModeUIObject()
    -- end)
    
end

return TipsUIView