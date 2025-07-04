---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/9/6 10:28

local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
---@class EmployeeToiletState:AIStateBase
---@field m_owner CompanyEmployeeNew
--- 开会 娱乐 上厕所 休息 通用  包含移动到交互点的移动过程
local EmployeeToiletState = Class("EmployeeToiletState",AIStateBase)

local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")
local FloorMode = GameTableDefine.FloorMode
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local CompanyEmployeeNew = require("CodeRefactoring.Actor.Actors.CompanyEmployeeNew")
local Timer = GameTimer
local MeetingEventManager = GameTableDefine.MeetingEventManager
local CompanyMode = GameTableDefine.CompanyMode

function EmployeeToiletState:ctor()
    self.m_timerID = nil
    self.m_randomAnim = nil
end

function EmployeeToiletState:OnEnter(...)

    local pos = select(1,...)
    local dir = select(2,...)
    if pos then
        self.m_owner:RandomElevatorMoveTo(pos,dir,function()
            self:OnMoveEnd()
        end)
    else
        self:OnMoveEnd()
    end
end

function EmployeeToiletState:OnMoveEnd()
    local interactions = self.m_owner:GetCurrentInteractionEntity()
    if interactions then
        interactions:PersonArriveIdlePos(self.m_owner) --到达交互点获取交互动画
        if self.m_owner.m_randomAnim.pleasure > 0 then
            self.m_owner:SetTargetMood("entertainment_type_", 500, self.m_owner.m_randomAnim.pleasure)
        end
        self.m_randomAnim = self.m_owner.m_randomAnim or {anim=1,countdown = 1}
        if self.m_randomAnim.setting then
            self:DoSitting()
        else
            self:DoAction()
        end
    end
end

function EmployeeToiletState:DoSitting()
    local keyFrames = {{}}
    keyFrames[1].key = "ANIM_IDLE2SIT_END"
    keyFrames[1].func = function()
        self:DoAction()
    end
    self.m_owner:SetAnimator(PERSON_ACTION.IDLE2SIT, keyFrames)
end

function EmployeeToiletState:DoAction()
    if self.m_owner.m_go then
        local randomAnim = self.m_randomAnim
        self.m_owner:SetAnimator(randomAnim.anim)
        self.m_timerID = Timer:CreateNewTimer(randomAnim.countdown,function()

            local scene = FloorMode:GetScene()
            if not scene then --场景已被卸载
                return
            end

            if randomAnim.setting then
                self.m_owner.m_stateMachine:ChangeState(ActorDefine.State.EmployeeStandUpState)
            else
                self.m_owner.m_stateMachine:ChangeState(ActorDefine.State.EmployeeGoToWorkState,false)
            end
        end)
    end
end

function EmployeeToiletState:OnExit()

    if self.m_owner.m_randomAnim and self.m_owner.m_randomAnim.addexp > 0 then
        CompanyMode:RoomAddExp(self.m_owner.m_roomData.config.room_index, self.m_owner.m_randomAnim.addexp)
        self.m_owner:AddDailyMeetingNumber() -- 等待修改为永久存档
    end
    self.m_owner:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_FURN_LV) -- 在互动行为结束后会进入一次检定
    self.m_owner:SetTargetMood("entertainment_type_")
    Timer:CreateNewTimer(math.random(4, 8), function()
        if self.m_owner.m_go and not self.m_owner.m_go:IsNull() then
            self.m_checkRoomUnlockTimerID = self.m_owner:CheckPopTalking(CompanyEmployeeNew.POP_TYPE_ROOM_UNLOCK) -- 回去的路上检查功能型房间在场景中存在并且未解锁
        end
    end)

    local interactions = self.m_owner:GetCurrentInteractionEntity()
    if interactions then
        if interactions.m_tag then
            self.m_owner.m_triggerCounter[interactions.m_tag] = math.random(interactions.m_colliderComponent.m_behaviourReset.x, interactions.m_colliderComponent.m_behaviourReset.y)
            interactions:PersonGetOut(self.m_owner)
            if self.m_owner:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING) then
                if MeetingEventManager:CheckRoomDailyMeetingComplete(interactions.m_roomIndex) then
                    interactions.m_roomIndex = nil
                end
            end
        end
    end

    self.m_owner:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION) ---1
    self.m_owner:CheckFloatState() ---2
    self.m_owner.m_randomAnim = nil ---3

    if self.m_timerID then
        Timer:StopTimer(self.m_timerID)
        self.m_timerID = nil
    end
    self.m_owner:StopMove()
end

function EmployeeToiletState:OnDestroy()
    if self.m_timerID then
        Timer:StopTimer(self.m_timerID)
        self.m_timerID = nil
    end
end

function EmployeeToiletState:Event(msg, params)
    --if msg == ActorDefine.Event.EVENT_EMPLOYEE_DISMISS then
    --    self.m_owner.m_stateMachine:ChangeState(ActorDefine.State.EmployeeDismissState)
    --end
end


return EmployeeToiletState