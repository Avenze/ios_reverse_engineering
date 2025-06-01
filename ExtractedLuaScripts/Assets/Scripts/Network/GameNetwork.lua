

GameNetwork = {
}

if GameConfig:IsWarriorVersion() then
    local ROOT_URL = "https://guigu1.loveballs.club/"
    -- if GameDeviceManager:IsDebugVersion() then
    --     ROOT_URL = "https://baidu.loveballs.club/"
    -- end
    GameNetwork.GAEM_DATA_URL               = ROOT_URL .. "gameapi/v1/data/game"
    GameNetwork.AWARD_URL                   = ROOT_URL .. "gameapi/v1/code/getAward" --  "https://guigu1.loveballs.club/gameapi/v1/code/getAward",
    GameNetwork.COST_CODE_URL               = ROOT_URL .. "gameapi/v1/code/costCode" --   "https://guigu1.loveballs.club/gameapi/v1/code/costCode"
    GameNetwork.CREATE_ORDER_URL            = ROOT_URL .. "gameapi/v1/payment/createRecharge" --      "https://guigu1.loveballs.club/gameapi/v1/payment/createRecharge",
    GameNetwork.COST_ORDER_URL              = ROOT_URL .. "gameapi/v1/payment/cost" -- https://guigu1.loveballs.club/gameapi/v1/payment/cost"
    GameNetwork.CHECK_UNFINISHED_ORDER_URL  = ROOT_URL .. "gameapi/v1/payment/add" -- "https://guigu1.loveballs.club/gameapi/v1/payment/add"
    GameNetwork.RESET_GAME_DATA_URL         = ROOT_URL .. "gameapi/v1/data/clear" -- https://guigu1.loveballs.club/gameapi/v1/data/clear
    GameNetwork.GET_GAME_VER_URL            = "https://advert.loveballs.club/ServerLink/server/getUrl4codeAndType?code=1ea09172-9659-4131-9764-c7b56df1dc2f&type=all"
    GameNetwork.GET_ACTIVITY_RANK_OPEN_URL  = "https://advert.loveballs.club/ServerLink/server/getUrl4codeAndType?code=1955d785-1e2c-4aa8-a68d-a46b3d800163&type=all"
    GameNetwork.GET_TIMELIMITED_ACTIVITES_URL = "https://advert.loveballs.club/ServerLink/server/getUrl4codeAndType?code=8c74a2d9-41ce-459c-b009-e4b552535e0d&type=all"
    if GameDeviceManager:IsiOSDevice() then
        GameNetwork.HEADR = {
            ["content-type"] = "application/json",
            ["X-WRE-APP-ID"] = "officebuilding_warrior_ioshw",
            ["X-WRE-APP-NAME"] = "officebuilding_warrior_ioshw",
            ["X-WRE-VERSION"] = "1.2.0",
            ["X-WRE-CHANNEL"] = "gp_ios",
            ["X-WRE-TOKEN"] = "",
            ["X-FORWARDED-FOR"] = "",
            ["P"] = "iOS",
        }
        GameNetwork.CHECK_ORDER_URL   = ROOT_URL .. "gameapi/v1/payment/ios"
    else
        GameNetwork.HEADR = {
            ["content-type"] = "application/json",
            ["X-WRE-APP-ID"] = "officebuilding_warrior_androidhw",
            ["X-WRE-APP-NAME"] = "officebuilding_warrior_androidhw",
            ["X-WRE-VERSION"] = "1.2.0",
            ["X-WRE-CHANNEL"] = "googleplay",
            ["X-WRE-TOKEN"] = "",
            ["X-FORWARDED-FOR"] = "",
            ["P"] = "And",
        }
        GameNetwork.CHECK_ORDER_URL   = ROOT_URL .. "gameapi/v1/payment/android"
    end
elseif GameConfig:IsLeyoHKVersion() then
    local ROOT_URL = "https://leyogame.3yoqu.com/"
    -- if GameDeviceManager:IsDebugVersion() then
    --     ROOT_URL = "http://47.254.42.14/"
    -- end
    -- GameNetwork.GAEM_DATA_URL               = ROOT_URL .. "gameapi/v1/data/game"
    -- GameNetwork.AWARD_URL                   = ROOT_URL .. "gameapi/v1/code/getAward"
    -- GameNetwork.COST_CODE_URL               = ROOT_URL .. "gameapi/v1/code/costCode"
    GameNetwork.CREATE_ORDER_URL            = ROOT_URL .. "api/v1.payment/createOrder"
    GameNetwork.COST_ORDER_URL              = ROOT_URL .. "api/v1.payment/cost" 
    GameNetwork.CHECK_UNFINISHED_ORDER_URL  = ROOT_URL .. "api/v1.payment/queryOrder" 
    if GameDeviceManager:IsiOSDevice() then
        GameNetwork.HEADR = {
            ["content-type"] = "application/json",
            ["X-LEYO-APP-ID"] = "35ly6o89ut",
            ["X-LEYO-APP-NAME"] = "MLBGG_HK_IOS",--"买楼吧哥哥HK",
            ["X-LEYO-VERSION"] = GameDeviceManager:GetAppversion(),
            ["X-LEYO-CHANNEL"] = "hk",
            ["X-LEYO-TOKEN"] = "",
            ["P"] = "iOS",
        }
        GameNetwork.CHECK_ORDER_URL   = ROOT_URL .. "api/v1.payment/verifyOrderIOS"
    else
        GameNetwork.HEADR = {
            ["content-type"] = "application/json",
            ["X-LEYO-APP-ID"] = "35ly6o89ut",
            ["X-LEYO-APP-NAME"] = "买楼吧哥哥HK",--"",
            ["X-LEYO-VERSION"] = GameDeviceManager:GetAppversion(),
            ["X-LEYO-CHANNEL"] = "hk",
            ["X-LEYO-TOKEN"] = "",
            ["P"] = "And",
        }
        GameNetwork.CHECK_ORDER_URL   = ROOT_URL .. "api/v1.payment/verifyOrder"
    end
end

local AES = CS.Common.Utils.AES
local GZipHelper = CS.Common.Utils.GZipHelper
local HTTPManager = CS.Common.Utils.HTTPManager.Instance
local persistentPath = CS.UnityEngine.Application.persistentDataPath

local socket = require "socket"
local http = require("socket.http")
-- local ltn12 = require("ltn12")
local json = require("rapidjson")

function GameNetwork:AssembleRequestParamString(paramTable, method, enableEncryption)
    local requestParamString = ""
    if "POST" == method then
        requestParamString = json.encode(paramTable or {})
        print("requestParamString PSOT:", requestParamString);
    else
        for k, v in pairs(paramTable or {}) do
            local value = v
            if type(value) == "table" then
                value = json.encode(value)
            end
            if requestParamString == "" then
                requestParamString = table.concat({k, "=", value})
            else
                requestParamString = table.concat({requestParamString, "&", k, "=",value})
            end
        end
        print("requestParamString GET:", requestParamString);
    end
    if requestParamString ~= "" and enableEncryption then
        requestParamString = AES.Encrypt(requestParamString)
        -- 如果‘+’出现在url中，在服务器端会被转化为空格，导致解码失败
        requestParamString = string.gsub(requestParamString, "+", "%%2B")
    end
    return requestParamString
end

--[[
    varTable params:
        url - Mandatory
        paramTable - Optional
        timeout - Optional, dafault value is 20s
        method - Optional, "GET" by default
        callback - Optional
]]
function GameNetwork:HTTPRequest(varTable, sync, headers)
    assert(varTable.url ~= nil, "url in varTable CANNOT be nil")
    if varTable.timeout then
        http._TIMEOUT = varTable.timeout
    else
        http._TIMEOUT = 20
    end


    local enableEncrypt = varTable.enableEncrypt == nil and true or varTable.enableEncrypt;
    local requestParamString =  self:AssembleRequestParamString(varTable.paramTable, varTable.method, enableEncrypt) 
    -- local contentLength = string.len(requestParamString)
    -- print("send http request url->", "http://"..varTable.url, "    requestParamString->", requestParamString)
    if headers then
        headers.ENABLE_ENCRYPT =  enableEncrypt and "1" or "0"
        Tools:DumpTable(headers, "headers")
    end
    Tools:DumpTable(varTable, "requestTable")
    local cb = function(uwr)
        if varTable.isLoading then
            GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
        end
        local encryptedRespStr = uwr.downloadHandler.text;
        local decryptedResponseStr = "";
        print("HTTPRequest URL", varTable.url)
        -- print("encryptedRespStr", type(encryptedRespStr), encryptedRespStr);
        if enableEncrypt then
            if GameDeviceManager:IsWindowsDevice() then
                encryptedRespStr = GZipHelper.DecompressString(uwr.downloadHandler.data)
            end
            -- encryptedRespStr = string.sub(encryptedRespStr, 2, #encryptedRespStr-1);
            -- print("encryptedRespStr string sub", encryptedRespStr);
            -- encryptedRespStr = json.decode(encryptedRespStr)
            pcall(function() decryptedResponseStr = AES.Decrypt(encryptedRespStr) end)
            print("encryptedRespStr AES Decrypt", decryptedResponseStr);
        else
            decryptedResponseStr = encryptedRespStr;
        end
        --decryptedResponseStr = string.gsub(decryptedResponseStr, "\3", "")
        if string.sub(decryptedResponseStr,1,5) == "data=" then
            decryptedResponseStr = string.sub(decryptedResponseStr,6,string.len(decryptedResponseStr))
        end
        local content = json.decode(decryptedResponseStr) or decryptedResponseStr

        Tools:DumpTable(content, "response content");

        if varTable.callback then
           return varTable.callback(uwr.responseCode, content, uwr.error);
        end
    end
    if varTable.isLoading then
        GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
    end

    -- local tab = varTable.paramTable
    -- if requestParamString then
    --     tab = {data = requestParamString}
    -- end
    if sync then
       local uwr = HTTPManager:SendHttpRequestSync(
            varTable.url,
            varTable.method or "GET",
            {data = requestParamString},
            headers,
            varTable.timeout or 0
        )
        return cb(uwr)
    else
        HTTPManager:SendHttpRequest(
            varTable.url,
            varTable.method or "GET",
            {data = requestParamString},
            headers,
            cb,
            varTable.timeout or 0
        )
    end
end

function GameNetwork:HTTP_SendRequest(params)
    ---这个现在都没有用到了，hw.3you.com是国内服务器2025-1-10 fy注释
    local url = "http://127.0.0.1:8080/"
    -- if GameConfig:IsDebugMode() then
    --     -- url = "http://47.98.100.225:8080/"
    -- else
    -- if GameConfig:IsLeyoHKVersion() then
    --     url = "http://hw.3yoqu.com/"
    -- elseif GameConfig:IsWarriorVersion() then
    --     url = "http://hw.3yoqu.com/"
    -- end
    -- local request = {
    --     url = url..params.url,
    --     method = "POST",
    --     paramTable = params.msg,
    --     timeout = 20,
    --     isLoading = params.isLoading,
    --     callback = function(statusCode, content, errstr)
    --         if (tonumber(statusCode) ~= 200 or (content.code and content.code ~= 200)) then 
    --             if params.errorCallback then
    --                 params.errorCallback(content, statusCode)
    --             end
    --         elseif params.callback then
    --             params.callback(content)
    --         end
    --     end
    -- }
    -- GameNetwork:HTTPRequest(request)
end

function GameNetwork:HTTP_PublicSendRequest(url, params, isSync, method, enableEncrypt, headers, timeout)
    local request = {
        url = url,
        method = method or "POST",
        paramTable = params.msg,
        timeout = timeout or 0,
        isLoading = params.isLoading,
        fullMsgTalbe = params.fullMsgTalbe,
        enableEncrypt = enableEncrypt and true or false,
        callback = function(statusCode, content, errstr)
            if not content or (tonumber(statusCode) ~= 200 or (type(content) == "table" and type(content.code) == "number" and (content.code ~= 200 and content.code ~= 0))) then 
                if params.errorCallback then
                    return params.errorCallback(content, statusCode)
                end
            elseif params.callback then
                return params.callback(content)
            end
        end
    }
    return GameNetwork:HTTPRequest(request, isSync, headers)
end


