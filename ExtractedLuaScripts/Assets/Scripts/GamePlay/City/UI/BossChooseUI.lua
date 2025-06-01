
local BossChooseUI = GameTableDefine.BossChooseUI
local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode
local CfgMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local Mathf = CS.UnityEngine.Mathf

local currentCharacterId = 1 --CfgMgr.boss_skin[1]
function BossChooseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BOSS_CHOOSE_UI, self.m_view, require("GamePlay.City.UI.BossChooseUIView"), self, self.CloseView)
    return self.m_view
end

function BossChooseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.BOSS_CHOOSE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function BossChooseUI:ShowChooseBossSkinPanel()
    local leftEnable = currentCharacterId > 1
    local rightEnable = currentCharacterId < #CfgMgr.config_global.boss_skin
    GameTableDefine.BenameUI:SetCurBossSkinID(currentCharacterId)
    self:GetView():Invoke("ShowPanel", leftEnable, rightEnable)
end

function BossChooseUI:ChangeBossSkin(ChangeBossSkinValue)
    local last = currentCharacterId
    currentCharacterId = Mathf.Clamp(currentCharacterId + ChangeBossSkinValue, 1, #CfgMgr.config_global.boss_skin)
    CityMode:ChangeBossSkin(last, currentCharacterId)
    GameTableDefine.BenameUI:SetCurBossSkinID(currentCharacterId)
    self:ShowChooseBossSkinPanel()
end

function BossChooseUI:Confirm()
    CityMode:ResumeOpeningScene()
end