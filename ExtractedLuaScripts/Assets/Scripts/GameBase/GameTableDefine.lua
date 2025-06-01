print("==========load Game Data Table==============")

--单例空表--

GameTableDefine = {
    --定义的内容用于ABtest的版本控制key
    --注意这个key是每次发包的时候策划都要明确该次包是否开启ABTest，以及开启的Key
    --因为这个值会用来给玩家进行分组以及读取不同的AB配置使用
    --2023-12-1约定
    OldABTest_Key = "instance",
    CurABTest_Key = "RemoteConfig",
    --开启ABtest时，上传埋点用户属性的Key值
    ABTest_UserKey = "AB_test_inner",
    ---@type ConfigMgr
    ConfigMgr = {},

    GameStateCity = {},
    GameStateFloor = {},

    ---@type LoadingScreen
    LoadingScreen = {},

    ---@type SoundEngine
    SoundEngine = {},

    ---@type GameUIManager
    GameUIManager = {},
    CommonUtils = {},

    Resource = {},
    ---@type CityMode
    CityMode = {},
    ---@type FloorMode
    FloorMode = {},
    ---@type CompanyMode
    CompanyMode = {},
    ---@type StarMode
    StarMode = {},
    BuildingPop = {},
    CashEarn = {},
    SceneUnlockUI = {},
    --AZhenMessage = {},
    ---@type GreateBuildingMana
    GreateBuildingMana = {},

    HUD = {},
    UIDemo = {},
    RoomBuildingUI = {},
    ---@type MainUI
    MainUI = {},
    CompanysUI = {},
    ---@type ResourceManger
    ResourceManger = {},
    DiamondRewardUI = {},
    DiamondShopUI = {},
    TicketUseUI = {}, 
    ---@type OfflineRewardUI
    OfflineRewardUI = {},
    TipsUI = {},
    ActorEventManger = {},
    ChatEventManager = {},
    Event001UI = {},
    Event004UI = {},
    Event003UI = {},
    Event005UI = {},
    Event006UI = {},
    QuestManager = {},
    QuestUI = {},
    ContractUI = {},
    --StarUI = {},
    RoomUnlockUI = {},
    UnlockingSkipUI = {},
    ---@type FloatUI
    FloatUI = {},
    ---@type FlyIconsUI
    FlyIconsUI = {},
    ---@type GuideManager
    GuideManager = {},
    GuideUI = {},
    SettingUI = {},
    DoubleRewardUI = {},
    ---@type GameClockManager
    GameClockManager = {},
    ---@type LightManager
    LightManager = {},
    ChooseUI = {},
    GiftUI = {},
    CutScreenUI = {},
    CompanyLvUpUI = {},
    RewardUI = {},
    ChatEventUI = {},
    SceneChatInfoUI = {},
    ConformUI = {},
    
    MeetingEventManager = {},
    EventMeetingUI = {},
    CollectionUI = {},
    CompanyMapInfoUI = {},
    RenewUI         = {},
    CloudStorageUI = {},

    ---@type BuyCarManager
    BuyCarManager = {},
    BuyHouseManager = {},
    ValueManager = {},
    PayBackManager = {},
    PhoneUI = {},
    ChatUI = {},
    BankUI = {},
    ChatInfoUI = {},
    ChatInfoUI2 = {},
    BuyCarUI = {},
    BuyCarInfoUI = {},
    BuyHouseUI = {},
    BuyHouseInfoUI = {},
    RankListUI = {},
	ForbesRewardUI = {},
    
    RateUI = {},
    CityMapUI = {},
    BossTalkUI = {},
    BossChooseUI = {},
    BenameUI = {},

    TalkUI = {},
    ---@type HouseMode
    HouseMode = {},
    HouseContractUI = {},
    ShopUI = {},
    RouletteUI = {},
    ---@type IntroduceUI
    IntroduceUI = {},
    ---@type Shop
    Shop = {},
    ---@type ShopManager
    ShopManager = {},
    ShopAfterPerson = {},
    GameCenterUI = {},
    ---@type PetMode
    PetMode = {},
    ---@type WarriorIAP
    IAP = {},
    ---@type PurchaseSuccessUI
    PurchaseSuccessUI = {},
    ---@type DiamondFundUI
    DiamondFundUI = {},
    AdFreeUI = {},
    ---@type FactoryMode
    FactoryMode = {},
    WorkShopUnlockUI = {},
    ---@type WorkShopInfoUI
    WorkShopInfoUI = {},
    OrderUI = {},
    StockFullUI = {},
    OrderFinishUI = {},
    ---@type PiggyBankUI
    PiggyBankUI = {},
    ---@type PetListUI
    PetListUI = {},
    PetInteractUI = {},
    ActivityUI = {},
    WorkshopItemUI ={},
	ActivityRankUI = {},
    ActivityRankDataManager = {},
	ActivityRankRewardGetUI = {},
    ---@type CountryMode
	CountryMode = {},
    EuropeMapUI = {},
    WorldListUI = {},    
    ExchangeUI = {},    
    ActivityFileDataManager = {},
    FragmentActivityUI = {},
    ---@type TimeLimitedActivitiesManager
    TimeLimitedActivitiesManager = {},
    BoardUI = {},
    ---@type CheatUI
    CheatUI = {},
    ---@type PersonInteractUI
    PersonInteractUI = {},
    ---@type DressUpDataManager
    DressUpDataManager = {},
    ---@type LimitPackUI
    LimitPackUI = {},
    ---@type LimitChooseUI
    LimitChooseUI = {},
    ---@type ActivityRemoteConfigManager
    ActivityRemoteConfigManager = {},
    ---@type AccumulatedChargeActivityDataManager
    AccumulatedChargeActivityDataManager = {},
    ---@type AccumulatedChargeACUI
    AccumulatedChargeACUI = {},
    QuestionSurveyDataManager = {},
    QuestionSurveyUI = {},
    ---@type MonthCardUI
    MonthCardUI = {},
    ---@type CommonRewardUI
    CommonRewardUI = {},

    ---@type QuestionSurveyNewUI
    QuestionSurveyNewUI = {},
    
    ---@type FootballClubModel
    FootballClubModel = {},   
    FootballClubScene = {}, 
    FootballClubController = {}, 
    FCStadiumUI = {},
    FCPopupUI = {},
    FCClubCenterUI = {},
    FCHealthCenterUI = {},
    FCTacticalCenterUI = {},
    FCTrainingGroundUI = {},
    FCRoomUnlockUI = {},

    FCLeagueRankUI = {},
    FCLevelupUI = {},
    
    FootballClubLeagueRankDataManager = {},
    FCSettlementUI = {},
    FCTrainningRewardUI = {},
    FCLeagueUpUI = {},
    GameStateInstance = {},
    ---@type InstanceDataManager
    InstanceDataManager = {},
    ---@type InstanceModel
    InstanceModel = {},
    InstanceViewUI = {},
    ---@type InstanceMainViewUI
    InstanceMainViewUI = {},
    InstanceTimeUI = {},
    ---@type InstanceRewardUI
    InstanceRewardUI = {},
    InstanceMilepostUI = {},
    InstanceBuildingUI = {},
    InstanceUnlockUI = {},
    InstanceShopUI = {},
    InstanceProcessUI = {},
    InstanceOfflineRewardUI = {},
    InstancePopUI = {},
    ---@type InstanceFlyIconManager
    InstanceFlyIconManager = {},
    ---@type InstanceTaskManager
    InstanceTaskManager = {},
    FAQUI = {},
    ---@type BuyCarShopUI
    BuyCarShopUI = {},
    ---@type ShopInstantUI
    ShopInstantUI = {},
    InstanceAdUI = {},
    PersonalDevModel = {},
    PersonalInfoUI = {},
    PersonalAffairUI = {},
    PersonalPromoteUI = {},
    PersonalPromoteResultUI = {},

    UIRedirect = {},

    PersonalLvlUpUI = {},

    --AI
    ---@type ActorManager
    ActorManager = {},
    InstanceAIBlackBoard = {},
    ---@type SpicalRoomManager
    SpicalRoomManager = {},

    InstanceRewardUI2 = {},
    InstanceRewardUI3 = {},
    ---@type PowerManager
    PowerManager = {},
    ---@type OfflineManager
    OfflineManager= {},
    ---@type UIPopupManager
    UIPopupManager = {},

    ---@type StoryLineUI
    StoryLineUI = {},
    ---@type StoryLineManager
    StoryLineManager = {},
    ---@type ElevatorManager
    ElevatorManager = {},
    ---@type FirstPurchaseUI
    FirstPurchaseUI = {},
    ---@type SeasonPassUI
    SeasonPassUI = {},
    ---@type SeasonPassManager
    SeasonPassManager = {},
    ---@type SeasonPassPopupUI
    SeasonPassPopupUI = {},
    
    ---@type CycleInstanceDataManager
    CycleInstanceDataManager = {},
    GameStateCycleInstance = {},
    ---@type SlotMachineUI
    SlotMachineUI = {},
    CycleInstanceSkillUI = {},
    ---@type CycleIslandHeroManager
    CycleIslandHeroManager = {},
    ---@type CycleIslandHeroUpgradeUI
    CycleIslandHeroUpgradeUI = {},
    ---@type CycleIslandTaskManager
    CycleIslandTaskManager = {},
    ---@type CycleIslandTaskUI
    CycleIslandTaskUI = {},
    ---@type CycleIslandMainViewUI
    CycleIslandMainViewUI = {},
    ---@type CycleIslandTimeUI
    CycleIslandTimeUI = {},
    ---@type CycleInstancePopUI
    CycleInstancePopUI = {},
    --新副本商店
    CycleInstanceShopUI = {},
    --新副本里程碑查看界面
    CycleInstanceMilepostUI = {}, 
    ---@type CycleIslandViewUI
    CycleIslandViewUI = {},
    ---@type CycleIslandBuildingUI
    CycleIslandBuildingUI = {},
    ---@type CycleIslandSellUI
    CycleIslandSellUI = {},
    --新副本里程碑领奖界面
    CycleInstanceRewardUI = {},
    ---@type CycleInstanceAIBlackBoard
    CycleInstanceAIBlackBoard = {},
    ---@type CycleIslandUnlockUI
    CycleIslandUnlockUI = {},
    ---@type CycleIslandOfflineRewardUI
    CycleIslandOfflineRewardUI = {}, 
    CycleInstanceAdUI = {},
    ADChooseUI = {},

    ---@type CycleCastleModel
    CycleCastleModel = {},
    GameStateCycleCastle = {},
    ---@type CycleCastleSlotMachineUI
    CycleCastleSlotMachineUI = {},
    CycleCastleSkillUI = {},
    ---@type CycleCastleHeroManager
    CycleCastleHeroManager = {},
    ---@type CycleCastleHeroUpgradeUI
    CycleCastleHeroUpgradeUI = {},
    ---@type CycleCastleTaskManager
    CycleCastleTaskManager = {},
    ---@type CycleCastleTaskUI
    CycleCastleTaskUI = {},
    ---@type CycleCastleMainViewUI
    CycleCastleMainViewUI = {},
    ---@type CycleCastlePopUI
    CycleCastlePopUI = {},
    --新副本商店
    CycleCastleShopUI = {},
    --新副本里程碑查看界面
    ---@type CycleCastleMilepostUI
    CycleCastleMilepostUI = {},
    ---@type CycleCastleViewUI
    CycleCastleViewUI = {},
    ---@type CycleCastleBuildingUI
    CycleCastleBuildingUI = {},
    ---@type CycleCastleSellUI
    CycleCastleSellUI = {},
    --新副本里程碑领奖界面
    ---@type CycleCastleRewardUI
    CycleCastleRewardUI = {},
    ---@type CycleCastleUnlockUI
    CycleCastleUnlockUI = {},
    ---@type CycleCastleOfflineRewardUI
    CycleCastleOfflineRewardUI = {},
    CycleCastleAdUI = {},
    ---@type CycleCastleCutScreenUI
    CycleCastleCutScreenUI = {},
    ---@type CycleCastleAIBlackBoard
    CycleCastleAIBlackBoard = {},
    
    ---@type CycleToyModel
    CycleToyModel = {},
    GameStateCycleToy = {},
    ---@type CycleToySlotMachineUI
    CycleToySlotMachineUI = {},
    CycleToySkillUI = {},
    ---@type CycleToyHeroManager
    CycleToyHeroManager = {},
    ---@type CycleToyHeroUpgradeUI
    CycleToyHeroUpgradeUI = {},
    ---@type CycleToyTaskManager
    CycleToyTaskManager = {},
    ---@type CycleToyTaskUI
    CycleToyTaskUI = {},
    ---@type CycleToyMainViewUI
    CycleToyMainViewUI = {},
    ---@type CycleToyPopUI
    CycleToyPopUI = {},
    --新副本商店
    CycleToyShopUI = {},
    --新副本里程碑查看界面
    ---@type CycleToyMilepostUI
    CycleToyMilepostUI = {},
    ---@type CycleToyViewUI
    CycleToyViewUI = {},
    ---@type CycleToyBuildingUI
    CycleToyBuildingUI = {},
    ---@type CycleToySellUI
    CycleToySellUI = {},
    --新副本里程碑领奖界面
    ---@type CycleToyRewardUI
    CycleToyRewardUI = {},
    ---@type CycleToyUnlockUI
    CycleToyUnlockUI = {},
    ---@type CycleToyOfflineRewardUI
    CycleToyOfflineRewardUI = {},
    CycleToyAdUI = {},
    ---@type CycleToyCutScreenUI
    CycleToyCutScreenUI = {},
    ---@type CycleToyAIBlackBoard
    CycleToyAIBlackBoard = {},
    ---@type CycleToyBlueprintUI
    CycleToyBlueprintUI = {},
    ---@type CycleToyBluePrintManager
    CycleToyBluePrintManager = {},


    ---@type CycleNightClubModel
    CycleNightClubModel = {},
    GameStateCycleNightClub = {},
    ---@type CycleNightClubSlotMachineUI
    CycleNightClubSlotMachineUI = {},
    CycleNightClubSkillUI = {},
    ---@type CycleNightClubHeroManager
    CycleNightClubHeroManager = {},
    ---@type CycleNightClubHeroUpgradeUI
    CycleNightClubHeroUpgradeUI = {},
    ---@type CycleNightClubTaskManager
    CycleNightClubTaskManager = {},
    ---@type CycleNightClubTaskUI
    CycleNightClubTaskUI = {},
    ---@type CycleNightClubMainViewUI
    CycleNightClubMainViewUI = {},
    ---@type CycleNightClubPopUI
    CycleNightClubPopUI = {},
    --新副本商店
    CycleNightClubShopUI = {},
    --新副本里程碑查看界面
    ---@type CycleNightClubMilepostUI
    CycleNightClubMilepostUI = {},
    ---@type CycleNightClubViewUI
    CycleNightClubViewUI = {},
    ---@type CycleNightClubBuildingUI
    CycleNightClubBuildingUI = {},
    ---@type CycleNightClubSellUI
    CycleNightClubSellUI = {},
    --新副本里程碑领奖界面
    ---@type CycleNightClubRewardUI
    CycleNightClubRewardUI = {},
    ---@type CycleNightClubUnlockUI
    CycleNightClubUnlockUI = {},
    ---@type CycleNightClubOfflineRewardUI
    CycleNightClubOfflineRewardUI = {},
    CycleNightClubAdUI = {},
    ---@type CycleNightClubCutScreenUI
    CycleNightClubCutScreenUI = {},
    CycleNightClubAIBlackBoard = {},
    ---@type CycleNightClubBlueprintUI
    CycleNightClubBlueprintUI = {},
    ---@type CycleNightClubBluePrintManager
    CycleNightClubBluePrintManager = {},

    SupplementOrderUI = {},

    ---@type StatisticUI
    StatisticUI = {},

    ---@type CycleCastleRankUI
    CycleCastleRankUI = {},

    ---@type CycleCastleRankManager
    CycleCastleRankManager = {},

    ---@type CycleCastleRankRewardUI
    CycleCastleRankRewardUI = {},

    ---@type DeeplinkManager
    DeeplinkManager = {},

    ---@type CoinPusherManager
    CoinPusherManager = {},

    ---@type FruitMachineManager
    FruitMachineManager = {},

    SeasonPassTaskManager = {},
    ---@type SeasonPassPackUI
    SeasonPassPackUI = {},


    ---@type CycleNightClubModel
    CycleNightClubModel = {},
    GameStateCycleNightClub = {},
    ---@type CycleNightClubSlotMachineUI
    CycleNightClubSlotMachineUI = {},
    CycleNightClubSkillUI = {},
    ---@type CycleNightClubHeroManager
    CycleNightClubHeroManager = {},
    ---@type CycleNightClubHeroUpgradeUI
    CycleNightClubHeroUpgradeUI = {},
    ---@type CycleNightClubTaskManager
    CycleNightClubTaskManager = {},
    ---@type CycleNightClubTaskUI
    CycleNightClubTaskUI = {},
    ---@type CycleNightClubMainViewUI
    CycleNightClubMainViewUI = {},
    ---@type CycleNightClubPopUI
    CycleNightClubPopUI = {},
    --新副本商店
    CycleNightClubShopUI = {},
    --新副本里程碑查看界面
    ---@type CycleNightClubMilepostUI
    CycleNightClubMilepostUI = {},
    ---@type CycleNightClubViewUI
    CycleNightClubViewUI = {},
    ---@type CycleNightClubBuildingUI
    CycleNightClubBuildingUI = {},
    ---@type CycleNightClubSellUI
    CycleNightClubSellUI = {},
    --新副本里程碑领奖界面
    ---@type CycleNightClubRewardUI
    CycleNightClubRewardUI = {},
    ---@type CycleNightClubUnlockUI
    CycleNightClubUnlockUI = {},
    ---@type CycleNightClubOfflineRewardUI
    CycleNightClubOfflineRewardUI = {},
    CycleNightClubAdUI = {},
    ---@type CycleNightClubCutScreenUI
    CycleNightClubCutScreenUI = {},
    ---@type CycleNightClubAIBlackBoard
    CycleNightClubAIBlackBoard = {},
    ---@type CycleNightClubBlueprintUI
    CycleNightClubBlueprintUI = {},
    ---@type CycleNightClubBluePrintManager
    CycleNightClubBluePrintManager = {},

    ---@type CycleNightClubRankUI
    CycleNightClubRankUI = {},

    ---@type CycleNightClubRankManager
    CycleNightClubRankManager = {},

    ---@type CycleNightClubRankRewardUI
    CycleNightClubRankRewardUI = {},

    ---@type CycleNightClubPiggyBankUI
    CycleNightClubPiggyBankUI = {},

    ---@type CycleNightClubPiggyBankUIView
    CycleNightClubPiggyBankUIView = {},
    SeasonPassPackUI = {},

    ---@type CEOHiringUI
    CEOHiringUI = {},
    ---@type CEODeskUI
    CEODeskUI = {},
    ---@type CEOHiredUI
    CEOHiredUI = {},
    ---@type CEODataManager
    CEODataManager = {},

    ---@type CEOBoxPurchaseUI
    CEOBoxPurchaseUI = {},

    ---@type CEOChestPreviewUI
    CEOChestPreviewUI = {},
    ---@type CeoExcessConvertUI
    CeoExcessConvertUI = {},

    ---@type ClockOutDataManager
    ClockOutDataManager = {},

    ---@type ClockOutUI
    ClockOutUI = {},

    ---@type ClockOutPopupUI
    ClockOutPopupUI = {},
}