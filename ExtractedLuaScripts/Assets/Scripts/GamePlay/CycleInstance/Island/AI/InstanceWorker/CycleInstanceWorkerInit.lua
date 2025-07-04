---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2024/7/1 14:13
---
local Class = require("Framework.Lua.Class")
local AIStateBase = require("CodeRefactoring.AI.StateMachines.AIStateBase")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleInstanceAIBlackBoard = GameTableDefine.CycleInstanceAIBlackBoard
local UIView = require("Framework.UI.View") -- 当工具类使用


---@class CycleInstanceWorkerInitState:AIStateBase
---@field m_owner CycleInstanceWorkerClass
local CycleInstanceWorkerInitState = Class("CycleInstanceWorkerInitState", AIStateBase)

function CycleInstanceWorkerInitState:ctor()
end

function CycleInstanceWorkerInitState:OnEnter(...)
    local actor = select(1, ...)
    local isBuy = select(2, ...)
    local stateMachine = actor.aiStateMachine ---@type PersonStateMachine
    local actorData = actor.data
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    if actorData.workPosTr:IsNull() then
        actorData.furGO = currentModel:GetSceneRoomFurnitureGo(actorData.roomId, 1)
        actorData.workPosTr = UIView:GetTrans(actorData.furGO, "workPos_" .. actorData.furIndex) --工位点
        actorData.workFaceTr = UIView:GetTrans(actorData.workPosTr.gameObject, "face") --工位点朝向
        actorData.actPosTr = UIView:GetTrans(actorData.roomGO, "actionPos/actionPos_" .. actorData.furIndex) or actorData.workPosTr --工位点
        actorData.actFaceTr = UIView:GetTrans(actorData.roomGO, "actionPos/actionPos_" .. actorData.furIndex .. "/face") or actorData.workFaceTr --工位点

        actor.gameObject.transform.position = actorData.actPosTr.position
        actor.gameObject.transform.rotation = actorData.actFaceTr.rotation
        -- error(actorData.roomId .."    "..actorData.furIndex)
    end
    actor.gameObject.transform.position = actorData.spawnPos

    -- 根据当前时间阶段初始化行为
    local timeType = currentModel.timeType
    if timeType == currentModel.TimeTypeEnum.work then
        if isBuy then
            -- 变换行为
            actor:TryTransState(
                    function()
                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToWorkSeat, actor)
                    end
            )
        else
            -- 初始化在工作点
            actor.gameObject.transform.position = actorData.actPosTr.position
            actor.gameObject.transform.rotation = actorData.actFaceTr.rotation
            -- 变换行为
            actor:TryTransState(
                    function()
                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerWork)
                    end
            )
        end
    elseif timeType == currentModel.TimeTypeEnum.eat then
        -- 获取吃饭对应的角色, 在座位的初始化到座位上, 不在座位的初始化到工位点
        if not currentModel.actorSeatBind[currentModel.timeType] or next(currentModel.actorSeatBind[currentModel.timeType]) == nil then
            currentModel:WorkerAttrRevert(currentModel.timeType, true)
        end
        local actorSeatBind = currentModel.actorSeatBind[currentModel.timeType]
        if not actorSeatBind then
            return
        end
        local rooms = currentModel:GetRoomDataByType(3)
        local targetRoomID = rooms[1].roomID
        if actorSeatBind[actorData.roomID] and actorSeatBind[actorData.roomID][actorData.furnitureIndex] then
            local roomId, furIndex, index = CycleInstanceAIBlackBoard:GetActorBindSeat(targetRoomID, actor)
            --local roomGO = currentModel:GetRoomGameObjectByID(roomId)
            local furGO = currentModel:GetFurGameObject(roomId, furIndex)
            local workPosName = "workPos_" .. index
            local workPosTrans = UIView:GetTrans(furGO, workPosName)
            actor:TryTransState(
                    function()
                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerEat, actor, targetRoomID, workPosTrans, roomId, furIndex)
                    end
            )
        else

            actor:TryTransState(
                    function()
                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToEatQueue, actor, targetRoomID)
                    end
            )
        end

    elseif timeType == currentModel.TimeTypeEnum.sleep then
        -- 获取睡觉对应的角色, 在床上的初始化到床上, 不再床上的初始化到工位点
        -- 如果所在房间强制加班，那就别睡了
        local forceWork = currentModel:GetRoomIsFullForce(actor.data.roomID)
        if forceWork then
            actor:TryTransState(
                    function()
                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToWorkSeat, actor)
                    end
            )
        else
            if not currentModel.actorSeatBind[currentModel.timeType] or next(currentModel.actorSeatBind[currentModel.timeType]) == nil then
                currentModel:WorkerAttrRevert(currentModel.timeType, true)
            end
            local actorSeatBind = currentModel.actorSeatBind[timeType]
            if not actorSeatBind then
                error("不应该找不到睡觉的座位")
                return
            end
            if actorSeatBind[actorData.roomID] and actorSeatBind[actorData.roomID][actorData.furnitureIndex] then
                local targetRoomID = actorSeatBind[actorData.roomID][actorData.furnitureIndex]
                local roomId, furIndex, index = CycleInstanceAIBlackBoard:GetActorBindSeat(targetRoomID, actor)
                local roomGO = currentModel:GetRoomGameObjectByID(roomId)
                local workPosName = "workPos_" .. index
                local workPosTrans = UIView:GetTrans(roomGO, workPosName)
                actor:TryTransState(
                        function()
                            stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerSleep, actor, targetRoomID, workPosTrans)
                        end
                )
            else

                actor:TryTransState(
                        function()
                            if isBuy and currentModel:FindSleepSeat(actor) then
                                --睡觉时间招募新工人
                                stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToSleepQueue, actor, actorSeatBind[actorData.roomID][actorData.furnitureIndex])
                            else
                                --error("没有睡觉的座位，肯定是哪一步出了问题")
                                stateMachine:ChangeState(ActorDefine.State.CycleInstanceWorkerRunToSleepQueue, actor)
                            end
                        end
                )
            end
        end
    end

    actor:SetTheDisplayOfBubbles("state")

end

function CycleInstanceWorkerInitState:OnExit()

end

return CycleInstanceWorkerInitState