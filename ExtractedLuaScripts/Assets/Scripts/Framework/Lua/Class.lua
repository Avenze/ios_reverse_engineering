

local function Class(className, super)
    local superType = type(super)
    local cls = {}

    cls.__id = 1
    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    -- inherited from other object
    if super then
        setmetatable(cls, {__index = super})
        cls.super = super
        cls.__id = super.__id + 1
    
        if not cls.ctor then
            cls.ctor = function() end
        end
    end

    cls.__cname = className
    cls.__index = cls

    function cls.new(...)
        local instance = setmetatable({}, cls)
        instance:ctor(...)
        return instance
    end

    function cls.create(...)
        return cls.new(...)
    end

    function cls.getSuper(self, parent)
        if self.__id == parent.__id then
            return self.super
        end
        return self.super:getSuper(parent)
    end
    
    return cls
end

return Class
