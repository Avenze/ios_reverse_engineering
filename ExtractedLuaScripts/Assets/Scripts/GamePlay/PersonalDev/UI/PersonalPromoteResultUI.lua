--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-13 14:55:02
]]

local PersonalPromoteResultUI = GameTableDefine.PersonalPromoteResultUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function PersonalPromoteResultUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSONAL_PROMOTE_RESULT_UI, self.m_view, require("GamePlay.PersonalDev.UI.PersonalPromoteResultUIView"), self, self.CloseView)
    return self.m_view
end

function PersonalPromoteResultUI:OpenPromoteResult(enemyID, playerSupport, enemySupport)
    self:GetView():Invoke("OpenPromoteResult", enemyID, playerSupport, enemySupport)
end

function PersonalPromoteResultUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSONAL_PROMOTE_RESULT_UI)
    self.m_view = nil
    collectgarbage("collect")
end