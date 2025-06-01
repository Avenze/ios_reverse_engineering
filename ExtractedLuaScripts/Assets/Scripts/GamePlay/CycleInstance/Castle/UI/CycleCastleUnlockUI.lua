---@class CycleCastleUnlockUI
local CycleCastleUnlockUI = GameTableDefine.CycleCastleUnlockUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


function CycleCastleUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_UNLOCK_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleCastleUnlockUI:ShowUI(roomID)
    self:GetView():Invoke("InitView",roomID)
end

function CycleCastleUnlockUI:RoomIsUnlock(roomID)
    local roomData = CycleInstanceDataManager:GetCurrentModel():GetCurRoomData(roomID)
    if roomData and next(roomData) ~= nil then
        return true
    else
        return false
    end
end
