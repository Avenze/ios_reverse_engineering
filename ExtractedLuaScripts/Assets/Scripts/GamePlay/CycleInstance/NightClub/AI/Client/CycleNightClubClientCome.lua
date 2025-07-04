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
local CycleNightClubAIBlackBoard = GameTableDefine.CycleNightClubAIBlackBoard ---@type CycleNightClubAIBlackBoard
local ConfigMgr = GameTableDefine.ConfigMgr

local WALK_SPEED = 5
local RUN_SPEED = 10


---@class CycleNightClubClientCome:AIStateBase
---@field m_owner CycleNightClubClient
local CycleNightClubClientCome = Class("CycleNightClubClientCome", AIStateBase)

function CycleNightClubClientCome:ctor()

end

function CycleNightClubClientCome:OnEnter(...)

    local actor = self.m_owner
    -- 初始化在工作点
    local startPos =  select(1, ...) or CycleNightClubAIBlackBoard:GetRandomInPos()
    local queueStart = CycleNightClubAIBlackBoard.gateData.queueStart
    CycleNightClubAIBlackBoard:ModifyOutClubClientNum(1)
    actor.gameObject.transform.position = startPos.transform.position
    local speed = ConfigMgr.config_global.character_run_v + Random.Range(-1.1, 1.1)

    actor:CalculatePath(
        queueStart.transform,
        true,
        speed,
        Random.Range(1.1, 4.1),
        function()
            -- 判断是否能进入夜店
            local needQueue = CycleNightClubAIBlackBoard:GetQueueActorCount() > 0
            local havePlayPos = CycleNightClubAIBlackBoard:CheckHaveSparePlayPos()
            if not needQueue and havePlayPos and not CycleNightClubAIBlackBoard.inPaymentState then
                -- 进入支付状态
                local playData = CycleNightClubAIBlackBoard:GetSparePlayPos(actor) 
                actor.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleNightClubClientPay, playData)
            else
                -- 进入排队
                actor.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleNightClubClientQueue)
            end

        end
    )

    -- 播放走路动画
    actor.m_animator:Play(ActorDefine.AnimationNames.Run)
end

function CycleNightClubClientCome:OnExit()

end

function CycleNightClubClientCome:OnDestroy()
    self:OnExit()
end

return CycleNightClubClientCome