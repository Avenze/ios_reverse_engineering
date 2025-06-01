
local LoadingScreen = GameTableDefine.LoadingScreen
local DeviceUtil = CS.Game.Plat.DeviceUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local EventManager = require("Framework.Event.Manager")
local rapidjson = require("rapidjson")

GameSDKs.GAEM_DATA_URL = "game_data"
GameSDKs.REST_DATA_URL = "clear_data"
GameSDKs.AWARD_URL = "award"
GameSDKs.CHECK_UNFINISHED_ORDER_URL = "check_unfinished_order"

local SUCCESS   = "_warrior_success"
local FAIL      = "_warrior_fail"
local count = 0
local errorQueue = {}

function GameSDKs:Warrior_request(msg)
    if msg.isLoading then
        GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
    end
    count = count + 1
    if self.GAEM_DATA_URL == msg.url then
        msg.uid = msg.url ..(msg.data and "_up" or "_down") ..count
    else
        msg.uid = msg.url..count
    end
    EventManager:RegEvent(msg.uid..SUCCESS, msg.callback)
    EventManager:RegEvent(msg.uid..FAIL, msg.errorCallback)

    msg.callback = nil
    msg.errorCallback = nil
    msg.msg = nil
    msg.isLoading = nil
    msg.fullMsgTalbe = nil
    DeviceUtil.InvokeNativeMethod("WarriorSDKAPI", rapidjson.encode(msg))
end

function GameSDKs:Warrior_response(info)
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
    if info.result == "true" then
        EventManager:DispatchEvent(info.uid..SUCCESS, info.data or {})
    else
        EventManager:DispatchEvent(info.uid..FAIL, info.errorCode or {})
        if not string.find(info.uid, self.AWARD_URL) then
            self:UploadErrorInfo("warrior_response", info)
        end
    end
    EventManager:UnregEvent(info.uid..SUCCESS)
    EventManager:UnregEvent(info.uid..FAIL)
end

function GameSDKs:UploadErrorInfo(url, data)
    xpcall(
        function()
            if not self.m_accountId then
                table.insert(errorQueue,{key=url,value=data})
                return
            end

            data.userInfo = self:GetSendUserIdInfo()
            local md5 = UnityHelper.GetMD5(rapidjson.encode(data))
            data.time = GameTimeManager:GetCurrentServerTime()
            local requestTable = {
                url = url,
                msg = {
                    userId = self.m_accountId,-- or "1234523",
                    key = md5,
                    value = rapidjson.encode(data),
                    version = CS.UnityEngine.Application.version
                },
                callback = function(response)
                end
            }
            GameNetwork:HTTP_SendRequest(requestTable)
        end,
        function(error)
        end
    )
end

function GameSDKs:ExecuteErrorQueue()
    xpcall(
        function()
            for k, v in pairs(errorQueue or {}) do
                self:UploadErrorInfo(v.key, v.value)
            end
            errorQueue = {}
        end,
        function(error)
        end  
    )
end