GfileSystemMgr = {
    m_currentSaveVer = "1.0"
}
local AES = CS.Common.Utils.AES
local rapidjson = require("rapidjson")
local persistentPath = CS.UnityEngine.Application.persistentDataPath
local UnityHelper = CS.Common.Utils.UnityHelper
local encryptTag = UnityHelper.GetMD5("The Best Property Tag 1.0.0")
local StateManager = GameStateManager
local DeviceUtil = CS.Game.Plat.DeviceUtil

function GfileSystemMgr:LoadFile(fileName)
    local filePath = persistentPath .. "/" .. fileName
    print("Load local file:->", filePath)

    if fileName == "SQL" then
        local checkFile = io.open(filePath, "r")
        if checkFile then
            LocalDataManager.hasOldData = true
            checkFile:close()
        end
    end

    local file = io.open(filePath, "a+")
    if file then
        file:seek("set", 0)
        local str = file:read("*a")
        file:close()
        if "" == str and LocalDataManager.hasOldData and fileName == "SQL" then
            GameSDKs:UploadErrorInfo("warrior_response", {uid="open_sql_fail", sql=str})
            return
        end

        local data = nil
        xpcall(function() 
            local hasTag = string.find(str, encryptTag)
            if hasTag then
                str = string.gsub(str, encryptTag, "")
                str = AES.Decrypt(str)
            end
            data = rapidjson.decode(str)
            if (data == nil or str == "") and LocalDataManager.hasOldData and fileName == "SQL" then
                GameSDKs:UploadErrorInfo("warrior_response", {uid="decode_json_fail", json=str})
            end
        end,function(error)
            if fileName ~= "SQL" then return end
            GameSDKs:TrackForeign("login", {login_type = "游客", login_result = 999})
            GameSDKs:UploadErrorInfo("warrior_response", {uid="aes_fail", aes = str})
            -- print(error, debug.traceback("Broken Data"))
        end)
        return Tools:CopyTable(data)
    else
        print("Unable to open file: ", filePath)
    end
end

function GfileSystemMgr:SaveFile(saveFileName, saveTableData, saveTableName, highProperty)
    if self.m_lastSaveTime and not highProperty then
        if GameTimeManager:GetCurServerOrLocalTime() - self.m_lastSaveTime  < 60 then
            return
        end
    end
    
    if StateManager.m_statePause and not highProperty then
        return
    end

    pcall(function()
        --local startTime = CS.System.DateTime.Now.Ticks
        LocalDataManager:RestoreTableBeforeSaveFile()
        --local endTime = CS.System.DateTime.Now.Ticks
        --local costTime = endTime - startTime
        --CS.UnityEngine.Debug.Log("LocalDataManager:RestoreTableBeforeSaveFile(saveTableData) timeCost:"..tostring(costTime))
    end)
    local filePath = persistentPath .. "/" .. saveFileName
    local isDebugMode = GameConfig:IsDebugMode()
    saveTableData.table_name = saveTableName

    local str = rapidjson.encode(saveTableData, {pretty = isDebugMode, sort_keys = isDebugMode})
    if (str == nil or str == "") and saveFileName == "SQL" then
        GameSDKs:TrackForeign("login", {login_type = "游客", login_result = 999 })
        GameSDKs:UploadErrorInfo("warrior_response", {uid="encode_json_fail", json=str})
        return
    end
    if not isDebugMode then
        str = AES.Encrypt(str)..encryptTag
    end
    
    local file = io.open(filePath, 'w+')
    if file then
        file:write(str)
        file:close()
    end
    str = nil
    collectgarbage("collect")
    self.m_lastSaveTime = GameTimeManager:GetCurServerOrLocalTime()
end

function GfileSystemMgr:SaveBrokenData(key, errorStr)
    local filePath = persistentPath .. "/ERROR"
    local data = self:GetBrokenData() or {}

    if key then
        data[key] = nil
    else
        local md5 = UnityHelper.GetMD5(errorStr)
        data[md5] = {content = errorStr, time = tostring(GameTimeManager:GetCurrentServerTime())}
    end
    local file = io.open(filePath, 'w+')
    if file then
        file:write(rapidjson.encode(data, {pretty = false, sort_keys = false}))
        file:close()
    end
end

function GfileSystemMgr:GetBrokenData()
    local filePath = persistentPath .. "/ERROR"
    local file = io.open(filePath, "a+")
    local str = ""
    if file then
        file:seek("set", 0)
        str = file:read("*a")
        file:close()
    end

    local data = nil
    if str and "" ~= str then
        data = rapidjson.decode(str)
    end
    return data
end

