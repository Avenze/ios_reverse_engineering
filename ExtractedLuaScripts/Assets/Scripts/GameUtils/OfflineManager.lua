--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-10-27 12:18:57
    description:离线管理器, 用于获取游戏(主场景)的离线时长, 副本/足球俱乐部等暂时不再此处管理(因为这些场景的退出和进入的条件判断与游戏主体不同)
]]
---@class OfflineManager
local OfflineManager = GameTableDefine.OfflineManager
local ShopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local CountryMode = GameTableDefine.CountryMode

local UnityHelper = CS.Common.Utils.UnityHelper;
local EventManager = require("Framework.Event.Manager")


local OFFLINE_START = 120 -- 离线奖励界限, 两分钟, 单位s
local LAST_GAME_TIME = "last_game_time"
local OFFLINE = "offline"

local haveInit = false

---@class OfflineStruct
---@field offlineTime number
---@field offlineTimeSum number
---@field offlineReward number
---@field reachMaximum boolean
local offlineStructDefine = {}

---@class offlineData
---@field exitTime number
---@field enterTime number
---@field playAD boolean
---@field areaData table<number, OfflineStruct>
local offlineDataDefine = {}


function OfflineManager:Init()
    if haveInit then 
        return 
    end
    haveInit = true
    self.offlineData = nil  ---@type offlineData
    self.oldOfflineTime = nil   
    
    self.offlineData = LocalDataManager:GetDataByKey(OFFLINE)  ---@type offlineData
    self:NewDataReplaceOldData()
    self:InitNewOfflineData()
    self:RegisterADEvent()

    local trace = debug.traceback() or ""
    GameSDKs:TrackForeign("debugger", { system = "Offline", desc = "OfflineManager.Init", value = self.offlineData.exitTime .. "\n" .. trace })
    -- 进入游戏时将playAD标记为false
    self.offlineData.playAD = false
    -- 进入游戏时设置EnterTime
    self.offlineData.enterTime = GameTimeManager:GetCurrentServerTime(true)
    -- 检查ExitTime是否正常(断网退出)
    if not self.offlineData.exitTime or self.offlineData.exitTime == 0 then
        self.offlineData.exitTime = GameTimeManager:GetCurrentServerTime(true)
    end

    --计算离线时长
    self.m_offline = self:GetOffline()
end

---获取离线奖励
---@return number 未经过处理的离线时长
function OfflineManager:GetOffline()    
    local offlineTime = self.offlineData.enterTime - self.offlineData.exitTime
    if offlineTime < OFFLINE_START then
        -- 离线时常不到两分钟,
    else
        -- 离线时长超过两分钟, 计算离线奖励
        self:UpdataOfflineData(offlineTime)
        self.offlineData.exitTime = 0
        self.offlineData.enterTime = 0
    end
    return offlineTime
end

function OfflineManager:UpdataOfflineData(offlineTime)
    local areaData = self.offlineData.areaData
    for k, v in ipairs(areaData) do
        local curOfflineTime = offlineTime
        
        -- 刷新OfflineTime
        -- TEMP K125取消计算离线时长时上限的限制
        local maxTime = 9999999999999 or self:GetOfflineMaxTime(k)
        curOfflineTime = math.min(curOfflineTime, maxTime)
        if v.offlineTime + curOfflineTime > maxTime then
            curOfflineTime = maxTime - v.offlineTime
        end
        v.offlineTime = v.offlineTime + curOfflineTime
        v.offlineTime = math.min(v.offlineTime, maxTime)
        
        -- 刷新OfflineReward
        local curReward = self:CalculateOfflineReward(k, curOfflineTime)
        v.offlineReward = v.offlineReward + curReward
        local currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[k]).currBuidlingId or 100
        local maxReward = ConfigMgr.config_buildings[currCity].offline_reward_limit
        v.reachMaximum = v.offlineReward > maxReward
        v.offlineReward = math.min(v.offlineReward, maxReward)
        
        -- 地区未解锁处理, 将累计时长也设置为0 
        v.offlineTime = v.offlineReward and v.offlineReward == 0 and 0 or v.offlineTime or 0
        v.offlineTimeSum = (v.offlineTimeSum or 0) + offlineTime
    end
end

function OfflineManager:CalculateOfflineReward(countryID, offlineTime)
    local cashTimes = math.floor(offlineTime / 30)
    local totalRent = FloorMode:GetTotalRent(nil, countryID)                   --总时长都没满
    local reward = cashTimes * totalRent * FloorMode:OfflineRewardRate(countryID)
    reward = math.floor(reward)
    return reward
end

---用新存档替换旧的存档
function OfflineManager:NewDataReplaceOldData()
    local oldData = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
    if oldData.abandoned then
        return
    end
    
    local now = GameTimeManager:GetCurrentServerTime(true)
    if next(self.offlineData) == nil then
        self.offlineData.exitTime = now
    end

    oldData.abandoned = true
    LocalDataManager:WriteToFile()
end

---初始化新的离线数据结构
function OfflineManager:InitNewOfflineData()
    if not self.offlineData.areaData then
        local countryConfig = ConfigMgr.config_country
        self.offlineData.areaData = {}
        for k, v in ipairs(countryConfig) do
            self.offlineData.areaData[k] = {
                offlineTime = 0,
                offlineReward = 0,
            }
        end
    end
end

---注册播放广告事件
function OfflineManager:RegisterADEvent()
    --1、广告播放时，不会进入离线计算流程
    --2、在广告界面一直挂机，保持游戏的运行状态（和之前一样）
    --3、在广告界面切到后台，也不会进入离线计算流程（但是如果杀掉app或者回来后app重启，需要有离线奖励的结算
    EventManager:RegEvent("PLAY_AD", function()
        self.offlineData.playAD = true
    end)
    EventManager:RegEvent("PLAY_AD_END", function()
        self.offlineData.playAD = false
        --计算离线时长
        --self.m_offline = self:GetOffline()
    end)
end

function OfflineManager:GreaterThanOffline(offline)
    return (offline or 0) >= OFFLINE_START
end

function OfflineManager:OnResume()
    if self.offlineData.playAD then
        return
    end

    self.offlineData.Received = nil
    self.offlineData.enterTime = GameTimeManager:GetCurrentServerTime(true)
    --检查ExitTime是否正常(断网退出)
    if not self.offlineData.exitTime then
        self.offlineData.exitTime = GameTimeManager:GetCurrentServerTime(true)
    end
    self.m_offline = self:GetOffline()
    if not self.offlineData.playAD and self:GreaterThanOffline(self.m_offline or 0) then
        GameTableDefine.OfflineRewardUI:CloseView() -- 先关再开  确保刷新
        GameTableDefine.OfflineRewardUI:LoopCheckRewardValue(function()
            GameTableDefine.OfflineRewardUI:GetView()
        end)
    end
end

function OfflineManager:OnPause(customCall)
    local now = GameTimeManager:GetCurrentServerTime(true)
    self.offlineData.exitTime = now
    local customCallStr = customCall and "true" or "false"

    GameSDKs:TrackForeign("debugger", { system = "Offline", desc = "OnpauseTime", value = tostring(now) .. "   CustomCall:" .. customCallStr })
end

function OfflineManager:OnQuit()
    self:OnPause()
    GameSDKs:TrackForeign("debugger", { system = "Offline", desc = "ExitGame", value = tostring(self.offlineData.exitTime) } )
end

function OfflineManager:OnUpdate()
    if self.offlineData then
        UnityHelper.ShowOfflineInfo(self.offlineData.exitTime, self.offlineData.enterTime)
    end
end

--[[
    @desc: 获取最大离线时长, 最大离线时长 = 基础离线时长+ 商店购买扩展时长
    author:{author}
    time:2023-10-27 17:48:45
    --@countryId: 
    @return:
]]
function OfflineManager:GetOfflineMaxTime(countryId)
    local shopTime = ShopManager:GetOfflineAdd(nil, countryId) * 3600
    if not shopTime then
        --容错添加2024-9-13
        return ConfigMgr.config_global.offline_timelimit * 3600
    end
    return ConfigMgr.config_global.offline_timelimit * 3600 + shopTime
end


function OfflineManager:CleanOfflineData(countryID)
    if self.offlineData and self.offlineData.areaData then
        self.offlineData.areaData[countryID].offlineReward = 0
        self.offlineData.areaData[countryID].offlineTime = 0
        self.offlineData.areaData[countryID].offlineTimeSum = 0
        self.offlineData.areaData[countryID].reachMaximum = false
    end
end

return OfflineManager
