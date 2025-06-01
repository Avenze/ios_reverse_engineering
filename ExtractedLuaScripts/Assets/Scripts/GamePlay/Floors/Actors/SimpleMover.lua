local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

local FloatUI = GameTableDefine.FloatUI
local CfgMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local GameClockManager = GameTableDefine.GameClockManager
local TimeManager = GameTimeManager
local ConfigMgr = GameTableDefine.ConfigMgr

local SimpleMover = Class("SimpleMover", Person)

SimpleMover.EVENT_MOVE = 3000

function SimpleMover:Init(rootGo, skinPath, initPos, moveSpeed, size, personID)
    self.super.Init(self, rootGo, skinPath, initPos, nil, personID)
    self.moveSpeed = moveSpeed or ConfigMgr.config_global.Batman_walkspeed
    self.sizeScale = size or 1
    self.lastTime = 0
    self.waitTime = 0
end

function SimpleMover:Update(dt)
    self.super.Update(self, dt)
end

function SimpleMover:Exit()
    self.super.Exit(self)
end

function SimpleMover:Event(msg, params)
    self.super.Event(self, msg, params)
end

function SimpleMover:OverrideStates()
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Event(person, msg, params)
        self.super.Event(self, person, msg)
        if msg == person.LOADING_COMPLETE then
            person:SetState(person.StateIdle)
            person.m_go.transform.localScale = Vector3(person.sizeScale,person.sizeScale,person.sizeScale)
        end
    end

    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Enter(person, msg, params)
        self.super.Enter(self, person, params)
    end

    function StateWalk:Event(person, msg, params)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then
            person.lastTime = TimeManager:GetSocketTime()
            person:SetState(person.StateIdle)
        end
    end

    local StateIdle = self:OverrideState(self.StateIdle)
    function StateIdle:Enter(person, msg, params)
        self.super.Enter(self, person, params)
    end

    function StateIdle:Update(person, dt)
        if TimeManager:GetSocketTime() - (person.lastTime or 0) < person.waitTime then
            return
        end
    
        person.waitTime = math.random(3,10)
        self.super.Update(self, person, dt)
        person.lastTime = TimeManager:GetSocketTime()
        person:Event(SimpleMover.EVENT_MOVE)
    end

    function StateIdle:Event(person, msg)
        self.super.Event(self, person, msg)

        if msg == SimpleMover.EVENT_MOVE then
            local go = FloorMode:GetScene():GetOnePlace();
            local params = {tragetPosition = go, speed = person.moveSpeed}
            person:SetState(person.StateWalk, params)
        end
    end
end

return SimpleMover