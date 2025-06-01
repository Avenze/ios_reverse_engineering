
GameTextLoader = {
	gameLoader = nil
}

local LocalizationManager = CS.UnityEngine.UI.LocalizationManager.Instance;

GameTextLoader.textIDPrefix = "TXT"

function GameTextLoader:LoadTextofLanguage(languageCode, cb)
	languageCode = GameLanguage:ConvertToFull(languageCode);
	LocalizationManager:SwitchLanguage(languageCode, cb);
end

function GameTextLoader:ForceRefreshText(cb)
	LocalizationManager:LoadLocalizedText(cb);
end

function GameTextLoader:ReadText(textId,isDebug)
	local text = LocalizationManager:GetValue(textId)
	if text == "" or text == " " then
		-- text = textId .. " is not configured"
		if isDebug then
			print(text)
			return nil
		end
	end
	return text
end

function GameTextLoader:IsTextID(text)
	if text then
		return string.sub(text, 1, 3) == self.textIDPrefix
	else
		return false
	end
end

return GameTextLoader