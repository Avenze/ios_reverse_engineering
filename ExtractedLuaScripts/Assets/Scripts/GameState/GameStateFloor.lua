
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local GameUIManager = GameTableDefine.GameUIManager
local SoundEngine = GameTableDefine.SoundEngine
local GameStateFloor = GameTableDefine.GameStateFloor
local FloorMode = GameTableDefine.FloorMode
local FloorScene = GameTableDefine.FloorScene
local LoadingScreen = GameTableDefine.LoadingScreen
local Interface = GameTableDefine.Interface
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local StateManager = GameTableDefine.StateManager
local CutScreenUI = GameTableDefine.CutScreenUI
local CityMapUI = GameTableDefine.CityMapUI
local CountryMode = GameTableDefine.CountryMode
local CityMode = GameTableDefine.CityMode
local TimeManager = GameTimeManager
local GuideManager = GameTableDefine.GuideManager
local DeviceUtil = CS.Game.Plat.DeviceUtil
local FloatUI = GameTableDefine.FloatUI
local ActorManager = GameTableDefine.ActorManager
local UnityTime = CS.UnityEngine.Time

local SUBSTATE_NORMAL = 1
local SUBSTATE_LOADING = 2

local m_currentSubState = nil
local m_currentLoadStep = 0
local m_loadSceneHandle = nil
local m_activeSceneHandle = nil

local m_isScenceLoaded = nil

local m_enteredCallback = nil

local m_floorScene = nil

local m_fllorParams = nil

local SCENE_DIR = "Assets/Scenes/Scene001.unity"

function GameStateFloor:Enter()
	local config = ConfigMgr.config_floors --require("ConfigData.config_floors")
	SCENE_DIR = config[m_fllorParams.config.floor_list[1]].scene_name	
	if m_isScenceLoaded and FloorMode:GetCurrFloorId() == m_fllorParams.config.floor_list[1] or m_fllorParams.specialBuildId then
		m_currentSubState = SUBSTATE_NORMAL
		local cb = function()
			FlyIconsUI:SetScenceSwitchEffect(-1)
			CityMapUI:CloseView()
			MainUI:Init(FloorMode:IsInOffice())
			MainUI:InitCameraScale("IndoorScale")
		end
		if CityMode:IsTypeOffice(m_fllorParams.specialBuildId) or not m_fllorParams.specialBuildId then
			cb()
			MainUI:SetFloorIndex(FloorMode:GetCurrentFloorIndex(), FloorMode)
			SoundEngine:SetTimeLineVisible(true)
			MainUI:SetPowerBtnState(true)
		else
			FloorMode:InitSpecialBuilding(m_fllorParams.specialBuildId, cb)
		end
        -- FloorMode:Init(m_fllorParams)
		CountryMode.m_isSwitchCountry = false
	else
		FloorMode:OnExit()
		local hasLoading = CS.Game.GameLauncher.Instance.updater:IsActive()
		m_currentLoadStep = 1 --hasLoading and 1 or 2
		m_currentSubState = SUBSTATE_LOADING
		CountryMode.m_isSwitchCountry = false
	end
	ActorManager:OnStateEnter(GameStateManager.GAME_STATE_FLOOR) -- 在state进入后处理状态进入逻辑, 避免空引用

end

function GameStateFloor:Exit()
	ActorManager:OnStateExit(GameStateManager.GAME_STATE_FLOOR) -- 在state退出前处理状态退出逻辑, 避免空引用
	FloatUI:DestroyAllFloatUIView()
	MainUI:SetPowerBtnState(false)
	SoundEngine:SetTimeLineVisible(false)
	-- SoundEngine:StopBackgroundMusic()
	-- FloorMode:OnExit()
    m_loadSceneHandle = nil
	--m_isScenceLoaded = nil
	collectgarbage("collect")
end

function GameStateFloor:Clear()
	SoundEngine:StopBackgroundMusic()
	m_isScenceLoaded = nil
	m_loadSceneHandle = nil
	m_currentSubState = nil
	FloorMode:OnExit()
	collectgarbage("collect")
end

function GameStateFloor:Update(dt)
	--print("----------update frame time: ", TimeManager:GetSocketTime() - (self.___t or 0))
	if m_currentSubState == SUBSTATE_NORMAL then
		FloorMode:Update(dt)
		if UnityTime.frameCount % 100 == 0 then
			GameSDKs:TrackForeign("enter_game_check", {step=15, check_desc ="GameStateFloor:执行Update-FloorMode:Update()"})
		end
	elseif m_currentSubState == SUBSTATE_LOADING then
		if m_currentLoadStep == 1 then
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 1, check_desc ="GameStateFloor:SUBSTATE_LOADING"})
			end
			if not LoadingScreen.m_view then
				LoadingScreen:InitView()
				LoadingScreen:SetLoadingProgress(80)
				--加载场景中
				LoadingScreen:SetLoadingMsg("TXT_LOG_LOADING_9")
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 2, check_desc ="GameStateFloor:没有LoadingScreen,初始化LoadingScreen,并设置进度到80%"})
				end
			else
				if LoadingScreen.m_ShowloginBtn then
					LoadingScreen:ShowLoadingScreen()
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 3, check_desc ="GameStateFloor:LoadingScreen.m_ShowloginBtn有,显示登录界面LoadingScreen:ShowLoadingScreen()"})
					end
				else
					LoadingScreen:SetLoadingProgress(80)
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 4, check_desc ="GameStateFloor:LoadingScreen.m_ShowloginBtn没有,LoadingScreen设置进度到80%"})
					end
				end
			end
			if LoadingScreen.m_view and not LoadingScreen.m_view:IsLoaded() then
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 5, check_desc ="GameStateFloor:LoadingScreen.m_view and not LoadingScreen.m_view:IsLoaded()条件不达成，Update等待条件达成"})
				end
				return
			end

            m_currentLoadStep = m_currentLoadStep + 1
		elseif m_currentLoadStep == 2 then
			if not MainUI.m_view then
				MainUI:GetView()
				CutScreenUI:GetView()
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 6, check_desc ="GameStateFloor:not MainUI.m_view,初始化MainUI:GetView()和CutScreenUI:GetView()"})
				end
			end
			if m_loadSceneHandle then
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 8, check_desc ="GameStateFloor:m_loadSceneHandle已经赋值开始执行场景加载"})
				end
				if m_loadSceneHandle.PercentComplete < 1 then
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 9, check_desc ="GameStateFloor:等待m_loadSceneHandle加载完成，进度:"..tostring(m_loadSceneHandle.PercentComplete)})
					end
					return
				end
				m_activeSceneHandle = m_loadSceneHandle.Result:ActivateAsync()
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 10, check_desc ="GameStateFloor:游戏场景:"..SCENE_DIR.."加载完成，激活使用"})
				end
			else
				m_loadSceneHandle = GameResMgr:ALoadSceneAsync(SCENE_DIR)
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 7, check_desc ="GameStateFloor:开始加载游戏场景:"..SCENE_DIR})
				end
			end
    		m_currentLoadStep = m_currentLoadStep + 1
			collectgarbage("collect")
		elseif m_currentLoadStep == 3 then
            self:LoadingScene()
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 11, check_desc ="GameStateFloor:self:LoadingScene()执行:"..SCENE_DIR})
			end
    	elseif m_currentLoadStep == 4 then
			m_currentLoadStep = m_currentLoadStep + 1
		elseif  m_currentLoadStep == 5 then
            m_currentLoadStep = m_currentLoadStep + 1
    	elseif m_currentLoadStep == 6 then
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 12, check_desc ="启动loading云的UI遮罩"})
			end
			FlyIconsUI:SetScenceSwitchEffect(1, function()
				LoadingScreen:HideLoadingScreen()
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 13, check_desc ="loading云的UI遮罩显示后，隐藏Loading界面完成(LoadingScreen:HideLoadingScreen())"})
				end
				FlyIconsUI:SetScenceSwitchEffect(-1, function()
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 14, check_desc ="loading云的UI遮罩关闭"})
					end
					if not GameConfig.IsIAP() then --只有国内才有
						DeviceUtil.InvokeNativeMethod("userEnterGame")
					end
				end)
			end)
			CityMapUI:CloseView()
			m_currentSubState = SUBSTATE_NORMAL
			FloorMode:Init(m_fllorParams)
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 15, check_desc ="游戏场景进行初始化完成:FloorMode:Init(m_fllorParams)"})
			end
			MainUI:SetPowerBtnState(true)
			GameStateManager:LoadSceneComplete(true)
			m_isScenceLoaded = true
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=16, substep = 16, check_desc ="加载游戏场景流程完成"})
			end
    	end
	end
	--self.___t = TimeManager:GetSocketTime()
end

function GameStateFloor:LoadingScene()
	if not m_loadSceneHandle then
		return
	end

	if m_activeSceneHandle then
		if m_activeSceneHandle.progress < 1 then
			return
		end
		m_activeSceneHandle = nil
	end

	if m_loadSceneHandle.Result and m_loadSceneHandle.PercentComplete >=1 then
		m_floorScene = m_loadSceneHandle.Result.Scene
		GameUIManager:InitFloatCanvas(m_floorScene)
		GameUIManager:AddOverlayUICamera()
		m_currentLoadStep = m_currentLoadStep + 1
		collectgarbage("collect")
	else
		LoadingScreen:SetLoadingProgress(80 + 20 * m_loadSceneHandle.PercentComplete)
	end
    -- local co = coroutine.create(function()
    --     if m_loadSceneHandle then
    --         while m_loadSceneHandle.PercentComplete < 1 do
    --             LoadingScreen:SetLoadingProgress(60 + 40 * m_loadSceneHandle.PercentComplete)
    --             coroutine.yield()
    --         end
    --     end
    --     if m_loadSceneHandle.Result then
    --         m_floorScene = m_loadSceneHandle.Result.Scene
    --         GameUIManager:InitFloatCanvas(m_floorScene)
    --         GameUIManager:AddOverlayUICamera()
    --     end
    --     m_currentLoadStep = m_currentLoadStep + 1
    -- end)
    -- assert(coroutine.resume(co))
end

function GameStateFloor:SetEnteredCallback(callback)
	m_enteredCallback = callback
end

function GameStateFloor:SetParams(params)
	m_fllorParams = params
end

function GameStateFloor:OnLoadedFloorScene()
	if m_enteredCallback then
        m_enteredCallback()
        m_enteredCallback = nil
    end
end

function GameStateFloor:PreLoadGameSfx()
    --SoundEngine:preloadEffect(SoundConst.SFX_MAIL_PAGE_TURN)          
end

function GameStateFloor:UnloadScene()
	if m_loadSceneHandle then
        m_loadSceneHandle = nil
	end
	m_loadSceneHandle = false
end

function GameStateFloor:GetScene()
	return m_floorScene
end

function GameStateFloor:GetMode()
	return FloorMode
end

function GameStateFloor:PreLoadScene(params)
	local config = ConfigMgr.config_floors
	SCENE_DIR = config[params.config.floor_list[1]].scene_name
	m_loadSceneHandle = GameResMgr:ALoadSceneAsync(SCENE_DIR, nil, false)
end

function GameStateFloor:FromOtherStateEnter()
	m_currentSubState = SUBSTATE_LOADING
	m_currentLoadStep = 0
	m_loadSceneHandle = nil
	m_activeSceneHandle = nil
	m_isScenceLoaded = nil
	m_enteredCallback = nil
	m_floorScene = nil
	m_fllorParams = nil
end