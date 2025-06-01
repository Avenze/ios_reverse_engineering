--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-07 17:56:01
    description:副本工人类
]]
local Class = require("Framework.Lua.Class")
local ActorBase = require("CodeRefactoring.Actor.ActorBase")
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FloatUI = GameTableDefine.FloatUI
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local PersonStateMachine = require("CodeRefactoring.AI.StateMachines.PersonStateMachine")
local Animator = CS.UnityEngine.Animator
local Vector3 = CS.UnityEngine.Vector3
local FloorMode = GameTableDefine.FloorMode
local AnimationUtil = CS.Common.Utils.AnimationUtil
local ColliderResponse = require("GamePlay.Floors.Actors.ColliderResponse")

---@class InstanceWorkerClass:ActorBase
---@field super ActorBase
local InstanceWorkerClass = Class("InstanceWorkerClass", ActorBase)

function InstanceWorkerClass:ctor(...)
    self.super:ctor()
    self.initialized = false
    self.data = setmetatable(
            { 
                buildID = 0, --所属建筑ID
                roomID = 0, --所属房间ID
                furnitureID = 0, --所属家具ID
                furnitureIndex = 0, --所属家具位置索引
            },
            {
                __index = function(myTable,key)
                    error(self.instanceID.."  "..self.__cname .. ".data中找不到[ " .. key .. " ]属性")
                    return nil
                end
            }
    )
    local data = select(1, ...)
    self:SetData(data)
    self.m_type = ActorDefine.ActorType.InstanceWorker
    self.m_go = nil
end

function InstanceWorkerClass:Init(id, go, actorData, pos, rot,isBuy)
    self.m_animator = go:GetComponent(typeof(Animator))

    if not self.m_stateMachine then
        self.m_stateMachine = PersonStateMachine.create()   ---@type PersonStateMachine
        self.m_stateMachine:SetOwner(self)
        self:AddAI(self.m_stateMachine)
        self:TryTransState(function ()
            self.m_stateMachine:ChangeState(ActorDefine.State.InstanceWorkerInit, self,isBuy)
        end)
    end
    self.super.Init(self, id, go, actorData, self.m_stateMachine, pos, rot)
    self.data.type = "InstanceWorker"
    self.m_go = go
    self.initialized = true
    self:SetDoorTrigger()
    print("创建 InstanceWorker", id)
end


function InstanceWorkerClass.InitAI(InstanceWorker, roomGo, furnitureGo, spawnPos, workPosTr, facePosTr, actionPosTr, faceTr)
    if not InstanceWorker.aiStateMachine then
        return
    end
    InstanceWorker.aiStateMachine:Init(roomGo, furnitureGo, spawnPos, workPosTr, facePosTr, actionPosTr, faceTr)
end


function InstanceWorkerClass.OnUpdate(InstanceWorker, dt) -- dt为毫秒
    InstanceWorker.super:OnUpdate(dt)
    InstanceWorker.UpdataData(InstanceWorker)
end


--设置气泡的显示
function InstanceWorkerClass:SetTheDisplayOfBubbles(typeB, interactiveRoomId)
    local workerAttr = InstanceModel:GetWorkerAttr(self.data.roomID, self.data.furnitureIndex)
    local state =
    {
        interactiveRoomId = interactiveRoomId,
        roomId = self.data.roomID,
        index = self.data.furnitureIndex,
        workProgress = 0,
        hungry = workerAttr.hungry,
        physical = workerAttr.physical,
        productionID = InstanceDataManager.config_rooms_instance[self.data.roomID].production
    }
    local speed
    if typeB == "product" then
        local roomCfg = InstanceDataManager.config_rooms_instance[state.roomId]
        local allReduce = InstanceModel:GetRoomCDReduce(state.roomId)
        local cd = roomCfg.bastCD - allReduce
        speed = 1 / cd
    elseif typeB == "eat" then
        speed = InstanceModel:GetRoomHunger(state.interactiveRoomId)
        
    elseif typeB == "sleep" then  
        speed = InstanceModel:GetRoomPhysical(state.interactiveRoomId) 
    end  
    state.speed = speed

    self.bubbleState = state
    self.typeB = typeB
    FloatUI:SetObjectCrossCamera(self, function(view)        
        view:Invoke("RefreshInstanceWorkerBubble", self.typeB, self.bubbleState)                  
    end,function()
        if not self.view then
            return
        end
        self.view:Invoke("RefreshInstanceWorkerBubble")        
    end,0)                   
end

--[[
    @desc: 获取最近的功能房间
    author:{author}
    time:2023-08-25 17:50:32
    --@stateMachine:
	--@roomType: 
    @return:
]]
function InstanceWorkerClass:GetNearestHouse(roomType)
    local actor = self
    local rooms = InstanceModel:GetRoomDataByType(roomType)
    local dis = 9999999
    for i=1, #rooms do
        local roomData = rooms[i]
        local roomGO = InstanceModel:GetRoomGameObjectByID(roomData.roomID)
        local tempDis = Vector3.Distance(actor.gameObject.transform.position,roomGO.transform.position)
        if dis > tempDis and roomData.state == 2 then
            dis = tempDis
            return roomData.roomID, roomGO
        end
    end
end


--region 初始化
---设置与门交互的Trigger
function InstanceWorkerClass:SetDoorTrigger()
    local animName = {"DoorOpenAnim", "ToiletDoor_open"}
    local animIndex = 1
    local enterFunc = function(responseGo, activatorGo, outRoom)
        local coll = responseGo:GetComponent("ColliderResponse")
        local anim = coll:GetDoorAnim()
        if not anim or coll:GetTriggerCount() > 1 then
            return
        end

        local lastAni = 1
        local currAni = AnimationUtil.GetAnimationState(anim, animName[lastAni])
        if not currAni then
            lastAni = 2
            currAni = AnimationUtil.GetAnimationState(anim, animName[lastAni])
        end
        local needAni = outRoom == true and "_revert" or ""

        if anim.isPlaying then
            return
        end

        AnimationUtil.Play(anim, animName[lastAni] .. needAni, function()
            AnimationUtil.GotoAndStop(anim, animName[lastAni] .. needAni, "KEY_FRAME_CLOSE_POINT")--放完停在末尾,让isPlay为true
        end)

        FloorMode:MakeDoorTimer(responseGo, function()--几秒后没人自动关闭
            if coll and not CS.UnityEngine.Object.ReferenceEquals( coll, nil ) and coll:GetTriggerCount() == 0 and anim then
                AnimationUtil.Play(anim, animName[lastAni] .. needAni, nil, -1, "KEY_FRAME_SECOND")
                return true
            elseif not anim then
                return 1--切换场景的时候没了...或者其他原因导致的错误
            end

            return false
        end)
    end
    ColliderResponse:SetActivatorTriggerEventOnEnter(ColliderResponse.TYPE_OPEN_DOOR, self.m_go, enterFunc)
end

--endregion

return InstanceWorkerClass
