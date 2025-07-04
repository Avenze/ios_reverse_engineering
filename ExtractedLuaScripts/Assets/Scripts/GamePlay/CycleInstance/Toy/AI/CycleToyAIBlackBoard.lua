---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Microsoft-GXY.
--- DateTime: 2024/8/15 18:16
---
---@class CycleToyAIBlackBoard
local CycleToyAIBlackBoard = GameTableDefine.CycleToyAIBlackBoard
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local BaseScene = require("Framework.Scene.BaseScene")
local UnityHelper = CS.Common.Utils.UnityHelper ---@type Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3 ---@type UnityEngine.Vector3
local AnimationUtil = CS.Common.Utils.AnimationUtil
local PERSON_ACTION = require("CodeRefactoring.Actor.PersonActionDefine")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local clientCount = 0

local clientStrollCanUse = {}
local clientStrollUsed = {}
local childPosCanUse = {}
local childPosUsed = {}
local childPosCount = 0

local waitBuyQueue = nil    ---@type Queue
local waitPayQueue = nil    ---@type Queue

--- resID, shelfUesActor
---@type table<number, toyPlaceholder>
local shelfUesTable = {
    --[25] = { actor = nil }  -- 默认初始化第一个建筑的货架, 避免时序问题导致的问题
}
local shelfCanUse = {}  -- 可用货架
---@class toyPlaceholder
---@field actor CycleToyClient
local shelfUesActor = {}
local counterActor = nil    --- 占用结账柜台的角色

---@class toyPayPosStruct
---@field pos UnityEngine.GameObject
---@field character UnityEngine.GameObject
---@field animator UnityEngine.Animator
local ToyPayPosStruct = {}

function CycleToyAIBlackBoard:Init(inPos, outPos, gateData, payPos, strollPos, shelf, kidPos)
    self.inPos = inPos
    self.outPos = outPos
    self.gateData = gateData
    ---@type table<number, toyPayPosStruct>
    self.payPos = payPos
    
    self.strollPos = strollPos
    --clientStrollCanUse = self.strollPos   -- 初始化可用随机寻路点, 一开始的时候全部可用
    ---@type table<number, UnityEngine.GameObject>  --- resID, posGO
    self.shelfPos = shelf
    self.childPos = kidPos
    --childPosCanUse = self.childPos  -- 初始化气氛组可用随机寻路点, 一开始的时候全部可用
    
    waitBuyQueue = Queue:new()
    waitPayQueue = Queue:new()
end

function CycleToyAIBlackBoard:EnterBuyQueue(actor)
    waitBuyQueue:enqueue(actor)
end

---@return CycleToyClient
function CycleToyAIBlackBoard:ExitBuyQueue()
    local actor = waitBuyQueue:dequeue()
    return actor
end

function CycleToyAIBlackBoard:EnterPayQueue(actor)
    waitPayQueue:enqueue(actor)
end

---@return CycleToyClient
function CycleToyAIBlackBoard:ExitPayQueue()
    local actor = waitPayQueue:dequeue()
    return actor
end

function CycleToyAIBlackBoard:GetRandomStrollPos(actor)
    if #clientStrollCanUse == 0 then
        return
    end
    local pos = table.remove(clientStrollCanUse, math.random(1, #clientStrollCanUse))
    clientStrollUsed[actor] = pos
    return pos
end

function CycleToyAIBlackBoard:RecycleStrollPos(actor)
    local pos = clientStrollUsed[actor]
    clientStrollCanUse[#clientStrollCanUse + 1] = pos
    clientStrollUsed[actor] = nil
end

function CycleToyAIBlackBoard:GetRandomChildPos(child)
    if #childPosCanUse == 0 then
        return
    end
    local pos = table.remove(childPosCanUse, math.random(1, #childPosCanUse))
    childPosUsed[child] = pos
    return pos
end

function CycleToyAIBlackBoard:RecycleChildPos(actor)
    local pos = childPosUsed[actor]
    childPosCanUse[#childPosCanUse + 1] = pos
    childPosUsed[actor] = nil
end

function CycleToyAIBlackBoard:GetRandomInPos()
    return self.inPos[math.random(1, #self.inPos)]
end

function CycleToyAIBlackBoard:GetRandomOutPos()
    return self.outPos[math.random(1, #self.outPos)]
end

function CycleToyAIBlackBoard:GetRandomPayPos()
    local posData = self.payPos[math.random(1, #self.payPos)]
    return posData
end

function CycleToyAIBlackBoard:GetRandomStrollIdleTime()
    local range = CycleInstanceDataManager:GetCurrentModel().config_global.instance_customer_idle
    return math.random(range[1], range[2])
end

function CycleToyAIBlackBoard:GetRandomChildPlayTime()
    local range = CycleInstanceDataManager:GetCurrentModel().config_global.instance_kid_idle
    return math.random(range[1], range[2])
end

---检查是否有闲置的货架
function CycleToyAIBlackBoard:CheckIdleShelf()
    for k,v in pairs(shelfUesTable) do
        if not v.actor then
            return true
        end
    end
    return false
end

---占用货柜
---@return UnityEngine.GameObject shelfGO
---@return number resID
function CycleToyAIBlackBoard:OccupiedShelf(actor)
    for k,v in pairs(shelfUesTable) do
        if not v.actor and CycleInstanceDataManager:GetCurrentModel():ProductIsSelling(k) then
            shelfCanUse[k] = k
        else
            shelfCanUse[k] = nil
        end
    end
    local k, v = table.GetRandomKeyValue(shelfCanUse)
    if not k then
        return
    end
    shelfUesTable[k].actor = actor
    local shelfGO = self.shelfPos[k]
    return shelfGO, k
end

---解除占用货柜
function CycleToyAIBlackBoard:DeoccupyShelf(actor)
    for k,v in pairs(shelfUesTable) do
        if v.actor == actor then
            v.actor = nil
            -- 通知队列有空位
            if waitBuyQueue:size() > 0 then
                local shelfGO = self.shelfPos[k]
                local willBuyActor = self:ExitBuyQueue()
                willBuyActor.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleToyClientGoToBuy, shelfGO)
            end
        end
    end
end

function CycleToyAIBlackBoard:RefreshShelf(workRoomData, resID)
    local curWorkRoomData = workRoomData
    if not shelfUesTable[resID] and CycleInstanceDataManager:GetCurrentModel():ProductIsSelling(resID) then
        -- 刷新了新的货架
        shelfUesTable[resID] = {}
        for i = 1, #self.strollPos[workRoomData.roomID] do
            table.insert(clientStrollCanUse, self.strollPos[workRoomData.roomID][i])
        end
        if self.childPos[workRoomData.roomID] then
            for i = 1, #self.childPos[workRoomData.roomID] do
                table.insert(childPosCanUse, self.childPos[workRoomData.roomID][i])
                childPosCount = childPosCount + 1
            end
        end

    end
end

---检查是否有闲置的结账柜台
function CycleToyAIBlackBoard:CheckIdleCounter()
    return counterActor == nil
end

---占用结账柜台
---@return toyPayPosStruct
function CycleToyAIBlackBoard:OccupiedCheckoutCounter(actor)
    if not counterActor then
        counterActor = actor
        local payData = self:GetRandomPayPos()
        return payData
    end
end

---解除占用结账柜台
function CycleToyAIBlackBoard:DeoccupyCounter(actor)
    counterActor = nil
    -- 通知结账柜台有空位
    if waitPayQueue:size() > 0 then
        local willPayActor = self:ExitPayQueue()
        local outData = self:GetRandomPayPos()
        willPayActor.m_stateMachine:ChangeState(ActorDefine.CycleInstanceState.CycleToyClientGoToPay, outData)
    end
end

function CycleToyAIBlackBoard:OnExit()
    waitBuyQueue = nil
    waitPayQueue = nil  
    counterActor = nil
    shelfUesTable = {}
    shelfUesActor = {} 
    clientStrollCanUse = {}
    clientStrollUsed = {}
    childPosCanUse = {}
    childPosUsed = {}
    childPosCount = 0
end

function CycleToyAIBlackBoard:AddClient()
    clientCount = clientCount + 1
end

function CycleToyAIBlackBoard:ReduceClient()
    clientCount = clientCount - 1
end

function CycleToyAIBlackBoard:GetClientCount()
    return clientCount
end

function CycleToyAIBlackBoard:GetChildPlayPosCount()
    return childPosCount
end

return CycleToyAIBlackBoard
