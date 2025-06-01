local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local GameResMgr = require("GameUtils.GameResManager")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local Event004UI = GameTableDefine.Event004UI

local EventChatter = Class("EventChatter", Person)

EventChatter.m_type = "TYPE_CHATTER"

EventChatter.m_category = 1000
EventChatter.EVENT_LEAVE_SCENE = EventChatter.m_category + 1

function EventChatter:ctor()
    self.super.ctor(self)
end

function EventChatter:Init(rootGo, tempGo, position, tragetPosition, conditionId)
    self.super.Init(self, rootGo, nil, position, tragetPosition)
    self.m_tempGo = tempGo
    self.m_conditionId = conditionId
end

function EventChatter:Update(dt)
    self.super.Update(self, dt)
end

function EventChatter:Exit()
    self.super.Exit(self)
end

function EventChatter:Event(msg)
    self.super.Event(self, msg)
end

function EventChatter:OverrideStates()
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.LOADING_COMPLETE then
            --person.StateWalk:SetPrams(target, 15)
            if person:HasFlag(person.FLAG_SPONSOR_WATTING) then
                person.m_go.transform.position = person.m_targetPosition
                person:SetState(person.StateWaitting)
                return
            end
            person:SetState(person.StateWalk, {tragetPosition=person.m_targetPosition})
        end
    end

    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then
            if person:HasFlag(person.FLAG_LEAVE_SCENE) then
                person:Exit()
                --原角色上车后的
                --GameTableDefine.ActorEventManger:CarLeave()
                --GameTableDefine.ActorEventManger:NPCLeave(self.parent.m_chatId)
                return
            end
            person:SetState(person.StateWaitting)
        end
    end

    local StateIdle = self:OverrideState(self.StateIdle)
    function StateIdle:Event(person, msg)
        if msg == person.EVENT_IDLE_END then
            person:SetState(person.StateWaitting)
        end
    end

    --StateWaitting
    local StateWaitting = self:InitState("StateWaitting")
    function StateWaitting:Enter(person)
        local action = 7
        local keyFrames = {{}}
        keyFrames[1].key = "ANIM_IDLE2SIT_END"
        keyFrames[1].func = function() person:Event(person.EVENT_IDLE2SIT_END) end
        self:SetAnimator(action, keyFrames)

        person:InitChatUIView(self.parent.m_conditionId)

        --???主界面关联图标
        --MainUI:SetEventSponsorHint(true, self.parent.m_chatId)


    end

    function StateWaitting:Update(person, dt)
    end

    function StateWaitting:Exit(person)
        person:RemoveFloatUIView()
    end
 
    function StateWaitting:Event(person, msg)
        if msg == person.EVENT_LEAVE_SCENE then
            --???主界面关联图标
            --MainUI:SetEventSponsorHint(false, self.parent.m_chatId)

            person:AddFlag(person.FLAG_LEAVE_SCENE)
            person:SetState(person.StateWalk, {tragetPosition=person.m_initPosition})
        end
    end
end

return EventChatter