local XLuaManager = CS.Common.Utils.XLuaManager.Instance
local EventDispatcher = EventDispatcher

local Manager = {
    init = false;
}

function Manager:RegEvent(event_type, handler)
    if not handler then return end
    
    self.__listeners = self.__listeners or {};
    self.__listeners[event_type] = handler --self.__listeners[event_type] or {};
    --self.__listeners[event_type][handler] = true;
end

-- function Manager:UnregEventAll(event_type)
--     self.__listeners = self.__listeners or {};
--     if not self.__listeners[event_type] then return end
--     self.__listeners[event_type] = nil;
-- end

function Manager:UnregEvent(event_type)
    self.__listeners = self.__listeners or {};
    if not self.__listeners[event_type] then return end
    -- self.__listeners[event_type][handler] = nil;
    self.__listeners[event_type] = nil;
end

function Manager:DispatchEvent(event_type, ...)
    --print("DispatchEvent: ", event_type, ...)

    EventDispatcher:TriggerEvent(event_type)

    self.__listeners = self.__listeners or {};
    if not self.__listeners[event_type] then return end
    self.__listeners[event_type](...)
    -- for k, v in pairs(self.__listeners[event_type]) do
    --     if v and type(k) == "function" then
    --         k(...);
    --     end
    -- end
end

if not Manager.init then
    XLuaManager:SetDispathcLuaEventFunc(handler(Manager, Manager.DispatchEvent));
    Manager.init = true;
end

return Manager;
