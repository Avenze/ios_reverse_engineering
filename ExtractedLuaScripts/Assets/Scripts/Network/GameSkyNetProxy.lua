GameSkyNetProxy = {
    m_login_server_ip = "",
    m_login_server_port = "",
    m_gameclient = nil
}

local GameNetworkHttp = require("Network.GameNetworkHttp")

function GameSkyNetProxy:Socket_Init(ip, port)
    if self.m_gameclient then
        self.m_gameclient:disconnect()
        self.m_gameclient = nil
    end
    local game_proto = require "Network.game_proto"
    self.m_gameclient = require("Network.GameSkynetClient"):new(game_proto, 'game')
    self.m_login_server_ip = ip
    self.m_login_server_port = port
    GameSkyNetProxy:Socket_register_push_listener()
end

function GameSkyNetProxy:clean_up()
    self.m_login_server_ip = ""
    self.m_login_server_port = ""
    self.m_gameclient = nil
end

function GameSkyNetProxy:update()
    if self.m_gameclient then
        self.m_gameclient:update()
    end
    GameNetworkHttp:Update();
end

function GameSkyNetProxy:Socket_register_push_listener()
    local callback = function(responseTable)
        print("[skynet push message]: got new msg!!!")
        GameNetwork:Socket_HandleServerPushMsg(responseTable.push, responseTable)
    end
    if self.m_gameclient then
        self.m_gameclient:register_listener("skynet_push", callback)
    end
end

function GameSkyNetProxy:Socket_Connect(...)

    if self.m_gameclient then
        self.m_gameclient:connect(self.m_login_server_ip, self.m_login_server_port, ...)
    else 
        print("skynet connect erro, pls confirm socket init right")
    end
end

function GameSkyNetProxy:Reconnect()
end

function GameSkyNetProxy:Socket_Close()
    self.m_gameclient:disconnect(true)
end

function GameSkyNetProxy:Socket_SendRequest(requestTable, url, res_callback)
    local r_url = string.gsub(requestTable.url, "%.", "_")
    local cur_time = os.time()--glib.pomelo.GetSysTime() 
    local callback = function(responseTable)
        local use_time = os.time() - cur_time
        print("[skynet]now we call back!!"..r_url.." : use time:"..use_time)
        if res_callback then
            res_callback(url, responseTable)
        end
    end
    local reqestT = {
        msg = requestTable.msg,
    }
    if self.m_gameclient then
        print("[skynet]now we call route "..r_url)
        Tools:DumpTable(reqestT, "requestTable")
        self.m_gameclient:call_remote(r_url, reqestT, callback)
    end
end


function GameSkyNetProxy:connect_game_server(token, serverinfo)
    self.m_gameclient:connect(serverinfo.host, serverinfo.port, nil)
end