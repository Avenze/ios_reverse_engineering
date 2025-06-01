--[[
    用于新版活动存档相关数据保存以及管理的对象类
]]

GActivityFileSysMgr = 
{
    m_currentVer = "1.0.0"
}

local AES = CS.Common.Utils.AES
local rapidjson = require("rapidjson")
local persistentPath = CS.UnityEngine.Application.persistentDataPath
local UnityHelper = CS.Common.Utils.UnityHelper
local encryptTag = UnityHelper.GetMD5("The Best Property Tag 1.0.0")
local StateManager = GameStateManager

function GActivityFileSysMgr:LoadFile(fileName)
    local filePath = persistentPath .."/"..fileName
    print("Load Activity file:->", filePath)

    if fileName == "ActivitySQL" then
        local checkFile = io.open(filePath, "r")
        if checkFile then
           ActivityFileDataManager.hasOldData = true
           checkFile:close() 
        end
    end
    local file = io.open(filePath, "a+")
    if file then
        file:seek("set", 0)
        local str = file:read("*a")
        file:close()
        if "" == str and ActivityFileDataManager.hasOldData and fileName == "ActivitySQL" then
            -- TODO：是否有更新错误的日志记录
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
            if (data == nil or str == "") and ActivityFileDataManager.hasOldData and fileName == "ActivitySQL" then
                -- TODO：是否上传更新错误的日志记录
            end
        end,
        function (error)
            if fileName ~= "ActivitySQL" then return end

        end)
        return Tools:CopyTable(data)
    else
        print("Unable to open file:", filePath)
    end
end

function GActivityFileSysMgr:SaveFile(saveFileName, saveTableData, saveTableName)
    if StateManager.m_statePause then
        return 
    end
    local filePath = persistentPath.."/"..saveFileName
    local isDebugMode = GameConfig:IsDebugMode()
    saveTableData.table_name = saveTableName

    local str = rapidjson.encode(saveTableData, {pretty = isDebugMode, sort_keys = isDebugMode})
    if (str == nil or str == "") and saveFileName == "ActivitySQL" then
        --TODO：是否有更新错误的日志记录:
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
end

function GActivityFileSysMgr:SaveBrokenData(key, errorStr)
    local filePath = persistentPath .. "/ERROR"
    local data = self:GetBrokenData() or {}
    if key then
        data[key] = nil
    else
        local md5 = UnityHelper.GetMD5(errorStr)
        data[md5] ={content = errorStr, time = tostring(GameTimeManager:GetCurrentServerTime())}
    end
    local file = io.open(filePath, 'w+')
    if file then
        file:write(rapidjson.encode(data, {pretty = false, sort_keys = false}))
        file:close()
    end
end

function GActivityFileSysMgr:GetBrokenData()
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