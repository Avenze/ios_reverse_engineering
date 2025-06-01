--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-23 14:42:57
]]

local FAQUI = GameTableDefine.FAQUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper

function FAQUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FAQ_UI, self.m_view, require("GamePlay.Common.UI.FAQUIView"), self, self.CloseView)
    return self.m_view
end

function FAQUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FAQ_UI)
    self.m_view = nil
    collectgarbage("collect")
end