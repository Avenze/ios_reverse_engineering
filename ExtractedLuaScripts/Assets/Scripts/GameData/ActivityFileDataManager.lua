ActivityFileDataManager = {}

local EventManager = require("Framework.Event.Manager")

local ActivityRecordData = nil
local saveTag = nil

local AES = CS.Common.Utils.AES
local rapidjson = require("rapidjson")

local ConfigMgr = GameTableDefine.ConfigMgr

function ActivityFileDataManager:Init()
    ActivityRecordData = GActivityFileSysMgr:LoadFile("ActivitySQL")
    if not ActivityRecordData or Tools:GetTableSize(ActivityRecordData) == 0 then
        ActivityRecordData = {}
        ActivityRecordData.userid = GameSDKs.m_accountId
        ActivityRecordData.activityDatas = {}
        saveTag = true
        self:Update()
    end
end

function ActivityFileDataManager:HasInit()
    return ActivityRecordData ~= nil and ActivityRecordData.userid ~= nil
end

function ActivityFileDataManager:Update()
    if saveTag then
        GActivityFileSysMgr:SaveFile("ActivitySQL", ActivityRecordData, "ActivityRecordData")
        saveTag = false
    end
end
--开启存档开关
function ActivityFileDataManager:WriteToFile()
	-- GfileSysMgr:SaveFile("SQL", RecordData, "RecordData")
	saveTag = true
    self:Update()
end
--获取总的存档
function ActivityFileDataManager:GetActivityRecord()
    if not ActivityRecordData then
        self:Init()
    end
	return ActivityRecordData
end
--通过字段去获取存档的
function ActivityFileDataManager:GetActivityRecordDataByKey(key)
    local data = self:GetActivityRecord()
    if not data then
        return
    end
    if not data[key] then
        data[key] = {}
        self:WriteToFile()
    end
    return data[key]
end