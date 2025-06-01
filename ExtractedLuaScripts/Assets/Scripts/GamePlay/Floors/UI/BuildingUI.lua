

-- local BuildingUI = GameTableDefine.BuildingUI
-- local GameUIManager = GameTableDefine.GameUIManager
-- local ConfigMgr = GameTableDefine.ConfigMgr
-- local FloorMode = GameTableDefine.FloorMode
-- local CompanyMode = GameTableDefine.CompanyMode
-- local EventManager = require("Framework.Event.Manager")

-- function BuildingUI:GetView()
--     self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BUILDING_UI, self.m_view, require("GamePlay.Floors.UI.BuildingUIView"), self, self.CloseView)
--     return self.m_view
-- end

-- function BuildingUI:CloseView()
--     GameUIManager:CloseUI(ENUM_GAME_UITYPE.BUILDING_UI)
--     self.m_view = nil
--     collectgarbage("collect")
-- end

-- function BuildingUI:ShowRoomPanelInfo(roomId)
--     local roomConfig = ConfigMgr.config_rooms[roomId]
--     local localData = FloorMode:GetCurrRoomLocalData().furnitures or {}
--     local data = {}
--     for i,v in ipairs(roomConfig.furniture or {}) do
--         local name = GameTextLoader:ReadText("TXT_FURNITURES_"..v.id.."_NAME")
--         local desc = GameTextLoader:ReadText("TXT_FURNITURES_"..v.id.."_DESC")
--         local time = "12345/hours"
--         local icon = nil
--         table.insert(data, {hint = localData[i].level, id= v.id, name = name, desc = desc, icon = icon, time = time})
--     end

--     local furnatureProgress = FloorMode:GetCurrRoomProgress()
--     local companyId = CompanyMode:CompIdByRoomIndex(roomConfig.index)
--     local companyData = companyId and ConfigMgr.config_company[companyId] or  {}
--     local moneyEarn = companyId == nil and "0/小时" or companyData.base_rent.."/小时"

--     self:GetView():Invoke("SetHeadPanel", moneyEarn, furnatureProgress)
--     self:GetView():Invoke("SetTitlePanel", companyId == nil, companyData.company_quality, companyData.company_name, companyData.type, "logo")
--     self:GetView():Invoke("SetListData", data)
-- end