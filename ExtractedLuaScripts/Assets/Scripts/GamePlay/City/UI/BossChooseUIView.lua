local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local GameUIManager = GameTableDefine.GameUIManager
local BossChooseUI = GameTableDefine.BossChooseUI
local BossChooseUIView = Class("BossChooseUIView", UIView)

function BossChooseUIView:ctor()
    self.super:ctor()
end

function BossChooseUIView:OnEnter()
    print("BossChooseUIView:OnEnter")
    GameUIManager:SetEnableTouch(true)  -- gxy 2024年5月10日  重命名时强制开启可点击
    self:SetButtonClickHandler(self:GetComp("ConfirmBtn", "Button"), function()
        self:DestroyModeUIObject()
        BossChooseUI:Confirm()
    end)

    self.m_left = self:GetComp("left", "Button")
    self:SetButtonClickHandler(self.m_left, function()
        BossChooseUI:ChangeBossSkin(-1)
    end)
    self.m_right = self:GetComp("right", "Button")
    self:SetButtonClickHandler(self.m_right, function()
        BossChooseUI:ChangeBossSkin(1)
    end)
end

function BossChooseUIView:OnPause()
    print("BossChooseUIView:OnPause")
end

function BossChooseUIView:OnResume()
    print("BossChooseUIView:OnResume")
end

function BossChooseUIView:OnExit()
    self.super:OnExit(self)
    print("BossChooseUIView:OnExit")
end

function BossChooseUIView:ShowPanel(leftEnabled, rightEnabled)
    self.m_left.gameObject:SetActive(leftEnabled)
    self.m_right.gameObject:SetActive(rightEnabled)
end

return BossChooseUIView