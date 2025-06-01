--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{GXY}
    time:2023-09-21 11:58:52
    description:{UI重定向管理}
]]

local GameUIManager = GameTableDefine.GameUIManager
local UIRedirect = GameTableDefine.UIRedirect


local tabelDefineCopy = nil

function UIRedirect:Redirect(activityName)
    local UIRedirectConfig =  GameTableDefine.ConfigMgr.config_ui_redirect --
    if not tabelDefineCopy then
        tabelDefineCopy = {}
        for k,v in ipairs(GameTableDefine) do
            tabelDefineCopy[k] = v
        end
    end

    local activityUITable = UIRedirectConfig[activityName]
    if not activityUITable then
        return
    end
    for k,v in pairs(activityUITable) do
        -- ui代码重定向
        if v.redirectUI and GameTableDefine[v.redirectUI] then
            GameTableDefine[v.ui] = GameTableDefine[v.redirectUI]
        else
            -- ui资源重定向
            if v.redirectPrefab then  -- 如果UI没有重定向,则只替换prefab的路径
                GameUIManager:RedirectPrefab(ENUM_GAME_UITYPE[v.uiType], v.redirectPrefab)
            end
    
        end
    end
end


return UIRedirect