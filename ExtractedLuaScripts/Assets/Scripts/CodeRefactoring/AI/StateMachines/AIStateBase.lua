---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/8/25 16:38
---
local Class = require("Framework.Lua.Class")
---@class AIStateBase
local AIStateBase = Class("AIStateBase")

function AIStateBase:ctor()
    self.m_owner = nil
end

---@param owner ActorBase
function AIStateBase:SetOwner(owner)
    self.m_owner = owner
end

function AIStateBase:OnEnter()

end

function AIStateBase:OnExit()

end

---self.m_go被删除时调用
function AIStateBase:OnDestroy()

end

function AIStateBase:Event(msg,params)

end

return AIStateBase