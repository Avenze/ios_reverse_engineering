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
local GameObject = CS.UnityEngine.GameObject
local AnimationUtil = CS.Common.Utils.AnimationUtil
local GameTimer = GameTimer

local WALK_SPEED = 5
local RUN_SPEED = 10


---@class CycleNightClubClientComeByBus:AIStateBase
---@field m_owner CycleNightClubClient
local CycleNightClubClientComeByBus = Class("CycleNightClubClientComeByBus", AIStateBase)

function CycleNightClubClientComeByBus:ctor()
end

function CycleNightClubClientComeByBus:OnEnter(...)

    self.m_owner.m_go:SetActive(false)

    local scene = CycleInstanceDataManager:GetCurrentModel():GetScene()---@type CycleNightClubScene
    local busGO = scene:GetBusGOFromPool()
    local busPlayable = UIView:GetComp(busGO,"","PlayableDirector") ---@type UnityEngine.Playables.PlayableDirector
    busPlayable.time = 0
    busPlayable:Play()

    AnimationUtil.AddKeyFrameEventOnObj(busGO, "EVENT_BUS_ARRIVED", function()
        if self.m_owner.m_go then
            busPlayable:Pause()
            self.m_owner.m_go:SetActive(true)
            local stationPos = UIView:GetGo(busGO,"car/NtClub_car/Position")
            self.m_owner.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleNightClubClientCome,stationPos)
            GameTimer:CreateNewTimer(1.2,function()
                if not busPlayable:IsNull() then
                    busPlayable:Play()
                end
            end)
        end
    end)

    AnimationUtil.AddKeyFrameEventOnObj(busGO, "EVENT_BUS_LEFT", function()
        local curScene = CycleInstanceDataManager:GetCurrentModel():GetScene()
        if curScene then
            curScene:RecycleBusGOToPool(busGO)
        end
    end)
end

function CycleNightClubClientComeByBus:OnExit()
end

function CycleNightClubClientComeByBus:OnDestroy()
end

return CycleNightClubClientComeByBus