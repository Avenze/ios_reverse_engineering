local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local ExchangeUI = GameTableDefine.ExchangeUI
local CountryMode = GameTableDefine.CountryMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local ResourceManger = GameTableDefine.ResourceManger
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local CompanysUI = GameTableDefine.CompanysUI

local ContractUIView = Class("ContractUIView", UIView)

function ContractUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ContractUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
    self.currMonth = 12

    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD())
    self:SetButtonClickHandler(btnNoAD, function()
        GameTableDefine.ShopUI:OpenAndTurnPage(1009)
    end)
end

function ContractUIView:OnExit()
end

function ContractUIView:Show(data)--就是config_company的数据
    --local movein_cost = ExchangeUI:CurrencyExchange(1, CountryMode:GetCurrCountry(), data.movein_cost)
    self:SetText("RootPanel/ContractPanel/company/name/text",
    GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME"))
    self:SetText("RootPanel/ContractPanel/company/desc", GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_DESC"))
    local currLv = CompanyMode:GetCompanyLevel(data.id)
    local isMax = CompanyMode:CompanyLvMax(data.id)

    local totalRent = GameTextLoader:ReadText("TXT_CONTRACT_CONTENT_1")
    local rents = FloorMode:GetRent(FloorMode.m_curRoomIndex, true)
    rents = rents + data.base_rent[currLv < data.levelMax and currLv or data.levelMax]
    rents = rents * FloorMode:GetSceneEnhance()
    
    totalRent = string.format(totalRent, rents)

    self:SetText("RootPanel/ContractPanel/contract/1/desc", totalRent)

    self:SetText("RootPanel/ContractPanel/btn/ConfirmBtn/bg/cost", Tools:SeparateNumberWithComma(data.movein_cost))
    self:SetSprite(self:GetComp("RootPanel/ContractPanel/btn/ConfirmBtn/bg/icon", "Image"), "UI_Main", ResMgr:GetResIcon(CountryMode:GetCurrCountryCurrency()))
    local stayTime = GameTextLoader:ReadText("TXT_CONTRACT_REAL_TIME")
    local totalTime
    if data.stayTime % 3600 == 0 then
        totalTime = string.format("%.0f", data.stayTime/3600)
    else
        totalTime = string.format("%.1f", data.stayTime/3600)
    end
    stayTime = string.format(stayTime, totalTime)
    self:SetText("RootPanel/ContractPanel/contract/3/desc2/time", stayTime)
    self:SetSprite(self:GetComp("RootPanel/ContractPanel/company/icon", "Image"), "UI_Common", data.company_logo..GameConfig:GetLangageFileSuffix(), nil, true)
    self:RefreshCompanyLevel(currLv - 1, data.levelMax)

    local textName = self:GetComp("RootPanel/ContractPanel/company/name/text", "TMPLocalization")
    local spriteQuality = self:GetComp("RootPanel/ContractPanel/company/name/quality", "Image")
    self:SetSprite(spriteQuality, "UI_Common", "icon_Grade"..data.company_quality)
    local toSet = {textName, spriteQuality}
    self:ArrangeWidget(toSet, true, 15)

    local workspaceNum = FloorMode:GetFurnitureNum(10001, 1, FloorMode.m_curRoomIndex)
    local invite = self:GetComp("RootPanel/ContractPanel/btn/ConfirmBtn","Button")
    invite.interactable = ResMgr:GetLocalMoney() >= data.movein_cost and workspaceNum >= data.deskNeed --并且办公工位是6个...

    local btn = self:GetComp("RootPanel/ContractPanel/btn/ConfirmBtn","Button")
    self:SetButtonClickHandler(btn, function()
        btn.interactable = false
        local cb = function(isEnough)
            if isEnough then
                --local workTime = 3600 * self.currMonth * Tools:GetCheat(1, 1/900)
                CompanyMode:InviteCompany(FloorMode.m_curRoomIndex, data.id, data.stayTime, data.movein_cost)
                GameSDKs:TrackForeign("corp_rent", { corp_id = data.id, corp_level_new = tonumber(currLv) or 0, renewal = false, max = isMax})
                
                if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.ROOM_BUILDING_UI) then                    
                    RoomBuildingUI:ShowRoomPanelInfo(FloorMode.m_curRoomId)
                end
                self:GetGo("RootPanel/ContractPanel/contract/done"):SetActive(true)
                local ani = self:GetComp("RootPanel/ContractPanel/contract/done", "Animation")
                AnimationUtil.Play(ani, "UI_contract_signed_anim", function()
                    CompanysUI:GetView():DestroyModeUIObject()
                    self:DestroyModeUIObject()
                end)
                LocalDataManager:WriteToFileInmmediately()
                 --2024-8-20添加用于的钞票消耗增加埋点上传
                 local type = CountryMode:GetCurrCountry()
                 local amount = data.movein_cost
                 local change = 1
                 local position = "["..data.id.."]公司签约"
                 GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0,amount_new = tonumber(amount) or 0, position = position})
                 GameSDKs:TrackControlCheckData("af", "af,corp_rent_10", {})
            end
        end

        ResMgr:SpendLocalMoney(data.movein_cost, nil, cb)
    end)

    local adBtn = self:GetComp("RootPanel/ContractPanel/btn/VidenBtn", "Button")
    adBtn.interactable = workspaceNum >= data.deskNeed

    if workspaceNum >= data.deskNeed then
        --GameSDKs:Track("ad_button_show", {video_id = 10007, video_namne = GameSDKs:GetAdName(10007)})
        -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
        -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10007, state = 0, revenue = 0})
    end

	self:SetButtonClickHandler(adBtn, function()
        adBtn.interactable = false

        local adUnlock = function()
            CompanyMode:InviteCompany(FloorMode.m_curRoomIndex, data.id, data.stayTime, 0)
            local isMax = CompanyMode:CompanyLvMax(data.id)
            GameSDKs:TrackForeign("corp_rent", { corp_id = data.id, corp_level_new = tonumber(currLv) or 0, renewal = false, max = isMax})
          
            if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.ROOM_BUILDING_UI) then
                RoomBuildingUI:ShowRoomPanelInfo(FloorMode.m_curRoomId)
            end
            --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10007, name = GameSDKs:GetAdName(10007), current_money = GameTableDefine.ResourceManger:GetCash()})
            self:GetGo("RootPanel/ContractPanel/contract/done"):SetActive(true)
            local ani = self:GetComp("RootPanel/ContractPanel/contract/done", "Animation")
                AnimationUtil.Play(ani, "UI_contract_signed_anim", function()
                CompanysUI:GetView():DestroyModeUIObject()
                self:DestroyModeUIObject()
            end)
            
        end

        --GameSDKs:Track("play_video", {video_id = 10006, current_money = GameTableDefine.ResourceManger:GetCash()})
        GameSDKs:PlayRewardAd(adUnlock, 
        function()
            if adBtn then
                adBtn.interactable = true
            end
        end,
        function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            if adBtn then
                adBtn.interactable = true
            end
        end,
        10007)
    end)
end

function ContractUIView:RefreshCompanyLevel(companyLevel, maxLevel)
    local levelHolder = self:GetGo("RootPanel/ContractPanel/company/levelHolder")
    local childCount = levelHolder.transform.childCount
    local level
    for i = 1, childCount do
        self:GetGo(levelHolder,"star"..i):SetActive(i < maxLevel)
        level = self:GetGo(levelHolder, "star" .. i .. "/on")
        if i <= companyLevel then
            level:SetActive(true)
        end
    end
end

return ContractUIView