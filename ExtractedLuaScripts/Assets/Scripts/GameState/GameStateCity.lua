
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local GameUIManager = GameTableDefine.GameUIManager
local SoundEngine = GameTableDefine.SoundEngine
local GameStateCity = GameTableDefine.GameStateCity
local CityMode = GameTableDefine.CityMode
local LoadingScreen = GameTableDefine.LoadingScreen
local MainUI = GameTableDefine.MainUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local CutScreenUI = GameTableDefine.CutScreenUI
local CityMapUI = GameTableDefine.CityMapUI
local StateManager = GameStateManager
local FloatUI = GameTableDefine.FloatUI
local ActorManager = GameTableDefine.ActorManager
local GameObject = CS.UnityEngine.GameObject
local UnityTime = CS.UnityEngine.Time

local SUBSTATE_NORMAL = 1
local SUBSTATE_LOADING = 2

local m_currentSubState = nil
local m_currentLoadStep = 0
local m_loadSceneHandle = nil
local m_activeSceneHandle = nil

local m_isScenceLoaded = nil

local m_enteredCallback = nil

local m_cityScene = nil

local timelineGO = nil
local timelineComp = nil
local videoPlayerGO = nil
local videoPlayer = nil
local MainCamera = nil	

local SCENE_DIR = "Assets/Scenes/OpeningScene.unity"

function GameStateCity:Enter()
	-- if m_currentLoadStep == 1 then
	-- 	m_currentSubState = SUBSTATE_NORMAL
	--     CityMode:Init()
	-- else
	-- local hasLoading = CS.Game.GameLauncher.Instance.updater:IsActive()
	m_currentLoadStep = 1
	m_currentSubState = SUBSTATE_LOADING

	self:OnLoadedCityScene()
	-- end
	ActorManager:OnStateEnter(GameStateManager.GAME_STATE_CITY) -- 在state进入后处理状态进入逻辑, 避免空引用

end

function GameStateCity:Exit()
	ActorManager:OnStateExit(GameStateManager.GAME_STATE_CITY) -- 在state退出前处理状态退出逻辑, 避免空引用
	FloatUI:DestroyAllFloatUIView()
	-- SoundEngine:StopBackgroundMusic()
	CityMode:OnExit()
	m_loadSceneHandle = nil
	-- m_isScenceLoaded = -1
	collectgarbage("collect")
end

function GameStateCity:Update(dt)
	if m_currentSubState == SUBSTATE_NORMAL then
		CityMode:Update(dt)
		if UnityTime.frameCount % 100 == 0 then
			GameSDKs:TrackForeign("enter_game_check", {step=17, check_desc ="GameStateCity:执行Update-CityMode:Update(dt)"})
		end
	elseif m_currentSubState == SUBSTATE_LOADING then
		if m_currentLoadStep == 1 then
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 1, check_desc ="GameStateCity:SUBSTATE_LOADING"})
			end
			if not LoadingScreen.m_view then
				LoadingScreen:InitView()
				LoadingScreen:SetLoadingProgress(60)
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 2, check_desc ="GameStateCity:没有LoadingScreen,初始化LoadingScreen,并设置进度到70%"})
				end
			else
				if LoadingScreen.m_ShowloginBtn then
					LoadingScreen:ShowLoadingScreen()
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 3, check_desc ="GameStateCity:LoadingScreen.m_ShowloginBtn有,显示登录界面LoadingScreen:ShowLoadingScreen()"})
					end
				else
					LoadingScreen:SetLoadingProgress(63)
					if UnityTime.frameCount % 100 == 0 then
						GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 4, check_desc ="GameStateCity:LoadingScreen.m_ShowloginBtn没有,LoadingScreen设置进度到70%"})
					end
				end
			end
			if LoadingScreen.m_view and not LoadingScreen.m_view:IsLoaded() then
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 5, check_desc ="GameStateCity:LoadingScreen.m_view and not LoadingScreen.m_view:IsLoaded()条件不达成，Update等待条件达成"})
				end
				return
			end
			m_currentLoadStep = m_currentLoadStep + 1
		elseif m_currentLoadStep == 2 then
			if not MainUI.m_view then
				MainUI:GetView()
				CutScreenUI:GetView()
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 6, check_desc ="GameStateCity:not MainUI.m_view,初始化MainUI:GetView()和CutScreenUI:GetView()"})
				end
			end
			if LocalDataManager:IsNewPlayerRecord() then
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 7, check_desc ="GameStateCity:新玩家阶段就是没有给公司取名前都要重复执行这块内容的"})
				end
				if m_loadSceneHandle then
					if m_loadSceneHandle.PercentComplete < 1 then
						return
					end
					m_activeSceneHandle = m_loadSceneHandle.Result:ActivateAsync()
				else
					m_loadSceneHandle = GameResMgr:ALoadSceneAsync(SCENE_DIR)
				end
				m_currentLoadStep = m_currentLoadStep + 1
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 8, check_desc ="GameStateCity:新玩家阶段加载角色选择和取名字场景完成并激活使用"})
				end
			else
				CityMapUI:ShowMap()
				LoadingScreen:SetLoadingProgress(100)
				m_currentLoadStep = m_currentLoadStep + 3
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 8, check_desc ="GameStateCity:非新玩家阶段加载角色选择和取名字场景完成并激活使用"})
				end
			end
		elseif m_currentLoadStep == 3 then
			self:LoadingScene()
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 9, check_desc ="GameStateCity:取名场景加载完成后的一些相关的逻辑执行完成LoadingScene()"})
			end
		elseif m_currentLoadStep == 4 then
			m_currentLoadStep = m_currentLoadStep + 2
		elseif  m_currentLoadStep == 5 then
			if not CityMapUI.m_view or not CityMapUI.m_view:IsLoaded() then
				if UnityTime.frameCount % 100 == 0 then
					GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 10, check_desc ="GameStateCity:等待CityMapUI.m_view和CityMapUI.m_view:IsLoaded()执行完成"})
				end
				return
			end
			m_currentLoadStep = m_currentLoadStep + 1
		elseif m_currentLoadStep == 6 then
			m_currentSubState = SUBSTATE_NORMAL
			CityMode:Init()

			--MainUI:Init(false)
			MainUI:ChangeUIStatus(false)
			if UnityTime.frameCount % 100 == 0 then
				GameSDKs:TrackForeign("enter_game_check", {step=17, substep = 10, check_desc ="GameStateCity:设置m_currentSubState = SUBSTATE_NORMAL MainUI:ChangeUIStatus(false)CityMode:Init()执行完成"})
			end
			-- GameStateManager:LoadSceneComplete()
		end
	end
end

function GameStateCity:SetParams(params)
end

function GameStateCity:LoadingScene()
	if not m_loadSceneHandle then
		return
	end
	if m_activeSceneHandle then
		if m_activeSceneHandle.progress < 1 then
			return
		end
		m_activeSceneHandle = nil
	end
	if m_loadSceneHandle.Result and m_loadSceneHandle.PercentComplete >= 1 then
		m_cityScene = m_loadSceneHandle.Result.Scene
		-- GameUIManager:InitFloatCanvas(m_cityScene)
		if not timelineGO or not videoPlayerGO then
			GameUIManager:AddOverlayUICamera()
			local roots = m_cityScene:GetRootGameObjects()
			for i = 0, roots.Length - 1 do
				if roots[i].name == "OpeningTimeline" then
					timelineGO = roots[i]
				end
				if roots[i].name == "Canvas" then
					videoPlayerGO = roots[i]
				end
				if roots[i].name == "Main Camera" then
					MainCamera = roots[i]
				end
			end
			timelineComp = timelineGO:GetComponent("PlayableDirector")
			videoPlayer = videoPlayerGO:GetComponentInChildren(typeof(CS.UnityEngine.Video.VideoPlayer), true)
			videoPlayer:Prepare()
		end

		if timelineComp and videoPlayer.isPrepared then
			m_currentLoadStep = m_currentLoadStep + 1
			MainCamera:SetActive(true)
			timelineComp:Play()
			LoadingScreen:HideLoadingScreen()

		end
		
	else
		LoadingScreen:SetLoadingProgress(80 + 20 * m_loadSceneHandle.PercentComplete)
	end
end

function GameStateCity:SetEnteredCallback(callback)
	m_enteredCallback = callback
end

function GameStateCity:OnLoadedCityScene()--没地方用
	if m_enteredCallback then
		m_enteredCallback()
		m_enteredCallback = nil
	end
end

function GameStateCity:PreLoadGameSfx()
	--SoundEngine:preloadEffect(SoundConst.SFX_MAIL_PAGE_TURN)
end

function GameStateCity:UnloadScene()
	if m_loadSceneHandle then
		m_loadSceneHandle = nil
	end
end

function GameStateCity:GetScene()
	return m_cityScene
end

function GameStateCity:GetMode()
	return CityMode
end

function GameStateCity:PreLoadScene()
	m_loadSceneHandle = GameResMgr:ALoadSceneAsync(SCENE_DIR, nil, false)
end