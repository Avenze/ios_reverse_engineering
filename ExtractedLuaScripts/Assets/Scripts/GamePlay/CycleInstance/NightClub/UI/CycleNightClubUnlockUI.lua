---@class CycleNightClubUnlockUI
local CycleNightClubUnlockUI = GameTableDefine.CycleNightClubUnlockUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


function CycleNightClubUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_UNLOCK_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleNightClubUnlockUI:ShowUI(roomID)
    self:GetView():Invoke("InitView",roomID)
end

function CycleNightClubUnlockUI:RoomIsUnlock(roomID)
    local roomData = CycleInstanceDataManager:GetCurrentModel():GetCurRoomData(roomID)
    if roomData and next(roomData) ~= nil then
        return true
    else
        return false
    end
end
