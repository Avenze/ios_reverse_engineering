local GameDefine = CS.Game.GameDefine;
local UnityHelper = CS.Common.Utils.UnityHelper
GameConfig = {
    currentGateWay = "test",
    -- enableDbgOutput = GameDefine.VersionInfo.CurGateway ~= "android" and GameDefine.VersionInfo.CurGateway ~= "ios",
    enableDbgTrace = true,
    enableLuaException = true,
    enableGuide = true,
    enableLocalPush = true,
    enableSound = true,
    isChristmas = false,
    SDK_USEAGE = {
    },

    --language
    defaultLanguage = "en",
    -- supportedLanguage = {
    --     ["zh_Hans"] = "cn",
    --     ["en"] 		= "en",
    --     ["zh_Hant"] = "tc",
    --     ["de"] 		= "de",
    --     -- ["ru"] 		= "ru",
    --     -- ["fr"]		= "fr",
    --     -- ["ko"]		= "kr",
    --     -- ["ja"]		= "jp",
    --     -- ["es"]      = "sp",
    --     -- ["ro"]      = "ro",
    --     -- ["tr"]      = "tk",
    --     -- ["tl"]      = "pi",
    -- },
    -- languageOrder = {
    --     ["cn"]      = 1,
    --     ["en"]      = 2,
    --     ["tc"]      = 3,
    --     ["de"]      = 4,
    --     -- ["ru"]      = 5,
    --     -- ["fr"]      = 6,
    --     -- ["kr"]      = 7,
    --     -- ["jp"]      = 8,
    --     -- ["sp"]      = 9,
    --     -- ["ro"]      = 10,
    --     -- ["tk"]      = 11,
    --     -- ["pi"]      = 12,
    -- },
}

local debug_traceback = debug.traceback;
debug.traceback = function(...)
    if not GameConfig.enableDbgTrace then return ... end
    return debug_traceback(...);
end

function GameConfig:GetLangageFileSuffix()
    if GameTableDefine.ConfigMgr.config_global.enable_iap == 1 then
		return "_en"
	end
    
    local curLang = GameLanguage:GetCurrentLanguageID()
    if curLang == "cn" then
        return ""
    end
    return "_en"
end

function GameConfig:GetCurrentGateway()
    return GameDeviceManager:GetGateway() or self.currentGateWay or "test"
end

function GameConfig:IsGuideEnabled()
    return self.enableGuide
end

function GameConfig:IsIAP()--初始化的时候gametabledefine并没有...
    return true -- 2025-2-26 17:06:16 改游戏初始化流程导致的修改, 策划说可以直接改为true, 内购始终可用
    --return GameTableDefine.ConfigMgr.config_global.enable_iap == 1
end

function GameConfig:IsChristmas()
    return self.isChristmas
end

function GameConfig:IsNeedSound()
    return self.enableSound
end

function GameConfig:IsLocalPushEnabled()
    return self.enableLocalPush
end

function GameConfig:IsExceptionCollectingEnabled()
    return self.enableLuaException
end

function GameConfig:IsDebugMode()
    return GameDeviceManager:IsDebugVersion();
end

function GameConfig:IsEnableDebugTrace()
    return self.enableDbgTrace;
end

function GameConfig:GetLocalLanguage()
    local deviceLanguage = GameDeviceManager:GetDeviceLanguage();
    -- if UnityHelper.IsRuassionVersion() then
    --     self.defaultLanguage = "ru"
    -- end
    local localLanguage = self.defaultLanguage

    print("deviceLanguage= ", deviceLanguage)
    for k, v in pairs(self:GetSupportedLanguages()) do
        --in ios9 , apple add locale postfix to language code
        --eg: zh_Hans in ios8 but zh_Hans_CN in ios9
        if deviceLanguage == v then
            localLanguage = v
            break
        end
    end

    print("localLanguage = ", localLanguage)
    return localLanguage
end

function GameConfig:GetSupportedLanguages()
    if not self.supportedLanguage then
        -- 2025-2-26 17:36:42 改游戏初始化流程导致的修改
        self.supportedLanguage = {
            ["en"] = "en",
            ["de"] = "de",
            ["vn"] = "vn",
            ["pt"] = "pt",
            ["fr"] = "fr",
            ["th"] = "th",
            ["ko"] = "ko",
            ["sp"] = "sp",
            ["jp"] = "jp",
            ["tr"] = "tr",
            ["ar"] = "ar",
            ["in"] = "in",
            ["tt"] = "tt",
            ["ru"] = "ru",
            ["cn"] = "cn",
            ["tc"] = "tc",

        }
        if GameTableDefine.ConfigMgr.config_language then   -- 2025-2-26 17:36:42 改游戏初始化流程导致的修改
            for i,v in ipairs(GameTableDefine.ConfigMgr.config_language) do
                if v.language == "cn" then
                    self.supportedLanguage.zh_Hans = v.language
                elseif v.language == "tc" then
                    self.supportedLanguage.zh_Hant = v.language
                else
                    self.supportedLanguage[v.language] = v.language
                end
            end
        else
            for i,v in pairs(self.supportedLanguage) do
                if v == "cn" then
                    self.supportedLanguage.zh_Hans = v.language
                elseif v == "tc" then
                    self.supportedLanguage.zh_Hant = v.language
                end
            end
        end

    end
    return self.supportedLanguage
end

if not GameConfig:IsDebugMode() then
    function print()
    end
end

function GameConfig:UseWarriorOldAPI()
    return false
end
function GameConfig:IsWarriorVersion()
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    return identifier == "com.warrior.officebuilding.gp" or identifier == "com.warrior.officebuilding.ioshw"
    or identifier == "com.warrior.obxso.gp" or identifier == "com.warrior.officebuilding.ioshw" or "com.warrior.officebuilding.amz"

end

function GameConfig:IsLeyoHKVersion()
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    return identifier == "com.mlbgg.leyogamehy"
end

--[[
    @desc: 判斷是否是亞馬遜的安卓包版本
    author:{author}
    time:2023-12-27 12:31:18
    @return:bool
]]
function GameConfig:IsAMZPackageVersion()
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    return identifier == "com.warrior.officebuilding.amz"
end
return GameConfig