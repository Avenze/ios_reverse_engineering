local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ForbesRewardUIView = Class("ForbesRewardUIView", UIView)

function ForbesRewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ForbesRewardUIView:OnEnter()
end

function ForbesRewardUIView:OnExit()
	self.super:OnExit(self)
end
--目前只有买车和买房使用后续如果不再适用请自行修改
function ForbesRewardUIView:Open(cfg, cb)
    local value = cfg.wealth_buff or 0
    local iconName
    local txtName
    if not cfg.pfb then        
        iconName = "icon_house_" .. cfg.id
        txtName = "TXT_BUILDING_B"..tostring(cfg.id).."_NAME"
    else
        iconName = "icon_" .. cfg.pfb
        txtName = "TXT_CAR_C"..tostring(cfg.id).."_NAME"
    end
    local currImage = self:GetComp("HeadPanel/content/icon", "Image")
    self:SetSprite(currImage, "UI_Common", iconName)
    local root = self:GetGo("HeadPanel/reward/forbes")
    self:SetText(root, "num", "+"..value)
    if txtName then
        self:SetText("HeadPanel/title/text", GameTextLoader:ReadText(txtName))
    end
    self:SetButtonClickHandler(self:GetComp("HeadPanel/confirmBtn", "Button"), function()
        if cb then cb() end
        self:DestroyModeUIObject()
    end)
end

return ForbesRewardUIView