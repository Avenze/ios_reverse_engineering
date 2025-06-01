-- local Class = require("Framework.Lua.Class")
-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local ViewUtils = require("GamePlay.Utils.ViewUtils")
-- local GameResMgr = require("GameUtils.GameResManager")

-- local FileHelper = CS.Common.Utils.FileHelper
-- local AnimationUtil = CS.Common.Utils.AnimationUtil
-- local UnityHelper = CS.Common.Utils.UnityHelper
-- local Color = CS.UnityEngine.Color

-- local GameUIManager = GameTableDefine.GameUIManager
-- local FloorMode = GameTableDefine.FloorMode

-- local CompanysUI = GameTableDefine.CompanysUI
-- local CompanyMode = GameTableDefine.CompanyMode

-- local BuildingUIView = Class("BuildingUIView", UIView)

-- function BuildingUIView:ctor()
--     self.super:ctor()
--     self.m_data = {}
-- end

-- function BuildingUIView:OnEnter()
--     print("BuildingUIView:OnEnter")
--     self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
--         self:DestroyModeUIObject()
--         FloorMode:GetScene():SelectFurniture(nil)
--     end)

--     self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn", "Button"), function()
--         self:DestroyModeUIObject()
--         FloorMode:GetScene():SelectFurniture(nil)
--     end)

--     self:SetButtonClickHandler(self:GetComp("RootPanel/BuldingPanel/BuildingInfo/BuildBtn", "Button"), function(  )
--         local data = self.m_data[self.m_currSelectItemIndex] or {}
--         FloorMode:BuyFurniture(self.m_currSelectItemIndex, data.id)
--     end)
--     self:InitList()
--     self.m_currSelectItemIndex = 1
-- end

-- function BuildingUIView:OnPause()
--     print("BuildingUIView:OnPause")
-- end

-- function BuildingUIView:OnResume()
--     print("BuildingUIView:OnResume")
-- end

-- function BuildingUIView:OnExit()
--     self.super:OnExit(self)
--     self.m_data = nil
--     print("BuildingUIView:OnExit")
-- end

-- function BuildingUIView:InitList()
--     self.m_list = self:GetComp("RootPanel/BuldingPanel/BuidlingList", "ScrollRectEx")
--     self:SetListItemCountFunc(self.m_list, function()
--         return #self.m_data
--     end)
--     self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateListItem))
-- end

-- function BuildingUIView:UpdateListItem(index, tran)
--    index = index + 1
--     local go = tran.gameObject
--     local itemData = self.m_data[index]
--     if itemData then
--         local image = go:GetComponent("RawImage")
--         if self.m_currSelectItemIndex == index then
--             image.color = Color.red
--             self:SetSelectItemInfo()
--             FloorMode:GetScene():SelectFurniture(index)
--             FloorMode:GetScene():SetFurnitureOnCenter(self:GetTrans("SceneObjectRange").position)
--         else
--             image.color = Color.blue
--         end
--         self:SetWidgetHint(go, itemData.hint, self.HINT_READ)
--         self:SetButtonClickHandler(self:GetComp(go, "Btn", "Button"), function()
--             if self.m_currSelectItemIndex == index then
--                 return
--             end

--             self.m_currSelectItemIndex = index
--             self.m_list:UpdateData()
--         end)
--     end
-- end


-- function BuildingUIView:SetHeadPanel(timeInfo, profress)
--     self:SetText("RootPanel/HeadPanel/RentIncome/Text", timeInfo)
--     self:SetText("RootPanel/HeadPanel/RoomProgress/Text", profress)
--     local bar = self:GetComp("RootPanel/HeadPanel/RoomProgress", "Slider")
--     self.barProgress = profress
--     bar.value = profress
-- end

-- function BuildingUIView:SetTitlePanel(isEmpty, compyStar, compyName, compyLable, compyLogo)
--     local roomEmptyGo = self:GetGo("RootPanel/TitlePanel/RoomEmpty")
--     local roomRentedGo = self:GetGo("RootPanel/TitlePanel/RoomRented")

--     roomEmptyGo:SetActive(isEmpty)
--     roomRentedGo:SetActive(not isEmpty)
--     if isEmpty then
--         self:SetButtonClickHandler(self:GetComp("RootPanel/TitlePanel/RoomEmpty/InviteBtn", "Button"), function()
--             print("---->InviteBtn")
--             CompanysUI:MakeEnableCompanys()
--             CompanysUI:OpenView()
--         end)
--     else
--         self:SetText("RootPanel/TitlePanel/RoomRented/CompanyName", compyName)
--         self:SetText("RootPanel/TitlePanel/RoomRented/CompanyLabel", compyLable)

--         local Rate = self:GetTrans(roomRentedGo, "CompanyRate")
--         for i = 1, Rate.childCount do
--             self:GetGo(Rate.gameObject, "icon"..i):SetActive(i <= compyStar)
--         end
--     end

--     self:GetGo("RootPanel/LogoPanel/NoLogo"):SetActive(compyLogo == nil)
--     self:GetGo("RootPanel/LogoPanel/LogoImage"):SetActive(compyLogo ~= nil)
--     if compyLogo then
--     end
-- end

-- function BuildingUIView:SetSelectItemInfo()
--     local data = self.m_data[self.m_currSelectItemIndex] or {}
--     self:SetText("RootPanel/BuldingPanel/BuildingInfo/BuildingName", data.name)
--     self:SetText("RootPanel/BuldingPanel/BuildingInfo/RentIncome", data.time)
--     self:SetText("RootPanel/BuldingPanel/BuildingInfo/BuildingDesc", data.desc)
-- end

-- function BuildingUIView:SetListData(data)
--     self.m_data = data
--     self.m_list:UpdateData()
-- end


-- return BuildingUIView