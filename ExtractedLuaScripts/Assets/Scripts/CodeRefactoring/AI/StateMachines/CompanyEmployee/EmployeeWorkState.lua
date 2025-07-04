---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/9/6 10:25
---
local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
---@class EmployeeWorkState:AIStateBase
---@field m_owner CompanyEmployeeNew
local EmployeeWorkState = Class("EmployeeWorkState",AIStateBase)

local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local Timer = GameTimer
local CompanyEmployeeNew = require("CodeRefactoring.Actor.Actors.CompanyEmployeeNew")

function EmployeeWorkState:ctor()
    self.m_timerID = nil
end

function EmployeeWorkState:OnEnter(...)
    self.m_owner:SetAnimator(PERSON_ACTION.WORK)
    if not self.m_owner:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
        self.m_owner:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
    end
    self.m_timerID = Timer:CreateNewTimer(1,function()
        local actor = self.m_owner
        if actor:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_DISMISS)
                or actor:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION)
                or (actor:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) and actor.m_busPosition)
        then
            actor.m_stateMachine:ChangeState(ActorDefine.State.EmployeeStandUpState)
            return
        end

        self:CheckPopTalking()
    end,true,false)
end

function EmployeeWorkState:CheckPopTalking()
    local actor = self.m_owner
    if actor.m_allFurnitureIsEnough then
        actor:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_FURN_SAT)
    else
        actor:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_FURN_UNSAT)
    end
    --local requirement = nil
    --local requirementFurnitures = self.m_owner.m_furnitureRequirement
    --if requirementFurnitures then
    --    for _, v in pairs(requirementFurnitures) do
    --        if requirement == nil then
    --            requirement = v
    --        else
    --            requirement = v and requirement
    --        end
    --    end
    --    if requirement ~= nil then
    --        if requirement then
    --            self.m_owner:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_FURN_SAT)
    --        else
    --            self.m_owner:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_FURN_UNSAT)
    --        end
    --    end
    --end
end

function EmployeeWorkState:OnExit()
    if self.m_timerID then
        Timer:StopTimer(self.m_timerID)
        self.m_timerID = nil
    end
end

function EmployeeWorkState:OnDestroy()
    if self.m_timerID then
        Timer:StopTimer(self.m_timerID)
        self.m_timerID = nil
    end
end

function EmployeeWorkState:Event(msg, params)
    --正在等车，然后跳过黑夜不需要等车了。
    if msg == ActorDefine.Event.EVENT_REMOVE_FLAG and params == ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING then
        self.m_owner:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
    end
end

return EmployeeWorkState