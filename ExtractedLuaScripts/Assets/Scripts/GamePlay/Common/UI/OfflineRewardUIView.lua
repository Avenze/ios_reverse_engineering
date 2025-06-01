local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local GameUIManager = GameTableDefine.GameUIManager
local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local TimerMgr = GameTimeManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local ResMgr = GameTableDefine.ResourceManger
local ChooseUI = GameTableDefine.ChooseUI
local MainUI = GameTableDefine.MainUI
local IntroduceUI = GameTableDefine.IntroduceUI
local OfflineManager = GameTableDefine.OfflineManager

local OfflineRewardUIView = Class("OfflineRewardUIView", UIView)

local AD_RATIO = 3

function OfflineRewardUIView:ctor()
    self.super:ctor()
    self.model = nil

    self.rewardItem = nil
    self.rewardEuroItem = nil
    self.offlineTimeSlider = nil
    self.claimBtn = nil
    self.trebleBtn = nil
    self.quitBtn = nil
    self.warningGO = nil
    self.bannerGO = nil
    self.gotoBtn = nil
end

--
--function OfflineRewardUIView:OnEnter()
--    --GameSDKs:Track("ad_button_show", {video_id = 10001, video_namne = GameSDKs:GetAdName(10001)})
--    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
--    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10001, state = 0, revenue = 0})
--
--    local quitBtn = self:GetComp("RootPanel/quitBtn", "Button")
--    self:SetButtonClickHandler(quitBtn, function()
--        MainUI:HideButton("EventArea/OfflineReward", true)
--        IntroduceUI:IntroduceEachDay()
--        self:DestroyModeUIObject()
--    end)
--
--    self.rewardList = OfflineRewardUI:NewGetRewardValueList()
--
--    self:GetGo("RootPanel/warining"):SetActive(OfflineRewardUI:NewIsMax())
--    --local totalTimeLimit = OfflineRewardUI:GetOfflineMaxTime() / 3600
--    local offlineTimeList = OfflineRewardUI:NewOffTimePassSecond()
--    for k,v in pairs(offlineTimeList) do
--        local maxTime = OfflineManager:GetOfflineMaxTime(k)
--        if v > maxTime then
--            offlineTimeList[k] = maxTime
--        end
--    end
--    --offlineTime = offlineTime < totalTimeLimit * 3600 and offlineTime or totalTimeLimit * 3600
--    --local timeTxt = TimerMgr:FormatTimeLength(offlineTime)
--
--    -- local totalTime = TimerMgr:FormatTimeLength(totalTimeLimit*3600)
--    -- local theFirst = string.find(totalTime, ':')
--    -- local theSecond = string.find(totalTime, ':', theFirst + 1)
--    -- totalTime = string.sub(totalTime, 1, theSecond-1)
--    -- maxTime = string.format(maxTime, totalTime)
--
--    local maxTime = GameTextLoader:ReadText("TXT_MISC_OFFLINE_LIMIT")
--
--    self:SetText("RootPanel/MidPanel/reward/item/offlineTime/prog/limit", TimerMgr:FormatTimeLength(OfflineManager:GetOfflineMaxTime(1)))
--    self:SetText("RootPanel/MidPanel/reward/item/offlineTime/prog/time", TimerMgr:FormatTimeLength(offlineTimeList[1]))
--
--    self:SetText("RootPanel/MidPanel/reward/item_Euro/offlineTime/prog/limit", TimerMgr:FormatTimeLength(OfflineManager:GetOfflineMaxTime(2)))
--    self:SetText("RootPanel/MidPanel/reward/item_Euro/offlineTime/prog/time", TimerMgr:FormatTimeLength(offlineTimeList[2]))
--
--    self:SetText("RootPanel/MidPanel/reward/item/money/num", '+'.. Tools:SeparateNumberWithComma(self.rewardList[1]))
--    self:SetText("RootPanel/MidPanel/reward/item_Euro/money/num", '+'.. Tools:SeparateNumberWithComma(self.rewardList[2]))
--
--    local progress = self:GetComp("RootPanel/MidPanel/reward/item/offlineTime/prog", "Slider")
--    local progressEro = self:GetComp("RootPanel/MidPanel/reward/item_Euro/offlineTime/prog", "Slider")
--    self:GetGo("RootPanel/MidPanel/reward/item_Euro"):SetActive(self.rewardList[2] ~= 0)
--
--    --local curr = offlineTime / (totalTimeLimit * 3600)
--    progress.value = offlineTimeList[1]/(OfflineManager:GetOfflineMaxTime(1))
--    progressEro.value = offlineTimeList[2]/(OfflineManager:GetOfflineMaxTime(2))
--
--
--    local btn = self:GetComp("RootPanel/SelectPanel/ClaimBtn", "Button")
--    self:SetButtonClickHandler(btn, function()
--        local rewardValue = OfflineRewardUI:NewGetRewardValueList()[1]
--
--        local success = function()
--            btn.interactable = false
--            OfflineRewardUI:NewGetReward(1)
--            -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10001})
--            EventManager:DispatchEvent("FLY_ICON", btn.gameObject.transform.position,
--            2, rewardValue)
--            IntroduceUI:IntroduceEachDay()
--            self:DestroyModeUIObject()
--            -- OfflineRewardUI:UpdateLeaveTime()
--            -- LocalDataManager:WriteToFileInmmediately()
--        end
--
--        ChooseUI:EarnCash(rewardValue, success)
--    end)
--
--    local btn2 = self:GetComp("RootPanel/SelectPanel/TribleBtn", "Button")
--    self:SetButtonClickHandler(btn2, function()
--        local rewardValue = OfflineRewardUI:GetRewardValueList()[1] * 3
--        local success = function()
--            btn2.interactable = false
--            local pos = btn2.gameObject.transform.position
--            local callback = function()
--
--                OfflineRewardUI:NewGetReward(3)
--                EventManager:DispatchEvent("FLY_ICON", pos,
--                2, rewardValue)
--                IntroduceUI:IntroduceEachDay()
--                self:DestroyModeUIObject()
--                -- LocalDataManager:WriteToFileInmmediately()
--            end
--
--            GameSDKs:PlayRewardAd(callback,
--            function()
--                if btn2 then
--                    btn2.interactable = true
--                end
--            end,
--            function()
--                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
--                if btn2 then
--                    btn2.interactable = true
--                end
--            end,
--            10001)
--        end
--
--        ChooseUI:EarnCash(rewardValue, success)
--    end)
--
--    local btnOffTime = self:GetComp("RootPanel/banner_offline", "Button")
--    btnOffTime.gameObject:SetActive(GameConfig:IsIAP())
--    self:SetButtonClickHandler(btnOffTime, function()
--        GameTableDefine.ShopUI:OpenAndTurnPage(1015)
--        self:DestroyModeUIObject()
--        MainUI:HideButton("EventArea/OfflineReward", true)
--    end)
--
--    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
--    btnNoAD.gameObject:SetActive(false)
--    -- self:SetButtonClickHandler(btnNoAD, function()
--    --     GameTableDefine.ShopUI:OpenAndTurnPage("noAD")
--    -- end)
--    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self:GetComp("RootPanel", "RectTransform"))
--end
--
--function OfflineRewardUIView:OnPause()
--end
--
--function OfflineRewardUIView:OnResume()
--end
--
--function OfflineRewardUIView:OnExit()
--    self.super:OnExit(self)
--end

function OfflineRewardUIView:OnEnter()
    self.model = OfflineRewardUI.model
    self.rewardItem = self:GetGo("RootPanel/MidPanel/reward/item")
    self.rewardEuroItem = self:GetGo("RootPanel/MidPanel/reward/item_Euro")
    self.offlineTimeSlider = self:GetComp("RootPanel/InfoPanel/offlineTime/prog", "Slider")
    self.claimBtn = self:GetComp("RootPanel/MidPanel/reward/SelectPanel/ClaimBtn", "Button")
    self.trebleBtn = self:GetComp("RootPanel/MidPanel/reward/SelectPanel/TribleBtn", "Button")
    self.quitBtn = self:GetComp("RootPanel/MidPanel/reward/quitBtn", "Button")
    self.warningGO = self:GetGo("RootPanel/warining")
    self.bannerGO = self:GetGo("RootPanel/banner_offline")

    self:Refresh()
    
    local curAreaOfflineData = self.model.offlineData.areaData[self.model.countryID]
    GameSDKs:TrackForeign("debugger", { system = "Offline", desc = "打开离线弹窗", value = tostring(curAreaOfflineData.offlineReward) })
end

function OfflineRewardUIView:OnExit()

end

---根据当前不同的地区, 刷新页面显示
function OfflineRewardUIView:Refresh()
    local curRewardItem = nil
    if self.model.countryID == 1 then
        self.rewardItem:SetActive(true)
        self.rewardEuroItem:SetActive(false)
        curRewardItem = self.rewardItem
    else
        self.rewardItem:SetActive(false)
        self.rewardEuroItem:SetActive(true)
        curRewardItem = self.rewardEuroItem
    end

    local curAreaOfflineData = self.model.offlineData.areaData[self.model.countryID]
    self:SetText(curRewardItem, "money/normal/num",
        "+" .. Tools:SeparateNumberWithComma(curAreaOfflineData.offlineReward))
    self:SetText(curRewardItem, "money/ad/num_1",
        "+" .. Tools:SeparateNumberWithComma(curAreaOfflineData.offlineReward * AD_RATIO))
    self:SetText(curRewardItem, "money/ad/num_2",
        "+" .. Tools:SeparateNumberWithComma(curAreaOfflineData.offlineReward * AD_RATIO))
    self.offlineTimeSlider.value = curAreaOfflineData.offlineTime / self.model.maxTime
    self:SetText("RootPanel/InfoPanel/offlineTime/prog/maxLimit/time", self.model.maxTime / 3600 .. "H")
    local tipStr = GameTextLoader:ReadText("TXT_MISC_OFFLINE_REWARD")
    --local offlineTimeH = tostring(curAreaOfflineData.offlineTimeSum // 3600)
    --local offlineTimeM = tostring(curAreaOfflineData.offlineTimeSum % 3600 // 60)
    --local offlineMaxH = tostring(math.min(self.model.maxTime, curAreaOfflineData.offlineTime) // 3600)
    --local offlineMaxM = tostring(math.min(self.model.maxTime, curAreaOfflineData.offlineTime) % 3600 // 60)
    --tipStr = string.gsub(tipStr, "%[hour_left%]", math.floor(offlineTimeH))
    --tipStr = string.gsub(tipStr, "%[min_left%]", math.floor(offlineTimeM))
    --tipStr = string.gsub(tipStr, "%[hour_gain%]", math.floor(offlineMaxH))
    --tipStr = string.gsub(tipStr, "%[min_gain%]", math.floor(offlineMaxM))
    --self:SetText("RootPanel/InfoPanel/offlineTime/tip/text", tipStr)
    self:SetText("RootPanel/InfoPanel/offlineTime/prog/info/timeLeft", GameTimeManager:FormatTimeLength(math.min(curAreaOfflineData.offlineTimeSum, self.model.maxTime)))
    self:SetText("RootPanel/InfoPanel/offlineTime/prog/info/timeLimit", GameTimeManager:FormatTimeLength(self.model.maxTime))
    

    self:SetButtonClickHandler(self.claimBtn, function()
        local rewardValue = curAreaOfflineData.offlineReward

        local success = function()
            self.claimBtn.interactable = false
            -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10001})
            EventManager:DispatchEvent("FLY_ICON", self.claimBtn.gameObject.transform.position,
                self.model.countryID == 1 and 2 or 6, rewardValue, function()
                    OfflineRewardUI:NewGetReward(1)
                end)
            IntroduceUI:IntroduceEachDay()
            self:DestroyModeUIObject()
            -- OfflineRewardUI:UpdateLeaveTime()
            -- LocalDataManager:WriteToFileInmmediately()
        end

        ChooseUI:EarnCash(rewardValue, success)
    end)
    self:SetButtonClickHandler(self.trebleBtn, function()
        local rewardValue = curAreaOfflineData.offlineReward * AD_RATIO
        local success = function()
            self.trebleBtn.interactable = false
            local pos = self.trebleBtn.gameObject.transform.position
            local callback = function()
                EventManager:DispatchEvent("FLY_ICON", pos, self.model.countryID == 1 and 2 or 6, rewardValue, function()
                    OfflineRewardUI:NewGetReward(AD_RATIO)
                end)
                IntroduceUI:IntroduceEachDay()
                self:DestroyModeUIObject()
                -- LocalDataManager:WriteToFileInmmediately()
            end

            GameSDKs:PlayRewardAd(callback, function()
                if self.trebleBtn then
                    self.trebleBtn.interactable = true
                end
            end, function()
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
                if self.trebleBtn then
                    self.trebleBtn.interactable = true
                end
            end, 10001)
        end

        ChooseUI:EarnCash(rewardValue, success)
    end)
    self:SetButtonClickHandler(self.quitBtn, function()
        MainUI:HideButton("EventArea/OfflineReward", true)
        IntroduceUI:IntroduceEachDay()
        self:DestroyModeUIObject()
    end)
    self.warningGO:SetActive(curAreaOfflineData.reachMaximum)


    if self.model.recommend then
        self.bannerGO:SetActive(true)
        local show = self:ShowOfflineBannerById(self.model.recommend.id)
        --self:SetSprite(self.offlineManagerImage, "UI_Shop", self.model.recommend.icon)
        local curMaxTimeFormat = GameTimeManager:FormatTimeLength(self.model.maxTime)
        local buyTimeFormat = GameTimeManager:FormatTimeLength(self.model.recommend.amount * 3600 + self.model.maxTime)
        self:SetText(show, "now/time", curMaxTimeFormat)
        self:SetText(show, "new/time_1", buyTimeFormat)
        self:SetText(show, "new/time_2", buyTimeFormat)
        self:SetText(show, "new/time_3", buyTimeFormat)
        self.gotoBtn = self:GetComp(show, "gotoBtn", "Button")
        self:SetButtonClickHandler(self.gotoBtn, function()
            GameTableDefine.ShopUI:OpenAndTurnPage(1015)
            self:DestroyModeUIObject()
            MainUI:HideButton("EventArea/OfflineReward", true)
            -- GameSDKs:TrackForeign("button_event", {offlinereward = 1})
        end)
    else
        self.bannerGO:SetActive(false)
    end
end

function OfflineRewardUIView:ShowOfflineBannerById(shopID)
    if not shopID then
        return
    end
    local childs = UnityHelper.GetAllChilds(self.bannerGO)
    local showChild = nil
    for i = 0, childs.Length - 1 do
        local curGO = childs[i].gameObject
        curGO:SetActive(curGO.name == tostring(shopID))
        showChild = curGO.name == tostring(shopID) and curGO or showChild
    end
    return showChild
end

return OfflineRewardUIView
