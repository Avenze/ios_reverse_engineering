---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/8/30 15:25
---

local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
---@class EventSponsorWaiting:AIStateBase
---@field m_owner EventSponsorNew
local EventSponsorWaiting = Class("EventSponsorWaiting",AIStateBase)

local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local MainUI = GameTableDefine.MainUI
local FloorMode = GameTableDefine.FloorMode
local Event001UI = GameTableDefine.Event001UI
local EventManager = require("Framework.Event.Manager")

function EventSponsorWaiting:ctor()
    self.m_speed = nil
end

function EventSponsorWaiting:OnEnter()
    self.m_owner:SetAnimator(PERSON_ACTION.DANCE)

    self.m_owner:InitFloatUIView(self.m_owner.m_eventId,function()
        Event001UI:ShowPanel(self.m_owner.m_eventId)
    end)
    MainUI:SetEventSponsorHint(true, self.m_owner.m_eventId)
    EventManager:DispatchEvent("EventSopnsor_click",self.m_owner.m_go)

    --FloorMode:GetScene():SetButtonClickHandler(self.m_owner.m_go, function()
    --    Event001UI:ShowPanel()
    --end)
end

function EventSponsorWaiting:Event(msg,params)
    --来的路上要结束
    if msg == self.m_owner.EVENT_LEAVE_SCENE then
        MainUI:SetEventSponsorHint(false,  self.m_owner.m_eventId)
        EventManager:DispatchEvent("EventSponsor_leave")

        self.m_owner.m_stateMachine:ChangeState(ActorDefine.State.EventSponsorLeaving)
    end
end

function EventSponsorWaiting:OnExit()
    self.m_owner:RemoveFloatUIView()
    FloorMode:GetScene():SetButtonClickHandler(self.m_owner.m_go, nil)
end

return EventSponsorWaiting