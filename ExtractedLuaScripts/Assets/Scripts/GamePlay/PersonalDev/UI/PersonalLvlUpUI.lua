--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-20 10:30:32
]]

local PersonalLvlUpUI = GameTableDefine.PersonalLvlUpUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function PersonalLvlUpUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSONAL_LVLUP_UI, self.m_view, require("GamePlay.PersonalDev.UI.PersonalLvlUpUIView"), self, self.CloseView)
    return self.m_view
end

function PersonalLvlUpUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSONAL_LVLUP_UI)
    self.m_view = nil
    collectgarbage("collect")
end

