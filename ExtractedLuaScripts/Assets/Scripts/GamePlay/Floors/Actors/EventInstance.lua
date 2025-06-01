local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local GameResMgr = require("GameUtils.GameResManager")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local Event003UI = GameTableDefine.Event003UI
local CfgMgr = GameTableDefine.ConfigMgr
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local InstanceDataManager = GameTableDefine.InstanceDataManager

local UnityHelper = CS.Common.Utils.UnityHelper;
local Vector3 = CS.UnityEngine.Vector3;

local EventInstance = Class("EventInstance", Person)


EventInstance.m_type = "TYPE_INSTANCE"
EventInstance.m_category = 1001

local PERSON_ACTION = {
    IDLE = 1,
    IDLE2SIT = 2,
    WORK = 3,
    SIT2IDLE = 4,
    WALK = 5,
    RUN = 6,
    DANCE = 7,
    SIT = 8,
    POO = 9,

    REST1 = 10,
    REST2 = 11,
    REST3 = 12,
    REST4 = 13,
    REST5 = 14,
    REST6 = 15,
    REST7 = 16,

    DARTS1 = 17,
    DARTS2 = 18,

    GOLF1 = 19,
    GOLF2 = 20,
    WATCH = 21,
    GAMING = 22,

    DANCE1 = 23,
    DANCE2 = 24,
    DANCE3 = 25,
    DANCE4 = 26,

    OBSERVE = 27,
    SHOPPING = 28,
    DRINGK_KING = 29,

    REPAIR = 30,
}

function EventInstance:ctor()
    self.super.ctor(self)
end

function EventInstance:Init(rootGo, position, tragetPosition, eventId)
    self.super.Init(self, rootGo, nil, position, tragetPosition)
    self.m_tempGo = self.m_go
    self.m_eventId = eventId
    self.m_go.transform.localScale = Vector3(3,3,3)
end

function EventInstance:Update(dt)
    self.super.Update(self, dt)
end

function EventInstance:Exit()
    self.super.Exit(self)
end

function EventInstance:Event(msg)
    self.super.Event(self, msg)
end

function EventInstance:OverrideStates()
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Enter(person)
        person:SetState(person.StateIdle)
    end

    local StateIdle = self:OverrideState(self.StateIdle)
    function StateIdle:Enter(person)
        person.m_go:SetActive(false)
        person.m_go.transform.position = person.m_initPosition
        self.m_timer = 0
        local iaaCD = CfgMgr.config_global.instance_iaa_cd
        self.m_interval = math.random(iaaCD[1],iaaCD[2])
    end
    function StateIdle:Update(person, dt)  
        
        self.m_timer = self.m_timer + dt
        if self.m_timer >= self.m_interval then
            local iaaLimit = CfgMgr.config_global.instance_iaa_limit
            local eventData = InstanceDataManager:GetEventData()
            local now = GameTimeManager:GetCurrentServerTime(true)
            local curDay = GameTimeManager:GetTimeLengthDate(now).d
            if eventData.count < iaaLimit and curDay == eventData.day or curDay > eventData.day then
                person.m_pathTarget = person.m_targetPosition
                person:SetState(person.StateWalk)
                InstanceDataManager:AddEventTime()
            end
        end
    end
    function StateIdle:Exit(person)
        person.m_go:SetActive(true)
        self.m_timer = 0
        self.m_interval = 0
    end

    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Enter(person)
        self.m_finalTragetPosition = person.m_targetPosition 
        person:SetAnimator(PERSON_ACTION.WALK)
        self.m_speed = 6
        self:CalculatePath(person, function()
            person:SetState(person.StateWork)
        end)
    end
    function StateWalk:CalculatePath(person,cb)
        local path = person.m_aiPath
        if path and path:IsNull() then
            --删掉了GameObject,但是复用了Person
            if person.m_go:IsNull() then
                return
            else
                --printf("path is null but enter stateWalk");
                --CS.UnityEngine.Debug.LogWarning("path is null but enter stateWalk",person.m_go);
                path = nil
            end
        end
        if not path then
            path = UnityHelper.AddAStartComp(person.m_go)
            person.m_aiPath = path
        end
        path.m_targetReachedAction = function()
            if path == nil or path:IsNull() or path.remainingDistance > path.endReachedDistance then
                return
            end

            path.m_targetReachedAction = nil
            path.canMove = false

            if cb then cb() end
        end
        path.destination =  self.m_finalTragetPosition
        path.canMove = true
        path.maxSpeed = 6
        path.pickNextWaypointDist = 2
        path:SearchPath()
    end

    local StateWalkBack = self:OverrideState(self.StateWalkBack)
    function StateWalkBack:Enter(person)
        self.m_finalTragetPosition = person.m_initPosition
        self:CalculatePath(person, function()
            person:SetState(person.StateIdle)
        end)
        person:SetAnimator(PERSON_ACTION.WALK)

    end
    function StateWalkBack:CalculatePath(person,cb)
        local path = person.m_aiPath

        if path and path:IsNull() then
            --删掉了GameObject,但是复用了Person
            if person.m_go:IsNull() then
                --printf("path is null and gameObject is null but enter stateWalk");
                return
            else
                --printf("path is null but enter stateWalk");
                --CS.UnityEngine.Debug.LogWarning("path is null but enter stateWalk",person.m_go);
                path = nil
            end
        end

        if not path then
            path = UnityHelper.AddAStartComp(person.m_go)
            person.m_aiPath = path
        end

        path.m_targetReachedAction = function()
			if path == nil or path:IsNull() or path.remainingDistance > path.endReachedDistance then
                return
            end

            path.m_targetReachedAction = nil
            path.canMove = false
            
            if cb then cb() end
        end
        path.destination =  self.m_finalTragetPosition
        path.canMove = true
        path.maxSpeed = 6
        path.pickNextWaypointDist = 2
        path:SearchPath()

    end


    local StateWork = self:OverrideState(self.StateWork)
    function StateWork:Enter(person)
        -- 修改下次寻路的目的地
        person.m_pathTarget = person.m_initPosition
        person:SetAnimator(PERSON_ACTION.IDLE)
        -- 显示气泡
        person:InitFloatUIView(101)
        -- 弹出banner
        InstanceMainViewUI:SetEventIAAActive(true)
    end
    function StateWork:Exit(person)
        person:RemoveFloatUIView()
    end
end

function EventInstance:SetAnimator(action)
    local animator = self.m_go:GetComponent("Animator")-- UIView:GetComp(parent.m_go, "Animator")
    if animator then
        animator:SetInteger("Action", action)
    end
end


return EventInstance