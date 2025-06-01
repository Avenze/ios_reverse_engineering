emmyLuaDebug = false
requireRemoveConfig = true
function enableEmmyLuaDebug()
    if emmyLuaDebug then
        local dbg = require('emmy_core')
        dbg.tcpConnect('::1', 9966)
    end
end
if emmyLuaDebug then
    package.cpath = package.cpath .. ';C:/Users/Microsoft-JZJ/AppData/Roaming/JetBrains/Rider2023.2/plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
end
enableEmmyLuaDebug()
require("GameUtils.GameDeviceManager")
require("GameBase.GameConfig")
require("GameUtils.GameTools")

local Execute = require("Framework.Queue.Execute");
local LocalDataMgr = nil
local UIManager = nil
local Timer = nil
local StateManager = nil
local GameLauncher = CS.Game.GameLauncher.Instance
ConfigLoadOver = false

print("======game lua main =======")

function dofile(n)
    local f, err = loadfile(n)
    if f then
        return f(), err
    else
        return nil, err
    end
end

loadstring = load;

function lprintf(...)
    print(string.format(...));
end

function handler(obj, method)
    return function(...)
       return method(obj, ...)
    end
end

function address(obj)
    return string.format("%s", obj);
end

local IsPause = false
local configs = 
{
    -- "Assets/Configs/VersionInfo.txt",
}

function InitConfigs()
    local GameResMgr = require("GameUtils.GameResManager");
    local count = 0;
    for _, v in ipairs(configs) do
        GameResMgr:ALoadAsync(v, configs, function(handler)
            load(handler.Result.text)();
            count = count + 1;
            if #configs == count then
                GameResMgr:Unload(configs)
            end
        end);
    end
end

function Awake()
    print("lua Awake")
    if GameConfig:IsDebugMode() then
        if GameDeviceManager:IsiOSDevice() then
            pcall(function()
                _debug_breakSocketHandle, _debug_xpCall, _debug_updateCounter = require("LuaDebug")("192.168.110.249", 7007)
            end)
        elseif GameDeviceManager:IsAndroidDevice() then
            pcall(function()
                _debug_breakSocketHandle, _debug_xpCall, _debug_updateCounter = require("LuaDebug")("192.168.110.249", 7007)
            end)
            
        else
            pcall(function()
                _debug_breakSocketHandle, _debug_xpCall, _debug_updateCounter = require("LuaDebug")("127.0.0.1", 7007)
            end)
        end
    end
    GameTools:AddTimePoint("LuaAwake")
    CS.UnityEngine.Application.targetFrameRate = tonumber(CS.Game.GameDefine.VersionInfo.FrameRate)
    --InitConfigs();
    require("GameBase.GameEntry")
    GameLauncher.updater:SetProgress(30)

    StateManager = GameStateManager
    LocalDataMgr = LocalDataManager
    UIManager = GameTableDefine.GameUIManager
    Timer = GameTimer
    GameTools:CalcTimePointCost("LuaAwake")
    --GameTableDefine.ConfigMgr:DynamicLoadConfig(function()
    --    CS.Common.Utils.XLuaManager.Instance:UnloadUnUseLuaFiles()
    --    ConfigLoadOver = true
    --    -- GameSDKs:TrackForeign("init", {init_id = 5, init_desc = "脚本初始化"})
    --    GameTableDefine.LoadingScreen:SetLoadingMsg("脚本初始化")
    --    GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_1"))
    --end)
    StateManager:Init()
end

function Init()
end

function Update(dt)
    Timer:Update(dt)
    UIManager:Update(dt)
    
    if ConfigLoadOver then
        if not IsPause then
            Execute:Update(dt)
            --GameSkyNetProxy:update(dt)
            StateManager:Update(dt)
            LocalDataMgr:Update()
            if _debug_breakSocketHandle then
                _debug_updateCounter = _debug_breakSocketHandle(_debug_updateCounter)
            end
        end
        GameTableDefine.OfflineManager:OnUpdate()
    end
end 

function Quit()
    if not ConfigLoadOver then
        return
    end
    print("lua Quit")
    GameTableDefine.OfflineManager:OnQuit()
    StateManager.m_statePause = true
    CS.Game.Plat.DeviceUtil.RegisterLowMemHandler(nil)
    CS.Common.Utils.ExceptionManager.Instance:SetExceptionCallback(nil)
    StateManager:Clear()
    UIManager:Clear()
    LocalDataMgr:WriteToFileInmmediately()
    
    local ResMgr = CS.Common.Utils.ResManager.Instance
    ResMgr:AUnloadAll()
end

function Destory()
    print("lua Destory")
end

function Pause(pause, custom)
    print("lua Pause state->", pause)
    if not ConfigLoadOver then
        return
    end
    if pause then
        if custom then
            GameTableDefine.OfflineManager:OnPause(custom)
            return
        end
        IsPause = true
        GameStateManager:OnPause()
        LocalDataMgr:WriteToFileInmmediately()
    else
        GameTimer:CreateNewMilliSecTimer(200, function()
            IsPause = false
            GameStateManager:OnResume()
        end)
        
    end
end


-- Lua: 创建一个全局表来存储C#回调
CSharpCallbacks = {}

function RegisterCallback(key, callback)
    CSharpCallbacks[key] = callback
end

function UnregisterCallback(key)
    CSharpCallbacks[key] = nil
end

function ClearAllCallbacks()
    for key, _ in pairs(CSharpCallbacks) do
        CSharpCallbacks[key] = nil
    end
end
