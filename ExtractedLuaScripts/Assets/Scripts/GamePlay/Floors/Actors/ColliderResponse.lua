local ColliderResponse = {}
local EventManager = require("Framework.Event.Manager")
local InstanceAIBlackBoard = GameTableDefine.InstanceAIBlackBoard
local CycleInstanceAIBlackBoard = GameTableDefine.CycleInstanceAIBlackBoard
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local EVENT_STATE = {
    "EVENT_COLLISION_ENTER",
    "EVENT_COLLISION_EXIT",
    "EVENT_COLLISION_STAY",
    "EVENT_TRIGGER_ENTER",
    "EVENT_TRIGGER_EXIT",
    "EVENT_TRIGGER_STAY"
}

ColliderResponse.TYPE_OPEN_DOOR = 1
ColliderResponse.TYPE_GOTO_BUS = 2
ColliderResponse.TYPE_PORTAL = 3
ColliderResponse.TYPE_FLOOR_AREA = 4

ColliderResponse.TYPE_GOTO_TOILE = 30           --1073741824
ColliderResponse.TYPE_GOTO_REST = 31            --2147483648
ColliderResponse.TYPE_GOTO_MEETING = 32         --4294967296
ColliderResponse.TYPE_GOTO_ENTERTAINMENT = 33   --8589934592
ColliderResponse.TYPE_GOTO_GYM = 34             --17179869184
ColliderResponse.TYPE_INSTANCE_DINING_ROOM = 35
ColliderResponse.TYPE_INSTANCE_DORM = 36
local Elevator = require("CodeRefactoring.Interactions.Elevator")

function ColliderResponse:InitEventMgr()
    for i, v in ipairs(EVENT_STATE) do
        if not self[v] then
            self[v] = {["RESPONSE"] = {}, ["ACTIVEATOR"] = {}}
        end
    end
end

function ColliderResponse:Execute(event, responseGo, activatorGo, type, outRoom)
    local exeFunc = function(e, go, t)
        if e[t] and e[t][go] then
            e[t][go](responseGo, activatorGo, outRoom)
        elseif e[type] and e[type][go] then
            e[type][go](responseGo, activatorGo, outRoom)
        end
    end
    exeFunc(event.RESPONSE, responseGo, responseGo:GetInstanceID())
    exeFunc(event.ACTIVEATOR, activatorGo, responseGo:GetInstanceID())
end

function ColliderResponse:SetEvent(e, type, go, cb)
    if cb then
        if not e[type] then
            e[type] = {}
        end
        e[type][go] = cb
    end
end

function ColliderResponse:SetResponderCollisionEventOnEnter(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_ENTER.RESPONSE, type, go, cb)
end
function ColliderResponse:SetResponderCollisionEventOnExit(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_EXIT.RESPONSE, type, go, cb)
end
function ColliderResponse:SetResponderCollisionEventOnStay(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_STAY.RESPONSE, type, go, cb)
end
function ColliderResponse:SetActivatorCollisionEventOnEnter(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_ENTER.ACTIVEATOR, type, go, cb)
end
function ColliderResponse:SetActivatorCollisionEventOnExit(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_EXIT.ACTIVEATOR, type, go, cb)
end
function ColliderResponse:SetActivatorCollisionEventOnStay(type, go, cb)
    self:SetEvent(self.EVENT_COLLISION_STAY.ACTIVEATOR, type, go, cb)
end



function ColliderResponse:SetResponderTriggerEventOnEnter(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_ENTER.RESPONSE, type, go, cb)
end
function ColliderResponse:SetResponderTriggerEventOnExit(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_EXIT.RESPONSE, type, go, cb)
end
function ColliderResponse:SetResponderTriggerEventOnStay(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_STAY.RESPONSE, type, go, cb)
end
function ColliderResponse:SetActivatorTriggerEventOnEnter(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_ENTER.ACTIVEATOR, type, go, cb)
end
function ColliderResponse:SetActivatorTriggerEventOnExit(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_EXIT.ACTIVEATOR, type, go, cb)
end
function ColliderResponse:SetActivatorTriggerEventOnStay(type, go, cb)
    self:SetEvent(self.EVENT_TRIGGER_STAY.ACTIVEATOR, type, go, cb)
end



function ColliderResponse:OnCollisionEnter(responseGo, activatorGo, eventType)
    self:Execute(self.EVENT_COLLISION_ENTER, responseGo, activatorGo, eventType)
end
function ColliderResponse:OnCollisionExit(responseGo, activatorGo, eventType)
    self:Execute(self.EVENT_COLLISION_EXIT, responseGo, activatorGo, eventType)
end
function ColliderResponse:OnCollisionStay(responseGo, activatorGo, eventType)
    self:Execute(self.EVENT_COLLISION_STAY, responseGo, activatorGo, eventType)
end

function ColliderResponse:OnTriggerEnter(responseGo, activatorGo, eventType, outRoom)
    self:Execute(self.EVENT_TRIGGER_ENTER, responseGo, activatorGo, eventType, outRoom)
end
function ColliderResponse:OnTriggerExit(responseGo, activatorGo, eventType)
    self:Execute(self.EVENT_TRIGGER_EXIT, responseGo, activatorGo, eventType)
end
function ColliderResponse:OnTriggerStay(responseGo, activatorGo, eventType)
    self:Execute(self.EVENT_TRIGGER_STAY, responseGo, activatorGo, eventType)
end

function ColliderResponse:InitClliderResponse(component, eventType)
    local tag = 1 << eventType
    local InteractionsManager = require("CodeRefactoring.Interactions.InteractionsManager")
    if tag == ActorDefine.Flag.FLAG_EMPLOYEE_ON_REST or
            tag == ActorDefine.Flag.FLAG_EMPLOYEE_ON_TOILET or
            tag == ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING or
            tag == ActorDefine.Flag.FLAG_EMPLOYEE_ON_GYM or
            tag == ActorDefine.Flag.FLAG_EMPLOYEE_ON_ENTERTAINMENT
    then
        local interactions = InteractionsManager:CreateEntity(tag, component.m_roomObject:GetInstanceID())
        interactions:Init(component, tag, eventType)
    elseif tag == ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_EATING or
            tag == ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_SLEEPING then
        local interactions = InteractionsManager:CreateEntity(tag, component.m_roomObject:GetInstanceID())
        interactions:Init(component, tag, eventType)
        InstanceAIBlackBoard:RegisterCollider(component)
        CycleInstanceAIBlackBoard:RegisterCollider(component)
    end
    if tag == ActorDefine.Flag.FLAG_ELEVATOR then
        local elevator = Elevator.new()
        elevator:Init(component)
    end
end

EventManager:RegEvent("EVENT_COLLISION_ENTER", handler(ColliderResponse, ColliderResponse.OnCollisionEnter))
EventManager:RegEvent("EVENT_COLLISION_EXIT", handler(ColliderResponse, ColliderResponse.OnCollisionExit))
EventManager:RegEvent("EVENT_COLLISION_STAY", handler(ColliderResponse, ColliderResponse.OnCollisionStay))

EventManager:RegEvent("EVENT_TRIGGER_ENTER", handler(ColliderResponse, ColliderResponse.OnTriggerEnter))
EventManager:RegEvent("EVENT_TRIGGER_EXIT", handler(ColliderResponse, ColliderResponse.OnTriggerExit))
EventManager:RegEvent("EVENT_TRIGGER_STAY", handler(ColliderResponse, ColliderResponse.OnTriggerStay))

EventManager:RegEvent("EVENT_COLLISION_INIT", handler(ColliderResponse, ColliderResponse.InitClliderResponse))

ColliderResponse:InitEventMgr()

return ColliderResponse
