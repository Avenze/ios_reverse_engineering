local RoomUnlockUI = GameTableDefine.RoomUnlockUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local EventManager = require("Framework.Event.Manager")

function RoomUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ROOM_UNLOCK_UI, self.m_view, require("GamePlay.Floors.UI.RoomUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function RoomUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ROOM_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function RoomUnlockUI:Show(data)
    local localData = FloorMode:GetRoomLocalData(data.room_index)
    if localData and localData.unlock then
        FloorMode:GetScene():InitRoomGo(data.id)
        return
    end
    self:GetView():Invoke("Refresh", data)
end