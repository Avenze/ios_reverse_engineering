--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 15:57:09
]]


local InstanceMilepostUI = GameTableDefine.InstanceMilepostUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceMilepostUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_MILEPOST_UI, self.m_view, require("GamePlay.Instance.UI.InstanceMilepostUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceMilepostUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_MILEPOST_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function InstanceMilepostUI:OpenUI()
    self:GetView()
end
