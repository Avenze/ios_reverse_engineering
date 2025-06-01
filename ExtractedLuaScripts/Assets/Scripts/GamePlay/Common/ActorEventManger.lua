local ActorEventManger = GameTableDefine.ActorEventManger
local CfgMgr = GameTableDefine.ConfigMgr
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local GameClockManager = GameTableDefine.GameClockManager
local GameUIManager = GameTableDefine.GameUIManager
local Event003UI = GameTableDefine.Event003UI
local CountryMode = GameTableDefine.CountryMode

local EVENT_SAVE = "event_save"

local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local EventSponsor = require "CodeRefactoring.Actor.Actors.EventSponsorNew"
local EventDiamonder = require "CodeRefactoring.Actor.Actors.EventDiamonderNew"
local EventBatman = require "CodeRefactoring.Actor.Actors.EventBatmanNew"

local lcoalData = nil
local scene = nil

local timer = nil

--用于生成特殊npc

local npcHolder = {}--1土豪 100跳过黑夜 2钻石 3圣诞老人 4经验

local interval = 0

local TimerMgr = GameTimeManager

function ActorEventManger:Init()
    scene = FloorMode:GetScene()
    interval = 16 * 1000
    self.lastUpdateTime = 0
    self.lastNpcCreate = nil
end

function ActorEventManger:Update()
    if not interval or interval == 0 then
        return
    end

    local curTime = TimerMgr:GetDeviceTimeInMilliSec()
    if curTime - self.lastUpdateTime >= interval then
        self.lastUpdateTime = curTime
        self:CheckEvent()
    end
end

function ActorEventManger:Exit()
    for k,v in pairs(npcHolder) do
        v:Exit()
    end
    npcHolder = {}

    interval = 0
    self.lastUpdateTime = 0
end

function ActorEventManger:CheckEventOnActivity(id)
    for k,v in pairs(self:GetLocalDate() or {}) do
        if v.id == id then
            return v.state == 1, v
        end
    end
    return false
end

function ActorEventManger:ActiveEventByChat(id)
    local isActive,cfg = self:CheckEventOnActivity(id)
    if isActive then
        return
    end
    cfg.next_trigger = 0
    cfg.count =  cfg.count - 1
end

function ActorEventManger:GetLocalDate()
    if lcoalData then
        return lcoalData
    end

    lcoalData = LocalDataManager:GetDataByKey("game_event")
    local curDate = DiamondRewardUI:GetDate()
    for k,v in pairs(CfgMgr.config_event or {}) do
        if not lcoalData[k] or lcoalData[k].date ~= curDate then
            lcoalData[k] = {}
            lcoalData[k].id = v.id
            lcoalData[k].count = 0
            lcoalData[k].date = curDate
            lcoalData[k].state = 0 -- 0结束，1是正在进行
            lcoalData[k].next_trigger = math.random(v.event_interval[1], v.event_interval[2]) + GameTimeManager:GetCurrentServerTime()
        end
    end
    return lcoalData
end

function ActorEventManger:CheckEvent()
    local currScene = LocalDataManager:GetDataByKey(CountryMode.city_record_data).currBuidlingId
    local currTime = GameTimeManager:GetCurrentServerTime(true)
    local data = self:GetLocalDate()
    local checkSceneOnArea = FloorMode:CheckSceneOnArea()
    for k,v in pairs( data or {}) do
        local cfg = CfgMgr.config_event[v.id]
        if cfg and cfg.event_scene[currScene] then--符合场景
            if v.next_trigger <= currTime and v.count < cfg.event_limit and not self.stopCreateNpc and checkSceneOnArea then--时间,次数满足
                self:ActiveEvent(v)
                v.state = 1
            end 
        end
    end
end

function ActorEventManger:stopCreate(stop)
    self.stopCreateNpc = stop
end

function ActorEventManger:ActiveEvent(data)
    -- 激活事件
    -- 事件基本上都是由两个部分构成:通过timeline管理的汽车模型, 通过ai管理的人物
    -- 这个方法本质就是通过路径,找到对应的directorPath,那是一个prefab,包含一个timeline以及汽车模型
    -- 播放timeline就是开车过来,到达后,timeline有设置事件比如EVENT_CAR_ARRIVED的事件,游戏就会暂停timeline
    
    -- if sponsor and not sponsor:IsValid() then--为什么要加这个
    --     sponsor = nil
    -- end

    -- if self.stopCreateNpc then
    --     return
    -- end

    if data.id == 3 and not GameConfig:IsChristmas() then--圣诞老人
        return
    end

    local directorName = {}--self.playableDirector, self.skipNightDirector...这样的方式存储
    directorName[1] = "playableDirector"
    directorName[2] = "diamondDirector"
    directorName[100] = "skipNightDirector"
    directorName[3] = "christmasDirector"
    directorName[4] = "expDirector"
    directorName[5] = "playableDirector5"

    local directorPath = {}
    local floorId = FloorMode:GetCurrFloorId() or "101"
    directorPath[1] = "Assets/Res/Prefabs/Timeline/CarAnimation1_" .. floorId ..".prefab"
    directorPath[2] = "Assets/Res/Prefabs/Timeline/CarAnimation2_" .. floorId ..".prefab"
    directorPath[100] = "Assets/Res/Prefabs/Timeline/BatAnimation.prefab"
    directorPath[3] = "Assets/Res/Prefabs/Timeline/SledAnimation.prefab"
    directorPath[4] = "Assets/Res/Prefabs/Timeline/CarAnimation3_" .. floorId .. ".prefab"
    directorPath[5] = "Assets/Res/Prefabs/Timeline/CarAnimation5_" .. floorId ..".prefab"

    local parentName = {}
    parentName[1] = "CarEvent"
    parentName[2] = "CarEvent2"
    parentName[100] = "BatEvent"
    parentName[3] = "ChristmasEvent"
    parentName[4] = "CarEvent3"
    parentName[5] = "CarEvent"

    local objName = {}
    objName[1] = "CarAnimationGo"
    objName[2] = "DiamondAnimationGo"
    objName[100] = "BatAnimation"
    objName[3] = "SledAnimation"
    objName[4] = "ExpAnimationGo"
    objName[5] = "CarAnimationGo5"

    local playDirector = function(npcType)
        local direName = directorName[npcType]
        local director = self[direName]
        if director and not director:IsNull() then
            director.gameObject:SetActive(true)
            director:Play()
            return
        end

        GameResMgr:AInstantiateObjectAsyncManual(directorPath[npcType], scene, function(go)
            if go then
                go.name = objName[npcType]
                --2022-12-9用于timeline整合装扮的功能修改添加
                GameTableDefine.DressUpDataManager:ChangeTimelineActorDressUp(go)
                local parent = GameObject.Find(parentName[npcType])
                if parent then
                    UnityHelper.AddChildToParent(parent.transform, go.transform)
                    self[direName] = go:GetComponent("PlayableDirector")
                    if self[direName] then
                        self[direName]:Play()
                    end
                end
            end
        end)
    end

    if not npcHolder[data.id] then
        playDirector(data.id)
    end
end

function ActorEventManger:IsBatmanCome()
    if self.skipNightDirector and not self.skipNightDirector:IsNull() then
        return self.skipNightDirector.gameObject.activeSelf
    end

    return false
end

function ActorEventManger:FinishEvent(cfg)
    local data = self:GetLocalDate()[cfg.id]
    if data then
        local random = math.random(cfg.event_interval[1], cfg.event_interval[2])
        data.next_trigger = random + TimerMgr:GetCurrentServerTime(true)
        data.state = 0
        data.count = data.count + 1
        LocalDataManager:WriteToFile()
    end

    if npcHolder[cfg.id] then
        npcHolder[cfg.id]:Event(npcHolder[cfg.id].EVENT_LEAVE_SCENE)
        npcHolder[cfg.id] = nil
    end
end

function ActorEventManger:EventFinishTimes(eventId)
    local data = LocalDataManager:GetDataByKey(EVENT_SAVE)
    return data["event"..eventId] or 0 
end

function ActorEventManger:BatmanCastSpell()
    if npcHolder[100] then
        npcHolder[100]:Event(npcHolder[100].EVENT_CAST_SPELL)
        npcHolder[100] = nil
    end
end

function ActorEventManger:CreateActor()
    if not self.lastNpcCreate then
        return
    end

    if npcHolder[self.lastNpcCreate] then
        return
    end

    if self.lastNpcCreate == 100 then
        local needBatMan = GameClockManager:ChangeBatMan()
        if not needBatMan then--如果已经过了黑夜,直接走
            return
        end
    end

    self:CreateNPC(self.lastNpcCreate)
end

function ActorEventManger:ActorCompleted()
    if not self.lastNpcLeave then
        return
    end

    self:NPCLeaveComplere(self.lastNpcLeave)
end

function ActorEventManger:CreateNPC(npcType)
    --不同的数据
    --人物实际上也是一个个ai,所有ai都包含在npcCreater中
    

    local parentName = {}
    parentName[1] ="EventPos/Event001"
    parentName[2] = "EventPos/Event002"
    parentName[100] = "EventPos/Event100"
    parentName[3] = "EventPos/Event003"
    parentName[4] = "EventPos/Event004"
    parentName[5] = "EventPos/Event001"

    local createPos = {}
    createPos[1] = "CarEvent/CarAnimationGo/SM_Veh_Car_Muscle_01/Position"
    createPos[2] = "CarEvent2/DiamondAnimationGo/LanSeChe/Position"
    createPos[100] ="BatEvent/BatAnimation/SM_Veh_EscapePod_Large_01/Position"
    createPos[3] = "ChristmasEvent/SledAnimation/SnowSled/Position"
    createPos[4] = "CarEvent3/ExpAnimationGo/LanSeChe/Position"
    createPos[5] = "CarEvent/CarAnimationGo5/SM_Veh_Car_Muscle_01/Position"

    local blockPos = {}
    blockPos[1] = "CarEvent/CarAnimationGo/SM_Veh_Car_Muscle_01/block"
    blockPos[2] = "CarEvent2/DiamondAnimationGo/LanSeChe/block"
    blockPos[100] = "BatEvent/BatAnimation/SM_Veh_EscapePod_Large_01/block"
    blockPos[3] = "CarEvent3/ExpAnimationGo/LanSeChe/block"
    blockPos[5] = "CarEvent/CarAnimationGo5/SM_Veh_Car_Muscle_01/block"

    local npcCfg = function(npcType)
        if npcType == 100 then
            return {NPC_dst = "Event003_NPC_DstPos", NPC_prefab = "Event003_NPC_prefab"}
        end
        return CfgMgr.config_event[npcType]
    end

    local npcCreater = {}
    npcCreater[1] = EventSponsor
    npcCreater[2] = EventDiamonder
    npcCreater[100] = EventBatman
    npcCreater[3] = EventDiamonder
    npcCreater[4] = EventDiamonder
    npcCreater[5] = EventSponsor

    local directorHolder = {}
    directorHolder[1] = self.playableDirector
    directorHolder[2] = self.diamondDirector
    directorHolder[100] = self.skipNightDirector
    directorHolder[3] = self.christmasDirector
    directorHolder[4] = self.expDirector
    directorHolder[5] = self.playableDirector5
    local cfg = npcCfg(npcType)
    --共同的操作
    local eventRoot = GameObject.Find(parentName[npcType])
    if not eventRoot or eventRoot:IsNull() then
        print("找不到Event节点,请检查一下场景,"..parentName[npcType])
        return
    end
    eventRoot = eventRoot.gameObject

    if not scene then
        scene = FloorMode:GetScene()
    end
    
    
    local posGoal = GameObject.Find(createPos[npcType])
    if not posGoal or posGoal:IsNull() then
        error("找不到NPC出生点，无法生成NPC,请检查一下资源,"..createPos[npcType])
        return
    end
    local spawnTrans = posGoal.transform--出现点
    local dstTrans = scene:GetTrans(eventRoot, cfg.NPC_dst)--终点

    if blockPos[npcType] then
        local blockGo = GameObject.Find(blockPos[npcType]).gameObject
        local box = blockGo:GetComponent("BoxCollider")
        if box then
            UnityHelper.RefreshAStarMap(box.bounds)
        end
    end

    npcHolder[npcType] = npcCreater[npcType]:CreateActor()
    npcHolder[npcType]:Init(eventRoot, scene:GetGo(eventRoot, cfg.NPC_prefab), spawnTrans.position, dstTrans.position, npcType)
    if directorHolder[npcType] then
        directorHolder[npcType]:Pause()
    end
end

function ActorEventManger:NPCLeave(npcType)
    local directorHolder = {}
    directorHolder[1] = self.playableDirector
    directorHolder[2] = self.diamondDirector
    directorHolder[100] = self.skipNightDirector
    directorHolder[3] = self.christmasDirector
    directorHolder[4] = self.expDirector
    directorHolder[5] = self.playableDirector5

    if directorHolder[npcType] then
        directorHolder[npcType]:Play()
    end
end

function ActorEventManger:NPCLeaveComplere(npcType)
    local directorHolder = {}
    directorHolder[1] = self.playableDirector
    directorHolder[2] = self.diamondDirector
    directorHolder[100] = self.skipNightDirector
    directorHolder[3] = self.christmasDirector
    directorHolder[4] = self.expDirector
    directorHolder[5] = self.playableDirector5

    if directorHolder[npcType] and directorHolder[npcType].gameObject then
        directorHolder[npcType].gameObject:SetActive(false)
    end
end

EventManager:RegEvent("EVENT_CAR_ARRIVED", function()
    ActorEventManger.lastNpcCreate = 1
    ActorEventManger:CreateActor()
end)
EventManager:RegEvent("EVENT_CAR_LEFT", function()
    ActorEventManger.lastNpcLeave = 1
    ActorEventManger:ActorCompleted()
end)


EventManager:RegEvent("EVENT_CAR2_ARRIVED", function()
    ActorEventManger.lastNpcCreate = 2
    ActorEventManger:CreateActor()
end)
EventManager:RegEvent("EVENT_CAR2_LEFT", function()
    ActorEventManger.lastNpcLeave = 2
    ActorEventManger:ActorCompleted()
end)

EventManager:RegEvent("EVENT_CAR3_ARRIVED", function()
    ActorEventManger.lastNpcCreate = 4
    ActorEventManger:CreateActor()
end)
EventManager:RegEvent("EVENT_CAR3_LEFT", function()
    ActorEventManger.lastNpcLeave = 4
    ActorEventManger:ActorCompleted()
end)

EventManager:RegEvent("EVENT_BAT_ARRIVED", function()
    ActorEventManger.lastNpcCreate = 100
    ActorEventManger:CreateActor()
end) 
EventManager:RegEvent("EVENT_BAT_LEFT", function()
    ActorEventManger.lastNpcLeave = 100
    ActorEventManger:ActorCompleted()
end)

EventManager:RegEvent("BATMAN_COME", function()
    ActorEventManger:ActiveEvent({id = 100})
end)

EventManager:RegEvent("EVENT_CAR5_LEFT", function()
    ActorEventManger.lastNpcLeave = 5
    ActorEventManger:ActorCompleted()
end)
EventManager:RegEvent("EVENT_CAR5_ARRIVED", function()
    ActorEventManger.lastNpcCreate = 5
    ActorEventManger:CreateActor()
end)

EventManager:RegEvent("BATMAN_LEAVE", function()--蝙蝠侠该走了
    if GameStateManager:IsInFloor() then
        if npcHolder[100] then
            npcHolder[100]:Event(npcHolder[100].EVENT_LEAVE_SCENE)
            npcHolder[100] = nil
        end
    end
    if GameUIManager:IsUIOpen(32) then
        Event003UI:GetView():DestroyModeUIObject()
    end
end)

EventManager:RegEvent("CHRISTMAS_MAN_COME", function()
    ActorEventManger.lastNpcCreate = 3
    ActorEventManger:CreateActor()
end)

EventManager:RegEvent("CHRISTMAS_MAN_LEAVE", function()
    ActorEventManger.lastNpcLeave = 3
    ActorEventManger:ActorCompleted()
end)