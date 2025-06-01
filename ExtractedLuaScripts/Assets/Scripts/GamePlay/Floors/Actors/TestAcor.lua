local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local TimeMgr = GameTimeManager
local TestActor = Class("TestActor", Person)

TestActor.m_type = "TYPE_TEST_ACTOR"
TestActor.m_category = 3000
--TestActor.EVENT_DISMISS_EMPLOYEE = TestActor.m_category + 1

function TestActor:Init(rootGo, tempGo, position)
    self.super.Init(self, rootGo, tempGo, position)
end

function TestActor:OverrideStates()
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.LOADING_COMPLETE then
            local initPos = person.m_initPosition
            local targetPos = {x = initPos.x + math.random(-20, 20), y = initPos.y, z = initPos.z + math.random(-20, 20)}
            local params = {tragetPosition = targetPos}
            person:SetState(person.StateWalk, params)
        end
    end

    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then
            person:SetState(person.StateSitting)
        end
    end

    local StateSitting = self:OverrideState(self.StateSitting)
    function StateSitting:Event(person, msg)
        if msg == person.EVENT_IDLE2SIT_END then
            person:SetState(person.StateWork)
        end
    end

    local StateWork = self:OverrideState(self.StateWork)
    function StateWork:Enter(person)
        self.super.Enter(self, person)
        self.m_count = math.random(10, 20)
        self.m_currentTime = TimeMgr:GetCurrentServerTime()
    end
    function StateWork:Update(person, dt)
        self.super.Update(self, person)
        if TimeMgr:GetCurrentServerTime() - self.m_currentTime > self.m_count then
            person:SetState(person.StateStandup)
        end
    end

    local StateStandup = self:OverrideState(self.StateStandup)
    function StateStandup:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_SIT2IDLE_END then
            local initPos = person.m_initPosition
            local targetPos = {x = initPos.x + math.random(-20, 20), y = initPos.y, z = initPos.z + math.random(-20, 20)}
            local params = {tragetPosition = targetPos}
            person:SetState(person.StateWalk, params)
        end
    end
end

return TestActor