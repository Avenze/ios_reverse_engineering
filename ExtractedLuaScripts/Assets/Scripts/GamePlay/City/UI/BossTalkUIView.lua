local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local GameUIManager = GameTableDefine.GameUIManager

local BossTalkUIView = Class("BossTalkUIView", UIView)

function BossTalkUIView:ctor()
    self.super:ctor()
end

function BossTalkUIView:Preoad()
end

function BossTalkUIView:OnEnter()
    --print("BossTalkUIView:OnEnter")
    -- self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
end

function BossTalkUIView:OnPause()
    --print("BossTalkUIView:OnPause")
end

function BossTalkUIView:OnResume()
    --print("BossTalkUIView:OnResume")
end

function BossTalkUIView:OnExit()
    self.super:OnExit(self)
    --print("BossTalkUIView:OnExit")
end