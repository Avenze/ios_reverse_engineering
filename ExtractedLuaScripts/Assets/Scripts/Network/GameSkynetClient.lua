local socket = require "socket"

local GameSkynetClient = {}

-- local print = function() end

function GameSkynetClient:new(...)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o:ctor(...)

    return o
end

function GameSkynetClient:ctor(proto, name)
    self.proto, self.name = proto, name
    self.ip, self.port = '0.0.0.0', 0
    self.buffer = ""

    ---- init the socket
    --self.client = socket.tcp()

    -- init the rpc client & host
    local sproto = require("Network.sproto")
    local parser = require("Network.sprotoparser")

    local s2c = parser.parse(proto.s2c)
    local c2s = parser.parse(proto.c2s)

    self.host = sproto.new(s2c):host("package") 
    self.request = self.host:attach(sproto.new(c2s))

    -- init the server push listeners
    self.cb_listeners = {}

    -- init the requests_callbacks
    self.cb_requests = {}
    self.session = 0
end

-- this three functions maybe rewrite adapted to custom client timers
local function tiemer_new(...)
    return GameTimer:CreateNewTimer(...)
end

local function timer_stop(timer)
    GameTimer:StopTimer(timer)
end

local function timer_run(timer)

end

local function handler(caller, func)
    return function(...)
        func(caller, ...)
    end
end

local function invoke(cb, ...)
    if cb and type(cb) == 'function' then
        cb(...)
    end
end

function GameSkynetClient:connect(ip, port, cb_event)
    print(string.format('[GameSkynetClient] connect ip = %s, port = %s', ip, port))

    assert(ip and type(ip) == 'string')
    assert(port and type(port) == 'number')

    self.ip, self.port = ip, port
    self.cb_event = cb_event

    -- block forever to wait the result
    -- 20 seconds for timeout

    local isipv6_only = false
    local addrifo, err = socket.dns.getaddrinfo(self.ip);
    if addrifo ~= nil then
        for k, v in pairs(addrifo) do
            if v.family == "inet6" then
                isipv6_only = true 
                break
            end
        end
    end

    if isipv6_only then
        self.client = socket.tcp6()
    else
        self.client = socket.tcp()
    end

    self.client:settimeout(20)
    local suceess, err = self.client:connect(ip, port)

    if suceess then
        print(string.format('[GameSkynetClient] successfully connect [%s]:[%d]', ip, port))

        -- clear the data buffer, this is used for pacakge-sticky
        self.buffer = "" 

        invoke(self.cb_event, "CONNECT", {ok = true})
    else
        invoke(self.cb_event, "CONNECT", {ok = false, err = err})
    end
end

function GameSkynetClient:disconnect(isInitiativeClose)
    print('[GameSkynetClient] disconnect from server.')
    if self.client then
        self.client:close()
        self.client = nil
        if not isInitiativeClose then
            invoke(self.cb_event, "DISCONNECT")
        end
    end
end

function GameSkynetClient:register_listener(funcname, cb)
    if not self.cb_listeners[funcname] then
        self.cb_listeners[funcname] = cb
    else
        assert(false, funcname .. "has been registered")
    end
end

function GameSkynetClient:remove_listener(funcname)
    if self.cb_listeners[funcname] then
        self.cb_listeners[funcname] = nil
    else
        error(string.format('not found listener for name = %s', funcname) )
    end
end

function GameSkynetClient:raw_request(name, args)
    self.session = self.session + 1

    -- 将请求打包成一个str, 注意这个是一个binary的package
    -- 输出的时候需要print_string_bytes() (see above), 直接print不行，有不可见字符
    local str = self.request(name, args, self.session)

    local function pack_msg()
        if _VERSION ~= 'Lua 5.3' then
            local len = string.len(str)
            local leninfo = string.pack("bb", math.floor(len/256), len%256)
            return string.pack("A", leninfo .. str)
        else
            return string.pack (">s2", str)
        end
    end

    local package = pack_msg()

    print(string.format("[GameSkynetClient] client send [%d] bytes to server.", string.len(package)))
    self.client:send(package)
    return self.session
end

function GameSkynetClient:call_remote(name, args, callback)
    assert(name and type(name) == 'string')
    print(string.format('GameSkynetClient:call_remote name[%s] args = ', name))

    if self.client then
        local session = self:raw_request(name, args)
        self.cb_requests[session] = callback
    elseif not GameDeviceManager:IsWPDevice() then
        print(string.format("[GameSkynetClient] Can NOT call_remote [%s], client has been destroyed.", name))
        --assert(false)
        invoke(self.cb_event, "DISCONNECT")
    end
end

local function print_string_bytes(data)
    if not data then return end
    local s = ""
    local limit = 100
    for i = 1, string.len(data) do
        if i >= limit then
            break
        end
        s = s .. string.byte(data, i) .. " "
    end
    print(s)
end

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = string.byte(text, 1)* 256 + string.byte(text, 2)
    if size < s+2 then
        return nil, text
    end

    return string.sub(text, 3, 2+s), string.sub(text, 3+s)
end

local function dispatch_package(self, package)
    local t, arg1, arg2 = self.host:dispatch(package)
    print('start dispatch ------  t, arg1, arg2 = ', t, arg1, arg2)
    if t == "REQUEST" then
        -- 服务端主动发送给客户端的请求
        local name, result = arg1, arg2
        print("[GameSkynetClient] dispatch_package, [server_push_msg], name = ", name)
        if result then
            local cb = self.cb_listeners[name]
            if cb then
                cb(result)
            else
                assert(false, 'not found listen for name = ' .. name)
            end
        end
    elseif t == "RESPONSE" then
        -- 客户端发送给服务端接受回应
        local session, result = arg1, arg2
        if result then
            local cb = self.cb_requests[session]
            if cb then
                cb(result)
                -- remove the callback function
                self.cb_requests[session] = nil
            else
                assert(false, "no request found for session = " .. session)
            end
        end
    else
        assert(false, "dispatach should only receive REQUEST and RESPONSE.")
    end
end

function GameSkynetClient:update()
    if self.client then
        self.client:settimeout(0)
        local body, err, partial = self.client:receive("*a")

        if err and err ~= 'timeout' then
            if err == "closed" or err == "Socket is not connected" then
                self:disconnect()
            else
                invoke(self.cb_event, 'RECEIVE', {ok = false, err = err})
            end                
        end

        if (body and string.len(body) == 0) 
           or (partial and string.len(partial) == 0) then 
            return 
        end
        -- print(string.format('GameSkynetClient:update, afeter receive, data = [%s], error = [%s], partial = [%s].', _data, err, partial))

        -- 这个socket.receive可能返回的数据在body或者partial里。
        -- http://w3.impa.br/~diego/software/luasocket/tcp.html
        -- 参考这个文档
        local data
        if body and partial then
            data = body .. partial
        else
            data = body or partial
        end
        self.buffer = self.buffer .. data

        local function logs1()
            print('---------------- Receive Process -----------------------')
            local body_size = body ~= nil and string.len(body) or 0
            print('[receive] ###body size = ', body_size)
            print_string_bytes(body)
            local partial_size = partial ~= nil and string.len(partial) or 0
            print('[receive] ##partial = ', partial_size)
            print_string_bytes(partial)
            print('[receive] totalsize = ', body_size + partial_size)
            print(string.format("client received [%d] bytes.", string.len(data)))
            print('[receive] client recevied origin data = ')
            print_string_bytes(data)
            print('-----------------End of Receive Process ----------------------')
        end
        -- logs1()

        while true do
            print(' -----------------dispatach Process ----------------------')
            local package
            package, self.buffer = unpack_package(self.buffer)
            
            local function logs2()
                print('[dispatach] after recv_package buffer_size = ' .. string.len(self.buffer))
                print('[dispatach]package = ')
                print_string_bytes(package)
                print('------- before dispatach ----------')
                print('[dispatach-before] buffer size = ', string.len(self.buffer))
                print('[dispatach-before] current buffer = ')
                print_string_bytes(self.buffer)
            end
            -- logs2()

            if not package then
                break
            end

            dispatch_package(self, package)

            local function logs3()
                print(string.format('[dispatach-after] dispatch package, size = [%d]', string.len(package)))
                print_string_bytes(package)
                print('[dispatach-after] buffer size = ', string.len(self.buffer))
                print('[dispatach-after] current buffer = ')
                print('----------------- end dispatach Process ----------------------')
            end
            -- logs3()
        end
    end
end

return GameSkynetClient