

ExceptionHandler = {
	isSendingException = false,
	earliestTime = nil,
	saveFileName = "EXCEP"
}

local LuaException = nil
local GfileSysMgr = nil

local ExceptionManager = CS.Common.Utils.ExceptionManager.Instance;
local UnityHelper = CS.Common.Utils.UnityHelper
local rapidjson = require("rapidjson")

local MassageTable = {}
---记录已经发送过的报错信息，不发第二遍减少服务器压力
local SentMessage = {}

function ExceptionHandler:Init()
	GfileSysMgr = GfileSystemMgr
	self:LoadLuaException()
	self.version = CS.UnityEngine.Application.version
	self.bundleId = GameDeviceManager:GetAppBundleIdentifier()
	ExceptionManager:SetExceptionCallback(function(logString, stackTrace)
		-- if _debug_xpCall then
		-- 	_debug_xpCall()
		-- end
		ExceptionHandler:AddLuaException(logString .. (stackTrace or ""))
	end)
end

function ExceptionHandler:LoadLuaException()
	LuaException = GfileSysMgr:LoadFile(self.saveFileName)
	if LuaException == nil then
		LuaException = {
			['RD_VER'] = '1.0',
			['info'] = {}
		}
	end
end

function ExceptionHandler:SaveLuaException()
	local save = Tools:CopyTable(LuaException)
	GfileSysMgr:SaveFile(self.saveFileName, save, "LuaException")
end

function ExceptionHandler:AddLuaException(content)
	if luaIdePrintErr then
		luaIdePrintErr(content)
	end
	if not GameConfig.enableLuaException then
		return
	end
	if false and GameConfig:IsDebugMode() then
		if not LuaException then
			ExceptionHandler:LoadLuaException()
		end
		local currentTime = GameTimeManager:GetDeviceTime()

		--if not self.earliestTime then
		--	self.earliestTime = 0
		--end

		if not LuaException.info then
			LuaException.info = {}
		end

		local md5 = UnityHelper.GetMD5(content)
		if not md5 then
			return
		end

		if not LuaException.info[md5] then
			LuaException.info[md5] = {}
		end
		LuaException.info[md5].exception = content
		LuaException.info[md5].time = currentTime
		LuaException.info[md5].count = (LuaException.info[md5].count or 0) + 1
		self:SaveLuaException()
	else

		--记录已经发送过的报错信息，不发第二遍减少服务器压力
		if SentMessage[content] then
			return
		end
		SentMessage[content] = true

		--local massage = MassageTable
		--massage.stack_trace = content
		--massage.time = self:GetUTCTime()
		--massage.user_id = GameSDKs:GetCurUserID()
		--massage.version = self.version
		--massage.bundle_id = self.bundleId

		--TODO 暂时使用埋点服务器来接收错误日志
		--GameSDKs:ReportException(massage.user_id, massage.time, rapidjson.encode(massage))

		local userID = GameSDKs:GetCurUserID()
		GameSDKs:TrackForeign("error",{userid = userID,log = content})
	end
end

function ExceptionHandler:GetUTCTime()

	local utc_timestamp = os.time()
	local timezone = os.date("%z", utc_timestamp)  -- 获取时区信息
	local utc_date_str = os.date("!%Y-%m-%d %H:%M:%S", utc_timestamp)  -- 获取 UTC 时间字符串

	local date_str_with_timezone = timezone .. " " .. utc_date_str  -- 将时区信息添加到 UTC 时间字符串前面

	return date_str_with_timezone
end

function ExceptionHandler:SyncLuaExceptionToServer()
	-- local requestParam = {
	-- 	type = 'client_errors',
	-- 	data = LuaTools:CopyTable(LuaException.info),
	-- }

	-- local domainName = RecordData.data_center

	-- if domainName then
	-- 	GameNetwork.HTTP.SendRequest({
	-- 		url = domainName .. "/gather/client",
	-- 		method = "POST",
	-- 		param = requestParam,
	-- 		enableEncrypt = false,
	-- 		callback = function(statusCode, content, errstr)
	-- 			LuaException.info = {}
	-- 			LuaException.earliestTime = nil
	-- 			self:SaveLuaException()
	-- 			self.isSendingException = false
	-- 		end
	-- 	})
	-- end
end

function ExceptionHandler:GetUploadingAddr()

end

function ExceptionHandler:TryToSendLuaException()
	-- if not GameConfig:IsExceptionCollectingEnabled() then
	-- 	return
	-- end
	-- if not LuaException then
	-- 	ExceptionHandler:LoadLuaException()
	-- end

	-- if self.isSendingException then
	-- 	return 
	-- end

	-- local INTERVAL_OF_SENDING = 300
	-- local currentTime = GameTimeManager:GetDeviceTime()
	-- local interval = INTERVAL_OF_SENDING

	-- if self.earliestTime then 
	-- 	interval = currentTime - self.earliestTime
	-- end

	-- if interval >= INTERVAL_OF_SENDING and self:HasException() then
	-- 	self.isSendingException = true
	-- 	self:SyncLuaExceptionToServer()
	-- end
end

function ExceptionHandler:HasException()
	if LuaException then
		local exceptionCount = Tools:GetTableSize(LuaException.info)
		return exceptionCount > 0
	else
		return false
	end
end

function ExceptionHandler:GetException()
	return LuaException or {}
end