--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 16:09:02
    副本活动的State类，用于副本活动入口和公用函数管理对象
]]
local GameStateDuplicate = GameTableDefine.GameStateDuplicate
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local GameUIManager = GameTableDefine.GameUIManager
local FlyIconsUI = GameTableDefine.FlyIconsUI
local MainUI = GameTableDefine.MainUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FloatUI = GameTableDefine.FloatUI

local SUBSTATE_NORMAL = 1
local SUBSTATE_LOADING = 2

local m_currentSubState = nil
local m_currentLoadStep = 0
local m_loadSceneHandle = nil
local m_activeSceneHandle = nil

local m_isSceneLoaded = nil
local m_enteredCallback = nil
local m_duplicateScene = nil
local m_fllorParam = nil
local m_canBeginLoad = false
local SCENE_DIR = "Assets/Scenes/Instance101.unity"

function GameStateDuplicate:Enter()
    --TODO:
    FlyIconsUI:SetScenceSwitchEffect(1, function()
        m_currentLoadStep = 1
        m_currentSubState = SUBSTATE_LOADING
    end) 
end

function GameStateDuplicate:Exit()
    FloatUI:DestroyAllFloatUIView()
    m_isSceneLoaded = nil
    m_loadSceneHandle = nil
    m_currentSubState = nil
    m_canBeginLoad = false
    --TODO:场景管理的一些处理，看是否需要删除创建的动态对象什么的，一般来说GameObject只要切换场景就会销毁了
    collectgarbage("collect")
end

function GameStateDuplicate:Update(dt)
    if m_currentSubState == SUBSTATE_NORMAL then
        --TODO:执行场景管理器上的Update逻辑比如计算产出等等
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
                m_loadSceneHandle = GameResMgr:ALoadSceneAsync(SCENE_DIR)
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
            m_currentSubState = SUBSTATE_NORMAL
            FlyIconsUI:SetScenceSwitchEffect(-1)
            MainUI:CloseView()

            GameStateManager:LoadInstanceSceneComplate()
            m_isSceneLoaded = true
        end
    end
end

function GameStateDuplicate:LoadingScene()
    if not m_loadSceneHandle then
        print("GameStateDuplicate:LoadingScene:Error,not loading Scene Exception")
        return
    end

    if m_activeSceneHandle then
        if m_activeSceneHandle.progress < 1 then
            return
        end
        m_activeSceneHandle = nil
    end

    if m_loadSceneHandle.Result and m_loadSceneHandle.PercentComplete >= 1 then
        m_duplicateScene = m_loadSceneHandle.Result.Scene
        GameUIManager:InitFloatCanvas(m_duplicateScene)
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
function GameStateDuplicate:EnterDuplicate()
    --TODO:调用副本UI'显示的初始化流程，包含需要显示离线奖励的界面等等,房间初始化等等相关逻辑
end

function GameStateDuplicate:SetEnteredCallback(callback)

end

function GameStateDuplicate:SetParams(params)

end

