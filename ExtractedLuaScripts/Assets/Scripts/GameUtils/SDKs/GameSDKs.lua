GameSDKs = {}

require("GameUtils.SDKs.WarriorSDK")
local Rapidjson = require("rapidjson")
local EventManager = require("Framework.Event.Manager")

local DeviceUtil = CS.Game.Plat.DeviceUtil
local GameSDKMgr = CS.Game.SDK.SDKManager.Instance
local Application = CS.UnityEngine.Application

local TicketUseUI = GameTableDefine.TicketUseUI
local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local IAP = GameTableDefine.IAP
local CashEarn = GameTableDefine.CashEarn
local ChooseUI = GameTableDefine.ChooseUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local LoadingScreen = GameTableDefine.LoadingScreen
local ActivityUI = GameTableDefine.ActivityUI
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local UnityHelper = CS.Common.Utils.UnityHelper
local GameLauncher = CS.Game.GameLauncher.Instance
local ResMgr = GameTableDefine.ResourceManger
local SeasonPassManager = GameTableDefine.SeasonPassManager
local ClockOutDataManager = GameTableDefine.ClockOutDataManager

local EVNET_HANDLER = {}
local EVNET_SUCCESS_HANDLER = {}
local EVNET_FAIL_HANDLER = {}
local EVNET_REPLAY_HANDLER = {}
local AD_TYPE_REWARD = 1

local MSG_REWARD_FINISHED = "ad_reward_finished"
local MSG_REWARD_START_FAIL = "ad_reward_start_fail"
local MSG_REWARD_START_SUCCESS = "ad_reward_start_success"
local MSG_REWARD_FAILED = "ad_reward_failed"
local MSG_REWARD_SUCCESS = "ad_reward_success"
local MSG_REWARD_NOT_READY = "ad_reward_not_ready"

local MSG_INTER_FINISHED = "ad_inter_finished"
local MSG_INTER_FAILED = "ad_inter_failed"

local MSG_BANNER_FINISHED = "ad_banner_finished"
local MSG_BANNER_FAILED = "ad_banner_failed"

local MSG_NO_INSTALL_QQ = "no_install_qq"

local MSG_IAP_SUCCESS = "fs_iap_buy_product_successful"
-- local MSG_ADD_SUCCESS = "fs_iap_add_product_successful"

local MSG_VIDEO_LIST = "video_list"

local ENTER_BACK_GROUND = "enterBackground"
local ENTER_FORE_GROUND = "enterForeground"

local adName = {}
adName[10001] = "离线3倍奖励"
adName[10002] = "每日广告送钻石"
adName[10003] = "土豪送现金"
adName[10004] = "刷新公司"
adName[10005] = "任务双倍"
adName[10006] = "跳过黑夜"
adName[10007] = "免费引进公司"
adName[10008] = "临时会以"
adName[10009] = "土豪送钻石"
adName[10010] = "土豪送经验"
adName[10011] = "转盘"
local ecpmValue = 0--广告价值
local testGroup = nil
local gameVideoData = nil
--用于埋点的区分对待，是否按地区进行相关信息的埋点和全局属性控制
local track_area_code = {"US"}
--用于地区埋点对应事件对应条件达成时才会上传该埋点，否则不上传该埋点
local track_area_event_condition = {"equipment_upgrade", "cash_event"}

--仅IOS，上传该埋点
local track_ios_event_condition = {"warrior_get_activity_data"}

-- 请求获取存档超时的标记id
GameSDKs.loginLoadDataTimeoutFlag = 0
-- 请求获取存档的次数，请求一次加一次，和超时标记做对应
GameSDKs.loginLoadDateRequesTime = 0
GameSDKs.LoginType = 
{
	tourist		= "1", 	-- warrior 
	facebook 	= "2", 	-- warrior 
	apple 		= "3",  -- warrior 
	google      = "3",  -- warrior
}
GameSDKs.LoginUUID = ""
function GameSDKs:Init()
	local data = LocalDataManager:GetDataByKey("ad_data")
	if data.today == nil then
		data.today = TimerMgr:GetCurrentServerTime()
	end
	if data.totalAdTime == nil then
		data.totalAdTime = 0
	end
	if data.todayAdTime == nil then
		data.todayAdTime = 0
	end

	if data.totalEcpm == nil then
		data.totalEcpm = 0
	end

	if data.firebaseEcpm == nil then
		data.firebaseEcpm = 0
	end

	self:GetGameVideo()

	local today = TimerMgr:GetCurrentServerTime()
	local offset = (ConfigMgr.config_global.reset_time or 5) * 60 * 60
	if os.date("%Y/%m/%d", data.today - offset) ~= os.date("%Y/%m/%d", today - offset) then
		data.today = today
		data.todayAdTime = 0
	end
	LocalDataManager.WriteToFile()
	self:AalibrateTime()
end

function GameSDKs:GetAdName(ad_id)
	return adName[ad_id] or "Empty"
end

function GameSDKs:PlayRewardAd(finishHandler, startSuccessfulHandler, startFailedHandler, ad_id)
	-- 白包
	if GameDeviceManager:IsWhitePackage("ad") and finishHandler then
		finishHandler()
		--调用通行证任务接口，更新任务进度2024-12-23
		GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(1, 1)
		--看广告获取下班打开门票2025-4-1
		GameTableDefine.ClockOutDataManager:AddClockOutTickets(3, 3, ad_id)
		return
	end
	
	-- GameSDKs:TrackForeign("ad_view", {ad_pos = ad_id, state = 1, revenue = 0})

	if ShopManager:IsNoAD() then
		finishHandler()
		--调用通行证任务接口，更新任务进度2024-12-23
		GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(1, 1)
		--看广告获取下班打开门票2025-4-1
		GameTableDefine.ClockOutDataManager:AddClockOutTickets(3, 3, ad_id)
		if startSuccessfulHandler then startSuccessfulHandler() end
		--活跃度--参数填config_activity 的 id
        EventManager:DispatchEvent("WATCH_ADS")
		return
	end

	-- if TicketUseUI:CheckSkipAd(finishHandler, ad_id) then
	-- 	return
	-- end

	if ResMgr:CheckTicket(1) then
        self.adHandler = handler
        self.id = ad_id
        -- TicketUseUI:ShowUseTicketPanel()txt, cb, showCancel, canceCb
        -- ChooseUI:CommonChoose(txt, cb, showCancel, canceCb, extendType, extendNum)--文本, 确定回调, 显示取消按钮, 取消回调, 额外显示的资源和数量，可以为nil
        --使用ChooseUI去完成广告卷的使用2024-7-5
        GameTableDefine.ADChooseUI:CommonChoose("TXT_TIP_AD_TICKET_USE", function()
			ResMgr:SpendTicket(1)
			GameSDKs:TrackForeign("ad_ticket", {behavior = 2, num_new = 1, source = tostring(ad_id)})
            finishHandler()
			--调用通行证任务接口，更新任务进度2024-12-23
			GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(1, 1)
			--看广告获取下班打开门票2025-4-1
			GameTableDefine.ClockOutDataManager:AddClockOutTickets(3, 3, ad_id)
			EventManager:DispatchEvent("WATCH_ADS")
			
        end, true, function()
            self:PlayAd(AD_TYPE_REWARD, finishHandler, startSuccessfulHandler, startFailedHandler, ad_id)
        end, 4, ResMgr:GetTicket())
    else
        self:PlayAd(AD_TYPE_REWARD, finishHandler, startSuccessfulHandler, startFailedHandler, ad_id)
    end

	--GameSDKs:Track("play_video", {video_id = ad_id, ad_type = "激励视频", current_money = GameTableDefine.ResourceManger:GetCash()})
	-- GameSDKs:TrackForeign("ad_view", {ad_pos = ad_id, state = 2, revenue = 0})

	
end

function GameSDKs:PlayAd(type, finishHandler, startSuccessfulHandler, startFailedHandler, ad_id)
	EventManager:DispatchEvent("PLAY_AD")

	local ad_type_name = {[AD_TYPE_REWARD] = "激励视频"}
	EVNET_HANDLER[type] = function()
		-- GameSDKs:Track("end_video", {ad_type = ad_type_name[type], ad_result = "成功", video_id = ad_id, current_money = GameTableDefine.ResourceManger:GetCash()})
		-- GameSDKs:TrackForeign("ad_view", {ad_pos = ad_id, state = 3, revenue = GameSDKs:GetEcpm()})
        EventManager:DispatchEvent("WATCH_ADS")
		EventManager:DispatchEvent("PLAY_AD_END")
		
		if finishHandler then finishHandler() end
		--调用通行证任务接口，更新任务进度2024-12-23
		GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(1, 1)
		--看广告获取下班打开门票2025-4-1
		GameTableDefine.ClockOutDataManager:AddClockOutTickets(3, 3, ad_id)
		GameSDKs:TrackControl("af", "af,adjust_ad_view", {})
	end
	--EVNET_HANDLER[type]()

	--EVNET_SUCCESS_HANDLER[type] = startSuccessfulHandler
	EVNET_SUCCESS_HANDLER[type] = function()
		--GameSDKs:Track("success_video", {video_id = ad_id, ad_type = ad_type_name[type], current_money = GameTableDefine.ResourceManger:GetCash()})
		if startSuccessfulHandler then startSuccessfulHandler() end
	end

	--EVNET_SUCCESS_HANDLER[type]()

	EVNET_REPLAY_HANDLER[type] = function()
		GameSDKMgr:PlayAd(type, tostring(ad_id))
	end
	EVNET_FAIL_HANDLER[type] = function()
		-- GameSDKs:TrackForeign("ad_view", {ad_pos = ad_id, state = 4, revenue = 0})		
		if startFailedHandler then startFailedHandler() end
	end
	GameSDKMgr:PlayAd(type, tostring(ad_id))
end

function GameSDKs:ClearRewardAd()
	EVNET_HANDLER[AD_TYPE_REWARD] = nil
	EVNET_SUCCESS_HANDLER[AD_TYPE_REWARD] = nil
	EVNET_FAIL_HANDLER[AD_TYPE_REWARD] = nil
	EVNET_REPLAY_HANDLER[AD_TYPE_REWARD] = nil
	DeviceUtil.InvokeNativeMethod("ResetShowRewardAd")
end

function GameSDKs:GetEcpm()
	-- print("广告价值" .. ecpmValue)
	return tostring(ecpmValue)
end

function GameSDKs:GetTotalEcpm()
	local data = LocalDataManager:GetDataByKey("ad_data")
	return data.totalEcpm or 0
end

-- function GameSDKs:AdStart(ecpm)
-- 	ecpmValue = ecpm
-- 	GameSDKs:TrackControl("af", "af,af_rv_ad_view", {af_revenue = ecpm})
-- end

function GameSDKs:AdEnd(type, ecpm)
	if EVNET_HANDLER[type] then
		local data = LocalDataManager:GetDataByKey("ad_data")

		-- if ecpm and tonumber(ecpm) then
		-- 	ecpmValue = tonumber(ecpm)
		-- 	data.totalEcpm = data.totalEcpm + ecpmValue
		-- 	data.firebaseEcpm = data.firebaseEcpm + ecpmValue
		-- end
		-- if data.firebaseEcpm > 0.01 then
		-- 	if GameConfig:IsWarriorVersion() then
		-- 		-- GameSDKs:Track("firebase,", {name = "Total_Ads_Revenue", arameter = {currency = "USD",value = data.firebaseEcpm}})
		-- 		print("Total_Ads_Revenue取消瓦瑞尔打点")
		-- 	else
		-- 		GameSDKs:Track("firebase,", {name = "Total_Ads_Revenue_001", arameter = {currency = "USD",value = data.firebaseEcpm}})
		-- 	end
		-- 	data.firebaseEcpm = 0--data.firebaseEcpm - 0.01
		-- end

		EVNET_HANDLER[type]()
		EVNET_HANDLER[type] = nil
		EVNET_FAIL_HANDLER[type] = nil
		--print("广告结束,当前价值" .. ecpm)
		-- data.totalAdTime = data.totalAdTime + 1
		-- data.todayAdTime = data.todayAdTime + 1

		MainUI:RefreshDiamondHint()
		CashEarn:SendEcpmEvent()

		-- event_1	激励视频触发200ecpm或以上ecpm1次	激励视频触发200ecpm或以上ecpm1次
		-- event_2	激励视频触发300ecpm或以上ecpm1次	激励视频触发200ecpm或以上ecpm1次
		-- event_3	激励视频触发500ecpm或以上ecpm1次	激励视频触发200ecpm或以上ecpm1次
		-- event_4	激励广告播放完成18次	玩家完成激励广告播放领取奖励18次即上报
		-- event_5	激励广告播放完12次且其中触发100ecpm4次	激励广告播放完12次且其中触发100ecpm或以上4次
		-- event_6	激励广告播放完12次且其中触发100ecpm2次	激励广告播放完12次且其中触发100ecpm或以上2次
		-- event_7	激励广告播放完12次且其中触发150ecpm2次	激励广告播放完12次且其中触发150ecpm或以上2次
		-- event_8	激励广告播放完12次且其中触发200ecpm1次	激励广告播放完12次且其中触发200ecpm或以上1次
		-- event_9	激励广告播放完12次且其中触发260ecpm1次	激励广告播放完12次且其中触发260ecpm或以上1次
		-- event_10	激励广告播放完12次且其中触发320ecpm2次	激励广告播放完12次且其中触发320ecpm或以上2次
		
		-- if data.totalAdTime == 2 then
		-- 	GameSDKs:Track("reyun,event_0")
		-- else
		-- if data.totalAdTime == 12 then
		-- 	GameSDKs:Track("reyun,event_1")
		-- elseif data.totalAdTime == 14 then
		-- 	GameSDKs:Track("reyun,event_2")
		-- elseif data.totalAdTime == 16 then
		-- 	GameSDKs:Track("reyun,event_3")
		-- else
		-- if data.totalAdTime == 18 then
		-- 	GameSDKs:Track("reyun,event_4")
		-- end

		-- if not data.ecpm then
		-- 	data.ecpm = {}
		-- 	data.ecpm_event = {"1", "2", "3", "5","6","7","8","9","10"}
		-- end
		-- local ecpmKey = {320, 260, 200, 150, 100}
		-- local ecpmNum = math.ceil((tonumber(ecpm) or 0) / 100)
		-- for i,v in ipairs(ecpmKey) do
		-- 	if ecpmNum >= v then
		-- 		local k = tostring(v)
		-- 		data.ecpm[k] = (data.ecpm[k] or 0) + 1
		-- 	end
		-- end
		-- if ecpmNum > 0 then
		-- 	GameSDKs:Track("ad_ecpm", {view_ecpm = ecpmNum})
		-- end
		
		-- print("--------> ecpm event: totalAdTime:", data.totalAdTime, 
		-- 	"ecpm[320]", tostring(data.ecpm["320"]) or "0", 
		-- 	"ecpm[260]", tostring(data.ecpm["260"]) or "0", 
		-- 	"ecpm[200]", tostring(data.ecpm["200"]) or "0", 
		-- 	"ecpm[145]", tostring(data.ecpm["145"]) or "0", 
		-- 	"ecpm[100]", tostring(data.ecpm["100"]) or "0")
		-- if not data.ecpm_event or #data.ecpm_event <= 0 then
		-- 	return
		-- end

		-- local ecpmEvent = {
		-- 		---广告次数 ecpm 达到ecpm次数
		-- 	["1"] = {1, 200, 1},
		-- 	["2"] = {1, 300, 1},
		-- 	["3"] = {1, 500, 1},
		-- 	["5"] = {12, 100, 4},
		-- 	["6"] = {12, 100, 2},
		-- 	["7"] = {12, 150, 2},
		-- 	["8"] = {12, 200, 1},
		-- 	["9"] = {12, 260, 1},
		-- 	["10"] = {12, 320, 2},
		-- }
		--print("--------> ecpm event: ecpm_event size1: ", #data.ecpm_event)
		-- local completed = true
		-- for i,e in ipairs(data.ecpm_event or {}) do
		-- 	if e ~= "" then
		-- 		local event = ecpmEvent[e]
		-- 		local k = tostring(event[2])
		-- 		if data.ecpm[k] and data.ecpm[k] >= event[3] and data.totalAdTime >= event[1] then
		-- 			GameSDKs:Track("reyun,event_"..e)
		-- 			data.ecpm_event[i] = ""
		-- 		end
		-- 		completed = false
		-- 	end
		-- end 
		--print("--------> ecpm event: ecpm_event size2: ", #data.ecpm_event)
		-- if completed then
		-- 	data.ecpm_event = nil
		-- end
		-- LocalDataManager:WriteToFile()
	end
end

function GameSDKs:AdStartResult(type, isSuccess, code, ecpm)
	local handler = isSuccess and EVNET_SUCCESS_HANDLER  or EVNET_FAIL_HANDLER
	if handler[type] then
		handler[type]()
		handler[type] = nil
		EVNET_REPLAY_HANDLER[type] = nil
		if code then
			EventManager:DispatchEvent("UI_NOTE", string.format(GameTextLoader:ReadText("TXT_TIP_AD_ERROR"), code))
		end
		if ecpm and tonumber(ecpm) then
			ecpmValue = ecpm
		end
	end
end

function GameSDKs:RePlayAd(type)
	if EVNET_REPLAY_HANDLER[type] then
		EVNET_REPLAY_HANDLER[type]()
		EVNET_REPLAY_HANDLER[type] = nil
	end
end

function GameSDKs:TrackForeign(event, properties)
	if GameDeviceManager:IsWhitePackage() then
		return
	end
	if GameConfig:IsWarriorVersion() and ((string.find(event, "login") and properties.login_result ~= 999) or event == "purchase" or string.find(event, "enter_game_check")) then
		return
	end

	if not GameDeviceManager:IsiOSDevice() and Tools:CheckContain(event, track_ios_event_condition) then
		return
	end
	
	local isUseArea = false 
	local getCode = ""
	if GameDeviceManager:IsiOSDevice() or GameDeviceManager:IsAndroidDevice() then
		getCode = DeviceUtil.GetCountryCodeAnalysis() or ""
	end
	for k, v in pairs(track_area_code) do
		if string.find(getCode, v) then
			isUseArea = true
			break
		end
	end
	local checkEventArea = false

	for _, evValue in pairs(track_area_event_condition) do
		if checkEventArea then
			break
		end
		if string.find(event, evValue) then
			checkEventArea = true
		end
	end

	if checkEventArea and not isUseArea then
		--地区检测事件，但是不在地区设置中，直接不传该事件
		return
	end

	--gxy 添加通用埋点信息
	if ConfigLoadOver then
		local record = LocalDataManager:GetRootRecord() and LocalDataManager:GetCurrentRecord()
		if record and record.resource then
			-- local commonProp = {}
			-- local curBuilding = GameTableDefine.CityMode:GetCurrentBuilding()
			-- commonProp.scene_id = curBuilding
			-- commonProp.star_num = GameTableDefine.StarMode:GetStar()
			-- commonProp.diamond_num = GameTableDefine.ResourceManger:GetDiamond()
			-- --2024-8-15副本场景中产生的埋点需要添加公共数据
			-- if GameStateManager:CheckStateIsCurrentState(GameStateManager.GAME_STATE_CYCLE_INSTANCE) then

			-- 	-- 	local roomID = maxRoomData.roomID
			-- 	-- local furLevelConfig = self:GetFurlevelConfigByRoomFurIndex(roomID,1)
			-- 	-- local furLevel = furLevelConfig and furLevelConfig.level or 1
			-- 	-- local heroID = self.roomsConfig[roomID].hero_id
			-- 	-- local heroLevel = CycleIslandHeroManager:GetHeroData(heroID).level
			-- 	local skillData = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurSkillData()

			-- 	--當前技能等級
			-- 	commonProp.cy_skill_level_1 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[1]).skill_level)
			-- 	commonProp.cy_skill_level_2 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[2]).skill_level)
			-- 	commonProp.cy_skill_level_3 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[3]).skill_level)
			-- 	--当前所有房间的等级以及英雄等级
			-- 	for key, v in pairs(GameTableDefine.CycleInstanceDataManager:GetCurrentModel().roomsConfig or {}) do
			-- 		if v.room_category == 1 then
			-- 			commonProp["cy_fur_level_"..tostring(v.id)], commonProp["cy_hero_level_"..tostring(v.id)] = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetRoomLevelAndHeroLevel(v.id, v.hero_id)
			-- 		end
			-- 	end
			-- 	commonProp.cy_mile_level = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel())
			-- 	commonProp.cy_coin_num = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurSlotCoin())
			-- 	commonProp.cy_slot_level = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotMachineLevel())
			-- 	commonProp.cy_slot_time = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotPushNum())
			-- 	commonProp.cy_slot_time_value = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotPushNumRotio())

			-- 	local currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
			-- 	--蓝图碎片
			-- 	if currentModel.instance_id == 6 or currentModel.instance_id == 7 then
			-- 		commonProp.cy_bp_store = currentModel:GetBluePrintManager():GetResCountRevertToBase()
			-- 		--printf("埋点,换算为基础蓝图碎片数"..commonProp.cy_bp_store)
			-- 	end

			-- 	--2024-10-31 排行榜添加公共数据， 2025-04-17转到只在副本上报
			-- 	local rankManagerClass = currentModel:GetRankManager()
			-- 	if rankManagerClass then
			-- 		commonProp.cy_rank_score = rankManagerClass:GetUserHistorySlotCoin() -- 当前副本内积分值
			-- 		commonProp.cy_rank_group = rankManagerClass:GetRankGroupKey() -- 当前副本内分组
			-- 		commonProp.cy_rank_num = rankManagerClass:GetRankNum() -- 当前副本内排名
			-- 	end

			-- 	--2025-4-17 增加全局事件tag
			-- 	commonProp.cy_tag = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurInstanceTag()
			-- end
			-- --2025-3-5 ceo相关的全局属性上报
			-- commonProp.normal_key_num = GameTableDefine.CEODataManager:GetKeysData("normal", 1)
			-- commonProp.premium_key_num = GameTableDefine.CEODataManager:GetKeysData("premium", 1)
			-- commonProp.normal_key_total_num = GameTableDefine.CEODataManager:GetKeysData("normal", 2)
			-- commonProp.premium_key_total_num = GameTableDefine.CEODataManager:GetKeysData("premium", 2)
			-- commonProp.normal_ceo_num = GameTableDefine.CEODataManager:GetCEOData("normal", 1)
			-- commonProp.premium_ceo_num = GameTableDefine.CEODataManager:GetCEOData("premium", 1)
			-- commonProp.normal_card_num = GameTableDefine.CEODataManager:GetCEOData("normal", 2)
			-- commonProp.premium_card_num = GameTableDefine.CEODataManager:GetCEOData("premium", 2)
			
			-- if isUseArea then
			-- 	commonProp.cash_1_num = tonumber(GameTableDefine.ResourceManger:GetCash())
			-- 	commonProp.cash_1_eff = tonumber(GameTableDefine.FloorMode:GetTotalRent(nil, 1) * 2)
			-- 	if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
			-- 		commonProp.cash_2_num = tonumber(GameTableDefine.ResourceManger:GetEuro())
			-- 		commonProp.cash_2_eff = tonumber(GameTableDefine.FloorMode:GetTotalRent(nil, 2) * 2)
			-- 	end
			-- 	-- LocalDataManager:GetDataByKey("UpgradeFurTotalCash")
			-- 	if record and record.UpgradeFurTotalCash and record.UpgradeFurTotalCash.total then
			-- 		commonProp.cash_1_cost = record.UpgradeFurTotalCash.total
			-- 	end

			-- 	--2025-1-21
			-- 	if record and record.UpgradeFurTotalDiamond and record.UpgradeFurTotalDiamond.total then
			-- 		commonProp.diamond_1_cost = record.UpgradeFurTotalDiamond.total
			-- 	end
			-- end

			-- --2024-12-31 fy添加用于通行证期间的全局属性添加
			-- if GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
			-- 	local pass_ticket_total = GameTableDefine.CoinPusherManager:GetTotalTicket()
			-- 	local pass_draw_total = GameTableDefine.CoinPusherManager:GetTotalPlayTime()
			-- 	local pass_point_total = GameTableDefine.CoinPusherManager:GetPointAndLevel()
			-- 	local pass_exp_total = GameTableDefine.SeasonPassManager:GetTotalExp()
			-- 	commonProp.pass_ticket_total = pass_ticket_total
			-- 	commonProp.pass_draw_total = pass_draw_total
			-- 	commonProp.pass_point_total = pass_point_total
			-- 	commonProp.pass_exp_total = pass_exp_total
			-- end

			-- --2025-4-7 增加全局事件属性分组
			-- local remoteConfigData = LocalDataManager:GetRemoteConfigData()
			-- commonProp.remote_group = remoteConfigData.group
			
			local newCommonProp = GameSDKs:GetTrackPlayerCommonAttr(isUseArea)
			local commonPropJson = nil
			if newCommonProp and type(newCommonProp) == "table" and Tools:GetTableSize(newCommonProp) > 0 then
				commonPropJson = Rapidjson.encode(newCommonProp)
			end
			print("warrior埋点调试(公共参数):", commonPropJson)
			DeviceUtil.SetCommonProperties(commonPropJson)
		end
	end

	if GameConfig:IsIAP() then
		local realEvent = "wa," .. event
		local json = nil

		if GameConfig:IsLeyoHKVersion() then
			if event == "purchase" then
				local num,_,__ = IAP:GetPriceDoubleByPurchaseId(properties.product_id)
				properties.huobi_jine = tonumber(num)
				properties.huobi_zhonglei = IAP:GetPriceCode()
			elseif event == "wheel_use" then
				properties.state_choujiang = properties.state
				properties.state = nil
			elseif event == "growth_fund" then
				properties.jijin_id = properties.id
				properties.id = nil
			end
		end
		if properties and type(properties) == "table" and Tools:GetTableSize(properties) > 0 then
			json = Rapidjson.encode(properties)
		end

		local toShow = json and json or " "
		print("warrior埋点调试:", realEvent, toShow)

		GameSDKMgr:Track(realEvent, json)
	end
end

--[[
    @desc: 获取玩家的上报的公共属性埋点
    author:{author}
    time:2025-05-06 19:17:21
    @return:
]]
function GameSDKs:GetTrackPlayerCommonAttr(isUseArea)

	if ConfigLoadOver then
		local record = LocalDataManager:GetRootRecord() and LocalDataManager:GetCurrentRecord()
		if record and record.resource then
			local commonProp = {}
			local curBuilding = GameTableDefine.CityMode:GetCurrentBuilding()
			commonProp.scene_id = curBuilding
			commonProp.star_num = GameTableDefine.StarMode:GetStar()
			commonProp.diamond_num = GameTableDefine.ResourceManger:GetDiamond()
			--2024-8-15副本场景中产生的埋点需要添加公共数据
			if GameStateManager:CheckStateIsCurrentState(GameStateManager.GAME_STATE_CYCLE_INSTANCE) then

				-- 	local roomID = maxRoomData.roomID
				-- local furLevelConfig = self:GetFurlevelConfigByRoomFurIndex(roomID,1)
				-- local furLevel = furLevelConfig and furLevelConfig.level or 1
				-- local heroID = self.roomsConfig[roomID].hero_id
				-- local heroLevel = CycleIslandHeroManager:GetHeroData(heroID).level
				local skillData = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurSkillData()

				--當前技能等級
				commonProp.cy_skill_level_1 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[1]).skill_level)
				commonProp.cy_skill_level_2 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[2]).skill_level)
				commonProp.cy_skill_level_3 = tonumber(GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[3]).skill_level)
				--当前所有房间的等级以及英雄等级
				for key, v in pairs(GameTableDefine.CycleInstanceDataManager:GetCurrentModel().roomsConfig or {}) do
					if v.room_category == 1 then
						commonProp["cy_fur_level_"..tostring(v.id)], commonProp["cy_hero_level_"..tostring(v.id)] = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetRoomLevelAndHeroLevel(v.id, v.hero_id)
					end
				end
				commonProp.cy_mile_level = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel())
				commonProp.cy_coin_num = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurSlotCoin())
				commonProp.cy_slot_level = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotMachineLevel())
				commonProp.cy_slot_time = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotPushNum())
				commonProp.cy_slot_time_value = tonumber(GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetSlotPushNumRotio())

				local currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
				--蓝图碎片
				if currentModel.instance_id == 6 or currentModel.instance_id == 7 then
					commonProp.cy_bp_store = currentModel:GetBluePrintManager():GetResCountRevertToBase()
					--printf("埋点,换算为基础蓝图碎片数"..commonProp.cy_bp_store)
				end

				--2024-10-31 排行榜添加公共数据， 2025-04-17转到只在副本上报
				local rankManagerClass = currentModel:GetRankManager()
				if rankManagerClass then
					commonProp.cy_rank_score = rankManagerClass:GetUserHistorySlotCoin() -- 当前副本内积分值
					commonProp.cy_rank_group = rankManagerClass:GetRankGroupKey() -- 当前副本内分组
					commonProp.cy_rank_num = rankManagerClass:GetRankNum() -- 当前副本内排名
				end
			end
			local cyModel = GameTableDefine.CycleInstanceDataManager:GetTrackUseCurrentModel()
			if cyModel then
				--2025-4-17 增加全局事件tag2025-5-8不在副本场景中时这个属性也要上传
				commonProp.cy_tag = cyModel:GetCurInstanceTag()
			end
			--2025-3-5 ceo相关的全局属性上报
			commonProp.normal_key_num = GameTableDefine.CEODataManager:GetKeysData("normal", 1)
			commonProp.premium_key_num = GameTableDefine.CEODataManager:GetKeysData("premium", 1)
			commonProp.normal_key_total_num = GameTableDefine.CEODataManager:GetKeysData("normal", 2)
			commonProp.premium_key_total_num = GameTableDefine.CEODataManager:GetKeysData("premium", 2)
			commonProp.normal_ceo_num = GameTableDefine.CEODataManager:GetCEOData("normal", 1)
			commonProp.premium_ceo_num = GameTableDefine.CEODataManager:GetCEOData("premium", 1)
			commonProp.normal_card_num = GameTableDefine.CEODataManager:GetCEOData("normal", 2)
			commonProp.premium_card_num = GameTableDefine.CEODataManager:GetCEOData("premium", 2)
			
			if isUseArea then
				commonProp.cash_1_num = tonumber(GameTableDefine.ResourceManger:GetCash())
				commonProp.cash_1_eff = tonumber(GameTableDefine.FloorMode:GetTotalRent(nil, 1) * 2)
				if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
					commonProp.cash_2_num = tonumber(GameTableDefine.ResourceManger:GetEuro())
					commonProp.cash_2_eff = tonumber(GameTableDefine.FloorMode:GetTotalRent(nil, 2) * 2)
				end
				-- LocalDataManager:GetDataByKey("UpgradeFurTotalCash")
				if record and record.UpgradeFurTotalCash and record.UpgradeFurTotalCash.total then
					commonProp.cash_1_cost = record.UpgradeFurTotalCash.total
				end

				--2025-1-21
				if record and record.UpgradeFurTotalDiamond and record.UpgradeFurTotalDiamond.total then
					commonProp.diamond_1_cost = record.UpgradeFurTotalDiamond.total
				end
			end

			--2024-12-31 fy添加用于通行证期间的全局属性添加
			if GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
				local pass_ticket_total = GameTableDefine.CoinPusherManager:GetTotalTicket()
				local pass_draw_total = GameTableDefine.CoinPusherManager:GetTotalPlayTime()
				local pass_point_total = GameTableDefine.CoinPusherManager:GetPointAndLevel()
				local pass_exp_total = GameTableDefine.SeasonPassManager:GetTotalExp()
				commonProp.pass_ticket_total = pass_ticket_total
				commonProp.pass_draw_total = pass_draw_total
				commonProp.pass_point_total = pass_point_total
				commonProp.pass_exp_total = pass_exp_total
			end

			--2025-4-7 增加全局事件属性分组
			local remoteConfigData = LocalDataManager:GetRemoteConfigData()
			commonProp.remote_group = remoteConfigData.group
			commonProp.clockout_tag = GameTableDefine.ClockOutDataManager:GetClockOutGroup()
			return commonProp
			-- local commonPropJson = nil
			-- if commonProp and type(commonProp) == "table" and Tools:GetTableSize(commonProp) > 0 then
			-- 	commonPropJson = Rapidjson.encode(commonProp)
			-- end
			-- print("warrior埋点调试(公共参数):", commonPropJson)
			-- DeviceUtil.SetCommonProperties(commonPropJson);
		end
	end
	return {}
end

--[[
    @desc: 新增运营需求adjust打点，并且需要进行数据保存的相关检测的
    author:{author}
    time:2024-09-13 16:38:10
    --@typeNane:
	--@event:
	--@properties: 
    @return:
]]
function GameSDKs:TrackControlCheckData(typeName, event, properties)
	local checkEvent = {}
	checkEvent["af,corp_rent_10"] = 10
	checkEvent["af,corp_upgrade_10"] = 10
	checkEvent["af,corp_renew_2"] = 2
	checkEvent["af,corp_refresh_1"] = 1
	checkEvent["af,build_upgrade_1009_1"] = 1
	checkEvent["af,equip_upgrade_diamond_1"] = 1

	if not checkEvent[event] then
		return
	end
	
	local adjustSaveData = LocalDataManager:GetDataByKey("adjust_game_data")
	if not adjustSaveData[event] then
		adjustSaveData[event] = 1
	else
		adjustSaveData[event]  = adjustSaveData[event] + 1
	end
	if adjustSaveData[event] == checkEvent[event] then
		self:TrackControl(typeName, event, properties)
	end
end

function GameSDKs:TrackControl(typeName, event, properties)
	if GameDeviceManager:IsWhitePackage() then
		return
	end
	if GameConfig:IsWarriorVersion() and (string.find(event, "login") or string.find(event, "purchase")) then
		return
	end
	if typeName == "af" then
		if not GameConfig:IsIAP() then
			return
		end
	end

	local json = nil
	properties = properties or {}
	if properties and type(properties) == "table" and Tools:GetTableSize(properties) > 0 then
		json = Rapidjson.encode(properties)
	end

	local toShow = json and json or " "
	print(typeName .. "埋点调试:" .. event .. toShow)

	GameSDKMgr:Track(event, json)
end

function GameSDKs:Track(event, properties) 
	if GameDeviceManager:IsWhitePackage() then
		return
	end
	if GameConfig:IsWarriorVersion() and (string.find(event, "login") or string.find(event, "purchase")) then
		return
	end

	local json = nil
	if GameTableDefine.ConfigMgr.config_global.enable_iap == 1 then
		properties = properties or {}
	end
	-- if properties and type(properties) == "table" then
	-- 	properties.eventId = event
	-- 	properties.ABT = "ABT.v" .. Application.version .. "." .. self:GetTestGroupId()
	-- end
	if properties and type(properties) == "table" and Tools:GetTableSize(properties) > 0 then
		json = Rapidjson.encode(properties)
	end
	
	local toShow = json and json or " "
	-- print("埋点调试:",event, string.find(event, ","), toShow)
	if GameConfig.IsIAP() and string.find(event, ",") == nil then
		GameSDKMgr:Track("wa," .. event, json)--warrior也要以前的
	else
		GameSDKMgr:Track(event, json)
	end
end

function GameSDKs:ReportException(id, time, content)
	GameSDKMgr:ReportException(id, time, content)
end

function GameSDKs:JumpQQGroup()
	--发起添加群流程。群号：物业大亨游戏交流群(547058561) 的 key 为： hzAEKXJeRDwtD_-BOll57YEKuS-VQuCg
	local qqGroup = "hzAEKXJeRDwtD_-BOll57YEKuS-VQuCg"
	GameSDKMgr:JumpQQGroup(qqGroup)
end

function GameSDKs:Wechat_Login()
	local data = LocalDataManager:GetDataByKey("user_data")
    if data.wechat_id and data.user_id then
        GameTableDefine.CloudStorageUI:ShowPanel()
        return
    end
    -- GameNetwork:HTTP_WechatLogin("051qLAll2ul8D74gi4ol2wdd3r2qLAli")
    DeviceUtil.WechatLogin()
end

function GameSDKs:Wechat_Share(shareType, shareUrl, shareTitle, shareDesc)
    DeviceUtil.WechatShare(shareType, shareUrl, shareTitle, shareDesc)
end

function GameSDKs:SignInWithApple_Login()
    DeviceUtil.SignInWithApple()
end

function GameSDKs:AntiAddiction(name, idNum)
    DeviceUtil.AntiAddiction(name, idNum)
end

function GameSDKs:AalibrateTime()
    if not DeviceUtil.AalibrateTime then
        return
    end
    GameTimeManager:GetNetWorkTime(function(time)
        if time > 0 then
            if GameConfig:IsWarriorVersion() then
                time = math.ceil(time / 1000)
            end
            DeviceUtil.AalibrateTime(time)	-- 这个方法现在在And和IOS中没有具体的实现, 是空方法
        end
    end)
end

function GameSDKs:Facebook_Login()
    local data = LocalDataManager:GetDataByKey("user_data")
    if data.fb_id then
        GameTableDefine.CloudStorageUI:ShowPanel()
        return
    end
    -- GameSDKs:HTTP_FacebookLogin("051qLAll2ul8D74gi4ol2wdd3r2qLAli")
    DeviceUtil.FaceBookLogin()
end

function GameSDKs:GetGameVideo()
    if gameVideoData == nil then
        DeviceUtil.InvokeNativeMethod("VideoLists")
    end

    return gameVideoData
end

function GameSDKs:PlayGameVideo(gameName, videoUrl)
    DeviceUtil.InvokeNativeMethod("PlayVideo", gameName, videoUrl)
end

function GameSDKs:OnReciveAndroidMsg(message)
    print("OnReciveAndroidMsg:", message)
    -- if message == MSG_REWARD_FINISHED then
    -- 	self:AdEnd(AD_TYPE_REWARD)
    -- else
    if message == MSG_REWARD_START_SUCCESS then
        --self:AdStartResult(AD_TYPE_REWARD, true)
    elseif message == MSG_REWARD_START_FAIL then
        self:AdStartResult(AD_TYPE_REWARD, false)
    elseif message == MSG_REWARD_FAILED then
        EVNET_HANDLER[AD_TYPE_REWARD] = nil
        if EVNET_FAIL_HANDLER[AD_TYPE_REWARD] then
            EVNET_FAIL_HANDLER[AD_TYPE_REWARD]()
            EVNET_FAIL_HANDLER[AD_TYPE_REWARD] = nil
        end
    elseif message == MSG_REWARD_SUCCESS then
        self:RePlayAd(AD_TYPE_REWARD)
    elseif message == MSG_NO_INSTALL_QQ then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_QQ_FAILED"))
    elseif message == "MSG_ANTIADDITON_ADULT" then -- 成年
    elseif message == "MSG_ANTIADDITON_NONAGE" then -- 未成年
    else
        local data = Rapidjson.decode(message) or {}
		if data.wechatLoginComplete then
			self:HTTP_WechatLogin(data.code)
			GameSDKs:TrackForeign("login", { login_type = "wechat", login_result = 1 })
		elseif data.FacebookUserId then
			self:HTTP_FacebookLogin(data.FacebookUserId)
			GameSDKs:TrackForeign("login", { login_type = "facebook", login_result = 1 })
		elseif data[MSG_REWARD_FINISHED] then
			self:AdEnd(AD_TYPE_REWARD, data[MSG_REWARD_FINISHED])
		elseif data[MSG_IAP_SUCCESS] ~= nil then --支付成功的回调
			local shopId = IAP:ShopIdFromProductId(data.productId)
			if shopId then
				local shopCfg = ConfigMgr.config_shop[shopId]
				if shopCfg and shopCfg.type == 17 then
					GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 0, order_state_desc = "接收SDK成功回调：" .. (message or "")})
				end
			end

			IAP:PurchaseResult(data)
			-- elseif data[MSG_ADD_SUCCESS] then --补单
			-- 	IAP:SetSerialData(data.data)
		elseif data.WarriorLoginInfo then
			if data.WarriorLoginInfo.warrior_login_user_id then
				self:Warrior_loginCallBack(data.WarriorLoginInfo.warrior_login_user_id)
			else
				self:Warrior_loginCallBack(nil, data.WarriorLoginInfo.warrior_login_error_code)
			end
			if data.WarriorLoginInfo.warrior_login_uuid then
				self.LoginUUID = data.WarriorLoginInfo.warrior_login_uuid
			end
			-- 时间管理初始化
			if data.WarriorLoginInfo.warrior_login_time then
				GameTimeManager:Init(data.WarriorLoginInfo.warrior_login_time)
			end
		elseif data.WarriorSDKAPI then
			GameSDKs:Warrior_response(data.WarriorSDKAPI)
		elseif data.iap_price then
			IAP:SetPrice(data.iap_price)
		elseif data[MSG_REWARD_START_SUCCESS] then
			self:AdStartResult(AD_TYPE_REWARD, true, nil, data[MSG_REWARD_START_SUCCESS])
		elseif data[MSG_VIDEO_LIST] then
			gameVideoData = data[MSG_VIDEO_LIST]

			-- leyo HK
		elseif data.LeyoHK_LoginInfo or data.LeyoHK_LoginInfo == false then
			if not data.LeyoHK_LoginInfo then
				self:LeyoHKCallBack()
			else
				self:LeyoHKCallBack(data.LeyoHK_LoginInfo.login_user_id, data.LeyoHK_LoginInfo.login_token)
			end
		elseif data.WarriorNoticeData then
			--TODO:处理公告的回调
			--json：数据格式
			GameTableDefine.BoardUI:WarriorNoticeCallback(data.WarriorNoticeData)
		elseif data.WarriorActivityData then
			if not LocalDataManager:IsNewPlayerRecord() then
				--TODO:处理活动返回的数据
				--joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
				ShopManager:CheckResetDoubleDiamond(data.WarriorActivityData)
				--K119 累充活动开启方式更改
				--AccumulatedChargeActivityDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
				--碎片活动
				TimeLimitedActivitiesManager:GetTLASDKCfg(data.WarriorActivityData)
				--老副本(已经不存在老副本了)
				--GameTableDefine.InstanceDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
				--循环副本
				GameTableDefine.CycleInstanceDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
				--print(data.WarriorActivityData)
				--赛季通行证
				SeasonPassManager:ProcessSDKCallbackData(data.WarriorActivityData)
				--2025-3-27fy下班打卡
				ClockOutDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
			end
		elseif data.WarriorBindInfo then
			--绑定账号的回调
			if data.WarriorBindInfo.warrior_bind_uuid then
				self.LoginUUID = data.WarriorBindInfo.warrior_bind_uuid
			end
			self:Warrior_bindingAccCallBack(data.WarriorBindInfo)
		elseif data.queryOrderInfo then
			--if UnityHelper.IsRuassionVersion() then
			--	--俄区新支付sdk查询返回	2023-11-3
			--end
			-- GameTableDefine.SettingUI:OnCheckRussionPurchaseCallback(data.queryOrderInfo.query_order_successful, data.queryOrderInfo.serialId, data.queryOrderInfo.productId)
			GameTableDefine.MainUI:OnInitQueryOrderCallback(data.queryOrderInfo.query_order_successful,
					data.queryOrderInfo.data, data.queryOrderInfo.type)
		elseif data.replenishOrderInfo then
			--if UnityHelper.IsRuassionVersion() then
			--end
			-- GameTableDefine.SettingUI:OnRestorePurchaseCallback(data.replenishOrderInfo.fs_iap_buy_product_successful, data.replenishOrderInfo.productId, data.replenishOrderInfo.type)
			GameTableDefine.MainUI:OnRestorePurchaseCallback(data.replenishOrderInfo.fs_iap_buy_product_successful,
					data.replenishOrderInfo.productId, data.replenishOrderInfo.serialId, data.replenishOrderInfo.type, data.replenishOrderInfo.extra)
		elseif data.WarriorGiftPackData then
			--限时礼包和累充活动
			--K119 累充活动改为由此开启
			local limitPackData = nil
			for i = 1, #data.WarriorGiftPackData do
				local packData = data.WarriorGiftPackData[i]

				if packData.type == TimeLimitedActivitiesManager.GiftPackType.LimitPack then
					limitPackData = packData
				elseif packData.type == TimeLimitedActivitiesManager.GiftPackType.AccumulatedCharge then
					AccumulatedChargeActivityDataManager:ProcessSDKCallbackData(packData)
				elseif packData.type == TimeLimitedActivitiesManager.GiftPackType.LimitChoose then
					GameTableDefine.TimeLimitedActivitiesManager:EnableLimitChooseActivityFromSDK(packData)
				else
					if packData.type then
						printError("WarriorGiftPackData : 未知活动类型" .. packData.type)
					else
						printError("WarriorGiftPackData : 未设置活动类型 nil")
					end
				end
			end

			if limitPackData then
				local dataSize = Tools:GetTableSize(limitPackData.sub_gift)
				if dataSize == 2 then
					GameTableDefine.TimeLimitedActivitiesManager:EnableLimitPackActivityFromSDK(limitPackData)
				elseif dataSize > 2 then
					GameTableDefine.TimeLimitedActivitiesManager:EnableLimitPackActivityFromSDK(limitPackData)
					printError("WarriorGiftPackData : LimitPack 超过支持上限，只支持2个配置")
				elseif dataSize < 2 then
					printError("WarriorGiftPackData : LimitPack 配置数不足2个无法开启活动,只支持2个配置")
				end
			end
		elseif data.notificationState then
			GameStateManager:SendNotificationStateTrackForeign(data.notificationState.is_open)
		elseif message == ENTER_BACK_GROUND then
			GameTableDefine.OfflineManager:OnPause(true)
		elseif data.remoteConfig then
			--"remoteConfig": {
			--"state": 2, -- 1是请求, 2是收到结果
			--"value": "test2",
			--"duration": 1150,
			--"end_time": 1738831938, -1为异常, 0为默认分组需请求活动
			--}
			if data.remoteConfig.state == 2 then
				-- 根据返回结果保存结束时间,在范围内则保存
				local now = GameTimeManager:GetCurLocalTime(true)
				local remoteConfigData = LocalDataManager:GetRemoteConfigData()
				if now < (data.remoteConfig.end_time) then
					remoteConfigData.endTime = data.remoteConfig.end_time
					ConfigMgr:SetCorrectlyGroupedMark(true)
				else
					if data.remoteConfig.end_time == 0 then
						ConfigMgr:SetCorrectlyGroupedMark(true)
					else
						ConfigMgr:SetCorrectlyGroupedMark(false)
					end
				end
				ConfigMgr:CheckABTestConfig(data.remoteConfig.value)
				ConfigMgr:LoadConfigByGroup()

				GameSDKs:TrackForeign("remote_config", {
					state = data.remoteConfig.state,
					result = remoteConfigData.group,
					value = data.remoteConfig.value,
					duration = data.remoteConfig.duration,
					endtimestamp = data.remoteConfig.end_time
			})
		end
		end
		
    end
end

function GameSDKs:OnReciveIOSMsg(message)
    print("OnReciveiOSdMsg:", message)
    local data = Tools:SplitEx(message, ",");
    local source = data[1];
    local code = data[2];
    local content = data[3];
    if source == MSG_REWARD_FINISHED then
        self:AdEnd(AD_TYPE_REWARD, code)
    elseif source == MSG_REWARD_START_SUCCESS then
        self:AdStartResult(AD_TYPE_REWARD, true)
    elseif source == MSG_REWARD_START_FAIL then
        self:AdStartResult(AD_TYPE_REWARD, false, code)
    elseif message == MSG_REWARD_FAILED then
        EVNET_HANDLER[AD_TYPE_REWARD] = nil
        if EVNET_FAIL_HANDLER[AD_TYPE_REWARD] then
            EVNET_FAIL_HANDLER[AD_TYPE_REWARD]()
            EVNET_FAIL_HANDLER[AD_TYPE_REWARD] = nil
        end
    elseif message == MSG_REWARD_SUCCESS then
        self:RePlayAd(AD_TYPE_REWARD)
    elseif message == "MSG_ANTIADDITON_ADULT" then -- 成年
    elseif message == "MSG_ANTIADDITON_NONAGE" then -- 未成年
    elseif source == "WeChatLogin" and (content ~= nil or content ~= "") then
        self:HTTP_WechatLogin(content)
    else
        local data = Rapidjson.decode(message) or {}
        -- Tools:DumpTable(data, "data")
        if data[MSG_REWARD_FINISHED] then
            self:AdEnd(AD_TYPE_REWARD, data[MSG_REWARD_FINISHED])
        elseif data.fs_iap_buy_product_successful ~= nil then --支付成功的回调
            IAP:PurchaseResult(data)
        elseif data.WarriorLoginInfo then
            if data.WarriorLoginInfo.warrior_login_user_id then
                data.WarriorLoginInfo.warrior_login_user_id = tostring(data.WarriorLoginInfo.warrior_login_user_id)
                self:Warrior_loginCallBack(data.WarriorLoginInfo.warrior_login_user_id)
            else
                self:Warrior_loginCallBack(nil, data.WarriorLoginInfo.warrior_login_error_code)
            end
			if data.WarriorLoginInfo.warrior_login_time then
				GameTimeManager:Init(data.WarriorLoginInfo.warrior_login_time)
			end
            -- data.WarriorLoginInfo.warrior_login_user_id = tostring(data.WarriorLoginInfo.warrior_login_user_id)
            -- self:WarriorLoginCallBack(data.WarriorLoginInfo.warrior_login_user_id, data.WarriorLoginInfo.warrior_login_token)
        elseif data.iap_price then
            IAP:SetPrice(data.iap_price)
            -- elseif data[MSG_REWARD_START_SUCCESS] then
            -- 	self:AdStartResult(AD_TYPE_REWARD, true, nil, data[MSG_REWARD_START_SUCCESS])

            -- leyo HK
        elseif data.LeyoHK_LoginInfo or data.LeyoHK_LoginInfo == false then
            if not data.LeyoHK_LoginInfo then
                self:LeyoHKCallBack()
            else
                self:LeyoHKCallBack(data.LeyoHK_LoginInfo.login_user_id, data.LeyoHK_LoginInfo.login_token)
            end
        elseif data.WarriorSDKAPI then
            GameSDKs:Warrior_response(data.WarriorSDKAPI)
        elseif data.WarriorNoticeData then
            --TODO:处理公告的回调
            --json：数据格式
            GameTableDefine.BoardUI:WarriorNoticeCallback(data.WarriorNoticeData)
        elseif data.WarriorActivityData then
            if not LocalDataManager:IsNewPlayerRecord() then
                --TODO:处理活动返回的数据
                --joso数据格式:"WarriorActivityData{instanceID=" + this.instanceID + ", activityType=" + this.activityType + ", previewTime=" + this.previewTime + ", startTime=" + this.startTime + ", settlementTime=" + this.settlementTime + ", endTime=" + this.endTime + ", icon='" + this.icon + '\'' + ", activityName='" + this.activityName + '\'' + ", backgroudImg='" + this.backgroudImg + '\'' + ", content=" + this.content + '}'
                ShopManager:CheckResetDoubleDiamond(data.WarriorActivityData)
                --K119 累充活动开启方式更改
                --AccumulatedChargeActivityDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
                TimeLimitedActivitiesManager:GetTLASDKCfg(data.WarriorActivityData)
                GameTableDefine.InstanceDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
                GameTableDefine.CycleInstanceDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
                --赛季通行证
                SeasonPassManager:ProcessSDKCallbackData(data.WarriorActivityData)
				--2025-3-27fy下班打卡
				ClockOutDataManager:ProcessSDKCallbackData(data.WarriorActivityData)
            end
        elseif data.WarriorBindInfo then
            --绑定账号的回调
            self:Warrior_bindingAccCallBack(data.WarriorBindInfo)
        elseif data.queryOrderInfo then
            --if UnityHelper.IsRuassionVersion() then
            --	--俄区新支付sdk查询返回	2023-11-3
            --end
            -- GameTableDefine.SettingUI:OnCheckRussionPurchaseCallback(data.queryOrderInfo.query_order_successful, data.queryOrderInfo.serialId, data.queryOrderInfo.productId)
            GameTableDefine.MainUI:OnInitQueryOrderCallback(data.queryOrderInfo.query_order_successful,
                data.queryOrderInfo.data, data.queryOrderInfo.type)
        elseif data.replenishOrderInfo then
            --if UnityHelper.IsRuassionVersion() then
            --end
            -- GameTableDefine.SettingUI:OnRestorePurchaseCallback(data.replenishOrderInfo.fs_iap_buy_product_successful, data.replenishOrderInfo.productId)
            GameTableDefine.MainUI:OnRestorePurchaseCallback(data.replenishOrderInfo.fs_iap_buy_product_successful,
                data.replenishOrderInfo.productId, data.replenishOrderInfo.serialId, data.replenishOrderInfo.type, data.replenishOrderInfo.extra)
        elseif data.WarriorGiftPackData then
			--限时礼包和累充活动
			--K119 累充活动改为由此开启
			local limitPackData = nil
			for i = 1, #data.WarriorGiftPackData do
				local packData = data.WarriorGiftPackData[i]

				if packData.type == TimeLimitedActivitiesManager.GiftPackType.LimitPack then
					limitPackData = packData
				elseif packData.type == TimeLimitedActivitiesManager.GiftPackType.AccumulatedCharge then
					AccumulatedChargeActivityDataManager:ProcessSDKCallbackData(packData)
				elseif packData.type == TimeLimitedActivitiesManager.GiftPackType.LimitChoose then
					TimeLimitedActivitiesManager:EnableLimitChooseActivityFromSDK(packData)
				else
					if packData.type then
						printError("WarriorGiftPackData : 未知活动类型" .. packData.type)
					else
						printError("WarriorGiftPackData : 未设置活动类型 nil")
					end
				end
			end

			if limitPackData then
				local dataSize = Tools:GetTableSize(limitPackData.sub_gift)
				if dataSize == 2 then
					GameTableDefine.TimeLimitedActivitiesManager:EnableLimitPackActivityFromSDK(limitPackData)
				elseif dataSize > 2 then
					GameTableDefine.TimeLimitedActivitiesManager:EnableLimitPackActivityFromSDK(limitPackData)
					printError("WarriorGiftPackData : LimitPack 超过支持上限，只支持2个配置")
				elseif dataSize < 2 then
					printError("WarriorGiftPackData : LimitPack 配置数不足2个无法开启活动,只支持2个配置")
				end
			end
		elseif data.notificationState then
			GameStateManager:SendNotificationStateTrackForeign(data.notificationState.is_open)
		elseif data.remoteConfig then
			--"remoteConfig": {
			--"state": 2, -- 1是请求, 2是收到结果
			--"value": "test2",
			--"duration": 1150,
			--"end_time": 1738831938, -1为异常, 0为默认分组需请求活动
			--}
			if data.remoteConfig.state == 2 then
				-- 根据返回结果保存结束时间,在范围内则保存
				local now = GameTimeManager:GetCurLocalTime(true)
				local remoteConfigData = LocalDataManager:GetRemoteConfigData()
				if now < (data.remoteConfig.end_time) then
					remoteConfigData.endTime = data.remoteConfig.end_time
					ConfigMgr:SetCorrectlyGroupedMark(true)
				else
					if data.remoteConfig.end_time == 0 then
						ConfigMgr:SetCorrectlyGroupedMark(true)
					else
						ConfigMgr:SetCorrectlyGroupedMark(false)
					end
				end
				ConfigMgr:CheckABTestConfig(data.remoteConfig.value)
				ConfigMgr:LoadConfigByGroup()

				GameSDKs:TrackForeign("remote_config", {
					state = data.remoteConfig.state,
					result = remoteConfigData.group,
					value = data.remoteConfig.value,
					duration = data.remoteConfig.duration,
					endtimestamp = data.remoteConfig.end_time
				})
			end
		end
	end
end

function GameSDKs:HTTP_WechatLogin(code)
    local requestTable = {
        url = "wechat_login",
        msg = {code = code},
        callback = function(response)
            if response.gameData then
                ChooseUI:ShowCloudConfirm("TXT_CLOUDSTORAGE_ASK", function()
                    LocalDataManager:ReplaceLocalData(response.gameData)
                end)
                return
            end
            local data = LocalDataManager:GetDataByKey("user_data")
            data.wechat_id = response.wxId
            data.user_id = response.userId
            LocalDataManager:WriteToFile()
            GameTableDefine.CloudStorageUI:ShowPanel()
        end
    }
    GameNetwork:HTTP_SendRequest(requestTable)
end


function GameSDKs:LoginTimeOutHint(cb)
	if self.loginTimer then
		GameTimer:StopTimer(self.loginTimer)
		self.loginTimer = nil
	end
	-- 2025-2-26 18:39:16 改游戏初始化流程导致的修改 
	self.loginTimer = GameTimer:CreateNewTimer(ConfigMgr.config_global and ConfigMgr.config_global.login_wait_time or 15, function()
		self.loginTimer = nil
		-- self:TrackForeign("init", {init_id = 12, init_desc = "登陆服务器超时"})
		self:TrackForeign("login", {login_type = self.m_loginType, login_result = 2})
		ChooseUI:CommonChoose("TXT_TIP_LOGIN_OVERTIME", function()
			cb()
		end, true, function()
			-- CS.UnityEngine.Application.Quit()
			UnityHelper.ApplicationQuit()
		end)
	end)
end

function GameSDKs:LoginFailHint(cb, error)
	-- self:TrackForeign("init", {init_id = 13, init_desc = "登陆服务器失败"})
	self:TrackForeign("login", {login_type = self.m_loginType, login_result = 0})
	if self.loginTimer then
		GameTimer:StopTimer(self.loginTimer)
		self.loginTimer = nil
	end

	local txt = GameTextLoader:ReadText("TXT_TIP_LOGIN_FAIL")
	if error then
		txt = txt .."["..error.."]"
		
	end
	ChooseUI:CommonChoose(txt, function()
		cb()
	end, true, function()
		-- CS.UnityEngine.Application.Quit()
		UnityHelper.ApplicationQuit()
	end)
end

-- 登陆客户端请求存档失败需要用户再次进行获取存档的操作 2022-10-9
function GameSDKs:LoginLoadSaveDataFromServerFailed(cb, error)
	if self.loginLoadDataTimer then
		GameTime:StopTimer(self.loginLoadDataTimer)
		self.loginLoadDataTimer = nil
	end
	self.loginLoadDataTimeoutFlag = 0
	self.loginLoadDateRequesTime = 0
	local txt = GameTextLoader:ReadText("TXT_LOGIN_FAIL_CLOUDSTORAGE")
	if error then
		ChooseUI:CommonChoose(txt, function()
			if cb ~= nil then
				cb()
			end
		end, true, function()
			-- CS.UnityEngine.Application.Quit()
			UnityHelper.ApplicationQuit()
		end)
	end
end

function GameSDKs:LoginLoadSaveDataFromServerTimeOut(cb)
	if self.loginLoadDataTimer then
		GameTimer:StopTimer(self.loginLoadDataTimer)
		self.loginLoadDataTimer = nil
	end
	-- 获取服务器存档超时标志
	self.loginLoadDataTimeoutFlag = self.loginLoadDataTimeoutFlag + 1
	self.loginLoadDataTimer = GameTimer:CreateNewTimer(ConfigMgr.config_global.login_wait_time, function()
		self.loginLoadDataTimer = nil
		-- TODO:需要增加埋点，告知客户端超时设置到了
		ChooseUI:CommonChoose("TXT_LOGIN_FAIL_CLOUDSTORAGE", function()
			if cb ~= nil then
				cb()
			end
		end, true, function()
			-- CS.UnityEngine.Application.Quit()
			UnityHelper.ApplicationQuit()
		end)
	end)
end
-- 登录
function GameSDKs:Warrior_login(type, isAuto)
	if type == self.LoginType.tourist or isAuto then
		self:LoginTimeOutHint(handler(LoadingScreen, LoadingScreen.WarriorLoginBtn))
	end
	self:TrackForeign("init", {init_id = 6, init_desc = "开始登陆服务器"})
	GameTableDefine.LoadingScreen:SetLoadingMsg("开始登陆服务器")
	GameLauncher.updater:SetProgress(65)
	GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_5"))
	self.m_loginType = type or self.LoginType.tourist
	DeviceUtil.InvokeNativeMethod("WarriorApiLogin", self.m_loginType)
end

function GameSDKs:Warrior_loginCallBack(id, error)
	
	if not id then
		self:LoginFailHint(handler(LoadingScreen, LoadingScreen.WarriorLoginBtn), error)
		return
	end
	--if tonumber(id) == nil or tonumber(id) <= 0 then
	--	self:LoginFailHint(handler(LoadingScreen, LoadingScreen.WarriorLoginBtn), tostring(id))
	--	return
	--end
	self.m_key = "fb_id"
	-- GameNetwork.HEADR["X-WRE-TOKEN"] = token
	self:LoginSuccess(self.m_key, id)
end

function GameSDKs:Warrior_bindingAccCallBack(bindInfo)
	--SDK回调数据：
	-- 成功：
	-- {
	-- 	"WarriorBindInfo":{
	-- 		"warrior_bind_user_id": "",
	-- 		"warrior_bind_game_data": ""
	-- 	}
	-- }
	-- 失败：
	-- {
	-- 	"WarriorBindInfo":{
	-- 		"warrior_bind_error_code": "",
	-- 		"warrior_bind_error_step": ""
	-- 	}
	-- }
	if not self.curBindType or self.curBindType == GameSDKs.LoginType.tourist then
		return
	end
	local bindSuccess = false
	if bindInfo.warrior_bind_user_id and bindInfo.warrior_bind_user_id ~= "" and bindInfo.warrior_bind_type and bindInfo.warrior_bind_type == self.curBindType then
		--成功
		bindSuccess = true
	else
		--失败
		bindSuccess = false
	end
	--SettingUI:WarriorBindingAccCallback(success, loginType, userID, serverData)
	GameTableDefine.SettingUI:WarriorBindingAccCallback(bindSuccess, self.curBindType, bindInfo.warrior_bind_user_id, bindInfo.warrior_bind_game_data)
end

function GameSDKs:Warrior_sendFeedbackMail()
	local id = self:GetSendUserIdInfo()
	DeviceUtil.InvokeNativeMethod("SendFeedbackMail", tostring(id))
end

function GameSDKs:GetSendUserIdInfo()
	local id = self:GetThirdAccountInfo()
	local data = LocalDataManager:GetDataByKey("user_data")
	if id ~= tostring(self.m_accountId) then
		id = string.format("%s.%s.%s.%s", data.cur_type or "#", id or "#", self.m_loginType or "#", self.m_accountId or "#")
	end
	return id
end

--- leyoHK
function GameSDKs:LeyoHKLogin()
	GameSDKs:TrackForeign("init", {init_id = 6, init_desc = "开始登陆服务器"})
	self.m_loginType = self.LoginType.tourist
	if GameDeviceManager:IsEditor() then
		local testinfo = "{\"LeyoHK_LoginInfo\":{\"login_token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NTU3NzgwNTAsImV4cCI6MTY1NTg0MTYwMCwiZGF0YSI6eyJ1c2VyaWQiOiI0NGYxYWVhZGVjYzcyYjZmN2IyN2YzYzkyNzVmNWViYyIsImlzX2JhbiI6MH19.iqB8-7AW1qnCPjTWLILOZiyu4D5xlS5Gx-Lgi292mtI\",\"login_user_id\":\"44f1aeadecc72b6f7b27f3c9275f5ebc\",\"openId\":\"61190ff43b740ebe\",\"uuid\":\"\",\"sessionKey\":\"\",\"block\":0,\"legal\":false,\"nickName\":\"\",\"avatarUrl\":\"\",\"ipBlock\":{\"ip\":\"183.6.117.50\",\"blockRegion\":\"\",\"block\":false},\"loginTime\":1655778050}}"
		self:OnReciveAndroidMsg(testinfo)
	else
		DeviceUtil.InvokeNativeMethod("LeyoHKApiLogin", self.m_loginType)
		self:LoginTimeOutHint(self.LeyoHKLogin)
	end
end

function GameSDKs:LeyoHKCallBack(id, token)
	if not id or not token then
		self:LoginFailHint(self.LeyoHKLogin)
		return
	end
	self.m_key = "wechat_id"
	GameNetwork.HEADR["X-LEYO-TOKEN"] = token
	self:LoginSuccess(self.m_key, id, token)
end
--- leyoHK end

function GameSDKs:LoginSuccess(key, id, token)
	ChooseUI:CloseView()
	GameTimer:StopTimer(self.loginTimer)
	GameSDKs:TrackForeign("init", {init_id = 7, init_desc = "登陆服务器成功"})
	GameTableDefine.LoadingScreen:SetLoadingMsg("登陆服务器成功")
	GameLauncher.updater:SetProgress(70)
	GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_6"))
	GameSDKs:TrackForeign("login", {login_type = self.m_loginType, login_result = 1 })

	local data = LocalDataManager:GetDataByKey("user_data")
	self.m_accountId = id
	self.m_accountToken = token
	self:ExecuteErrorQueue()
	if self:VerifyThirdAccountInfo(key) then -- 账号id相同自己进入游戏并且上传存档
		data.token = token
		data.cur_type = self.m_loginType
		LocalDataManager:UpdateLoadLocalData()
		--LocalDataManager:UploadWarriorDataBackups() -- 备份存档
		GameStateManager:Init()
	else
		
		LocalDataManager:LoginDownLoadLocalData(id, function(error)
			if error then -- 服务器崩溃或者下载失败 不保存id 到本地，防止本地存档有可能损坏覆盖服务端存档
				GameStateManager:Init()
				return
			end
			--上传存档成功后添加账号信息到本地存档，表示存档已经在服务器登记，服务器未登记的存档不会有账号信息（只有上传成功才在本地保存账号id）
			self:SaveThirdAccountInfo(key)
			GameStateManager:Init()
		end)
	end
end

function GameSDKs:LoginDownLoadLocalDataCallback(id, error, key)
	if error then
		self:LoginLoadSaveDataFromServerFailed(function(id)
			GameSDKs:LoginLoadSaveDataFromServerTimeOut(function()
				self.loginLoadDateRequesTime = self.loginLoadDateRequesTime + 1
				LocalDataManager:LoginDownLoadLocalData(id, function(error)
					self:LoginDownLoadLocalDataCallback(id, error, key)
				end)
			end)
			self.loginLoadDateRequesTime = self.loginLoadDateRequesTime + 1
			LocalDataManager:LoginDownLoadLocalData(id, function(newError)
				self:LoginDownLoadLocalDataCallback(id, newError, key)
			end)
		end)
		return
	end
	if self.loginLoadDateRequesTime == 0 then
		return
	end
	if self.loginLoadDateRequesTime <= self.loginLoadDataTimeoutFlag then
		return
	end
	if self.loginLoadDataTimer ~= nil then
		GameTimer:StopTimer(self.loginLoadDataTimer)
		self.loginLoadDataTimer = nil
	end
	-- 上传存档成功后添加账号信息到本地存档，表示存档已经在服务器登记，服务器未登记的存档不会有账号信息（只有上传成功才在本地保存账号id）
	self:SaveThirdAccountInfo(key)
	GameStateManager:Init()
end

function GameSDKs:SaveThirdAccountInfo(key)
	if not self.m_accountId then
		return
	end

	local data = LocalDataManager:GetDataByKey("user_data")
	data.token = self.m_accountToken
	data.cur_type = self.m_loginType
	if not self.m_loginType then -- 兼容老存档
		if data[key] == nil then 
			data[key] = self.m_accountId
			LocalDataManager:WriteToFile()
			LocalDataManager:Update()
		end
		return
	end
	--新存档
	if not data[key] then
		data[key] = self.m_accountId
	end
	data.third_account = data.third_account or {}
	if not data.third_account[self.m_loginType] then 
		data.third_account[self.m_loginType] = self.m_accountId
		LocalDataManager:WriteToFile()
		LocalDataManager:Update()
	end
	 
end

function GameSDKs:VerifyThirdAccountInfo(key)	
	if LocalDataManager:IsNewPlayerRecord() then
		-- GameSDKs:TrackForeign("savedata", {login_type = self.m_loginType, local_id = 0, login_id = self.m_accountId, new_flag = 1, err_type = 0 })
		return
	end

	local data = LocalDataManager:GetDataByKey("user_data")
	if not self.m_loginType then -- 兼容老的存档结构
		return tostring(data[key] or "") == tostring(self.m_accountId)
	end

	--新的存档结构
	data.third_account = data.third_account or {}
	if data[key] and not data.third_account[self.LoginType.tourist] then
		data.third_account[self.LoginType.tourist] = data[key]
		LocalDataManager:WriteToFile()
	end
	-- if tostring(data.third_account[self.m_loginType]) ~= tostring(self.m_accountId) then
	-- 	GameSDKs:TrackForeign("savedata", {login_type = self.m_loginType, local_id = data.third_account[self.m_loginType], login_id = self.m_accountId, new_flag = 0, err_type = 1 })
	-- else
	-- 	GameSDKs:TrackForeign("savedata", {login_type = self.m_loginType, local_id = data.third_account[self.m_loginType], login_id = self.m_accountId, new_flag = 0, err_type = 0 })
	-- end
	-- 2024-6-19 17:11:39 gxy 如果登录类型不是设备账号,则直接返回true
	return tostring(data.third_account[self.m_loginType]) == tostring(self.m_accountId)
end

function GameSDKs:GetThirdAccountInfo()
	local data = LocalDataManager:GetDataByKey("user_data")
	-- if not self.m_loginType then -- 兼容老存档
	-- 	return tostring(data[self.m_key])
	-- end
	if not data.cur_type then
		return
	end
	--新存档
	data.third_account = data.third_account or {}
	if data.third_account[data.cur_type] then
		return tostring(data.third_account[data.cur_type])
	end
end

---获取可用的玩家识别ID，根据版本返回ThirdAccountID,UUID,DeviceUDID
function GameSDKs:GetCurUserID()
	local userId = GameSDKs:GetThirdAccountInfo()
	if UnityHelper.IsRuassionVersion() or GameConfig:IsAMZPackageVersion() then
		userId = GameSDKs.LoginUUID
	end
	if not userId or userId == "" then
		userId = GameDeviceManager:GetDeviceUDID()
	end
	return userId
end

function GameSDKs:InitLoginAccountInLocalData()
	local rootData = LocalDataManager:GetRootRecord()
	local _,data = next(rootData)
	if GameSDKs:GetThirdAccountInfo() ~= nil then
		return rootData --老账号直接返回数据
	end

	if not self.m_accountId then
		return
	end
	-- 如果是新存档或者没有账号id的存档会在缓存数据里面添加账号信息并上传，并在上传成功后再在真实存档里面添加账号信息（防止上传失败后本地存档添加了账号信息可能会覆盖服务器存档）
	local newRootData = Tools:CopyTable(rootData) 
	_,data = next(newRootData)

	data.user_data = data.user_data or {}
	if not self.m_loginType then -- 兼容老存档
		data.user_data[self.m_key] = self.m_accountId
		return newRootData
	end
	
	data.user_data.third_account = data.user_data.third_account or {}
	--[[检测本地缓存存档如果和登陆的用户id不一致的话，说明本地缓存存档有问题，上传会覆盖玩家的正常存档]]
	if data.user_data.third_account[self.m_loginType] ~= nil then
		if tonumber(data.user_data.third_account[self.m_loginType]) ~= nil then
			if tonumber(data.user_data.third_account[self.m_loginType]) ~= self.m_accountId then
				return nil
			end
		else
			--userid是个字符串，字符串也可能是"nil"
			return nil
		end
		
	end
	data.user_data.third_account[self.m_loginType] = self.m_accountId
	data.user_data.cur_type = self.m_loginType
	return newRootData
end

-- tapjoy
function GameSDKs:ShowDefaultEarnedCurrencyAlert()
	if not GameSDKMgr.ShowDefaultEarnedCurrencyAlert then
		return
	end
	GameSDKMgr:ShowDefaultEarnedCurrencyAlert()
end

function GameSDKs:ShowTapJoyOfferwall()
	if not GameSDKMgr.ShowTapjoyOfferWall then
		return
	end
	FlyIconsUI:SetNetWorkLoading(true)
	GameSDKMgr:ShowTapjoyOfferWall(GameDeviceManager:IsiOSDevice() and "offerwall_IOS" or "offerwall")
end

function GameSDKs:TapjoyOnRewardRequest(type, amount, quantity)
	if type == "gem" then
        GameTableDefine.ResourceManger:AddCash(tonumber(amount), nil, function()
			EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
		end)
	elseif type == "diamond" then
		GameTableDefine.ResourceManger:AddDiamond(tonumber(amount), nil, function()
			EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
		end)
	end
	print("--->TapjoyOnRewardRequest", type, amount, quantity)
	FlyIconsUI:SetNetWorkLoading(false)
end

function GameSDKs:TapjoyOnCanncel()
	FlyIconsUI:SetNetWorkLoading(false)
end

--向瓦瑞爾sdk服務器請求公告的接口
--[[
    @desc: 向瓦瑞尔服务器请求公告的接口
    author:{author}
    time:2022-11-17 10:49:19
    --@language:当前使用的语言
	--@appversion: app版本
    @return:
]]
function GameSDKs:WarriorGetNotice(language, appversion)
	print("WarriorGetNotice:language:"..language.." appversion:"..appversion)
	DeviceUtil.InvokeNativeMethod("WarriorApiGetNotice", language, appversion)
end

--向瓦瑞尔sdk请求活动的接口
--[[
    @desc:sdk封装了向瓦瑞尔服务器请求活动相关数据的接口 
    author:{author}
    time:2022-11-17 10:48:44
    --@language:当前语言
	--@appversion:app的版本
	--@activityType: 活动类型，3-首充双倍
    @return:
]]
function GameSDKs:WarriorGetActivityData(language, appversion, activityType)
	if not GameDeviceManager:IsEditor() and not ConfigMgr:HasCorrectlyGrouped() then	-- 如果没有处在正确的分组情况下, 则不请求活动
		return
	end
	-- language = string.upper(language)
	print("WarriorGetActivityData:language:"..string.upper(language).."appversion:"..appversion.."activityType:"..tostring(activityType))
	DeviceUtil.InvokeNativeMethod("WarriorApiRequestActivityData", string.upper(language), appversion, tostring(activityType))
end

---向瓦瑞尔sdk请求 限时礼包 活动的接口
function GameSDKs:WarriorGetLimitPackData()
	if not ConfigMgr:HasCorrectlyGrouped() then	-- 如果没有处在正确的分组情况下, 则不请求活动
		return
	end
	local userID = self:GetThirdAccountInfo()
	local language = string.upper(GameLanguage:GetCurrentLanguageID())
	DeviceUtil.GetGiftPackData(userID or "", Application.version, language)
end

function GameSDKs:Warrior_bindingAcc(bindType)
	if bindType == GameSDKs.LoginType.tourist then
		return
	end
	-- if GameDeviceManager:IsiOSDevice() and bindType == GameSDKs.LoginType.google then
	-- 	return
	-- end
	-- if GameDeviceManager:IsAndroidDevice() and bindType == GameSDKs.LoginType.apple then
	-- 	return
	-- end
	self.curBindType = bindType
	DeviceUtil.InvokeNativeMethod("WarriorApiBind", bindType)
end

--[[
    @desc: 添加设置用户属性到埋点上
    author:{author}
    time:2023-12-01 10:49:11
    --@properties:比如："{\"app_version\":\"1.0.1\",\"role_create_time\":\"2023-12-01 10:14\"}"
	--@type: 
    @return:
]]
function GameSDKs:SetUserAttrToWarrior(properties)
	local json = nil
	if properties and type(properties) == "table" and Tools:GetTableSize(properties) > 0 then
		json = Rapidjson.encode(properties)
	end
	DeviceUtil.SetUserProperties(json, "set")
end

EventManager:RegEvent("FS_ON_TAPJOY_REWARD_REQUEST", handler(GameSDKs, GameSDKs.TapjoyOnRewardRequest))
EventManager:RegEvent("FS_ON_TAPJOY_CONTENT_DISMISS", handler(GameSDKs, GameSDKs.TapjoyOnCanncel))
--end tapjoy

EventManager:RegEvent("EVENT_AD_END", handler(GameSDKs, GameSDKs.AdEnd))
EventManager:RegEvent("FS_ON_ANDROID_MSG", handler(GameSDKs, GameSDKs.OnReciveAndroidMsg))
EventManager:RegEvent("FS_ON_IOS_MSG", handler(GameSDKs, GameSDKs.OnReciveIOSMsg))