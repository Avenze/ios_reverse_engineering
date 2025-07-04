---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/8/25 17:07
---
local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
---@class AIStateIdle:AIStateBase
---@field super AIStateBase
local AIStateIdle = Class("AIStateIdle",AIStateBase)
local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")

function AIStateIdle:ctor()
    self.super:ctor()
end

function AIStateIdle:OnEnter()
    self.super:OnEnter()
    local action = PERSON_ACTION.IDLE
    local keyFrames = {{}}
    keyFrames[1].key = "ANIM_IDLE_END"
    keyFrames[1].func = function() self.owner:Event(self.owner.EVENT_IDLE_END) end
    self.owner.aiStateMachine:SetAnimator(action, keyFrames)
end

function AIStateIdle:OnExit()
    self.super:OnExit()
end

return AIStateIdle