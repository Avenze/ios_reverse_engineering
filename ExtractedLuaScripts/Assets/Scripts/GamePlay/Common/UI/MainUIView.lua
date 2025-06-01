local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local EventDispatcher = EventDispatcher

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local ParticleSystem = CS.UnityEngine.ParticleSystem
local ClipboardManager = CS.Game.Plat.ClipboardManager
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local RouletteUI = GameTableDefine.RouletteUI
local CountryMode = GameTableDefine.CountryMode
local PetInteractUI = GameTableDefine.PetInteractUI
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local DiamondShopUI = GameTableDefine.DiamondShopUI
local WorldListUI = GameTableDefine.WorldListUI
local MainUI = GameTableDefine.MainUI
local ActivityUI = GameTableDefine.ActivityUI
local Event001UI = GameTableDefine.Event001UI
local Event004UI = GameTableDefine.Event004UI
local Event003UI = GameTableDefine.Event003UI
local Event005UI = GameTableDefine.Event005UI
local Event006UI = GameTableDefine.Event006UI
local EventMeetingUI = GameTableDefine.EventMeetingUI
local FloorMode = GameTableDefine.FloorMode
local StarMode = GameTableDefine.StarMode
local GameClockManager = GameTableDefine.GameClockManager
local LightManager = GameTableDefine.LightManager
local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local SoundEngine = GameTableDefine.SoundEngine
local CityMode = GameTableDefine.CityMode
local CompanyMode = GameTableDefine.CompanyMode
local CityMapUI = GameTableDefine.CityMapUI
local OrderUI = GameTableDefine.OrderUI
local StockFullUI = GameTableDefine.StockFullUI
local OrderFinishUI = GameTableDefine.OrderFinishUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local GuideManager = GameTableDefine.GuideManager
local ChatEventManager = GameTableDefine.ChatEventManager
local ShopUI = GameTableDefine.ShopUI
local ValueManager = GameTableDefine.ValueManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ShopManager = GameTableDefine.ShopManager
local FactoryMode = GameTableDefine.FactoryMode
local PiggyBankUI = GameTableDefine.PiggyBankUI
local LimitPackUI = GameTableDefine.LimitPackUI
local LimitChooseUI = GameTableDefine.LimitChooseUI
local FragmentActivityUI = GameTableDefine.FragmentActivityUI
---@class MainUIView:UIBaseView
local MainUIView = Class("MainUIView", UIView)
local PetMode = GameTableDefine.PetMode
local TimerMgr = GameTimeManager
local DiamondFundUI = GameTableDefine.DiamondFundUI
local ActivityRankUI = GameTableDefine.ActivityRankUI
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local TalkUI = GameTableDefine.TalkUI
local ChooseUI = GameTableDefine.ChooseUI
local AccumulatedChargeACUI = GameTableDefine.AccumulatedChargeACUI
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local BoardUI = GameTableDefine.BoardUI
local FCStadiumUI = GameTableDefine.FCStadiumUI
local FootballClubController = GameTableDefine.FootballClubController
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local InstanceViewUI = GameTableDefine.InstanceViewUI
local StoryLineManager = GameTableDefine.StoryLineManager
local MonthCardUI = GameTableDefine.MonthCardUI
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI
local GameStateManager = GameStateManager
local SeasonPassManager = GameTableDefine.SeasonPassManager
local CEODataManager = GameTableDefine.CEODataManager

function MainUIView:ctor()
    self.super:ctor()
    -- self.roomBrokenData = {}
    self.m_isFloor = true
    self.m_limitChooseTimer = nil
end

function MainUIView:OnEnter()
    print("MainUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("return", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("ResourceBG/CurrStarFrame", "Button"), function()
        self:GetGo("HelpInfo_reputation"):SetActive(true)
        -- GameSDKs:TrackForeign("button_event", {reputation = 1})
    end)
    -- self:SetButtonClickHandler(self:GetComp("ResourceInterface/water/AddBtn", "Button"), function()
    --     CityMode:EnterDefaultBuiding()
    -- end)
    self:SetButtonClickHandler(self:GetComp("ResourceBG/ResourceInterface/AddBtn", "Button"), function()
        --GameUIManager:SetEnableTouch(false)
        MainUI:ShowEnergyRoom()
    end)

    self:SetButtonClickHandler(self:GetComp("ResourceBG/DiamondInterface/AddBtn", "Button"), function()
        --if GameConfig:IsIAP() then
        GameTableDefine.ShopUI:OpenAndTurnPage(1000)
        -- else
        --     DiamondShopUI:ShowShopPanel()
        -- end
    end)

    self:SetButtonClickHandler(self:GetComp("DiamondGiftBtn", "Button"), function()
        DiamondRewardUI:ShowRewardPanel()
    end)

    self:SetButtonClickHandler(self:GetComp("DetailPanel/SettingBtn", "Button"), function()
        GameTableDefine.SettingUI:GetView()
        --GameTableDefine.TutorialUI:GetView()
    end)

    self:SetButtonClickHandler(self:GetComp("DetailPanel/BoardBtn", "Button"),function()
        --TODO:这里需要检测是否有订单需要补，如果有订单要补的话，优先进行补单的提示操作
        local isHaveSupplementOrder = false
        local orderData = MainUI:GetInitSupplementOrder()
        if orderData and Tools:GetTableSize(orderData) > 0 then
            isHaveSupplementOrder = true
        end
        if isHaveSupplementOrder then
            GameTableDefine.SupplementOrderUI:GetView()
        else
            if (not BoardUI.isOverTime) and BoardUI.cacheData and( BoardUI.cacheData["unRead"] or BoardUI.thisTime )then
                BoardUI:ShowView()
            else
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_NOTIFY"))
            end
        end

    end)

    self:SetButtonClickHandler(self:GetComp("MoveBuding", "Button"), function()
        -- print("移动到活动场景")
        -- CityMode:GotoOtherCityBuilding(300)     
        WorldListUI:GetView()
    end)
    local wheelRoot = self:GetGo("RightPanel/WheelBtn")
    local wheelDisFlag = ConfigMgr.config_global.wheel_switch == 1 and StarMode:GetStar() >= ConfigMgr.config_global.wheel_condition and FloorMode:CheckWheelGo()
    wheelRoot:SetActive(wheelDisFlag)

    self:SetButtonClickHandler(self:GetComp("RightPanel/WheelBtn", "Button"), function()
        GameTableDefine.RouletteUI:GetView()
    end)

    self:SetButtonClickHandler(self:GetComp("BottomPanel/PhoneUI", "Button"), function()
        GameTableDefine.PhoneUI:Refresh()
    end)

    self:SetButtonClickHandler(self:GetComp("DetailPanel/CollectionBtn", "Button"), function()
        GameTableDefine.CollectionUI:Refresh()
    end)

    self:SetButtonClickHandler(self:GetComp("TaskBtn", "Button"), function()
        GameTableDefine.QuestUI:ShowQuestPanel()
    end)

    self:SetButtonClickHandler(self:GetComp("FloorPanel/UpstairBtn", "Button"), function()
        --(self.m_switchFloorMode or FloorMode):GoUpstairs()
        local mode = self.m_switchFloorMode or FloorMode
        mode:GoUpstairs()
    end)

    self:SetButtonClickHandler(self:GetComp("FloorPanel/DownstairBtn", "Button"), function()
        local mode = self.m_switchFloorMode or FloorMode
        mode:GoDownstairs()
    end)

    self:SetButtonClickHandler(self:GetComp("EventArea/OfflineReward", "Button"), function()
        OfflineRewardUI:GetView()
        --self:GetGo("EventArea/OfflineReward"):SetActive(false)
    end)
    --工厂订单可完成气泡
    self:SetButtonClickHandler(self:GetComp("OrderFinish", "Button"), function()
        OrderFinishUI:GetView()
    end)
    --工厂爆仓
    self:SetButtonClickHandler(self:GetComp("StockFull", "Button"), function()
        StockFullUI:GetView()
    end)
    --成长基金按钮
    self:SetButtonClickHandler(self:GetComp("RightPanel/BpBtn", "Button"), function()
        DiamondFundUI:GetView()
        -- GameSDKs:TrackForeign("button_event", {fund = 1})
    end)
    --工厂仓库
    self:SetButtonClickHandler(self:GetComp("BottomPanel/WarehousetBtn","Button"), function()
        --这里写死后面需要再改
        WorkShopInfoUI:WorkShopInfoInit(10005)
        FactoryMode:LookAtWorkShop(10005)
    end)

    -- local btn = self:GetComp("RightPanel/TapjoyBtn","Button")
    -- btn.gameObject:SetActive(false)
    -- if GameConfig:IsWarriorVersion() and GameDeviceManager:IsAndroidDevice() then
    --     btn.gameObject:SetActive(true)
    --     self:SetButtonClickHandler(btn, function()
    --         GameSDKs:ShowTapJoyOfferwall()
    --     end)
    -- end

    --工厂订单
    self:SetButtonClickHandler(self:GetComp("OrderBtn","Button"), function()
        OrderUI:GetView()
        FactoryMode:LookAtParkingLot()
    end)
    --主场景工厂引导Npc
    self:SetButtonClickHandler(self:GetComp("EventArea/FactoryGuide","Button"), function()
        local Root = GameObject.Find("Factory_Guide")
        FloorMode:GetScene():LocatePosition(self:GetGo(Root, "GuideNpc").transform.position, true)
        GuideManager.currStep = 500
        GuideManager:OpenGuideView()
    end)

    --主场景足球俱乐部引导Npc
    self:SetButtonClickHandler(self:GetComp("EventArea/FBClubGuide","Button"), function()
        local Root = GameObject.Find("FBClub_Guide")
        FloorMode:GetScene():LocatePosition(self:GetGo(Root, "GuideNpc").transform.position, true)
        GuideManager.currStep = 20001
        GuideManager:OpenGuideView()
    end)
    --存钱罐按钮
    self:SetButtonClickHandler(self:GetComp("RightPanel/piggyBank", "Button"),function()
        GameTableDefine.PiggyBankUI:OpenView()
        -- GameSDKs:TrackForeign("button_event", {piggybank = 1})
    end)
    --钻石月卡按钮
    local mcBtn = self:GetComp("RightPanel/McBtn", "Button")
    self:SetButtonClickHandler(mcBtn,function()
        GameTableDefine.MonthCardUI:OpenView()
        -- GameSDKs:TrackForeign("button_event", {monthcard = 1})
    end)
    mcBtn.gameObject:SetActive(true)
    --宠物养成按钮
    self.m_petBtn = self:GetComp("BottomPanel/PetBtn", "Button")
    self:SetButtonClickHandler(self.m_petBtn,function()
        GameTableDefine.PetListUI:GetView()
        GameTableDefine.PetListUI:RefreshEmployee()
    end)
    self.m_petBtnRedPoint = self:GetGo("BottomPanel/PetBtn/icon")
    --活跃度入口按钮
    self:SetButtonClickHandler(self:GetComp("BottomPanel/ActivityBtn", "Button"), function()
        GameTableDefine.ActivityUI:GetView()
    end)
    --俱乐部等级按钮
    self:SetButtonClickHandler(self:GetComp("ResourceBG/ClubLevelFrame/bg_up/bg", "Button"), function()
        GameTableDefine.FCLevelupUI:GetView()
    end)
    --俱乐部联赛按钮
    self:SetButtonClickHandler(self:GetComp("DetailPanel/LeagueFrame", "Button"), function()
        GameTableDefine.FCLeagueRankUI:ShowLeagueList()
    end)
    --俱乐部场馆按钮
    self:SetButtonClickHandler(self:GetComp("BottomPanel/StadiumBtn","Button"), function()
        FootballClubController:ClickStadium(FootballClubController.sceneGo["Stadium"].root,FootballClubModel.StadiumID)
    end)
    --俱乐部训练场按钮
    self:SetButtonClickHandler(self:GetComp("BottomPanel/TranningBtn","Button"), function()
        FootballClubController:ClickTrainingGround(FootballClubController.sceneGo["TrainingGround"].root,FootballClubModel.TrainingGroundID)
    end)
    --俱乐部球馆Banner
    self:SetButtonClickHandler(self:GetComp("EventArea/MatchReady","Button"),function()
        CountryMode:SetCurrCountry(2)
        FloorMode:GotoSpecialBuilding(50001)
    end)

    --主线故事按钮
    local mainLineBtn = self:GetComp("MainLinePanel/btn","Button")
    if mainLineBtn then
        self:SetButtonClickHandler(mainLineBtn,function()
            GameTableDefine.StoryLineUI:ShowStoryLineUI()
        end)
    end

    -- 排行榜判断进入游戏后能否直接领奖的功能
    ActivityRankDataManager:GetActivityRankReward()
    self:DisplayActivityRankBtn()
    --活动排行入口按钮
    self:SetButtonClickHandler(self:GetComp("PackPanel/rank", "Button"), function()
        print("Button click to Open the ActivityRankUI")
        GameTableDefine.ActivityRankUI:GetView()
        if ActivityRankDataManager:GetActivityIsOverTimer() then
            GameTableDefine.ActivityRankUI:LastActivityShow()
        else
            GameTableDefine.ActivityRankUI:NewActivityShow()
        end

    end)

    --限时礼包入口按钮
    self:SetButtonClickHandler(self:GetComp("PackPanel/LimitPack", "Button"), function()
        GameTableDefine.LimitPackUI:OpenView()
    end)

    --限时多选一礼包入口按钮
    self:SetButtonClickHandler(self:GetComp("PackPanel/LimitChoose", "Button"), function()
        GameTableDefine.LimitChooseUI:OpenView()
    end)

    self:RefreshAccumulatedChargeActivity()
    --累积充值活动按钮设置2022-12-26 fengyu
    self:SetButtonClickHandler(self:GetComp("PackPanel/Payment", "Button"), function()
        AccumulatedChargeACUI:OpenView()
    end)

    --首充重置入口按钮
    self:SetButtonClickHandler(self:GetComp("PackPanel/FirstPurchaseBtn", "Button"), function()
        GameTableDefine.FirstPurchaseUI:OpenView()
    end)

    --赛季通行证入口按钮
    self:SetButtonClickHandler(self:GetComp("PackPanel/SeasonPass", "Button"), function()
        GameTableDefine.SeasonPassUI:OpenView()
    end)

    --添加判断显示资产(宠物，经理等相关)转移按钮的逻辑
    self:CheckTransformAsset()
    self.m_leaveBtn = self:GetComp("BottomPanel/LeaveBtn", "Button")
    self:SetButtonClickHandler(self.m_leaveBtn, function()
        if not GameUIManager:CleanUI() then--有其他界面就不能离开
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_CLOSE_UI"))
            return
        end
        if FloorMode:IsInFactory() then
            FloorMode:ExitSpecialBuilding()
            return
        end
        if FloorMode:IsInFootballClub()  then
            FloorMode:ExitSpecialBuilding()
            FootballClubModel:OnExit()
        end
        self:BackToCity()
    end)


    local shopBtn = self:GetComp("BottomPanel/ShopBtn", "Button")
    shopBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(shopBtn, function()
        GameTableDefine.ShopUI:EnterShop()
    end)

    local noAdBtn = self:GetComp("NoAdBtn", "Button")
    local show = GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD() or false
    noAdBtn.gameObject:SetActive(show)
    self:SetButtonClickHandler(noAdBtn, function()
        --GameTableDefine.ShopUI:TurnTo(1009)
        GameTableDefine.IntroduceUI:Open(1068, nil, 4)
    end)


    self.m_backBtn = self:GetComp("BottomPanel/ReturnBtn", "Button")
    self:SetButtonClickHandler(self.m_backBtn, function()
        EventManager:DispatchEvent("BACK_TO_SCENE")
        if FloorMode:IsInHouse() or FloorMode:IsInCarShop() then
            FloorMode:ExitSpecialBuilding()
        else
            CityMode:EnterDefaultBuiding()
        end
    end)

    --2025-3-28fy 下班打开活动相关内容
    self:RefreshClockOutActivity()
    self:SetButtonClickHandler(self:GetComp("PackPanel/ClockOutBtn", "Button"), function()
        if GameTableDefine.ClockOutDataManager:GetActivityIsOpen() then
            GameTableDefine.ClockOutUI:OpenView()
        end
    end)
    --检测问卷调查是否初始化，然后进行问卷调查初始化控件初始化设置
    self:InitSurvey()
    --if not GameTableDefine.QuestionSurveyDataManager:GetIsInit() then
    --    GameTableDefine.QuestionSurveyDataManager:Init(true)
    --end
    --self:RefreshQuestionSurvey()
    --self.m_surveyBtn = self:GetComp("PackPanel/SurveyBtn", "Button")
    --self:SetButtonClickHandler(self.m_surveyBtn, function()
    --    if GameTableDefine.QuestionSurveyDataManager:GetQuestionIsOpen() then
    --        GameTableDefine.QuestionSurveyUI:GetView()
    --    end
    --end)

    self:InitCheat()

    self.m_roomBrokenDemo = {}
    self.m_roomBrokenDemo["root"] = self:GetGo("EventArea")
    -- self.m_roomBrokenDemo["PowerOff"] = self:GetGo("PowerOff")
    -- self.m_roomBrokenDemo["WaterLeakage"] = self:GetGo("WaterLeakage")
    -- self.m_roomBrokenDemo["OverHeat"] = self:GetGo("OverHeat")
    -- self.m_roomBrokenDemo["FacilityDamage"] = self:GetGo("FacilityDamage")
    -- self.m_roomBrokenDemo["NetOff"] = self:GetGo("NetOff")

    GuideManager:ConditionToStart()--???这里为什么要加

    local dayIcon = self:GetGo("DetailPanel/CurrTimeFrame/icon_day")
    local nightIcon = self:GetGo("DetailPanel/CurrTimeFrame/icon_night")

    local refreshCash = function()
        local num = FloorMode:GetTotalRent()
        local pay = FloorMode:GetEmployeePay()
        local currCash = ResourceManger:GetCash()
    end

    EventManager:RegEvent("CASH_MAX", function()
        self:RefreshCashEarn(true)
    end);

    EventManager:RegEvent("CASH_SPEND", function()
        self:RefreshCashEarn()
    end);
    self.m_changeCEOActorHandler = handler(self,self.OnCEOActorChanged)
    self.m_updateCEOBoxTipsHandler = handler(self, self.RefreshCEOBoxTipsDisp)
    EventDispatcher:RegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
    EventDispatcher:RegEvent(GameEventDefine.UpgradeCEODesk,self.m_changeCEOActorHandler)
    EventDispatcher:RegEvent(GameEventDefine.RoomCEOUpgrade,self.m_changeCEOActorHandler)
    EventDispatcher:RegEvent(GameEventDefine.UpdateCEOBoxTips,self.m_updateCEOBoxTipsHandler)
    -- EventManager:RegEvent("EVENT_EDIT_LANGUAGE", function()
    --     local currLanguage = ConfigMgr.config_global.game_language or "cn"
    --     GameLanguage:SetCurrentLanguageID(currLanguage)
    --     GameTextLoader:LoadTextofLanguage(currLanguage,function()
    --         print("Switch LoadTextofLanguage ", currLanguage)
    --     end) 
    -- end);

    -- if UnityHelper.OnlyEventOnEdit ~= nil then
    --     UnityHelper.OnlyEventOnEdit("EVENT_EDIT_LANGUAGE")
    -- end

    self:CreateTimer(100, function()
        if GameStateManager:IsCycleInstanceState() then
            return
        end
        local h,m = GameClockManager:GetCurrGameTime()
        if h then
            if m < 10 then
                m = "0"..m
            end
            self:SetText("DetailPanel/CurrTimeFrame/CurrTime", h..":"..m)
        end

        local isDeepNight = GameClockManager:IsDeepNight()
        if not dayIcon.activeSelf and not isDeepNight then
            dayIcon:SetActive(true)
            nightIcon:SetActive(false)
        end
        if not nightIcon.activeSelf and isDeepNight then
            nightIcon:SetActive(true)
            dayIcon:SetActive(false)
        end

        if FloorMode:IsInFootballClub() then
            self:RefreshFCStrength()

        end

        if FootballClubModel:IsInitialized() then
            local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
            if FCData and FCData.league then
                self:RefreshStadiumBanner()
            end

            self:RefreshFCStadiumRedPoint()
            self:RefreshFCTrainingGroundRedPoint()
        end
        self:RefreshCEOBoxTipsDisp()
        self:RefreshPetHint()

    end, true, true)


    --一系列初始化相关的方法
    -- GameSDKs:TrackForeign("init_info", {cash = ResourceManger:GetCash(), diamond = ResourceManger:GetDiamond()})
    GameTableDefine.ValueManager:GetValue(true)
    ResourceManger:SetCashMax(ValueManager:CurrCashLimit())

    EventManager:RegEvent(GameEventDefine.OnRoomBuildingViewOpen,handler(self,self.OnRoomBuildingViewOpen))
    EventManager:RegEvent(GameEventDefine.OnRoomBuildingViewClose,handler(self,self.OnRoomBuildingViewClose))

    EventManager:RegEvent(GameEventDefine.OnBuyBuilding,handler(self,self.RefreshQuestionSurvey)) -- 问卷按钮开关

    self.m_refreshSeasonPassBtnHandler = handler(self,self.RefreshSeasonPassBtn)
    EventDispatcher:RegEvent(GameEventDefine.SeasonPassStateChange,self.m_refreshSeasonPassBtnHandler) -- 更新赛季通行证按钮
end

function MainUIView:InitSurvey()
    if not GameTableDefine.QuestionSurveyDataManager:GetIsInit() then
        GameTableDefine.QuestionSurveyDataManager:Init()
    end
    self:RefreshQuestionSurvey()

    self.m_surveyBtnV2 = self:GetComp("PackPanel/SurveyBtn", "Button")
    self:SetButtonClickHandler(self.m_surveyBtnV2, function()
        if GameTableDefine.QuestionSurveyDataManager:GetQuestionIsOpen() then
            GameTableDefine.QuestionSurveyNewUI:GetView()
        end
    end)
end

function MainUIView:OnRoomBuildingViewOpen()
    if self.m_isFloor then
        local packPanel = self:GetGo("PackPanel")
        local rightPanel = self:GetGo("RightPanel")
        local eventArea = self:GetGo("EventArea")
        local bottomPanel = self:GetGo("BottomPanel")
        packPanel:SetActive(false)
        rightPanel:SetActive(false)
        eventArea:SetActive(false)
        bottomPanel:SetActive(false)
        self:RefreshMainLinePanel(false)
    end
end

function MainUIView:OnRoomBuildingViewClose()
    if self.m_isFloor then
        local packPanel = self:GetGo("PackPanel")
        local rightPanel = self:GetGo("RightPanel")
        local eventArea = self:GetGo("EventArea")
        local bottomPanel = self:GetGo("BottomPanel")
        packPanel:SetActive(true)
        rightPanel:SetActive(true)
        eventArea:SetActive(true)
        bottomPanel:SetActive(true)
        self:RefreshMainLinePanel(GameStateManager:IsInFloor())
    end
end

function MainUIView:BackToCity(cb)
    self:InitCameraScale("IndoorScale", function()
        GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(1, function()
            GameStateManager:EnterCity(cb)
        end)
    end, true)

    -- GameTableDefine.GameStateCity:PreLoadScene()
    self:PlayUIAnimation(false)
end
--从工厂回到大地图
function MainUIView:FactoryBackToCity()
    GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(1, function()
        EventManager:DispatchEvent("BACK_TO_SCENE")
        FloorMode:ExitSpecialBuilding(true)
        FactoryMode:OnExit()
        GameStateManager:EnterCity()
    end)
end
--隐藏 MainUI,reverse 反转效果
function MainUIView:Hideing(reverse)
    local CanasGroup = self:GetComp("","CanvasGroup")
    if not reverse then
        CanasGroup.alpha = 0
        CanasGroup.interactable = false
        CanasGroup.blocksRaycasts = false
    else
        CanasGroup.alpha = 1
        CanasGroup.interactable = true
        CanasGroup.blocksRaycasts = true
    end
end

function MainUIView:InitCheat()
    --local CheatButton  = self:GetGo("Cheat/CheatButton")
    -- CheatButton:SetActive(false)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ResetGame", "Button"), function()
    --     LocalDataManager:ClearUserSave()
    --     GameStateManager:RestartGame()
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ReadData/Btn", "Button"), function()

    --     local str = "http://192.168.110.249:8000/share/wuyeSave/PlayerSaves.txt"
    --     local ipStr = self:GetComp("Cheat/CheatButton/ReadData/input", "TMP_InputField").text
    --     local clipStatus1 = self:GetComp("Cheat/CheatButton/ReadData/Image/Status1", "Text")
    --     local clipStatus2 = self:GetComp("Cheat/CheatButton/ReadData/Image/Status2", "Text")
    --     if not ipStr or string.len(ipStr) ~= 0 then
    --         str = "http://"..ipStr.."/share/wuyeSave/PlayerSaves.txt"
    --     end
    --     local clipBoardStr1 = "请求地址为:"..str
    --     local clipBoardStr2 = "开始请求存档"
    --     clipStatus1.text = clipBoardStr1
    --     clipStatus2.text = clipBoardStr2
    --     -- 存档请求
    --     local requestTable = {
    --     callback = function(response)
    --         print(response)
    --         if response ~= nil and string.len(response) > 0 then
    --             local dataStr = response
    --             local data = nil
    --             xpcall(function()
    --                 local rapidjson = require("rapidjson")
    --                 dataStr = CS.Common.Utils.AES.Decrypt(dataStr)
    --                 data = {record = rapidjson.decode(dataStr)}
    --             end,function(error)
    --                 local rapidjson = require("rapidjson")
    --                 data = rapidjson.decode(dataStr)
    --             end)
    --             if data then
    --                 local key,value = next(data.record)
    --                 local userData = LocalDataManager:GetDataByKey("user_data")
    --                 value.user_data = Tools:CopyTable(userData)
    --                 LocalDataManager:ReplaceRecordData(data)
    --                 CS.UnityEngine.Application.Quit()
    --                 clipBoardStr1 = "替换存档成功，重新启动客户端生效"
    --             else
    --                 clipBoardStr1 = "获取的存档为空或者异常"
    --             end
    --             clipStatus1.text = clipBoardStr1
    --             clipStatus2.text = clipBoardStr2
    --         else

    --         end

    --     end
    --     }
    --     GameNetwork:HTTP_PublicSendRequest(str, requestTable, nil, "GET")
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/CopyExcption", "Button"), function()
    --     local excp = ExceptionHandler:GetException()
    --     local rapidjson = require("rapidjson")
    --     local strExcp = rapidjson.encode(excp, {pretty = true, sort_keys = true})
    --     GameDeviceManager:CopyToClipboard(strExcp)
    --     EventManager:DispatchEvent("UI_NOTE", "程序异常已经拷贝到本设备剪贴板中。")
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/CheatTime", "Button"), function()
    --     self:SetText("Cheat/CheatButton/CheatTime/Count", Tools:SwitchCheatMode() and "开" or "关")
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/CheatTime", "Button"), function()
    --     self:SetText("Cheat/CheatButton/CheatTime/Count", Tools:SwitchCheatMode() and "开" or "关")
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/companyLv", "Button"), function()
    --     local data = CompanyMode:GetData()
    --     local companyConfig = ConfigMgr.config_company
    --     local needSave = false

    --     for k,v in pairs(data or {}) do
    --         local currConfig = companyConfig[v.company_id]
    --         if not v.currExp then 
    --             v.currExp = 0 
    --         end
    --         if not v.level then 
    --             v.level = ConfigMgr.config_company[v.company_id].levelBegin

    --         end

    --         local expAdd = 1000000000
    --         v.currExp = math.floor(v.currExp + expAdd)
    --     end
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddCash", "Button"), function()
    --     local pos = self:GetTrans("Cheat/CheatButton/AddCash").position
    --     EventManager:DispatchEvent("FLY_ICON", pos, 2, 10)

    --     local resourMana = GameTableDefine.ResourceManger
    --     if resourMana:CashMax(1) then
    --         resourMana:AddCash(100000000, nil, nil, true, true)
    --     else
    --         GameTableDefine.ResourceManger:AddCash(100000000)
    --     end
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddDiamond", "Button"), function()
    --     local pos = self:GetTrans("Cheat/CheatButton/AddDiamond").position
    --     EventManager:DispatchEvent("FLY_ICON", pos, 3, 10)
    --     GameTableDefine.ResourceManger:AddDiamond(100000, nil, nil, true)
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddStart", "Button"), function()
    --     GameTableDefine.StarMode:StarRaise(1)
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddResouce/Btn", "Button"), function()
    --     local inputNum = self:GetComp("Cheat/CheatButton/AddResouce/input", "TMP_InputField")
    --     local numInfo = Tools:SplitString(inputNum.text, ",")
    --     if numInfo[1] and numInfo[2] and tonumber(numInfo[2]) then
    --         if numInfo[1] == "gem" then
    --             EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
    --             GameTableDefine.ResourceManger:AddDiamond(tonumber(numInfo[2]), nil, nil, true)
    --         elseif numInfo[1] == "cash" then
    --             EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
    --             -- if GameTableDefine.ResourceManger:CashMax(1) then
    --             -- else
    --             --     GameTableDefine.ResourceManger:AddCash(tonumber(numInfo[2]))
    --             -- end
    --             GameTableDefine.ResourceManger:AddCash(tonumber(numInfo[2]), nil, nil, true, true)
    --         elseif numInfo[1] == "euro" then
    --             EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
    --             GameTableDefine.ResourceManger:AddEUR(tonumber(numInfo[2]), nil, nil, true, true)
    --         elseif numInfo[1] == "star" then
    --             GameTableDefine.StarMode:StarRaise(tonumber(numInfo[2]))
    --         elseif  numInfo[1] == "coexp" then
    --             local data = CompanyMode:GetData()
    --             local companyConfig = ConfigMgr.config_company
    --             local needSave = false
    --             for k,v in pairs(data or {}) do
    --                 local currConfig = companyConfig[v.company_id]
    --                 if not v.currExp then 
    --                     v.currExp = 0 
    --                 end
    --                 if not v.level then 
    --                     v.level = ConfigMgr.config_company[v.company_id].levelBegin
    --                 end
    --                 local expAdd = tonumber(numInfo[2])
    --                 v.currExp = math.floor(v.currExp + expAdd)
    --             end
    --         end
    --     end
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/TimeBack", "Button"), function()
    --     --时间后退1小时
    --     GameTableDefine.GameClockManager.offsetTime = GameTableDefine.GameClockManager.offsetTime - 60
    -- end)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/TimeForward", "Button"), function()
    --     --时间前进1小时
    --     GameTableDefine.GameClockManager.offsetTime = GameTableDefine.GameClockManager.offsetTime + 60
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ActiveEvent/Btn", "Button"), function()
    --     local inputNum = self:GetComp("Cheat/CheatButton/ActiveEvent/input", "TMP_InputField")
    --     local num = tonumber(inputNum.text) or 0
    --     local idFrom = 1
    --     local idTo = #ConfigMgr.config_chat_condition
    --     if num >= idFrom and num <= idTo then
    --         ChatEventManager:ActiveChatEvent(num, true, true)
    --         return
    --     end
    --     for k = idFrom, idTo do
    --         ChatEventManager:ActiveChatEvent(k, true, true)
    --     end        
    -- end)

    --员工事件
    -- local Actor = require "GamePlay.Floors.Actors.Actor"
    -- local tab = {
    --     {"厕", Actor.FLAG_EMPLOYEE_ON_TOILET},
    --     {"休", Actor.FLAG_EMPLOYEE_ON_REST},
    --     {"会", Actor.FLAG_EMPLOYEE_ON_MEETING},
    --     {"娱", Actor.FLAG_EMPLOYEE_ON_ENTERTAINMENT},
    --     {"健", Actor.FLAG_EMPLOYEE_ON_GYM},
    -- }
    -- local cur = 1
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ActivePersionEvent/AddBtn", "Button"), function()
    --     local text = self:GetComp("Cheat/CheatButton/ActivePersionEvent/Event", "TextMeshProUGUI")
    --     cur = math.min(cur + 1, #tab)
    --     text.text = tab[cur][1]
    -- end)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ActivePersionEvent/DelBtn", "Button"), function()
    --     local text = self:GetComp("Cheat/CheatButton/ActivePersionEvent/Event", "TextMeshProUGUI")
    --     cur = math.max(cur - 1, 1)
    --     text.text = tab[cur][1]
    -- end)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ActivePersionEvent/ConfBtn", "Button"), function()
    --     Actor:DebugAddFlag(tab[cur][2])
    -- end)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/CleanShop", "Button"), function()
    --     ShopManager:CleanShopData()
    --     PetMode:CleanEntiey()
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AllUnlock", "Button"), function()
    --     FloorMode:BeNB()
    --     EventManager:DispatchEvent("UI_NOTE", "退出游戏后生效")
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/CrashlyticsTester", "Button"), function()
    --     CS.Game.SDK.SDKManager.Instance:CrashlyticsTester()
    -- end)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/ActivityBtn", "Button"),function()
    --     ActivityRankDataManager:GMAddPlayerRankScore()
    -- end)


    -- local list = GameLanguage:GetSupportedLanguageList()
    -- local cur = GameLanguage:GetCurrentLanguageID()
    -- local curIndex = 1
    -- local langTxt = self:SetText("Cheat/CheatButton/Langue/TXT", cur)

    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/Langue/Btn", "Button"), function()
    --     for i,v in ipairs(list) do
    --         if v == cur then
    --             curIndex = i
    --             break
    --         end
    --     end
    --     curIndex = curIndex + 1
    --     if curIndex > #list then
    --         curIndex = curIndex - #list
    --     end
    --     GameLanguage:SetCurrentLanguageID(list[curIndex])

    --     cur = GameLanguage:GetCurrentLanguageID()
    --     GameTextLoader:LoadTextofLanguage(cur,function()
    --         print("Switch LoadTextofLanguage ", cur)
    --     end) 
    --     langTxt.text = cur
    -- end)

    if GameConfig:IsDebugMode() then
        self:GetGo("Cheat"):SetActive(true)
        local password = ""
        local CheckPsd = function()
            print(password, "1111111111")
            if password == "1111111111" then
                --CheatButton:SetActive(not CheatButton.activeSelf)
                GameTableDefine.CheatUI:GetView()
                password = ""
                -- GameConfig.showfps = CheatButton.activeSelf
                -- UnityHelper.ShowFps(GameUIManager.canvasObj)                
                -- if CheatButton.activeSelf and GameDeviceManager:IsiOSDevice() then
                --     GameSDKs:Track("debug_info")
                -- end
            elseif #password >= 10 then
                password = ""
            end
        end
        self:SetClickHandler(self:GetComp("Cheat", "Button"), function()
            password = password .. "1"
            CheckPsd()
        end)
    else
        -- self:GetGo("Cheat"):SetActive(false)
    end
    -- --加许可证
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddLimit", "Button"), function()
    --     ResourceManger:AddLicense(10,nil,function()            
    --         MainUI:RefreshLicenseState()
    --     end, true)
    -- end)
    -- --开启碎片活动
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/FragmentBtn", "Button"), function()
    --     --self:GetGo("PackPanel/FestivalActivityBtn"):SetActive(true)
    --     GameTableDefine.TimeLimitedActivitiesManager:EnableFragmentActivity()
    -- end)
    -- self:SetButtonClickHandler(self:GetComp("Cheat/CheatButton/AddFragment", "Button"), function()
    --     FragmentActivityUI:AddFragment(nil, 10)
    -- end)
end

function MainUIView:OnPause()
    print("MainUIView:OnPause")
end

function MainUIView:OnResume()
    print("MainUIView:OnResume")
end

function MainUIView:HideButton(buttonName, open)--当前修改:LeaveBtn
    local button = self:GetGo(buttonName)
    if button then
        button:SetActive(false or open)
    end
end

function MainUIView:OnExit()

    EventManager:UnregEvent(GameEventDefine.OnRoomBuildingViewOpen)
    EventManager:UnregEvent(GameEventDefine.OnRoomBuildingViewClose)

    EventManager:UnregEvent(GameEventDefine.OnBuyBuilding) -- 问卷按钮开关

    EventDispatcher:UnRegEvent(GameEventDefine.SeasonPassStateChange,self.m_refreshSeasonPassBtnHandler) -- 更新赛季通行证按钮
    EventDispatcher:UnRegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
    EventDispatcher:UnRegEvent(GameEventDefine.UpgradeCEODesk,self.m_changeCEOActorHandler)
    EventDispatcher:UnRegEvent(GameEventDefine.RoomCEOUpgrade,self.m_changeCEOActorHandler)
    self.m_changeCEOActorHandler = nil
    EventDispatcher:UnRegEvent(GameEventDefine.UpdateCEOBoxTips,self.m_updateCEOBoxTipsHandler)
    self.m_updateCEOBoxTipsHandler = nil
    if self.instanceTimer then
        GameTimer:_RemoveTimer(self.instanceTimer)
    end

    if self.starVfxTimer then
        GameTimer:StopTimer(self.starVfxTimer)
        self.starVfxTimer = nil
    end

    if self.piggyBankVfxTimer then
        GameTimer:StopTimer(self.piggyBankVfxTimer)
        self.piggyBankVfxTimer = nil
    end

    if self.CheckInstanceDisplayTimer then
        GameTimer:_RemoveTimer(self.CheckInstanceDisplayTimer)
    end

    if self.m_officeTipTimer then
        GameTimer:_RemoveTimer(self.m_officeTipTimer)
        self.m_officeTipTimer = nil
    end

    if self.m_limitChooseTimer then
        GameTimer:StopTimer(self.m_limitChooseTimer)
        self.m_limitChooseTimer = nil
    end

    if self.m_firstPurchaseTimer then
        GameTimer:StopTimer(self.m_firstPurchaseTimer)
        self.m_firstPurchaseTimer = nil
    end

    if self.m_seasonPassTimer then
        GameTimer:StopTimer(self.m_seasonPassTimer)
        self.m_seasonPassTimer = nil
    end

    if self.clockOutTimer then
        GameTimer:StopTimer(self.clockOutTimer)
        self.clockOutTimer = nil
    end

    for k, v in pairs(self.__timers) do
        if v then
            GameTimer:_RemoveTimer(v)
        end
    end
    self.__timers = {}

    self.super:OnExit(self)
    print("MainUIView:OnExit")
end


function MainUIView:SetUIStatus(isFloor)
    self.m_isFloor = isFloor
    self:GetGo("EventArea"):SetActive(isFloor)
    self:GetGo("ResourceBG/CurrStarFrame"):SetActive(true)
    self:GetGo("ResourceBG/ResourceInterface"):SetActive(true)
    local needLeaveBtn = GuideManager:isShowLeaveBtn()
    self.m_leaveBtn.gameObject:SetActive(isFloor and needLeaveBtn)
    self:RefreshOfficeTip(isFloor)
    --self.m_leaveBtn.gameObject:SetActive(isFloor)

    local haveLastFloor = (not isFloor) and CityMode:GetCurrentBuilding() ~= nil
    self.m_backBtn.gameObject:SetActive(haveLastFloor)
    -- self:SetEventSponsorHint(false,1)
    -- self:SetEventSponsorHint(false,2)
    -- self:SetEventBatmanHint(false)
    --self:PlayUIAnimation(true)
    self:GetGo("BottomPanel/PhoneUI"):SetActive(isFloor)
    self:GetGo("DetailPanel/CollectionBtn"):SetActive(isFloor)
    self:GetGo("MoveBuding"):SetActive(not isFloor and CityMapUI:isInCity())
    self:GetGo("MoveBuding/icon"):SetActive(WorldListUI:MovingBtnHint())
    self.m_petBtn.gameObject:SetActive(isFloor)
    self:GetGo("BottomPanel/ActivityBtn"):SetActive(isFloor)

    local iap = GameConfig:IsIAP()

    self:GetGo("BottomPanel/ShopBtn"):SetActive(isFloor)

    self:GetGo("DetailPanel/LicenseInterface"):SetActive(FloorMode:IsInFactory())
    self:GetGo("BottomPanel/WarehousetBtn"):SetActive(FloorMode:IsInFactory())
    self:GetGo("OrderBtn"):SetActive(FloorMode:IsInFactory())

    self:GetGo("ResourceBG/ClubLevelFrame"):SetActive(FloorMode:IsInFootballClub())
    self:GetGo("DetailPanel/LeagueFrame"):SetActive(FloorMode:IsInFootballClub())
    self:GetGo("ResourceBG/StrengthInterface"):SetActive(FloorMode:IsInFootballClub())


    local noAd = not GameTableDefine.ShopManager:IsNoAD()
    local showBtn = noAd and iap
    local result = isFloor and showBtn
    self:GetGo("NoAdBtn"):SetActive(isFloor and showBtn)

    --if iap then
    self.firstTime = self.firstTime == nil and true or false
    self:RefreshNewPlayerPackage(self.firstTime)
    self.firstTime = false

    self:RefreshGrowPackageBtn()
    self:RefreshPiggyBankBtn()
    self:RefreshFirstPurchaseBtn()
    self:RefreshSeasonPassBtn()
    --end
    -- local buyNew = not ShopManager:IsBuyNewGift()
    -- showBtn = buyNew and iap
    -- result = isFloor and showBtn
    -- self:GetGo("PackBtn"):SetActive(result)

    -- local newPackage = self:GetGo("PackBtn")
    -- local show = iap and not ShopManager:IsBuyNewGift() or false
    -- result = isFloor and show
    -- newPackage:SetActive(result)

    --self:GetGo("DiamondGiftBtn"):SetActive(isFloor and not iap)

    self:GetGo("PackPanel"):SetActive(isFloor and iap)
    self:RefreshQuestionSurvey()

    self:GetGo("RightPanel/BpBtn"):SetActive(isFloor and iap and DiamondFundUI:IsUnlocked())

    self:GetGo("TaskBtn"):SetActive(isFloor)

    local wheelDisFlag = isFloor and ConfigMgr.config_global.wheel_switch == 1 and StarMode:GetStar() >= ConfigMgr.config_global.wheel_condition and FloorMode:CheckWheelGo()
    self:GetGo("RightPanel/WheelBtn"):SetActive(wheelDisFlag)

    self:GetGo("RightPanel"):SetActive(isFloor)

    if not isFloor then
        self:GetGo("FloorPanel"):SetActive(false)
    end
    local image = self:GetComp("ResourceBG/MoneyInterface/icon", "Image")
    self:SetSprite(image, "UI_Main", CountryMode.cash_icon, nil, true)
    self:CheckTransformAsset()
    --工厂的事件UI
    self:RefreshFactorytips()
    --碎片活动按钮
    self:FragmentActivity(isFloor)
    --限时礼包按钮
    self:LimitPackActivity(isFloor)
    --限时多选一礼包按钮
    self:LimitChooseActivity(isFloor)
    --主线故事UI
    self:RefreshMainLinePanel(isFloor)
    self:RefreshMonthCardHint()

    self:GetGo("BottomPanel/StadiumBtn"):SetActive(false)
    self:GetGo("BottomPanel/TranningBtn"):SetActive(false)
    self:GetGo("Cheat"):SetActive(isFloor and not FloorMode:IsInFootballClub())
end

function MainUIView:SetResourceInfo(cash, diamond, water, power, totalPower)
    local warmPower = FloorMode:isWarmPower(power, totalPower)

    self:SetText("ResourceBG/MoneyInterface/num", Tools:SeparateNumberWithComma(cash))
    self:SetText("ResourceBG/DiamondInterface/num", Tools:SeparateNumberWithComma(diamond))
    self:SetText("ResourceBG/ResourceInterface/num", power, warmPower and "FF3100" or "FFFFFF")

end

function MainUIView:RefreshCashEarn(isMax)
    self:GetGo("DetailPanel/Efficiency/max"):SetActive(isMax)
    self:GetGo("DetailPanel/Efficiency/num"):SetActive(isMax == nil or isMax == false)
    self:GetGo("ResourceBG/IncomeTips"):SetActive(isMax == nil or isMax == false)
    if isMax and CountryMode:GetCurrCountry() == 1 then
        return
    else
        local text = GameTextLoader:ReadText("TXT_MISC_INCOME_RATE")
        text = string.format(text, FloorMode:GetTotalRent())
        self:SetText("DetailPanel/Efficiency/num", text)--XU_TODO:文本配置,MISC_COMPANY_EXP有
    end
end

function MainUIView:PlaySkipNight()
    local node = self:GetGo("SkipNightAnim")
    local ani = self:GetComp("SkipNightAnim", "Animation")
    node:SetActive(true)
    AnimationUtil.Play(ani, "NightSkip_Anim", function()
        node:SetActive(false)
    end)
end

function MainUIView:RefreshNewPlayerPackage(refresh)
    local root = self:GetGo("PackPanel")
    local allNewPackage = {1037}

    local closeAll = function()
        for k,v in pairs(allNewPackage) do
            self:GetGo(root, k .. ""):SetActive(false)
        end
    end

    if not refresh then
        return
    end

    -- if not GameConfig:IsIAP() then
    --     closeAll()
    --     return
    -- end

    local canBuyPackage = {}
    local havePackage = false
    local needGuide = false

    local isTimeGift = false
    local leftTime = 0
    local timeNodeGo = nil
    local shopId = nil
    local currGo = nil
    for k,v in pairs(allNewPackage) do
        needGuide = ShopManager:canBuyNewGift(v)

        if needGuide then
            self:SetButtonClickHandler(self:GetComp(root, k.."", "Button"), function()
                -- ShopUI:TurnTo(v)
                GameTableDefine.IntroduceUI:OpenNewPlayerPackage()
                if k == 1 then
                    -- GameSDKs:TrackForeign("button_event", {starterpack = 1})
                end
            end)
            canBuyPackage[k] = v
            havePackage = true
            shopId = v
            if not isTimeGift then
                isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(v)
            end
        end
        currGo = self:GetGoOrNil(root, k.."")
        if currGo then
            timeNodeGo = self:GetGoOrNil(currGo, "time")
            currGo:SetActive(GameTableDefine.IntroduceUI:CanOpenNewPlayerPackage())--改开的都开了,改关的都关了,之后场景切换的开关,就有计时器里自己判断了 
        end
    end
    if havePackage then
        self.__timers = self.__timers or {}
        if self.__timers["newPack"] then
            GameTimer:StopTimer(self.__timers["newPack"])
            self.__timers["newPack"] = nil
        end

        if isTimeGift and leftTime > 0 and timeNodeGo and shopId then
            self.__timers["newPack"] = GameTimer:CreateNewTimer(1, function()
                if leftTime > 0 then
                    isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(shopId)
                    local timeStr = GameTimeManager:FormatTimeLength(leftTime)

                    self:SetText(timeNodeGo, "num", timeStr)
                else
                    if self.__timers["newPack"] then
                        GameTimer:StopTimer(self.__timers["newPack"])
                        self.__timers["newPack"] = nil
                    end
                    if currGo then
                        currGo:SetActive(false)
                    end
                end
            end, true, true)
        end
    end
    -- if havePackage then
    --     self.__timers = self.__timers or {}
    --     if self.__timers["newPack"] then
    --         GameTimer:StopTimer(self.__timers["newPack"])
    --     end

    --     local canBuy,timeStay,show
    --     local textRoot
    --     local nowTime,inOffice
    --     self.__timers["newPack"] = GameTimer:CreateNewTimer(1, function()
    --         nowTime = TimerMgr:GetCurrentServerTime()
    --         inOffice = FloorMode:IsInOffice()
    --         for k,v in pairs(canBuyPackage) do
    --             self:GetGo(root, k..""):SetActive(inOffice)
    --         end
    --         if not inOffice then
    --             return
    --         end
    --         for k,v in pairs(canBuyPackage) do
    --             canBuy,timeStay = ShopManager:canBuyNewGift(v, nowTime)
    --             self:GetGo(root, k .. ""):SetActive(timeStay > 0)
    --             if timeStay > 0 then
    --                 show = TimerMgr:FormatTimeLength(timeStay)
    --                 self:SetText(root, k.."/time", show)
    --             end
    --             if canBuy == false then
    --                 GameTimer:StopTimer(self.__timers["newPack"])
    --                 self:RefreshNewPlayerPackage(true)
    --             end
    --         end
    --     end, true)
    -- end


end
-- 主界面成长礼包按钮刷新
function MainUIView:RefreshGrowPackageBtn()
    local root = self:GetGo("PackPanel")
    local allGrowPackage = {1038,1039,1040,1041,1042,1043,1044,1045,1046,1094,1190,1191,1192,1193,1194}
    local GrowUpGo = self:GetGo(root, "2")
    --当前需要显示的包
    local nowGrowPk = nil
    local nowGrowPkNum = nil
    for k,v in pairs(allGrowPackage) do
        local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(v)
        local timeCheckOK = true
        if isTimeGift and leftTime == 0 then
            timeCheckOK = false
        end
        if ShopManager:EnableBuy(v) and timeCheckOK then
            nowGrowPk = v
            nowGrowPkNum = k
        end
    end
    --当有包时则激活按钮
    GrowUpGo:SetActive(nowGrowPk ~= nil)
    if nowGrowPk then
        local GrowUpBtn = self:GetComp(root,"2", "Button")
        local GrowUpImage = self:GetComp(root,"2", "Image")
        self:SetSprite(GrowUpImage, "UI_Main", "btn_premiumpack" .. nowGrowPkNum)
        self:SetText(root,"2/time",GameTextLoader:ReadText("TXT_POPUP_PREMIUMPACK" .. nowGrowPkNum))
        self:SetButtonClickHandler(GrowUpBtn, function()
            -- ShopUI:TurnTo(nowGrowPk)
            GameTableDefine.IntroduceUI:OpenCurrentGrowPackage()
        end)
        self:SetDynamicLocalizeText("MainUI_RefreshGrowPackageBtn", function()
            self:SetText(root,"2/time",GameTextLoader:ReadText("TXT_POPUP_PREMIUMPACK" .. nowGrowPkNum))
        end)
        --添加倒计时
        local timeNodeGo = self:GetGoOrNil(root, "2/time")
        local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(nowGrowPk)
        if self.__timers["growPack"] then
            GameTimer:StopTimer(self.__timers["growPack"])
            self.__timers["growPack"] = nil
        end
        if isTimeGift and leftTime > 0 and timeNodeGo then
            self.__timers["growPack"] = GameTimer:CreateNewTimer(1, function()
                if leftTime > 0 then
                    isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(nowGrowPk)
                    local timeStr = GameTimeManager:FormatTimeLength(leftTime)

                    self:SetText(timeNodeGo, "num", timeStr)
                else
                    if self.__timers["newPack"] then
                        GameTimer:StopTimer(self.__timers["newPack"])
                        self.__timers["newPack"] = nil
                    end
                    -- self:SetText(timeNodeGo, "num", GameTimeManager:FormatTimeLength(0))
                    GrowUpGo:SetActive(false)
                end
            end, true, true)
        end
    end
end
--刷新主界面存钱罐
function MainUIView:RefreshPiggyBankBtn(playAnim)
    -- k124 改为20星之后，才开启存钱罐，没开启时，不显示
    local show = PiggyBankUI:GetPiggyBankEnable()
    self:GetGo("RightPanel/piggyBank"):SetActive(show)
    if not show then
        return
    end

    if playAnim then
        local vfxGO = self:GetGo("RightPanel/piggyBank/pig/vfx")
        if self.piggyBankVfxTimer then
            GameTimer:StopTimer(self.piggyBankVfxTimer)
        end

        self.piggyBankVfxTimer = GameTimer:CreateNewMilliSecTimer(400, function()
            vfxGO:SetActive(false)
        end)

        vfxGO:SetActive(false)
        vfxGO:SetActive(true)
        print("播放主界面存钱罐的扫光动效")
    end

    -- local Slider = self:GetComp("RightPanel/piggyBanklocked", "Slider")
    -- local num = PiggyBankUI:CalculationValue(true)
    -- Slider.value = num
    -- self:GetGo("RightPanel/piggyBankunlocked"):SetActive(num >= 1)
    -- self:GetGo("RightPanel/piggyBanklocked"):SetActive(num < 1)  
    -- self:GetGo("RightPanel/piggyBankunlocked"):SetActive(num >= 1)
    -- self:SetText(self:GetGo("RightPanel/piggyBanklocked"), "num", math.floor(num * 100) .. "%")
    local num = PiggyBankUI:CalculationValue(true)
    -- 可购买或可领取里程碑奖励时，都显示红点
    self:GetGo("RightPanel/piggyBank/icon"):SetActive(num >= 1 or PiggyBankUI:CheckMileRewardEnable())
    local earnings = PiggyBankUI:CalculateEarnings()
    self:SetText("RightPanel/piggyBank/bg/num",earnings.num)
    GameTableDefine.UIPopupManager:EnqueuePopView(PiggyBankUI, function()
        PiggyBankUI:OpenView()
    end, "PiggyBankUI")
end

function MainUIView:SetEventSponsorHint(enable, eventId)
    local btn = self:GetComp("EventArea/npc"..eventId, "Button")
    btn.gameObject:SetActive(enable)

    local openView = {}
    openView[1] = Event001UI
    openView[2] = Event004UI
    openView[3] = Event005UI
    openView[4] = Event006UI
    openView[5] = Event001UI

    if enable then
        self:SetButtonClickHandler(btn, function()
            GameUIManager:SetEnableTouch(false)
            local cfg = ConfigMgr.config_event[eventId]
            local scene = FloorMode:GetScene()
            local idName = string.format("%03d",eventId == 5 and 1 or eventId) -- 5 黄钞（欧元）
            local eventRootGo = GameObject.Find("EventPos/Event".. idName).gameObject
            local dstTrans = scene:GetTrans(eventRootGo, cfg.NPC_dst)
            scene:LocatePosition(dstTrans.position, true, function()
                openView[eventId]:ShowPanel(eventId)
                GameUIManager:SetEnableTouch(true)
            end)
        end)
    end
end
--清空事件UI
function MainUIView:ClearEventUI()
    local transform =self:GetGo("EventArea").transform
    for k,v in pairs(transform) do
        v.gameObject:SetActive(false)
    end
    self:SetSwitchFloorButton()
end

function MainUIView:SetPhoneNum(num)
    self:GetGo("BottomPanel/PhoneUI/icon"):SetActive(num > 0)
    self:SetText("BottomPanel/PhoneUI/icon/num", num)
end

function MainUIView:SetCityHintNum(num)

    local factoryData = LocalDataManager:GetCurrentRecord()["factory"]
    local value = false
    --工厂对Open的影响
    if ConfigMgr.config_buildings[40001].unlock_require <= ResourceManger:GetCash() and StarMode:GetStar() >= 100 then
        if not factoryData or Tools:GetTableSize(factoryData) == 0 then
            value = true
        end
    end
    --K117 红点整合进Open Tip
    self.m_cityHintNum = num + (value and 1 or 0)
    --self:GetGo("BottomPanel/LeaveBtn/icon"):SetActive(num > 0 or value)
end

function MainUIView:SetEventBatmanHint(enable)
    local btn = self:GetComp("EventArea/SkipNightHint", "Button")
    btn.gameObject:SetActive(enable)

    if enable then
        self:SetButtonClickHandler(btn, function()
            GameUIManager:SetEnableTouch(false)
            local scene = FloorMode:GetScene()
            local eventRootGo = GameObject.Find("EventPos/Event100").gameObject
            local dstTrans = scene:GetTrans(eventRootGo, "Event003_NPC_DstPos")
            scene:LocatePosition(dstTrans.position, true, function()
                Event003UI:ShowPanel()
                GameUIManager:SetEnableTouch(true)
            end)
        end)
    end
end

function MainUIView:SetEventRoomBrokenHint(roomIndex, type, roomGo, enable, brokenId)
    local name = "EventArea/RoomBrokenHint_" ..roomIndex
    local tarns =  self:GetTrans(name)
    local go = nil
    if not tarns then
        if enable then
            go = GameObject.Instantiate(self.m_roomBrokenDemo[type] , self.m_roomBrokenDemo["root"].transform)
            go.name = "RoomBrokenHint_" ..roomIndex
            go:SetActive(true)
        else
            return
        end
    end
    if tarns then
        if not enable then
            GameObject.Destroy(tarns.gameObject)
            -- self.roomBrokenData["RoomBrokenHint_" ..roomIndex] = nil
            return
        else
            go = tarns.gameObject
        end
    end
    -- self.roomBrokenData["RoomBrokenHint_" ..roomIndex] = function()
    --     CompanyEmployee:RequestRoomService(roomGo, brokenId, true)
    -- end
    self:SetButtonClickHandler(go:GetComponent("Button"), function()
        local scene = FloorMode:GetScene()
        if roomGo.floorNumberIndex ~= FloorMode:GetCurrentFloorIndex() then
            FloorMode:SetCurrentFloorIndex(roomGo.floorNumberIndex, nil, function()
                scene:LocatePosition(roomGo.go.transform.position, true)
            end)
        else
            scene:LocatePosition(roomGo.go.transform.position, true)
        end
    end)
end

function MainUIView:SetFPS(fps)
    self:SetText("TestAcotr/FPS", fps)
end

function MainUIView:SetQuestHint(num)
    -- self:GetGo("TaskBtn/icon"):SetActive(num > 0)
    self:GetGo("TaskBtn/dot"):SetActive(num > 0)
end

function MainUIView:SetHaveBoardUnread(unread)
    self:GetGo("DetailPanel/BoardBtn/icon"):SetActive(unread)
end

function MainUIView:RefreshMovingHing()
    self:GetGo("MoveBuding/icon"):SetActive(WorldListUI:MovingBtnHint())
end

function MainUIView:RefreshCollectionHing(rewardAble)
    self:GetGo("DetailPanel/CollectionBtn/icon"):SetActive(rewardAble)
end

function MainUIView:RefreshDiamondFund()
    local result = DiamondFundUI:IsCanDraw()
    local iap = GameConfig:IsIAP()
    self:GetGo("RightPanel/BpBtn"):SetActive( self.m_isFloor and iap and DiamondFundUI:IsUnlocked())
    self:GetGo("RightPanel/BpBtn/icon"):SetActive(result)
end

--宠物的入口红点 
function MainUIView:RefreshPetHint()
    local rewardAble = GameTableDefine.DressUpDataManager:CheckNewDressNotViewed()
    self:GetGo("BottomPanel/PetBtn/icon"):SetActive(
            PetInteractUI:DetectStarvationOrUpgrade() or
            rewardAble or
            CEODataManager:NeedShowHint()
    )
end

--活跃度的红点
function MainUIView:RefreshActivityHint()
    self:GetGo("BottomPanel/ActivityBtn/icon"):SetActive(ActivityUI:CheckGiftCanGet())
end
--bool
function MainUIView:SetFestivalActivityBtn(bool)
    self:GetGo("PackPanel/FestivalActivityBtn"):SetActive(bool)
end

--播放主界面知名度图标的扫光动效
function MainUIView:PlayStarAnim()
    local vfxGO = self:GetGo("ResourceBG/CurrStarFrame/vfx")
    if self.starVfxTimer then
        GameTimer:StopTimer(self.starVfxTimer)
    end

    self.starVfxTimer = GameTimer:CreateNewMilliSecTimer(400, function()
        vfxGO:SetActive(false)
    end)

    vfxGO:SetActive(false)
    vfxGO:SetActive(true)
    print("播放主界面知名度图标的扫光动效")
end

function MainUIView:RefreshStarState()
    print("mainui 刷新星星信息")
    local curr = StarMode:GetStar()
    self:SetText("CurrStarFrame/star/lvl", curr)
    print("mainui 刷新成功")
    -- --左下图标及红点
    -- local isMax = StarUI:GetStar() >= StarUI:GetMax()
    -- if isMax then
    --     self:GetGo("StarBtn"):SetActive(false)
    -- else
    --     local raiseAble = StarUI:RaiseAble()
    --     local rewardAble = StarUI:RewardAble()
    --     self:GetGo("StarBtn/Image/icon"):SetActive(raiseAble or rewardAble)
    -- end

    --右上星星及进度条
    -- local progress = StarUI:RaiseProgress()
    -- self:GetComp("CurrStarFrame/prog", "Slider").value = progress

    -- if self.currStar == StarUI:GetStar() then
    --     return
    -- end

    -- self.currStar = StarUI:GetStar()

    -- local starHolder = self:GetTrans("CurrStarFrame/starHolder")
    -- local star
    -- for i = 1, starHolder.childCount do
    --     star = self:GetGo(starHolder.gameObject, "star"..i.."/on")
    --     if i <= self.currStar then
    --         star:SetActive(true)
    --     end
    -- end
end
function MainUIView:RefreshLicenseState() --刷新建筑许可证
    local curr = ResourceManger:GetLicense()
    self:SetText("DetailPanel/LicenseInterface/num", curr)
end
--刷新有关工厂的信息的UI
function MainUIView:RefreshFactorytips()
    self:GetGo("EventArea/StockFull"):SetActive(GameStateManager:IsInFloor() and WorkShopInfoUI:storageLimit() <= 0 and CountryMode:GetCurrCountry() == 1)
    self:GetGo("EventArea/OrderFinish"):SetActive(GameStateManager:IsInFloor() and OrderUI:AnyOrderCanFinish() and CountryMode:GetCurrCountry() == 1)
    self:GetGo("OrderBtn/icon"):SetActive(OrderUI:AnyOrderCanFinish())
end
--工厂引导UI
function MainUIView:RefreshFactoryGuideUI(bool)
    self:GetGo("EventArea/FactoryGuide"):SetActive(bool)
end

--足球俱乐部引导
function MainUIView:RefreshFootballClubGuideUI(bool)
    self:GetGo("EventArea/FBClubGuide"):SetActive(bool)
end

--刷新俱乐部等级
function MainUIView:RefreshFootBallLevel()
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local clubCfg = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][FCData.LV]
    local imageSilder = self:GetComp("ResourceBG/ClubLevelFrame/prog", "Image")
    self:SetText("ResourceBG/ClubLevelFrame/bg/num", FCData.LV)
    imageSilder.fillAmount = FCData.curEXP / clubCfg.exp
    if FCData.curEXP >= clubCfg.exp then
        self:GetGo("ResourceBG/ClubLevelFrame/bg_up"):SetActive(true)
        --self:GetComp("ResourceBG/ClubLevelFrame", "Button").interactable = true
    else
        self:GetGo("ResourceBG/ClubLevelFrame/bg_up"):SetActive(false)
        --self:GetComp("ResourceBG/ClubLevelFrame", "Button").interactable = false
    end
end

--刷新俱乐部联赛等级
function MainUIView:RefreshLeagueLevel()
    local leagueData = FootballClubModel:GetLeagueData()
    local leagueCfg = ConfigMgr.config_league[FootballClubModel.m_cfg.id][leagueData.currLeagueLV]
    local image = self:GetComp("DetailPanel/LeagueFrame/icon","Image")
    self:SetSprite(image,"UI_Common",leagueCfg.iconUI)

end

--刷新俱乐部体力值
function MainUIView:RefreshFCStrength()
    if FootballClubModel:IsInitialized() then
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        local curSP = FootballClubModel:GetSP()
        self:SetText("ResourceBG/StrengthInterface/num/num1",tostring(math.floor(curSP)))
        --self:SetText("ResourceBG/StrengthInterface/num/num1",tostring(math.floor(FCData.SP)))
        self:SetText("ResourceBG/StrengthInterface/num/num2",tostring(FCData.SPlimit))
    end
end

--刷新球馆红点
function MainUIView:RefreshFCStadiumRedPoint()
    local canUpgrade = FCStadiumUI:GetCanUpgrade()
    local UIModel = FCStadiumUI:GetUIModel()
    local FCState = FootballClubModel:GetCurrentState()
    if FootballClubModel:GetRoomDataById(FootballClubModel.StadiumID).state ~= 2 then
        self:GetGo("BottomPanel/StadiumBtn/icon"):SetActive(false)
        return
    end
    -- 当球馆可以升级/比赛就绪/比赛结束时，显示红点提示
    if not canUpgrade or UIModel.matchChance >= 1 or FCState == FootballClubModel.EFCState.GameSettlement then
        self:GetGo("BottomPanel/StadiumBtn/icon"):SetActive(true)
    else
        self:GetGo("BottomPanel/StadiumBtn/icon"):SetActive(false)
    end
end

--刷新训练场红点
function MainUIView:RefreshFCTrainingGroundRedPoint()
    local FCState = FootballClubModel:GetCurrentState()
    if FootballClubModel:GetRoomDataById(FootballClubModel.TrainingGroundID).state ~= 2 then
        self:GetGo("BottomPanel/TranningBtn/icon"):SetActive(false)
        return
    end
    if FCState == FootballClubModel.EFCState.TrainingSettlement then
        self:GetGo("BottomPanel/TranningBtn/icon"):SetActive(true)
    else
        self:GetGo("BottomPanel/TranningBtn/icon"):SetActive(false)
    end
end

--刷新球馆banner
function MainUIView:RefreshStadiumBanner()
    local leagueData = FootballClubModel:GetLeagueData()
    MainUI:UpdateResourceUI()
    local matchChance = FootballClubModel:GetMatchChange(leagueData)
    self:GetGo("EventArea/MatchReady"):SetActive(matchChance >= 1)
end

-- function MainUIView:SetStarHint()
--     local isMax = StarUI:GetStar() >= StarUI:GetMax()
--     if isMax then
--         self:GetGo("StarBtn"):SetActive(false)
--         return
--     end
--     local raiseAble = StarUI:RaiseAble()
--     self:GetGo("StarBtn/Image/icon"):SetActive(raiseAble)
-- end

function MainUIView:SetDiamondHint(rewardAble)
    self:GetGo("DiamondGiftBtn/icon"):SetActive(rewardAble)
end
function MainUIView:SetWheelBtnActive(bool)
    local disp = bool
    self:GetGo("RightPanel/WheelBtn"):SetActive(disp)
end
function MainUIView:SetWheelHint(cdTime)
    self:GetGo("RightPanel/WheelBtn/icon"):SetActive(cdTime <= 0)

    if cdTime > 0 then
        self.__timers = self.__timers or {}
        if self.__timers["wheel"] then
            GameTimer:StopTimer(self.__timers)
        end

        self.__timers["wheel"] = GameTimer:CreateNewTimer(cdTime,
                function()
                    MainUI:RefreshWheelHint()
                end)
    end
end

---刷新月卡提示
function MainUIView:RefreshMonthCardHint()
    local canGetTodayReward = MonthCardUI:CanGetMonthCardReward()
    self:GetGo("RightPanel/McBtn/icon"):SetActive(canGetTodayReward)

    local cdTime = MonthCardUI:GetCDTime()
    if cdTime then
        self.__timers = self.__timers or {}
        if self.__timers["monthCard"] then
            GameTimer:StopTimer(self.__timers["monthCard"])
        end

        self.__timers["monthCard"] = GameTimer:CreateNewTimer(cdTime,
                function()
                    MainUI:RefreshMonthCardHint()
                end)
    end
end

function MainUIView:SetDiamondShopHint(beActive)
    self:GetGo("BottomPanel/ShopBtn/icon"):SetActive(beActive)
    local cd = ShopUI:RewardDiamondCD()
    if cd > 0 then
        GameTimer:CreateNewTimer(cd, function()
            MainUI:RefreshDiamondShop()
        end)
    end
end

function MainUIView:RefreshRewardDiamond()
    -- local cd = ShopUI:RewardDiamondCD()
    -- --self:GetGo("ResourceBG/DiamondInterface/AddBtn/icon"):SetActive(cd <= 0)
    -- if cd > 0 then
    --     GameTimer:CreateNewTimer(cd, function()
    --         MainUI:RefreshRewardDiamond()
    --     end)
    -- end
end

function MainUIView:NotCashChange(get, pay, lastCash, isMax)
    local tips = self:GetGo("IncomeTips")
    --self:GetGo("ResourceBG/MoneyInterface/Image/efficiency"):SetActive(isMax == false)
    self:GetGo("DetailPanel/Efficiency/max"):SetActive(isMax == true)
    self:GetGo("ResourceBG/IncomeTips"):SetActive(isMax == false)

    local ani = self:GetComp("IncomeTips", "Animation")
    self:GetGo("ResourceBG/IncomeTips/income"):SetActive(get > 0)
    local showPay = pay < 0 and (lastCash + pay >= 0)
    self:GetGo("IncomeTips/cost"):SetActive(showPay)
    if get > 0 then
        self:SetText("IncomeTips/income/num", "+"..get)
    end
    if pay < 0 then
        self:SetText("IncomeTips/cost/num", pay)
    end
    self:AddAnimationHander(ani)
    AnimationUtil.Play(ani, "IncomeTips", function()
        self:GetGo("IncomeTips/income"):SetActive(false)
        self:GetGo("IncomeTips/cost"):SetActive(false)
    end)
    if get > 0 or showPay then
        SoundEngine:PlaySFX(SoundEngine.CASH_EARN)
    end
end

function MainUIView:InitCameraScale(name, cb, isBack)
    local cameraFocus = self:GetComp(name, "CameraFocus")
    if cameraFocus then
        local data = {m_cameraSize = cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position = cameraFocus.transform.position}
        local scene = GameTableDefine.GameStateFloor:GetMode():GetScene()
        if isBack then
            local cameraFollow = scene.cameraGO:GetComponent("CameraFollow")
            data.m_cameraSize = cameraFollow.scaleMaxLimit or data.m_cameraSize
            data.m_oldCameraSize = cameraFocus.m_cameraSize
        end
        scene:InitSceneCameraScale(data, cb, isBack)
    end
end

function MainUIView:PlayUIAnimation(toFloor)
    local animation = self.m_uiObj:GetComponent("Animation")
    if toFloor then
        AnimationUtil.Play(animation, "UI_transfer", nil, -1, "KEY_FRAME_ANIM_END")
    else
        AnimationUtil.Play(animation, "UI_transfer", nil, 1)
    end
end

function MainUIView:GuideTimeUIState(isPlay)
    local animation = self.m_uiObj:GetComponent("Animation")
    if isPlay then
        AnimationUtil.Play(animation, "UI_transfer", nil, -1, "KEY_FRAME_ANIM_END")
    else
        AnimationUtil.GotoAndStop(animation, "UI_transfer", "KEY_FRAME_ANIM_END")
    end
end

function MainUIView:MakeEff(roomIndex, currType, sameTypeNum)
    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    local effFocus = GameObject.Find("eff_focus").gameObject

    local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
    local scene = FloorMode:GetScene()

    scene:Locate3DPositionByScreenPosition(effFocus,
            cameraFocus.transform.position, cameraFocus.m_cameraSize, cameraFocus.m_cameraMoveSpeed, function()
                GameUIManager:SetEnableTouch(false)--到底地点也暂时不要取消锁定
            end
    )

    self.__timers = self.__timers or {}
    if not self.__timers["eff_focus"] then
        self.__timers["eff_focus"] = GameTimer:CreateNewTimer(3, function ()

            local data = scene:GetSetCameraLocateRecordData() or {}
            data.isBack = true
            local size = data.offset or cameraFocus.m_cameraSize
            local target2DPosition = data.offset2dPosition
            scene:Locate3DPositionByScreenPosition(effFocus, target2DPosition,
                    size, cameraFocus.m_cameraMoveSpeed)
            self.__timers["eff_focus"] = nil
        end)
    end
    --控制镜头到指定点,并且在结束之后返回
    --local cameraObj = GameObject.Find("effCamera").gameObject
    --self:SetCameraFollowGo(cameraObj)
    --将镜头调整到最大

    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    local data = FloorMode:GetScene():GetRoomRootGoData(roomId)
    local root = data.go
    local eff = UnityHelper.FindTheChild(root, "officebuff")

    --local color = "#FF0000"--到时根据类型配置颜色

    --local rgbColor = UnityHelper.GetColor(color)

    --local partic = UnityHelper.GetTheChildComponent(root, "FX_OfficeBonus", "ParticleSystem")
    --partic.main.startColor = ParticleSystem.MinMaxGradient(rgbColor)

    eff.gameObject:SetActive(true)

    self.__timers["type_eff"..roomIndex] = GameTimer:CreateNewTimer(3, function()
        eff.gameObject:SetActive(false)
    end)

    local setSprite = function(sprite, atlas, name)
        local address = string.format("Assets/Res/SpriteAltas/%s.spriteatlas", atlas)
        local callback = function(handler)
            if sprite:IsNull() then return end
            local toSet = handler.Result:GetSprite(name)
            if not toSet then return end

            sprite.sprite = toSet
            toSet.name = name
        end

        local handler = GameResMgr:LoadSpriteSyncFree(address, self)
        callback(handler)
    end

    --设置提示文字
    local buffText = UnityHelper.GetTheChildComponent(root, "Buff_1/sprite", "SpriteRenderer")
    local spriteName = math.floor(CompanyMode:GetBuffReward(sameTypeNum) * 100)
    if not buffText or buffText:IsNull() then
        GameResMgr:AInstantiateObjectAsyncManual(
                "Assets/Res/UI/Buff_1.prefab",
                self,
                function(childGo)
                    childGo.name = "Buff_1"
                    UnityHelper.AddChildToParent(eff.transform, childGo.transform)
                    local sprite = UnityHelper.GetTheChildComponent(childGo, "sprite", "SpriteRenderer")
                    setSprite(sprite, "UI_BG", "buff_"..spriteName)
                end
        )
    else
        setSprite(buffText, "UI_BG", "buff_"..spriteName)
    end
end

function MainUIView:SetMeetingEventHint(enable)
    local btn = self:GetComp("EventArea/TempConf", "Button")
    btn.gameObject:SetActive(enable)
    if enable then
        self:SetButtonClickHandler(btn, function()
            EventMeetingUI:ShowPanel()
        end)
    end
end

function MainUIView:SetSwitchFloorButton(upEnable, downEnable, target, index)
    if upEnable ~= nil and downEnable ~= nil then
        if not upEnable and not downEnable then
            self:GetGo("FloorPanel"):SetActive(false)
        else
            self:GetGo("FloorPanel"):SetActive(true)
            local upstairBtnGo = self:GetGo("FloorPanel/UpstairBtn")
            upstairBtnGo:SetActive(true)
            local downstairBtnGo = self:GetGo("FloorPanel/DownstairBtn")
            downstairBtnGo:SetActive(true)
            local upBtn = self:GetComp("FloorPanel/UpstairBtn", "Button")
            local downBtn = self:GetComp("FloorPanel/DownstairBtn", "Button")
            upBtn.interactable = upEnable
            downBtn.interactable = downEnable
            self:SetText("FloorPanel/num", index)
        end

    else
        self:GetGo("FloorPanel"):SetActive(false)
    end

    self.m_switchFloorMode = target
end

--进工厂
function MainUIView:EnterFactorySetUI()
    self:SetUIStatus(true)
    self:GetGo("EventArea"):SetActive(false)
    self:GetGo("FloorPanel"):SetActive(false)
    self.m_petBtn.gameObject:SetActive(false)
    self:GetGo("BottomPanel/TaskBtn"):SetActive(false)

    self:GetGo("DetailPanel/LicenseInterface"):SetActive(true)
    self:GetGo("BottomPanel/WarehousetBtn"):SetActive(true)
    self:GetGo("OrderBtn"):SetActive(true)
end

--出工厂
function MainUIView:ExitFactorySetUI()

    self:SetUIStatus(false)
    self:GetGo("DetailPanel/LicenseInterface"):SetActive(false)
    self:GetGo("BottomPanel/WarehousetBtn"):SetActive(false)
    self:GetGo("OrderBtn"):SetActive(false)
end

--进俱乐部
function MainUIView:EnterFootballClubSetUI()
    self:SetUIStatus(true)
    self:GetGo("EventArea"):SetActive(false)
    self:GetGo("RightPanel"):SetActive(false)
    self:GetGo("DetailPanel/CollectionBtn"):SetActive(false)
    self:GetGo("DetailPanel/BoardBtn"):SetActive(false)
    self:GetGo("FloorPanel"):SetActive(false)
    self.m_petBtn.gameObject:SetActive(false)
    self:GetGo("BottomPanel/StadiumBtn"):SetActive(true)
    self:GetGo("BottomPanel/TaskBtn"):SetActive(false)
    self:GetGo("BottomPanel/TranningBtn"):SetActive(true)
    self:GetGo("ResourceBG/CurrStarFrame"):SetActive(false)
    self:GetGo("ResourceBG/ResourceInterface"):SetActive(false)
    self:GetGo("ResourceBG/StrengthInterface"):SetActive(true)
    self:GetGo("PackPanel"):SetActive(false)

    self:RefreshFootBallLevel()
    self:RefreshLeagueLevel()
    self:RefreshFCStrength()
    self:RefreshFCStadiumRedPoint()
    self:RefreshFCTrainingGroundRedPoint()

end


function MainUIView:LocateSpecialBuildingTarget(targetPosition)

    local endTarget = self:GetComp("IndoorScale", "CameraFocus")
    local succ, position = self:GetScene():GetSceneGroundPosition(endTarget.transform.position)
    self:GetScene():LocatePosition(self:GetScene().capsuleGO.transform.position - (position - targetPosition), true)
end


function MainUIView:SetPowerBtnState(enable)
    local electricBtn = self:GetGo("ResourceBG/ResourceInterface/AddBtn")
    electricBtn:SetActive(enable)
end

function MainUIView:DisplayActivityRankBtn()
    if self.activityDisplayTimer then
        GameTimer:StopTimer(self.activityDisplayTimer)
        self.activityDisplayTimer = nil
    end
    self.activityRankLeftTime = ActivityRankDataManager:GetCurrentLeftTime()
    if self.activityRankLeftTime > 0 then
        self.activityDisplayTimer = GameTimer:CreateNewTimer(1, function()
            -- self.activityRankLeftTime = self.activityRankLeftTime - 1
            -- if self.activityRankLeftTime <= 0 then
            --     if self.activityDisplayTimer then
            --         GameTimer:StopTimer(self.activityDisplayTimer)
            --         self.activityDisplayTimer = nil
            --     end
            -- end
            -- self:SetText("PackPanel/rank/remain", GameTimeManager:FormatTimeLength(self.activityRankLeftTime))
            -- self:GetGo("PackPanel/rank/remain"):SetActive(self.activityRankLeftTime > 0)
            -- self:GetGo("PackPanel/rank/end"):SetActive(self.activityRankLeftTime <= 0)
            self:SetActivityOverTimePassed()
        end, true)
    end
    self:SetText("PackPanel/rank/remain", GameTimeManager:FormatTimeLength(self.activityRankLeftTime))
    self:GetGo("PackPanel/rank/remain"):SetActive(self.activityRankLeftTime > 0)
    --self:GetGo("PackPanel/rank/end"):SetActive(self.activityRankLeftTime <= 0)
    self:GetGo("PackPanel/rank"):SetActive(ActivityRankDataManager:CanDisplayMainUIEntry())
end

function MainUIView:SetActivityOverTimePassed()
    self.activityRankLeftTime = ActivityRankDataManager:GetCurrentLeftTime()
    if self.activityRankLeftTime <= 0 then
        if self.activityDisplayTimer then
            GameTimer:StopTimer(self.activityDisplayTimer)
            self.activityDisplayTimer = nil
        end
    end
    self:SetText("PackPanel/rank/remain", GameTimeManager:FormatTimeLength(self.activityRankLeftTime))
    self:GetGo("PackPanel/rank/remain"):SetActive(self.activityRankLeftTime > 0)
    self:GetGo("PackPanel/rank/end"):SetActive(self.activityRankLeftTime <= 0)
end

function MainUIView:ReOpenActivityRankBtn()
    self:GetGo("PackPanel/rank"):SetActive(true)
    self:DisplayActivityRankBtn()
end

function MainUIView:CheckTransformAsset()
    --step 1 检测是否显示按钮，检测是地区和是否场景1有可转移的资产
    if CountryMode:GetCurrCountry() == 2 and PetMode:CheckPetsCanTrans(2) then
        --step 2 显示按钮
        self:GetGo("PackPanel/transferBtn"):SetActive(true)
        self:SetButtonClickHandler(self:GetComp("PackPanel/transferBtn", "Button"), function()
            --如果当前的知名度不够弹出阿珍对话框
            local needStar = ConfigMgr.config_global.transfer_condition
            if StarMode:GetStar() < needStar then
                TalkUI:OpenTalk("transfer", {fame = ConfigMgr.config_global.transfer_condition})
            else
                local txt = GameTextLoader:ReadText("TXT_TIP_TRANSFER_CONFIRM")
                ChooseUI:CommonChoose(txt, function()
                    --调用一键转移资产的接口
                    print("开始资产转移了")
                    self:GetGo("PackPanel/transferBtn"):SetActive(false)
                    PetMode:PetsTransfer(2, handler(MainUI, MainUI.CheckTransformAsset))
                end, true, nil)
            end
        end)
    else
        self:GetGo("PackPanel/transferBtn"):SetActive(false)
    end
end

function MainUIView:CheckHavePreviewInstance()    
    local previewData = false
    local previewButtonName = nil

    -- 是否显示预告
    previewData = CycleInstanceDataManager:GetCurPreviewInstance()
    if previewData then
        -- 判断开启条件
        --if not CycleInstanceDataManager:GetInstanceEnable() then
            --self.cycleInstanceEnablePrevTimer = GameTimer:CreateNewTimer(1, function()
            --    if CycleInstanceDataManager:GetInstanceEnable() then
            --        if self.cycleInstanceEnablePrevTimer then
            --            GameTimer:StopTimer(self.cycleInstanceEnablePrevTimer)
            --            self.cycleInstanceEnablePrevTimer = nil
            --        end
            --        
            --        self:CheckHavePreviewInstance()
            --    end
            --end, true, true)

            --self:GetGo("PackPanel/Instance"):SetActive(false)
            --return
        --end

        local id = previewData.m_Instance_id
        local instanceBInd = CycleInstanceDataManager:GetInstanceBind(id)
        previewButtonName = instanceBInd.entranceBtn

        -- 停止副本按钮的刷新
        if self.instanceTimer then
            GameTimer:StopTimer(self.instanceTimer)
            self.instanceTimer = nil
        end
    else
        return
    end
    self:GetGo("PackPanel"):SetActive(true)
    local parent = self:GetGo("PackPanel/Instance")
    parent:SetActive(true)
    local button = self:GetComp(parent, previewButtonName, "Button")
    local go = button.gameObject
    go:SetActive(true)
    local timeGO = self:GetGo(go, "time")
    timeGO:SetActive(false)
    local vfxGO = self:GetGo(go, "vfx")
    vfxGO:SetActive(false)
    local preview = self:GetGo(go, "preview")
    preview:SetActive(true)

    local refreshPreviewTime = function()
        local now = GameTimeManager:GetTheoryTime()
        local previewRemain = previewData.m_StartTime - now
        if previewRemain <= 0 then
            -- 停止预告的刷新
            GameTimer:StopTimer(self.cycleInstancePreviewTimer)
            self.cycleInstancePreviewTimer = nil
            -- 恢复显示UI节点
            timeGO:SetActive(true)
            preview:SetActive(false)
            self:CheckHaveActiveInstance()
            return
        end
        previewRemain = GameTimeManager:GetTimeLengthDate(previewRemain)
        local remainStr = math.floor(previewRemain.d) .. "D" .. math.floor(previewRemain.h) .. "H"
        if math.floor(previewRemain.d) == 0 and math.floor(previewRemain.h) == 0 then
            remainStr = math.floor(previewRemain.h) .. "H" .. math.floor(previewRemain.m) .. "M"
        end
        local text = GameTextLoader:ReadText("TXT_INSTANCE_PREVIEW") or ""
        local finalText,_ = text:gsub("%%s", remainStr)
        self:SetText(preview, "txt", finalText)
    end

    if self.cycleInstancePreviewTimer then
        return
    end
    self.cycleInstancePreviewTimer = GameTimer:CreateNewTimer(1, function()
        refreshPreviewTime()
    end, true, true)

end

function MainUIView:CheckHaveActiveInstance()

    local isCycleInstance = false
    local instanceIsActive = false
    local buttonName = nil
    local state = nil
    local instanceState = InstanceDataManager:GetInstanceState()
    CycleInstanceDataManager:GetCurActivityInstance()
    local cycleInstanceState = CycleInstanceDataManager:GetInstanceState()
    if instanceState ~= InstanceDataManager.instanceState.overtime then
        instanceIsActive = true
        buttonName = InstanceDataManager:GetInstanceBind().entranceBtn
        state = instanceState
    elseif cycleInstanceState == CycleInstanceDataManager.instanceState.isActive or cycleInstanceState == CycleInstanceDataManager.instanceState.awartable then
        isCycleInstance = true
        instanceIsActive = true
        buttonName = CycleInstanceDataManager:GetInstanceBind().entranceBtn
        state = cycleInstanceState
        -- 停止预告的刷新
        GameTimer:StopTimer(self.cycleInstancePreviewTimer)
        self.cycleInstancePreviewTimer = nil
    else
        buttonName = "" --or InstanceDataManager:GetInstanceBind().entranceBtn
    end


    -- 设置按钮显隐
    local parent = self:GetGo("PackPanel/Instance")
    local childCount = parent.transform.childCount
    for i=0, childCount - 1 do
        local child = parent.transform:GetChild(i)
        child.gameObject:SetActive(false)
    end

    local button = self:GetComp(parent,buttonName,"Button")

    if isCycleInstance then
        -- 判断开启条件
        --if not CycleInstanceDataManager:GetInstanceEnable() then
        --    self.cycleInstanceEnableTimer = GameTimer:CreateNewTimer(1, function()
        --        if CycleInstanceDataManager:GetInstanceEnable() then
        --            if self.cycleInstanceEnableTimer then
        --                GameTimer:StopTimer(self.cycleInstanceEnableTimer)
        --                self.cycleInstanceEnableTimer = nil
        --            end
        --
        --            self:CheckHaveActiveInstance()
        --        end
        --    end, true, true)
        --
        --    self:GetGo("PackPanel/Instance"):SetActive(false)
        --    return
        --end
        
        --设置一下新副本的图标
        local iconGo = self:GetGoOrNil(button.gameObject, "vfx/icon")
        if state == CycleInstanceDataManager.instanceState.awartable then
            if next(CycleInstanceDataManager:GetCurrentModel():GetAllSKRewardNotClaim()) == nil then
                --parent:SetActive(false)
                --return
            end
        end
        if state == CycleInstanceDataManager.instanceState.isActive and iconGo then
            --表明是新副本了，需要获取奖励相关的内容去做一个图标显示
            local currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
            local cycleInstanceMilepostUI
            if currentModel then
                cycleInstanceMilepostUI = GameTableDefine.CycleInstanceDataManager:GetCycleInstanceMilepostUI()
            end
            local data = cycleInstanceMilepostUI and cycleInstanceMilepostUI:CalculateData() or {}
            local canClaimData = nil
            local nextData = nil

            for k, v in ipairs(data) do
                if v.rewardStatus == 3 then
                    canClaimData = v
                    break
                end
                if v.rewardStatus == 2 then
                    nextData = v
                    break
                end
            end
            local vfxGO = self:GetGo(button.gameObject,"vfx")
            --iconGo:SetActive(true)
            if canClaimData then
                local iconImage = self:GetComp(iconGo,"", "Image")
                self:SetSprite(iconImage, "UI_Shop", canClaimData.icon)
                vfxGO:SetActive(true)
            elseif nextData then
                local iconImage = self:GetComp(iconGo,"", "Image")
                self:SetSprite(iconImage, "UI_Shop", nextData.icon)
                vfxGO:SetActive(true)
            else
                --iconGo:SetActive(false)
                vfxGO:SetActive(false)
            end
        else
            self:GetGoOrNil(button.gameObject, "vfx"):SetActive(false)
        end
        parent:SetActive(true)
        button.gameObject:SetActive(not FloorMode:IsInFactory())


        self:SetButtonClickHandler(button,function()
            if isCycleInstance then
                CycleInstanceDataManager:GetCycleInstanceUI():OpenView()
            else
                InstanceViewUI:OpenInstanceViewUI()
            end
        end)
        GameTableDefine.UIPopupManager:EnqueuePopView(GameTableDefine.CycleInstanceDataManager, function()
            --添加检测活动自动弹出进入的功能
            if isCycleInstance then
                CycleInstanceDataManager:GetCycleInstanceUI():OpenView()
                GameTimer:StopTimer(self.CheckInstanceDisplayTimer)
                self.CheckInstanceDisplayTimer = nil

            else
                if InstanceDataManager:CanDisplayEnterUI() then
                    InstanceViewUI:OpenInstanceViewUI()
                end
            end

        end, "CycleInstanceDataManager")

        -- 刷新进入按钮显示
        self.instanceTimer = GameTimer:CreateNewTimer(1,function()
            local timeRemaining = 0
            if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
                instanceIsActive = true
                state = InstanceDataManager:GetInstanceState()
                isCycleInstance = false
                if state == InstanceDataManager.instanceState.isActive then
                    timeRemaining = InstanceDataManager:GetLeftInstanceTime()
                else
                    timeRemaining = InstanceDataManager:GetInstanceRewardTime()
                end
            elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
                instanceIsActive = true
                state = CycleInstanceDataManager:GetInstanceState()
                isCycleInstance = true
                if state == CycleInstanceDataManager.instanceState.isActive then
                    timeRemaining = CycleInstanceDataManager:GetLeftInstanceTime()
                else
                    timeRemaining = CycleInstanceDataManager:GetInstanceRewardTime()
                end
            end

            local timeDate = GameTimeManager:GetTimeLengthDate(timeRemaining)
            local d = timeDate.d
            local h = timeDate.h + d * 24
            local m = timeDate.m
            local s = timeDate.s
            if h < 10 then h = "0"..h end
            if m < 10 then m = "0"..m end
            if s < 10 then s = "0"..s end
            local timeStr = string.format("%s:%s:%s",h,m,s)

            if state == InstanceDataManager.instanceState.isActive or state == InstanceDataManager.instanceState.locked then
                local tmpGO = self:GetGoOrNil(button.gameObject,"end")
                if tmpGO then
                    tmpGO:SetActive(false)
                end
                self:SetText(button.gameObject,"time/num",timeStr)
            elseif state == InstanceDataManager.instanceState.awartable then
                self:GetGoOrNil(button.gameObject, "vfx"):SetActive(false)
                local tmpGO = self:GetGoOrNil(button.gameObject,"end")
                if tmpGO then
                    tmpGO:SetActive(true)
                end
                self:SetText(button.gameObject,"end/time/num",timeStr)
            end
            if timeRemaining <= 0 and state == InstanceDataManager.instanceState.awartable then
                if self.instanceTimer then
                    GameTimer:StopTimer(self.instanceTimer)
                    self.instanceTimer = nil
                end
                if self.CheckInstanceDisplayTimer then
                    GameTimer:StopTimer(self.CheckInstanceDisplayTimer)
                    self.CheckInstanceDisplayTimer = nil
                end
                parent:SetActive(false)
                local tmpGO = button.gameObject
                if tmpGO then
                    tmpGO:SetActive(false)
                end

            end
        end,true,true)
    else -- 老副本的代码
        parent:SetActive(false)
        -- self:GetGo("PackPanel/InstanceBtn"):SetActive(false)
        --if self.CheckInstanceDisplayTimer then
        --    GameTimer:StopTimer(self.CheckInstanceDisplayTimer)
        --    self.CheckInstanceDisplayTimer = nil
        --end
        --local tmpGO = button.gameObject
        --if tmpGO then
        --    tmpGO:SetActive(false)
        --end
    end
end

--设置碎片活动UI
function MainUIView:FragmentActivity(isFloor)
    --碎片活动按钮
    local FestivalActivityBtn = self:GetComp("PackPanel/FestivalActivityBtn", "Button")
    if not isFloor then
        if self.fragmentTime then
            GameTimer:StopTimer(self.fragmentTime)
            self.fragmentTime = nil
        end
        FestivalActivityBtn.gameObject:SetActive(false)
        return
    end
    local bool = FestivalActivityBtn.gameObject.activeSelf
    local bool2 = FestivalActivityBtn.gameObject.activeSelf
    self:SetButtonClickHandler(FestivalActivityBtn, function()
        FragmentActivityUI:GetView()
        GameSDKs:TrackForeign("rank_activity", {name = "Fragment", operation = "1"})
    end)
    self:GetGo("PackPanel/FestivalActivityBtn/end"):SetActive(false)
    self:GetGo("PackPanel/FestivalActivityBtn/time"):SetActive(true)
    if not self.fragmentTime then
        self.fragmentTime = GameTimer:CreateNewMilliSecTimer(1000, function()
            local fragment = FragmentActivityUI:GetFragmentNum("pets")
            fragment = fragment > 99 and "99+" or fragment
            self:SetText("PackPanel/FestivalActivityBtn/coin_num/num", fragment)
            local finishCount, taskCount, haveFinished = FragmentActivityUI:GetTaskState()
            self:SetText("PackPanel/FestivalActivityBtn/prog/Fill Area/txt/num_1",finishCount)
            self:SetText("PackPanel/FestivalActivityBtn/prog/Fill Area/txt/num_2",taskCount)
            self:GetComp("PackPanel/FestivalActivityBtn/prog","Slider").value = finishCount/taskCount
            self:GetGo("PackPanel/FestivalActivityBtn/tip"):SetActive(haveFinished)

            local value, endTime = FragmentActivityUI:GetTimeRemaining()
            if value > 0 then
                if not bool2  then
                    FestivalActivityBtn.gameObject:SetActive(true)
                    bool2 = true
                end
                self:SetText("PackPanel/FestivalActivityBtn/time", TimerMgr:FormatTimeLength(value))
            elseif endTime > 0 then
                --GameTimer:StopTimer(FragmentTime)
                if not bool  then
                    FestivalActivityBtn.gameObject:SetActive(true)
                    bool = true
                end
                self:GetGo("PackPanel/FestivalActivityBtn/end"):SetActive(true)
                self:GetGo("PackPanel/FestivalActivityBtn/time"):SetActive(false)
            else
                GameTimer:StopTimer(self.fragmentTime)
                self.fragmentTime = nil
                FestivalActivityBtn.gameObject:SetActive(false)
            end
        end, true, true)
    end
    -- 打开弹窗
    FragmentActivityUI:OpenGuidePanel()
end

--设置限时礼包活动UI
function MainUIView:LimitPackActivity(isFloor)
    local limitPackBtn = self:GetComp("PackPanel/LimitPack", "Button")
    local limitPackData = LimitPackUI:GetLimitPackData()
    if not limitPackData or not limitPackData.LimitPackEnable or not LimitPackUI:IsActive() then
        limitPackBtn.gameObject:SetActive(false)
        return
    end
    
    if not isFloor then
        if self.limitPackTime then
            GameTimer:StopTimer(self.limitPackTime)
            self.limitPackTime = nil
        end
        limitPackBtn.gameObject:SetActive(false)
        return
    end
    local active = limitPackBtn.gameObject.activeSelf
    if not self.limitPackTime then
        self.limitPackTime = GameTimer:CreateNewMilliSecTimer(1000, function()
            local activePack = LimitPackUI:GetFirstActivePack()
            if activePack then
                if not active then
                    local icon = limitPackData.icon
                    if icon then
                        local iconImage = self:GetComp("PackPanel/LimitPack/activityIcon","Image")
                        self:SetSprite(iconImage,"UI_Main",icon)
                    end
                    limitPackBtn.gameObject:SetActive(true)
                    active = true
                end
                local timeRemaining = LimitPackUI:GetTimeRemaining()
                self:SetText("PackPanel/LimitPack/remain", TimerMgr:FormatTimeLength(timeRemaining))
            else
                GameTimer:StopTimer(self.limitPackTime)
                self.limitPackTime = nil
                limitPackBtn.gameObject:SetActive(false)
            end
        end, true, true)
    end
    --打开弹窗
    GameTableDefine.UIPopupManager:EnqueuePopView(LimitPackUI, function()
        LimitPackUI:OpenPanel()
    end, "LimitPackUI")
end

--设置限时多选一礼包活动UI
function MainUIView:LimitChooseActivity(isFloor)
    local button = self:GetComp("PackPanel/LimitChoose", "Button")
    local limitPackChooseData = LimitChooseUI:GetLimitChooseData()
    if not limitPackChooseData or not limitPackChooseData.LimitPackChooseEnable or not LimitChooseUI:IsActive() then
        button.gameObject:SetActive(false)
        return
    end
    
    if not isFloor then
        if self.m_limitChooseTimer then
            GameTimer:StopTimer(self.m_limitChooseTimer)
            self.m_limitChooseTimer = nil
        end
        button.gameObject:SetActive(false)
        return
    end
    local active = button.gameObject.activeSelf
    if not self.m_limitChooseTimer then
        self.m_limitChooseTimer = GameTimer:CreateNewMilliSecTimer(1000, function()
            local canBuy = LimitChooseUI:IsActive() and not LimitChooseUI:IsBought()
            if canBuy then
                if not active then
                    local icon = limitPackChooseData.icon
                    if icon then
                        local iconImage = self:GetComp("PackPanel/LimitChoose/activityIcon","Image")
                        self:SetSprite(iconImage,"UI_Main",icon)
                    end
                    button.gameObject:SetActive(true)
                    active = true
                end
                local timeRemaining = LimitChooseUI:GetTimeRemaining()
                self:SetText("PackPanel/LimitChoose/remain", TimerMgr:FormatTimeLength(timeRemaining))
            else
                GameTimer:StopTimer(self.m_limitChooseTimer)
                self.m_limitChooseTimer = nil
                button.gameObject:SetActive(false)
            end
        end, true, true)
    end
    --打开弹窗
    GameTableDefine.UIPopupManager:EnqueuePopView(LimitChooseUI, function()
        LimitChooseUI:OpenView()
    end, "LimitChooseUI")
end

--强制设置界面的钱和钻石的显示的数量(用于转盘加资源后的滞后显示)
function MainUIView:Forcedisplay(money, diamonds)
    if money then
        self:SetText("ResourceBG/MoneyInterface/Image/text", Tools:SeparateNumberWithComma(money))
    end
    if diamonds then
        self:SetText("ResourceBG/DiamondInterface/Image/text", Tools:SeparateNumberWithComma(diamonds))
    end
end

---刷新累充活动入口的显示,包括每日一次自动打开界面的判断
function MainUIView:RefreshAccumulatedChargeActivity()
    local btnGO = self:GetGo("PackPanel/Payment")
    if not AccumulatedChargeActivityDataManager:AccumulatedChargeEnable() then
        btnGO.gameObject:SetActive(false)
        return
    end

    if AccumulatedChargeActivityDataManager:GetActivityIsOpen() then
        btnGO:SetActive(true)
        local freeGO = self:GetGo(btnGO,"icon/tip")
        if freeGO then
            freeGO:SetActive(AccumulatedChargeActivityDataManager:IsCurItemFree())
        end
        if not self.accumulatedChargeACTimer then
            self.accumulatedChargeACTimer = GameTimer:CreateNewTimer(1, function()
                if AccumulatedChargeActivityDataManager:GetActivityLeftTime() > 0 then
                    self:SetText("PackPanel/Payment/remain", GameTimeManager:FormatTimeLength(AccumulatedChargeActivityDataManager:GetActivityLeftTime()))
                else
                    GameTimer:StopTimer(self.accumulatedChargeACTimer)
                    self.accumulatedChargeACTimer = nil
                    if btnGO then
                        btnGO:SetActive(false)
                    end
                end
            end, true, true)
        end
        self:SetText("PackPanel/Payment/remain", GameTimeManager:FormatTimeLength(AccumulatedChargeActivityDataManager:GetActivityLeftTime()))
    else
        if self.accumulatedChargeACTimer then
            GameTimer:StopTimer(self.accumulatedChargeACTimer)
            self.accumulatedChargeACTimer = nil
        end
        if btnGO then
            btnGO:SetActive(false)
        end
    end
    GameTableDefine.UIPopupManager:EnqueuePopView(AccumulatedChargeACUI, function()
        AccumulatedChargeACUI:OpenView()
    end, "AccumulatedChargeACUI")
end

---刷新首充重置活动入口
function MainUIView:RefreshFirstPurchaseBtn()
    local btnGO = self:GetGoOrNil("PackPanel/FirstPurchaseBtn")
    if FirstPurchaseUI:GetActivityIsOpen() then
        if btnGO then
            btnGO:SetActive(true)
        end
        if not self.m_firstPurchaseTimer then
            self.m_firstPurchaseTimer = GameTimer:CreateNewTimer(1, function()
                local leftTime = FirstPurchaseUI:GetActivityLeftTime()
                if leftTime > 0 then
                    self:SetText("PackPanel/FirstPurchaseBtn/remain", GameTimeManager:FormatTimeLength(leftTime))
                else
                    GameTimer:StopTimer(self.m_firstPurchaseTimer)
                    self.m_firstPurchaseTimer = nil
                    if btnGO then
                        btnGO:SetActive(false)
                    end
                end
            end, true, true)
        end
        self:SetText("PackPanel/FirstPurchaseBtn/remain", GameTimeManager:FormatTimeLength(FirstPurchaseUI:GetActivityLeftTime()))
    else
        if self.m_firstPurchaseTimer then
            GameTimer:StopTimer(self.m_firstPurchaseTimer)
            self.m_firstPurchaseTimer = nil
        end
        if btnGO then
            btnGO:SetActive(false)
        end
    end
    GameTableDefine.UIPopupManager:EnqueuePopView(GameTableDefine.FirstPurchaseUI, function()
        GameTableDefine.FirstPurchaseUI:OpenView()
    end, "FirstPurchaseUI")
end

---刷新赛季活动入口
function MainUIView:RefreshSeasonPassBtn()
    local btnGO = self:GetGoOrNil("PackPanel/SeasonPass")
    if SeasonPassManager:GetActivityIsOpen() then
        -- 对应主题的进入图标
        local icons = UnityHelper.GetAllChilds(self:GetGo("PackPanel/SeasonPass/passIcon"))
        local theme = SeasonPassManager:GetTheme()
        for i = 0, icons.Length - 1 do
            local go = icons[i]
            go.gameObject:SetActive(go.gameObject.name == theme)
        end
        
        if not self.m_seasonRemainText then
            self.m_seasonRemainText = self:GetComp(self.m_uiObj,"PackPanel/SeasonPass/remain","TMPLocalization")
        end
        if not self.m_seasonPassTimer then
            local redPointGO = self:GetGo("SeasonPass/redTip")
            local coinPusherManager = GameTableDefine.CoinPusherManager
            local unlockBuildingID = ConfigMgr.config_global.pass_openScene or 200
            self.m_seasonPassTimer = GameTimer:CreateNewTimer(1, function()
                local leftTime = SeasonPassManager:GetActivityLeftTime()
                if leftTime > 0 then
                    if leftTime > 86400 then
                        local timeDate = GameTimeManager:GetTimeLengthDate(leftTime)
                        self.m_seasonRemainText.text = string.format("%dd %dh",timeDate.d,timeDate.h)
                    else
                        self.m_seasonRemainText.text = GameTimeManager:FormatTimeLength(leftTime)
                    end
                    local needShow = SeasonPassManager:CanClaimAnyReward() or
                            GameTableDefine.SeasonPassTaskManager:GetCanClaimTaskTotalNum() > 0 or
                            coinPusherManager:IsNeedShowGameHintPoint()
                    --红点提示
                    redPointGO:SetActive(needShow)

                    if not btnGO.activeSelf then
                        local buildingId = CityMode:GetCurrentBuilding()
                        if buildingId and buildingId >= unlockBuildingID then
                            btnGO:SetActive(true)
                        end
                    end
                else
                    GameTimer:StopTimer(self.m_seasonPassTimer)
                    self.m_seasonPassTimer = nil
                    if btnGO then
                        btnGO:SetActive(false)
                    end
                end
            end, true, true)
        end
        --self.m_seasonRemainText.text = GameTimeManager:FormatTimeLength(SeasonPassManager:GetActivityLeftTime(),true)
    else
        if self.m_seasonPassTimer then
            GameTimer:StopTimer(self.m_seasonPassTimer)
            self.m_seasonPassTimer = nil
        end
        if btnGO then
            btnGO:SetActive(false)
        end
    end
    GameTableDefine.UIPopupManager:EnqueuePopView(GameTableDefine.SeasonPassPopupUI, function()
        GameTableDefine.SeasonPassPopupUI:OpenView()
    end, "SeasonPassPopupUI")
end

---可以购买下一个大楼时，就显示提示
function MainUIView:RefreshOfficeTip(isFloor)
    if self.m_officeTipTimer then
        GameTimer:StopTimer(self.m_officeTipTimer)
        self.m_officeTipTimer = nil
    end

    local officeTip = self:GetGoOrNil("BottomPanel/LeaveBtn/tip")
    if officeTip then
        if isFloor then
            local active = officeTip.activeSelf
            self.m_officeTipTimer = GameTimer:CreateNewTimer(1,function()
                --是否有工厂或大地图区块需要提示
                local showTip = (self.m_cityHintNum or 0) > 0
                if not showTip then
                    --判断星级和钱是否能买新办公楼
                    local curBuildingID = CountryMode:GetMaxDevelopCountryBuildingID()
                    local config = ConfigMgr.config_buildings[curBuildingID+100]
                    if config then
                        local curStar = StarMode:GetStar()
                        local curMoney = CountryMode:GetCurrCountry() == 2 and ResourceManger:GetEUR() or ResourceManger:GetCash()
                        --1号场景不需要买得起就显示Open
                        if (curBuildingID==100 or curMoney>=config.unlock_require) and curStar>=config.starNeed and StoryLineManager:IsCompleteStage(config.unlock_stage) then
                            showTip = true
                        end
                    end
                end
                if not showTip then
                    --判断是否有没去过的伟大建筑，汽车商店，豪宅
                    showTip = CityMode:AnyBuildingNeedCome()
                end
                if showTip then
                    if not active then
                        active = true
                        officeTip:SetActive(true)
                    end
                else
                    if active then
                        active = false
                        officeTip:SetActive(false)
                    end
                end
            end,1,true)
        else
            officeTip:SetActive(false)
        end
    end
end

function MainUIView:RefreshQuestionSurvey()
    local surveyIsOpen = GameTableDefine.QuestionSurveyDataManager:GetQuestionIsOpen()
    if surveyIsOpen then
        local award = 0
        local mathcRuleIndex = GameTableDefine.QuestionSurveyDataManager:matchRule()
        local surveyConfig = ConfigMgr.config_survey_new[CS.UnityEngine.Application.version] or {}
        if mathcRuleIndex > 0 then
            local surveyConf = surveyConfig[mathcRuleIndex] or {}
            award = surveyConf and surveyConf.award or 0
        end

        -- 显示奖励数值到主界面
        self:GetComp("PackPanel/SurveyBtn/reward/num", "TMPLocalization").text = award
    end

    --self:GetGo("PackPanel/SurveyBtn"):SetActive(surveyIsOpen)
    self:GetGo("PackPanel/SurveyBtn"):SetActive(surveyIsOpen)

    --self:GetGo("PackPanel/SurveyBtn"):SetActive(GameTableDefine.QuestionSurveyDataManager:GetQuestionIsOpen())
end

function MainUIView:CloseInstanceEntry()
    if self.instanceTimer then
        GameTimer:StopTimer(self.instanceTimer)
        self.instanceTimer = nil
    end
    if self.CheckInstanceDisplayTimer then
        GameTimer:StopTimer(self.CheckInstanceDisplayTimer)
        self.CheckInstanceDisplayTimer = nil
    end
    -- 设置按钮显隐
    local parent = self:GetGo("PackPanel/Instance")
    parent:SetActive(false)
end

---主线故事栏
function MainUIView:RefreshMainLinePanel(isFloor)
    local mainLinePanel = self:GetGoOrNil("MainLinePanel")
    if mainLinePanel then
        if isFloor then
            local showBtn = GuideManager:IsShowMainStoryBtn()
            mainLinePanel:SetActive(showBtn)
            if showBtn then
                if not self.m_mainLineTimer then
                    --间隔1s刷新图标状态.
                    local progressSlider = self:GetComp("MainLinePanel/prog","Slider")
                    local nowText = self:GetComp("MainLinePanel/prog/txt/now","TMPLocalization")
                    local totalText = self:GetComp("MainLinePanel/prog/txt/total","TMPLocalization")
                    local completeMark = self:GetGoOrNil("MainLinePanel/bubble")
                    local completeAnim = self:GetComp("MainLinePanel/btn/bg2","Animation")
                    local completeAnim2 = self:GetComp("MainLinePanel/icon","Animation")
                    local hintPointGO = self:GetGoOrNil(mainLinePanel,"icon")
                    self.m_mainLineTimer = GameTimer:CreateNewTimer(1,function()
                        if not mainLinePanel.activeInHierarchy then
                            --使用下面的代码会在打开其他界面后停止及时更新界面
                            --GameTimer:StopTimer(self.m_mainLineTimer)
                            --self.m_mainLineTimer = nil
                        else
                            local nowValue,totalValue = StoryLineManager:GetCurStageProgress()
                            local progress = totalValue>0 and nowValue/totalValue or 1
                            nowText.text = tostring(nowValue)
                            totalText.text = tostring(totalValue)
                            progressSlider.value = progress
                            local showCompleteMark = StoryLineManager:IsCurrentStageCanComplete()
                            if completeMark then
                                completeMark:SetActive(showCompleteMark)
                            end
                            if hintPointGO then
                                hintPointGO:SetActive(showCompleteMark)
                            end
                            if completeAnim then
                                if showCompleteMark then
                                    if not completeAnim.isPlaying then
                                        AnimationUtil.Play(completeAnim,"vfx_mainlineLight")
                                    end
                                else
                                    if completeAnim.isPlaying then
                                        AnimationUtil.Reset(completeAnim,"vfx_mainlineLight")
                                    end
                                end
                            end
                            if completeAnim2 then
                                if showCompleteMark then
                                    if not completeAnim2.isPlaying then
                                        AnimationUtil.Play(completeAnim2,"vfx_mainlineDot")
                                    end
                                else
                                    if completeAnim2.isPlaying then
                                        AnimationUtil.Reset(completeAnim2,"vfx_mainlineDot")
                                    end
                                end
                            end
                        end
                    end,true,true)
                end
            end
        else
            mainLinePanel:SetActive(false)
        end
    end
end
function MainUIView:OnCEOActorChanged(roomIndex, id)
    if id and id ~= CountryMode:GetCurrCountry() then
        return
    end
    local  countryId = CountryMode:GetCurrCountry() or 1
       
    if countryId == 3 then
        countryId = CityMode:CheckBuildingSatisfy(700) and 2 or 1
    end
    local lv = LocalDataManager:GetDataByKey("bank")
    lv = lv["lv" .. CountryMode.SAVE_KEY[countryId]]
    local limit = ConfigMgr.config_bank[lv][ValueManager.limitKey[countryId]]
    local curr = ResourceManger:GetLocalMoney()
    if not limit then
        return
    end
    if curr >= limit then           --已经满了
        self:RefreshCashEarn(true)
    else
        self:RefreshCashEarn()                                                                  
    end
end

--[[
    @desc: 刷新显示CEO宝箱可开启的显示
    author:{author}
    time:2025-02-27 15:19:36
    @return:
]]
function MainUIView:RefreshCEOBoxTipsDisp()
    local state, icon = CEODataManager:CheckCEOBoxCanUse()
    self:GetGo("BottomPanel/ShopBtn/chest"):SetActive(state > 0)
    self:SetSprite(self:GetComp("BottomPanel/ShopBtn/chest/icon", "Image"), "UI_Shop", icon)
end

--[[
    @desc: 刷新显示下班打开入口按钮相关内容
    author:{author}
    time:2025-03-28 10:51:18
    @return:
]]
function MainUIView:RefreshClockOutActivity()
    local btnGo = self:GetGo("PackPanel/ClockOutBtn")
    if not GameTableDefine.ClockOutDataManager:ClockOutEnable() then
        btnGo:SetActive(false)
        return
    end

    if GameTableDefine.ClockOutDataManager:GetActivityIsOpen() then
        btnGo:SetActive(true)
        if self.clockOutTimer then
            GameTimer:StopTimer(self.clockOutTimer)
            self.clockOutTimer = nil
        end
        self.clockOutTimer = GameTimer:CreateNewTimer(1, function()
            local leftTime  = GameTableDefine.ClockOutDataManager:GetActivityLeftTime()
            if leftTime <= 0 then
                GameTimer:StopTimer(self.clockOutTimer)
                self.clockOutTimer = nil
                self:RefreshClockOutActivity()
            else
                local timeStr = GameTimeManager:FormatTimeLength(leftTime)
                self:SetText("PackPanel/ClockOutBtn/activityTime/time", timeStr)
                local isCanClaim = GameTableDefine.ClockOutDataManager:GetHaveCanClaimReward() > 0 or GameTableDefine.ClockOutDataManager:CheckHaveTicketLevelUp()
                self:GetGo("PackPanel/ClockOutBtn/tip"):SetActive(isCanClaim)
                local leftTickets = GameTableDefine.ClockOutDataManager:GetLeftTickets()
                if GameTableDefine.ClockOutDataManager:GetConfigTotalTickets() == 0 then
                    self:SetText("PackPanel/ClockOutBtn/activityTicket/num", "---")
                else
                    self:SetText("PackPanel/ClockOutBtn/activityTicket/num", tostring(leftTickets))
                end
                
            end
            
        end, true, true)
        --设置主题图标
        local iconEntryString = "btn_clockout_entry_"..GameTableDefine.ClockOutDataManager:GetActivityTheme()
        local iconTicketString = "icon_clockout_ticket_"..GameTableDefine.ClockOutDataManager:GetActivityTheme()
        self:SetSprite(self:GetComp("PackPanel/ClockOutBtn/activityIcon", "Image"), "UI_Shop", iconEntryString)
        self:SetSprite(self:GetComp("PackPanel/ClockOutBtn/activityTicket/icon", "Image"), "UI_Shop", iconTicketString)
    else
        if self.clockOutTimer then
            GameTimer:StopTimer(self.clockOutTimer)
            self.clockOutTimer = nil
        end
        if btnGo then
            btnGo:SetActive(false)
        end
    end

    GameTableDefine.UIPopupManager:EnqueuePopView(GameTableDefine.ClockOutPopupUI, function()
        GameTableDefine.ClockOutPopupUI:OpenView()
    end, "FirstPurchaseUI")
end
return MainUIView