-- local Class = require("Framework.Lua.Class")
-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local ViewUtils = require("GamePlay.Utils.ViewUtils")

-- local UnityHelper = CS.Common.Utils.UnityHelper
-- local EventType = CS.UnityEngine.EventSystems.EventTriggerType
-- local Button = CS.UnityEngine.UI.Button
-- local AnimationUtil = CS.Common.Utils.AnimationUtil
-- local GameUIManager = GameTableDefine.GameUIManager

-- local BuildingUIView = Class("BuildingUIView", UIView)

-- function BuildingUIView:ctor()
--     self.super:ctor()
-- end

-- function BuildingUIView:OnEnter()
--     self:Init()
-- end

-- function BuildingUIView:OnPause()
-- end

-- function BuildingUIView:OnResume()
-- end

-- function BuildingUIView:OnExit()
--     self.super:OnExit(self)
-- end

-- function BuildingUIView:Hide()
--     if self.m_uiObj and not self.m_uiObj:IsNull() then
--         ViewUtils:SetGoVisibility(self.m_uiObj, false)
--     end
-- end

-- function BuildingUIView:Show()
--     local buildingActiveInHierarchy = true
--     if self.m_buildObj then
--         buildingActiveInHierarchy = self.m_buildObj.activeInHierarchy
--     end
--     ViewUtils:SetGoVisibility(self.m_uiObj, true and buildingActiveInHierarchy)
-- end

-- function BuildingUIView:Init()
--     -- local childCount = self.m_uiObj.transform.childCount
--     -- for i = 1, childCount do
--     --     local child = self.m_uiObj.transform:GetChild(i - 1)
--     --     if child then
--     --         ViewUtils:SetGoVisibility(child.gameObject, false)
--     --     end
--     -- end
--     self:Hide()
--     self.m_entityGo = nil
--     GameUIManager:UpdateFloatUIEntity(self, nil)
-- end

-- function BuildingUIView:SetEntity(go, info,icon)
--     self.m_entityGo = go
--     self:Show()

--     local tran = self:GetTrans(go, "UIPosition") or go.transform
--     GameUIManager:UpdateFloatUIEntity(self, tran)
--     self:SetText("icon/name", info)
--     self:SetImageSprite("icon", icon)
-- end

-- return BuildingUIView
