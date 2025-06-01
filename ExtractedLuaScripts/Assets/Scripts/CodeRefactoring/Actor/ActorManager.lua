--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{gxy}
    time:2023-08-07 14:00:07
    description:演员管理类,负责管理游戏中所有Actor增删查改, AI的异步刷新也放在这里面处理
]]
---@class ActorManager
local ActorManager = GameTableDefine.ActorManager
local ActorTypeEnum = require("CodeRefactoring.Actor.ActorTypeEnum")
local NewInstanceWorker = require("CodeRefactoring.Actor.Actors.InstanceWorker")
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local UnityTime = CS.UnityEngine.Time
local UnityHelper = CS.Common.Utils.UnityHelper
local FloorMode = GameTableDefine.FloorMode



local InstanceDataManager = GameTableDefine.InstanceDataManager
local InstanceModel = GameTableDefine.InstanceModel

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local instanceID = 1 -- 演员实例ID
local actorArray = {} ---@type ActorBase[]-- 演员集合, 有序数组, 方便做遍历
local actorTable = {} -- 演员id表
local actorTypeTable = {} -- 演员类型列表
local actorRoomTable = {} -- 演员房间列表
local actorPool = {} ---@type ActorBase[][] ---回收的ActorTable, [ActorType][ActorBase]

local aiTransActorQueue = {} -- ai行为变化演员队列
local aiTransStateQueue = {} -- ai行为变化状态队列
local transLimit = 20 -- 每帧行为变换数量限制
local updateTimePoint = {} -- 演员更新时间戳
local UPDATE_LIMIT = 20 -- 每帧角色更新的数量限制
local InActorGos = {} ---@type UnityEngine.GameObject[]
local OutActorGos = {} ---@type UnityEngine.GameObject[]

local findActorResult = {} -- 查找演员表, 缓存该表避免每帧重复调用创建新表
local updateLoopIndex = 1 --更新循环到的位置

local floorBossEntity = nil ---@type PropertyWorker 公司场景Boss实体

function ActorManager:Init()
    self.StateInstances = {}
    for k, v in pairs(ActorDefine.State) do
        if not self.StateInstances[v] then
            self.StateInstances[v] = require("CodeRefactoring.AI.StateMachines."..v)
        end
    end
    for k, v in pairs(ActorDefine.CycleInstanceState) do
        if not self.StateInstances[v] then
            self.StateInstances[v] = require("GamePlay.CycleInstance."..v)
        end
    end
    self.m_needUpdateList = {}
end

function ActorManager:Update(dt)
    local curTime = GameTimeManager:GetCurrentServerTimeInMilliSec()
    local arrayCount = #actorArray
    --数据刷新 批次更新

    local count = 0
    local startIndex = updateLoopIndex
    local index = startIndex
    local needUpdateList = self.m_needUpdateList ---@type ActorBase[]--避免actorArray在Update过程中出现改变导致Update不正确
    while count < UPDATE_LIMIT do
        count = count + 1
        needUpdateList[count] = actorArray[index]
        if not needUpdateList[count] then
            printf("ActorManager List管理有点问题")
        end
        index = index + 1
        --循环完后从1开始,免得只循环少于UPDATE_LIMIT就结束循环
        if index > arrayCount then
            index = 1
        end
        --再次遇到开始的Index
        if index == startIndex then
            break
        end
    end
    --下次循环从此Index开始
    updateLoopIndex = index
    if count>0 then
        local deltaTime = UnityTime.deltaTime
        local indexShift = 0
        for i=1,count do
            local actor = needUpdateList[i]
            if actor then
                if actor.HasFlag and actor:HasFlag(ActorDefine.Flag.FLAG_ACTIVE) then
                    local lastUpdateTime = updateTimePoint[actor.instanceID]
                    local actorDt = lastUpdateTime and (curTime - lastUpdateTime)*0.001 or deltaTime
                    actor:OnUpdate(actorDt)
                    updateTimePoint[actor.instanceID] = curTime
                elseif actor.m_isPooling then--回收销毁的Actor
                    table.RemoveValue(actorArray, actor)

                    local realIndex = updateLoopIndex - count - 1 + i
                    if realIndex <= 0 then
                        realIndex = realIndex + arrayCount
                    end
                    if realIndex < updateLoopIndex then
                        indexShift = indexShift + 1
                    end
                    self:RecycleActor(actor)
                end
            else
                printf("ActorManager List管理有点问题")
            end
        end
        if indexShift>0 then
            updateLoopIndex = updateLoopIndex - indexShift
            --回到起点
            if updateLoopIndex > #actorArray then
                updateLoopIndex = 1
            end
        end
    end
    --for i = updateLoopIndex, arrayCount do
    --    if count > UPDATE_LIMIT then -- 达到每帧最大循环次数退出
    --        break
    --    end
    --    local actor = actorArray[i]
    --    local dt = curTime - (updateTimePoint[actor.instanceID] or curTime)
    --    actor:OnUpdate(dt)
    --    updateTimePoint[actor.instanceID] = curTime
    --    updateLoopIndex = updateLoopIndex + 1
    --    count = count + 1
    --end

    --变换队列刷新
    for i = 1, transLimit do
        if next(aiTransActorQueue) ~= nil then
            local actor = table.remove(aiTransActorQueue, 1)
            local state = table.remove(aiTransStateQueue, 1)
            state()
        else
            break
        end
    end
end

local ActorPath = "CodeRefactoring.Actor.Actors."

function ActorManager:CreateActorSync(actorType, data,actorPath)
    if not actorPath then
        actorPath = ActorPath
    end

    local actorClass
    if type(actorType) == "string" then
        local actorPath = actorPath.. actorType
        actorClass = require(actorPath)
    else
        actorClass = actorType
        actorType = actorClass.__cname
    end
    local actor = self:GetActorFromActorPool(actorType)
    if not actor then
        actor = actorClass.create(data)
    end
    local actorData = actor.data
    actor.instanceID = instanceID
    instanceID = instanceID + 1
    actorArray[#actorArray + 1] = actor
    actorTable[actor.instanceID] = actor

    -- 创建actorRoomTable储存结构
    if not actorTypeTable[actorType] then
        actorTypeTable[actorType] = {}
    end
    actorTypeTable[actorType][#actorTypeTable[actorType] + 1] = actor
    -- 创建actorRoomTable储存结构
    if actorData.buildID then
        if not actorRoomTable[actorData.buildID] then
            actorRoomTable[actorData.buildID] = {}
        end
        if not actorRoomTable[actorData.buildID][actorData.roomID] then
            actorRoomTable[actorData.buildID][actorData.roomID] = {} -- roomID默认为0, 如果没有所属roomID, 则存入索引为0的表中
        end
        if not actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex] then
            actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex] = {}
        end
        local furTable = actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex]
        furTable[#furTable + 1] = actor
    end

    return actor
end

--function ActorManager:CreateActorAsync(type, goPath, data, spawnPos, spawnRot, cb) -- 增
--    local function addNewActor(actor)
--        local actorData = actor.data
--        actorData["type"] = type
--
--        actorArray[#actorArray + 1] = actor
--        actorTable[actor.instanceID] = actor
--
--        -- 创建actorRoomTable储存结构
--        if not actorTypeTable[type] then
--            actorTypeTable[type] = {}
--        end
--        actorTypeTable[type][#actorTypeTable[type] + 1] = actor
--
--        -- 创建actorRoomTable储存结构
--        if not actorRoomTable[actorData.buildID] then -- 所有角色都有所属建筑
--            actorRoomTable[actorData.buildID] = {}
--        end
--        if not actorRoomTable[actorData.buildID][actorData.roomID] then
--            actorRoomTable[actorData.buildID][actorData.roomID] = {} -- roomID默认为0, 如果没有所属roomID, 则存入索引为0的表中
--        end
--        if not actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex] then
--            actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex] = {}
--        end
--        local furTable = actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureIndex]
--        furTable[#furTable + 1] = actor
--    end
--
--    --执行创建流程
--    if type == ActorTypeEnum.InstanceWorker then
--        local instance = NewInstanceWorker:new(data)
--        instance:Init(instanceID, nil, data, ai, spawnPos, spawnRot)
--        instanceID = instanceID + 1 -- 序号自增
--        local perfabPath = string.format("Assets/Res/Prefabs/character/Instance/%s.prefab", goPath)
--        GameResMgr:AInstantiateObjectAsyncManual(
--            perfabPath,
--            self,
--            function(go)
--                    instance:AddGO(go)
--                    if cb then
--                        cb(instance)
--                    end
--                end
--        )
--        addNewActor(instance)
--        return instance
--    elseif type == ActorTypeEnum.Employees then
--    elseif type == ActorTypeEnum.Bus then
--    end
--end

--删
function ActorManager:DestroyActor(id)
    local actor = actorTable[id]
    if not actor then
        return 
    end
    local actorData = actor.data
    -- 从actorTable中移除
    actorTable[id] = nil
    -- 从actorArray中移除
    for i=1, #actorArray do
        if actorArray[i] == actor then
            table.remove(actorArray,i)
            break
        end
    end
    -- 从actorTypeTable中移除
    local typeList = actorTypeTable[actorData.type]
    for i=1, #typeList do
        if typeList[i] == actor then
            table.remove(typeList,i)
            break
        end
    end
    -- 从actorRoomTable中移除
    if actorData.buildID then
        if actorRoomTable[actorData.buildID] and actorRoomTable[actorData.buildID][actorData.roomID]
                and actorRoomTable[actorData.buildID][actorData.roomID] [actorData.furnitureID] then
            local furTable = actorRoomTable[actorData.buildID][actorData.roomID][actorData.furnitureID]
            for i=1, #furTable do
                if furTable[i] == actor then
                    table.remove(furTable,i)
                    break
                end
            end
        end
    end

    actor:Destroy()
end

---回收Actor到ActorPool里面
---@param actor ActorBase
---@private
function ActorManager:RecycleActor(actor)
    local actorType = actor.__cname
    local actors = actorPool[actorType]
    if not actors then
        actors = {}
        actorPool[actorType] = actors
    end
    table.insert(actors,#actors+1,actor)

    -- 从actorTypeTable中移除
    local typeList = actorTypeTable[actorType]
    for i=1, #typeList do
        if typeList[i] == actor then
            table.remove(typeList,i)
            break
        end
    end
end

---从Pool中取出对应ActorType的Actor
---@return ActorBase
function ActorManager:GetActorFromActorPool(actorType)
    local actors = actorPool[actorType]
    if actors then
        local len = #actors
        if len>0 then
            local actor = table.remove(actors,len)
            actor.m_isPooling = false
            return actor
        end
    end
    return nil
end

--查, 根据实例ID
function ActorManager:GetActorByID(instanceID)
    if actorTable[instanceID] then
        return actorTable[instanceID]
    else
        print("未找到ID为[" .. instanceID .. "]的Actor", debug.traceback())
        return nil
    end
end

-- 查, 根据房间
function ActorManager:GetActorsByRoom(buildID, roomID, furIndex)
    if not buildID then -- 如果没有buildID则直接不执行查找
        return
    end
    findActorResult = {}

    local buildTable = actorRoomTable[buildID] or nil
    if not roomID then -- 如果没有roomID则返回buildID下所有子节点
        if buildTable then
            for roomK, roomV in pairs(buildTable) do
                for furK, furV in pairs(roomV) do
                    for i = 1, #furV do
                        result[#findActorResult + 1] = furV[i]
                    end
                end
            end
            return findActorResult
        else
            return findActorResult
        end
    end

    local roomTable = actorRoomTable[buildID][roomID] or nil
    if not roomTable then -- 如果没有furID 则返回roomID下所有子节点
        if roomTable then
            for furK, furV in pairs(roomTable) do
                for i = 1, #furV do
                    result[#findActorResult + 1] = furV[i]
                end
            end
            return findActorResult
        else
            return findActorResult
        end
    end

    findActorResult = actorRoomTable[buildID][roomID][furIndex] or nil
    return findActorResult
end

-- 查, 根据演员种类
function ActorManager:GetActorByType(type)
    findActorResult = actorTypeTable[type] or nil
    return findActorResult
end

-- 尝试切换状态
function ActorManager:TryTransState(actor, state)
    -- 将要变换的状态加入队列, 顺序执行
    aiTransActorQueue[#aiTransActorQueue + 1] = actor
    aiTransStateQueue[#aiTransStateQueue + 1] = state
end

function ActorManager:OnStateEnter(state)
    if state == GameStateManager.GAME_STATE_FLOOR then
    elseif state == GameStateManager.GAME_STATE_CITY then
    elseif state == GameStateManager.GAME_STATE_INIT then
    elseif state == GameStateManager.GAME_STATE_INSTANCE then
        EventManager:RegEvent(
            "INSTANCE_WORK",
            function()
                local instanceWorkers = self:GetActorByType("InstanceWorker")
                if not instanceWorkers then
                    return
                end
                for i = 1, #instanceWorkers do
                    local actor = instanceWorkers[i]
                    if actor.initialized then
                        local stateMachine = actor.aiStateMachine ---@type PersonStateMachine
                        actor:TryTransState(
                                function()
                                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerRunToWorkSeat, actor)
                                end
                        )

                    end
                end
            end
        )

        EventManager:RegEvent(
            "INSTANCE_EAT",
            function()
                GameTableDefine.InstanceAIBlackBoard:ClearSeat()
                if not InstanceModel.actorSeatBind[InstanceModel.timeType] or next(InstanceModel.actorSeatBind[InstanceModel.timeType]) == nil then
                    InstanceModel:WorkerAttrRevert(InstanceModel.timeType, true)
                end
                local actorSeatBind = InstanceModel.actorSeatBind[InstanceModel.timeType]
                local instanceWorkers = self:GetActorByType("InstanceWorker")
                local rooms = InstanceModel:GetRoomDataByType(3)
                local targetRoomID = rooms[1].roomID
                if not instanceWorkers then
                    return
                end
                table.sort(instanceWorkers,function(a, b)
                    local attrA = a.data and InstanceModel:GetWorkerAttr(a.data.roomID,a.data.furIndex).hungry or 0
                    local attrB = b.data and InstanceModel:GetWorkerAttr(b.data.roomID,b.data.furIndex).hungry or 0
                    return attrA < attrB
                end)

                for i = 1, #instanceWorkers do
                    local actor = instanceWorkers[i]
                    if actor.initialized then
                        local stateMachine = actor.aiStateMachine
                        actor:TryTransState(
                            function()
                                stateMachine:ChangeState(ActorDefine.State.InstanceWorkerRunToEatQueue, actor, targetRoomID)
                            end
                        )
                    end
                end
            end
        )

        EventManager:RegEvent(
            "INSTANCE_SLEEP",
            function()
                GameTableDefine.InstanceAIBlackBoard:ClearSeat()
                if not InstanceModel.actorSeatBind[InstanceModel.timeType] or next(InstanceModel.actorSeatBind[InstanceModel.timeType]) == nil then
                    InstanceModel:WorkerAttrRevert(InstanceModel.timeType, true)
                end
                local actorSeatBind = InstanceModel.actorSeatBind[InstanceModel.timeType]
                local instanceWorkers = self:GetActorByType("InstanceWorker")
                if not instanceWorkers then
                    return
                end
                table.sort(instanceWorkers,function(a, b)
                    local attrA = a.data and InstanceModel:GetWorkerAttr(a.data.roomID,a.data.furIndex).physical or 0
                    local attrB = b.data and InstanceModel:GetWorkerAttr(b.data.roomID,b.data.furIndex).physical or 0
                    return attrA < attrB
                end)

                for i = 1, #instanceWorkers do
                    local actor = instanceWorkers[i]
                    if actor.initialized then
                        local actorData = actor.data
                        local stateMachine = actor.aiStateMachine
                        if actorSeatBind[actorData.roomID] and actorSeatBind[actorData.roomID][actorData.furnitureIndex] then
                            local targetRoomID = actorSeatBind[actorData.roomID][actorData.furnitureIndex]
                            actor:TryTransState(
                                function()
                                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerRunToSleepQueue, actor, targetRoomID)
                                end
                            )
                        else
                            actor:TryTransState(
                                function()
                                    stateMachine:ChangeState(ActorDefine.State.InstanceWorkerRunToSleepQueue, actor)
                                end
                            )
                        end
                        
                    end
                end
            end
        )
    elseif state == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
        EventManager:RegEvent(
            "CYCLE_INSTANCE_WORK",
            function()
                    local instanceWorkers = self:GetActorByType("CycleInstanceWorker")
                    if not instanceWorkers then
                        return
                    end
                    for i = 1, #instanceWorkers do
                        local actor = instanceWorkers[i]
                        if actor.initialized then
                            local stateMachine = actor.aiStateMachine ---@type PersonStateMachine
                            actor:TryTransState(
                                    function()
                                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToWorkSeat, actor)
                                    end
                            )

                        end
                    end
                end
        )

        EventManager:RegEvent(
            "CYCLE_INSTANCE_EAT",
            function()
                    GameTableDefine.InstanceAIBlackBoard:ClearSeat()
                    local currentModel = CycleInstanceDataManager:GetCurrentModel() ---@type  CycleInstanceModel
                    if not currentModel.actorSeatBind[currentModel.timeType] or next(currentModel.actorSeatBind[currentModel.timeType]) == nil then
                        currentModel:WorkerAttrRevert(currentModel.timeType, true)
                    end
                    local actorSeatBind = currentModel.actorSeatBind[currentModel.timeType]
                    local instanceWorkers = self:GetActorByType("CycleInstanceWorker")
                    local rooms = currentModel:GetRoomDataByType(3)
                    local targetRoomID = rooms[1].roomID
                    if not instanceWorkers then
                        return
                    end

                    for i = 1, #instanceWorkers do
                        local actor = instanceWorkers[i]
                        if actor.initialized then
                            local stateMachine = actor.aiStateMachine
                            actor:TryTransState(
                                    function()
                                        stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToEatQueue, actor, targetRoomID)
                                    end
                            )
                        end
                    end
                end
        )

        EventManager:RegEvent(
            "CYCLE_INSTANCE_SLEEP",
            function()
                    GameTableDefine.CycleInstanceAIBlackBoard:ClearSeat()
                    local currentModel = CycleInstanceDataManager:GetCurrentModel() ---@type  CycleInstanceModel
                    if not currentModel.actorSeatBind[currentModel.timeType] or next(currentModel.actorSeatBind[currentModel.timeType]) == nil then
                        currentModel:WorkerAttrRevert(currentModel.timeType, true)
                    end
                    local actorSeatBind = currentModel.actorSeatBind[currentModel.timeType]
                    local instanceWorkers = self:GetActorByType("CycleInstanceWorker")
                    if not instanceWorkers then
                        return
                    end

                    for i = 1, #instanceWorkers do
                        local actor = instanceWorkers[i]
                        if actor.initialized then
                            local actorData = actor.data
                            local stateMachine = actor.aiStateMachine
                            local forceWork = currentModel:GetRoomIsFullForce(actorData.roomID)
                            if forceWork then
                                actor:TryTransState(
                                        function()
                                            stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToWorkSeat, actor)
                                        end
                                )
                            else
                                if actorSeatBind[actorData.roomID] and actorSeatBind[actorData.roomID][actorData.furnitureIndex] then
                                    local targetRoomID = actorSeatBind[actorData.roomID][actorData.furnitureIndex]
                                    actor:TryTransState(
                                            function()
                                                stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToSleepQueue, actor, targetRoomID)
                                            end
                                    )
                                else
                                    actor:TryTransState(
                                            function()
                                                stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleInstanceWorkerRunToSleepQueue, actor)
                                            end
                                    )
                                end
                            end
                        end
                    end
                end
        )
    end
end

function ActorManager:OnStateExit(state)
    if state == GameStateManager.GAME_STATE_FLOOR then
    elseif state == GameStateManager.GAME_STATE_CITY then
    elseif state == GameStateManager.GAME_STATE_INIT then
    elseif state == GameStateManager.GAME_STATE_INSTANCE then
        local actors = self:GetActorByType("InstanceWorker")
        if not actors then
            return
        end
        for i = #actors, 1, -1 do
            local instanceID = actors[i].instanceID
            self:DestroyActor(instanceID)
        end
        for k,v in pairs(InstanceDataManager.config_rooms_instance) do
            GameTableDefine.InstanceAIBlackBoard:ClearInstnaceQueue(k)
        end
    elseif state == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
        local actors = self:GetActorByType("CycleCastleWorker")
        if actors then
            for i = #actors, 1, -1 do
                local instanceID = actors[i].instanceID
                self:DestroyActor(instanceID)
            end
        end
        
        local clients = self:GetActorByType("CycleCastleClient")
        if clients then
            for i = #clients, 1, -1 do
                local instanceID = clients[i].instanceID
                self:DestroyActor(instanceID)
            end
        end

    end
end

function ActorManager:ResetEmployeeDailyMeeting()
    local actorList = actorArray
    for k, person in pairs(actorList) do
        if person.m_type == ActorDefine.ActorType.Employee
                and person:HasFlag(ActorDefine.Flag.FLAG_ACTIVE | person.FLAG_EMPLOYEE_ON_WORKING)
                and person.m_employeeLocalData
        then
            person:AddDailyMeetingMaxLimit()
        end
    end
end

function ActorManager:DebugData()
end

function ActorManager:ConstructTrigger(isEnter, actorGo, hashCode)
    local isDay = GameTableDefine.LightManager:IsDayOrNight() or isEnter
    if actorGo.transform.parent then
        if not isEnter then
            for k, v in pairs(InActorGos or {}) do
                if k == hashCode then
                    InActorGos[k] = nil
                    break
                end
            end
            if not OutActorGos then
                OutActorGos = {}
            end
            OutActorGos[hashCode] = actorGo.transform.parent.gameObject

        else

            for k, v in pairs(OutActorGos or {}) do
                if k == hashCode then
                    OutActorGos[k] = nil
                    break
                end
            end
            if not InActorGos then
                InActorGos = {}
            end
            InActorGos[hashCode] = actorGo.transform.parent.gameObject
        end
        UnityHelper.ChangeActorDayOrNightMatColor(actorGo.transform.parent.gameObject, isDay)
    end
end

function ActorManager:InitEventReg()
    EventManager:RegEvent("CONSTRUCT_ON_TRIGGER", function(isEnter, actorGo, hashCode)
        self:ConstructTrigger(isEnter, actorGo, hashCode)
    end)
end

function ActorManager:SceneSwtichDayOrLight(isDay)
    for k, go in pairs(OutActorGos) do
        if go:IsNull() then
            OutActorGos[k] = nil
        else
            UnityHelper.ChangeActorDayOrNightMatColor(go, isDay)
        end
    end

end

--[[
    @desc:将一些只在室外产生的角色对象放到对象管理器中
    author:{author}
    time:2023-09-05 15:19:16
    --@go:
	--@isAdd:
    @return:
]]
function ActorManager:OutActorChange(go, isAdd)
    if not FloorMode:IsProcessDayNightScene() then
        return
    end
    local triggerGo = UnityHelper.FindTheChildByGo(go, "Trigger")
    local hashCode = nil
    if triggerGo then
        hashCode = triggerGo:GetHashCode()
    end
    if not hashCode then
        return
    end
    if InActorGos[hashCode] then
        return
    end
    if isAdd then
        OutActorGos[hashCode] = go
        --设置一下当前的颜色
        UnityHelper.ChangeActorDayOrNightMatColor(go, GameTableDefine.LightManager:IsDayOrNight())
    else
        OutActorGos[hashCode] = nil
    end
end

function ActorManager:RefreshEmployeesMood()
    for i, actor in ipairs(actorArray or {}) do
        if actorArray.HasFlag and actor:HasFlag(ActorDefine.Flag.FLAG_ACTIVE) and actor.UpdateFurnitureMood then
            actor:UpdateFurnitureMood()
        end
    end
end

function ActorManager:DebugAddFlag(flag)
    for i, actor in ipairs(actorArray or {}) do
        if not actor:HasFlag(self.FLAG_EMPLOYEE_ON_ACTION | self.FLAG_EMPLOYEE_OFF_WORKING | self.FLAG_EMPLOYEE_PROPERTY | self.FLAG_BACK_TO_WORK) then
            actor:AddFlag(flag)
        end
    end
end

function ActorManager:RegFloorBossEntity(boss)
    floorBossEntity = boss
end

function ActorManager:GetFloorBossEntity()
    return floorBossEntity
end

function ActorManager:UnRegFloorBossEntity(boss)
    if floorBossEntity == boss then
        floorBossEntity = nil
    end
end

return ActorManager