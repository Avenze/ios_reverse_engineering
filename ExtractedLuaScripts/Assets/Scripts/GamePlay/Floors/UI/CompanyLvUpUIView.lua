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

local PiggyBankUI = GameTableDefine.PiggyBankUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ActivityUI = GameTableDefine.ActivityUI
local CompanyMode = GameTableDefine.CompanyMode
local CompanyLvUpUI = GameTableDefine.CompanyLvUpUI
local StarMode = GameTableDefine.StarMode
local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI

local CompanyLvUpUIView = Class("CompanyLvUpUIView", UIView)

function CompanyLvUpUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CompanyLvUpUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CompanyLvUpUIView:OnExit()
    EventManager:DispatchEvent("UPGRADE_COMPANY")
    self.super:OnExit(self)
end

function CompanyLvUpUIView:CheckClose(companyId)
    if self.currId and self.currId == companyId then
        self:DestroyModeUIObject()
    end
end

function CompanyLvUpUIView:Refresh(companyId)
    self.currId = companyId
    local data = ConfigMgr.config_company[companyId]
    local currLv = CompanyMode:GetCompanyLevel(data.id)
    local isMax = CompanyMode:CompanyLvMax(companyId)
    local reward = data["lvReward"][currLv] or {}

    local currRoomIndex = CompanyMode:GetRoomIndexByCompanyId(companyId)
    local currRent = data.base_rent[currLv < data.levelMax and currLv or data.levelMax]
    local nextRent = data.base_rent[currLv + 1 < data.levelMax and currLv + 1 or data.levelMax]

    -- local sceneImprove = FloorMode:GetSceneEnhance()
    -- currRent = currRent * sceneImprove
    -- nextRent = nextRent * sceneImprove

    self:SetText("HeadPanel/other_reward/r/rent/cur", "+" .. currRent)
    self:SetText("HeadPanel/other_reward/r/rent/next", "+" .. nextRent)

    local rewardDiamond = 0
    local allReward = data.lvReward[currLv]
    for k,v in pairs(allReward) do
        if k % 2 ~= 0 then
            if v == 5 then
                self:SetText("HeadPanel/fame_reward/reward/num", allReward[k+1])
            elseif v == 3 then
                rewardDiamond = allReward[k + 1]
            end
        end
    end
    --带修改
    -- local rewardDiamondRoot = self:GetGo("HeadPanel/other_reward/d")
    -- rewardDiamondRoot:SetActive(rewardDiamond > 0)
    -- if rewardDiamond > 0 then
    --     self:SetText(rewardDiamondRoot, "num", "+" .. rewardDiamond)
    -- end
    -- local starReward = data.lvReward[currLv][2]
    -- self:SetText("HeadPanel/reward/num", starReward)

    -- self:GetGo("HeadPanel/money"):SetActive(reward[3] ~= nil)
    -- if reward[3] then
    --     self:SetText("HeadPanel/money/num", reward[4])
    -- end

    self:SetText("HeadPanel/name/text",
    GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME"))

    self:SetSprite(self:GetComp("HeadPanel/logo", "Image"), "UI_Common", data.company_logo..GameConfig:GetLangageFileSuffix(), nil, true)

    self:RefreshCompanyLevel(currLv - 1, data.levelMax)

    local button = self:GetComp("HeadPanel/btn_rise", "Button")
    self:SetButtonClickHandler(button, function()
        button.interactable = false
        CompanyLvUpUI:GetReward(companyId, currLv, function()
            MainUI:RefreshQuestHint()
            self:DestroyModeUIObject()
            --存钱罐累加值 加二号类型
            PiggyBankUI:AddValue(2)
            isMax = CompanyMode:CompanyLvMax(companyId)
            GameSDKs:Track("corp_upgrade", {corp_id = companyId, corp_level_new = tonumber(currLv) or 0, max = isMax})
        end)
    end)
end

function CompanyLvUpUIView:RefreshCompanyLevel(companyLevel, maxLevel)
    local levelHolder = self:GetGo("HeadPanel/levelHolder")
    local tempPre = self:GetGo(levelHolder, "star")
    local currLv
    for i = 1, maxLevel - 1 do
        currLv = GameObject.Instantiate(tempPre, levelHolder.transform)
        self:GetGo(currLv, "on"):SetActive(i <= companyLevel + 1)
        if i == companyLevel + 1 then
            self:GetGo(currLv, "on"):SetActive(false)
            local currGo = currLv
            GameTimer:CreateNewMilliSecTimer(500, function()                           
                local ani = self:GetComp(currGo, "", "Animation")
                AnimationUtil.Play(ani, "CompanyLevelup_Anim")             
            end, false, false)  
        end
    end
    tempPre:SetActive(false)
end
return CompanyLvUpUIView
