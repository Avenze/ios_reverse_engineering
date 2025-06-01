local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local ConfigMgr = GameTableDefine.ConfigMgr

local ChooseUIView = Class("ChooseUIView", UIView)

function ChooseUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ChooseUIView:OnEnter()
    self.cancelBtn = self:GetComp("background/BottomPanel/CancelBtn","Button")
    self.confBtn = self:GetComp("background/BottomPanel/ConfirmBtn","Button")
    self.yesBtn = self:GetComp("background/BottomPanel/YesBtn","Button")
    self.confBtn.gameObject:SetActive(false)
    self.yesBtn.gameObject:SetActive(false)

    self:SetButtonClickHandler(self.cancelBtn, function()
        self:DestroyModeUIObject()
    end)

    
end

function ChooseUIView:OnExit()
    self.super:OnExit(self)
end

function ChooseUIView:BindFunction(cb, title, spend)
    self.func = cb;
    self:Refresh(title, spend)
end

function ChooseUIView:Refresh(title, spend)
    self:SetText("background/HeadPanel/desc", title)
    local numText = self:SetText("background/BottomPanel/ConfirmBtn/num", spend)
    self.confBtn.gameObject:SetActive(true)
    self.confBtn.interactable = self.func(true)
    local matAddress = self.func(true) and "Assets/Res/Fonts/MSYH GreenOutline Material.mat" or "Assets/Res/Fonts/MSYH RedOutline Material.mat"
    -- numText.fontMaterial = GameResMgr:LoadMaterialSyncFree(matAddress, self).Result

    if self.confBtn.interactable then
        self:SetButtonClickHandler(self.confBtn, function()
            self.confBtn.interactable = false
            if self.func then
                self.func()
                self:DestroyModeUIObject()
            end
        end)
    end
end

function ChooseUIView:ShowCloudConfirm(title, cb)
    self:SetText("background/HeadPanel/desc", title)
    self.yesBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(self.yesBtn, function()
        if cb then cb() end
    end)
end

function ChooseUIView:Choose(title, cb)
    self:SetText("background/HeadPanel/desc", title)
    self.yesBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(self.yesBtn, function()
        self.yesBtn.interactable = false
        if cb then cb() end
        self:DestroyModeUIObject()
    end)
end

function ChooseUIView:CommonChoose(content, cb, showCancel, cancelCb,title, extendType, extendNum)
    self:SetText("background/HeadPanel/desc", content)
    self.yesBtn.gameObject:SetActive(true)
    self.cancelBtn.gameObject:SetActive(showCancel == true) 
    if showCancel == true then
        self:SetButtonClickHandler(self.cancelBtn, function()
            self.cancelBtn.interactable = false
            if cancelCb then cancelCb() end
            self:DestroyModeUIObject()
        end)
    end
    self:SetButtonClickHandler(self.yesBtn, function()
        self.yesBtn.interactable = false
        if cb then cb() end
        self:DestroyModeUIObject()
    end)
    
    if title then
        self:SetText("background/title/text",title)
    else
        --TXT_HELP_TIP
        self:SetText("background/title/text",GameTextLoader:ReadText("TXT_HELP_TIP"))
    end
    if extendType then
        local displayNum = extendNum or 0
        self:SetText("Res/adRes/num", displayNum)
        self:GetGo("Res/adRes"):SetActive(true)
    else
        self:GetGo("Res/adRes"):SetActive(false)
    end
end


return ChooseUIView