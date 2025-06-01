--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{gxy}
    time:2023-08-07 14:00:07
    description:ai状态机基类, 需要AI的演员都需要创建自己的ai状态机, 这里不使用唯一的状态机是因为, 有的状态中需要等待或循环执行,
    无法在一帧内完成动作的话需要缓存<Actor, Action> 队列, 不方便管理和debug, 所以采用为每个演员创建其自身的状态机的方案
]]
local Class = require("Framework.Lua.Class")
---@class AIStateMachine
local AIStateMachine = Class("AIStateMachine")
local FloorMode = GameTableDefine.FloorMode
local UnityHelper = CS.Common.Utils.UnityHelper
local AIBlackBoard = GameTableDefine.AIBlackBoard

local states = {} -- 状态列表
local curState = nil
local lastState = nil

--[[
    @desc: 创建每个演员自己的StateMachine
    author:{author}
    time:2023-08-21 14:48:48
    --@stateMachine:ai状态机基类
	--@actor:绑定的演员
	--@data: 演员的数据
    @return:
]]
function AIStateMachine.newClass(stateMachine, actor, data)
    local instance =
        setmetatable(
        {
            actor = actor,
            data = data,
            states = states,
            curState = curState,
            lastState = lastState,
            aiBlackBoard = AIBlackBoard
        },
        {
            __index = stateMachine
        }
    )
    return instance
end

function AIStateMachine.Init(stateMachine)
    stateMachine:InitStates()
end

--[[
    @desc: 初始化状态列表, 将每个状态拆分至一个单一的Action, 状态内不做复杂的条件和逻辑判断
    author:{gxy}
    time:2023-08-21 11:50:49
    --@stateMachine: 调用方法的示例
    @return:
]]
function AIStateMachine.InitStates(stateMachine)
end

--[[
    @desc: 切换状态
    author:{author}
    time:2023-08-25 10:09:03
    --@stateMachine:
	--@stateType:
	--@args: 
    @return:
]]
function AIStateMachine.TransState(stateMachine, stateType, ...)
    if stateMachine.states[stateType] then
        stateMachine:ExitState()
        stateMachine.curState = stateType
        stateMachine.states[stateType](stateMachine, ...)
    end

end

function AIStateMachine.ExitState(stateMachine)
    local curState = stateMachine.curState
    if stateMachine.states[curState] then
        stateMachine.lastState = stateMachine.curState
        stateMachine:OnStateExit(stateMachine.lastState )
    end
end

function AIStateMachine.Destory(stateMachine)
    stateMachine:ExitState()
end

--function AIStateMachine.SetAnimator(stateMachine, action, keyFrames)
--    for k, v in pairs(keyFrames or {}) do
--        AnimationUtil.AddKeyFrameEventOnObj(stateMachine.actor.gameObject, v.key, v.func) -- 调用的Unity的方法, 一次穿越
--    end
--    if action then
--        local animator = stateMachine.actor.gameObject:GetComponent("Animator")
--         -- UIView:GetComp(parent.m_go, "Animator")
--        if animator then
--            animator:SetInteger("Action", action)
--        end
--    end
--end

--function AIStateMachine.ClearAnimator(stateMachine, keyFrames)
--    for k, v in pairs(keyFrames or {}) do
--        AnimationUtil.AddKeyFrameEventOnObj(stateMachine.actor.gameObject, v.key, nil)
--    end
--end

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
function AIStateMachine:CalculatePath(actor, destination, canMove, maxSpeed, pickNextWayPointDist, cb, ...)
    local path = actor.m_path
    if not path then
        path = UnityHelper.AddAStartComp(actor.gameObject, false)
        actor.m_path = path
    end

    path.m_targetReachedAction = function()
        if path.remainingDistance > path.endReachedDistance then
            return
        end
        path.m_targetReachedAction = nil
        path.canMove = false
        if cb then
            cb()
        end
    end
    
    path.destination = destination.position or destination
    path.canMove = canMove
    path.maxSpeed = maxSpeed -- + Random.Range(-1.1, 1.1)  需要随机的在外面设置好
    path.pickNextWaypointDist = pickNextWayPointDist --Random.Range(1.1, 4.1)
    path:SearchPath()
end

function AIStateMachine.StopPath(stateMachine, actor)
    local path = actor.m_path
    if not path then
        return
    end
    path.m_targetReachedAction = nil
    path.canMove = false
end

--[[
    @desc: 当状态退出时
    author:{author}
    time:2023-08-30 11:03:26
    @return:
]]
function AIStateMachine:OnStateExit(lastState)
    local actor = self.actor
end


return AIStateMachine
