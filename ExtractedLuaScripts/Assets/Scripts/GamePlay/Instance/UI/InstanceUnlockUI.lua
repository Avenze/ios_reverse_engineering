--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 16:15:44
]]

local InstanceUnlockUI = GameTableDefine.InstanceUnlockUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")


function InstanceUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_UNLOCK_UI, self.m_view, require("GamePlay.Instance.UI.InstanceUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function InstanceUnlockUI:ShowUI(roomID)
    self:GetView():Invoke("InitView",roomID)
end

function InstanceUnlockUI:RoomIsUnlock(roomID)
    local roomData = InstanceDataManager:GetCurRoomData(roomID)
    if roomData and next(roomData) ~=nil then
        return true
    else
        return false
    end
end
