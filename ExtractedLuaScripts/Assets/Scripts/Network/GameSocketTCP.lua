--[[
SocketTCP lua
@origin author zrong (zengrong.net)
@maintainer tangyiyang
]]

local SOCKET_TICK_TIME = 0.1 			-- check socket data interval
local SOCKET_RECONNECT_TIME = 5			-- socket reconnect try interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 3	-- socket failure timeout

local STATUS_CLOSED = "closed"
local STATUS_NOT_CONNECTED = "Socket is not connected"
local STATUS_ALREADY_CONNECTED = "already connected"
local STATUS_ALREADY_IN_PROGRESS = "Operation already in progress"
local STATUS_TIMEOUT = "timeout"

-- this socket using the LuaSocket Module
local socket = require "socket"

local SocketTCP = {}

SocketTCP.EVENT_DATA = "SOCKET_TCP_DATA"
SocketTCP.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
SocketTCP.EVENT_DISCONNECTED = "SOCKET_TCP_DISCONNECTED"
SocketTCP.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
SocketTCP.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"

SocketTCP._VERSION = socket._VERSION
SocketTCP._DEBUG = socket._DEBUG

function SocketTCP:new(...)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	o:ctor(...)
	return o
end

function SocketTCP.getTime()
	return socket.gettime()
end

function SocketTCP:ctor()
	self.tickTimer = nil			-- timer for data
	self.reconnectTimer = nil		-- timer for reconnect
	self.timeoutTimer = nil	-- timer for connect timeout
	self.tcp = nil
	self.isConnected = false
end

function SocketTCP:setTickTime(time)
	SOCKET_TICK_TIME = time
	return self
end

function SocketTCP:setReconnTime(time)
	SOCKET_RECONNECT_TIME = time
	return self
end

function SocketTCP:setConnFailTime(time)
	SOCKET_CONNECT_FAIL_TIMEOUT = time
	return self
end

function SocketTCP:connect(host, port, isRetry)
	self.host = host
	self.port = port
	self.isRetryConnect = isRetry

	assert(self.host or self.port, "Host and port are necessary!")
	self.tcp = socket.tcp()
	self.tcp:settimeout(0)

	local function checkConnect()
		print('call checkconnect')
		local success = self:_connect()
		if success then
			self:_onConnected()
		end
		return success
	end

	if not checkConnect() then
		-- check whether connection is success
		-- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
		local function timeoutUpdateFunc()
			print('call timeoutUpdateFunc')
			if self.isConnected then return end
			self.waitConnect = self.waitConnect or 0
			self.waitConnect = self.waitConnect + SOCKET_TICK_TIME
			if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
				self.waitConnect = nil
				self:close()
				self:_connectFailure()
			end
			checkConnect()
		end

		self.timeoutTimer = GameTimer:CreateNewTimer(SOCKET_TICK_TIME, timeoutUpdateFunc, true)
	end
end

function SocketTCP:send(data)
	assert(self.isConnected, "SocketTCP is not connected.")
	self.tcp:send(data)
end

function SocketTCP:close( ... )
	self.tcp:close()

	if self.timeoutTimer then GameTimer:StopTimer(self.timeoutTimer) end
	if self.tickTimer then GameTimer:StopTimer(self.tickTimer)  end
	GameNotificationCenter:dispatch(SocketTCP.EVENT_CLOSE)
end

-- disconnect on user's own initiative.
function SocketTCP:disconnect()
	self:_disconnect()
	self.isRetryConnect = false -- initiative to disconnect, no reconnect.
end

--------------------
-- private
--------------------

--- When connect a connected socket server, it will return "already connected"
-- @see: http://lua-users.org/lists/lua-l/2009-10/msg00584.html
function SocketTCP:_connect()
	print('call SocketTCP:_connect, self.host, self.port =', self.host, self.port)
	local __succ, __status = self.tcp:connect(self.host, self.port)
	print("SocketTCP._connect:", __succ, __status)
	return __succ == 1 or __status == STATUS_ALREADY_CONNECTED
end

function SocketTCP:_disconnect()
	self.isConnected = false
	self.tcp:shutdown()
	GameNotificationCenter:dispatch(SocketTCP.EVENT_DISCONNECTED)
end

function SocketTCP:_onDisconnect()
	--printInfo("%s._onDisConnect", self.name);
	self.isConnected = false
	GameNotificationCenter:dispatch(SocketTCP.EVENT_DISCONNECTED)
	self:_reconnect();
end

-- connecte success, cancel the connection timerout timer
function SocketTCP:_onConnected()
	--printInfo("%s._onConnectd", self.name)
	print("SocketTCP:_onConnected")
	self.isConnected = true
	GameNotificationCenter:dispatch(SocketTCP.EVENT_CONNECTED)

	if self.timeoutTimer then GameTimer:StopTimer(self.timeoutTimer) end

	local __tick = function()
		while true do
			local __body, __status, __partial = self.tcp:receive("*a")	

    	    if __status == STATUS_CLOSED or __status == STATUS_NOT_CONNECTED then
		    	self:close()
		    	if self.isConnected then
		    		self:_onDisconnect()
		    	else
		    		self:_connectFailure()
		    	end
		   		return
	    	end

	    	-- this is nothing to read, just return
	    	if (__body and string.len(__body) == 0) or (__partial and string.len(__partial) == 0) then return end

	    	-- read something, dispatch the data to the listeners.
			local data = __partial or __body

			-- here we pass the partical and the body to the user in case of he or she concerns
			GameNotificationCenter:dispatch(SocketTCP.EVENT_CONNECTED, data, __partial, __body)

		end
	end
	-- start to read TCP data
	self.tickTimer = GameTimer:CreateNewTimer(SOCKET_TICK_TIME, __tick, true)
end

function SocketTCP:_connectFailure(status)
	GameNotificationCenter:dispatch(SocketTCP.EVENT_CONNECT_FAILURE)
	self:_reconnect();
end

-- if connection is initiative, do not reconnect
function SocketTCP:_reconnect(immediately)
	if not self.isRetryConnect then return end

	if immediately then self:connect() return end

	if self.reconnectTimer then scheduler.unscheduleGlobal(self.reconnectTimer) end
	local function doReConnect()
		self:connect()
	end
	self.reconnectTimer = GameTimer:CreateNewTimer(SOCKET_RECONNECT_TIME, doReConnect, false)
end

return SocketTCP
