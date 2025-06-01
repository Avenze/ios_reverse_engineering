local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ResourceManger = GameTableDefine.ResourceManger

local ChatEventUIView = Class("ChatEventUIView", UIView)

function ChatEventUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ChatEventUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("xxxx","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function ChatEventUIView:Refresh(eventId, cost, acceptCb, rejectCb, considerCb)
    self:SetText("RootPanel/HeadPanel/title/event_name", eventId)
    self:SetText("RootPanel/MidPanel/event/reward/num", "+"..cost)

    local accept = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    accept.interactable = ResourceManger:CheckCash(cost)

    self:SetButtonClickHandler(accept, function()
        ResourceManger:SpendCash(cost, nil, function()
            if acceptCb then acceptCb() end
            self:DestroyModeUIObject()
        end)
    end)

    local reject = self:GetComp("RootPanel/QuitBtn", "Button")
    self:SetButtonClickHandler(reject, function()
        if rejectCb then rejectCb() end
        self:DestroyModeUIObject()
    end)

    local consider = self:GetComp("RootPanel/ThinkBtn", "Button")
    self:SetButtonClickHandler(consider, function()
        if considerCb then considerCb() end
        self:DestroyModeUIObject()
    end)
end
function ChatEventUIView:OnExit()
    self.super:OnExit(self)
end

return ChatEventUIView