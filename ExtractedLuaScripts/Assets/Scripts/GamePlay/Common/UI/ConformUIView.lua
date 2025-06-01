local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local AnimationUtil = CS.Common.Utils.AnimationUtil
local DeviceUtil = CS.Game.Plat.DeviceUtil

local ConformUIView = Class("ConformUIView", UIView)

function ConformUIView:ctor()
    self.super:ctor()
end

function ConformUIView:OnEnter()
    self.super:OnEnter()

end

function ConformUIView:OpenFirstResetAccount()
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/CancelBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/YesBtn", "Button"), function()
        local isBindFBAccount = false
        local otherThirdAccBind = false
        if GameDeviceManager:IsAndroidDevice() then
            otherThirdAccBind = DeviceUtil.IsBindGoogle()
            isBindFBAccount = DeviceUtil.IsBindFacebook()
        end
        if GameDeviceManager:IsiOSDevice() then
            isBindFBAccount = DeviceUtil.IsBindFacebook()
            otherThirdAccBind = DeviceUtil.IsBindApple()
        end
        if isBindFBAccount or otherThirdAccBind then
            GameTableDefine.ConformUI:OpenThirdAccountReset()
        else
            GameTableDefine.SettingUI:ResetGameData()
        end
        
    end)
    local txtContent = self:SetText("background/MidPanel/desc", GameTextLoader:ReadText(GameDeviceManager:IsiOSDevice() and "TXT_TIP_RESET_WARNING_IOS" or "TXT_TIP_RESET_WARNING_AND"))
    AnimationUtil.AddKeyFrameEventOnObj(
        self.m_uiObj,
        "CMD_CONFORMUI_OPEND",
        function()
            local txtSize = UIView:GetWidgetSize(txtContent)
            local midPanel = self:GetTrans("background/MidPanel")
            midPanel.sizeDelta = {
                x = txtSize.width,
                y = txtSize.height + 20
            }
            ViewUtils:ReseTextSize(txtContent)
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self:GetComp("background", "RectTransform"))
        end
    )
end

function ConformUIView:OpenThirdAccountReset()
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/CancelBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/YesBtn", "Button"), function()
        GameTableDefine.SettingUI:ResetGameData()
    end)
    local txtContent = self:SetText("background/MidPanel/desc", GameTextLoader:ReadText("TXT_TIP_RESET_WARNING_BIND"))
    AnimationUtil.AddKeyFrameEventOnObj(
        self.m_uiObj,
        "CMD_CONFORMUI_OPEND",
        function()
            local txtSize = UIView:GetWidgetSize(txtContent)
            local midPanel = self:GetTrans("background/MidPanel")
            midPanel.sizeDelta = {
                x = txtSize.width,
                y = txtSize.height + 20
            }
            ViewUtils:ReseTextSize(txtContent)
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self:GetComp("background", "RectTransform"))
        end
    )
end

function ConformUIView:OnExit()
    self.super:OnExit(self)
end
return ConformUIView