---@class CycleIslandUnlockUI
local CycleIslandUnlockUI = GameTableDefine.CycleIslandUnlockUI
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")


function CycleIslandUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_UNLOCK_UI, self.m_view, require("GamePlay/CycleInstance/Island/UI/CycleIslandUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function CycleIslandUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleIslandUnlockUI:ShowUI(roomID)
    self:GetView():Invoke("InitView",roomID)
end

function CycleIslandUnlockUI:RoomIsUnlock(roomID)
    local roomData = CycleInstanceDataManager:GetCurrentModel():GetCurRoomData(roomID)
    if roomData and next(roomData) ~= nil then
        return true
    else
        return false
    end
end
