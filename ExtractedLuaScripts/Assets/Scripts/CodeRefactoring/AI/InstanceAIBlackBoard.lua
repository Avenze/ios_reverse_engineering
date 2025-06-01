--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-25 10:57:55
    description:AI黑板, 用于存放AI状态机中公用的数据和 中间过程, 单例唯一, 所有的ai状态机都引用这个实例
]]
local InstanceAIBlackBoard = GameTableDefine.InstanceAIBlackBoard
local Vector3 = CS.UnityEngine.Vector3
local UnityHelper = CS.Common.Utils.UnityHelper
local InstanceModel = GameTableDefine.InstanceModel
local ActorManager = GameTableDefine.ActorManager
local UIView = require("Framework.UI.View") -- 当工具类使用
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")

local colliderResponse = {}   -- 绑定colliderResponse组件的物体-组件表
local colliderTransTable = {} -- 交互建筑上绑定的数据 roomID,colliderTransTable
local animaTable = {}         --交互建筑上绑定的动画数据

local queueUpQueue = {}       -- 副本排队队列, {actor1,actor2,actor3}
local queueUpTable = {}       -- 副本排队索引(index)对应表, {actor1 = 1 ,actor2 = 2 ,actor3 = 3}
local queueUpPathTable = {}   --副本排队位置(position)
local queueInterval = 3       -- 副本排队间隔

local instanceRoomSeat = {}   -- 副本房间座位

--[[
    @desc: 添加演员到排队队列
    author:{author}
    time:2023-08-25 16:37:07
    --@target:目的地(roomID)
	--@start:排队起点
	--@actor: 演员
    @return:
]]
function InstanceAIBlackBoard:AddInstanceQueue(target, start, actor, createQueuePathCb)
    -- 记录排队数据数据
    actor.data.queueTarget = target
    actor.data.queueStart = start

    if not queueUpQueue[target] then
        queueUpQueue[target] = {}
        queueUpTable[target] = {}
    end
    local queue = queueUpQueue[target]
    local queueTable = queueUpTable[target]
    queue[#queue + 1] = actor
    queueTable[actor] = #queue --此时[queueUpQueue]长度已+1,所以储存其现在的长度

    --获取路径
    if not queueUpPathTable[target] then -- 将固定路径存起来, 不需要重复生成
        local endPoint = UIView:GetTrans(start.transform.parent.gameObject, "QueuePoint")
        local vectorPath = UnityHelper.SearchPathByNavMesh(start.position, endPoint.transform.position)

        queueUpPathTable[target] = {}
        local lastPos = vectorPath[0]
        for i = 1, vectorPath.Length - 1 do
            local dir = vectorPath[i] - lastPos
            local dis = dir.magnitude
            if dis > queueInterval then
                --插入N个距离大于1的点.
                dir = dir.normalized
                for j = 1, dis, queueInterval do
                    lastPos = lastPos + dir * queueInterval
                    table.insert(queueUpPathTable[target], 1, lastPos)
                end
            end
        end
    end

    return #queue, queueUpPathTable[target]
end

function InstanceAIBlackBoard:ClearSeat()
    instanceRoomSeat = {}
end

--[[
    @desc: 将演员从排队队列移除
    author:{author}
    time:2023-08-25 16:37:21
    --@target:
	--@start:
	--@actor:
    @return:
]]
function InstanceAIBlackBoard:GetOutInstanceQueue(actor)
    local queueTarget = actor.data.queueTarget
    actor.data.queueTarget = nil
    actor.data.queueStart = nil
    local queue = queueUpQueue[queueTarget]
    local queueTable = queueUpTable[queueTarget]
    local curIndex = queueTable[actor]
    for i = curIndex + 1, #queue do
        local actor = queue[i]
        queueTable[actor] = queueTable[actor] - 1
    end
    table.remove(queue, curIndex)

end

--购买家具回调
function InstanceAIBlackBoard:OnBuyFurCallBack(roomCfg, furIndex, furLevelCfg)
    local queue = queueUpQueue[roomCfg.id]
    local curActor = nil


    if roomCfg.room_category == 3 and furLevelCfg.seat >= 1 then
        if not queue or not queue[1] then
            return
        end

        curActor = queue[1]
        local actorData = curActor.data
        local stateMachine = curActor.aiStateMachine
        InstanceModel:FindEatSeat(curActor) --确保InstanceModel数据正确
        local roomId, furIndex, index = self:GetActorBindSeat(roomCfg.id,curActor)
        curActor:TryTransState(
                function()
                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerWalkToEat, curActor, roomCfg.id, furIndex, index)
                end
        )
    elseif roomCfg.room_category == 2 and furLevelCfg.seat >= 1 then
        if not queue or not queue[1] then
            return
        end

        curActor = queue[1]
        local actorData = curActor.data
        local stateMachine = curActor.aiStateMachine
        InstanceModel:FindSleepSeat(curActor) --确保InstanceModel数据正确
        local roomId, furIndex, index = self:GetActorBindSeat(roomCfg.id,curActor)
        curActor:TryTransState(
                function()
                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerWalkToSleep, curActor, roomCfg.id, furIndex, index)
                end
        )
    elseif roomCfg.room_category == 1 and furLevelCfg.action then
        curActor = ActorManager:GetActorsByRoom("instance", roomCfg.id, furIndex)
        curActor = curActor and curActor[1] or nil
        if not curActor then
            return
        end
        local stateMachine = curActor.aiStateMachine
        if not stateMachine or not stateMachine:IsState("InstanceWorkerWork") then
            return
        end
        curActor:TryTransState(
                function()
                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerWork)
                end
        )
    end
end

--[[
    @desc: 清空排队队列
    author:{author}
    time:2023-08-29 10:52:31
    --@target:
    @return:
]]
function InstanceAIBlackBoard:ClearInstnaceQueue(target)
    queueUpQueue[target] = {}
    queueUpTable[target] = {}
end

--[[
    @desc: 获取演员绑定位置
    author:{author}
    time:2023-08-30 14:32:11
    --@roomID:
	--@actor:
    @return:
]]
function InstanceAIBlackBoard:GetActorBindSeat(roomID, actor)
    --local roomCfg = InstanceModel:GetRoomConfigByID(roomID)
    local roomData = InstanceModel:GetRoomDataByID(roomID)
    for k, v in pairs(roomData.furList) do
        -- 初始化列表
        if v.state > 0 then
            if not instanceRoomSeat[roomID] then
                instanceRoomSeat[roomID] = {}
            end
            if not instanceRoomSeat[roomID][k] then
                instanceRoomSeat[roomID][k] = {}
            end
            --local furLevelCfg = InstanceModel:GetFurLevelConfigByLevelID(v.id)
            local seatCount = InstanceModel:GetFurLevelCfgAttrSum(v.id, "seat") -- 已解锁座位数量
            local roomSeatFur = instanceRoomSeat[roomID][k]
            for i2,v2 in ipairs(roomSeatFur) do
                if v2 == actor then
                    print("重复绑定")
                    return roomID, v.index, i2
                end
            end
            if seatCount > 0 and #roomSeatFur < seatCount then
                roomSeatFur[#roomSeatFur + 1] = actor
                actor.data.seat = {
                    roomID = roomID,
                    furIndex = k,
                    index = #roomSeatFur
                }
                return roomID, v.index, #roomSeatFur
            else
                --error(string.format("超出房间 %d 家具 %d 的容量上限 %d", roomID, v.index, seatCount))
            end
        end
    end
    return nil,nil,nil
end

function InstanceAIBlackBoard:UnbindActorWithSeat(actor)
    local seatInfo = actor.data.seat
    if instanceRoomSeat[seatInfo.roomID] then
        if instanceRoomSeat[seatInfo.roomID][seatInfo.furIndex] then
            local isInclude = false
            for k, v in pairs(instanceRoomSeat[seatInfo.roomID][seatInfo.furIndex]) do
                for i = #instanceRoomSeat[seatInfo.roomID][seatInfo.furIndex], 1, -1 do
                    if instanceRoomSeat[seatInfo.roomID][seatInfo.furIndex][i].instanceID == actor.instanceID then
                        table.remove(instanceRoomSeat[seatInfo.roomID][seatInfo.furIndex], i)
                        isInclude = true
                        break
                    end
                end
            end

            if isInclude then
                print("========== 离开房间", actor.instanceID, seatInfo.roomID, seatInfo.furIndex, seatInfo.index)
            else
                error(seatInfo.index)
            end
            actor.data.seat = nil
        end
    end
end

function InstanceAIBlackBoard:RegisterCollider(component)
    if not component then
        return
    end
    local go = component.m_roomObject
    colliderResponse[go] = component
    local furniturePosition = {}
    local furnitureAnim = {}
    component:GetFurnitureGoData(furniturePosition, furnitureAnim)
    colliderResponse[go] = component
    colliderTransTable[go] = furniturePosition
    animaTable[go] = furnitureAnim
end

function InstanceAIBlackBoard:GetInstanceColliderTransTable(roomID)
    local roomGO = InstanceModel:GetRoomGameObjectByID(roomID)
    local furniturePosition = colliderTransTable[roomGO]
    return furniturePosition
end


return InstanceAIBlackBoard
