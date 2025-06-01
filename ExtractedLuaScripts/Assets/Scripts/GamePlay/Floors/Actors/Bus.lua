local Class = require("Framework.Lua.Class")
local Actor = require("GamePlay.Floors.Actors.Actor")
-- local GameResMgr = require("GameUtils.GameResManager")
-- local UIView = require("Framework.UI.View")

 local FloatUI = GameTableDefine.FloatUI
 local FloorMode = GameTableDefine.FloorMode
 local CfgMgr = GameTableDefine.ConfigMgr
 local BuyCarManager = GameTableDefine.BuyCarManager
 local CompanyMode = GameTableDefine.CompanyMode
 
-- local Quaternion = CS.UnityEngine.Quaternion
 local GameObject = CS.UnityEngine.GameObject
 local UnityHelper = CS.Common.Utils.UnityHelper
 local Vector3 = CS.UnityEngine.Vector3
 local BoxCollider = CS.UnityEngine.BoxCollider
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")

-- local DotweenUtil = CS.Common.Utils.DotweenUtil
-- local UnityHelper = CS.Common.Utils.UnityHelper
-- local Vector3 = CS.UnityEngine.Vector3
-- local Seeker = CS.Pathfinding.Seeker
-- local SimpleSmoothModifier = CS.Pathfinding.SimpleSmoothModifier


local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local TimeManager = GameTimeManager

local Bus = Class("Bus", Actor)

local STATE_LOADING = "StateLoading"
local STATE_IDLE = "StateIdle"
local STATE_COMING = "StateComing"
local STATE_ARRIVED = "StateArrived"
local STATE_LEAVING = "StateLeaving"

Bus.EVENT_BUS_ARRIVED = 201
Bus.EVENT_BUS_LEFT = 202
Bus.EVENT_NEW_PASSENGER = 203
Bus.EVENT_PERSON_IN = 204
Bus.EVENT_PERSON_OUT = 205

Bus.m_type = "TYPE_BUS"

local busEntity = nil
local carEntity = nil

function Bus:ctor()
    self:getSuper(Bus).ctor(self)
end

function Bus:Init(rootGo, prefab)
    self.m_rootGo = rootGo
    self.m_prefab = prefab
    self.m_passengers = {}
    self.m_passengersTag = {}
    self:getSuper(Bus).Init(self)
    self:SetState(self.StateLoading)
end

function Bus:Update(dt)
    self:getSuper(Bus).Update(self, dt)
end

function Bus:Exit()
    self:getSuper(Bus).Exit(self)
end

function Bus:Event(msg, params)
    self:getSuper(Bus).Event(self, msg, params)
    if msg == self.EVENT_NEW_PASSENGER then
        self:AddPassenger(params)
    end
end

function Bus:InitFloatUIView()
    FloatUI:SetObjectCrossCamera(self, function(view)
        if view then
            view:Invoke("ShowEventBumble")
        end
    end)
end

function Bus:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self)
end

function Bus:AddPassenger(passenger)
    if self.m_passengersTag[passenger] then
        self:CheckPassengerOnWork(passenger)
        return
    end
    table.insert(self.m_passengers, passenger)
    self.m_passengersTag[passenger] = #self.m_passengers
end

function Bus:RmovePassenger(index)
    local passenger = table.remove(self.m_passengers, index or 1)
    if passenger then
        self.m_passengersTag[passenger] = nil
        return passenger
    end
end

function Bus:CheckPassengerOnWork(passenger)
    if not passenger:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) and passenger.m_state ~= passenger.StateInBus then
        for i, v in ipairs(self.m_passengers or {}) do
            if v == passenger then
                self:RmovePassenger(i)
                if self:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) and #self.m_passengers == 0 then
                    self.nextPoint = 0
                end
                return
            end
        end
    end
end

function Bus:GetBusEntity()
    if busEntity then
        return busEntity
    end
    busEntity = self:CreateActor()
    busEntity:Init(GameObject.Find("Bus").gameObject, "Assets/Res/Prefabs/Timeline/BusAnimation_" .. FloorMode:GetCurrFloorId() .. ".prefab")
    return busEntity
end

function Bus:GetCarEntity(carId)
    if not carId or (carEntity and carEntity.m_carId == carId) then
        return carEntity
    end

    if carEntity then
        carEntity:Exit()
    end
    carEntity = self:CreateActor()
    --
    local bossCar = GameObject.Find("BossCar")
    local canFly = BuyCarManager:CanCarFly(carId)

    if not canFly then
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. FloorMode:GetCurrFloorId() .. "/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. FloorMode:GetCurrFloorId() .. "/Car")
    else
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. FloorMode:GetCurrFloorId() .. "_fly/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. FloorMode:GetCurrFloorId() .. "_fly/Car")
    end
    if carEntity.m_bossCome == nil then
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. FloorMode:GetCurrFloorId() .. "/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. FloorMode:GetCurrFloorId() .. "/Car")
    end

    for k,v in pairs(carEntity.m_bossCome or {}) do
        GameObject.Destroy(v.gameObject)
    end
    for k,v in pairs(carEntity.m_bossLeave or {}) do
        GameObject.Destroy(v.gameObject)
    end

    local pfbName = CfgMgr.config_car[carId].pfb
    carEntity:Init(carEntity.m_bossLeave.gameObject, "Assets/Res/Prefabs/Vehicles/" .. pfbName .. ".prefab")
    carEntity:AddFlag(ActorDefine.Flag.FLAG_CAR_BOSS)
    carEntity.m_carId = carId
    return carEntity
end

function Bus:ClearEntity()
    busEntity = nil
    carEntity = nil
end

function Bus:InitStates()
    -- loaidng
    local StateLoading = self:InitState(STATE_LOADING)
    function StateLoading:Enter(bus)
        bus:CreateGo()
    end

    function StateLoading:Update(bus, dt)
    end

    function StateLoading:Exit(bus)
    end
    function StateLoading:Event(bus, msg)
        if msg == bus.LOADING_COMPLETE then
            bus:SetState(bus.StateIdle)
        end
    end

    -- idle
    local StateIdle = self:InitState(STATE_IDLE)
    function StateIdle:Enter(bus)
        if not bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
            bus.m_playableDirector = bus.m_go:GetComponent("PlayableDirector")
            bus.m_go:SetActive(false)
        else
            local isWork = CompanyMode:CheckManagerRoomOnWork(true)
            if isWork then
                bus.m_bossLeave.localPosition = Vector3.zero
                UnityHelper.SetLocalRotation(bus.m_bossLeave, 0, 0, 0)
                UnityHelper.AddChildToParent(bus.m_bossLeave, bus.m_go.transform)
                bus.m_playableDirector = bus.m_bossLeave.parent.gameObject:GetComponent("PlayableDirector")
            end
            bus.m_bossCome.parent.gameObject:SetActive(false)
            bus.m_bossLeave.parent.gameObject:SetActive(isWork)
        end
    end

    function StateIdle:Update(bus, dt)
        if #bus.m_passengers > 0 then
            bus:SetState(bus.StateComing)
        end
    end

    function StateIdle:Exit(bus)
    end

    function StateIdle:Event(bus, msg, params)
        if msg == bus.EVENT_PERSON_IN then
            bus.StateArrived:PersonGetIn(params[1], params[2])
        end
    end

    -- coming
    local StateComing = self:InitState(STATE_COMING)
    function StateComing:Enter(bus)
        if bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
            local boss = bus.m_passengers[1]
            local bossComeRoot = bus.m_bossCome.parent.gameObject
            local bossLeaveRoot = bus.m_bossLeave.parent.gameObject
            -- bossComeRoot:SetActive(false)
            --bossLeaveRoot:SetActive(false)
            if boss:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
                -- bossLeaveRoot:SetActive(true)
                UnityHelper.AddChildToParent(bus.m_bossLeave, bus.m_go.transform)
                bus.m_playableDirector = bossLeaveRoot:GetComponent("PlayableDirector")
                StateComing:Event(bus, Bus.EVENT_BUS_ARRIVED)
            else
                bossComeRoot:SetActive(true)
                UnityHelper.AddChildToParent(bus.m_bossCome, bus.m_go.transform)
                bus.m_playableDirector = bossComeRoot:GetComponent("PlayableDirector")
                bus.m_playableDirector:Play()
                if bus:HasFlag(ActorDefine.Flag.FLAG_CAMERA_FOLLOW_CAR) then
                    FloorMode:GetScene():SetCameraFollowGo(bus.m_bossCome.gameObject)
                    bus:RemoveFlag(ActorDefine.Flag.FLAG_CAMERA_FOLLOW_CAR)
                    EventManager:RegEvent("EVENT_NEWCAR_COME", function(go)
                        FloorMode:GetScene():SetCameraFollowGo(nil)
                        EventManager:UnregEvent("EVENT_NEWCAR_COME")
                    end)
                end
            end
        else
            bus.m_go:SetActive(true)
            local anchor = UnityHelper.FindTheChild(bus.m_go, "GuideAnchor")
            if anchor then
                EventManager:DispatchEvent("Bus_come",anchor.gameObject)
            end
            if bus.m_playableDirector then
                bus.m_playableDirector:Play()
            end
        end
    end

    function StateComing:Update(bus, dt)
    end

    function StateComing:Exit(bus)
    end

    function StateComing:Event(bus, msg)
        if msg == Bus.EVENT_BUS_ARRIVED then
            bus:SetState(bus.StateArrived)
        end
    end

    -- arrived
    local StateArrived = self:InitState(STATE_ARRIVED)
    function StateArrived:Enter(bus)
        -- local blockGo = GameObject.Find(blockPos[npcType]).gameObject
        -- local box = blockGo:GetComponent("BoxCollider")
        -- if box then
        --     UnityHelper.RefreshAStarMap(box.bounds)
        -- end
        if bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then--boss的bus....
            if bus.m_bossCome then
                local box = bus.m_bossCome:GetComponentInChildren(typeof(BoxCollider))
                if box then
                    UnityHelper.RefreshAStarMap(box.bounds)
                end
            end
        else--真正的bus
            local root = UnityHelper.FindTheChild(bus.m_go, "Bus/SM_Veh_Bus_01/block")
            local box = root:GetComponent("BoxCollider")
            if box then
                UnityHelper.RefreshAStarMap(box.bounds)
            end
        end

        if bus.m_playableDirector then
            bus.m_playableDirector:Pause()
        end
        self.nextPoint = TimeManager:GetSocketTime() + CfgMgr.config_global.bus_interval_time
    end

    function StateArrived:Update(bus, dt)
        if TimeManager:GetSocketTime() > (self.nextPoint or 0) then
            local passenger = bus:RmovePassenger()
            if passenger then
                self.nextPoint = TimeManager:GetSocketTime() + CfgMgr.config_global.bus_interval_time
                local position = nil
                if bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
                    position = UIView:GetTrans(bus.m_go, "Position").position
                else
                    position = UIView:GetTrans(bus.m_go, "Bus/SM_Veh_Bus_01/Position").position
                end
                if passenger:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
                    if passenger.m_roomData and passenger.m_roomData.onSpecialBuilding then
                        self.nextPoint = 0
                    end
                    if not passenger.m_busPosition then
                        passenger:Event(ActorDefine.Event.EVENT_GET_IN_BUS, position)
                    end
                    if passenger.m_stateMachine then
                        if  passenger.m_stateMachine:IsState("EmployeeInBusState") or  passenger.m_stateMachine:IsState("PropertyInBusState") then
                            bus:AddPassenger(passenger)
                        end
                    elseif passenger.m_state and passenger.m_state ~= passenger.StateInBus then
                        bus:AddPassenger(passenger)
                    end
                else
                    passenger:Event(ActorDefine.Event.EVENT_GET_OFF_BUS, position)
                    if bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) and #bus.m_passengers == 0 then
                        self.nextPoint = TimeManager:GetSocketTime() - 8
                    end
                end
            elseif #bus.m_passengers == 0 and (TimeManager:GetSocketTime() - self.nextPoint) > CfgMgr.config_global.bus_wait_time then
                if bus:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
                    local isWork = CompanyMode:CheckManagerRoomOnWork(true)
                    bus:SetState(isWork and bus.StateIdle or bus.StateLeaving)
                else
                    bus:SetState(bus.StateLeaving)
                end
            end
        end
    end

    function StateArrived:Exit(bus)
        self.nextPoint = nil
    end

    function StateArrived:Event(bus, msg, params)
        if msg == bus.EVENT_PERSON_OUT then
            self:PersonGetOut(params[1], params[2])
        elseif msg == bus.EVENT_PERSON_IN then
            self:PersonGetIn(params[1], params[2])
        end
    end

    ---@param person PersonBase
    function StateArrived:PersonGetIn(person, personCount)
        for i,v in ipairs(self.parent.m_passengers or {}) do
            if v == person then
                self.parent:RmovePassenger(i)
                break
            end
        end
        if person.SetState then
            person:SetState(person.StateInBus)
        else
            if person.m_type == ActorDefine.ActorType.Employee then
                person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeInBusState)
            elseif person.m_type == ActorDefine.ActorType.PropertyWorker then
                person.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
            end
        end
        if self.parent:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) and #self.parent.m_passengers == 0 then
            self.nextPoint = 0
        end
    end

    function StateArrived:PersonGetOut(person, personCount)
    end

    -- leaving
    local StateLeaving = self:InitState(STATE_LEAVING)
    function StateLeaving:Enter(bus)
        if bus.m_playableDirector then
            bus.m_playableDirector:Play()
        end
    end

    function StateLeaving:Update(bus, dt)
    end

    function StateLeaving:Exit(bus)
    end

    function StateLeaving:Event(bus, msg, params)
        if msg == bus.EVENT_BUS_LEFT then
            bus:SetState(bus.StateIdle)
        elseif msg == bus.EVENT_PERSON_IN then
            bus.StateArrived:PersonGetIn(params[1], params[2])
        end
    end
end

EventManager:RegEvent("EVENT_BUS_ARRIVED", function(go)
    if busEntity and busEntity.m_go == go then
        local bus = Bus:GetBusEntity()
        bus:Event(bus.EVENT_BUS_ARRIVED)
    else
        local car = Bus:GetCarEntity()
        car:Event(car.EVENT_BUS_ARRIVED)
    end
end)
EventManager:RegEvent("EVENT_BUS_LEFT", function(go)
    if busEntity and busEntity.m_go == go then
        local bus = Bus:GetBusEntity()
        bus:Event(bus.EVENT_BUS_LEFT)
    else
        local car = Bus:GetCarEntity()
        car:Event(car.EVENT_BUS_LEFT)
    end
end)

return Bus