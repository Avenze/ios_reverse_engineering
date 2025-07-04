---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/9/19 11:04
---

local Class = require("Framework.Lua.Class")
local ActorBase = require("CodeRefactoring.Actor.ActorBase")
---@class BusNew:ActorBase
---@field super ActorBase
local BusNew = Class("BusNew",ActorBase)

local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local FloatUI = GameTableDefine.FloatUI ---@type FloatUI
local GameObject = CS.UnityEngine.GameObject
local FloorMode = GameTableDefine.FloorMode
local CfgMgr = GameTableDefine.ConfigMgr
local BuyCarManager = GameTableDefine.BuyCarManager
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local UnityHelper = CS.Common.Utils.UnityHelper
local ActorManager = require("CodeRefactoring.Actor.ActorManager")
local PersonStateMachine = require("CodeRefactoring.AI.StateMachines.PersonStateMachine")
--local LuaBehavior = CS.Framework.Lua.LuaBehavior

local busEntity = nil ---@type BusNew
local carEntity = nil ---@type BusNew

function BusNew:ctor(...)
    self:getSuper(BusNew).ctor(self,...)
    self.m_go = nil             ---@type UnityEngine.GameObject -对应的角色GO
    self.m_rootGo = nil         ---@type UnityEngine.GameObject -角色GO的Parent
    self.m_prefab = nil         ---@type string -角色Prefab的路径
    self.m_stateMachine = nil   ---@type PersonStateMachine
    self.m_waiting_passengers = {}      ---@type PersonBase[] ---等待车通知的乘客
    self.m_movingToBusCount = 0      ---@type number ---正在前往汽车途中的乘客数
    self.m_movingToBusPassengers = {}
    self.m_waiting_passengersTag = {}
    self.m_bossCome = nil       ---@type UnityEngine.Transform
    self.m_bossLeave = nil      ---@type UnityEngine.Transform
    self.m_playableDirector = nil ---@type UnityEngine.Playables.PlayableDirector
    self.m_flags = 0
    self.m_luaBehavior = nil ---@type Framework.Lua.LuaBehavior
    self.m_busStationTrans = nil ---@type UnityEngine.Transform
    self.m_type = ActorDefine.ActorType.Bus
end

--function BusNew:DefineFlag(flag)
--    return 1 << flag
--end

function BusNew:HasFlag(flag)
    return (self.m_flags & (flag)) ~= 0
end

function BusNew:AddFlag(flag)
    self.m_flags = self.m_flags | flag
    self:Event(ActorDefine.Event.EVENT_ADD_FLAG, flag)
end

function BusNew:RemoveFlag(flag)
    self.m_flags = self.m_flags & ~flag
    self:Event(ActorDefine.Event.EVENT_REMOVE_FLAG, flag)
end

function BusNew:Init(rootGo, prefab)
    self.m_rootGo = rootGo
    self.m_prefab = prefab
    self.m_movingToBusCount = 0

    if not self.m_stateMachine then
        self.m_stateMachine = PersonStateMachine.create()
        self.m_stateMachine:SetOwner(self)
        self:AddAI(self.m_stateMachine)
    end

    self:LoadGameObject()
end

---加载GameObject
function BusNew:LoadGameObject()
    if self.m_go and not self.m_go:IsNull() then
        self:OnLoadedGO(self.m_go)
    elseif self.m_prefab then
        GameResMgr:AInstantiateObjectAsyncManual(self.m_prefab, self, handler(self,self.OnLoadedGO))
    else
        self:Destroy()
    end
end

---加载GameObject完毕
function BusNew:OnLoadedGO(go)
    self.m_go = go
    self.m_luaBehavior = UnityHelper.GetOrAddLuaBehavior(self.m_go)
    self.m_luaBehavior:SetOnDestroyEvent(handler(self,self.OnDestroy))
    if self.m_rootGo and not self.m_rootGo:IsNull() then
        UnityHelper.AddChildToParent(self.m_rootGo.transform, go.transform)

        --优化Animator性能
        --local animator = go:GetComponent("Animator")
        --if not animator:IsNull() and not animator.applyRootMotion then
        --    animator.cullingMode = CS.UnityEngine.AnimatorCullingMode.CullUpdateTransforms
        --end
        self:getSuper(BusNew).Init(self,nil,self.m_go,{},self.m_stateMachine)

        --初始化GO的挂载
        self:OnLoadGOSuccess()
    else
        self:Destroy()
    end
end

function BusNew:OnLoadGOSuccess()

    if self:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
        self.m_busStationTrans = UIView:GetTrans(self.m_go, "Position")

        EventManager:RegEvent(GameEventDefine.ChangeBossCar,function(carId)
            self:ChangeCarPrefab(carId)
        end)
    else
        self.m_busStationTrans = UIView:GetTrans(self.m_go, "Bus/SM_Veh_Bus_01/Position")
    end

    self.m_stateMachine:ChangeState(ActorDefine.State.BusIdleState)
end


function BusNew:ChangeCarPrefab(carId)

    --if carId == nil then
    --    self:Destroy()
    --    return
    --end
    --
    --if self.m_luaBehavior then
    --    self.m_luaBehavior:ClearOnDestroyEvent()
    --    self.m_luaBehavior = nil
    --end
    --if self.m_go and not self.m_go:IsNull() then
    --    UnityHelper.DestroyGameObject(self.m_go)
    --end
    --self.m_go = nil
    --
    --local pfbName = CfgMgr.config_car[carId].pfb
    --self.m_prefab = "Assets/Res/Prefabs/Vehicles/" .. pfbName .. ".prefab"
    --GameResMgr:AInstantiateObjectAsyncManual(self.m_prefab, self, function(go)
    --    self.m_go = go
    --    self.m_luaBehavior = UnityHelper.GetOrAddLuaBehavior(self.m_go)
    --    self.m_luaBehavior:SetOnDestroyEvent(handler(self,self.OnDestroy))
    --    if self.m_rootGo and not self.m_rootGo:IsNull() then
    --        UnityHelper.AddChildToParent(self.m_rootGo.transform, go.transform)
    --        if self:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
    --            self.m_busStationTrans = UIView:GetTrans(self.m_go, "Position")
    --        else
    --            self.m_busStationTrans = UIView:GetTrans(self.m_go, "Bus/SM_Veh_Bus_01/Position")
    --        end
    --        self.m_carId = carId
    --    else
    --        self:Destroy()
    --    end
    --end)
end

---将Actor标记为WASTE,这样Table可以重复利用,相当于放入对象池
function BusNew:Destroy()
    self:Exit()
end

function BusNew:Exit()
    --if self.m_state and self.m_state.ClearAnimator then
    --    self.m_state:ClearAnimator()
    --end
    if self.m_go and not self.m_go:IsNull() then
        UnityHelper.DestroyGameObject(self.m_go)
        GameResMgr:Unload(self)
    else
        self.m_isPooling = true
        self.m_go = nil
        self.m_flags = 0
        self.m_busStationTrans = nil
    end
end

function BusNew:OnDestroy()
    if self:HasFlag(ActorDefine.Flag.FLAG_CAR_BOSS) then
        EventManager:UnregEvent(GameEventDefine.ChangeBossCar)
    end
    if not self.m_luaBehavior or self.m_luaBehavior:IsNull() then --不明原因一加载出来就删除了
        return
    end
    --printf("BusNew:OnDestroy()")
    self.m_isPooling = true
    if self.m_stateMachine then
        self.m_stateMachine:OnDestroy()
    end
    self.m_luaBehavior:ClearOnDestroyEvent()

    self.gameObject = nil
    self.m_go = nil
    self.m_rootGo = nil
    self.m_prefab = nil
    self.m_waiting_passengers = {}
    self.m_movingToBusCount = 0
    self.m_movingToBusPassengers = {}
    self.m_waiting_passengersTag = {}
    self.m_bossCome = nil
    self.m_bossLeave = nil
    self.m_playableDirector = nil
    self.m_flags = 0
    self.m_luaBehavior = nil
    self.m_busStationTrans = nil
    if busEntity == self then
        busEntity = nil
    elseif carEntity == self then
        carEntity = nil
    end
end

function BusNew:Event(msg, params)
    if self.m_stateMachine then
        self.m_stateMachine:Event(msg, params)
    end
    --if msg == ActorDefine.Event.EVENT_NEW_PASSENGER then
    --    self:AddWaitingPassenger(params)
    --end
end

---@return BusNew
function BusNew:CreateActor()
    return ActorManager:CreateActorSync(self)
end

function BusNew:InitFloatUIView()
    ---@param view FloatUIView
    FloatUI:SetObjectCrossCamera(self, function(view)
        if view then
            view:Invoke("ShowEventBumble")
        end
    end)
end

function BusNew:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self)
end

---乘客走向汽车
function BusNew:PassengerMoveToBus(passenger)
    self.m_movingToBusCount = self.m_movingToBusCount + 1
    self.m_movingToBusPassengers[passenger] = passenger
end

---乘客停止走向汽车
function BusNew:PassengerUnMoveToBus(passenger)
    self.m_movingToBusCount = self.m_movingToBusCount - 1
    self.m_movingToBusPassengers[passenger] = nil
end

---注册为等待乘车的乘客，等待Bus通知它上车。
function BusNew:AddWaitingPassenger(passenger)
    if self.m_waiting_passengersTag[passenger] then
        --如果乘客已经在列表中，检查是否不是下班状态，不是的话就不用上车了，省略上车再立刻下车的过程。
        self:CheckPassengerOnWork(passenger)
        return
    end
    table.insert(self.m_waiting_passengers, passenger)
    self.m_waiting_passengersTag[passenger] = #self.m_waiting_passengers
end

---将乘客从等待列表中移除
---@return PersonBase
function BusNew:RemoveWaitingPassenger(index)
    local passenger = table.remove(self.m_waiting_passengers, index or 1)
    if passenger then
        self.m_waiting_passengersTag[passenger] = nil
        return passenger
    end
end

---@param passenger PersonBase
---
function BusNew:CheckPassengerOnWork(passenger)
    if not passenger:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) and
            not passenger.m_stateMachine:IsState("PropertyInBusState") and
            not passenger.m_stateMachine:IsState("EmployeeInBusState")
    then
        for i, v in ipairs(self.m_waiting_passengers) do
            if v == passenger then
                self:RemoveWaitingPassenger(i)
                return
            end
        end
    end
end

---@param person PersonBase
function BusNew:PersonGetIn(person, personCount)
    for i,v in ipairs(self.m_waiting_passengers or {}) do
        if v == person then
            --乘客上车后，从乘客等待表中移除
            self:RemoveWaitingPassenger(i)
            break
        end
    end
    if person.m_type == ActorDefine.ActorType.Employee then
        person.m_stateMachine:ChangeState(ActorDefine.State.EmployeeInBusState)
    elseif person.m_type == ActorDefine.ActorType.PropertyWorker then
        person.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
    elseif person.m_type == ActorDefine.ActorType.CEOActor then
        person.m_stateMachine:ChangeState(ActorDefine.State.CEOInBusState)
    end
end

function BusNew:GetBusEntity()
    if busEntity then
        return busEntity
    end
    busEntity = self:CreateActor()
    busEntity:Init(GameObject.Find("Bus").gameObject, "Assets/Res/Prefabs/Timeline/BusAnimation_" .. FloorMode:GetCurrFloorId() .. ".prefab")
    return busEntity
end

function BusNew:DestroyCarEntity()
    if carEntity then
        --删掉车时如果BOSS正在赶往car，那让BOSS直接变成InCarState,防止BOSS上不了车的错误
        local bossActor
        if carEntity.m_waiting_passengers and #carEntity.m_waiting_passengers>0 then
            bossActor = carEntity.m_waiting_passengers[1]
        elseif carEntity.m_movingToBusCount > 0 then
            bossActor = next(carEntity.m_movingToBusPassengers)
        end
        if bossActor and bossActor.m_stateMachine:IsState(ActorDefine.State.PropertyOffWorkState) then
            bossActor.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
        end
        carEntity:Exit()
        carEntity = nil
    end
end

function BusNew:GetCarEntity(carId)
    if not carId or (carEntity and carEntity.m_carId == carId) then
        return carEntity
    end

    if carEntity then
        --删掉车时如果BOSS正在赶往car，那让BOSS直接变成InCarState,防止BOSS上不了车的错误
        local bossActor
        if carEntity.m_waiting_passengers and #carEntity.m_waiting_passengers>0 then
            bossActor = carEntity.m_waiting_passengers[1]
        elseif carEntity.m_movingToBusCount > 0 then
            bossActor = next(carEntity.m_movingToBusPassengers)
        end
        if bossActor and bossActor.m_stateMachine:IsState(ActorDefine.State.PropertyOffWorkState) then
            bossActor.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
        end
        carEntity:Exit()
    end
    carEntity = self:CreateActor()
    --
    local bossCar = GameObject.Find("BossCar")
    local canFly = BuyCarManager:CanCarFly(carId)
    local floorId = FloorMode:GetCurrFloorId()

    if not canFly then
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. floorId .. "/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. floorId .. "/Car")
    else
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. floorId .. "_fly/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. floorId .. "_fly/Car")
    end
    if carEntity.m_bossCome == nil then
        carEntity.m_bossCome = UIView:GetTrans(bossCar, "BossCarCome_" .. floorId .. "/Car")
        carEntity.m_bossLeave = UIView:GetTrans(bossCar, "BossCarLeave_" .. floorId .. "/Car")
    end

    carEntity.m_bossCome.parent.gameObject:SetActive(false)
    carEntity.m_bossLeave.parent.gameObject:SetActive(false)

    for k,v in pairs(carEntity.m_bossCome or {}) do
        GameObject.Destroy(v.gameObject)
    end
    for k,v in pairs(carEntity.m_bossLeave or {}) do
        GameObject.Destroy(v.gameObject)
    end

    local pfbName = CfgMgr.config_car[carId].pfb
    carEntity:AddFlag(ActorDefine.Flag.FLAG_CAR_BOSS)
    carEntity:Init(carEntity.m_bossLeave.gameObject, "Assets/Res/Prefabs/Vehicles/" .. pfbName .. ".prefab")
    carEntity.m_carId = carId
    return carEntity
end

function BusNew:ClearEntity()
    busEntity = nil
    carEntity = nil
end

--由Timeline发出
EventManager:RegEvent("EVENT_BUS_ARRIVED", function(go)
    if busEntity and busEntity.m_go == go then
        local bus = BusNew:GetBusEntity()
        bus:Event(ActorDefine.Event.EVENT_BUS_ARRIVED)
        --printf("汽车到达，pos = "..tostring(bus.m_go.transform.position).." time="..bus.m_playableDirector.time)
    else
        local car = BusNew:GetCarEntity()
        car:Event(ActorDefine.Event.EVENT_BUS_ARRIVED)
    end
end)

EventManager:RegEvent("EVENT_BUS_LEFT", function(go)
    if busEntity and busEntity.m_go == go then
        local bus = BusNew:GetBusEntity()
        bus:Event(ActorDefine.Event.EVENT_BUS_LEFT)
    else
        local car = BusNew:GetCarEntity()
        --car有可能这时被卖掉，获取不到了
        if car then
            car:Event(ActorDefine.Event.EVENT_BUS_LEFT)
        end
    end
end)

return BusNew