

local Application = CS.UnityEngine.Application;
local RuntimePlatform = CS.UnityEngine.RuntimePlatform;
local SystemInfo = CS.UnityEngine.SystemInfo;
local DeviceType = CS.UnityEngine.DeviceType;
local Screen = CS.UnityEngine.Screen;
-- local GameDevOpt = CS.Game.GameDevOpt;
local GameDefine = CS.Game.GameDefine;
local DeviceInfo = CS.Game.Plat.DeviceInfo;
local DeviceUtil = CS.Game.Plat.DeviceUtil;
local NotificationCenter = CS.Game.Plat.NotificationCenter;
local GameResMgr = require("GameUtils.GameResManager");

GameDeviceManager = {}

local STAGE_WIDTH = 750
local STAGE_HEIGHT = 1334
local UNIVERSAL_RESOURCE_VER = "1.0.0"

print("platform", Application.platform);

local LANGUAGE_FULL_TO_SIMPLE = {

}

ENUM_ASPECT_RATIO = 
{
	R_5_4 	= 1,
	R_4_3 	= 2,
	R_16_9 	= 3,
	R_16_10	= 4,
}

local QualityLevel = {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
}

function GameDeviceManager:Init()
	--if GameConfig:IsJituoVersion() or GameConfig:IsWarStorm2() or GameConfig:IsYunBuIOS() or GameConfig:IsWarStorm3() then
	--	UNIVERSAL_RESOURCE_VER = "1.0.0"
	--end
	self:RegisterLowMemHandler()
	if GameDefine.VersionInfo.SrcStr then
		loadstring(GameDefine.VersionInfo.SrcStr)()
		Tools:DumpTable(VersionInfo, "VersionInfo")
	end
end

function GameDeviceManager:GetDeviceOS()
	if Application.IsEditor then
		return RuntimePlatform.WindowsEditor
	end
	return Application.platform;
end

function GameDeviceManager:IsiOSDevice()
	return self:GetDeviceOS() == RuntimePlatform.IPhonePlayer;
end

function GameDeviceManager:IsAndroidDevice()
	if Application.IsEditor then
		return false
	end
	return self:GetDeviceOS() == RuntimePlatform.Android;
end

function GameDeviceManager:IsWindowsDevice()
	local platform = self:GetDeviceOS();
	return platform == RuntimePlatform.WindowsEditor or platform == RuntimePlatform.WindowsPlayer;
end

function GameDeviceManager:IsMacDevice()
	local platform = self:GetDeviceOS();
	return platform == RuntimePlatform.OSXEditor or platform == RuntimePlatform.OSXPlayer;
end

function GameDeviceManager:IsPCDevice()
	return self:IsWindowsDevice() or self:IsMacDevice();
end

function GameDeviceManager:GetOsVersion()
	return SystemInfo.operatingSystem;
end

function GameDeviceManager:GetAppversion()
	return DeviceInfo.GetAppVersion()
end

function GameDeviceManager:GetResVersion()
	return DeviceInfo.GetResVersion()
end

function GameDeviceManager:IsDebugVersion()
	return GameDefine.VersionInfo.IsDebug
end

function GameDeviceManager:GetAppBundleIdentifier()
	return DeviceInfo.GetAppBundleIdentifier();
end

function GameDeviceManager:GetDeviceScreenSize()
	return Screen.width, Screen.height
end

function GameDeviceManager:GetDeviceCountry()
	return DeviceInfo.GetCountry();
end

function GameDeviceManager:GetDeviceHardwareType()
	return SystemInfo.deviceModel;
end

function GameDeviceManager:GetDeviceLanguage()
	local language = Application.systemLanguage:ToString()
	language = GameLanguage:ConvertToSimple(language)
	return language
end

function GameDeviceManager:GetDeviceUDID()
	return DeviceInfo.GetDeviceUDID()
end

function GameDeviceManager:GetDeviceIDFA()
	return DeviceInfo.GetDeviceIDFA()
end

function GameDeviceManager:PickImage(takeType, callback)
	self.imagePickupCallback = callback
	if GameConfig:IsCustomPortraitUploadingEnabled() then
		if 1 == takeType then
			DeviceUtil.TakePhotoUpload();
		else
			DeviceUtil.PickPhotoUpload();
		end
	end
end

function GameDeviceManager:OnPickupImage(dataStream)
	GameNetwork.HTTP.UploadFile(dataStream, self.imagePickupCallback)
end

function GameDeviceManager:GetGateway()
	local gateway = self:GetValueFromPlist("GameGateway")
	return gateway
end

function GameDeviceManager:GetValueFromPlist(key)
	if self:IsiOSDevice() or self:IsAndroidDevice() then
		return nil
	end
end

function GameDeviceManager:LimitFPSto30()
	GameDeviceManager:SetMaxFPS(30)
end

function GameDeviceManager:SetMaxFPS(fps)
	local availableFPS = {60, 30, 15}

	local interval = nil
	for k, v in pairs(availableFPS) do
		if tonumber(v) == tonumber(fps) then
			interval = v
			break
		end
	end

	if interval then
		print("SetMaxFPS", fps);
		 -- Application.targetFrameRate = interval
	end
end


function GameDeviceManager:IsUniversalResourceVersionReleased()
	-- local latestVerString = server_config.latest_client_ver
	-- local _, _, AppVer1, AppVer2, AppVer3 = string.find(latestVerString, '(%d+).(%d+).(%d+)')
	-- local latestAppVer = AppVer1 * 10000 + AppVer2 * 100 + AppVer3

	-- local _, _, AppVer1, AppVer2, AppVer3 = string.find(UNIVERSAL_RESOURCE_VER, '(%d+).(%d+).(%d+)')
	-- local universalRssVer = AppVer1 * 10000 + AppVer2 * 100 + AppVer3
	-- return latestAppVer >= universalRssVer
end

function GameDeviceManager:IsGreaterVersion(targetVer)
	local curAppVer = self:GetAppVer()
	local _, _, AppVer1, AppVer2, AppVer3 = string.find(curAppVer, '(%d+).(%d+).(%d+)')
	local curAppVerValue = AppVer1 * 10000 + AppVer2 * 100 + AppVer3

	_, _, AppVer1, AppVer2, AppVer3 = string.find(targetVer, '(%d+).(%d+).(%d+)')
	local targetVerValue =  AppVer1 * 10000 + AppVer2 * 100 + AppVer3
	return curAppVerValue > targetVerValue
end

function GameDeviceManager:IsSupportedVer(targetVer)
	local curAppVer = self:GetAppVer()
	local _, _, AppVer1, AppVer2, AppVer3 = string.find(curAppVer, '(%d+).(%d+).(%d+)')
	local curAppVerValue = AppVer1 * 10000 + AppVer2 * 100 + AppVer3

	_, _, AppVer1, AppVer2, AppVer3 = string.find(targetVer, '(%d+).(%d+).(%d+)')
	local targetVerValue =  AppVer1 * 10000 + AppVer2 * 100 + AppVer3
	return curAppVerValue >= targetVerValue
end


function GameDeviceManager:IsIOSReviewInAppSupported()
	local osVer = self:GetOsVersion()
	local findNum = string.gmatch(osVer, '%d+');
	local osVer1 = findNum() or 0;
	local osVer2 = findNum() or 0;
	local osVer3 = findNum() or 0;
	local osVerValue = osVer1 * 10000 + osVer2 * 100 + osVer3

	local targetVer = "10.3.0"
	local findNum = string.gmatch(targetVer, '%d+');
	local osVer1 = findNum() or 0;
	local osVer2 = findNum() or 0;
	local osVer3 = findNum() or 0;
	local targetOsVerValue = osVer1 * 10000 + osVer2 * 100 + osVer3
	return osVerValue >= targetOsVerValue
end



function GameDeviceManager:CopyToClipboard(text)
	return DeviceUtil.CopyToClipboard(text)
end

function GameDeviceManager:PasteFromClipboard()
	return DeviceUtil.PasteFromClipboard()
end

function GameDeviceManager:OpenURL(url)
	return DeviceUtil.OpenURL(url)
end

function GameDeviceManager:IsPadScreenRatio()
	local w, h = GameDeviceManager:GetDeviceScreenSize()
	local isPad = w / h >= 0.57
	return isPad
end

function GameDeviceManager:GetMemorySize()
	-- return value is in Gigabytes.
	return DeviceUtil.GetDeviceMemorySize() / 1024
end

function GameDeviceManager:RegisterLowMemHandler()
	-- GameDeviceManager.lastLowMemoryGCTimeStamp = 0
	-- DeviceUtil.RegisterLowMemHandler(function()
	-- 	print("Low Memory Alert:!!!!")
	-- 	GameDeviceManager:OnLowMemoryAlert()
	-- end)
end

function GameDeviceManager:OnLowMemoryAlert()
	local curTime = GameTimeManager:GetCurrentServerTimeInMilliSec()

	if curTime - GameDeviceManager.lastLowMemoryGCTimeStamp >= 120 * 1000 then
		GameDeviceManager.lastLowMemoryGCTimeStamp = curTime
		GameResMgr:UnloadUnused()
		collectgarbage("collect")
	end
end

function GameDeviceManager:WechatExist()
	return DeviceUtil.WechatExist()
end

function GameDeviceManager:GetMemorySize()
	return DeviceUtil.GetDeviceMemorySize() / 1024
end

function GameDeviceManager:ApplyRecommendedQualitylevel()
	local data = LocalDataManager:GetCurrentRecord()
	local savedQualityLevel = data.quality --UserSetting:GetSavedQualityLevel()
	local recommendedQualityLevel = QualityLevel.HIGH
	if not savedQualityLevel then
		local memSize = self:GetMemorySize()
		if self:IsAndroidDevice() then
			if memSize < 6.1 then
				recommendedQualityLevel = QualityLevel.LOW
			elseif memSize >= 6.1 and memSize <= 10.1 then
				recommendedQualityLevel = QualityLevel.MEDIUM
			elseif memSize > 10.1 then
				recommendedQualityLevel = QualityLevel.HIGH
			else
				recommendedQualityLevel = QualityLevel.LOW
			end
		else
			if memSize < 3.0 then
				recommendedQualityLevel = QualityLevel.LOW
			end
		end
		CS.Common.Utils.UnityHelper.SetQualityLevel(recommendedQualityLevel - 1)
		data.quality = recommendedQualityLevel
		LocalDataManager:WriteToFile()
		-- UserSetting:SaveQualityLevel(recommendedQualityLevel)
	end
end

---从存档中读取并适用图形质量等级
--function GameDeviceManager:ApplyQualityFromSaveData()
--	local data = LocalDataManager:GetCurrentRecord()
--	if data.quality then
--		CS.Common.Utils.UnityHelper.SetQualityLevel(data.quality - 1)
--	end
--end

function GameDeviceManager:GetWechatSupportList()
	if not VersionInfo or not VersionInfo.platform_list[VersionInfo.platform] then -- local versionInfo
		return
	end
	return VersionInfo.platform_list[VersionInfo.platform].wechatSupport
end

function GameDeviceManager:IsIAPVersion()
	if not VersionInfo or not VersionInfo.platform_list[VersionInfo.platform] then
		return true
	end
	return VersionInfo.platform_list[VersionInfo.platform].iap
end

function GameDeviceManager:GetPlatform()
	if VersionInfo then
		return VersionInfo.platform
	end
end

function GameDeviceManager:IsGooglePlayVersion()
	return self:GetPlatform() == "android_google_play"
end

function GameDeviceManager:GetResDate()
	if not GameDefine then 
		return
	end
	
	-- server versionInfo
	return GameDefine.VersionInfo.Date
end

function GameDeviceManager:GetServerVersionInfo()
	if not GameDefine then
		return {}
	end
	return GameDefine.VersionInfo  or {}
end

--推送
function GameDeviceManager:ClearNotifications()
	if not GameConfig:IsLocalPushEnabled() then
		return
	end
	
	--self.m_registerPush = nil
	DeviceUtil.ClearNotifications()
end

function GameDeviceManager:RegisterRemoteNotification()
	if not GameConfig:IsLocalPushEnabled() then
		return
	end
	DeviceUtil.RegisterNotification(self.OnRegisterdForNotification)
	-- 暂时屏蔽
	-- local data = LocalDataManager:GetCurrentRecord()
	-- local checkPush = DeviceUtil.CheckNotifyEnabled()
	-- if nil == data.push and not checkPush then
	-- 	GameTableDefine.ChooseUI:ShowCloudConfirm("TXT_NOTIFICATION_SETTING", function()
    --         DeviceUtil.ShowApplicationSetting()
	-- 		GameTableDefine.ChooseUI:CloseView()
    --     end)
	-- end
	-- data.push = checkPush
	-- LocalDataManager:WriteToFile()
end

--K117 本地通知添加唯一标识
---@param notification_id string
function GameDeviceManager:AddNotification(title, scheduledTime, hint, soundName,notification_id)
	if not GameConfig:IsLocalPushEnabled() then
		return
	end
	--if self.m_registerPush then
    --    return
    --end
	--
    --self.m_registerPush = true
	scheduledTime = math.floor(scheduledTime)
	DeviceUtil.AddNotification(title or "", "", scheduledTime, hint, soundName, 1, "c_id", "t_id",notification_id)
end

function GameDeviceManager:OnRegisterdForNotification(param)
end

function GameDeviceManager:IsEditor( )
	if DeviceUtil.IsEditor then
		return DeviceUtil.IsEditor()
	end
end

function GameDeviceManager:IsWhitePackage(target)
	if not self.whitePackageInfo then
		self.whitePackageInfo = {}
		local info = Tools:SplitString(GameDefine.VersionInfo.WhitePackage or "", ",")
		for k, v in pairs(info or {}) do
			self.whitePackageInfo[v] = true
		end
	end
	if not target then
		return self.whitePackageInfo["iap"] or self.whitePackageInfo["ad"]
	end
	return self.whitePackageInfo[target]
end

--推送结束
