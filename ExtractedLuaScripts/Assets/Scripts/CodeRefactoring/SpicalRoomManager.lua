--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{gxy}
    time:2023-08-07 13:49:55
    description:特殊房间管理, 根据特定时间或固定时间间隔触发房间事件, 所有房间事件的触发都是通过调用这个类中的方法实现, 统一入口方便debug
]]
local EventManager = require("Framework.Event.Manager")
---@class SpicalRoomManager
local SpicalRoomManager = GameTableDefine.SpicalRoomManager
local InstanceDataManager = GameTableDefine.InstanceDataManager

local roomsData = {}    --房间数据列表

function SpicalRoomManager:Init()

end

-------------------------------副本相关---------------------------------

function SpicalRoomManager:InstanceWorkTime()
    EventManager:DispatchEvent("INSTANCE_WORK")
end

function SpicalRoomManager:InstanceEatTime()
    EventManager:DispatchEvent("INSTANCE_EAT")
end

function SpicalRoomManager:InstanceSleepTime()
    EventManager:DispatchEvent("INSTANCE_SLEEP")
end

function SpicalRoomManager:CycleInstanceWorkTime()
    EventManager:DispatchEvent("CYCLE_INSTANCE_WORK")
end

function SpicalRoomManager:CycleInstanceEatTime()
    EventManager:DispatchEvent("CYCLE_INSTANCE_EAT")
end

function SpicalRoomManager:CycleInstanceSleepTime()
    EventManager:DispatchEvent("CYCLE_INSTANCE_SLEEP")
end

return SpicalRoomManager