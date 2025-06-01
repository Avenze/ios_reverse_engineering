---@class LocalDataManager
LocalDataManager = {}
local LocalDataManager = LocalDataManager

local EventManager = require("Framework.Event.Manager")

local RecordData = nil
local saveTag = nil
local GfileSysMgr = nil
local AES = CS.Common.Utils.AES
local rapidjson = require("rapidjson")
local GameResMgr = require("GameUtils.GameResManager")

local CityMode = GameTableDefine.CityMode
local ConfigMgr = GameTableDefine.ConfigMgr

local curRecordVerson = '1.1'
local UnityHelper = CS.Common.Utils.UnityHelper
local encryptTag = UnityHelper.GetMD5("The Best Property Tag 1.0.0")
local PWDFieldTag = "PWD_"
local PWDFieldTagLen = #PWDFieldTag
---@type table<string,string>
local PWDFieldNameDic = {}
---@type table<string,boolean>
---记录哪些数据经过了加密
local PWDFieldInfoList = {}

local GameLanucher = CS.Game.GameLauncher.Instance
function LocalDataManager:Init()
	GfileSysMgr = GfileSystemMgr
	RecordData = GfileSysMgr:LoadFile("SQL")
	if not RecordData then
		RecordData = {
			version = curRecordVerson,
			record = {},
		}
	else
		local userData = LocalDataManager:GetDataByKey("user_data")
		local loginType = userData["cur_type"] or "1"
		if userData and not userData["fb_id"] then
			if userData["third_account"] and userData["third_account"][loginType] then
				userData["fb_id"] = userData["third_account"][loginType]
				self:WriteToFileInmmediately()
			end
		end
	end
	-- if tonumber(RecordData.version or "1.0") < tonumber(curRecordVerson) then
		RecordData.version = curRecordVerson
		local key, v = next(RecordData.record or {})

		--print("--------->", _, v.boss_skin, v.boss_name, v.building_name, v.city_record_data.currBuidlingId, v.boss_skin == nil and v.boss_name == nil and v.building_name == nil and v.city_record_data and v.city_record_data.currBuidlingId == 100)
		if v and v.boss_skin == nil and v.boss_name == nil and v.building_name == nil and v.city_record_data and v.city_record_data.currBuidlingId == 100 then
			-- RecordData.record = nil
			local oldUserData = nil
			if v.user_data then
				oldUserData = Tools:CopyTable(v.user_data)
			end
			RecordData.record[key] = {}
			if oldUserData then
				RecordData.record[key].user_data = Tools:CopyTable(oldUserData)
			end
			self:InitRecordContent(RecordData.record[key])
			self.WriteToFile()
		end
	-- end
	GameTableDefine.ChatUI:ClearChatLocalData()
	-- if ConfigMgr.config_global.enable_iap == 1 and GameSDKs.isDownLoadingOnLogin then
	-- 	LocalDataManager:DownLoadLocalData()
	-- end
	-- Tools:DumpTable(RecordData, "LocalDataManager")
end

---@private 数字转成加密字符串
---@return string
function LocalDataManager:EncryptFromNumToString(num)
	local result = AES.Encrypt(tostring(num))
	return result
end

---@private从加密字符串中获取数字
---@return number
function LocalDataManager:DecryptFromStringToNum(content)
	local tmpStr = AES.Decrypt(content)
	local result = tonumber(tmpStr)
	return result or 0
end

---获取fieldName对应的PWDFieldName,减少每次生成临时字符串的GC
function LocalDataManager:GetPWDFieldName(fieldName)
	local pwdFiledName = PWDFieldNameDic[fieldName]
	if not pwdFiledName then
		pwdFiledName = PWDFieldTag..fieldName
		PWDFieldNameDic[fieldName] = pwdFiledName
	end
	return pwdFiledName
end

---@public
---加密sourceTable中的字段,加密后的字段名为PWD_开头
---@param sourceTable table
---@param fieldName string
---@param value number
function LocalDataManager:EncryptField(sourceTable,fieldName,value)
	sourceTable[self:GetPWDFieldName(fieldName)] = self:EncryptFromNumToString(value)
	--缓存加密table field信息,用于在存档时恢复原始数据
	local pwdInfo = PWDFieldInfoList[sourceTable]
	if not pwdInfo then
		pwdInfo = {}
		PWDFieldInfoList[sourceTable] = pwdInfo
	end
	if not pwdInfo[fieldName] then
		pwdInfo[fieldName] = true
	end
end

---解密sourceTable中的字段,有对应PWD_[fieldName]就使用PWD_[fieldName],否则使用fieldName的值
---@param sourceTable table
---@param fieldName string
function LocalDataManager:DecryptField(sourceTable,fieldName)
	local content = sourceTable[self:GetPWDFieldName(fieldName)]
	local value = nil
	if content then
		value = self:DecryptFromStringToNum(content)
	else
		value = sourceTable[fieldName]
		--在内存中创建加密字段
		self:EncryptField(sourceTable,fieldName,value)
	end
	return value or 0
end

---@private
---是否有加密数据特征，由PWD_开头
function LocalDataManager:IsDecryptFiled(key)
	if type(key) == "string" then
		local keyLen = #key
		if keyLen > PWDFieldTagLen then
			return string.sub(key,1,PWDFieldTagLen) == PWDFieldTag
		end
	end
	return false
end

--@public 读取存档后将原始数据覆盖加密数据，以备使用
--function LocalDataManager:InitTableAfterLoadFile(targetTable)
--	for k,v in pairs(targetTable) do
--		if self:IsDecryptFiled(k) then
--			local value = self:DecryptFromStringToNum(v)
--			local fieldName = string:sub(k,PWDFieldTagLen,#k-PWDFieldTagLen)
--			targetTable[fieldName] = value
--		end
--	end
--end

---@public
---将存档保存到本地前先将加密数据还原并覆盖原始数据
function LocalDataManager:RestoreTableBeforeSaveFile()
	for sourceTable,fieldDic in pairs(PWDFieldInfoList) do
		for fieldName,v in pairs(fieldDic) do
			local pwdFieldName = self:GetPWDFieldName(fieldName)
			local content = sourceTable[pwdFieldName]
			if content then
				local realValue = self:DecryptFromStringToNum(content)
				sourceTable[fieldName] = realValue
			end
		end
	end
end

--@public
--将存档保存到本地前先将加密数据还原并覆盖原始数据
--function LocalDataManager:RestoreTableBeforeSaveFile(targetTable,deep)
--	deep = deep and (deep+1) or 1
--	if deep>3 then ---最多4层
--		return
--	end
--	--加密数据还原到原始数据上
--	local encryptFiledNames = nil
--	for k,v in pairs(targetTable) do
--		if type(v) == "table" then
--			--递归子表
--			self:RestoreTableBeforeSaveFile(v)
--		elseif self:IsDecryptFiled(k) then
--			local value = self:DecryptFromStringToNum(v)
--			local fieldName = string.sub(k,PWDFieldTagLen+1)
--			targetTable[fieldName] = value
--			encryptFiledNames = encryptFiledNames or {}
--			table.insert(encryptFiledNames,k)
--		end
--	end
--	--删除不需要的加密数据
--	if encryptFiledNames then
--		for i,v in ipairs(encryptFiledNames) do
--			targetTable[encryptFiledNames[i]] = nil
--		end
--	end
--end

function LocalDataManager:HasInit()
	return RecordData ~= nil and RecordData.record ~= nil
end

function LocalDataManager:Update()
	if saveTag then
		GfileSysMgr:SaveFile("SQL", RecordData, "RecordData")
		saveTag = false
	end
end

function LocalDataManager:WriteToFileInmmediately()
	GfileSysMgr:SaveFile("SQL", RecordData, "RecordData", true)
end

function LocalDataManager:UpdateLoadLocalData(cb)
	local record = GameSDKs:InitLoginAccountInLocalData() 
	if not record then
		return
	end

	local id,uploadData =next(record)
	local requestTable = {
		url = GameConfig:IsLeyoHKVersion() and "hk_upload_data" or "upload_data",
		msg = {
			game_data = record,
			data_id = id,
			wx_id = GameSDKs.m_accountId,
		},
		callback = function(response)
			local data = LocalDataManager:GetDataByKey("user_data")
			data.save_time = response.timePoint or GameTimeManager:GetDeviceTimeInMilliSec()
			if not data.user_id then data.user_id = response.userId end
			LocalDataManager:WriteToFile()
			if cb then cb() end
		end,
		errorCallback = function(response)
			if cb then cb(true) end
		end,
	}

	if GameConfig:IsWarriorVersion() then
		if GameConfig:UseWarriorOldAPI() then
			local url = GameNetwork.GAEM_DATA_URL
			requestTable.msg.data = AES.Encrypt(rapidjson.encode(requestTable.msg.game_data))
			requestTable.msg.appId = GameNetwork.HEADR["X-WRE-APP-ID"]
			requestTable.msg.uuid = tostring(GameSDKs.m_accountId)
			requestTable.msg.game_data = nil
			requestTable.msg.data_id = nil
			requestTable.isLoading = true
			requestTable.fullMsgTalbe = true
			GameNetwork:HTTP_PublicSendRequest(url, requestTable, true, nil, nil, GameNetwork.HEADR)
		else
			requestTable.url = GameSDKs.GAEM_DATA_URL
			requestTable.data = AES.Encrypt(rapidjson.encode(requestTable.msg.game_data))
			requestTable.msg = nil
			GameSDKs:Warrior_request(requestTable)
			if requestTable.data == nil or requestTable.data == "" then
				GameSDKs:UploadErrorInfo("warrior_response", {uid = "game_data_up_nil", rkey = id})
			end
		end
	else
		GameNetwork:HTTP_SendRequest(requestTable)
	end
end

-- 手动替换存档调用
function LocalDataManager:DownLoadLocalData(restartGame)
	local data = LocalDataManager:GetDataByKey("user_data")
	if not RecordData.record or (not GameSDKs:GetThirdAccountInfo()) then
		return
	end
	
	local requestTable = {
		url = "download_data",
		msg = {wx_id = GameSDKs:GetThirdAccountInfo()},
		callback = function(response)
			local id,data = next(RecordData.record)
			self:ReplaceLocalData(response.gameData or response.game_data or response)
			if restartGame then
				GameSDKs:UploadErrorInfo("warrior_response", {uid="touch_download"})
				-- CS.UnityEngine.Application.Quit()
				UnityHelper.ApplicationQuit()
			end
		end,
		errorCallback = function()
			EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_CLOUDSTORAGE_DOWNLOAD_FALL"))
		end,
	}
	if GameConfig:IsWarriorVersion() then
		if GameConfig:UseWarriorOldAPI() then
			local url = GameNetwork.GAEM_DATA_URL
			requestTable.msg.appId = GameNetwork.HEADR["X-WRE-APP-ID"]
			requestTable.msg.uuid = GameSDKs:GetThirdAccountInfo()
			requestTable.isLoading = true
			requestTable.fullMsgTalbe = true
			GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
			GameNetwork:HTTP_PublicSendRequest(url, requestTable, true, "GET", nil, GameNetwork.HEADR)
		else
			requestTable.msg = nil
			requestTable.url = GameSDKs.GAEM_DATA_URL
			GameSDKs:Warrior_request(requestTable)
		end
	else
		GameNetwork:HTTP_SendRequest(requestTable)
	end
end

--没有保存账号id或者账号id跟登录账号不一致才会调用
function LocalDataManager:LoginDownLoadLocalData(id, cb)
	if not id then
		return
	end
	local requestTable = {
		url = "download_data",
		msg = {wx_id = id},
		callback = function(response)
			GameSDKs:TrackForeign("init", {init_id = 18, init_desc = "服务器返回存档请求"})
			local newData = response.gameData or response.game_data or response
			if not newData or newData == "" then --新账号无存档
				if self.hasOldData then
					GameSDKs:UploadErrorInfo("warrior_response", {uid="lost_data"})
				end
				self:UpdateLoadLocalData(cb)
				return
			end

			newData = string.gsub(newData,"%%2B","+")
			local newDataTable = rapidjson.decode(AES.Decrypt(newData)) -- 解码直接替换
			RecordData.record = newDataTable
			--userid也需要同步进行修改
			local userData = LocalDataManager:GetDataByKey("user_data")
			userData["fb_id"] = id
			if GameSDKs.m_loginType then
				if not userData.third_account then
					userData.third_account = {}
				end
				userData.third_account[GameSDKs.m_loginType] = id
			end
			self:WriteToFile()
			self:Update()
			if cb then cb() end
		end,
		errorCallback = function(error)
			if error.message == "download data failed" then --港澳台新账号无存档
				self:UpdateLoadLocalData(cb)
			else
				EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_CLOUDSTORAGE_DOWNLOAD_FALL"))
				if cb then cb(true) end -- 错误或者服务器崩溃
				-- self:LoginDownLoadLocalData(id, cb)
			end
		end,
	}
	if GameConfig:IsWarriorVersion() then
		GameSDKs:TrackForeign("init", {init_id = 17, init_desc = "服务器存档请求发送"})
		GameTableDefine.LoadingScreen:SetLoadingMsg("服务器存档请求发送")
		GameLanucher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_2"))
		if GameConfig:UseWarriorOldAPI() then
			local url = GameNetwork.GAEM_DATA_URL
			requestTable.msg.appId = GameNetwork.HEADR["X-WRE-APP-ID"]
			requestTable.msg.uuid = id
			requestTable.isLoading = true
			requestTable.fullMsgTalbe = true
			GameNetwork:HTTP_PublicSendRequest(url, requestTable, true, "GET", nil, GameNetwork.HEADR)
		else
			requestTable.msg = nil
			requestTable.url = GameSDKs.GAEM_DATA_URL
			GameSDKs:Warrior_request(requestTable)
		end
	else
		GameNetwork:HTTP_SendRequest(requestTable)
	end
end

function LocalDataManager:IsNewPlayerRecord()
	local data = self:GetCurrentRecord()
	return data.new_record
end

function LocalDataManager:ClearNewPlayerRecord(bossSkin)
	local data = self:GetCurrentRecord()
	data.new_record = nil
	data.boss_skin = bossSkin
	self:WriteToFile()
end

function LocalDataManager:SaveBuildingName(name)
	local data = self:GetCurrentRecord()
	data.building_name = name
	self:WriteToFile()
	-- self:WriteToFileInmmediately()
end

function LocalDataManager:GetBuildingName()
	local data = self:GetCurrentRecord()
	return data.building_name
end

function LocalDataManager:SaveBossName(name)
	local data = self:GetCurrentRecord()
	data.boss_name = name
	self:WriteToFile()
end

function LocalDataManager:GetBossSkin()
	local data = self:GetCurrentRecord()
	local skin = data.boss_skin or ConfigMgr.config_global.boss_skin[CityMode.m_currSkin or 1]
	if skin == "Boss_003" then
		skin = "Boss_001"
	end
	return skin
end

function LocalDataManager:GetBossName()
	local data = self:GetCurrentRecord()
	return data.boss_name
end

function LocalDataManager:GetBossSex()
	local skin = self:GetBossSkin()
	if skin == "Boss_002" then
		return 2 --女
	end
	return 1 --男
end

function LocalDataManager:GetGeneralSettingRecord()
	if not RecordData.GENERAL_SETTING then
		RecordData.GENERAL_SETTING = {}
	end
	return RecordData.GENERAL_SETTING
end

function LocalDataManager:GetCurrentRecord()
	if not RecordData then
		return nil
	end
	if not RecordData.record then
		RecordData.record = {}
	end

	if Tools:GetTableSize(RecordData.record) <= 0 then
		local time = tostring(GameTimeManager:GetCurrentServerTime())
		RecordData.record[time] = {}
		self:InitRecordContent(RecordData.record[time])
		self:WriteToFile()
		return RecordData.record[time]
	else
		for k,v in pairs(RecordData.record) do
			return v
		end
	end
end

function LocalDataManager:GetRootRecord()
	return RecordData and RecordData.record
end
function LocalDataManager:InitRecordContent(record)
	record.record_name = "record 1"
	record.new_record = true
end

function LocalDataManager:Save(key, value)
	local userData = self:GetCurrentRecord()
	if not userData then
		return 
	end
	userData[key] = value
	self:WriteToFile()
end

function LocalDataManager:SaveGeneralSetting(key, value)
	local record = self:GetGeneralSettingRecord()
	record[key] = value
	self:WriteToFile()
end

function LocalDataManager:WriteToFile()
	-- GfileSysMgr:SaveFile("SQL", RecordData, "RecordData")
	saveTag = true
end

function LocalDataManager:GetLastLoginTime()
	local userData = self:GetCurrentRecord()
	if userData then
		return userData.LAST_LOGIN_TIME
	end
end
function LocalDataManager:GetCurDayLoginTimes()
	local userData = self:GetCurrentRecord()
	if userData then
		return userData.CUR_DAY_LOGIN_TIMES or 1
	end
	return 1
end
function LocalDataManager:ClearUserSave()
	RecordData = {
		['version'] = curRecordVerson,
	}
	-- self:WriteToFile()
	-- self:Update()
	self:WriteToFileInmmediately()
	local Instance = CS.UnityEngine.UI.LocalizationManager.Instance
	if Instance.ClearAppLauncherText then
		Instance:ClearAppLauncherText()
	end
end

function LocalDataManager:ReplaceLocalData(newData)
	if not newData or newData == "" then
		return
	end

	print("==ReplaceLocalData", newData)
	newData = string.gsub(newData,"%%2B","+")
	local newDataTable = rapidjson.decode(AES.Decrypt(newData))
	RecordData.record = newDataTable
	self:WriteToFile()
	self:Update()
end

function LocalDataManager:ReplaceLocalDataByGM(newData)
	if not newData or newData == "" then
		return
	end

	print("==ReplaceLocalData", newData)
	-- newData = string.gsub(newData,"%%2B","+")
	-- local newDataTable = rapidjson.decode(AES.Decrypt(newData))
	local userData = nil
	local tmpData = nil
	for key1, tmpV in pairs(newData.record) do
		if tonumber(key1) then
			tmpData = tmpV
		end
	end
	for key, v in pairs(RecordData.record) do
		if tonumber(key) and tmpData then
			tmpData.user_data = v.user_data
			RecordData.record[key] = tmpData
		end
	end
	-- local userData = RecordData.record
	-- RecordData.record = newData.record
	-- RecordData.record.user_data = userData
	self:WriteToFileInmmediately()
end

function LocalDataManager:GetDataByKey(key)
	local data = self:GetCurrentRecord()
	if not data then
		return 
	end
	if not data[key] then
		data[key] = {}
		self:WriteToFile()
	end
	return data[key]
end

function LocalDataManager:ReplaceRecordData(data)
	if not data then
		return
	end
	RecordData = data
	self:WriteToFile()
	self:Update()
end

function LocalDataManager:UploadWarriorDataBackups(str, ignoreUpdate)
    xpcall(
        function()
			if not GameSDKs.m_accountId or not GameNetwork.HEADR.P then
				return
			end
	
			local key, v = next(RecordData.record or {})
			local hasPurchasing = false
				-- 内购记录缓存
			if Tools:GetTableSize(v.warrior_order or {}) > 0 then
				hasPurchasing = true
			end
			-- 间隔2小时
			if not ignoreUpdate and v.data_backups_time and (GameTimeManager:GetCurrentServerTime() - v.data_backups_time > (60 * 60 * 2)) then
				return
			end
			-- v = AES.Encrypt(rapidjson.encode(v))
            local requestTable = {
                url = "warrior_data",
                msg = {
                    userId = GameSDKs.m_accountId,
                    data = AES.Encrypt(rapidjson.encode(v)),
                    key = key,
                    platform = GameNetwork.HEADR.P,
                    version = CS.UnityEngine.Application.version,
                    timestamp = GameTimeManager:GetCurrentServerTime(),
					hasPurchasing = hasPurchasing,
                },
                callback = function(response)
                	-- Tools:DumpTable(response, "respone")
					v.data_backups_time = GameTimeManager:GetCurrentServerTime()
                end,
            }
            GameNetwork:HTTP_SendRequest(requestTable)
        end,
        function(error)
        end
    )
end

function LocalDataManager:ReplaceLocalDataByConfig(num)
	local AsyncOperationStatus = CS.UnityEngine.ResourceManagement.AsyncOperations.AsyncOperationStatus

	local accountCfg = ConfigMgr.config_account[num]
	print(accountCfg.desc, accountCfg.id)
	local path = "Assets/Res/account_data/".. accountCfg.data ..".txt"
	local refer = nil
	local handler = GameResMgr:LoadTxtSyncFree(path, refer)
	if handler.Status == AsyncOperationStatus.Failed then
	    return
	end
	local str = handler.Result
	str = str.text

	local hasTag = string.find(str, encryptTag)
	if hasTag then
		str = string.gsub(str, encryptTag, "")
	end
	xpcall(function()
		str = AES.Decrypt(str)
	end, function(error)
	end)
	print(str)
	
	data = rapidjson.decode(str)
	if (data == nil or str == "")then
		error("decode_json_fail")
	end
	if not data.version then
		data.version = curRecordVerson
	end
	if not data.table_name then
		data.table_name = "RecordData"
	end
    local newDataID = nil
	if not data.record then
		local pair = {}
		for k, v in pairs(data) do
			if k ~= "version" and k ~= "table_name" then
				pair.k = k
				pair.v = v
				break
			end
		end
		data[pair.k] = nil
		data.record = {}
		data.record[pair.k] = pair.v
		id = pair.k
	else
		for k, v in pairs(data.record) do
			id = k
		end
	end
	data.record[id].user_data = self:GetDataByKey("user_data")
	RecordData = data
	self:WriteToFileInmmediately()
	CS.UnityEngine.Application.Quit()
end

---@class RemoteConfigSaveData
---@field group string
---@field endTime number
local RemoteConfigData = {}

---@return RemoteConfigSaveData
function LocalDataManager:GetRemoteConfigData() 
	return self:GetDataByKey("RemoteConfig")
end
