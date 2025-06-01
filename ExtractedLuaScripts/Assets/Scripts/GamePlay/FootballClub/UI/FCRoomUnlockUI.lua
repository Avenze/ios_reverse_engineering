--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-25 13:46:25
]]
local FCRoomUnlockUI = GameTableDefine.FCRoomUnlockUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function FCRoomUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_ROOM_UNLOCK_UI, self.m_view, require("GamePlay.FootballClub.UI.FCRoomUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function FCRoomUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_ROOM_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function FCRoomUnlockUI:Show(buildID,go)
    self:GetView():Invoke("Show",buildID,go)
end