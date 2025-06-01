local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local EventTriggerListener = CS.Common.Utils.EventTriggerListener
local EventType = CS.UnityEngine.EventSystems.EventTriggerType

local GameUIManager = GameTableDefine.GameUIManager
local CompanysUI = GameTableDefine.CompanysUI
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local ContractUI = GameTableDefine.ContractUI
local StarMode = GameTableDefine.StarMode
local TimerMgr = GameTimeManager
local CompanysUIView = Class("CompanysUIView", UIView)
local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger

function CompanysUIView:ctor()
	self.super:ctor()
	self.m_data = {}
end

function CompanysUIView:OnEnter()
    self.openAni = false
    self:SetButtonClickHandler(self:GetComp("RootPanel/BottomPanel/QuitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self.currProgress = FloorMode:GetCurrRoomProgress()

    self:InitButton()

    self.timeText = self:GetComp("RootPanel/BottomPanel/RerollBtn/time", "TMPLocalization")


    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(false)
    -- self:SetButtonClickHandler(btnNoAD, function()
    --     GameTableDefine.ShopUI:OpenAndTurnPage("noAD")
    -- end)
end

function CompanysUIView:OnPause()
	print("CompanysUIView:OnPause")
end

function CompanysUIView:OnResume()
    print("CompanysUIView:OnResume")
end

function CompanysUIView:OnExit()
    self.super:OnExit(self)
    self.m_data = nil
    self:StopTimer()
    if self.__timers then
        GameTimer:StopTimer(self.__timers["companyRefresh"])
        self.__timers["companyRefresh"] = nil
    end
    print("CompanysUIView:OnExit")
end

function CompanysUIView:RefreshCompany(index, tran)
    local root = tran.gameObject
    local data = self.companysPool[index]

    self:SetSprite(self:GetComp(root, "info/qua_back", "Image"), "UI_BG", "icon_bg_Grade"..data.company_quality)
    self:SetSprite(self:GetComp(root, "info/icon", "Image"), "UI_Common", data.company_logo..GameConfig:GetLangageFileSuffix())
    self:SetSprite(self:GetComp(root, "info/qua_icon", "Image"), "UI_Common", "icon_Grade"..data.company_quality)
    --self:SetSprite(self:GetComp(root, "info/qua_frame", "Image"), "UI_BG", "icon_frame_Grade"..data.company_quality)
    
    self:SetText(root, "info/name", GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME"))
    local companyDesc = GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_DESC")
    self:SetText(root, "info/desc", companyDesc)

    local qualityImage = self:GetComp(root, "info/qua_icon", "Image")
    local txtName = self:GetComp(root, "info/name", "TMPLocalization")
    local toSet = {txtName, qualityImage}
    --self:ArrangeWidget(toSet, true, 15)
    
    local requireText = GameTextLoader:ReadText("TXT_CONTRACT_WORKSPACE_REQUIRE")
    requireText = string.format(requireText, data.deskNeed)
    self:SetText(root, "info/require", requireText)
    --self:SetText(root,"info/cost", data.movein_cost, canInvite and "000000" or "E24028")

    local inviteAlready = CompanyMode:CheckCompanyAlreadyExists(data.id)
    local workspaceNum = FloorMode:GetFurnitureNum(10001, 1, FloorMode.m_curRoomIndex)
    local haveChance = workspaceNum >= data.deskNeed
    local haveMoney = ResourceManger:GetCash() >= data.movein_cost

    self:GetGo(root, "info/existBtn"):SetActive(inviteAlready)
    self:GetGo(root, "info/require"):SetActive(not haveChance and not inviteAlready)
    self:GetGo(root, "info/InviteBtn"):SetActive(not inviteAlready and haveChance)

    --self:ShowType(self:GetGo(root, "info/label"), data.company_label)
    local currLv = CompanyMode:GetCompanyLevel(data.id)
    self:ShowLevel(self:GetGo(root, "info/levelHolder"), currLv - 1, data.levelMax)

    local button = self:GetComp(root, "info/InviteBtn", "Button")
    --button.interactable = canInvite
    self:SetButtonClickHandler(button, function()
        if data.room_star > StarMode:GetStar() and not self.guideInvite then
            local message = GameTextLoader:ReadText("TXT_TIP_LACK_STAR")
            message = message:gsub("%%s", data.room_star)
            EventManager:DispatchEvent("UI_NOTE", message)
        elseif data.locate_require > FloorMode:GetCurrRoomProgress()*100 and not self.guideInvite then
            local message = GameTextLoader:ReadText("TXT_TIP_LACK_PROGRESS")
            message = message:gsub("%%s", data.locate_require).."%"
            EventManager:DispatchEvent("UI_NOTE", message)
        else
            ContractUI:Refresh(data)
        end
    end)
end

function CompanysUIView:ShowLevel(root, companyLevel, maxLevel)
    local childCount = root.transform.childCount
    local level
    for i = 1, childCount do
        self:GetGo(root,"star"..i):SetActive(i < maxLevel)
        level = self:GetGo(root, "star" .. i .. "/on")
        level:SetActive(i <= companyLevel)
    end
end

function CompanysUIView:ShowType(root, companyTypes)
    for i = 1, root.transform.childCount do
        local curr = self:GetGo(root, tostring(i))
        if i <= #companyTypes then
            curr:SetActive(true)
            self:SetSprite(self:GetComp(curr, "", "Image"), "UI_Common", "icon_tag_"..companyTypes[i], nil, true)
            self:SetText(curr, "text", GameTextLoader:ReadText("TXT_COMPANY_TAG_"..companyTypes[i]))
        else
            curr:SetActive(false)
        end
    end
end

function CompanysUIView:RefreshAll()
    local root = self:GetGo("RootPanel/ListPanel/BuidlingList/Viewport/Content")
    for i = 1, 5 do
        self:RefreshCompany(i, self:GetTrans(root, tostring(i)))
    end
end

function CompanysUIView:Refresh(currCompanys, guideInvite)
    self.aniBefor = nil
    self.companysPool = currCompanys
    self.guideInvite = guideInvite--新手引导的引入公司,无视条件

    local rootAni = self:GetComp("", "Animation")
    -- local companyAni = self:GetComp("RootPanel/ListPanel/BuidlingList/Viewport/Content", "Animation")
    self.needAni = CompanysUI:NeedAni()

    local content = self:GetGo("RootPanel/ListPanel/BuidlingList/Viewport/Content")
    content:SetActive(not self.needAni)

    if not self.openAni then
        AnimationUtil.Play(rootAni, "UI_slide_open", function()
            self.openAni = true
            if self.needAni then
                content:SetActive(true)
                -- AnimationUtil.Play(companyAni, "CompanyList_Anim")
            end
        end)
    elseif self.needAni then
        content:SetActive(true)
        -- AnimationUtil.Play(companyAni, "CompanyList_Anim")
    end

    self:RefreshAll()

    self:RefreshButton()
end

function CompanysUIView:RefreshButton()
    self.endPoint = CompanysUI:GetNextRefreshTime()
    local timeEnough = self.endPoint <= TimerMgr:GetCurrentServerTime(true)
    self:GetGo("RootPanel/BottomPanel/RerollBtn"):SetActive(not timeEnough)
    self:GetGo("RootPanel/BottomPanel/FreeBtn"):SetActive(timeEnough)
    if not timeEnough then

        --GameSDKs:Track("ad_button_show", {video_id = 10004, video_namne = GameSDKs:GetAdName(10004)})
        -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
        -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10004, state = 0, revenue = 0})

        self.__timers = self.__timers or {}
        if not self.__timers["companyRefresh"] then
            self.__timers["companyRefresh"] = GameTimer:CreateNewTimer(1, function()
                local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
                local timeTxt = TimerMgr:FormatTimeLength(t)
                if t > 0 then
                    self.timeText.text = timeTxt
                else
                    GameTimer:StopTimer(self.__timers["companyRefresh"])
                    self.__timers["companyRefresh"] = nil
                    self:RefreshButton()
                end
            end, true)
        end
    end
end

function CompanysUIView:InitButton()
    --初始化刷新,引进按钮
    local adBtn = self:GetComp("RootPanel/BottomPanel/RerollBtn", "Button")
    self:SetButtonClickHandler(adBtn, function()
        adBtn.interactable = false
        --先判定一波观看广告,成功之后再刷新
        local callback = function()
            CompanysUI:RefreshCompany(false)
            CompanysUI:OpenView()
            GameSDKs:TrackForeign("corp_refresh", {ad = GameTableDefine.ShopManager:IsNoAD() and 3 or 2 })
            --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10004, name = GameSDKs:GetAdName(10004), current_money = GameTableDefine.ResourceManger:GetCash()})
        end
        --GameSDKs:Track("play_video", {video_id = 10004,current_money = GameTableDefine.ResourceManger:GetCash()})
        GameSDKs:PlayRewardAd(callback,
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
        10004)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/BottomPanel/FreeBtn", "Button"), function()
        CompanysUI:RefreshCompany(true)
        CompanysUI:OpenView()
        GameSDKs:TrackForeign("corp_refresh", {ad = 1})
    end)
end

return CompanysUIView