local XLuaUtils = require ("Framework.Lua.XLuaUtils")

local ResMgr = CS.Common.Utils.ResManager.Instance
local LoadSceneMode = CS.UnityEngine.SceneManagement.LoadSceneMode
local Resources = CS.UnityEngine.Resources
local Sprite = CS.UnityEngine.Sprite

---@class GameResMgr
local GameResMgr = 
{
    -- m_handles = {},
}

-- 同步加载资源
-- 注意:此同步方法只能加载Resources目录下的本地资源!!!
function GameResMgr:LoadSync(path)
    return ResMgr:Load(path)
end

-- 同步加载资源
-- 注意:此同步方法只能加载Resources目录下的本地资源!!!
function GameResMgr:LoadSpriteSync(path)
    return Resources.Load(path, typeof(Sprite))
end

local function _ALoadSync(path, obj, cb)
    ResMgr:LuaAPI_ALoadSync(path, obj, function(h)
        cb(h)
    end)
end

-- 同步加载资源
-- 注意:此同步方法必须在协程中使用!!!
function GameResMgr:ALoadSync(path, refer)
    refer = refer and address(refer) or refer
    local sync = XLuaUtils.async_to_sync(_ALoadSync)
    local handle = sync(path, refer or self)
    -- print("GameResMgr:ALoadSync", handle.Result)
    return handle and handle.Result
end

local function _AInstantiateSync(path, obj, cb)
    ResMgr:LuaAPI_AInstantiateObjectASync(path, obj, function(o)
        --print("GameResMgr:_AInstantiateSync", path, o)
        cb(o)
    end)
end

-- 同步实例化资源
-- 此同步方法必须在协程中使用
function GameResMgr:AInstantiateSync(path, refer)
    refer = refer and address(refer) or refer
    -- print("call AInstantiateSync: ", path, refer)
    local instantiate = XLuaUtils.async_to_sync(_AInstantiateSync)
    local obj = instantiate(path, refer or self)
    -- print("GameResMgr:AInstantiateSync", path, handle, handle.Result)
    return obj
end

local function _AInstantiateObjectSync(path, cb)
    ResMgr:LuaAPI_AInstantiateObjectSync(path, function(o)
        cb(o)
    end)
end

-- 同步实例化Object,并释放原始资源
-- 此同步方法必须在协程中使用
function GameResMgr:AInstantiateObjectSync(path)
    local instantiate = XLuaUtils.async_to_sync(_AInstantiateObjectSync)
    local obj = instantiate(path)
    -- print("GameResMgr:AInstantiateSync", handle.Result)
    return obj
end

-- 异步加载资源
function GameResMgr:ALoadAsync(path, refer, cb)
    refer = refer and address(refer) or refer
    if cb and type(cb) == "function" then
        _ALoadSync(path, refer, cb)
    else
        return nil -- ResMgr:ALoadAsync(path, refer or self)
    end
end

-- 异步实例化资源
-- function GameResMgr:AInstantiateAsync(path, refer)
--     local refer = refer and address(refer) or refer
--     return ResMgr:AInstantiateAsync(path, refer or self)
-- end

-- 异步实例化GameObject，手动回收资源
function GameResMgr:AInstantiateObjectAsyncManual(path, refer, cb)
    refer = refer and address(refer) or refer
    return ResMgr:LuaAPI_AInstantiateObjectASync(path, refer, cb)
end

-- 异步实例化Object，并释放原始资源
-- function GameResMgr:AInstantiateObjectAsync(path, cb)
--     return ResMgr:LuaAPI_AInstantiateObjectSync(path, cb)
-- end

-- 异步实例化场景
function GameResMgr:ALoadSceneAsync(path, loadMode, activateOnLoad, priority)
    loadMode = (1 == loadMode) and LoadSceneMode.Additive or LoadSceneMode.Single
    activateOnLoad = (nil == activateOnLoad) and true or activateOnLoad
    priority = (nil == priority) and 100 or activateOnLoad
    -- print(path, loadMode, activateOnLoad, priority)
    return ResMgr:ALoadSceneAsync(path, loadMode, activateOnLoad, priority)
end

-- 释放一个引用者引用的资源
function GameResMgr:Unload(refer)
    refer = refer and address(refer) or refer
    ResMgr:AUnload(refer)
end

-- 释放全部没有引用的资源
function GameResMgr:UnloadUnused()
    ResMgr:AUnloadUnused()
end

-- 异步释放一个场景
function GameResMgr:UnloadSceneAsync(handle, autoReleaseHandle)
    return ResMgr:UnloadSceneAsync(handle, autoReleaseHandle)
end

-- 预加载一张图集
function GameResMgr:PreloadSpriteAltas(atlas, isSync, refer, cb)
    local path = string.format("Assets/Res/SpriteAltas/%s.spriteatlas", atlas)
    if isSync then
        return self:LoadSpriteSyncFree(path, refer)
    else

    refer = refer and address(refer) or refer
    self:ALoadAsync(path, refer, function()
        print("PreloadSpriteAltas done!!")
        if cb then cb() end
    end)
    end
end

-- 无限制同步加载图集方法
function GameResMgr:LoadSpriteSyncFree(path, refer)
    refer = refer and address(refer) or refer
    return ResMgr:LuaAPI_LoadSpriteAltasSync(path, refer)
end

-- 无限制同步加载材质方法
function GameResMgr:LoadMaterialSyncFree(path, refer)
    refer = refer and address(refer) or refer
    return ResMgr:LuaAPI_LoadMaterialSync(path, refer)
end

-- 无限制同步加载贴图方法
function GameResMgr:LoadTextureSyncFree(path, refer)
    refer = refer and address(refer) or refer
    return ResMgr:LuaAPI_LoadTextureSync(path, refer)
end

-- 无限制同步加载文本方法
function GameResMgr:LoadTxtSyncFree(path, refer)
    refer = refer and address(refer) or refer
    return ResMgr:LuaAPI_LoadTxtSync(path, refer)
end

return GameResMgr
