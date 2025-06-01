--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-19 13:46:46
]]

local InstanceProcessUI = GameTableDefine.InstanceProcessUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceProcessUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSRANCE_PROCESS_UI, self.m_view, require("GamePlay.Instance.UI.InstanceProcessUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceProcessUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSRANCE_PROCESS_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function InstanceProcessUI:ShowView()
    self:GetView()
end