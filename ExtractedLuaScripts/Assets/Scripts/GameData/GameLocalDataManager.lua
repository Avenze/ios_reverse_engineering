

GameLocalDataManager = {}

function GameLocalDataManager:Init()
	GameRecordData = nil
	GfileSystemMgr:LoadFile("SQL");
	if not GameRecordData then
		GameRecordData = {
			['RD_VER'] = '1.0',
		}
	end
	
	Tools:DumpTable(GameRecordData, "GameLocalDataManager");
end

function GameLocalDataManager:GetGeneralSettingRecord()
	if not GameRecordData.GENERAL_SETTING then
		GameRecordData.GENERAL_SETTING = {}
	end
	return GameRecordData.GENERAL_SETTING
end

function GameLocalDataManager:GetCurrentUserSave()
	local userID = GameRecordData.userID
	local roleID = GameRecordData.roleID
	if not userID or not roleID then
		return 
	end

	if not GameRecordData.record then
		GameRecordData.record = {}
	end

	if not GameRecordData.record[roleID] and roleID ~= "" then
		GameRecordData.record[roleID] = {}
	end

	if GameRecordData.record[userID]
		and next(GameRecordData.record[userID])
		and roleID
		and roleID ~= "" then
		local roleID = GameRecordData.roleID
		GameRecordData.record[roleID] = LuaTools:CopyTable(GameRecordData.record[userID])
		GameRecordData.record[userID] = nil
		self:WriteToFile()
		return GameRecordData.record[roleID] or {}
	end

	if roleID == "" then
		roleID = nil
	end
	return GameRecordData.record[roleID or userID] or {}
end

function GameLocalDataManager:Save(key, value)
	local userData = self:GetCurrentUserSave()
	if not userData then
		return 
	end
	userData[key] = value
	self:WriteToFile()
end

function GameLocalDataManager:SaveGeneralSetting(key, value)
	local record = GameLocalDataManager:GetGeneralSettingRecord()
	record[key] = value
	self:WriteToFile()
end

function GameLocalDataManager:WriteToFile()
	GfileSystemMgr:SaveFile("SQL", GameRecordData, "GameRecordData")
end

function GameLocalDataManager:GetLastLoginTime()
	local userData = self:GetCurrentUserSave()
	if userData then
		return userData.LAST_LOGIN_TIME
	end
end
function GameLocalDataManager:GetCurDayLoginTimes()
	local userData = self:GetCurrentUserSave()
	if userData then
		return userData.CUR_DAY_LOGIN_TIMES or 1
	end
	return 1
end
function GameLocalDataManager:ClearUserSave()
	local userSave = GameLocalDataManager:GetCurrentUserSave()
	userSave = {}
	-- self:WriteToFile()
	GfileSystemMgr:SaveFile("SQL", GameRecordData, "GameRecordData", true)
end

function GameLocalDataManager:UpdateServerName(server_name)
	GameRecordData.server_name = server_name
	self:WriteToFile()
end