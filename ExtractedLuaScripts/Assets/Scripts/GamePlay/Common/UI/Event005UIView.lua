local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local GameUIManager = GameTableDefine.GameUIManager
local Event005UI = GameTableDefine.Event005UI
local MainUI = GameTableDefine.MainUI
local CfgMgr = GameTableDefine.ConfigMgr

local Event005UIView = Class("Event005UIView", UIView)


function Event005UIView:ctor()
    self.super:ctor()
    self.container = {}
end

function Event005UIView:OnEnter()--圣诞老人
    local cfg = CfgMgr.config_event[3]

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/QuitBtn", "Button"), function()
        Event005UI:ClaimResource(false)
        self:DestroyModeUIObject()
    end)
    local adBtn = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    self:SetButtonClickHandler(adBtn, function()
        adBtn.interactable = false
        local pos = self:GetTrans("RootPanel/MidPanel/ConfirmBtn/Button").position
        Event005UI:ClaimResource(function()
                EventManager:DispatchEvent("FLY_ICON", pos,
                    cfg.event_reward[1], Event005UI:GetReward())
                MainUI:RefreshQuestHint()
                self:DestroyModeUIObject()
            end
        )
    end)
end

function Event005UIView:OnPause()
    print("Event005UIView:OnPause")
end

function Event005UIView:OnResume()
    print("Event005UIView:OnResume")
end

function Event005UIView:OnExit()
    self.super:OnExit(self)
    print("Event005UIView:OnExit")
end

function Event005UIView:ShowPanel(totalRent, reward)
    local showText = GameTextLoader:ReadText("TXT_EVENT_EFFICIENCY_001")
    showText = string.format(showText, totalRent)
    self:SetText("RootPanel/MidPanel/event/efficiency", showText)
    self:SetText("RootPanel/MidPanel/event/reward/num", "+" .. Tools:SeparateNumberWithComma(reward))
end

return Event005UIView