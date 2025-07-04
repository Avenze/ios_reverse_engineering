---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Microsoft-GXY.
--- DateTime: 2024/8/15 18:16
---
local Class = require("Framework.Lua.Class")
local ActorBase = require("CodeRefactoring.Actor.ActorBase")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local FloatUI = GameTableDefine.FloatUI
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local PersonStateMachine = require("CodeRefactoring.AI.StateMachines.PersonStateMachine")
local Animator = CS.UnityEngine.Animator
local Vector3 = CS.UnityEngine.Vector3  ---@type UnityEngine.Vector3
local AnimationUtil = CS.Common.Utils.AnimationUtil
local ColliderResponse = require("GamePlay.Floors.Actors.ColliderResponse")

---@class CycleToyChild:ActorBase
---@field super ActorBase
local CycleToyChild = Class("CycleToyChild", ActorBase)

function CycleToyChild:ctor()
    self.super.ctor(self)
    self.initialized = false
    self.m_type = ActorDefine.ActorType.CycleToyChild
    self.m_go = nil
    self.m_animator = nil ---@type UnityEngine.Animator
end

function CycleToyChild:Init(id, go, actorData)
    self.m_animator = go:GetComponent(typeof(Animator))
    self.data = actorData
    
    --优化Animator性能
    if not self.m_animator:IsNull() and not self.m_animator.applyRootMotion then
        self.m_animator.cullingMode = CS.UnityEngine.AnimatorCullingMode.CullUpdateTransforms
    end
    --创建行为状态机
    if not self.m_stateMachine then
        self.m_stateMachine = PersonStateMachine.create() ---@type PersonStateMachine
        self.m_stateMachine:SetOwner(self)
        self:TryTransState(function()
            self.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleToyChildPlay, self)
        end)
    end
    self.super.Init(self, id, go, actorData, self.m_stateMachine)
    self.data.type = "CycleToyChild"
    self.m_go = go
    self.initialized = true
    self.m_go.transform.localScale = Vector3(1, 1, 1)
    
    --self:SetDoorTrigger()
    print("创建 CycleToyChild", id)
end


--region 气泡显示 abandon
--设置气泡的显示
function CycleToyChild:SetTheDisplayOfBubbles(typeB, interactiveRoomId)
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local state =
    {
        interactiveRoomId = interactiveRoomId,
        roomId = self.data.roomID,
        index = self.data.furnitureIndex,
        workProgress = 0,
        productionID = currentModel.roomsConfig[self.data.roomID].production
    }
    local speed
    if typeB == "product" then
        local roomCfg = currentModel.roomsConfig[state.roomId]
        local allReduce = currentModel:GetRoomCDReduce(state.roomId)
        local cd = roomCfg.bastCD - allReduce
        speed = 1 / cd
    elseif typeB == "eat" then
        error("CycleToyChild在此副本没有 eat 状态")
    elseif typeB == "sleep" then
        error("CycleToyChild在此副本没有 sleep 状态")
    end
    state.speed = speed

    self.bubbleState = state
    self.typeB = typeB
    FloatUI:SetObjectCrossCamera(self, function(view)
        view:Invoke("RefreshCycleToyChildBubble", self.typeB, self.bubbleState)
    end,function()
        if not self.view then
            return
        end
        self.view:Invoke("RefreshCycleToyChildBubble")
    end,0)
end
--endregion

--region 初始化 abandon
---设置与门交互的Trigger
--function CycleToyChild:SetDoorTrigger()
--    local animName = {"DoorOpenAnim", "ToiletDoor_open"}
--    local animIndex = 1
--    local enterFunc = function(responseGo, activatorGo, outRoom)
--        local coll = responseGo:GetComponent("ColliderResponse")
--        local anim = coll:GetDoorAnim()
--        if not anim or coll:GetTriggerCount() > 1 then
--            return
--        end
--
--        local lastAni = 1
--        local currAni = AnimationUtil.GetAnimationState(anim, animName[lastAni])
--        if not currAni then
--            lastAni = 2
--            currAni = AnimationUtil.GetAnimationState(anim, animName[lastAni])
--        end
--        local needAni = outRoom == true and "_revert" or ""
--
--        if anim.isPlaying then
--            return
--        end
--
--        AnimationUtil.Play(anim, animName[lastAni] .. needAni, function()
--            AnimationUtil.GotoAndStop(anim, animName[lastAni] .. needAni, "KEY_FRAME_CLOSE_POINT")--放完停在末尾,让isPlay为true
--        end)
--
--        FloorMode:MakeDoorTimer(responseGo, function()--几秒后没人自动关闭
--            if coll and not CS.UnityEngine.Object.ReferenceEquals( coll, nil ) and coll:GetTriggerCount() == 0 and anim then
--                AnimationUtil.Play(anim, animName[lastAni] .. needAni, nil, -1, "KEY_FRAME_SECOND")
--                return true
--            elseif not anim then
--                return 1--切换场景的时候没了...或者其他原因导致的错误
--            end
--
--            return false
--        end)
--    end
--    ColliderResponse:SetActivatorTriggerEventOnEnter(ColliderResponse.TYPE_OPEN_DOOR, self.m_go, enterFunc)
--end

--endregion

return CycleToyChild
