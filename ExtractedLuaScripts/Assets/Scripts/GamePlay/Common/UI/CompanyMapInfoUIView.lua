local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject

local CollectionUI = GameTableDefine.CollectionUI
local CompanyMode = GameTableDefine.CompanyMode

local CompanyMapInfoUIView = Class("CompanyMapInfoUIView", UIView)

function CompanyMapInfoUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CompanyMapInfoUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CompanyMapInfoUIView:OnExit()
    self.super:OnExit(self)
end

function CompanyMapInfoUIView:Refresh(data,cfg)
    local iconImage = self:GetComp("RootPanel/info/basic/icon", "Image")
    local iconImageGo = self:GetGoOrNil("RootPanel/info/basic/icon")
    self:SetSprite(iconImage, "UI_Common", cfg.company_logo..GameConfig:GetLangageFileSuffix())
    
    local qualityImage = self:GetComp("RootPanel/info/basic/name/quality", "Image")
    self:SetSprite(qualityImage, "UI_Common", "icon_Grade"..cfg.company_quality)
    if iconImageGo then
        iconImageGo:SetActive(false)
    end
    local companyName = GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME")
    local nameTxt = self:GetComp("RootPanel/info/basic/name/text", "TMPLocalization")
    self:SetText("RootPanel/info/basic/name/text", companyName)

    local invited = CompanyMode:GetRoomIndexByCompanyId(data.id) ~= nil
    local invitedGo = self:GetGo("RootPanel/info/basic/icon/if_invited")
    invitedGo:SetActive(invited)

    local toSet = {nameTxt, qualityImage}
    self:ArrangeWidget(toSet, true, 3)

    local companyDesc = GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_DESC")
    self:SetText("RootPanel/info/basic/desc/text", companyDesc)

    self:RefreshStar(data.lv, cfg.levelMax)

    self:RefreshCompanyLevel(self:GetGo("RootPanel/info/basic/labelHolder"), cfg["company_label"..GameConfig:GetLangageFileSuffix()])

    --self:GetGo("RootPanel/info/reward"):SetActive(data.rewardAble)--领奖功能好像去掉了??

    local pro = self:GetComp("RootPanel/info/basic/prog", "Slider")
    local currExp = CompanyMode:GetCompanyExp(data.id)
    local maxExp = cfg.expMax[data.lv] or 1--满级
    local expProgress = currExp / maxExp
    expProgress = expProgress > 1 and 1 or expProgress
    pro.value = expProgress
    self:SetText("RootPanel/info/basic/prog/pro", string.format("%.2f", expProgress*100).."%")

    if iconImageGo then
        iconImageGo:SetActive(true)
    end
end

function CompanyMapInfoUIView:RefreshStar(companyLevel, maxLevel)
    local levelHolder = self:GetGo("RootPanel/info/basic/levelHolder")
    local tempPre = self:GetGo(levelHolder, "star")
    local currLv
    for i = 1, maxLevel - 1 do
        currLv = GameObject.Instantiate(tempPre, levelHolder.transform)
        self:GetGo(currLv, "on"):SetActive(i < companyLevel)
    end
    tempPre:SetActive(false)
end

function CompanyMapInfoUIView:RefreshCompanyLevel(root, types)
    local tempPre = self:GetGo(root, "type")
    local currPre
    for i = 1, #types do
        currPre = GameObject.Instantiate(tempPre, root.transform)
        self:SetSprite(self:GetComp(currPre, "", "Image"), "UI_Common", "icon_tag_"..types[i], nil, true)
        self:SetText(currPre, "name", GameTextLoader:ReadText("TXT_COMPANY_TAG_"..types[i]))
    end
    tempPre:SetActive(false)
end

return CompanyMapInfoUIView