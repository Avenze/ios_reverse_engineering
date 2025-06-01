local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")


local HouseMode = GameTableDefine.HouseMode
-- local EventManager = require("Framework.Event.Manager")
-- local ViewUtils = require("GamePlay.Utils.ViewUtils")
-- local GameResMgr = require("GameUtils.GameResManager")

-- local FileHelper = CS.Common.Utils.FileHelper

-- local UnityHelper = CS.Common.Utils.UnityHelper
-- local Color = CS.UnityEngine.Color
-- local CompanyMode = GameTableDefine.CompanyMode
-- local FloorMode = GameTableDefine.FloorMode
-- local ConfigMgr = GameTableDefine.ConfigMgr
-- local ResMgr = GameTableDefine.ResourceManger
local ResMgr = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr

local HouseContractView = Class("HouseContractView", UIView)

function HouseContractView:ctor()
    self.super:ctor()
end

function HouseContractView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function HouseContractView:OnExit()
    self.super:OnExit(self)
end

function HouseContractView:ShowPanel(cfg, image, name, desc, price, carportNum)
    self:SetSprite(self:GetComp("RootPanel/ContractPanel/house/icon", "Image"), "UI_Common", image)
    
    self:SetText("RootPanel/ContractPanel/house/name", name)
    self:SetText("RootPanel/ContractPanel/house/desc", desc)

    self:SetText("RootPanel/ContractPanel/contract/1/desc", price)
    self:SetText("RootPanel/ContractPanel/contract/2/desc", carportNum)
    self:SetText("RootPanel/ContractPanel/contract/2/desc", carportNum)

    --local isIap = GameConfig:IsIAP()
    self:GetGo("RootPanel/ContractPanel/contract/3"):SetActive(true)
    --if isIap then
        local buildingId = cfg.id
        local data = ConfigMgr.config_buildings[buildingId]
        local txtRoom = GameTextLoader:ReadText("TXT_CONTRACT_HOUSE_CONTENT_3")
        txtRoom = string.format(txtRoom, data.wealth_buff)
        self:SetText("RootPanel/ContractPanel/contract/3/desc", txtRoom)
    --end

    self:SetText("RootPanel/ContractPanel/btn/buyBtn/bg/cost", Tools:SeparateNumberWithComma(cfg.price))

    local animation = self:GetComp("RootPanel/ContractPanel/contract/done", "Animation")
    local buyBtn = self:GetComp("RootPanel/ContractPanel/btn/buyBtn","Button")
    local returnBtn = self:GetComp("RootPanel/ContractPanel/btn/returnBtn","Button")
    --K117始终可以点击购买按钮，购买失败弹出兑换金币的界面
    --buyBtn.interactable = ResMgr:GetCash() >= cfg.price
    buyBtn.interactable = true
    self:SetButtonClickHandler(buyBtn, function()
        buyBtn.interactable = false
        HouseMode:BuyHouse(function(result)
            if result then
                self:PlayAnimation(animation, "UI_contract_signed_anim", function()
                    HouseMode:BoughtHouse()
                    self:DestroyModeUIObject()
                end)
            else
                buyBtn.interactable = true
                GameTableDefine.ShopInstantUI:EnterToCashBuy()
            end
        end)
    end)
    self:SetButtonClickHandler(returnBtn, function()
    end)
    -- 待定
    -- 
    -- returnBtn.interactable = true
    -- animation.gameObject:SetActive(true)
end

-- function HouseContractView:Show(data)--就是config_company的数据
--     self:SetText("RootPanel/ContractPanel/company/name/text",
--     GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME"))

--     local currLv = CompanyMode:GetCompanyLevel(data.id)

--     local totalRent = GameTextLoader:ReadText("TXT_CONTRACT_CONTENT_1")
--     rents = rents + data.base_rent[currLv < data.levelMax and currLv or data.levelMax]
--     rents = rents * FloorMode:GetSceneEnhance()
    
--     totalRent = string.format(totalRent, rents)

--     self:SetText("RootPanel/ContractPanel/contract/1/desc", totalRent)

--     self:SetText("RootPanel/ContractPanel/btn/ConfirmBtn/bg/cost", data.movein_cost)

--     local stayTime = GameTextLoader:ReadText("TXT_CONTRACT_REAL_TIME")
--     local totalTime
--     if data.stayTime % 3600 == 0 then
--         totalTime = string.format("%.0f", data.stayTime/3600)
--     else
--         totalTime = string.format("%.1f", data.stayTime/3600)
--     end
--     stayTime = string.format(stayTime, totalTime)
--     self:SetText("RootPanel/ContractPanel/contract/3/desc2/time", stayTime)
--     self:SetSprite(self:GetComp("RootPanel/ContractPanel/company/icon", "Image"), "UI_Common", data.company_logo..GameConfig:GetLangageFileSuffix(), nil, true)
--     self:RefreshCompanyLevel(currLv - 1, data.levelMax)

--     local textName = self:GetComp("RootPanel/ContractPanel/company/name/text", "TMPLocalization")
--     local spriteQuality = self:GetComp("RootPanel/ContractPanel/company/name/quality", "Image")
--     self:SetSprite(spriteQuality, "UI_Common", "icon_Grade"..data.company_quality)
--     local toSet = {textName, spriteQuality}
--     self:ArrangeWidget(toSet, true, 15)

--     local workspaceNum = FloorMode:GetFurnitureNum(10001, 1, FloorMode.m_curRoomIndex)
--     local invite = self:GetComp("RootPanel/ContractPanel/btn/ConfirmBtn","Button")
--     invite.interactable = ResourceManger:GetCash() >= data.movein_cost and workspaceNum >= data.deskNeed --并且办公工位是6个...

--     self:SetButtonClickHandler(self:GetComp("RootPanel/ContractPanel/btn/ConfirmBtn","Button"), function()

--         local cb = function(isEnough)
--             if isEnough then
--                 --local workTime = 3600 * self.currMonth * Tools:GetCheat(1, 1/900)
--                 CompanyMode:InviteCompany(FloorMode.m_curRoomIndex, data.id, data.stayTime)
--                 local ani = self:GetComp("RootPanel/ContractPanel/contract/done", "Animation")
--                 AnimationUtil.Play(ani, "CompanyInvite_Anim", function()
--                     self:DestroyModeUIObject()
--                 end)
--             end
--         end

--         ResMgr:SpendCash(data.movein_cost, nil, cb)
--     end)

--     local adBtn = self:GetComp("RootPanel/ContractPanel/btn/VidenBtn", "Button")
--     adBtn.interactable = workspaceNum >= data.deskNeed
-- 	self:SetButtonClickHandler(adBtn, function()
--         adBtn.interactable = false

--         local adUnlock = function()
--             CompanyMode:InviteCompany(FloorMode.m_curRoomIndex, data.id, data.stayTime)

--             local ani = self:GetComp("RootPanel/ContractPanel/contract/done", "Animation")
--                 AnimationUtil.Play(ani, "CompanyInvite_Anim", function()
--                 self:DestroyModeUIObject()
--             end)
            
--         end

--         --GameSDKs:Track("play_video", {video_id = 10006, current_money = GameTableDefine.ResourceManger:GetCash()})
--         GameSDKs:PlayRewardAd(adUnlock, 
--         function()
--             if adBtn then
--                 adBtn.interactable = true
--             end
--         end,
--         function()
--             if adBtn then
--                 adBtn.interactable = true
--             end
--         end,
--         10007)
--     end)
-- end

-- function HouseContractView:RefreshCompanyLevel(companyLevel, maxLevel)
--     local levelHolder = self:GetGo("RootPanel/ContractPanel/company/levelHolder")
--     local childCount = levelHolder.transform.childCount
--     local level
--     for i = 1, childCount do
--         self:GetGo(levelHolder,"star"..i):SetActive(i < maxLevel)
--         level = self:GetGo(levelHolder, "star" .. i .. "/on")
--         if i <= companyLevel then
--             level:SetActive(true)
--         end
--     end
-- end

return HouseContractView