--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 18:23:08
]]
local InstanceTimeUI = GameTableDefine.InstanceTimeUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceTimeUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_TIME_UI, self.m_view, require("GamePlay.Instance.UI.InstanceTimeUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceTimeUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_TIME_UI)
    self.m_view = nil
    collectgarbage("collect")
end

