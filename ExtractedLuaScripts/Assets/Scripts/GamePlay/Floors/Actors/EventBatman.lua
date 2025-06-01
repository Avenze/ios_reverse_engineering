local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local GameResMgr = require("GameUtils.GameResManager")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local Event003UI = GameTableDefine.Event003UI
local CfgMgr = GameTableDefine.ConfigMgr

local EventBatman = Class("EventBatman", Person)

EventBatman.m_type = "TYPE_BATMAN"

EventBatman.m_category = 1001
EventBatman.EVENT_LEAVE_SCENE = EventBatman.m_category + 1
EventBatman.EVENT_CAST_SPELL = EventBatman.m_category + 2

function EventBatman:ctor()
    self.super.ctor(self)
end

function EventBatman:Init(rootGo, tempGo, position, tragetPosition, eventId)
    self.super.Init(self, rootGo, nil, position, tragetPosition)
    self.m_tempGo = tempGo
    self.m_eventId = eventId
end

function EventBatman:Update(dt)
    self.super.Update(self, dt)
end

function EventBatman:Exit()
    self.super.Exit(self)
end

function EventBatman:Event(msg)
    self.super.Event(self, msg)
end

function EventBatman:OverrideStates()
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
            person:SetState(person.StateWalk, {tragetPosition=person.m_targetPosition, speed = CfgMgr.config_global.Batman_walkspeed})
        end
    end

    local StateWalk = self:OverrideState(self.StateWalk)

    function StateWalk:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then
            if person:HasFlag(person.FLAG_LEAVE_SCENE) then
                person:Exit()
                --GameTableDefine.ActorEventManger:BatLeave()
                GameTableDefine.ActorEventManger:NPCLeave(self.parent.m_eventId)
                return
            end
            person:SetState(person.StateWaitting)        
        elseif msg == person.EVENT_LEAVE_SCENE then--走的过程中就
            MainUI:SetEventBatmanHint(false)
            person:AddFlag(person.FLAG_SKIP_NIGHT_LEAVE)
        end
    end

    local StateIdle = self:OverrideState(self.StateIdle)
    function StateIdle:Event(person, msg)
        if msg == person.EVENT_IDLE_END then
            person:SetState(person.StateWaitting)
        end
    end

    --StateCastSpell
    local StateCastSpell = self:InitState("StateCastSpell")--释放跳过黑夜法术
    function StateCastSpell:Enter(person)
        local action = 7
        local keyFrames = {{},{}}
        keyFrames[1].key = "ANIM_CAST_SPELL_END"
        keyFrames[1].func = function() 
            person:AddFlag(person.FLAG_LEAVE_SCENE)
            person:SetState(person.StateWalk, {tragetPosition=person.m_initPosition, speed = CfgMgr.config_global.Batman_walkspeed})
        end

        keyFrames[2].key = "ANIM_CAST_SPELL_KEY"
        keyFrames[2].func = function()
            EventManager:DispatchEvent("DAY_COME")
            MainUI:PlaySkipNight()
        end

        self:SetAnimator(action, keyFrames)
    end

    function StateCastSpell:Update(person, dt)
    end

    function StateCastSpell:Exit(person)
    end

    function StateCastSpell:Event(person)
    end

    --StateWaitting
    local StateWaitting = self:InitState("StateWaitting")
    function StateWaitting:Enter(person)
        local action = 1--动画到时修改
        local keyFrames = {{}}
        keyFrames[1].key = "ANIM_IDLE2SIT_END"
        keyFrames[1].func = function() person:Event(person.EVENT_IDLE2SIT_END) end
        self:SetAnimator(action, keyFrames)

        person:InitFloatUIView(self.parent.m_eventId)
        MainUI:SetEventBatmanHint(true)

        FloorMode:GetScene():SetButtonClickHandler(person.m_go, function()
            Event003UI:ShowPanel()
        end)

        if person:HasFlag(person.FLAG_SKIP_NIGHT_LEAVE) then
            MainUI:SetEventBatmanHint(false)
            person:AddFlag(person.FLAG_LEAVE_SCENE)
            person:SetState(person.StateWalk, {tragetPosition=person.m_initPosition, speed = CfgMgr.config_global.Batman_walkspeed})
        end
    end

    function StateWaitting:Update(person, dt)
    end

    function StateWaitting:Exit(person)
        person:RemoveFloatUIView()
        FloorMode:GetScene():SetButtonClickHandler(person.m_go, nil)
    end

    function StateWaitting:Event(person, msg)
        if msg == person.EVENT_LEAVE_SCENE then
            MainUI:SetEventBatmanHint(false)

            person:AddFlag(person.FLAG_LEAVE_SCENE)
            person:SetState(person.StateWalk, {tragetPosition=person.m_initPosition, speed = CfgMgr.config_global.Batman_walkspeed})
        elseif msg == person.EVENT_CAST_SPELL then
            MainUI:SetEventBatmanHint(false)
            person:SetState(person.StateCastSpell)
        end
    end
end

return EventBatman