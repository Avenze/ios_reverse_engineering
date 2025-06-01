
---@class LoadingScreen
local LoadingScreen = GameTableDefine.LoadingScreen
local SoundEngine = GameTableDefine.SoundEngine
local GameUIManager = GameTableDefine.GameUIManager
local ChooseUI = GameTableDefine.ChooseUI
local LaunchView = require("GamePlay.Launch.View")
local GameResMgr = require("GameUtils.GameResManager")
-- require("ConfigData.ConfigFuncVariable")

local _currentLoadingProgress = 0
local _loadingTips = nil

function LoadingScreen:InitView()
	if GameStateManager.m_loadSceneComplete then
		return
	end

	if not self.m_view or not self.m_view:IsValid()then
		self.m_view = LaunchView.new()
		GameUIManager:OpenUI(ENUM_GAME_UITYPE.LAUNCH, self.m_view)
	end
	ChooseUI:CloseView()
end

function LoadingScreen:DestroyView()
	GameUIManager:CloseUI(ENUM_GAME_UITYPE.LAUNCH)
	self.m_view = nil
end

function LoadingScreen:ShowLoadingScreen()
	if not self.m_view then
		return
	end
	--SoundEngine:PlayBackgroundMusic(SoundConst.MUSIC_LOGO, true)
	self.m_view:Invoke("ShowLoadingScreen")
	self.m_ShowloginBtn = nil
	ChooseUI:CloseView()
end

function LoadingScreen:HideLoadingScreen()
	-- SoundEngine:StopBackgroundMusic()
	GameResMgr:UnloadUnused()
	collectgarbage("collect")
    LoadingScreen:DestroyView()
end

function LoadingScreen:SetLoadingProgress(percentage, msg)
	print("SetLoadingProgress: ", percentage)
	if not self.m_view or not self.m_view:IsValid() then return end
	self.m_view:Invoke("SetLoadingProgress", tonumber(percentage), msg)
end

function LoadingScreen:SetLoadingMsg(msg)
	if msg and msg ~= "" then
		if not self.m_view or not self.m_view:IsValid() then return end
		self.m_view:Invoke("SetLoadingMsg", msg)
	end
end

function LoadingScreen:InitLoadingProgress()
	_currentLoadingProgress = 0
end

function LoadingScreen:IncreaseProgress(value)
	_currentLoadingProgress = _currentLoadingProgress + value
	_currentLoadingProgress = math.min(100, _currentLoadingProgress)

	self:SetLoadingProgress(_currentLoadingProgress)
end

function LoadingScreen:ResetLoadingTips()
	_loadingTips = nil
end

function LoadingScreen:WarriorLoginBtn()
	local data = LocalDataManager:GetDataByKey("user_data")
	-- if data.cur_type and data.cur_type ~= GameSDKs.LoginType.tourist then
	-- 	GameSDKs:Warrior_login(data.cur_type, true)
	-- 	return
	-- end
	
	-- =====2023-7-10修改成全部自动登录，不管是游客还是第三方登录
	if data.cur_type then
		GameSDKs:Warrior_login(data.cur_type, true)
	else
		GameSDKs:Warrior_login(GameSDKs.LoginType.tourist, true)
	end
	--CS.Game.GameLauncher.Instance.updater:SetProgress(70.0)
	-- =====2023-7-10修改成全部自动登录，不管是游客还是第三方登录
	
	-- self.m_ShowloginBtn = true
	-- CS.Game.GameLauncher.Instance.updater:SetProgress(100.0)
	-- GameTimer:CreateNewMilliSecTimer(500, function ()
	-- 	LoadingScreen:InitView()
	-- 	self.m_view:Invoke("WarriorLoginBtn")
	-- end)
end

function LoadingScreen:ShowWaitingEffect()
	if not self.m_view then
		LoadingScreen:InitView()
	end
    self.m_view:Invoke("ShowWaitingEffect")
end

function LoadingScreen:HideWaitingEffect()
	if not self.m_view then
		LoadingScreen:InitView()
	end
    self.m_view:Invoke("HideWaitingEffect")
end
