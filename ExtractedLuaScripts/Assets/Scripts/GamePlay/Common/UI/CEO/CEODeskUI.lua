---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2025/2/6 15:33
---

---@class CEODeskUI
local CEODeskUI = GameTableDefine.CEODeskUI

local GameUIManager = GameTableDefine.GameUIManager

function CEODeskUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CEO_DESK_UI, self.m_view, require("GamePlay.Common.UI.CEO.CEODeskUIView"), self, self.CloseView)
    return self.m_view
end

function CEODeskUI:CloseView()
    ---当前正在执行雇佣操作的房间
    self.m_operationRoomIndex = nil
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CEO_DESK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CEODeskUI:Show(roomIndex, countryId,playShineAnim)
    self:GetView():Invoke("Init",roomIndex, countryId)
    self.m_operationRoomIndex = roomIndex
    self.m_OperationRoomCountryId = countryId
    if playShineAnim then
        self.m_view:PlayShineAnim()
    end
end

return CEODeskUI