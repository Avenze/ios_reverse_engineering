--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-09-10 14:47:58
]]
local RateUI = GameTableDefine.RateUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local DeviceUtil = CS.Game.Plat.DeviceUtil

function RateUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.RATE_UI, self.m_view, require("GamePlay.Common.UI.RateUIView"), self, self.CloseView)
    return self.m_view
end

function RateUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.RATE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function RateUI:ShowPanel()
    if GameConfig:IsWarriorVersion() then
        local cfg = ConfigMgr.config_global.rate_reward
        EventManager:DispatchEvent("FLY_ICON", nil, cfg[1], cfg[2])
        GameTableDefine.ResourceManger:Add(cfg[1], cfg[2])
        --2024-8-20添加用于钞票消耗增加埋点上传
        local type = 1
        local amount = cfg[2]
        local change = 0
        local position = "评分奖励"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
        DeviceUtil.RequestReview()
    else
        self:GetView()
    end
end

function RateUI:CollectRewards(pos, level)
    local cfg = ConfigMgr.config_global.rate_reward
    EventManager:DispatchEvent("FLY_ICON", pos, cfg[1], cfg[2])
    GameTableDefine.ResourceManger:Add(cfg[1], cfg[2])
     --2024-8-20添加用于钞票消耗增加埋点上传
     local type = 1
     local amount = cfg[2]
     local change = 0
     local position = "评分奖励"
     GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
    if level > 2 then
        DeviceUtil.RequestReview()
    end
end

