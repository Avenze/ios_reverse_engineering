--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 16:09:02
    副本活动的State类，用于副本活动入口和公用函数管理对象
]]
local GameStateInstance = GameTableDefine.GameStateInstance
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local GameUIManager = GameTableDefine.GameUIManager
local FlyIconsUI = GameTableDefine.FlyIconsUI
local MainUI = GameTableDefine.MainUI
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI 
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FloatUI = GameTableDefine.FloatUI
local ActorManager = GameTableDefine.ActorManager

local SUBSTATE_NORMAL = 1
local SUBSTATE_LOADING = 2

local m_currentSubState = nil
local m_currentLoadStep = 0
local m_loadSceneHandle = nil
local m_activeSceneHandle = nil

local m_isSceneLoaded = nil
local m_enteredCallback = nil
local m_InstanceScene = nil
local m_fllorParam = nil
local m_canBeginLoad = false
local SCENE_DIR = "Assets/Scenes/%s.unity"

function GameStateInstance:Enter()
    
    FlyIconsUI:SetScenceSwitchEffect(1, function()
        m_currentLoadStep = 1
        m_currentSubState = SUBSTATE_LOADING
    end) 
    --手动释放一下FloorMode的Exit
    GameTableDefine.FloorMode:OnExit()
    --GameTableDefine.AZhenMessage:Clear()
    ActorManager:OnStateEnter(GameStateManager.GAME_STATE_INSTANCE) -- 在state进入后处理状态进入逻辑, 避免空引用

end

function GameStateInstance:Exit()
    ActorManager:OnStateExit(GameStateManager.GAME_STATE_INSTANCE) -- 在state退出前处理状态退出逻辑, 避免空引用
    FloatUI:DestroyAllFloatUIView()

    m_isSceneLoaded = nil
    m_loadSceneHandle = nil
    m_currentSubState = nil
    m_canBeginLoad = false
    MainUI:Hideing(true)
    
    --TODO:场景管理的一些处理，看是否需要删除创建的动态对象什么的，一般来说GameObject只要切换场景就会销毁了
    InstanceModel:OnExit()
    InstanceDataManager:OnPause()
    collectgarbage("collect")
end

function GameStateInstance:Update(dt)
    if m_currentSubState == SUBSTATE_NORMAL then
        InstanceModel:Update(dt)
        return
    end

    if m_currentSubState == SUBSTATE_LOADING then
        if m_currentLoadStep == 1 then
            m_currentLoadStep  = m_currentLoadStep + 1
        elseif m_currentLoadStep == 2 then
            if m_loadSceneHandle then
                if m_loadSceneHandle.PercentComplete < 1 then
                    --还在场景加载中
                    return
                end
                m_activeSceneHandle = m_loadSceneHandle.Result:ActivateAsync()
            else
                local sceneName = InstanceDataManager:GetInstanceBind().scene
                sceneName = string.format(SCENE_DIR,sceneName)
                m_loadSceneHandle = GameResMgr:ALoadSceneAsync(sceneName)
            end
            m_currentLoadStep  = m_currentLoadStep + 1
            collectgarbage("collect")
        elseif m_currentLoadStep == 3 then
            self:LoadingScene()
        elseif m_currentLoadStep == 4 then
            m_currentLoadStep  = m_currentLoadStep + 1
        elseif m_currentLoadStep == 5 then
            m_currentLoadStep  = m_currentLoadStep + 1
        elseif m_currentLoadStep == 6 then
            GameStateManager:LoadInstanceSceneComplate() --先完成数据的初始化等行为再打开UI 
            m_currentSubState = SUBSTATE_NORMAL
            --控制云打开的时间
            GameTimer:CreateNewTimer(2.5, function()     
                FlyIconsUI:SetScenceSwitchEffect(-1)
            end)            
            MainUI:Hideing()
            InstanceMainViewUI:OpenUI()
            m_isSceneLoaded = true
            

        end
    end
end

function GameStateInstance:LoadingScene()
    if not m_loadSceneHandle then
        print("GameStateInstance:LoadingScene:Error,not loading Scene Exception")
        return
    end

    if m_activeSceneHandle then
        if m_activeSceneHandle.progress < 1 then
            return
        end
        m_activeSceneHandle = nil
    end

    if m_loadSceneHandle.Result and m_loadSceneHandle.PercentComplete >= 1 then
        m_InstanceScene = m_loadSceneHandle.Result.Scene
        GameUIManager:InitFloatCanvas(m_InstanceScene)
        GameUIManager:AddOverlayUICamera()
        m_currentLoadStep  = m_currentLoadStep + 1
        collectgarbage("collect")
    end
end

--[[
    @desc: 初始化场景完成进入副本场景的初始化相关内容
    author:{author}
    time:2023-03-24 10:22:12
    @return:
]]
function GameStateInstance:EnterInstance()
    InstanceModel:Init()
    
    InstanceModel:OnEnter()
    InstanceDataManager:EnterInstance()
end

function GameStateInstance:SetEnteredCallback(callback)

end

function GameStateInstance:SetParams(params)

end

