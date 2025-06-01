---@class CycleToyUnlockUI
local CycleToyUnlockUI = GameTableDefine.CycleToyUnlockUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


function CycleToyUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_UNLOCK_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleToyUnlockUI:ShowUI(roomID)
    self:GetView():Invoke("InitView",roomID)
end

function CycleToyUnlockUI:RoomIsUnlock(roomID)
    local roomData = CycleInstanceDataManager:GetCurrentModel():GetCurRoomData(roomID)
    if roomData and next(roomData) ~= nil then
        return true
    else
        return false
    end
end
