--region 读取协议
local pb = require "pb"
local protoc = require "Network.protoc"
local msghandler = require "Network.msghandler"
--endregion

local HTTPManager = CS.Common.Utils.HTTPManager.Instance
local UnityHelper = CS.Common.Utils.UnityHelper
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local FloorMode = GameTableDefine.FloorMode
local CountryMode = GameTableDefine.CountryMode

local rapidjson = require("rapidjson")
require("GameUtils.GameDeviceManager")
local GameResMgr = require("GameUtils.GameResManager")

GameServerHttpClient = {
    loginAddr = {
        ["com.warrior.officebuilding.ioshw"] = "http://49.51.242.111:9001",
        ["com.warrior.officebuilding.gp"] = "http://49.51.242.111:9002",
        ["com.warrior.obxso.gp"] = "http://49.51.242.111:9003",
        --["com.warrior.officebuilding.ioshw"] = "http://127.0.0.1:9001",
        --["com.warrior.officebuilding.gp"] = "http://127.0.0.1:9001",
        --["com.warrior.obxso.gp"] = "http://127.0.0.1:9001",
    },
    curGameServerIPAndPort = nil, -- 游戏逻辑服
    versionCheckState = 0, --0未请求过服务器连接，1-协议匹配，2-协议不匹配
    curMsgID = 0, --当前请求的MsgID
    callback = nil, --当前的请求回调函数
}

function GameServerHttpClient:GetServerAddr()
    local bundleId = self:GetAppBundleIdentifier()
    
    return self.loginAddr[bundleId] or nil
end

--region 接入skynet服务器相关的函数定义
function GameServerHttpClient:LoadProto(protoName, cb)
    local filePath = "Assets/Scripts/protobuf/" .. protoName .. ".proto.txt"
    local protoStr
    GameResMgr:ALoadAsync(filePath, this, function(handler)
        protoStr = handler.Result.text
        protoc:load(protoStr)
        if cb then
            cb()
        end
    end)
end

function GameServerHttpClient:encode(msgid, data)
    local msg = ""
    if msghandler[msgid] then
        local retmsg = pb.encode(msghandler[msgid]["msgname"], data)
        local head = string.pack(">H", msgid)
        local body = string.pack(">s2", retmsg)
        msg = head .. body
    end

    return msg
end

function GameServerHttpClient:decode(msg)
    if msg and msg ~= "" and string.len(msg) >= 4 then
        local msgid, body = string.unpack(">Hs2", msg)
        if msghandler[msgid] then
            local ack_name = msghandler[msgid]["ackname"] or nil
            if ack_name then
                local data = assert(pb.decode(ack_name, body))
                return msgid, data
            end
        end
    end

    return nil, nil
end
--endregion

function GameServerHttpClient:debug_log(msg)
    if GameConfig:IsDebugMode() then
        HTTPManager:debug_log(msg)
    end
end

function GameServerHttpClient:Request(url, msgid, data, callback, maxRetryTimes, timeout)
    --2024-11-26增加一个容错fy
    if not url then
        return
    end
    if (msgid ~= 1000 and msgid ~= 1001) and self.versionCheckState ~= 1 then
        self:debug_log("登陆信息错误:" .. rapidjson.encode(url) .. ", msgid: " .. msgid)
        return { errno = -1, msg = "登陆信息错误" }
    end

    local requestMsg = self:encode(msgid, data)

    self:debug_log("请求：" .. url .. ", " .. msgid .. ", " .. rapidjson.encode(data))

    local header = { username = GameServerHttpClient:GetCurUserID() }
    HTTPManager:SendHttpServerRequest(url, "POST", { data = requestMsg }, header, function(result)
        local returnData = { errno = 0 }
        if not result or not result.downloadHandler or not result.downloadHandler.data then
            returnData = { errno = -1, msg = "网络错误" }
        else
            local msgId, msgData = self:decode(result.downloadHandler.data)
            if msgId == 0 or msgData == nil then
                returnData = { errno = -1, msg = "解析错误" }
            elseif msgData.errno ~= 0 then
                returnData = { errno = -1, msg = msgData.msg or "请求错误" }
            else
                returnData = msgData
                self:debug_log("成功:" .. rapidjson.encode(msgData) .. ", msgid: " .. msgid)
            end
        end

        if returnData.errno ~= 0 then
            self:debug_log("code 错误: " .. returnData.msg .. ", msgid: " .. msgid)
        end

        if callback then
            callback(returnData)
        end
    end, maxRetryTimes or 3, timeout or 10)
end

--region 玩家信息

--- 玩家 ID
function GameServerHttpClient:GetCurUserID()
    return GameSDKs:GetCurUserID()
end

--- 玩家 ID
function GameServerHttpClient:GetCurUserID()
    return GameSDKs:GetCurUserID()
end

--- 玩家 当前赚钱效率
function GameServerHttpClient:GetTotalRent()
    local countryID = CountryMode:GetCurrCountry() -- 获取当前的区域ID
    
    return FloorMode:GetTotalRent(nil, countryID) --获取当前的赚钱效率根据地区来进行显示的
end

--- 玩家 当前的办公楼进度ID
function GameServerHttpClient:GetMaxDevelopCountryBuildingID()
    return CountryMode:GetMaxDevelopCountryBuildingID() --获取当前的办公楼进度ID（包含当前地区问题了
end

--- 玩家角色 ID
function GameServerHttpClient:GetUserGender()
    return LocalDataManager:GetBossSex()
end

--- 玩家昵称
function GameServerHttpClient:GetUserName()
    return LocalDataManager:GetBossName()
end

-- 玩家装扮
function GameServerHttpClient:GetUserDressUp()
    local dressUpData = GameTableDefine.DressUpDataManager:GetCurrentPersonAllDressUp(1)
    local skinId = 0
    local hatId = 0
    local bagId = 0
    if dressUpData then
        for part, equipId in pairs(dressUpData) do
            if part == 0 then
                skinId = equipId
            elseif part == 1 then
                hatId = equipId
            elseif part == 2 then
                bagId = equipId
            end
        end
    end

    return skinId, hatId, bagId
end

--- 场景 ID
function GameServerHttpClient:GetSceneId()
    local scene_id = CityMode:GetCurrentBuilding()

    return tostring(scene_id and math.floor(scene_id) or 0)
end

--- 游戏版本号
function GameServerHttpClient:GetAppVersion()
    return CS.UnityEngine.Application.version -- 游戏版本号
end


--- 语言设置
function GameServerHttpClient:GetLanguage()
    return GameLanguage:GetCurrentLanguageID() -- 语言ID
end

--- 星级 or 知名度
function GameServerHttpClient:GetUserStar()
    return StarMode:GetStar()
end

--- 平台
function GameServerHttpClient:GetCurPlatformDesc()
    if GameDeviceManager:IsiOSDevice() then
        return "IOS"
    elseif GameDeviceManager:IsAndroidDevice() then
        return "Android"
    end

    return "UnityEditor"
end

--- 包名
function GameServerHttpClient:GetAppBundleIdentifier()
    return GameDeviceManager:GetAppBundleIdentifier()
end
--endregion

--region 请求游戏服务器的地址
function GameServerHttpClient:Init()
    self:LoadProto("player", function() end)
    self:LoadProto("login", function()
        --TODO：这里后面要和运营对接，看是否去运营那边拉取游戏网关服务器的地址
        local serverAddr = self:GetServerAddr()
        if serverAddr then
            local loginAddrData = {
                userid = self:GetCurUserID(),
                bundleid = self:GetAppBundleIdentifier(),
                platform = self:GetCurPlatformDesc(),
                version = tostring(msghandler.version)
            }

            self:Request(serverAddr, 1000, loginAddrData, function(result)
                if result and result.errno == 0 then
                    self:GetLoginGameServerAddrCallback(result)
                end
            end)
        end
    end)
end

function GameServerHttpClient:GetLoginGameServerAddrCallback(msgData)
    self.curGameServerIPAndPort = "http://" .. msgData.ip .. ":" .. msgData.port
    local loginData = {
        userid = self:GetCurUserID(),
        username = self:GetUserName(),
        startlvl = self:GetUserStar(),
        version = tostring(msghandler.version)
    }

    self:Request(self.curGameServerIPAndPort, 1001, loginData, function(result)
        self:LoginGameServerCallback(result)
    end)
end
--endregion

--region 登入、登出
function GameServerHttpClient:LoginGameServerCallback(msgData)
    if msgData and msgData.errno == 0 then
        self.versionCheckState = 1

        --GameServerHttpClient:UpdateRank("DAU", os.time(), function(res)
        --    self:debug_log("排行榜上报：" .. rapidjson.encode(res))
        --end)
        --
        --GameServerHttpClient:GetRank("DAU", 0, function(res)
        --    self:debug_log("获取排行榜：" .. rapidjson.encode(res))
        --end)

        --GameServerHttpClient:Track("test_event", { param1 = "param1", param2 = "param2" }, function(res)
        --    self:debug_log("事件上报：" .. rapidjson.encode(res))
        --end)
    else
        self.versionCheckState = 2  --协议不匹配
    end
end

function GameServerHttpClient:LogoutGameServer()
    if self.versionCheckState ~= 1 then
        self:debug_log("Error:client server version not equal server version")
        return
    end

    local logoutdata = {
        userid = self:GetCurUserID(),
        version = tostring(msghandler.version)
    }
    self:Request(self.curGameServerIPAndPort, 1002, logoutdata, function()
        self:debug_log("Login out")
    end)

    self.curGameServerIPAndPort = nil
    self.versionCheckState = 0
end
--endregion


--region 排行榜
--- 上报排行榜
---@param 回调函数
function GameServerHttpClient:ReportRank(instance_id, instance_index, score, callback)
    local skinId, hatId, bagId = self:GetUserDressUp()
    local requestData = {
        user_id = self:GetCurUserID(),
        --bundleid = self:GetAppBundleIdentifier(),
        --platform = self:GetCurPlatformDesc(),
        version = tostring(msghandler.version),
        language = self:GetLanguage(), -- 语言
        scene_id = self:GetSceneId(), -- 场景
        username = self:GetUserName(), -- 昵称
        gender = self:GetUserGender(), -- 性别
        skin = skinId, -- 皮肤
        hat = hatId, -- 帽子
        bag = bagId, -- 包
        score = score, -- 副本拉霸机代币获得的数量总和
        instance_id = instance_id, -- 副本ID
        instance_index = instance_index, -- 活动代号
        total_rent = tostring(self:GetTotalRent()), -- 当前赚钱效率
        max_develop_country_building_id = self:GetMaxDevelopCountryBuildingID(), -- 当前的办公楼进度ID
    }

    self:Request(self.curGameServerIPAndPort, 1061, requestData, callback)
end

--- 排行榜数据获取
---@param 回调函数
function GameServerHttpClient:GetReportRank(instance_id, instance_index, callback)
    local requestData = {
        user_id = self:GetCurUserID(),
        version = tostring(msghandler.version),
        --language = self:GetLanguage(),
        --scene_id = self:GetSceneId(),
        instance_id = instance_id, -- 副本ID
        instance_index = instance_index, -- 活动代号
    }

    self:Request(self.curGameServerIPAndPort, 1062, requestData, callback, 3, 10)
end

--- 作弊通知
---@param 回调函数
function GameServerHttpClient:CheatTag(instance_id, instance_index, callback)
    local requestData = {
        user_id = self:GetCurUserID(),
        version = tostring(msghandler.version),
        instance_id = instance_id, -- 副本ID
        instance_index = instance_index, -- 活动代号
    }

    self:Request(self.curGameServerIPAndPort, 1063, requestData, callback)
end
--endregion