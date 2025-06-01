
local GameDefine = CS.Game.GameDefine

GameLanguage = {}

function GameLanguage:GetSupportedLanguageList()
	if self.m_langList then
		return self.m_langList
	end

	local langInConfig = GameConfig:GetSupportedLanguages()
	self.m_langList = {}
	for k, v in pairs(GameTableDefine.ConfigMgr.config_language or {}) do
		table.insert(self.m_langList, v.language)
	end
	return self.m_langList
end

function GameLanguage:GetLanguageDescription(languageID)
	local textID = "LC_WORD_LANGUAGE_" .. string.upper(languageID)
	return GameTextLoader:ReadText(textID)
end

function GameLanguage:GetCurrentLanguageID()
	if not self.m_currentLanguageID then
		local userSave = LocalDataManager:GetCurrentRecord()
		if userSave and userSave.CURRENT_LANGUAGE then
			self.m_currentLanguageID = userSave.CURRENT_LANGUAGE
		else
			self.m_currentLanguageID = GameConfig:GetLocalLanguage()
		end
	end

	return self.m_currentLanguageID
end

function GameLanguage:GetCurrentLanguageIndex()
	local id = self:GetCurrentLanguageID();
	for i, v in ipairs(self:GetSupportedLanguageList()) do
		if v == id then
			return i;
		end
	end
	return nil;
end

function GameLanguage:SetCurrentLanguageID(languageID)
	self.m_currentLanguageID = languageID
	local userSave = LocalDataManager:GetCurrentRecord()
	userSave.CURRENT_LANGUAGE = languageID
	LocalDataManager:WriteToFile()
end

function GameLanguage:ConvertToSimple(full)
	local simple;
	for k, v in pairs(GameDefine.LANGUAGE_AERA_FULL_NAME) do
		if v == full then
			simple = k;
			break;
		end
	end
	return simple or full;
end

function GameLanguage:ConvertToFull(simple)
	local full;
	for k, v in pairs(GameDefine.LANGUAGE_AERA_FULL_NAME) do
		if k == simple then
			full = v;
			break;
		end
	end
	return full or simple;
end

