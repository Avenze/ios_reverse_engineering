local ChatEventManager = GameTableDefine.ChatEventManager
local ConfigMgr = GameTableDefine.ConfigMgr
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local GameClockManager = GameTableDefine.GameClockManager
local TimerMgr = GameTimeManager
local CompanyMode = GameTableDefine.CompanyMode
local ChatUI = GameTableDefine.ChatUI

local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local EventChatter = require "CodeRefactoring.Actor.Actors.EventChatterNew"

local ACTIVE_CHAT = "active_chat"

local localData = nil
local interval = 0
local npcCreate = nil
local saveStpes = nil

local conditionsType = nil
local allConditions = nil

--用于触发手机对话,之前还分手机事件,场景事件
--现在是只有手机事件了,满足一定的条件,然后让手机微信聊天上多亮一个对话内容

function ChatEventManager:Init()
    localData = nil
    npcCreate = nil
    saveStpes = nil
    conditionsType = nil
    self:InitConditions()
    interval = 5 * 1000
    self.lastUpdateTime = 0
end

function ChatEventManager:InitConditions()
    allConditions = {}
    local currName = nil

    for k, v in pairs(ConfigMgr.config_chat_condition) do
        currName = v.name
        if allConditions[currName] == nil then
            allConditions[currName] = {}
        end

        table.insert(allConditions[currName], v)
    end
end

function ChatEventManager:Update()
    if not interval or interval == 0 then
        return
    end

    local currTime = TimerMgr:GetDeviceTimeInMilliSec()
    if currTime - self.lastUpdateTime >= interval then
        self.lastUpdateTime = currTime
        self:CheckEvent()
    end
end

function ChatEventManager:FirstTime(chatId, happen)--是否第一次触发,下次进游戏才判断为不是第一次
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not save.happen then
        save.happen = {}
    end

    local result = true
    local curr = save.happen["" .. chatId]
    if curr then
        result = false
    end

    if happen then
        save.happen["" .. chatId] = true
    end

    return result
end

function ChatEventManager:GetConditionData()
    if localData then
        return localData
    end

    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not save.chatEventTime then
        save.chatEventTime = {}
    end

    localData = save.chatEventTime
    return localData
end

function ChatEventManager:CheckEvent()
    local currTime = GameTimeManager:GetCurrentServerTime()
    local data = self:GetConditionData() or {}
    for k,v in pairs(data) do
        if v.have > 0 and v.next_trigger <= currTime then
            self:ActiveChatEvent(tonumber(string.sub(k, 10)), true)
        end
    end
end

--点击聊天
function ChatEventManager:ClickCheckEvent()
    local currTime = GameTimeManager:GetCurrentServerTime()
    local data = self:GetConditionData() or {}
    for k,v in pairs(data) do
        if v.have > 0 and v.next_trigger <= currTime then
            self:ActiveChatEvent(tonumber(string.sub(k, 10)), true)
        end
    end

end

--例子 ConditionToStart(2, 4)--id为4的公司升到满级
function ChatEventManager:ConditionToStart(type, data, data2)
    --暂时关闭
    --return false


    if conditionsType == nil  then
        conditionsType = {}
        conditionsType[1] = "company"--引进公司(comId)
        conditionsType[2] = "companyMax"--公司满级(comId)
        conditionsType[3] = "companyUpgrade"--公司等级(comlv)
        conditionsType[4] = "buyCar"--买车(caiId)
        conditionsType[5] = "moveScene"--买办公楼(sceneId)
        conditionsType[8] = "other"--对话触发(chatId)
        conditionsType[9] = "idle"--闲聊(chatId)
        conditionsType[10] = "buyHouse"--买房(sceneId)
    end
    
    local conditionIds = self:GetTriggerId(type, data)--都要遍历,会不会有些多,如果实在多的话,可以在init里面处理一下
    --通过type和data,找到config_chat_condition中对应的n条满足条件的对话id并且去激活
    
    local isRequire = function(type, need1, need2)--是否满足条件
        if type == 2 then
            return CompanyMode:CompanyLvMax(need1)
        else
            return true
        end
    end
    -- if conditionId then
    --     if isRequire(type, data) then--可以触发
    --         self:ActiveChatEvent(conditionId)
    --         return conditionId
    --     end
    -- end
    for k,v in pairs(conditionIds or {}) do
        if isRequire(type, data, data2) then
            return self:ActiveChatEvent(v)
        end
    end
end

function ChatEventManager:ChatEventHappenCount(conditionId)
    local data = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not data.chatEventCount then
        data.chatEventCount = {}
    end
    local curr = data.chatEventCount["id"..conditionId]
    return curr or 0
end

function ChatEventManager:ChatEventCD(typeId, cdTime)
    local data = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not data.cd then
        data.cd = {}
    end

    local nowTime = TimerMgr:GetCurrentServerTime()
    if data.cd["" .. typeId] == nil then
        data.cd["".. typeId] = nowTime
        return 0
    end

    local timePass = nowTime - data.cd["" .. typeId]
    local timeNeed = cdTime - timePass
    if timeNeed <= 0 then
        timeNeed = 0
    end

    return timeNeed
end

function ChatEventManager:ActiveChatEvent(conditionId, activeNow, noTimeLimit)
    local cfg = ConfigMgr.config_chat_condition[conditionId]

    local happenCount = self:ChatEventHappenCount(conditionId)
    if cfg.timeLimit ~= 0 and happenCount >= cfg.timeLimit then
        if not noTimeLimit then
            return--超过发生次数限制,不激活
        end
    end

    if cfg.timeSetting > 0 and not activeNow then
        self:ActiveChatEventLater(conditionId, cfg.timeSetting)
        return
    end

    if cfg.place == 1 then
        return self:ActiveChatPhoneEvent(conditionId)
    elseif cfg.place == 2 then--后面没用了
        self:ActiveChatSceneEvent(conditionId)
    end
end

function ChatEventManager:ActiveChatEventLater(conditionId, waitTime, noCount)
    local data = self:GetConditionData()
    if not data["condition"..conditionId] then--这个id是condition的id
        data["condition"..conditionId] = {}
    end

    local now = GameTimeManager:GetCurrentServerTime()
    local curr = data["condition"..conditionId]
    --if not curr.count then curr.count = 0 end--累计发生次数
    if not curr.have then curr.have = 0 end--剩余次数(满足条件才+1)
    if not curr.next_trigger then curr.next_trigger = now + waitTime end
    
    if not noCount then--有些是触发失败而调用的,所以have不能累加
        curr.have = curr.have + 1
    end

    if curr.next_trigger < now then
        curr.next_trigger = now + waitTime
    end

    LocalDataManager:WriteToFile()
end

function ChatEventManager:GetTypeById(conditionId)
    local currData = ConfigMgr.config_chat_condition[conditionId]
    local currName = currData.name
    for k,v in pairs(conditionsType or {}) do
        if currName == v then
            return k
        end
    end

    return nil
end

function ChatEventManager:FinishChatEvent(conditionId)
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not save.chatEventTime then
        save.chatEventTime = {}
    end
    if not save.chatEventCount then
        save.chatEventCount = {}
    end
    if not save.cd then
        save.cd = {}
    end

    local cfg = ConfigMgr.config_chat_condition
    local currData = cfg[conditionId]
    if not currData then
        return
    end

    if not save.chatEventTime["condition"..conditionId] then
        save.chatEventTime["condition"..conditionId] = {}
    end
    if not save.chatEventCount["id"..conditionId] then
        save.chatEventCount["id"..conditionId] = 0
    end
    if currData.cd then
        local typeId = self:GetTypeById(conditionId)
        if typeId then
            save.cd["" .. typeId] = TimerMgr:GetNetWorkTimeSync(true)
        end
    end

    local curr = save.chatEventTime["condition"..conditionId]
    if not curr.have then curr.have = 0 end--剩余次数(满足条件才+1)

    curr.have = curr.have - 1
    if curr.have <= 0 then 
        save.chatEventTime["condition"..conditionId] = nil--次数用完清除,避免反复判断
    end
    save.chatEventCount["id"..conditionId] = save.chatEventCount["id"..conditionId] + 1

    LocalDataManager:WriteToFile()
end

function ChatEventManager:ActiveChatPhoneEvent(conditionId)--手机
    local success = ChatUI:ActiveChat(conditionId)
    if not success then--消息发送失败,尝试30秒后再发
        self:ActiveChatEventLater(conditionId, 60, true)
        return success
    end
    self:FinishChatEvent(conditionId)
    return success
end

function ChatEventManager:ActiveChatSceneEvent(conditionId)--场景
    local success = false
    if not npcCreate then--为生成
        success = self:CreateNPC(conditionId)
    end
    if not success then
        self:ActiveChatEventLater(conditionId, 60, true)
        return
    end
    --场景的聊天时间以npc接收事件为标志
end

function ChatEventManager:CreateNPC(conditionId)--需要condition因为需要完成计数,而chat是因为
    local cfg = ConfigMgr.config_chat_condition[conditionId]
    if not cfg or not cfg.nodeName then
        return false--错误情况如何处理??
    end
    local parentName = "ChatEvent/"..cfg.nodeName

    local eventRoot = GameObject.Find(parentName)
    if not eventRoot or eventRoot:IsNull() then
        return false
    end

    local scene = FloorMode:GetScene()

    npcCreate = EventChatter:CreateActor()
    npcCreate:Init(eventRoot, scene:GetGo(eventRoot, "prefab"),
        scene:GetTrans(eventRoot, "from").position, scene:GetTrans(eventRoot, "to").position,
        conditionId
    )

    return true
end

function ChatEventManager:UpdateSceneChat(steps)
    if not steps then
        return saveStpes or ""
    end

    local temp = ""
    for k,v in pairs(steps) do
        if k ~= #steps then
            temp = temp .. v  .. "_"
        else
            temp = temp .. v
        end
    end

    saveStpes = temp
end

function ChatEventManager:LeaveNPC(conditionId, finish)
    if not npcCreate then
        return
    end

    npcCreate:Event(npcCreate.EVENT_LEAVE_SCENE)
    npcCreate = nil
    saveStpes = nil

    if finish then
        self:FinishChatEvent(conditionId)
    end
end

function ChatEventManager:GetTriggerId(type, data)--找到相应的那一条
    if allConditions == nil then
        self:InitConditions()
    end
    
    local currName = conditionsType[type]
    if not currName then
        return nil
    end
    
    local currCondition = allConditions[currName]
    if currCondition == nil then
        return nil
    end

    local goals = {}

    for k,v in pairs(currCondition or {}) do
        if v.name == conditionsType[9] then--闲聊
            local currData = ConfigMgr.config_chat[v.condition] or {}
            local npc = ChatUI:GetNpcLocalData(data)
            if npc and #npc == 0 and currData.head == ChatUI:GetNpcByConditionId(data) then
                table.insert(goals, v.id)
            end
        elseif v.name == conditionsType[8] and v.id == data then--对话触发
            table.insert(goals, v.id)
        elseif v.condition == data then--满足条件
            table.insert(goals, v.id)
        end
    end

    local finalId = {}
    local happenCount = 0
    local happenCd = 0
    local canHappen = true

    local cfg = ConfigMgr.config_chat_condition
    local currCfg = nil
    for k,v in pairs(goals) do
        happenCount = self:ChatEventHappenCount(v)

        currCfg = cfg[v]
        if currCfg.timeLimit and currCfg.timeLimit ~= 0 and happenCount > currCfg.timeLimit then
            canHappen = false
        end

        if currCfg.cd then
            happenCd = self:ChatEventCD(type, currCfg.cd)
            if happenCd > 0 then
                canHappen = false
            end
        end

        if canHappen == true then
            table.insert(finalId, v)
        end
    end

    return finalId
end