local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local CountryMode = GameTableDefine.CountryMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject

local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local CompanysUI = GameTableDefine.CompanysUI

local RenewUIView = Class("RenewUIView", UIView)

function RenewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function RenewUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function RenewUIView:OnExit()
    self.super:OnExit(self)
end

function RenewUIView:Refresh(companyId, roomIndex, roomId)
    local cfg = ConfigMgr.config_company[companyId]
    if not cfg then
        return
    end

    local textName = self:GetComp("RootPanel/ContractPanel/company/name/text", "TMPLocalization")
    self:SetText("RootPanel/ContractPanel/company/name/text", GameTextLoader:ReadText("TXT_COMPANY_C"..cfg.id.."_NAME"))

    local companyQuality = self:GetComp("RootPanel/ContractPanel/company/name/quality", "Image")
    self:SetSprite(companyQuality, "UI_Common", "icon_Grade"..cfg.company_quality)

    local toSet = {textName, companyQuality}
    self:ArrangeWidget(toSet, true, 15)

    local currLv = CompanyMode:GetCompanyLevel(cfg.id)
    local maxLv = cfg.levelMax

    ---2024-10-29 fy根据需求调整续约显示的相关内容
    self:GetGo("RootPanel/RenewBtn"):SetActive(true)
    self:GetGo("RootPanel/FreeRenewBtn"):SetActive(false)
    self:GetGo("RootPanel/ReinviteBtn"):SetActive(true)
    self:GetGo("RootPanel/tips"):SetActive(currLv == maxLv)
    
    self:RefreshLevel(currLv, maxLv)

    self:SetSprite(self:GetComp("RootPanel/ContractPanel/company/icon", "Image"), "UI_Common", cfg.company_logo..GameConfig:GetLangageFileSuffix(), nil, true)
    self:SetSprite(self:GetComp("RootPanel/RenewBtn/icon", "Image"), "UI_Main", CountryMode.cash_icon, nil, true)
    local rentShow = nil
    if currLv ~= maxLv then
        rentShow = GameTextLoader:ReadText("TXT_RENEW_CONTRACT_NOMAX")
    else
        rentShow = GameTextLoader:ReadText("TXT_RENEW_CONTRACT_MAX")
    end
    local currCompany = cfg.base_rent[currLv < cfg.levelMax and currLv or cfg.levelMax]
    local nextCompany = cfg.base_rent[currLv + 1 < cfg.levelMax and currLv + 1 or cfg.levelMax]
    --local sceneImprove = FloorMode:GetSceneEnhance()
    --currCompany = currCompany * sceneImprove
    --nextCompany = nextCompany * sceneImprove
    rentShow = string.format(rentShow, currCompany, nextCompany)
    self:SetText("RootPanel/ContractPanel/contract/1/desc", rentShow)
    
    local inviteBtn = self:GetComp("RootPanel/RenewBtn", "Button")
    inviteBtn.interactable = ResMgr:GetLocalMoney() >= cfg.movein_cost

    self:SetText("RootPanel/RenewBtn/cost", Tools:SeparateNumberWithComma(cfg.movein_cost))
    
    local pro = self:GetComp("RootPanel/ContractPanel/company/prog", "Slider")
    local currExp = CompanyMode:GetCompanyExp(cfg.id)
    local maxExp = cfg.expMax[currLv] or 1--满级
    local expProgress = currExp / maxExp
    expProgress = expProgress > 1 and 1 or expProgress
    pro.value = expProgress
    self:SetText("RootPanel/ContractPanel/company/prog/pro", string.format("%.2f", expProgress*100).."%")

    self:SetButtonClickHandler(inviteBtn, function()--续签公司
        local cb = function(isEnough)
            if isEnough then--只是去掉续约的标识,更新显示...但是要延长一下时间...
                CompanyMode:RenewCompany(roomIndex, cfg.id, cfg.stayTime)
                local isMax = CompanyMode:CompanyLvMax(cfg.id)
                GameSDKs:TrackForeign("corp_rent", { corp_id = cfg.id, corp_level_new = tonumber(currLv), renewal = true, max = isMax })
                
                self:ClearnData(cfg.id, roomIndex)
                FloorMode:GetScene():InitRoomGo(roomId)
                self:DestroyModeUIObject()
            end
        end

        ResMgr:SpendLocalMoney(cfg.movein_cost, nil, cb)
    end)

    --2024-10-29 fy添加播放广告后续约的功能
    local freeAdRenewBtn = self:GetComp("RootPanel/FreeRenewBtn", "Button")
    self:SetButtonClickHandler(freeAdRenewBtn, function()
        freeAdRenewBtn.interactable = false
        GameSDKs:PlayRewardAd(function()
            CompanyMode:RenewCompany(roomIndex, cfg.id, cfg.stayTime)
                GameSDKs:TrackForeign("corp_rent", { corp_id = cfg.id, corp_level_new = tonumber(currLv), renewal = true })
                self:ClearnData(cfg.id, roomIndex)
                FloorMode:GetScene():InitRoomGo(roomId)
                freeAdRenewBtn.interactable = true
                self:DestroyModeUIObject()
        end,
        function()
            freeAdRenewBtn.interactable = true
        end,
        function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            freeAdRenewBtn.interactable = true
        end,
        10007)
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/ReinviteBtn", "Button"), function()--重新引进
        --清空数据
        CompanyMode:FireCompany(roomIndex, roomId, 1)


        FloorMode:SetCurrRoomInfo(roomIndex, roomId)
        CompanysUI:MakeEnableCompanys()
        CompanysUI:OpenView()
        self:ClearnData(companyId, roomIndex)
        FloorMode:GetScene():InitRoomGo(roomId)
        self:DestroyModeUIObject()
    end)
end

function RenewUIView:ClearnData(companyId, roomIndex)
    CompanysUI:ExcludeCompany(companyId, false)
    local data = FloorMode:GetCurrRoomLocalData(roomIndex)
    data.leaveCompany = nil
end

function RenewUIView:RefreshLevel(companyLevel, maxLevel)
    local levelHolder = self:GetGo("RootPanel/ContractPanel/company/levelHolder")
    local tempPre = self:GetGo(levelHolder, "star")
    local currLv
    for i = 1, maxLevel - 1 do
        currLv = GameObject.Instantiate(tempPre, levelHolder.transform)
        self:GetGo(currLv, "on"):SetActive(i < companyLevel)
    end
    tempPre:SetActive(false)
end

return RenewUIView