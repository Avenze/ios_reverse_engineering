---@class GameUIManager
local GameUIManager = GameTableDefine.GameUIManager
local UIView = require("Framework.UI.View")
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local Object = CS.UnityEngine.Object
local GameObject = CS.UnityEngine.GameObject
local ResMgr = CS.Common.Utils.ResManager.Instance
local UnityHelper = CS.Common.Utils.UnityHelper

local EventTriggerListener = CS.Common.Utils.EventTriggerListener
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local UIFollow = CS.UnityEngine.UI.UIFollow
local Color = CS.UnityEngine.Color
local EmptyRaycast = CS.UnityEngine.UI.EmptyRaycast
local Button = CS.UnityEngine.UI.Button
local Application = CS.UnityEngine.Application
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local ENUM_VIEW_STATUS = UIView.ENUM_STATUS

ENUM_GAME_UITYPE = {
    LAUNCH = 0,

    HUD = 1,

    FLOAT_UI = 2,
    BUILDING_POP = 3,

    UI_DEMO = 1000,
    CITY_MAP = 4,

    ROOM_BUILDING_UI = 5, --房间点开的UI

    MAIN_UI = 6,

    COMPANYS_UI = 7,

    DIAMOND_REWARD_UI = 8,
    DIAMOND_SHOP_UI = 9,
    TICKET_USE_UI = 10,

    ROOM_FLOAT_UI = 11,

    OFFLINE_REWARD_UI = 13,

    TIPS_UI = 14,

    EVENT001_UI = 15,

    QUEST_UI = 16,
    CONTRACT_UI = 17,
    ROOM_UNLOCK_UI = 19,
    UNLOCKING_SKIP_UI = 20,
    FLY_ICONS_UI = 21,
    GUIDE_UI = 22,
    SETTING_UI = 23,
    DOUBLE_REWARD_UI = 24,
    CHOOSE_UI = 25,
    GIFT_UI = 26,
    CUT_SCREEN_UI = 27,
    COMPANY_LVUP_UI = 28,
    COLLECTION_UI = 29,
    COMPANY_MAP_INFO_UI = 30,
    EVENT_MEETING_UI = 31,
    EVENT003_UI = 32,
    RENEW_UI = 33,
    EVENT004_UI = 34,
    CLOUD_STORAGE = 35,

    PHONE_UI = 36,
    APP_CHAT_UI = 37,
    APP_CHAT_INFO_UI = 38,
    APP_CAR_UI = 39,
    APP_CAR_INFO_UI = 40,
    APP_RANK_UI = 43,
    RATE_UI = 44,

    REWARD_UI = 45,

    BOSS_CHOOSE_UI = 46,
    BOSS_TALK_UI = 47,
    BENAME_UI = 48,

    CHAT_EVENT_UI = 49,
    SCENE_CHAT_INFO_UI = 50,

    APP_CHAT_INFO_UI2 = 51,

    TALK_UI = 52,

    HOUSE_CONTRACT_UI = 53,
    EVENT005_UI = 54,

    SHOP_UI = 55,
    BANK_UI = 56,

    FORBES_UI = 57,

    EVENT006_UI = 58,

    ROULETTE_UI = 59,

    INTRODUCE_UI = 60,

    GAME_CENTER_UI = 61,

    PURCHASESUCCESS_UI = 62,

    DIAMONDFUNDUIVIEW_UI = 63,

    AD_FREE_UI = 64,

    WORK_SHOP_UNLOCK_UI = 65,

    WORK_SHOP_INFO_UI = 66,

    CONFORM_UI = 67,

    ORDER_UI = 68,

    ORDER_FINISH_UI = 69,

    STOCK_FULL_UI = 70,

    PIGGY_BANK_UI = 71,

    PET_LIST_UI = 72,

    PET_INTERACT_UI = 73,

    ACTIVITY_UI = 74,

    WORKSHOP_ITEM_UI = 75,

    ACTIVITY_RANK_UI = 76, --新增活动排行UI，用于阶段性临时活动排行的统一UI2022-9-30

    ACTIVITY_RANK_REWARD_GET_UI = 77, -- 新增活动排行奖励领取面板，用于活动排行的奖励领取 2020-10-13

    EUROPE_MAP_UI = 78,

    WORLD_LIST_UI = 79,

    EXCHANGE_UI = 80,

    FRAGMENT_ACTIVITY_UI = 81,

    BOARD_UI = 82,

    CHEAT_UI = 83,

    PERSON_INTERACT_UI = 84,

    LIMIT_PACK_UI = 85,

    ACCUMULATED_CHARGE_UI = 86,

    FC_LENAGUE_RANK_UI = 87,

    FOOTBALL_CLUB_LEAGUE_RANK_DATA_MANAGER = 88,

    FC_LEVEL_UP_UI = 89,

    FC_MANAGER_INFO_UI = 90,

    FC_STADIUM_UI = 91,

    FC_SETLEMENT_UI = 92,

    FC_SETTLEMENT_UI = 93,

    FC_CLUB_CENTER_UI = 95,

    FC_HEALTH_CENTER_UI = 96,

    FC_TACTICAL_CENTER_UI = 97,

    FC_TRAINING_GROUND_UI = 98,

    FC_ROOM_UNLOCK_UI = 99,

    FC_TRAINING_REWARD_UI = 100,

    FC_LEAGUE_UP_UI = 101,
    INSTANCE_VIEW_UI = 102,

    INSTANCE_MAIN_VIEW_UI = 103,

    INSTANCE_TIME_UI = 104,

    INSTANCE_REWARD_UI = 105,

    INSTANCE_MILEPOST_UI = 106,

    INSTANCE_UNLOCK_UI = 107,

    INSTANCE_BUILDING_UI = 108,

    INSTANCE_SHOP_UI = 109,

    INSRANCE_PROCESS_UI = 110,

    INSTANCE_OFFLINE_REWARD_UI = 111,

    INSTANCE_POP_UI = 112,

    QUESTION_SURVEY = 113,

    FAQ_UI = 114,

    SHOP_INSTANT_UI = 115, --快捷支付UI

    INSTANCE_AD_UI = 116,
    PERSONAL_INFO_UI = 117, --个人发展个人信息UI
    PERSONAL_AFFAIR_UI = 118, --个人发展事务处理界面
    PERSONAL_PROMOTE_UI = 119, --个人发展竞选界面
    PERSONAL_PROMOTE_RESULT_UI = 120, --个人发展竞选结果界面
    PERSONAL_LVLUP_UI = 121, --个人发展竞选升级界面

    INSTANCE_REWARD_UI_2 = 122,
    INSTANCE_REWARD_UI_3 = 123,
    CAR_SHOP_UI = 124, --汽车商店

    Story_Line_UI = 130, --主线故事

    SUPPLEMENT_ORDER_UI = 131, --用于初始化订单
    ---月卡
    MONTH_CARD_UI = 132,
    ---首冲重置界面,首冲双倍钻石(不是首次IAP)
    FIRST_PURCHASE_UI = 133,

    --名片系统UI
    STATISTIC_UI = 134,
    ---限时多选一礼包
    LIMIT_CHOOSE_UI = 135,
    ---新的通用领奖界面
    COMMON_REWARD_UI = 136,
    ---通行证界面
    SEASON_PASS_UI = 137,
    ---通行证弹窗界面
    SEASON_PASS_POPUP_UI = 138,
    ---通行证礼包
    SEASON_PASS_PACK_UI = 139,

    ---CEO总览
    CEO_HIRING_UI = 140,
    ---CEO指派成功
    CEO_HIRED_UI = 141,
    ---CEO办公桌
    CEO_DESK_UI = 142,

    --CEO宝箱开启的UI
    CEO_PURCHASE_UI = 143,

    --CEO宝箱概率展示界面
    CEO_CHEST_PREVIEW_UI = 144, 

    --ClockOut下班打开活动UI
    CLOCK_OUT_UI = 145,

    --ClockOut下班打开活动的弹窗界面
    CLOCK_OUT_POPUP_UI = 146,

    INSTANCE_SLOT_MACHINE = 201, --拉霸机
    CYCLE_ISLAND_HERO_UPGRADE_UI = 202, --英雄升级界面
    CYCLE_INSTANCE_SKILL_UI = 203, --新副本技能UI
    CYCLE_ISLAND_TASK_UI = 204, --新复活节副本任务界面
    CYCLE_ISLAND_MAIN_VIEW_UI = 205, --新复活节主界面
    CYCLE_ISLAND_TIME_UI = 206, --副本日程界面
    CYCLE_INSTANCE_SHOP_UI = 207, --新副本的商店UI
    CYCLE_INSTANCE_MILEPOST_UI = 208, --新副本的里程碑界面
    CYCLE_ISLAND_VIEW_UI = 209, --循环副本入口界面
    CYCLE_ISLAND_BUILDING_UI = 210, --循环副本建筑界面
    CYCLE_INSTANCE_REWARD_UI = 212, --新副本的里程碑领奖界面
    CYCLE_ISLAND_SELL_UI = 211, --循环副本建筑界面
    CYCLE_INSTANCE_POP_UI = 213, --循环弹窗礼包
    CYCLE_ISLAND_UNLOCK_UI = 214, --循环建筑解锁界面
    CYCLE_ISLAND_OFFLINE_REWARD_UI = 215, --离线奖励界面
    CYCLE_INSTANCE_AD_UI = 216, --新副本的广告奖励面板
    AD_TICKET_CHOOSE_UI = 217, --广告卷使用的选择界面

    CYCLE_CASTLE_SLOT_MACHINE = 218, --拉霸机
    CYCLE_CASTLE_HERO_UPGRADE_UI = 219, --英雄升级界面
    CYCLE_CASTLE_SKILL_UI = 220, --新副本技能UI
    CYCLE_CASTLE_TASK_UI = 221, --新复活节副本任务界面
    CYCLE_CASTLE_MAIN_VIEW_UI = 222, --新复活节主界面
    CYCLE_CASTLE_TIME_UI = 223, --副本日程界面
    CYCLE_CASTLE_SHOP_UI = 224, --新副本的商店UI
    CYCLE_CASTLE_MILEPOST_UI = 225, --新副本的里程碑界面
    CYCLE_CASTLE_VIEW_UI = 226, --循环副本入口界面
    CYCLE_CASTLE_BUILDING_UI = 227, --循环副本建筑界面
    CYCLE_CASTLE_REWARD_UI = 228, --新副本的里程碑领奖界面
    CYCLE_CASTLE_SELL_UI = 229, --循环副本建筑界面
    CYCLE_CASTLE_POP_UI = 230, --循环弹窗礼包
    CYCLE_CASTLE_UNLOCK_UI = 231, --循环建筑解锁界面
    CYCLE_CASTLE_OFFLINE_REWARD_UI = 232, --离线奖励界面
    CYCLE_CASTLE_AD_UI = 233, --新副本的广告奖励面板
    CYCLE_CASTLE_CUT_SCREEN_UI = 234,    ---城堡副本转场

    QUESTION_SURVEY_NEW = 235, -- 新问卷界面

    CYCLE_TOY_SLOT_MACHINE = 236, --拉霸机
    CYCLE_TOY_HERO_UPGRADE_UI = 237, --英雄升级界面
    CYCLE_TOY_SKILL_UI = 238, --新副本技能UI
    CYCLE_TOY_TASK_UI = 239, --新复活节副本任务界面
    CYCLE_TOY_MAIN_VIEW_UI = 240, --新复活节主界面
    CYCLE_TOY_TIME_UI = 241, --副本日程界面
    CYCLE_TOY_SHOP_UI = 242, --新副本的商店UI
    CYCLE_TOY_MILEPOST_UI = 243, --新副本的里程碑界面
    CYCLE_TOY_VIEW_UI = 244, --循环副本入口界面
    CYCLE_TOY_BUILDING_UI = 245, --循环副本建筑界面
    CYCLE_TOY_REWARD_UI = 246, --新副本的里程碑领奖界面
    CYCLE_TOY_SELL_UI = 247, --循环副本货架界面
    CYCLE_TOY_POP_UI = 248, --循环弹窗礼包
    CYCLE_TOY_UNLOCK_UI = 249, --循环建筑解锁界面
    CYCLE_TOY_OFFLINE_REWARD_UI = 250, --离线奖励界面
    CYCLE_TOY_AD_UI = 251, --新副本的广告奖励面板
    CYCLE_TOY_CUT_SCREEN_UI = 252,    ---城堡副本转场
    CYCLE_TOY_BLUE_PRINT_UI = 253,--玩具副本蓝图

    CYCLE_CASTLE_RANK_UI = 254, -- 城堡副本排行榜界面
    CYCLE_CASTLE_RANK_REAWARD_UI = 255, -- 城堡副本排行榜奖励，弹出宝箱

    CYCLE_NIGHT_CLUB_SLOT_MACHINE = 256, --拉霸机
    CYCLE_NIGHT_CLUB_HERO_UPGRADE_UI = 257, --英雄升级界面
    CYCLE_NIGHT_CLUB_SKILL_UI = 258, --新副本技能UI
    CYCLE_NIGHT_CLUB_TASK_UI = 259, --新复活节副本任务界面
    CYCLE_NIGHT_CLUB_MAIN_VIEW_UI = 260, --新复活节主界面
    CYCLE_NIGHT_CLUB_TIME_UI = 261, --副本日程界面
    CYCLE_NIGHT_CLUB_SHOP_UI = 262, --新副本的商店UI
    CYCLE_NIGHT_CLUB_MILEPOST_UI = 263, --新副本的里程碑界面
    CYCLE_NIGHT_CLUB_VIEW_UI = 264, --循环副本入口界面
    CYCLE_NIGHT_CLUB_BUILDING_UI = 265, --循环副本建筑界面
    CYCLE_NIGHT_CLUB_REWARD_UI = 266, --新副本的里程碑领奖界面
    CYCLE_NIGHT_CLUB_SELL_UI = 267, --循环副本货架界面
    CYCLE_NIGHT_CLUB_POP_UI = 268, --循环弹窗礼包
    CYCLE_NIGHT_CLUB_UNLOCK_UI = 269, --循环建筑解锁界面
    CYCLE_NIGHT_CLUB_OFFLINE_REWARD_UI = 270, --离线奖励界面
    CYCLE_NIGHT_CLUB_AD_UI = 271, --新副本的广告奖励面板
    CYCLE_NIGHT_CLUB_CUT_SCREEN_UI = 272,    ---城堡副本转场
    CYCLE_NIGHT_CLUB_BLUE_PRINT_UI = 273,--玩具副本蓝图


    CYCLE_NIGHT_CLUB_RANK_UI = 274, -- 夜店副本排行榜界面
    CYCLE_NIGHT_CLUB_RANK_REAWARD_UI = 275, -- 夜店副本排行榜奖励，弹出宝箱
    CYCLE_NIGHT_CLUB_PIGGY_BANK_UI = 276, -- 夜店副本小猪



    CEO_EXCESS_CONVERT_UI = 277,
}

ENUM_GAME_UISTYLE =
{
    -- open ui
    ---Normal不影响场景摄像机的刷新,是叠加在场景摄像机上的
    NORMAL          = 0,
    ---Big影响显示UI界面后，是否截取静态场景图片做UI背景
    BIG             = 1,
    ---Full当前与Big类似,基本一样
    FULL            = 2,

    -- open float ui
    SOLE            = 11,
    MULTI           = 12,
}

-- 响应设备返回按键
local BACK_CLOSE_LAYER = 0-- 默认关闭当前界面
local BACK_SHOW_QUIT_POP = 1-- 检查到这一层，直接弹退出提示
local BACK_SKIP_TO_NEXT_LAYER = 2-- 不处理，判断下一层，比如TopAnim
local BACK_RETURN = 3-- 不响应，直接返回，比如Loading,引导
local BACK_CHECK_VIEW = 4-- 根据实际情况检测，直接返回，比如GuideView,要看能部分能点穿
local BACK_INSTANCE_MAIN = 5-- 从副本主界面退出

local UIConfig =
{
    [ENUM_GAME_UITYPE.LAUNCH]                   = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.Launch.View",                         res = "Assets/Resources/Splash/SplashLoading.prefab",       backType = BACK_RETURN}, -- isMultilingual = true

    [ENUM_GAME_UITYPE.HUD]                      = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.Floors.UI.HUDView",                   res = "Assets/Res/UI/FloorHUD.prefab"},

    [ENUM_GAME_UITYPE.FLOAT_UI]                 = {style = ENUM_GAME_UISTYLE.MULTI,         class = "GamePlay.Common.UI.FloatUIViewNew",               res = "Assets/Res/UI/FloatUI.prefab"},
    [ENUM_GAME_UITYPE.BUILDING_POP]             = {style = ENUM_GAME_UISTYLE.SOLE,          class = "GamePlay.Buildings.BuildingPopView",           res = "Assets/Res/UI/BuildingPop.prefab"},

    [ENUM_GAME_UITYPE.UI_DEMO]                  = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.City.UI.UIDemoView",                  res = "Assets/Res/UI/UIDemo.prefab"},
    [ENUM_GAME_UITYPE.CITY_MAP]                  = {style = ENUM_GAME_UISTYLE.FULL,        class = "GamePlay.City.UI.CityMapUIView",                  res = "Assets/Res/UI/CityMapUI.prefab"},

    [ENUM_GAME_UITYPE.ROOM_BUILDING_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.Floors.UI.RoomBuildUIView",            res = "Assets/Res/UI/RoomBuildUI.prefab"},

    [ENUM_GAME_UITYPE.MAIN_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.Common.UI.MainUIView",                res = "Assets/Res/UI/MainViewUI.prefab", backType = BACK_SHOW_QUIT_POP},

    [ENUM_GAME_UITYPE.COMPANYS_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Floors.UI.CompanysUIView",            res = "Assets/Res/UI/CompanysUI.prefab"},

    [ENUM_GAME_UITYPE.DIAMOND_REWARD_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.DiamondRewardUIView",        res = "Assets/Res/UI/DiamondRewardUI.prefab"},
    [ENUM_GAME_UITYPE.DIAMOND_SHOP_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.DiamondShopUIView",          res = "Assets/Res/UI/DiamondShopUI.prefab"},
    [ENUM_GAME_UITYPE.TICKET_USE_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.TicketUseUIView",            res = "Assets/Res/UI/TicketUseUI.prefab"},

    [ENUM_GAME_UITYPE.ROOM_FLOAT_UI]            = {style = ENUM_GAME_UISTYLE.MULTI,          class = "GamePlay.Floors.UI.RoomFloatUIView",             res = "Assets/Res/UI/RoomUnlockBtn.prefab"},
    [ENUM_GAME_UITYPE.ROOM_UNLOCK_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Floors.UI.RoomUnlockUIView",             res = "Assets/Res/UI/RoomUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.UNLOCKING_SKIP_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Floors.UI.UnlockingSkipUIView",             res = "Assets/Res/UI/UnlockingSkipUI.prefab"},

    [ENUM_GAME_UITYPE.OFFLINE_REWARD_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.OfflineRewardView",            res = "Assets/Res/UI/OfflineRewardUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.TIPS_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.TipsUIView",                   res = "Assets/Res/UI/TipsUI.prefab"},
    [ENUM_GAME_UITYPE.CHOOSE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.ChooseUIView",                   res = "Assets/Res/UI/ChooseUI.prefab"},
    [ENUM_GAME_UITYPE.GIFT_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.GiftUIView",                   res = "Assets/Res/UI/GiftUI.prefab"},

    [ENUM_GAME_UITYPE.EVENT001_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.Event001UIView",               res = "Assets/Res/UI/Event001_Interface.prefab"},
    [ENUM_GAME_UITYPE.EVENT003_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.Event003UIView",               res = "Assets/Res/UI/Event003_Interface.prefab"},
    [ENUM_GAME_UITYPE.EVENT004_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.Event004UIView",               res = "Assets/Res/UI/Event004_Interface.prefab"},
    [ENUM_GAME_UITYPE.EVENT005_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.Event005UIView",               res = "Assets/Res/UI/Event005_Interface.prefab"},--圣诞老人的,prefab删了...
    [ENUM_GAME_UITYPE.EVENT006_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.Event006UIView",               res = "Assets/Res/UI/Event006_Interface.prefab"},

    [ENUM_GAME_UITYPE.CLOUD_STORAGE]            = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.CloudStorageUIUIView",       res = "Assets/Res/UI/CloudStorageUI.prefab"},

    [ENUM_GAME_UITYPE.QUEST_UI]                 = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.QuestUIView",                  res = "Assets/Res/UI/TaskUI.prefab"},
    [ENUM_GAME_UITYPE.CONTRACT_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Floors.UI.ContractUIView",               res = "Assets/Res/UI/ContractUI.prefab"},
    [ENUM_GAME_UITYPE.FLY_ICONS_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.FlyIconsUIView",               res = "Assets/Res/UI/FlyIconsUI.prefab", backType = BACK_SKIP_TO_NEXT_LAYER},
    [ENUM_GAME_UITYPE.GUIDE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.GuideUIView",               res = "Assets/Res/UI/GuideUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.SETTING_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.SettingView",               res = "Assets/Res/UI/SettingUI.prefab"},
    [ENUM_GAME_UITYPE.DOUBLE_REWARD_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.DoubleRewardUIView",                  res = "Assets/Res/UI/DoubleRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CUT_SCREEN_UI]               = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.CutScreenUIView",                  res = "Assets/Res/UI/CutToSceneUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.COMPANY_LVUP_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Floors.UI.CompanyLvUpUIView",               res = "Assets/Res/UI/CompanyLvUpUI.prefab"},
    [ENUM_GAME_UITYPE.EVENT_MEETING_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.EventMeetingUIView",               res = "Assets/Res/UI/Event002_Interface.prefab"},
    [ENUM_GAME_UITYPE.COLLECTION_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.CollectionUIView",               res = "Assets/Res/UI/CollectionUI.prefab"},
    [ENUM_GAME_UITYPE.COMPANY_MAP_INFO_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.CompanyMapInfoUIView",               res = "Assets/Res/UI/CompanyMapInfoUI.prefab"},
    [ENUM_GAME_UITYPE.RENEW_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Floors.UI.RenewUIView",               res = "Assets/Res/UI/RenewUI.prefab"},
    [ENUM_GAME_UITYPE.RATE_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.RateUIView",               res = "Assets/Res/UI/RateUI.prefab"},
    [ENUM_GAME_UITYPE.REWARD_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.RewardUIView",               res = "Assets/Res/UI/RewardUI.prefab"},
    [ENUM_GAME_UITYPE.CHAT_EVENT_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.ChatEventUIView",               res = "Assets/Res/UI/ChatEventUI.prefab"},
    [ENUM_GAME_UITYPE.SCENE_CHAT_INFO_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.SceneChatInfoUIView",               res = "Assets/Res/UI/SceneChatInfoUI.prefab"},
    [ENUM_GAME_UITYPE.CONFORM_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.ConformUIView",              res = "Assets/Res/UI/ConformUI.prefab"},

    [ENUM_GAME_UITYPE.PHONE_UI]                   = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.PhoneUI",            res = "Assets/Res/UI/PhoneUI.prefab"},
    [ENUM_GAME_UITYPE.APP_CHAT_UI]                = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.ChatUI",             res = "Assets/Res/UI/AppChatUI.prefab"},
    [ENUM_GAME_UITYPE.APP_CHAT_INFO_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.ChatInfoUI",         res = "Assets/Res/UI/AppChatInfoUI.prefab"},
    [ENUM_GAME_UITYPE.BANK_UI]                    = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.BankUI",             res = "Assets/Res/UI/AppBankUI.prefab"},

    [ENUM_GAME_UITYPE.APP_CHAT_INFO_UI2]           = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.ChatInfoUI2",         res = "Assets/Res/UI/AppChatInfoUI2.prefab"},

    [ENUM_GAME_UITYPE.APP_CAR_UI]                 = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.BuyCarUI",           res = "Assets/Res/UI/AppCarUI.prefab"},
    [ENUM_GAME_UITYPE.APP_CAR_INFO_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.BuyCarInfoUI",       res = "Assets/Res/UI/AppCarInfoUI.prefab"},
    [ENUM_GAME_UITYPE.APP_RANK_UI]                = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Phone.UI.RankListUI",         res = "Assets/Res/UI/AppRankUI.prefab"},

    [ENUM_GAME_UITYPE.BOSS_CHOOSE_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.City.UI.BossChooseUI",        res = "Assets/Res/UI/BossChooseUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.BOSS_TALK_UI]               = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.City.UI.BossTalkUI",          res = "Assets/Res/UI/SceneTalkUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.BENAME_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.City.UI.BenameUI",            res = "Assets/Res/UI/NameUI.prefab", backType = BACK_RETURN},

    [ENUM_GAME_UITYPE.TALK_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.TalkUIView",            res = "Assets/Res/UI/TalkUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.HOUSE_CONTRACT_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Floors.UI.HouseContractView",      res = "Assets/Res/UI/HouseContractUI.prefab"},
    [ENUM_GAME_UITYPE.FORBES_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Floors.UI.ForbesRewardUIView",      res = "Assets/Res/UI/ForbesRewardUI.prefab"},

    [ENUM_GAME_UITYPE.SHOP_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.ShopUIView",              res = "Assets/Res/UI/ShopUI.prefab"},
    [ENUM_GAME_UITYPE.ROULETTE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.RouletteUIView",              res = "Assets/Res/UI/WheelUI.prefab"},
    [ENUM_GAME_UITYPE.INTRODUCE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.IntroduceUIView",              res = "Assets/Res/UI/PopupUI.prefab"},
    [ENUM_GAME_UITYPE.GAME_CENTER_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.GameCenterUIView",              res = "Assets/Res/UI/GameCenterUI.prefab"},

    [ENUM_GAME_UITYPE.PURCHASESUCCESS_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.PurchaseSuccessUI",              res = "Assets/Res/UI/PurchaseSuccess.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.DIAMONDFUNDUIVIEW_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.DiamondFundUIView",              res = "Assets/Res/UI/DiamondFundUI_2.prefab"},
    [ENUM_GAME_UITYPE.AD_FREE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Shop.AdFreeUIView",              res = "Assets/Res/UI/AdFreeUI.prefab"},
    [ENUM_GAME_UITYPE.WORK_SHOP_UNLOCK_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Factory.UI.WorkShopUnlockUIView",              res = "Assets/Res/UI/WorkshopUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.WORK_SHOP_INFO_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Factory.UI.WorkShopInfoUIView",              res = "Assets/Res/UI/WorkshopInfoUI.prefab"},
    [ENUM_GAME_UITYPE.ORDER_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Factory.UI.OrderUIView",              res = "Assets/Res/UI/OrderUI.prefab"},
    [ENUM_GAME_UITYPE.ORDER_FINISH_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.OrderFinishUIView",              res = "Assets/Res/UI/OrderFinishUI.prefab"},
    [ENUM_GAME_UITYPE.STOCK_FULL_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.StockFullUIView",              res = "Assets/Res/UI/StockFullUI.prefab"},
    [ENUM_GAME_UITYPE.PIGGY_BANK_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.PiggyBankUIView",              res = "Assets/Res/UI/PiggyBankUI_2.prefab"},
    [ENUM_GAME_UITYPE.PET_LIST_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.PetListUIView",              res = "Assets/Res/UI/PetListUI.prefab"},
    [ENUM_GAME_UITYPE.PET_INTERACT_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.PetInteractUIView",              res = "Assets/Res/UI/PetInteractUI.prefab"},
    [ENUM_GAME_UITYPE.ACTIVITY_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Common.UI.ActivityUIView",              res = "Assets/Res/UI/ActivityUI.prefab"},
    [ENUM_GAME_UITYPE.WORKSHOP_ITEM_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.Factory.UI.WorkshopItemUIView",              res = "Assets/Res/UI/WorkshopItemUI.prefab"},
    [ENUM_GAME_UITYPE.WORLD_LIST_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.City.UI.WorldListUIView",              res = "Assets/Res/UI/WorldListUI.prefab"},
    [ENUM_GAME_UITYPE.EXCHANGE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,          class = "GamePlay.City.UI.ExchangeUIView",              res = "Assets/Res/UI/ExchangeUI.prefab"},
    [ENUM_GAME_UITYPE.EUROPE_MAP_UI]                  = {style = ENUM_GAME_UISTYLE.FULL,          class = "GamePlay.City.UI.CityMapUIView",              res = "Assets/Res/UI/EuropeMapUI.prefab"},

    --临时活动排行榜UI 2022-9-30 fengyu
    [ENUM_GAME_UITYPE.ACTIVITY_RANK_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,        class = "GamePlay.Common.UI.ActivityRankUIView",                res = "Assets/Res/UI/BuildRankUI.prefab"},
    --活动排行榜奖励领取UI 2022-10-13
    [ENUM_GAME_UITYPE.ACTIVITY_RANK_REWARD_GET_UI]  = {style = ENUM_GAME_UISTYLE.NORMAL,    class = "GamePlay.Common.UI.ActivityRankRewardGetUIView", res = "Assets/Res/UI/BuildRankRewardUI.prefab"},
    [ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI]  = {style = ENUM_GAME_UISTYLE.NORMAL,    class = "GamePlay.Common.UI.FragmentActivityUIView", res = "Assets/Res/UI/FragmentActivityUI.prefab"},

    --公告板UI 2022-11-11
    [ENUM_GAME_UITYPE.BOARD_UI]             		= {style = ENUM_GAME_UISTYLE.NORMAL,        	class = "GamePlay.Common.UI.BoardUIView",                	res = "Assets/Res/UI/BoardUI.prefab", backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CHEAT_UI]             		= {style = ENUM_GAME_UISTYLE.NORMAL,        	class = "GamePlay.Common.UI.CheatUIView",                	res = "Assets/Res/UI/CheatUI.prefab"},
    [ENUM_GAME_UITYPE.PERSON_INTERACT_UI] 			= {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.Common.UI.PersonInteractUIView",      	res = "Assets/Res/UI/PersonInteractUI.prefab"},
    [ENUM_GAME_UITYPE.LIMIT_PACK_UI] 		        = {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.Common.UI.LimitPackUIView",      	        res = "Assets/Res/UI/LimitPackUI.prefab"},

    --累充奖励活动UI2022-12-22 fengyu
    [ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI] 		= {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.Common.UI.AccumulatedChargeACUIView",      	res = "Assets/Res/UI/PaymentUI.prefab"},

    --问卷答题活动的UI2023-3-20 fengyu
    --[ENUM_GAME_UITYPE.QUESTION_SURVEY]              ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.QuestionSurvey.UI.QuestionSurveyUIView",      res = "Assets/Res/UI/SurveyUI.prefab"},

    --接入第三方问卷 UI 2024-09-05 wangyang
    [ENUM_GAME_UITYPE.QUESTION_SURVEY_NEW]              ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.QuestionSurvey.UI.QuestionSurveyNewUIView",      res = "Assets/Res/UI/SurveyUI.prefab", backType = BACK_RETURN},

    [ENUM_GAME_UITYPE.FC_STADIUM_UI] 		        = {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.FootballClub.UI.FCStadiumUIView",      	    res = "Assets/Res/UI/FCStadiumUI.prefab"},

    --足球俱乐部 2023年8月1日11:42:16
    [ENUM_GAME_UITYPE.FC_STADIUM_UI] 		        = {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.FootballClub.UI.FCStadiumUIView",      	    res = "Assets/Res/UI/FCStadiumUI.prefab"},
    [ENUM_GAME_UITYPE.FC_LEVEL_UP_UI]               ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCLevelupUIView",             res = "Assets/Res/UI/FCLevelupUI.prefab"},
    [ENUM_GAME_UITYPE.FC_CLUB_CENTER_UI]            ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCClubCenterUIView",          res = "Assets/Res/UI/FCClubCenterUI.prefab"},
    [ENUM_GAME_UITYPE.FC_HEALTH_CENTER_UI]          ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCHealthCenterUIView",        res = "Assets/Res/UI/FCHealthCenterUI.prefab"},
    [ENUM_GAME_UITYPE.FC_TACTICAL_CENTER_UI]        ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCTacticalCenterUIView",      res = "Assets/Res/UI/FCTacticalCenterUI.prefab"},
    [ENUM_GAME_UITYPE.FC_TRAINING_GROUND_UI]        ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCTrainingGroundUIView",      res = "Assets/Res/UI/FCTrainingGroundUI.prefab"},
    [ENUM_GAME_UITYPE.FC_ROOM_UNLOCK_UI]            ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCRoomUnlockUIView",          res = "Assets/Res/UI/FCRoomUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.FC_LENAGUE_RANK_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,          	class = "GamePlay.FootballClub.UI.FCLeagueRankUIView",          res = "Assets/Res/UI/FCLeagueRankUI.prefab"},
    [ENUM_GAME_UITYPE.FC_SETTLEMENT_UI]             ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCSettlementUIView",          res = "Assets/Res/UI/FCSettlementUI.prefab"},
    [ENUM_GAME_UITYPE.FC_TRAINING_REWARD_UI]        ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCTrainningRewardUIView",     res = "Assets/Res/UI/FCTrainningRewardUI.prefab"},
    [ENUM_GAME_UITYPE.FC_LEAGUE_UP_UI]              ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.FootballClub.UI.FCLeagueUpUIView",            res = "Assets/Res/UI/FCLeagueupUI.prefab"},


    --副本 2023年3月16日15:52:23 guoxiaoyu
    [ENUM_GAME_UITYPE.INSTANCE_VIEW_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceViewUIView",          res = "Assets/Res/UI/InstanceViewUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceMainViewUIView",      res = "Assets/Res/UI/InstanceMainViewUI.prefab", backType = BACK_INSTANCE_MAIN},
    [ENUM_GAME_UITYPE.INSTANCE_TIME_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceTimeUIView",          res = "Assets/Res/UI/InstanceTimeUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_REWARD_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceRewardUIView",        res = "Assets/Res/UI/InstanceRewardUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_MILEPOST_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceMilepostUIView",      res = "Assets/Res/UI/InstanceMilepostUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_UNLOCK_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceUnlockUIView",        res = "Assets/Res/UI/InstanceUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_BUILDING_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceBuildingUIView",      res = "Assets/Res/UI/InstanceBuildingUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_SHOP_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceShopUIView",          res = "Assets/Res/UI/InstanceShopUI.prefab"},
    [ENUM_GAME_UITYPE.INSRANCE_PROCESS_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceProcessUIView",       res = "Assets/Res/UI/InstanceProcessUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_OFFLINE_REWARD_UI]   = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceOfflineRewardUIView", res = "Assets/Res/UI/InstanceOfflineUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_POP_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstancePopUIView",           res = "Assets/Res/UI/InstancePopupUI.prefab"},
    [ENUM_GAME_UITYPE.FAQ_UI]                       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.FAQUIView",                     res = "Assets/Res/UI/FaqUI.prefab"},
    [ENUM_GAME_UITYPE.SHOP_INSTANT_UI]              = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.ShopInstantUIView",             res = "Assets/Res/UI/ShopInstantUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_AD_UI]               = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceAdUIView",            res = "Assets/Res/UI/InstanceAdUI.prefab"},

    [ENUM_GAME_UITYPE.PERSONAL_INFO_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.PersonalDev.UI.PersonalInfoUIView",       res = "Assets/Res/UI/LeadInfoUI.prefab"},
    [ENUM_GAME_UITYPE.PERSONAL_AFFAIR_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.PersonalDev.UI.PersonalAffairUIView",     res = "Assets/Res/UI/LeadAffairsUI.prefab"},
    [ENUM_GAME_UITYPE.PERSONAL_PROMOTE_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.PersonalDev.UI.PersonalPromoteUIView",     res = "Assets/Res/UI/ElectiontimeUI.prefab"},
    [ENUM_GAME_UITYPE.PERSONAL_PROMOTE_RESULT_UI]   = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.PersonalDev.UI.PersonalPromoteResultUIView",res = "Assets/Res/UI/ElectionresultUI.prefab"},
    [ENUM_GAME_UITYPE.PERSONAL_LVLUP_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.PersonalDev.UI.PersonalLvlUpUIView",      res = "Assets/Res/UI/LeadPromoteUI.prefab"},

    [ENUM_GAME_UITYPE.LIMIT_CHOOSE_UI] 		        = { style = ENUM_GAME_UISTYLE.NORMAL,           class = "GamePlay.Common.UI.LimitChooseUIView",             res = "Assets/Res/UI/LimitChooseUI.prefab"},

    [ENUM_GAME_UITYPE.INSTANCE_REWARD_UI_2]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceRewardUIView2",       res = "Assets/Res/UI/InstanceRewardUI_2.prefab"},

    [ENUM_GAME_UITYPE.INSTANCE_REWARD_UI_3]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Instance.UI.InstanceRewardUIView3",       res = "Assets/Res/UI/InstanceRewardUI_3.prefab"},
    [ENUM_GAME_UITYPE.Story_Line_UI]                = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.House.UI.StoryLineUIView",                res = "Assets/Res/UI/MainLineUI.prefab"},
    [ENUM_GAME_UITYPE.CAR_SHOP_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Shop.BuyCar.BuyCarShopUIView",            res = "Assets/Res/UI/CarShopUI.prefab"},
    [ENUM_GAME_UITYPE.SUPPLEMENT_ORDER_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.SupplementOrderUIView",            res = "Assets/Res/UI/OrderRestoreUI.prefab"},
    [ENUM_GAME_UITYPE.MONTH_CARD_UI]                = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.MonthCardUIView",               res = "Assets/Res/UI/MonthCardUI.prefab"},
    [ENUM_GAME_UITYPE.FIRST_PURCHASE_UI]            = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.FirstPurchaseUIView",           res = "Assets/Res/UI/FirstPurchaseUI.prefab"},
    [ENUM_GAME_UITYPE.STATISTIC_UI]                 = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Statistic.UI.StatisticUIView",            res = "Assets/Res/UI/StatisticUI.prefab"},
    [ENUM_GAME_UITYPE.COMMON_REWARD_UI]             = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.CommonRewardUIView",            res = "Assets/Res/UI/LimitChooseRewardUI.prefab"},
    [ENUM_GAME_UITYPE.SEASON_PASS_UI]               = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.SeasonPassUIView",              res = "Assets/Res/UI/SeasonPass/UI_SeasonPass_tuibiji_normal_Main.prefab"},
    [ENUM_GAME_UITYPE.SEASON_PASS_POPUP_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.SeasonPassPopupUIView",         res = "Assets/Res/UI/SeasonPass/UI_SeasonPass_tuibiji_normal_Popup.prefab"},
    [ENUM_GAME_UITYPE.SEASON_PASS_PACK_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.SeasonPassPackUIView",          res = "Assets/Res/UI/SeasonPass/UI_SeasonPass_tuibiji_normal_Pack.prefab"},

    [ENUM_GAME_UITYPE.CEO_HIRING_UI]                  = { style = ENUM_GAME_UISTYLE.NORMAL, class = "GamePlay.Common.UI.CEO.CEOHiringUIView", res = "Assets/Res/UI/CeoHiringViewUI.prefab"},
    [ENUM_GAME_UITYPE.CEO_DESK_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.CEO.CEODeskUIView",                 res = "Assets/Res/UI/CeoDeskUI.prefab"},
    [ENUM_GAME_UITYPE.CEO_HIRED_UI]                 = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.CEO.CEOHiredUIView",                res = "Assets/Res/UI/CeoDeskUI.prefab"},
    [ENUM_GAME_UITYPE.CEO_PURCHASE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.CEO.CEOBoxPurchaseUIView",                 res = "Assets/Res/UI/CeoChestUI.prefab"},
    [ENUM_GAME_UITYPE.CEO_CHEST_PREVIEW_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.CEO.CEOChestPreviewUIView",                 res = "Assets/Res/UI/CeoChestPreviewUI.prefab"},
    [ENUM_GAME_UITYPE.CLOCK_OUT_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.ClockOut.ClockOutUIView",                 res = "Assets/Res/UI/ClockOutUI.prefab"},
    [ENUM_GAME_UITYPE.CLOCK_OUT_POPUP_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.Common.UI.ClockOut.ClockOutPopupUIView",               res = "Assets/Res/UI/ClockOutPopupUI.prefab"},
    [ENUM_GAME_UITYPE.INSTANCE_SLOT_MACHINE]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.temp.SlotMachine.SlotMachineUIView",           res = "Assets/Res/UI/SlotMachineUI.prefab",  backType = BACK_RETURN},

    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_SKILL_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstanceSkillUIView",           res = "Assets/Res/UI/InstanceNewSkillUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_HERO_UPGRADE_UI] = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandHeroUpgradeUIView",       res = "Assets/Res/UI/InstanceNewHeroUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_TASK_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandTaskUIView",              res = "Assets/Res/UI/InstanceNewTaskUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI]    = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandMainViewUIView",              res = "Assets/Res/UI/InstanceNewMainViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_TIME_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandTimeUIView",              res = "Assets/Res/UI/InstanceTimeUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_SHOP_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstanceShopUIView",           res = "Assets/Res/UI/InstanceNewShopUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_VIEW_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandViewUIView",              res = "Assets/Res/UI/InstanceNewViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_MILEPOST_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstanceMilepostUIView",           res = "Assets/Res/UI/InstanceNewMilepostUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_BUILDING_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandBuildingUIView",           res = "Assets/Res/UI/InstanceNewBuildingUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_REWARD_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstanceRewardUIView",           res = "Assets/Res/UI/InstanceNewRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_SELL_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandSellUIView",           res = "Assets/Res/UI/InstanceNewSellUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_POP_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstancePopUIView",           res = "Assets/Res/UI/InstanceNewGiftsUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_UNLOCK_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandUnlockUIView",           res = "Assets/Res/UI/InstanceNewUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_ISLAND_OFFLINE_REWARD_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleIslandOfflineRewardUIView",           res = "Assets/Res/UI/InstanceNewOfflineUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_INSTANCE_AD_UI]               = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Island.UI.CycleInstanceAdUIView",            res = "Assets/Res/UI/InstanceAdUI.prefab"},
    [ENUM_GAME_UITYPE.AD_TICKET_CHOOSE_UI]                  = {style = ENUM_GAME_UISTYLE.NORMAL,         class = "GamePlay.Common.UI.ADChooseUIView",                   res = "Assets/Res/UI/ChooseUI.prefab"},

    [ENUM_GAME_UITYPE.CYCLE_CASTLE_SLOT_MACHINE]    = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleSlotMachineUIView",        res = "Assets/Res/UI/CycleInstance/Castle/CastleSlotMachineUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_SKILL_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleSkillUIView",              res = "Assets/Res/UI/CycleInstance/Castle/CastleSkillUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_HERO_UPGRADE_UI] = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleHeroUpgradeUIView",        res = "Assets/Res/UI/CycleInstance/Castle/CastleHeroUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_TASK_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleTaskUIView",               res = "Assets/Res/UI/CycleInstance/Castle/CastleTaskUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_MAIN_VIEW_UI]    = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleMainViewUIView",           res = "Assets/Res/UI/CycleInstance/Castle/CastleMainViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_TIME_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleTimeUIView",               res = "Assets/Res/UI/CycleInstance/Castle/CastleTimeUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_SHOP_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleShopUIView",               res = "Assets/Res/UI/CycleInstance/Castle/CastleShopUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_VIEW_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleViewUIView",               res = "Assets/Res/UI/CycleInstance/Castle/CastleViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_MILEPOST_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleMilepostUIView",           res = "Assets/Res/UI/CycleInstance/Castle/CastleMilepostUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_BUILDING_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleBuildingUIView",           res = "Assets/Res/UI/CycleInstance/Castle/CastleBuildingUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_REWARD_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleRewardUIView",             res = "Assets/Res/UI/CycleInstance/Castle/CastleRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_SELL_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleSellUIView",               res = "Assets/Res/UI/CycleInstance/Castle/CastleSellUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_POP_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastlePopUIView",                res = "Assets/Res/UI/CycleInstance/Castle/CastleGiftsUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_UNLOCK_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleUnlockUIView",             res = "Assets/Res/UI/CycleInstance/Castle/CastleUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_OFFLINE_REWARD_UI]={style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleOfflineRewardUIView",      res = "Assets/Res/UI/CycleInstance/Castle/CastleOfflineUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_AD_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleAdUIView",                 res = "Assets/Res/UI/CycleInstance/Castle/CastleAdUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_CUT_SCREEN_UI]   = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Castle.UI.CycleCastleCutScreenUIView",          res = "Assets/Res/UI/CycleInstance/Castle/CastleLoadingUI.prefab",  backType = BACK_RETURN},


    [ENUM_GAME_UITYPE.CYCLE_TOY_SLOT_MACHINE]    = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToySlotMachineUIView",        res = "Assets/Res/UI/CycleInstance/Toy/ToySlotMachineUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CYCLE_TOY_SKILL_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToySkillUIView",              res = "Assets/Res/UI/CycleInstance/Toy/ToySkillUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_HERO_UPGRADE_UI] = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyHeroUpgradeUIView",        res = "Assets/Res/UI/CycleInstance/Toy/ToyHeroUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_TASK_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyTaskUIView",               res = "Assets/Res/UI/CycleInstance/Toy/ToyTaskUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_MAIN_VIEW_UI]    = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyMainViewUIView",           res = "Assets/Res/UI/CycleInstance/Toy/ToyMainViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_TIME_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyTimeUIView",               res = "Assets/Res/UI/CycleInstance/Toy/ToyTimeUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_SHOP_UI]         = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyShopUIView",               res = "Assets/Res/UI/CycleInstance/Toy/ToyShopUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_VIEW_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyViewUIView",               res = "Assets/Res/UI/CycleInstance/Toy/ToyViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_MILEPOST_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyMilepostUIView",           res = "Assets/Res/UI/CycleInstance/Toy/ToyMilepostUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_BUILDING_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyBuildingUIView",           res = "Assets/Res/UI/CycleInstance/Toy/ToyBuildingUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_REWARD_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyRewardUIView",             res = "Assets/Res/UI/CycleInstance/Toy/ToyRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_SELL_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToySellUIView",               res = "Assets/Res/UI/CycleInstance/Toy/ToySellUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_POP_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyPopUIView",                res = "Assets/Res/UI/CycleInstance/Toy/ToyGiftsUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_UNLOCK_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyUnlockUIView",             res = "Assets/Res/UI/CycleInstance/Toy/ToyUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_OFFLINE_REWARD_UI]={style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyOfflineRewardUIView",      res = "Assets/Res/UI/CycleInstance/Toy/ToyOfflineUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_AD_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyAdUIView",                 res = "Assets/Res/UI/CycleInstance/Toy/ToyAdUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_TOY_CUT_SCREEN_UI]   = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyCutScreenUIView",          res = "Assets/Res/UI/CycleInstance/Toy/ToyLoadingUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CYCLE_TOY_BLUE_PRINT_UI]   = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.Toy.UI.CycleToyBlueprintUIView",          res = "Assets/Res/UI/CycleInstance/Toy/ToyBlueprintUI.prefab",  backType = BACK_RETURN},

    --副本排行榜 UI 2024-10-28 wangyang
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_UI]              ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.CycleInstance.Castle.UI.CycleCastleRankUIView",      res = "Assets/Res/UI/CycleInstance/Castle/CastleRankUI.prefab", backType = BACK_RETURN},
    -- 2024.11.04 排行榜奖励，弹出宝箱，改为新预制体
    [ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_REAWARD_UI]         = { style = ENUM_GAME_UISTYLE.NORMAL, class = "GamePlay.CycleInstance.Castle.UI.CycleCastleRankRewardUIView", res = "Assets/Res/UI/CycleInstance/Castle/CastleRankRewardUI.prefab"},


    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SLOT_MACHINE]    = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubSlotMachineUIView",        res = "Assets/Res/UI/CycleInstance/NtClub/NtClubSlotMachineUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SKILL_UI]        = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubSkillUIView",              res = "Assets/Res/UI/CycleInstance/NtClub/NtClubSkillUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_HERO_UPGRADE_UI] = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubHeroUpgradeUIView",        res = "Assets/Res/UI/CycleInstance/NtClub/NtClubHeroUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_TASK_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubTaskUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubTaskUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI]    = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubMainViewUIView",           res = "Assets/Res/UI/CycleInstance/NtClub/NtClubMainViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_TIME_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubTimeUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubTimeUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SHOP_UI]         = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubShopUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubShopUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_VIEW_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubViewUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubViewUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MILEPOST_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubMilepostUIView",           res = "Assets/Res/UI/CycleInstance/NtClub/NtClubMilepostUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_BUILDING_UI]     = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubBuildingUIView",           res = "Assets/Res/UI/CycleInstance/NtClub/NtClubBuildingUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_REWARD_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubRewardUIView",             res = "Assets/Res/UI/CycleInstance/NtClub/NtClubRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SELL_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubSellUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubSellUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_POP_UI]          = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubPopUIView",                res = "Assets/Res/UI/CycleInstance/NtClub/NtClubGiftsUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_UNLOCK_UI]       = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubUnlockUIView",             res = "Assets/Res/UI/CycleInstance/NtClub/NtClubUnlockUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_OFFLINE_REWARD_UI]={style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubOfflineRewardUIView",      res = "Assets/Res/UI/CycleInstance/NtClub/NtClubOfflineUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_AD_UI]           = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubAdUIView",                 res = "Assets/Res/UI/CycleInstance/NtClub/NtClubAdUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_CUT_SCREEN_UI]   = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubCutScreenUIView",          res = "Assets/Res/UI/CycleInstance/NtClub/NtClubLoadingUI.prefab",  backType = BACK_RETURN},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_BLUE_PRINT_UI]   = {style = ENUM_GAME_UISTYLE.FULL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubBlueprintUIView",          res = "Assets/Res/UI/CycleInstance/NtClub/NtClubBlueprintUI.prefab",  backType = BACK_RETURN},

    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_UI]              ={style = ENUM_GAME_UISTYLE.NORMAL,             class = "GamePlay.CycleInstance.Castle.UI.CycleNightClubRankUIView",      res = "Assets/Res/UI/CycleInstance/NtClub/NtClubRankUI.prefab", backType = BACK_RETURN},
    -- 2024.11.04 排行榜奖励，弹出宝箱，改为新预制体
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_REAWARD_UI]         = { style = ENUM_GAME_UISTYLE.NORMAL, class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubRankRewardUIView", res = "Assets/Res/UI/CycleInstance/NtClub/NtClubRankRewardUI.prefab"},
    [ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_PIGGY_BANK_UI]         = {style = ENUM_GAME_UISTYLE.NORMAL,            class = "GamePlay.CycleInstance.NightClub.UI.CycleNightClubPiggyBankUIView",               res = "Assets/Res/UI/CycleInstance/NtClub/NtClubPiggyBankUI.prefab"},



    [ENUM_GAME_UITYPE.CEO_EXCESS_CONVERT_UI] = { style = ENUM_GAME_UISTYLE.NORMAL, class = "GamePlay.Common.UI.CEOExcessConvertUIView", res = "Assets/Res/UI/CeoExcessConvertUI.prefab" },

}
-- 最后面的在最上层
local ENUM_TOP_UI_LIST =
{
    ENUM_GAME_UITYPE.INTRODUCE_UI,
    ENUM_GAME_UITYPE.GUIDE_UI,
    ENUM_GAME_UITYPE.BENAME_UI,
    ENUM_GAME_UITYPE.TALK_UI,
    ENUM_GAME_UITYPE.SUPPLEMENT_ORDER_UI,
    ENUM_GAME_UITYPE.OFFLINE_REWARD_UI,
    ENUM_GAME_UITYPE.INSTANCE_OFFLINE_REWARD_UI,
    ENUM_GAME_UITYPE.FLY_ICONS_UI,
    ENUM_GAME_UITYPE.LAUNCH,
    ENUM_GAME_UITYPE.AD_TICKET_CHOOSE_UI,
    ENUM_GAME_UITYPE.CHOOSE_UI,
    ENUM_GAME_UITYPE.CUT_SCREEN_UI,
    ENUM_GAME_UITYPE.BOARD_UI,
    ENUM_GAME_UITYPE.TIPS_UI,
    ENUM_GAME_UITYPE.CYCLE_CASTLE_CUT_SCREEN_UI,
    ENUM_GAME_UITYPE.CYCLE_TOY_CUT_SCREEN_UI,
}
local ENUM_TOP_UI_LIST_LOOK_UP = nil

local CONST_UI_FIRST_INDEX = 4

function GameUIManager:RedirectPrefab(UIType, prefabPath)
    local uiconfig = UIConfig[UIType]
    uiconfig.res = prefabPath
end

local function IsInTopUIList(UIType)
    if not ENUM_TOP_UI_LIST_LOOK_UP then
        ENUM_TOP_UI_LIST_LOOK_UP = {}
        for _, v in ipairs(ENUM_TOP_UI_LIST) do
            ENUM_TOP_UI_LIST_LOOK_UP[v] = true
        end
    end
    return ENUM_TOP_UI_LIST_LOOK_UP[UIType] or false
end

---@generic T:UIBaseView
---@param UIViewClass T
---@return T
function GameUIManager:SafeOpenUI(UIType, UIView, UIViewClass, mode, modeCloseFunction)
    local view = UIView or UIViewClass.new()
    if not UIView or not UIView:IsValid() then
        self:OpenUI(UIType, view,mode, modeCloseFunction)
    end
    return view
end

function GameUIManager:OpenUI(_UIType, view, mode, modeCloseFunction)
    local cfg = UIConfig[_UIType]
    if not cfg then return end

    if not view and cfg.class and "" ~= cfg.class then
        view = require(cfg.class).new()
    end

    local uiTop = self.m_uiStack[#self.m_uiStack]

    view:SetUIObj(nil)
    view:SetUIType(_UIType)
    view:SetStatus(ENUM_VIEW_STATUS.LOADING)
    if _UIType == ENUM_GAME_UITYPE.CITY_MAP or _UIType == ENUM_GAME_UITYPE.EUROPE_MAP_UI then --  --ENUM_GAME_UITYPE.MAIN_UI
        local mainUIIndex = self:GetUIIndex(ENUM_GAME_UITYPE.MAIN_UI, true)
        table.insert(self.m_uiStack, mainUIIndex, view)
        table.insert(self.m_uiShow, mainUIIndex, true)
    else
        table.insert(self.m_uiStack, view)
        table.insert(self.m_uiShow, true)
    end

    local co = coroutine.create(function(UIType, view)
        local uiObj
        view:Preoad()
        --GameTools:CostTime(function()
        self.m_resLoaidngCount = (self.m_resLoaidngCount or 0) + 1

            local res = cfg.res
            if cfg.isMultilingual then
                res = string.format(res, GameConfig:GetLangageFileSuffix())
            end
            uiObj = GameResMgr:AInstantiateSync(res, view)
            if not uiObj or not view then
                lprintf("Open UI '%s' Error!", res)
                return
            end
            if ENUM_GAME_UISTYLE.NORMAL == UIConfig[UIType].style 
            and UIType ~= ENUM_GAME_UITYPE.MAIN_UI 
            and UIType ~= ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI
            and UIType ~= ENUM_GAME_UITYPE.FLY_ICONS_UI
            and UIType ~= ENUM_GAME_UITYPE.TIPS_UI
            and UIType ~= ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI
            and UIType ~= ENUM_GAME_UITYPE.CYCLE_CASTLE_MAIN_VIEW_UI
            and UIType ~= ENUM_GAME_UITYPE.CYCLE_TOY_MAIN_VIEW_UI
            and UIType ~= ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI
            then
                uiObj:AddComponent(typeof(EmptyRaycast))
                --uiObj:AddComponent(typeof(Button))
            end
        --end, string.format("Load UI '[%s](%s)' Prefab", UIType, cfg.res))

        -- 异步检查
        if not view:IsValid() then
            GameObject.Destroy(uiObj)
            GameResMgr:Unload(view)
            self:CheckSceneSwitchOnUIComplete(UIType)
            return
        end

        --GameTools:CostTime(function()
        if cfg.overLookMotch then
            UnityHelper.AddChildToParent(self.masterCanvasObj.transform, uiObj.transform)
        else
            UnityHelper.AddChildToParent(self.canvasObj.transform, uiObj.transform)
            -- uiObj.transform:SetSiblingIndex(CONST_UI_FIRST_INDEX + self:GetUIIndex(UIType))
        end
        self:CheckSceneSwitchOnUIComplete(UIType)
        --end, string.format("Attach UI '[%s](%s)' to root", UIType, cfg.res))

        if uiTop then
            uiTop:OnPause()
        end

        --GameTools:CostTime(function()
        -- 打开一个新界面
        -- print("OpenUI -->", UIType, view)
        view:SetUIObj(uiObj)
        view:SetStatus(ENUM_VIEW_STATUS.OPENED)
        enableEmmyLuaDebug()
        view:OnEnter()
        view:ClearCmdPool()
        view:SendGuideEvent(GameTableDefine.GuideManager.EVENT_VIEW_OPEND)
        --end, string.format("Enter UI '[%s](%s)'", UIType, cfg.res))

        --GameTools:CostTime(function()
        -- 检查置顶列表
        for _, v in ipairs(ENUM_TOP_UI_LIST) do
            self:SetUITop(v)
        end
        self:UpdateSiblingIndex()
        self:UpdateStyle(UIType)
        -- self:UpdateStyle()      // 暂时注释掉
        --end, string.format("Sort UI '[%s](%s)'", UIType, cfg.res))

        --lprintf("Open UI '[%s](%s)' success!", UIType, cfg.res)
        return view
    end)

    table.insert(self.m_waitPool, {
        co = co,
        type = _UIType,
        view = view,
    })


    if mode then
        view:Invoke("SetModeObj", mode, modeCloseFunction)
    end
end

function GameUIManager:Update()
    if not GameUIManager.canvasObj then return end
    if #self.m_waitPool < 1 then return end

    local d = table.remove(self.m_waitPool, 1)
    assert(coroutine.resume(d.co, d.type, d.view, d.guid, d.canvas))
end

function GameUIManager:GetUIByType(UIType, guid)
    local index = self:GetUIIndex(UIType, false)
    if index and index > 0 then
        local UI = self.m_uiStack[index]
        if UI then
            return UI
        end
    end
    local floatUI = self.m_uiFloat[UIType]
    if self.m_uiFloat and self.m_uiFloat[UIType] then
        return self.m_uiFloat[UIType][guid]
    end
end

function GameUIManager:GetUIIndex(UIType, forward)
    local index = 0
    if forward then
        for i, view in ipairs(self.m_uiStack) do
            if UIType == view:GetUIType() then
                index = i
                break
            end
        end
    else
        for i = #self.m_uiStack, 1, -1 do
            local view = self.m_uiStack[i]
            if view and UIType == view:GetUIType() then
                index = i
                break
            end
        end
    end
    return index
end

function GameUIManager:IsUIOpen(UIType)
    return GameUIManager:GetUIIndex(UIType, false) > 0
end

function GameUIManager:IsUIOpenComplete(UIType)
    for i, view in ipairs(self.m_uiStack) do
        if UIType == view:GetUIType() then
            return view:IsLoaded()
        end
    end
    return false
end

function GameUIManager:UpdateSiblingIndex()
    for idx, ui in ipairs(self.m_uiStack) do
        local uiobj = ui:GetUIObj()
        if uiobj then
            uiobj.transform:SetSiblingIndex(CONST_UI_FIRST_INDEX + idx)
        end
    end
end

function GameUIManager:SetUITop(UIType, update)
    local uiIndex = self:GetUIIndex(UIType, false)
    if uiIndex < 1 then return end

    local oldTop = self.m_uiStack[#self.m_uiStack]
    oldTop:OnPause()

    local newTop = table.remove(self.m_uiStack, uiIndex)
    table.insert(self.m_uiStack, newTop)
    newTop:OnResume()

    if update then
        self:UpdateSiblingIndex()
        self:UpdateStyle(UIType)
    end
end

function GameUIManager:SetUIVisibility(UIType, isVisible)
    if 0 == #self.m_uiStack then
        lprintf("Without close ui error!")
        return
    end
    local uiIndex = self:GetUIIndex(UIType, true)

    if uiIndex > 0 then
        local view = self.m_uiStack[uiIndex]
        local uiObj = view:GetUIObj()
        uiObj:SetActive(isVisible)
    end
end

function GameUIManager:OnlyExitMainUI()
    for index = #self.m_uiStack,1,-1 do
        local uiType = self.m_uiStack[index]:GetUIType()
        if uiType ~= ENUM_GAME_UITYPE.MAIN_UI and uiType ~= ENUM_GAME_UITYPE.GUIDE_UI
                and uiType ~= ENUM_GAME_UITYPE.FLY_ICONS_UI then
            self:CloseUI(uiType)
        end
    end
end

function GameUIManager:CleanUI()--是否没有打开其他界面
    if #self.m_uiStack > 5 then return false end--最基础的只有main_ui和fly_icon和新手引导

    for index = #self.m_uiStack,1,-1 do
        local uiType = self.m_uiStack[index]:GetUIType()
        if uiType ~= ENUM_GAME_UITYPE.MAIN_UI and uiType ~= ENUM_GAME_UITYPE.FLY_ICONS_UI
                and uiType ~= ENUM_GAME_UITYPE.GUIDE_UI and uiType ~= ENUM_GAME_UITYPE.CUT_SCREEN_UI then
            return false
        end
    end

    return true
end

function GameUIManager:CloseUI(UIType)
    if 0 == #self.m_uiStack then
        lprintf("Without close ui error!")
        return
    end

    local uiTopType = self.m_uiStack[#self.m_uiStack]:GetUIType()   -- 优先关闭最上面的UI
    local uiType = UIType or uiTopType
    local uiIndex = self:GetUIIndex(UIType, true)
    local cfg = UIConfig[uiType]

    if 0 == uiIndex then    -- 没有打开这个UI
        if uiType then
            lprintf("Close UI '[%s](%s)' Error!", uiType, cfg.res)
        else

        end
        return
    else
        local view = table.remove(self.m_uiStack, uiIndex)
        if not view then return end
        table.remove(self.m_uiShow, uiIndex)

        local uiType = view:GetUIType()
        local uiObj = view:GetUIObj()
        if uiObj then
            view:OnExit()
            GameObject.Destroy(view:GetUIObj())
            GameResMgr:Unload(view)
        end

        view:SetStatus(ENUM_VIEW_STATUS.CLOSED)
        view = nil
        --lprintf("Close UI '[%s](%s)' Successed!", uiType, cfg.res)
        -- end    
    end

    local uiUnder = self.m_uiStack[uiIndex-1]
    local executeResume = true
    -- print("Close UI", uiTopType, uiType)
    if uiTopType ~= uiType then
        for i = uiIndex, #self.m_uiStack do
            -- 检查置顶列表
            local upView = self.m_uiStack[i]
            local upType = upView:GetUIType()
            if not IsInTopUIList(upType) then
                executeResume = false
                break
            end
        end
    end

    if uiUnder and (uiTopType == uiType or executeResume) then
        uiUnder:OnResume()
    end

    -- 检查置顶列表
    for _, v in ipairs(ENUM_TOP_UI_LIST) do
        self:SetUITop(v)
    end
    self:UpdateStyle(nil, true)
end

--[[
    @desc: UI是否在最上层
    author:{author}
    time:2023-05-08 17:27:18
    --@UIType:待检查的UI类型
	--@ignoreList: 忽略列表,传UI类型组成的table,形式同ENUM_TOP_UI_LIST,在列表中的的UI将不在计算范围中
    @return:
]]
function GameUIManager:UIIsOnTop(UIType,uesIgnore,ignoreList)
    if not UIType then
        return false
    end
    local ignoreUIList = {}
    if uesIgnore then
        if ignoreList and next(ignoreList) ~= nil then
            ignoreUIList = ignoreList
        else
            ignoreUIList = ENUM_TOP_UI_LIST
        end
    end

    local startCheck = false
    for i=1,#self.m_uiStack do
        local curUIType = self.m_uiStack[i].m_uiType
        for i=1,1 do
            if not startCheck then
                if UIType == curUIType then
                    startCheck =true
                    break
                end
            end

            if startCheck then
                local isIgnore = false
                for k,v in pairs(ignoreUIList) do
                    for i=1,1 do
                        if v == curUIType then
                            isIgnore = true
                            break
                        end
                    end
                end
                if isIgnore then
                    break
                end

                return false
            end
        end
    end
    return true
end

--是否为最底层UI(再点击返回就会弹退出弹窗)
function GameUIManager:GetIsTopUI()
    local result = false
    if 1 == #self.m_uiStack then
        local uiTopType = self.m_uiStack[1]:GetUIType()
        local uiBackType =  UIConfig[uiTopType].backType or BACK_CLOSE_LAYER
        if uiBackType == BACK_SHOW_QUIT_POP then
            result = true
        end
    end
    return result
end

function GameUIManager:CloseTopUI()
    local quitPop = function()
        if Application.platform == RuntimePlatform.Android then
            local title = GameTextLoader:ReadText("TXT_TIP_HINT")
            local msg = GameTextLoader:ReadText("TXT_TIP_QUIT_GAME")
            local confirm = GameTextLoader:ReadText("TXT_BTN_CONFIRM")
            local cancel = GameTextLoader:ReadText("TXT_BTN_CANCEL")
            print("Android KeyCode.Escape:title:"..title.." msg:"..msg.." confirm:"..confirm.." cancel:"..cancel)
            UnityHelper.AndroidBackExitGame(title, msg, confirm, cancel)
        else
            print("GameUIManager:CloseTopUI:quitPop")
        end
    end
    if 0 == #self.m_uiStack then
        quitPop()
        return
    end
    print("GameUIMananger:CloseTop[000000]:QuitPop():"..#self.m_uiStack)
    -- if 2 == #self.m_uiStack or 1 == #self.m_uiStack then
    --     for index = #self.m_uiStack, 1, -1 do
    --         local uiTopType = self.m_uiStack[index]:GetUIType()
    --         local uiStyle = UIConfig[uiTopType].style 
    --         local uiBackType =  UIConfig[uiTopType].backType or BACK_CLOSE_LAYER
    --         print("GameUIMananger:CloseTop[11111]:QuitPop():"..uiBackType)
    --         if uiBackType == BACK_SHOW_QUIT_POP then
    --             print("GameUIMananger:CloseTop[22222]:QuitPop()")   
    --             quitPop()
    --             return
    --         end
    --     end
    -- end
    for index = #self.m_uiStack,1,-1 do
        local uiTopType = self.m_uiStack[index]:GetUIType()
        local uiStyle = UIConfig[uiTopType].style
        local uiBackType =  UIConfig[uiTopType].backType or BACK_CLOSE_LAYER
        if uiBackType == BACK_SHOW_QUIT_POP then
            quitPop()
            return
        end
        if uiBackType == BACK_CHECK_VIEW then
            local view = self.m_uiStack[index]
            uiBackType =  view:CheckPressBack()
        end
        if uiBackType == BACK_RETURN then
            return
        elseif uiBackType == BACK_SHOW_QUIT_POP then
            quitPop()
            return
        elseif uiBackType == BACK_CLOSE_LAYER then
            local cfg = UIConfig[uiTopType]
            local view = self.m_uiStack[index]
            if not view:DestroyModeUIObject() then
                view = table.remove(self.m_uiStack, index)
                table.remove(self.m_uiShow, index)
                local uiObj = view:GetUIObj()
                if uiObj then
                    view:OnExit()
                    GameObject.Destroy(uiObj)
                    GameResMgr:Unload(view)
                end
                view:SetStatus(ENUM_VIEW_STATUS.CLOSED)
                view = nil
                local uiUnder = self.m_uiStack[index-1]
                if uiUnder  then
                    uiUnder:OnResume()
                end
                self:UpdateStyle(nil, true)
            end
            break
        elseif uiBackType == BACK_INSTANCE_MAIN then
            self.m_uiStack[index]:Exit()
            break
        end
    end
end

function GameUIManager:UpdateStyle(UIType, force)
    lprintf("GameUIManager UpdateStyle -> %s", UIType)
    local topIndex = UIType and self:GetUIIndex(UIType, false) or #self.m_uiStack
    if topIndex < 1 then return end

    local topUIType = self.m_uiStack[topIndex]:GetUIType()
    local topStyle = UIConfig[topUIType].style
    local topView = self.m_uiStack[topIndex]
    local topObj = topView:GetUIObj()
    local bTopShow = topView:IsLoaded()
    if topObj then topObj:SetActive(bTopShow) end
    self.m_uiShow[topIndex] = bTopShow

    local bEnabledCamera = ENUM_GAME_UISTYLE.NORMAL == topStyle or not topView:IsLoaded()
    local bRenderStatic = ENUM_GAME_UISTYLE.BIG == topStyle

    local tailStyle = topStyle
    -- lprintf("GameUIManager UpdateStyle topUIType->%s topIndex->%s topStyle->%s", topUIType, topIndex, topStyle)
    for index = topIndex-1, 1, -1 do
        local view = self.m_uiStack[index]
        if not view then break end

        tailStyle = UIConfig[view:GetUIType()].style
        local bShow = (ENUM_GAME_UISTYLE.NORMAL == topStyle or not topView:IsLoaded()) and view:IsLoaded()
        if view.forceHide then
            bShow = false
        end
        local uiObj = view:GetUIObj()
        -- print("UpdateStyle ui Obj", uiObj, bShow, topStyle, topView:IsLoaded(), view:IsLoaded())
        if uiObj then
            uiObj:SetActive(bShow)
        end
        self.m_uiShow[index] = bShow

        -- lprintf("GameUIManager UpdateStyle tailIndex->%s tailStyle->%s", index, tailStyle)
        if ENUM_GAME_UISTYLE.NORMAL ~= tailStyle then
            bEnabledCamera = not view:IsLoaded()
            bRenderStatic = bRenderStatic or ENUM_GAME_UISTYLE.BIG == topStyle
            break
        end
    end

    -- lprintf("GameUIManager UpdateStyle tailStyle->%s, topStyle->%s, bEnabledCamera->%s", tailStyle, topStyle, bEnabledCamera)
    -- Tools:DumpTable(self.m_uiStack, "UpdateStyle ui stack", 2, true)
    -- Tools:DumpTable(self.m_uiShow, "UpdateStyle ui show")
    if tailStyle == topStyle and topIndex > 1 and not force then return end

    local camera = self:GetSceneCamera()
    --print("Main Camera ->", camera)
    if not camera then
        -- self:ShowUIBg()
        return
    end

    camera = self:GetSceneCamera()

    local cameraActive = camera.gameObject.activeSelf
    camera.gameObject:SetActive(bEnabledCamera)
    if bEnabledCamera and not self.m_inStack then
        self:AddOverlayUICamera(bRenderStatic)
    elseif not bEnabledCamera and self.m_inStack then
        UnityHelper.RemoveCameraFromCameraStack(self:GetSceneCamera(), self.m_uiCamera)
        UnityHelper.SetCameraRenderType(self.m_uiCamera, 0)
        self.m_inStack = false
        local sprite = UnityHelper.ScreenShot(camera)
        self:ShowUIBg(sprite)
    end

    if bEnabledCamera and (not cameraActive) then EventManager:DispatchEvent("FS_CMD_CAMERA_SHOW") end
end

function GameUIManager:CheckCameraEnable()
    local camera = self:GetSceneCamera()
    local cameraActive = camera.gameObject.activeSelf
    return cameraActive
end

function GameUIManager:InitFloatCanvas(scene)
    local arr = scene:GetRootGameObjects()
    -- print("array length", arr.Length)
    for i = 0, arr.Length-1 do
        self.m_canvas3D = UnityHelper.GetTheChildComponent(arr[i], "Canvas3D", "Canvas")
        if self.m_canvas3D then break end
    end
    -- print("Canvas3D", self.m_canvas3D)
    if not self.m_canvas3D then
        lprintf("Canvas3D is null!")
    end

    self.m_canvas3D.sortingOrder = 1
end

function GameUIManager:GetCanvas3D()
    return self.m_canvas3D
end

function GameUIManager:AddView2Canvas3D(view)
    if self.m_canvas3D then
        local viewGO = view:GetUIObj()
        if viewGO then
            UnityHelper.AddChildToParent(self.m_canvas3D.transform, viewGO.transform)
        end
    end
end

function GameUIManager:SetFloatUILockScale(lock, dis)
    if not self.m_canvas3D then return end
    self.m_canvas3D.gameObject:GetComponent("Canvas3D"):SetLockScale(lock, dis)
    -- self.m_canvas3D.gameObject:GetComponent("Canvas3D").LockScale = lock
end

function GameUIManager:OpenFloatUI(_UIType, _UIView, entity)
    if not self.m_canvas3D then
        lprintf("Open FloatUI Error! Canvas3D is null!")
        return
    end
    -- if not entity then 
    --     lprintf("Open FloatUI '%s' Error! Follow entity is null!", UIConfig[_UIType].res)
    --     return
    -- end

    local co = coroutine.create(function(UIType, view, guid, canvas)
        if not guid then return end
        -- if not entity or entity.gameObject:IsNull() then
        --     return
        -- end

        local cfg = UIConfig[UIType]
        if not cfg then return end

        if ENUM_GAME_UISTYLE.SOLE == cfg.style then
            self:CloseFloatUI(UIType)
        end

        if not view and cfg.class and "" ~= cfg.class then
            view = require(cfg.class).new()
        end

        self.m_resLoaidngCount = (self.m_resLoaidngCount or 0) + 1
        local uiObj = GameResMgr:AInstantiateSync(cfg.res, view)

        if not uiObj or not view then
            --lprintf("Open FloatUI '%s' Error!", cfg.res)
            self:CheckSceneSwitchOnUIComplete(UIType)
            return
        end

        local uiFollow = uiObj:AddComponent(typeof(UIFollow))
        if entity then
            uiFollow.Entity = entity
        end
        -- if the specific canvas changed (scene switch for example), the UI should not be created any more
        if canvas and not canvas:IsNull() then
            UnityHelper.AddChildToParent(self.m_canvas3D.transform, uiObj.transform)
            self:CheckSceneSwitchOnUIComplete(UIType)
        else
            UnityHelper.DestroyGameObject(uiObj)
            self:CheckSceneSwitchOnUIComplete(UIType)
            return
        end

        -- 打开一个新界面
        --print("OpenFloatUI -->", UIType, view)
        self.m_uiFloat[UIType] = self.m_uiFloat[UIType] or {}
        self.m_uiFloat[UIType][guid] = view

        view:SetFloatGuid(guid)
        view:SetUIType(UIType)
        view:SetUIObj(uiObj)
        enableEmmyLuaDebug()
        view:OnEnter()
        view:ClearCmdPool()
        return view
    end)

    self.m_guid = self.m_guid + 1
    table.insert(self.m_waitPool, {
        co = co,
        type = _UIType,
        view = _UIView,
        guid = self.m_guid,
        canvas = self.m_canvas3D,
    })
    return self.m_guid
end

function GameUIManager:CheckSceneSwitchOnUIComplete(UIType)
    -- self.m_resLoaidngCount = self.m_resLoaidngCount - 1
    -- if self.m_waitPoolCB and self.m_resLoaidngCount <= 0 and UIType ~= ENUM_GAME_UITYPE.TOP_SWITCH_SCENE then
    --     self.m_waitPoolCB()
    --     self.m_resLoaidngCount = 0
    -- end
end

function GameUIManager:UpdateFloatUIEntity(view, entity)
    local uiObj = view:GetUIObj()
    if uiObj and entity then
        local uiFollow = uiObj:GetComponent(typeof(UIFollow))
        if uiFollow then
            uiFollow.Entity = entity
        end
    end
end

function GameUIManager:CloseFloatUI(UIType, guid)
    if not UIType then return end

    local data = self.m_uiFloat[UIType]
    if not data then
        lprintf("Close CloseFloatUI Type->{'%s'} GUID->{'%s'} Error!", UIType, guid)
        return
    end

    local view
    local guid = guid
    if guid then
        view = data[guid]
    else
        guid, view = next(data)
    end

    if not view then
        lprintf("Close CloseFloatUI Type->{'%s'} GUID->{'%s'} Error!", UIType, guid)
        return
    end

    view:OnExit()
    GameObject.Destroy(view:GetUIObj())
    GameResMgr:Unload(view)
    data[guid] = nil
    view = nil
end

function GameUIManager:ShowUIBg(sprite)
    self.uiBgObj:SetActive(true)
    if not sprite then return end
    self.imgBg.sprite = sprite
    self.imgBg.color = Color.white
end

function GameUIManager:HideUIBg()
    if self.uiBgObj then
        self.uiBgObj:SetActive(false)
        self.imgBg.color = Color.black
    end
end

function GameUIManager:CloseAllUI(ignoreList)
    local destroyView = {}
    for index = #self.m_uiStack, 1, -1 do
        local view = self.m_uiStack[index]
        local uiType = view:GetUIType()

        local ignored = false
        for k, v in pairs(ignoreList or {}) do
            if v == uiType then
                ignored = true
                break
            end
        end

        if not ignored and view then
            table.insert(destroyView, view)
        end
    end
    for _, view in ipairs(destroyView) do
        view:DestroyModeUIObject(true)
    end
    destroyView = nil
end

function GameUIManager:CloseAllFloatUI()
    for uiType, uiList in pairs(self.m_uiFloat or {}) do
        for guid, view in pairs(uiList or {}) do
            self:CloseFloatUI(uiType, guid)
        end
    end
end

function GameUIManager:Clear()
    print("GameUIManager:Clear", #self.m_uiStack)
    self:CloseAllUI()
    self:CloseAllFloatUI()
end

function GameUIManager:GetSceneCamera()
    if not self.m_camera or self.m_camera:IsNull() then
        local cameraObj = GameObject.Find("Main Camera")
        self.m_camera = cameraObj and cameraObj:GetComponent("Camera")
    end
    return self.m_camera
end

function GameUIManager:GetMasterCanvasObj()
    return self.masterCanvasObj
end

function GameUIManager:AddOverlayUICamera(bRenderStatic)
    UnityHelper.SetCameraRenderType(self.m_uiCamera, 1)
    UnityHelper.AddCameraToCameraStack(self:GetSceneCamera(), self.m_uiCamera)
    self.m_inStack = true
    -- if bRenderStatic then
    --     local sprite = UnityHelper.ScreenShot(camera)
    --     self:ShowUIBg(sprite)
    -- else
    --     self:HideUIBg()     
    -- end
    self:HideUIBg()
end

function GameUIManager:GetCameraStackSize()
    local camera = self:GetSceneCamera()
    if not camera or camera:IsNull() then
        return 999
    end
    return 0 -- 临时修改
    -- local size = UnityHelper.GetCameraStackSize(camera)
    -- return size or 0
end

function GameUIManager:Init()
    print("GameUIManager:Init")
    GameUIManager.m_uiStack = {}
    GameUIManager.m_uiShow = {}
    GameUIManager.m_waitPool = {}
    GameUIManager.m_uiFloat = {}
    GameUIManager.m_guid = 0
    GameUIManager.m_uiCamera = nil
    GameUIManager.m_canvas3D = nil
    GameUIManager.m_inStack = false
    GameUIManager.m_enableTouchGo = nil
    local co = coroutine.create(function()
        local canvasObj = GameObject.Find("UICanvas")
        print("GameUIManager:Init canvasObj", canvasObj)
        if canvasObj then
        else
            canvasObj = GameResMgr:AInstantiateSync("Assets/Resources/Prefabs/UICanvas.prefab")
            canvasObj.name = "UICanvas"
            Object.DontDestroyOnLoad(canvasObj.transform)
        end
        GameUIManager.masterCanvasObj = canvasObj

        -- local splash = GameObject.Find("Splash")
        -- if splash then GameObject.Destroy(splash) end

        GameUIManager.canvasObj = GameObject.Find("NotchFit").gameObject
        -- GameUIManager:FixNotchFit()
        CONST_UI_FIRST_INDEX = GameUIManager.canvasObj.transform.childCount-1
        GameUIManager.imgBg = UnityHelper.GetTheChildComponent(GameUIManager.canvasObj, "UIBGImage", "Image")
        GameUIManager.uiBgObj = GameUIManager.imgBg.gameObject
        GameUIManager.m_uiCamera = UnityHelper.GetTheChildComponent(GameUIManager.masterCanvasObj, "UICamera", "Camera")
        GameUIManager.masterCanvasObj:GetComponent("CanvasScaler").matchWidthOrHeight = GameDeviceManager:IsPadScreenRatio() and 1.0 or 0.0
        GameUIManager.m_enableTouchGo = UnityHelper.FindTheChild(self.masterCanvasObj, "EnableTouch").gameObject
    end)
    assert(coroutine.resume(co))
end

function GameUIManager:FixNotchFit()
    local screen = CS.UnityEngine.Screen
    local safeArea = screen.safeArea
    local transform = self.canvasObj.transform
    local banner = UnityHelper.FindTheChild(GameUIManager.masterCanvasObj, "UIBanner")

    local anchorMin = safeArea.position
    local anchorMax = safeArea.position + safeArea.size
    local offset = 0
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer and anchorMin.y  > 0 then
        offset = anchorMin.y / 2
    end
    anchorMin.x = anchorMin.x / screen.width
    anchorMin.y = offset / screen.height
    anchorMax.x = anchorMax.x / screen.width
    anchorMax.y = anchorMax.y / screen.height
    self.canvasObj.transform.anchorMin = anchorMin
    self.canvasObj.transform.anchorMax = anchorMax

    -- print(string.format("New safe area applied to {%s}: x={%s}, y={%s}, w={%s}, h={%s} on full extents w={%s}, h={%s}", "NotchFit", safeArea.x, safeArea.y, safeArea.width, safeArea.height, screen.width, screen.height))
    local banner = UnityHelper.FindTheChild(GameUIManager.masterCanvasObj, "UIBannerUp")
    local bannerAnchorMin = banner.anchorMin
    bannerAnchorMin.y = anchorMax.y
    banner.anchorMin = bannerAnchorMin
    banner.gameObject:SetActive(true)

    local banner2 = UnityHelper.FindTheChild(GameUIManager.masterCanvasObj, "UIBannerBotton")
    local bannerAnchorMax = banner2.anchorMax
    bannerAnchorMax.y = anchorMin.y
    banner2.anchorMax = bannerAnchorMax
    banner2.gameObject:SetActive(true)
end

function GameUIManager:SetEnableTouch(enable, reason)

    reason = reason or "未知"
    local result = enable == true and "打开" or "关闭"
    printf("界面管理" .. reason .. result)

    if GameUIManager.m_enableTouchGo then
        GameUIManager.m_enableTouchGo:SetActive(not enable)
    end
end

---是否可操作
function GameUIManager:GetEnableTouch()
    if GameUIManager.m_enableTouchGo then
        return not GameUIManager.m_enableTouchGo.activeSelf
    else
        return false
    end
end

function GameUIManager:ChangeCanvas3DCamera(camera)
    if not self.m_canvas3D then
        return
    end
    local canvs3DCom = self.m_canvas3D.gameObject:GetComponent("Canvas3D")
    if not canvs3DCom then
        return
    end
    canvs3DCom:ChangeCanvas3DCamera(camera)
end

function GameUIManager:RestoreCanvas3DCamera()
    if not self.m_canvas3D then
        return
    end
    local canvs3DCom = self.m_canvas3D.gameObject:GetComponent("Canvas3D")
    if not canvs3DCom then
        return
    end
    canvs3DCom:RestoreCanvas3DCamera()
end

if not GameUIManager.canvasObj then
    GameUIManager:Init()
end

EventManager:RegEvent("FS_CMD_UI_UPDATE_CLOSE", function()
    CS.Game.GameLauncher.Instance:Hide()
end)

EventManager:RegEvent("FS_CMD_UI_MANAGER_BG_CLOSE", handler(GameUIManager, GameUIManager.HideUIBg))
