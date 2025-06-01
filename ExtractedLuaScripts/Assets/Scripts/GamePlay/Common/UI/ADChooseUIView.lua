--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-10 17:45:52
]]
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

local ADChooseUIView = Class("ADChooseUIView", UIView)

function ADChooseUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ADChooseUIView:OnEnter()
    self.cancelBtn = self:GetComp("background/BottomPanel/CancelBtn","Button")
    self.confBtn = self:GetComp("background/BottomPanel/ConfirmBtn","Button")
    self.yesBtn = self:GetComp("background/BottomPanel/YesBtn","Button")
    self.confBtn.gameObject:SetActive(false)
    self.yesBtn.gameObject:SetActive(false)

    self:SetButtonClickHandler(self.cancelBtn, function()
        self:DestroyModeUIObject()
    end)
end

function ADChooseUIView:OnExit()
    self.super:OnExit(self)
end

function ADChooseUIView:CommonChoose(content, cb, showCancel, cancelCb,title, extendType, extendNum)
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


return ADChooseUIView