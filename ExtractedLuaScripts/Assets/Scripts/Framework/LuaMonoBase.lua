-- abstract
_G.LuaMonoBase = _G.LuaMonoBase or {
	owner = nil,
	_instNum = 0,
}

-- 继承方法
function LuaMonoBase:Create()
	local obj = {}
	obj._instNum = 0
	self.__index = self
	setmetatable(obj, self)
	return obj
end

-- for gc
_G.luaMonoMap = _G.luaMonoMap or {}

-- 生成实例
function LuaMonoBase:CreateInst(originClassName)
	self._instNum = self._instNum + 1
	local instName = string.format("%s_INST_%d", originClassName, self._instNum)

	local obj = self:Create()
	_G.luaMonoMap[originClassName] = _G.luaMonoMap[originClassName] or {}
	_G.luaMonoMap[originClassName][instName] = obj
	return instName
end

function LuaMonoBase:DestroyInst(instName)
	if instName == "" then
		return
	end
	local nameArr = string.split(instName, "_")
	local className = nameArr[1]
	local num = nameArr[3]
	_G.luaMonoMap[className][instName] = nil
end

function LuaMonoBase:LinkValue(key, value)
	self[key] = value
end
