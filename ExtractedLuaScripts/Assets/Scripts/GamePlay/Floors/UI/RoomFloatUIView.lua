
-- local Class = require("Framework.Lua.Class")
-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local ViewUtils = require("GamePlay.Utils.ViewUtils")
-- local GameResMgr = require("GameUtils.GameResManager")

-- local UnityHelper = CS.Common.Utils.UnityHelper
-- local EventType = CS.UnityEngine.EventSystems.EventTriggerType
-- local Button = CS.UnityEngine.UI.Button
-- local AnimationUtil = CS.Common.Utils.AnimationUtil

-- local GameUIManager = GameTableDefine.GameUIManager
-- local FloorMode = GameTableDefine.FloorMode
-- local ResMgr = GameTableDefine.ResourceManger
-- local TimerMgr = GameTimeManager
-- local RoomUnlockUI = GameTableDefine.RoomUnlockUI
-- local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI

-- local RoomFloatUIView = Class("RoomFloatUIView", UIView)

-- function RoomFloatUIView:ctor()
--     self.super:ctor()
-- end

-- function RoomFloatUIView:OnEnter()
--     self.m_allButton = {self:GetGo("unlock"), self:GetGo("inBuild"), self:GetGo("reward")}
--     self:Init()
-- end

-- function RoomFloatUIView:OnPause()
--     --print("RoomFloatUIView:OnPause")
-- end

-- function RoomFloatUIView:OnResume()
--     --print("RoomFloatUIView:OnResume")
-- end

-- function RoomFloatUIView:OnExit()
--     self.super:OnExit(self)
--     --print("Exit RoomFloatUIView")
-- end

-- function RoomFloatUIView:SetEntity(go)
--     self.m_entityGo = go
--     self:Show()

--     self.m_locationTrans = self:GetTrans(go, "UIPostion") or go.transform
--     GameUIManager:UpdateFloatUIEntity(self, self.m_locationTrans)
-- end

-- function RoomFloatUIView:Hide()
--     if self.m_uiObj and not self.m_uiObj:IsNull() then
--         self.m_uiObj:SetActive(false)
--     end
-- end

-- function RoomFloatUIView:Show()
--     local buildingActiveInHierarchy = true
--     if self.m_entityGo then
--         buildingActiveInHierarchy = self.m_entityGo.activeInHierarchy
--     end
--     self.m_uiObj:SetActive(true and buildingActiveInHierarchy)
-- end

-- function RoomFloatUIView:Init()
--     -- local childCount = self.m_uiObj.transform.childCount
--     -- for i = 1, childCount do
--     --     local child = self.m_uiObj.transform:GetChild(i - 1)
--     --     if child then
--     --         ViewUtils:SetGoVisibility(child.gameObject, false)
--     --     end
--     -- end
--     self:Hide()
--     self.m_entityGo = nil
--     self.m_locationTrans = nil
--     if self.m_allButton[4] then
--         self.m_allButton[4]:SetActive(false)
--     end
--     GameUIManager:UpdateFloatUIEntity(self, nil)
-- end

-- function RoomFloatUIView:ShowRoomUnlockButtton(unlock, cash, timeWait, moneyGet, config)
--     --原来的
--     -- local ownCash = ResMgr:GetCash()
--     -- local numberTxt = Tools:SeparateNumberWithComma(cash)
--     -- if cash <= ownCash then
--     --     self:SetText("Button/money", numberTxt)
--     -- else
--     --     self:SetText("Button/money", Tools:ChangeTextColor(numberTxt, Tools.COLOR_RED))
--     -- end

--     -- local btn = self:GetComp("Button", "Button")
--     -- btn.interactable = cash <= ownCash
--     -- self:SetButtonClickHandler(btn, function()
--     --     FloorMode:UnlockRoom(cash, config)
--     -- end)
--     if unlock and timeWait > TimerMgr:GetCurrentServerTime() then--等待解锁
--         for i, v in pairs(self.m_allButton) do
--             v:SetActive(v.name == "inBuild")
--         end
--         --再加一个绑定按钮,立刻解锁并刷星界面
--         self:SetButtonClickHandler(self:GetComp("inBuild/SkipBtn", "Button"), function()
--             UnlockingSkipUI:Show(config, timeWait)
--         end)
--         self.endPoint = timeWait
--         self:CreateTimer(1000, function()
--             local t = self.endPoint - TimerMgr:GetCurrentServerTime()
--             local timeTxt = GameTimeManager:FormatTimeLength(t)
--             if t > 0 then
--                 self:SetText("inBuild/timer", timeTxt)
--                 local progress = self:GetComp("inBuild/prog", "Slider")
--                 progress.value = 1 - t / config.unlock_times
--             else
--                 self:StopTimer()
--                 FloorMode:RefreshFloorScene(config.room_index_number)--还是说直接关掉用一个新的比较合适
--                 --刷新界面
--             end
--         end, true, true)
--     elseif moneyGet > 0 then--零钱
--         for i, v in pairs(self.m_allButton) do
--             v:SetActive(v.name == "reward")
--         end
--         --点击价钱直接加在房间点击那里  
--     else--点击解锁
--         self:Init3DMode(cash, config)
--         -- local btn = self:GetComp("unlock/frame", "Button")
--         -- self:SetButtonClickHandler(btn, function()
--         --     --打开一个新界面,来调用下面这个方法.
--         --     RoomUnlockUI:Show(cash, config)
--         --     --FloorMode:UnlockRoom(cash, config)--这个config导出都在用啊...
--         -- end)
--     end
-- end

-- function RoomFloatUIView:Init3DMode(cash, config)
--     for i, v in ipairs(self.m_allButton) do
--         v:SetActive(i == 4)
--         if i == 4 then
--             self:Load3dComplete(v, cash, config)
--             return
--         end
--     end
--     GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/unlockable_btn.prefab", self, function(childGo)
--         self:Load3dComplete(childGo, cash, config)
--     end)
-- end

-- function RoomFloatUIView:Load3dComplete(childGo, cash, config)
--     if self.m_locationTrans and not self.m_locationTrans:IsNull() then
--         UnityHelper.AddChildToParent(self.m_locationTrans.transform, childGo.transform)
--         self:SetClickHandler(childGo, function()
--             RoomUnlockUI:Show(config)
--          end)
--          --self.m_allButton[4] = childGo
--          self.m_allButton[4] = childGo
--     else
--         UnityHelper.DestroyGameObject(childGo)
--     end
-- end

-- return RoomFloatUIView
