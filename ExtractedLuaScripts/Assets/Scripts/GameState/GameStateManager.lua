require("GameUtils.ExceptionHandler")

require("GameState.GameStateCity")
require("GameState.GameStateFloor")
require("GameState.GameStateInstance")

local Application = CS.UnityEngine.Application
local DeviceUtil = CS.Game.Plat.DeviceUtil
local DeviceManager = GameDeviceManager

local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local MainUI = GameTableDefine.MainUI
local GuideManager = GameTableDefine.GuideManager
local SoundEngine = GameTableDefine.SoundEngine
local GameClockManager = GameTableDefine.GameClockManager
local CompanyMode = GameTableDefine.CompanyMode
local PetMode = GameTableDefine.PetMode
local StarMode = GameTableDefine.StarMode
local CountryMode = GameTableDefine.CountryMode
local CloudStorageUI = GameTableDefine.CloudStorageUI
local DressUpDataManager = GameTableDefine.DressUpDataManager
local FootballClubModel = GameTableDefine.FootballClubModel
local UnityHelper = CS.Common.Utils.UnityHelper
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameLanucher = CS.Game.GameLauncher.Instance
local ActorManager = GameTableDefine.ActorManager
local OfflineManager = GameTableDefine.OfflineManager
local GameLauncher = CS.Game.GameLauncher.Instance


GameStateManager = {
    m_currentGameState = -1,
    m_lastGameState = -1,
    m_nextGameState = -1,
    GAME_STATE_INIT = 1,
    GAME_STATE_CITY = 2,
    GAME_STATE_FLOOR = 3,
    --m_currentStateManager = nil,
    m_currentSaveVer = "1.0",
    m_statePause = false,
    m_nextStateCallback = nil,
    m_nextStateParams = nil,
    GAME_STATE_INSTANCE = 4,
    GAME_STATE_CYCLE_INSTANCE = 5,
}

GameStateManager.m_stateManager = {
    [GameStateManager.GAME_STATE_CITY] = GameTableDefine.GameStateCity,
    [GameStateManager.GAME_STATE_FLOOR] = GameTableDefine.GameStateFloor,
    [GameStateManager.GAME_STATE_INSTANCE] = GameTableDefine.GameStateInstance,
    [GameStateManager.GAME_STATE_CYCLE_INSTANCE] = GameTableDefine.GameStateCycleInstance
}

local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode

local ConfigMgr = GameTableDefine.ConfigMgr
local BoardUI = GameTableDefine.BoardUI


function GameStateManager:Init()
    GameTableDefine.SpicalRoomManager:Init()
    --GameTableDefine.ActorManager:Init()
    if GameConfig:IsWarriorVersion() and not LocalDataManager:HasInit() and not GameDeviceManager:IsEditor() then
        DeviceUtil.GetNotificationState()
        GameTableDefine.LoadingScreen:SetLoadingMsg("本地存档初始化")
        GameLanucher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_4"))
        LocalDataManager:Init()
        --CountryMode:OnEnter()
        CountryMode:ctor()
        GameTableDefine.DeeplinkManager:Init()
        --GameTableDefine.CycleInstanceDataManager:Init()
        --GameTableDefine.ValueManager:InitBankData() -- 2024-3-22 18:09:42 gxy 提前初始化一次钱的上限
        GameSDKs:TrackForeign("init", {init_id = 13, init_desc = "礼包码显示标志请求"})
        GameTableDefine.SettingUI:RequestNextWorkAppVersion()
        GameSDKs:TrackForeign("init", {init_id = 14, init_desc = "初始化本地语言配置"})
        GameTextLoader:LoadTextofLanguage(GameLanguage:GetCurrentLanguageID(),function()
            -- GameSDKs:WarriorLogin()
            -- GameSDKs:TrackForeign("init", {init_id = 15, init_desc = "加载登陆界面"})
            GameTableDefine.LoadingScreen:WarriorLoginBtn()
        end)
        ExceptionHandler:Init()
        GameSDKs:TrackForeign("enter_game_check", {step=1, check_desc = "GameStateManager第一次Init()完成"})

    elseif GameConfig:IsLeyoHKVersion() and not LocalDataManager:HasInit() and not GameDeviceManager:IsEditor() then --
        LocalDataManager:Init()
        CountryMode:OnEnter()
        GameTableDefine.ValueManager:InitBankData() -- 2024-3-22 18:09:42 gxy 提前初始化一次钱的上限
        GameTextLoader:LoadTextofLanguage(GameLanguage:GetCurrentLanguageID(),function()
            GameSDKs:LeyoHKLogin()
        end)
        GameTableDefine.SettingUI:HKRequestNextWorkAppVersion() 
        GameTableDefine.DeeplinkManager:Init()
        GameTableDefine.OfflineManager:Init()

    else
        -- GameTableDefine.SettingUI:RequestNextWorkAppVersion()
        GameSDKs:TrackForeign("enter_game_check", {step=2, check_desc ="GameStateManager第二次Init()开始"})
        if requireRemoveConfig and not DeviceManager:IsPCDevice() then
            -- 请求远程配置
            ConfigMgr:RequireConfigGroup()
            ---- TEMP 没写正式的远程配置加载流程, 先用本地的
            --if not ConfigLoadOver then
            --    GameTableDefine.ConfigMgr:DynamicLoadConfig(function()
            --        CS.Common.Utils.XLuaManager.Instance:UnloadUnUseLuaFiles()
            --        ConfigLoadOver = true
            --        -- GameSDKs:TrackForeign("init", {init_id = 5, init_desc = "脚本初始化"})
            --        GameTableDefine.LoadingScreen:SetLoadingMsg("脚本初始化")
            --        GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_1"))
            --        self:AfterConfigLoaded()
            --    end)
            --else
            --    self:AfterConfigLoaded()
            --end
        else
            if not LocalDataManager:HasInit() then
                LocalDataManager:Init()
            end
            -- 不请求远程配置
            if not ConfigLoadOver then
                GameTableDefine.ConfigMgr:CheckABTestConfig()
                GameTableDefine.ConfigMgr:DynamicLoadConfig(function()
                    CS.Common.Utils.XLuaManager.Instance:UnloadUnUseLuaFiles()
                    ConfigLoadOver = true
                    -- GameSDKs:TrackForeign("init", {init_id = 5, init_desc = "脚本初始化"})
                    GameTableDefine.LoadingScreen:SetLoadingMsg("脚本初始化")
                    GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_1"))
                    self:AfterConfigLoaded()
                end)
            else
                self:AfterConfigLoaded()
            end
        end
    end
end

function GameStateManager:AfterConfigLoaded()

    GameTableDefine.ActorManager:Init()
    GameTableDefine.IAP:Init()

    CountryMode:OnEnter()
    GameTableDefine.ValueManager:InitBankData() -- 2024-3-22 18:09:42 gxy 提前初始化一次钱的上限
    GameTableDefine.OfflineManager:Init()

    GameTableDefine.DeeplinkManager:Init()
    GameTableDefine.CycleInstanceDataManager:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=3, check_desc ="GameStateManager第二次Init()初始化银行钞票上线完成"})
    --跳过等待公告回调,继续登陆流程
    GameDeviceManager:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=4, check_desc ="GameStateManager第二次Init()GameDeviceManager:Init()完成"})
    ExceptionHandler:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=4, check_desc ="GameStateManager第二次Init()ExceptionHandler:Init()完成"})
    GameTableDefine.OfflineManager:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=5, check_desc ="GameStateManager第二次Init()离线奖励模块初始化完成"})
    GameTableDefine.TipsUI:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=6, check_desc ="GameStateManager第二次Init()TipsUI初始化完成"})
    GameTableDefine.FlyIconsUI:Init()
    GameSDKs:TrackForeign("enter_game_check", {step=7, check_desc ="GameStateManager第二次Init()FlyIconsUI初始化完成"})
    GameTextLoader:LoadTextofLanguage(
        GameLanguage:GetCurrentLanguageID(),
        function()
            GameTableDefine.IAP:GetOrder()
            GameSDKs:TrackForeign("enter_game_check", {step=8, check_desc ="GameStateManager第二次Init()IAP:GetOrder完成"})
            GameTableDefine.SettingUI:Init()
            GameSDKs:TrackForeign("enter_game_check", {step=9, check_desc ="GameStateManager第二次Init()SettingUI:Init完成"})
            GameTableDefine.CashEarn:Init()
            GameSDKs:TrackForeign("enter_game_check", {step=10, check_desc ="GameStateManager第二次Init()CashEarn:Init()完成"})
            --GameTableDefine.AZhenMessage:Init()
            --GameClockManager:Init()
            --GameTableDefine.LightManager:Init()
            GameSDKs:Init()
            GameSDKs:TrackForeign("enter_game_check", {step=11, check_desc ="GameStateManager第二次Init()GameSDKs:Init()完成"})
            -- GameSDKs:Track("log_in", {state = "success"})
            GameTextLoader:ForceRefreshText(function()
                local buildingId = GameTableDefine.CityMode:GetCurrentBuilding()
                GameSDKs:TrackForeign("enter_game_check", {step=12, check_desc ="GameStateManager第二次Init()获取玩家当前办公室ID"})
                if buildingId and not LocalDataManager:IsNewPlayerRecord() then
                    GameSDKs:TrackForeign("enter_game_check", {step=13, check_desc ="GameStateManager第二次Init()获取玩家当前办公室ID:"..tostring(buildingId).."准备进入场景加载状态执行"})
                    self:EnterBuildingFloor({id = buildingId, config = ConfigMgr.config_buildings[buildingId]})
                else
                    GameSDKs:TrackForeign("init", {init_id = 8, init_desc = "进入命名场景"})
                    GameSDKs:TrackForeign("enter_game_check", {step=13, check_desc ="GameStateManager第二次Init()新玩家进入命名场景状态执行"})
                    self:EnterCity()
                end
            end)
            GameDeviceManager:RegisterRemoteNotification()
            --2024-4-17 添加用于服务器初始化和登陆请求
            GameServerHttpClient:Init()
        end)
end




function GameStateManager:SendNotificationStateTrackForeign(bool)
    GameSDKs:TrackForeign("init", {init_id = 12, init_desc = "本地存档初始化", notify_type = bool and 1 or 0 })
end

function GameStateManager:LoadSceneComplete(isInFloor)
    GuideManager:Clear()
    GuideManager:Init()
    GameTableDefine.ShopManager:Init()

    GameTableDefine.StarMode:Init()

    PetMode:Refresh()
    GameTableDefine.GreateBuildingMana:UpdateBankMoney(true)
    GameTableDefine.GreateBuildingMana:RefreshImprove()
    EventManager:DispatchEvent(GameEventDefine.ReCalculatePowerUsed)
    EventManager:DispatchEvent(GameEventDefine.ReCalculateTotalPower)
    MainUI:Init(isInFloor)
    GameSDKs:Track("reyun,login")
    --GameTableDefine.IAP:CheckUnfinishedTransactions() -- gxy 2024-3-11 18:34:45  去掉统一的未完成订单检查
    CloudStorageUI:StartAutoUpdateGameDataTimer()
    --OfflineRewardUI:StartUpdateLeaveTime()
    GameStateManager.m_loadSceneComplete = true
    
end

--[[
    @desc:副本场景的读取完成通知到GameStateManager 
    author:{author}
    time:2023-03-24 10:04:57
    @return:
]]
function GameStateManager:LoadInstanceSceneComplate()
    if self.m_currentGameState == GameStateManager.GAME_STATE_INSTANCE 
    and self.m_stateManager[self.GAME_STATE_INSTANCE] then
        self.m_stateManager[self.GAME_STATE_INSTANCE]:EnterInstance()
    end
end

---循环副本场景的读取完成通知到GameStateManager
function GameStateManager:LoadCycleInstanceSceneComplate()
    if self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE
            and self.m_stateManager[self.GAME_STATE_CYCLE_INSTANCE] then
        self.m_stateManager[self.GAME_STATE_CYCLE_INSTANCE]:EnterInstance()
    end
end

function GameStateManager:Update(dt)
    -- self:GetFPS()
    -- if self.m_currentStateManager ~= nil then
    --     self.m_currentStateManager:Update(dt)
    -- end
    
    if self.m_currentGameState == self.GAME_STATE_INSTANCE then
        self.m_stateManager[self.GAME_STATE_INSTANCE]:Update(dt)
    elseif self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE then
        self.m_stateManager[self.GAME_STATE_CYCLE_INSTANCE]:Update(dt)
    else
        self.m_stateManager[self.GAME_STATE_CITY]:Update(dt)
        self.m_stateManager[self.GAME_STATE_FLOOR]:Update(dt)
    end
    -- self.m_stateManager[self.GAME_STATE_CITY]:Update(dt)
    -- self.m_stateManager[self.GAME_STATE_FLOOR]:Update(dt)
    if DeviceManager:IsPCDevice() then
        if Input.GetKeyUp(KeyCode.Escape) then
            self:RestartGame()
        end
        if Input.GetKeyUp(KeyCode.PageDown) or Input.GetKeyDown(KeyCode.Q)then
            GameTableDefine.GameUIManager:CloseTopUI()
        end
        -- self:TestInstance()        
    elseif Application.platform == RuntimePlatform.Android and Input.GetKeyDown(KeyCode.Escape) then   
        SoundEngine:PlaySFX(SoundEngine.BUTTON_CLICK_SFX)
        GameTableDefine.GameUIManager:CloseTopUI()
        -- if GameTableDefine.GameUIManager:GetIsTopUI() then
        --     local title = GameTextLoader:ReadText("TXT_TIP_HINT")
        --     local msg = GameTextLoader:ReadText("TXT_TIP_QUIT_GAME")
        --     local confirm = GameTextLoader:ReadText("TXT_BTN_CONFIRM")
        --     local cancel = GameTextLoader:ReadText("TXT_BTN_CANCEL")
        --     print("Android KeyCode.Escape:title:"..title.." msg:"..msg.." confirm:"..confirm.." cancel:"..cancel)
        --     UnityHelper.AndroidBackExitGame(title, msg, confirm, cancel)
        -- end
    end
    self:ChangingGameState()

    if not self:IsInstanceState() or not self:IsCycleInstanceState() then
        GameClockManager:Update(dt) 
    end
end

function GameStateManager:SetCurrentGameState(curState, params, cb)
    if self.m_currentGameState == curState then
        return
    end
    self.m_nextGameState = curState
    self.m_nextStateParams = params
    self.m_nextStateCallback = cb
end

function GameStateManager:ChangingGameState()
    if self.m_nextGameState == nil then
        return
    end

    self.m_lastGameState = self.m_currentGameState
    self.m_currentGameState = self.m_nextGameState
    self.m_nextGameState = nil

    local lastStateManager = self.m_stateManager[self.m_lastGameState]
    local currentStateManager = self.m_stateManager[self.m_currentGameState]
    if lastStateManager then
        lastStateManager:Exit()
    end
    if (self.m_lastGameState == self.GAME_STATE_INSTANCE or self.m_lastGameState == self.GAME_STATE_CYCLE_INSTANCE) and self.m_currentGameState == self.GAME_STATE_FLOOR then
        self.m_stateManager[self.m_currentGameState]:FromOtherStateEnter()
    end
    print("----->m_lastGameState:", self.m_lastGameState, "m_currentGameState:", self.m_currentGameState)
    if currentStateManager then
        currentStateManager:SetEnteredCallback(self.m_nextStateCallback)
        currentStateManager:SetParams(self.m_nextStateParams)
        currentStateManager:Enter()

    end
    --self.m_currentStateManager = currentStateManager
    self.m_nextStateCallback = nil
    self.m_nextStateParams = nil
end

function GameStateManager:OnResume()
    print("-----------now game on resume------------")
    self.m_statePause = false
    if self.m_currentGameState == -1 then
        return
    end
    GameTimeManager:VerifySystemTimeModification()
    OfflineManager:OnResume()
    -- OfflineRewardUI:ForceRefreshOffTimePass()
    -- local leaveTime = OfflineRewardUI:LeaveTime()
    -- local offTime = OfflineRewardUI:OffTimePassSecond()[1]/60 --获取第一个国家的房间的收益
    -- local canReward = math.floor(offTime) > 2 and leaveTime > 60 * 5
    local leaveTime = OfflineManager.m_offline
    local offTime = leaveTime/60 --获取第一个国家的房间的收益
    local canReward = math.floor(offTime) > 2
    print("leaveTime is:"..tostring(leaveTime))
    print("offTime is:"..tostring(offTime))
    if GameConfig:IsIAP() then
        if canReward then
            OfflineRewardUI:LoopCheckRewardValue(function()
                OfflineRewardUI:GetView()
            end, false)
        end
    elseif canReward ~= nil then
        OfflineRewardUI:LoopCheckRewardValue(function()
            OfflineRewardUI:GetView()
        end, false)
    end
    
    --工厂的零件离线计算
    GameTableDefine.FactoryMode:PiecewiseCalculation()

    --宠物的离线成长计算
    GameTableDefine.PetInteractUI:OfflineGrowingUp(30)

    CompanyMode.offlineRewardBefor = false
    GameDeviceManager:ClearNotifications()
    
    --if self.m_currentGameState == self.GAME_STATE_INSTANCE then
    --    InstanceDataManager:OnResume()
    --else
    --    --副本活动数据模块的初始化相关内容
    --    if not InstanceDataManager:GetInstanceIsActive() and not InstanceDataManager:GetInstanceRewardIsActive() then
    --        InstanceDataManager:Init(
    --            function()
    --                MainUI:RefreshInstanceentrance()
    --            end
    --        )
    --    end
    --end
    if self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE then
        CycleInstanceDataManager:OnResume()
    else
        --副本活动数据模块的初始化相关内容
        if not CycleInstanceDataManager:GetInstanceIsActive() and CycleInstanceDataManager:GetInstanceRewardIsActive() then
            CycleInstanceDataManager:Init(
                function()
                    MainUI:RefreshInstanceentrance()
                end
            )
        end
    end
    
    
    --足球俱乐部恢复
    FootballClubModel:OnResume()
    --游戏服务器重新登陆2024-4-18
    GameServerHttpClient:Init()
    --通行证任务的计时需要调用2024-12-24
    GameTableDefine.SeasonPassTaskManager:OnResume()
    --CEO计时需要调用2025-2-18
    GameTableDefine.CEODataManager:OnResume()
end
function GameStateManager:OnPause()
    self.m_statePause = true
    if self.m_currentGameState == -1 then
        return
    end
    self:AddLocalPush()

    OfflineManager:OnPause()
    if self.m_currentGameState == self.GAME_STATE_INSTANCE then
        InstanceDataManager:OnPause()
    end
    if self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE then
        CycleInstanceDataManager:OnPause()
    end
    --足球俱乐部离线开始
    FootballClubModel:OnPause()
    --游戏服务器登出2024-4-18
    GameServerHttpClient:LogoutGameServer()
    --通行证任务的计时需要调用2024-12-24
    GameTableDefine.SeasonPassTaskManager:OnPause()
    --CEO的计时需要调用的2025-2-18
    GameTableDefine.CEODataManager:OnPause()
end

function GameStateManager:AddLocalPush()
    local function SendOfflineRewardNotif()
        -- 离线奖励提示
        local maxOfflineTime = Tools:GetCheat(OfflineManager:GetOfflineMaxTime(), 30)
        if Tools:IsActiveUser() then
            local title = GameTextLoader:ReadText("TXT_NOTIFICATION_OFFLINE_REWARD_TITLE")
            local content = GameTextLoader:ReadText("TXT_NOTIFICATION_OFFLINE_REWARD_DESC")
            local countryID = CountryMode:GetCurrCountry()
            local Countdown = maxOfflineTime - ((OfflineManager.m_offline + OfflineManager.offlineData.areaData[countryID].offlineTime) or 0)
            if OfflineManager.offlineData.areaData[countryID].offlineTime == 0 and OfflineManager.offlineData.areaData[countryID].offlineReward == 0 then
                Countdown = maxOfflineTime
            end
            if Countdown < 0 then
                Countdown = 1
            end
            GameDeviceManager:AddNotification(title, Countdown, content,nil,1001)
        end
    end
     
    local function SendDailyTaskRefreshNotif()
        -- 发送本地推送消息(日常任务刷新)
        local Countdown = GameTableDefine.ActivityUI:CountDownToTheDay("day")
        local title = GameTextLoader:ReadText("TXT_NOTIFICATION_DAILY_TASK_TITLE")
        local content = GameTextLoader:ReadText("TXT_NOTIFICATION_DAILY_TASK_DESC")
        GameDeviceManager:AddNotification(title, Countdown<=0 and 1 or Countdown, content,nil,1002)
    end
    
    local function SendDiamonCardNotif()
        -- 发送本地推送消息(月卡待领取)
        local save = GameTableDefine.ShopManager:GetLocalData()
        local data, diamondGet = GameTableDefine.ShopManager:BuyDiamonCardData()
        if save and save["dia"] and data then
            local now = GameTimeManager:GetNetWorkTimeSync(true)
            local lastGet = save["dia"] and save["dia"].get
            if lastGet and lastGet + 86400 <= data.last and lastGet + 86400 > data.get then
                local Countdown = lastGet + 86400 - now
                if Countdown < 0 then
                    Countdown = 1
                end
                local title = GameTextLoader:ReadText("TXT_NOTIFICATION_MONTHLY_DIAMOND_TITLE")
                local content = GameTextLoader:ReadText("TXT_NOTIFICATION_MONTHLY_DIAMOND_DESC")
                GameDeviceManager:AddNotification(title, Countdown, content,nil,1003)
            end
        end
    end

    local function SendWheelReadyNotif()
        -- 转盘冷却完成提示
        --local wheelData = LocalDataManager:GetDataByKey("wheel")
        --local last = wheelData and wheelData.last
        --local now = GameTimeManager:GetNetWorkTimeSync(true)
        local cdTime = GameTableDefine.RouletteUI:UpdateWheelCDTime(true)
        if cdTime then
            local Countdown = cdTime
            if Countdown < 0 then
                Countdown = 1
            end
            local title = GameTextLoader:ReadText("TXT_NOTIFICATION_WHEEL_TITLE")
            local content = GameTextLoader:ReadText("TXT_NOTIFICATION_WHEEL_DESC")
            GameDeviceManager:AddNotification(title, Countdown, content,nil,1004)
        end
    end

    local function SendFCFCMatchChargeNotif()
        -- 足球俱乐部充能完成提示a
        local FCData = FootballClubModel:GetUnlockFCData()
        if not FCData then
            return
        end
        if not FootballClubModel.IsInitialized() then
            return
        end
        local leagueData = FootballClubModel:GetLeagueData()
        local matchData = FootballClubModel:GetMatchData()
        local MatchChange = FootballClubModel:GetMatchChange(leagueData)
        local roomData = FootballClubModel:GetRoomDataById(10002)
        if not FCData.id or not ConfigMgr.config_stadium[FCData.id] then
            return
        end
        local stadiumCfg = ConfigMgr.config_stadium[FCData.id][roomData.LV]
        if FCData and leagueData and matchData and MatchChange < 1 then
            local Countdown = stadiumCfg.matchCD * 3600 - leagueData.chargeTime
            if Countdown < 0 then
                Countdown = 1
            end
            local title = GameTextLoader:ReadText("TXT_NOTIFICATION_FT_CLUB_TITLE")
            local content = GameTextLoader:ReadText("TXT_NOTIFICATION_FT_CLUB_DESC")
            GameDeviceManager:AddNotification(title, Countdown, content,nil,1005)
        end
    end
    
    if not Tools:IsActiveUser() then
        return
    end
    SendOfflineRewardNotif()
    SendDailyTaskRefreshNotif()
    SendDiamonCardNotif()
    SendWheelReadyNotif()
    SendFCFCMatchChargeNotif()
    CycleInstanceDataManager:SendNotification()
end

function GameStateManager:EnterCity(cb)
    self:SetCurrentGameState(self.GAME_STATE_CITY, nil, cb)
    GameSDKs:TrackForeign("enter_game_check", {step=14, check_desc ="GameStateManager执行状态改变：self.GAME_STATE_CITY"})
end

function GameStateManager:EnterBuildingFloor(params, cb)
    GameClockManager:Init()
    self:SetCurrentGameState(self.GAME_STATE_FLOOR, params, cb)
    GameSDKs:TrackForeign("enter_game_check", {step=14, check_desc ="GameStateManager执行状态改变：self.GAME_STATE_FLOOR"})
end

function GameStateManager:GetCurrentGameState()
    return self.m_currentGameState
end

function GameStateManager:IsInCity()
    return self:GetCurrentGameState() == self.GAME_STATE_CITY
end


function GameStateManager:IsInFloor()
    return self:GetCurrentGameState() == self.GAME_STATE_FLOOR
end

function GameStateManager:IsInstanceState()
    return self.m_currentGameState == self.GAME_STATE_INSTANCE
end

function GameStateManager:IsCycleInstanceState()
    return self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE
end


-- function GameStateManager:GetCurrScene()
--     if self:IsInFloor() then
--         return GameTableDefine.FloorMode:GetScene()
--     end
--     return nil
-- end

function GameStateManager:AndroidPressBack(androidPressBack)
    self.m_androidPressBack = true
    if androidPressBack and (not self.m_androidPressBack) then
        local callback = function()
            self.m_androidPressBack = false
            GameStateManager:AddLocalPush()
            --glib.glib_ExitGame()
        end
        local cancelFunc = function()
            self.m_androidPressBack = false
        end
        local title = GameTextLoader:ReadText("LC_WORD_CONFIRM_ANDROID_QUIT_TITLE")
        local content = GameTextLoader:ReadText("LC_WORD_CONFIRM_ANDROID_QUIT_DESCRIPTION")
        GameTopPopupMenu:ShowConfirmCommon(title, content, callback, cancelFunc)
        return true
    end
end

function GameStateManager:CleanAll3DScene()
    -- GameTableDefine.Soldier3DPreview:ReleaseSoldierPreview(true)
    -- GameTableDefine.Hero3DPreview:ReleaseHero3DModel(true)
    -- GameTableDefine.WildCity3DPreview:ReleaseCityPreview(true)
    -- GameTableDefine.Guardian3DPreview:Release(true)
end

function GameStateManager:RestartGame()
    -- if destroy all resource in function LeaveState(), then
    -- switching state in game is very slow
    GameTimer:RemoveAllTimer()
    GameTableDefine.CompanyMode:Clear()
    GameTableDefine.ResourceManger:ClearData()
    GameTableDefine.GameUIManager:CloseAllFloatUI()
    GameTableDefine.GameUIManager:CloseAllUI({ENUM_GAME_UITYPE.LAUNCH})
    if not GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LAUNCH) then
        CS.Game.GameLauncher.Instance:Reset()
    end
    GameTableDefine.GameStateFloor:Clear()
    GameTableDefine.QuestManager:Clear()
    -- self.m_currentStateManager:Exit()
    GameTableDefine.GameStateCity:Exit()
    GameTableDefine.GameStateFloor:Exit()
    self.m_currentGameState = nil
    --self.m_currentStateManager = nil
    --SoundEngine:unLoadEffectSoundAll()
    self:Init()
end

function GameStateManager:Clear()
    self:AddLocalPush()
    GameTimer:RemoveAllTimer()
    GameTableDefine.CompanyMode:Clear()
    GameTableDefine.ResourceManger:ClearData()
    GameTableDefine.GameStateFloor:Clear()
    GameTableDefine.QuestManager:Clear()
    GameTableDefine.GameStateCity:Exit()
    GameTableDefine.GameStateFloor:Exit()
    if self.m_currentGameState == self.GAME_STATE_INSTANCE then
        InstanceDataManager:OnPause()
    elseif self.m_currentGameState == self.GAME_STATE_CYCLE_INSTANCE then
        if GameDeviceManager:IsEditor() then
            CycleInstanceDataManager:OnPause()
        end
    end
    self.m_currentGameState = nil
    --self.m_currentStateManager = nil
    FootballClubModel:OnPause()
end

-- local updateInterval = 1
-- local accum = 0
-- local frames = 0
-- local timeLeft = updateInterval
-- local strFPSValue = ""

-- local Time = CS.UnityEngine.Time
-- function GameStateManager:GetFPS()
--     timeLeft = timeLeft - Time.deltaTime
--     accum = accum + (Time.timeScale / Time.deltaTime)
--     frames = frames + 1;                                 
--     if timeLeft <= 0.0 then
--         strFPSValue = string.format("FPS: %s",math.ceil(accum / frames))
--         timeLeft = updateInterval;
--         accum = 0;
--         frames = 0;
--        GameTableDefine.MainUI:SetFPS(strFPSValue)
--     end
-- end

function GameStateManager:CheckStateIsCurrentState(state)
    return self.m_currentGameState and self.m_currentGameState == state
end

function GameStateManager:TestInstance()
    if GameConfig:IsDebugMode() then
        if Input.GetKeyDown(KeyCode.I) then
            if self.m_currentGameState ~= GameStateManager.GAME_STATE_INSTANCE then
                GameStateManager:SetCurrentGameState(GameStateManager.GAME_STATE_INSTANCE)
            else
                EventManager:DispatchEvent("BACK_TO_SCENE")
                GameTableDefine.CityMode:EnterDefaultBuiding()
            end
        end
    end
end

return GameStateManager
