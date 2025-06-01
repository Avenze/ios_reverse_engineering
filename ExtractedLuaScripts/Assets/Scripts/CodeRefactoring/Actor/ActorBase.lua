--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{gxy}
    time:2023-08-07 14:00:07
    description:游戏中所有实体对象基类
]]
local GameObject = CS.UnityEngine.GameObject
local Class = require("Framework.Lua.Class")
---@class ActorBase
local ActorBase = Class("ActorBase")
local ActorManager = GameTableDefine.ActorManager
local AnimationUtil = CS.Common.Utils.AnimationUtil
local FloorMode = GameTableDefine.FloorMode
local UnityHelper = CS.Common.Utils.UnityHelper

local data = {
    buildID = 0, --所属建筑ID
    roomID = 0, --所属房间ID
    furnitureID = 0, --所属家具ID
    furnitureIndex = 0, --所属家具位置索引

}

function ActorBase:ctor(...)
    self.instanceID = 0
    self.gameObject = nil
    self.m_animator = nil ---@type UnityEngine.Animator
    self.aiStateMachine = nil
    self.m_path = nil ---@type AIPathNav
    self.m_type = nil ---@type string -ActorType
    self.m_isPooling = false ---@type boolean 是否被回收
    self.data = data
    --setmetatable(
    --    Tools:CopyTable(data),
    --    {
    --        __index = function(key)
    --            print(self.instanceID, self.__cname .. "中找不到[" .. key .. "]属性", debug.traceback())
    --            return nil
    --        end
    --    }
    --)
end

function ActorBase.Init(actor, id, go, data, ai)
    actor.instanceID = id
    actor:AddGO(go)
    actor:SetData(data)
    actor:AddAI(ai)
end

function ActorBase.AddAI(actor, ai)
    if not ai then
        return
    end
    actor.aiStateMachine = ai
end

function ActorBase.RemoveAI(actor)
    if actor.aiStateMachine then
        actor.aiStateMachine:OnDestroy()
    end
end

function ActorBase.OnUpdate(actor,dt)
end

function ActorBase:AddGO(go)
    if not go then
        return
    end
    if self.gameObject then
        --TEMP 先直接销毁,后面用对象池缓存
        GameObject.Destroy(self.gameObject)
    end
    self.gameObject = go
    ActorManager:OutActorChange(self.m_go, true)
end

function ActorBase.AddGOByPath(acotr, goPath)
end

function ActorBase.RemoveGO(actor)
    GameObject.Destroy(actor.gameObject)
    actor.gameObject = nil
end

function ActorBase.SetData(actor, actorData)
    if not actorData then
        return
    end
    for k, v in pairs(actorData) do
        actor.data[k] = v
    end
end

function ActorBase.GetData(actor, key)
    return actor.data[key]
end

--[[
    @desc: 将行为变换封装为一个闭包
    author:{author}
    time:2023-08-25 10:25:46
    --@actor:
	--@transAction: 
    @return:
]]
function ActorBase.TryTransState(actor, transAction)
    ActorManager:TryTransState(actor, transAction)
end

function ActorBase.Destroy(actor)
    -- 销毁状态机
    actor.RemoveAI(actor)
    -- 数据清空

    -- 销毁模型
    actor.RemoveGO(actor)
    -- 销毁actor自身
    actor = nil
end

function ActorBase:SetAnimator(action, keyFrames)
    for k, v in pairs(keyFrames or {}) do
        local animator = self.m_animator
        local cb = function()
            if animator and not animator:IsNull() then --确保注册这个回调的Animator还存在,不然换场景时刚好调用会报错
                v.func()
            end
        end
        AnimationUtil.AddKeyFrameEventOnObj(self.gameObject, v.key, cb) -- 调用的Unity的方法, 一次穿越
    end
    if action then
        --if self.gameObject == nil or self.gameObject:IsNull() then
        --    local dbg = require('emmy_core')
        --    dbg.breakHere()
        --end
        -- UIView:GetComp(parent.m_go, "Animator")
        if self.m_animator then
            self.m_animator:SetInteger("Action", action)
        end
    end
end

function ActorBase:PlayAnima(stateName, layer, normalizedTime, keyFrames)
    self:SetAnimator(-1)
    for k, v in pairs(keyFrames or {}) do
        local animator = self.m_animator
        local cb = function()
            if animator and not animator:IsNull() then --确保注册这个回调的Animator还存在,不然换场景时刚好调用会报错
                v.func()
            end
        end
        AnimationUtil.AddKeyFrameEventOnObj(self.gameObject, v.key, cb) -- 调用的Unity的方法, 一次穿越
    end
    if stateName and self.m_animator then
        self.m_animator:Play(stateName, layer or -1, normalizedTime or 0)
    end
end

function ActorBase.ClearAnimator(stateMachine, keyFrames)
    for k, v in pairs(keyFrames or {}) do
        AnimationUtil.AddKeyFrameEventOnObj(stateMachine.actor.gameObject, v.key, nil)
    end
end

--到达回调，为优化GC减少闭包.
function ActorBase:OnReachedTarget()
    local path = self.m_path
    if path.remainingDistance > path.endReachedDistance then
        return
    end
    path.m_targetReachedAction = nil
    path.canMove = false
    if self.m_onReachedCallback then
        local cb = self.m_onReachedCallback
        self.m_onReachedCallback = nil
        cb()
    end
end

--[[
    @desc: 计算寻路路径
    author:{author}
    time:2023-08-28 11:33:45
    --@stateMachine:状态机
	--@actor:演员
	--@destination:目的地Transform
	--@canMove:可以移动
	--@maxSpeed:最大移动速度
	--@pickNextWayPointDist:忽略下个寻路点的距离
	--@cb: 寻路结束的回调
    @return:
]]
function ActorBase:CalculatePath(destination, canMove, maxSpeed, pickNextWayPointDist, cb, ...)
    local path = self.m_path
    if not path then
        path = UnityHelper.AddAStartComp(self.gameObject, false)
        self.m_path = path
    end

    --path.m_targetReachedAction = function()
    --    if path.remainingDistance > path.endReachedDistance then
    --        return
    --    end
    --    path.m_targetReachedAction = nil
    --    path.canMove = false
    --    if cb then
    --        cb()
    --    end
    --end
    if not self.m_onReachedAction then
        self.m_onReachedAction = handler(self,self.OnReachedTarget)
    end
    self.m_onReachedCallback = cb
    path.m_targetReachedAction = self.m_onReachedAction

    path.destination = destination.position or destination
    path.canMove = canMove
    path.maxSpeed = maxSpeed -- + Random.Range(-1.1, 1.1)  需要随机的在外面设置好
    path.pickNextWaypointDist = pickNextWayPointDist --Random.Range(1.1, 4.1)
    path:SearchPath()
end

function ActorBase:StopPath()
    local path = self.m_path
    if not path then
        return
    end
    path.m_targetReachedAction = nil
    path.canMove = false
end


return ActorBase
