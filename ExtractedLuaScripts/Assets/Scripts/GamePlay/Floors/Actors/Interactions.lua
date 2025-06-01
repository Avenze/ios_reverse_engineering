local Class = require("Framework.Lua.Class")
local Actor = require("GamePlay.Floors.Actors.Actor")

local FloatUI = GameTableDefine.FloatUI
local FloorMode = GameTableDefine.FloorMode
local CfgMgr = GameTableDefine.ConfigMgr
local GameClockManager = GameTableDefine.GameClockManager
local MeetingEventManager = GameTableDefine.MeetingEventManager
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local ColliderResponse = require("GamePlay.Floors.Actors.ColliderResponse")

local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
local UnityHelper = CS.Common.Utils.UnityHelper;

local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local TimeManager = GameTimeManager
--local LuaBehavior = CS.Framework.Lua.LuaBehavior

---@class Interactions
local Interactions = Class("Interactions", Actor)

local STATE_LOADING = "StateLoading"
local STATE_IDLE = "StateIdle"

local personUpdateIntercationTag = nil

local interactionsEntity = {}

Interactions.EVENT_PERSON_IN = 501
Interactions.EVENT_PERSON_OUT = 502
Interactions.EVENT_PERSON_QUEUE = 503
Interactions.EVENT_PERSON_ARRIVE_TARGET = 504

Interactions.m_type = "TYPE_INTERACTIONST"
-- Interactions.m_tag = nil

function Interactions:ctor()
    self:getSuper(Interactions).ctor(self)
end

function Interactions:Init(component, tag, type)
    self.m_go = component.m_roomObject ---@type UnityEngine.GameObject
    self.m_luaBehavior = UnityHelper.GetOrAddLuaBehavior(self.m_go) ---@type Framework.Lua.LuaBehavior
    self.m_luaBehavior:SetOnDestroyEvent(handler(self,self.OnDestroy))
    self.m_colliderComponent = component

    self.m_formula = loadstring("return " .. self.m_colliderComponent.m_formula)()
    self.m_threshold = self.m_colliderComponent.m_threshold
    self.m_enableQueue = self.m_colliderComponent.m_enableQueue
    self.m_tag = tag
    self.m_interactionType = type
    self.m_meetingTime = self.m_colliderComponent.m_meetingTime
    self.m_persionMood = {}
    -- self.m_colliderComponent.m_persionMood
    for i = 0, self.m_colliderComponent.m_persionMood.Length - 1 do
        local v = self.m_colliderComponent.m_persionMood[i]
        table.insert(self.m_persionMood, {x=v.x, y=v.y})
    end

    self:getSuper(Interactions).Init(self)
    self:SetState(self.StateIdle)
end

function Interactions:Update(dt)
    self:getSuper(Interactions).Update(self, dt)
end

function Interactions:OnDestroy()
    self.m_luaBehavior:ClearOnDestroyEvent()
    self.m_luaBehavior = nil
    self.m_flags = 0
    Interactions:ClearEntity(self.m_tag)
    self.m_tag = nil
end

function Interactions:Exit()
    self:getSuper(Interactions).Exit(self)
end

function Interactions:Event(msg, params)
    self:getSuper(Interactions).Event(self, msg, params)
end

function Interactions:SetData(config, localData, sceneProcessData)
    GameTimer:CreateNewTimer(2, function()
        -- if self.m_interactionType == 32 then
        --     print()
        -- end
        if not self.m_localData or (not self.m_roomUnlock and localData.unlock) then
            self.m_furnitureChanged = localData.unlock and 1 or nil
        end

        self.m_roomUnlock = localData.unlock
        self.m_currRoomIndex = config.room_index
        self.m_config = config
        self.m_localData = localData
        self.m_sceneProcessData = sceneProcessData
        self.m_sceneProcessData.interactionsActor = self
    end)
end

---@param person CompanyEmployeeNew
function Interactions:Behavior(person)
    local size = self:GetTableSize(self.StateIdle:GetPosition())
    -- if size <= 0 then
    --     return
    -- end

    local collider = ColliderResponse
    local meetRoomTrigger = person:GetInteractionEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING)
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    local curTime = gameH + (gameM / 60)
    local meetingSize = 0
    if meetRoomTrigger then
        meetingSize = self:GetTableSize(meetRoomTrigger.StateIdle:GetPosition())
    end
    if self.m_interactionType == collider.TYPE_GOTO_MEETING 
        and person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
        and not person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION | ActorDefine.Flag.FLAG_EMPLOYEE_ON_TURN_BACK | ActorDefine.Flag.FLAG_BACK_TO_WORK)
        and (person.m_stateMachine:IsState("EmployeeWorkState") or person.m_stateMachine:IsState("EmployeeGoToWorkState"))
        and person:CheckDailyMeetingValid()
    then
        if (self.m_roomIndex == nil or self.m_roomIndex == person.m_roomData.config.room_index)
            and self.m_meetingTime > 0
            and curTime >= self.m_meetingTime 
            and size > 0
        then
            person:AddFlag(self.m_tag)
            self.m_roomIndex = person.m_roomData.config.room_index
        end
    elseif meetRoomTrigger and  meetRoomTrigger.m_roomIndex == person.m_roomData.config.room_index 
        and person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
        and not person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION | ActorDefine.Flag.FLAG_EMPLOYEE_ON_TURN_BACK | ActorDefine.Flag.FLAG_BACK_TO_WORK)
        -- and not person:HasFlag(person.FLAG_EMPLOYEE_ON_TURNBACK)
        -- and not person:HasFlag(person.FLAG_BACK_TO_WORK)
        and (person.m_stateMachine:IsState("EmployeeWorkState") or person.m_stateMachine:IsState("EmployeeGoToWorkState"))
        and person:CheckDailyMeetingValid()
    then
        person:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING)
    end

    if not person.m_triggerCounter[self.m_tag] then
        return
    end
    if self.m_interactionType == collider.TYPE_GOTO_TOILE
        or self.m_interactionType == collider.TYPE_GOTO_REST
        or self.m_interactionType == collider.TYPE_GOTO_ENTERTAINMENT
        or self.m_interactionType == collider.TYPE_GOTO_GYM
    then
        person.m_triggerCounter[self.m_tag] = person.m_triggerCounter[self.m_tag] + 0.5
        local probability = self.m_formula(person.m_triggerCounter[self.m_tag])
        local p = math.random(1, 100)
        if person.m_triggerCounter[self.m_tag]%10 == 0 
            and person.m_triggerCounter[self.m_tag] >= self.m_threshold 
            and p < probability 
            and not person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION | ActorDefine.Flag.FLAG_EMPLOYEE_ON_TURN_BACK | ActorDefine.Flag.FLAG_BACK_TO_WORK)
            and person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
            and (person.m_stateMachine:IsState("EmployeeWorkState") or person.m_stateMachine:IsState("EmployeeGoToWorkState"))
            and (not meetRoomTrigger.m_meetingTime or meetingSize <= 0 or curTime < meetRoomTrigger.m_meetingTime or not person:CheckDailyMeetingValid())
            and size > 0
            --and false
        then 
            person:AddFlag(self.m_tag)
            person:Event(person.EVENT_EMPLOYEE_GOTO_ACTION)--无意义了
        end
    end
end

function Interactions:CheckPersonMood(person)
    local target = nil
    if #self.m_persionMood <= 0 or (person.m_triggerCounter[self.m_tag] or 0) < self.m_persionMood[1].x then
        person:SetTargetMood("interaction_type_"..self.m_interactionType)
        return
    end

    -- for i = 0, self.m_persionMood.Length - 1 do
    --     local v = self.m_persionMood[i]
    --     if person.m_triggerCounter[self.m_tag] >= v.x then
    --         target = v
    --     end
    -- end
    for i,v in ipairs(self.m_persionMood) do
        if person.m_triggerCounter[self.m_tag] >= v.x then
            target = v
        end
    end

    if target then
        local targetMood = GreateBuildingMana:GetMoodImprove()
        local transferVlaue = math.ceil(target.y)  --/ 1000 -- / v.z * 1000
        person:SetTargetMood("interaction_type_"..self.m_interactionType, targetMood, transferVlaue)
    end
end

---解雇后需要清空会议室的占用
function Interactions:OnEmployeeDISMISS(companyIndex,roomIndex)
    for k,v in interactionsEntity do
        if v.m_roomIndex == roomIndex then
            v.m_roomIndex = nil
            break
        end
    end
end

---static
function Interactions:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self)
end

---@return Interactions[]
function Interactions:GetEntities(tag)
    if not interactionsEntity then
        return
    end
    return interactionsEntity[tag]
end

function Interactions:GetEntity(tag, objId)
    if not objId or not interactionsEntity[tag] then
        return
    end
    return interactionsEntity[tag][objId]
end

function Interactions:CreateEntity(tag, createNewObjId)
    if not createNewObjId then
        return
    end
    if not interactionsEntity[tag] then
        interactionsEntity[tag] = {}
    end
    interactionsEntity[tag][createNewObjId] = self:CreateActor()
    return interactionsEntity[tag][createNewObjId]
end

function Interactions:ClearEntity(tag)
    if not tag then return end
    interactionsEntity[tag] = nil
end

function Interactions:RegisterPersonTrigger(person)
    if person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_PROPERTY) or (person.m_type ~= "TYPE_EMPLOYEE" and person.m_type ~= "TYPE_INSTANCE_WORKER")then
        return
    end
    for i,entity in pairs(interactionsEntity) do
        for k,v in pairs(entity) do
            v:SetTrigger(person)
        end
    end
end
---end static

function Interactions:UpdatePersonInteraction(person)
    self:Behavior(person)
    self:CheckPersonMood(person)
end

function Interactions:SetPersonUpdateIntercationTag()
    personUpdateIntercationTag = GameTimeManager:GetSocketTime()
end

function Interactions:GetPersonUpdateIntercationTag()
    return personUpdateIntercationTag
end

---@param person CompanyEmployeeNew
function Interactions:SetTrigger(person)
    local colliderResp = ColliderResponse
    local enterFunc = function(responseGo, activatorGo)
        --person:AddFlag(ActorDefine.Flag.FLAG_BACK_TO_WORK)
        if person.m_stateMachine:IsState("EmployeeGoToToiletState") then
            person.m_stateMachine.m_curState.m_colliderInteraction = self
            local coll = responseGo:GetComponent("ColliderResponse")
            self:Event(self.EVENT_PERSON_IN, {person, coll:GetTriggerCount()})
        end
    end
    local exitFunc = function(responseGo, activatorGo)
        if person:HasFlag(ActorDefine.Flag.FLAG_BACK_TO_WORK) then
            person:RemoveFlag(ActorDefine.Flag.FLAG_BACK_TO_WORK)
        end
    end
    if not self.m_colliderComponent and not self.m_colliderComponent.gameObject then
        print("Interactions is error:SetTrigger the m_colliderComponent is null")
        return
    end
    local name = self.m_colliderComponent.gameObject:GetInstanceID()
    colliderResp:SetActivatorTriggerEventOnEnter(name, person.m_go, enterFunc)
    colliderResp:SetActivatorTriggerEventOnExit(name, person.m_go, exitFunc)
    self:ResetTriggerCounter(person)
end

function Interactions:ResetTriggerCounter(person)
    if person.m_triggerCounter then
        person.m_triggerCounter[self.m_tag] = math.random(self.m_colliderComponent.m_behaviourInit.x, self.m_colliderComponent.m_behaviourInit.y)
    end
end

function Interactions:InitStates()
    local StateLoading = self:InitState(STATE_LOADING)
    function StateLoading:Enter(interactions)
        interactions:CreateGo()
    end

    function StateLoading:Update(interactions, dt)
    end

    function StateLoading:Exit(interactions)
    end

    function StateLoading:Event(interactions, msg)
    end

    -- idle
    local StateIdle = self:InitState(STATE_IDLE)
    function StateIdle:Enter(interactions)
        self.m_personQueue = {}
    end

    function StateIdle:Update(interactions, dt)
        if TimeManager:GetSocketTime() - (self.lastTime or 0) < 1 then
            return
        end
        self.lastTime = TimeManager:GetSocketTime()

        --不知道是做什么的
        --while self.m_personQueue[1] and self.m_personQueue[1].m_stateMachine.m_curState == nil do
        --    self:RemoveTopQueuePath()
        --end
        if not self.m_personQueue or #self.m_personQueue == 0 then
            return
        end

        --if self.m_personQueue[1] and self.m_personQueue[1].m_stateMachine:IsState("EmployeeQueueUpState") then
        --    return
        --end

        local idlePosition = self:GetFurnitureIdlePosition()
        if idlePosition then
            self:PersonGetIn(idlePosition)
        end

        --解雇排队中的人后需要刷新
        if self.m_needUpdateQueue then
            self:UpdateQueue()
            self.m_needUpdateQueue = false
        end
    end

    function StateIdle:Exit(interactions)
    end

    -- function StateIdle:UpdateCheckPersonMood(interactions,dt)
    --     local CheckPersonMood = function(k, person)
    --         if person:HasFlag(person.FLAG_EMPLOYEE_ON_MEETING) then
    --             return
    --         end
            
    --         local target = nil
    --         if interactions.m_persionMood.Length <= 0 then
    --             return
    --         end
    --         --for i = 0, interactions.m_persionMood.Length - 1 do
    --         for k,v in pairs(interactions.m_persionMood or {}) do
    --             if person.m_mood >= v.x then
    --                 target = v
    --             end
    --         end

    --         if target then
    --             local targetMood = 0
    --             local transferVlaue = v.y / 1000 -- /v.z*1000
    --             person:SetTargetMood(targetMood, transferVlaue, true)
    --         end
    --     end
    --     for k,p in pairs(self.m_personQueue or {}) do
    --         CheckPersonMood(k, p)
    --     end
    -- end
    

    function StateIdle:Event(interactions, msg, params)
        if msg == Interactions.EVENT_PERSON_IN then
            self:AddQueuePath(params[1], params[2])
        elseif msg == Interactions.EVENT_PERSON_OUT then
            self:PersonGetOut(params[1], params[2])
        elseif msg == Interactions.EVENT_PERSON_ARRIVE_TARGET then
            self:PersonArriveTarget(params)
        end
    end
    
    function StateIdle:GetIdlePositionSize()
        local size = 0
        local furniturePosition = self:GetPosition() or {}
        for k, v in pairs(furniturePosition) do
            if v.person == nil then
                size = size + 1
            end
        end
        return size
    end

    function StateIdle:GetFurnitureIdlePosition()
        local furniturePosition = self:GetPosition() or {}
        local enableQueue = self.parent.m_enableQueue
        for k, v in pairs(furniturePosition) do
            if v.person == nil then
                return v
            end
        end

        if not enableQueue and Tools:GetTableSize(furniturePosition) > 1 and furniturePosition["randomPos"] then
            local randomPos = Tools:CopyTable(furniturePosition["randomPos"])
            local pos = self.parent.m_go.transform.position
            pos.x = pos.x + math.random(-6,6)
            pos.z = pos.z + math.random(-6,6)
            randomPos.pos = pos
            return randomPos
        end
        return nil
    end

    function StateIdle:GetPosition()
        if not self.m_furniturePosition then
            self.m_furniturePosition = {}
        end
        if not self.m_furnitureAnim then
            self.m_furnitureAnim = {}
        end
        if self.parent.m_furnitureChanged then
            self.parent.m_colliderComponent:GetFurnitureGoData(self.m_furniturePosition, self.m_furnitureAnim)
            self.parent.m_furnitureChanged = nil
            for fgo1,pos in pairs(self.m_furniturePosition) do
                for k, fgo2 in pairs(self.parent.m_sceneProcessData.furnituresGo or {}) do                    
                    if fgo1 ~= "randomPos" and pos.furnGo == fgo2 then
                        local furnitureData = self.parent.m_localData.furnitures[k]
                        pos.localData = furnitureData.level > 0 and furnitureData or nil
                        break
                    end                                                                                
                end
                if self.parent.m_tag == Actor.FLAG_INSTANCEWORKER_ON_SLEEPING then -- 副本的卧室                        
                    if pos.posGo:IsNull() or not pos.posGo or pos.posGo.activeInHierarchy == false then
                        self.m_furniturePosition[fgo1] = nil
                    end
                end
                if not pos.localData then
                    self.m_furniturePosition[fgo1] = nil
                end
            end
        end
        return self.m_furniturePosition
    end

    function StateIdle:PersonGetIn(idlePosition, per)
        if FloorMode:IsRoomBroken(self.parent.m_currRoomIndex) then
            return false
        end

        local person = self:RemoveTopQueuePath(per)
        if person then
            idlePosition.person = person
            person.m_idlePosition = idlePosition
            person:Event(ActorDefine.Event.EVENT_GET_IN_IDLE_POSITION, {
                pos = idlePosition.pos,
                dir = idlePosition.dir,
            })
        end
        if #self.m_personQueue > 0 then
            self:UpdateQueue()
        end
        return true
    end

    function StateIdle:PersonGetOut(person, personCount)
        if person.m_idlePosition then
            person.m_idlePosition.person = nil
            person.m_idlePosition = nil
        end
        if self.parent.m_localData then
            self.parent.m_localData.using_count = (self.parent.m_localData.using_count or 0) + 1
        end
        ---Person离开队伍，出现空位
        local idlePosition = self:GetFurnitureIdlePosition()
        if idlePosition then
            self:PersonGetIn(idlePosition)
        end
    end

    ---取出排在队伍最前面的Person
    function StateIdle:RemoveTopQueuePath(per)
        local p = per or table.remove(self.m_personQueue, 1)
        if p then
            if p.m_queueBack then
                p.m_queueBack.m_queueFront = nil
            end
            p.m_queueBack = nil
            -- p.m_inQueue = nil
            --p.m_idlePosition = nil
        end
        return p
    end

    ---从队列中移除Person
    ---@param per CompanyEmployeeNew
    function StateIdle:RemovePersonFromQueue(per)
        local len = #self.m_personQueue
        for i = 1, len do
            if self.m_personQueue[i] == per then
                table.remove(self.m_personQueue,i)
                if per.m_queueBack then
                    per.m_queueBack.m_queueFront = per.m_queueFront
                end
                if per.m_queueFront then
                    per.m_queueFront.m_queueBack = per.m_queueBack
                end
                per.m_queueBack = nil
                per.m_queueFront = nil
                --per.m_idlePosition = nil
                self.m_needUpdateQueue = true
                break
            end
        end
    end
    
    function StateIdle:AddQueuePath(person)
        local a = person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_IN_QUEUE)
        local b = not person:HasFlag(self.parent.m_tag)
        local c = (self.parent ~= person:GetInteractionEntity(self.parent.m_tag))
        if person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_IN_QUEUE)     --在排队排除
            or not person:HasFlag(self.parent.m_tag)          --活动类型不匹配排除
            or (self.parent ~= person:GetInteractionEntity(self.parent.m_tag)) --活动房间不匹配排除
        then
            --if self.parent.m_tag == ColliderResponse.TYPE_GOTO_MEETING then
            --    printf("没进入排队，A(已经在排队中)="..tostring(a)..",B(活动类型不对应)="..tostring(b).."C=(它的目标Entity不是这个)"..tostring(c))
            --    printf("没进入排队，self.flag="..tostring(self.parent.m_tag)..",person.flag="..tostring(person.m_flags))
            --end
            return
        end

        if not self.parent.m_enableQueue then
            local idlePosition = self:GetFurnitureIdlePosition()
            if idlePosition then
                self:PersonGetIn(idlePosition, person)
            end
            --printf("没进入排队，self.parent.m_enableQueue")
            return
        end
        
        person.m_queueFront = self.m_personQueue[#self.m_personQueue]
        table.insert(self.m_personQueue, person)
        -- person.m_inQueue = true
        if person.m_queueFront then
            person.m_queueFront.m_queueBack = person
        end
        person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeQueueUpState)

        if self.m_queuePath then
            self:UpdatePerson(person)
            return
        end

        --AIPath
        --local seeker = person.m_go:GetComponent("Seeker")
        --if seeker then
        --    local cb = seeker.pathCallback
        --    seeker.pathCallback = function(p)
        --        if p.error ~= nil then
        --            self.m_queuePath = {}
        --            local lastPos =  p.vectorPath[0]
        --            for i = 1, p.vectorPath.Count - 1 do
        --                if Vector3.Distance(lastPos, p.vectorPath[i]) > 1 then
        --                    table.insert(self.m_queuePath, 1, p.vectorPath[i])
        --                    lastPos = p.vectorPath[i]
        --                end
        --            end
        --            self:UpdateQueue()
        --        end
        --        seeker.pathCallback = cb
        --    end
        --    local start = UIView:GetTrans(self.parent.m_go, "QueueStart")
        --    local endPoint = self.parent.m_colliderComponent.m_queueStartPoint or self.parent.m_go
        --    seeker:StartPath(start.position, endPoint.transform.position)
        --else
        --    error(debug.traceback("person have no path component!"))
        --end

        --AIPathNav
        local startPoint = UIView:GetTrans(self.parent.m_go, "QueueStart")
        local endPoint = self.parent.m_colliderComponent.m_queueStartPoint.transform or self.parent.m_go.transform
        local vectorPath = UnityHelper.SearchPathByNavMesh(startPoint.position,endPoint.position)

        self.m_queuePath = {}
        local lastPos =  vectorPath[0]
        for i = 1, vectorPath.Length - 1 do
            local dir = vectorPath[i] - lastPos
            local dis = dir.magnitude
            if dis > 1 then
                --插入N个距离大于1的点.
                dir = dir.normalized
                for j = 1, dis,1 do
                    lastPos = lastPos+dir*1
                    table.insert(self.m_queuePath, 1, lastPos)
                end
            end
        end
        self:UpdateQueue()
    end

    ---@param per CompanyEmployeeNew
    function StateIdle:ReSetTargetPosition(per,id)
        if not per.m_stateMachine.m_curState then
            return
        end

        local pos = self.m_queuePath[id] or self.m_queuePath[#self.m_queuePath]
        if per.m_stateMachine:IsState("EmployeeQueueUpState") then
            --已经在排队就更改位置
            per.m_stateMachine.m_curState:MoveToQueuePos(pos)
        elseif per.m_stateMachine:IsState("EmployeeGoToToiletState") then
            --进入排队
            per.m_stateMachine:ChangeState(ActorDefine.State.EmployeeQueueUpState)
            per.m_stateMachine.m_curState:MoveToQueuePos(pos)
        end
    end

    function StateIdle:UpdatePerson(person)
        if not self.m_queuePath then
            return
        end
        self:ReSetTargetPosition(person, person:GetQueueId())
    end

    function StateIdle:UpdateQueue()
        if not self.m_queuePath then
            return
        end
        local queueMaxCount = #self.m_queuePath
        for _,per in ipairs(self.m_personQueue or {}) do
            local queueID = per:GetQueueId()
            if queueID <= queueMaxCount then --不需要移动就不要动了
                self:ReSetTargetPosition(per, queueID)
            end
        end
    end

    ---@param person CompanyEmployeeNew
    function StateIdle:PersonArriveTarget(person)
        if person.m_idlePosition then
            if person.SetPersonBonuses then                            
                local random = math.random(1, #person.m_idlePosition.anim)
                local anim = person.m_idlePosition.anim[random]
                local setting = person.m_idlePosition.setting[random]
                person.m_randomAnim = {anim = anim, setting = setting}

                if person:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ENTERTAINMENT) then
                    self:SetPersonAnimationByAccessory(person, random)
                
                end
                
                person:SetPersonBonuses(person.m_randomAnim, {"pleasure", "addexp", "time"})
                
                local timeRange = self.parent.m_colliderComponent.m_timeRange
                person.m_randomAnim.countdown = math.random(timeRange.x, timeRange.y) / 1000 + (person.m_randomAnim.time or -1)
                
                --person.m_stateMachine:ChangeState(setting and ActorDefine.State.EmployeeSitting or ActorDefine.State.EmployeeToiletState)
                return
            end
        end

        if self.m_personQueue[1] ~= person then
            person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeQueueUpState)
            --person:SetState(person.StateQueueUp)
            return
        end

        local idlePosition = self:GetFurnitureIdlePosition()
        if idlePosition then
            local succ = self:PersonGetIn(idlePosition)
            if not succ then
                person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeQueueUpState)
                --person:SetState(person.StateQueueUp)
            end
        else
            person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeQueueUpState)
            --person:SetState(person.StateQueueUp)
        end
    end

    ---@param person CompanyEmployeeNew
    function StateIdle:SetPersonAnimationByAccessory(person, random)
        local data = person.m_idlePosition.localData
        local config = CfgMgr.config_furnitures_levels[data.id][data.level]
        person.m_randomAnim.moodTransfer = config.pleasure or 0
        if data.accessory_info and data.accessory_info[FloorMode.F_TYPE_AUX_CONDITION] then
            local _,accessory = next(data.accessory_info[FloorMode.F_TYPE_AUX_CONDITION])
            local accessoryLevelId = accessory.lvId
            -- local accessoryId, accessoryLevel = CfgMgr.config_furnitures_levels[accessoryLevelId].furniture_id, CfgMgr.config_furnitures_levels[accessoryLevelId].level
            -- local accessoryConifg = CfgMgr.config_furnitures_levels[accessoryId][accessoryLevel]
            -- person.m_randomAnim.moodTransfer = person.m_randomAnim.moodTransfer + (accessoryConifg.pleasure or 0)
            for i, v in ipairs(self.parent.m_localData.furnitures or {}) do
                if v.level_id == accessoryLevelId then
                    local accessoryGo = self.parent.m_sceneProcessData.furnituresGo[i]
                    local accessoryAnim = self.m_furnitureAnim[accessoryGo]
                    if accessoryAnim then
                        person.m_randomAnim.anim = accessoryAnim.anim[random]
                        person.m_randomAnim.setting = accessoryAnim.setting[random]
                    end
                    return
                end
            end
        end
    end
end

return Interactions