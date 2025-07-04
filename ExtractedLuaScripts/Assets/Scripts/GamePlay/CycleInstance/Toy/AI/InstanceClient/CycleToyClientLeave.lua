---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Microsoft-GXY.
--- DateTime: 2024/8/16 12:28
---
local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")
local UIView = require("Framework.UI.View") -- 当工具类使用
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local Vector3 = CS.UnityEngine.Vector3
local UnityHelper = CS.Common.Utils.UnityHelper
local Random = CS.UnityEngine.Random
local ActorManager = GameTableDefine.ActorManager ---@type ActorManager
local CycleToyAIBlackBoard = GameTableDefine.CycleToyAIBlackBoard ---@type CycleToyAIBlackBoard


local WALK_SPEED = 2
local RUN_SPEED = 5


---@class CycleToyClientLeave:AIStateBase
---@field m_owner CycleToyClient
local CycleToyClientLeave = Class("CycleToyClientLeave",AIStateBase)

function CycleToyClientLeave:ctor()

end

function CycleToyClientLeave:OnEnter(...)
    local actor = self.m_owner
    local actorData = actor.data
    local stateMachine = actor.m_stateMachine
    
    local speed = RUN_SPEED + Random.Range(-1.1, 1.1)
    local midPos = CycleToyAIBlackBoard:GetRandomOutPos()
    local outPos = CycleToyAIBlackBoard.gateData.outPos
    actor:CalculatePath(
        outPos.transform,
        true,
        speed,
        Random.Range(1.1, 4.1), 
        function()
            -- 播放动画
            actor:SetAnimator(PERSON_ACTION.SHOPPING_BIG_WALK)

            actor:CalculatePath(
                midPos.transform,
                true,
                speed,
                Random.Range(1.1, 4.1),
                function()
                    ActorManager:DestroyActor(actor.instanceID)
                    --actor.m_isPooling = true
                end
            )
        end
    )

    -- 播放动画
    actor:SetAnimator(PERSON_ACTION.TROLLEY_RUN_BUY)
  

end

function CycleToyClientLeave:OnExit()

end

return CycleToyClientLeave