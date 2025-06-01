---@class ConfigMgr
---@field config_global
---@field config_ceo_furniture_level CEOFurnitureConfig[]
---@field config_ceo CEOConfig[]
---@field config_ceo_level CEOLevelConfig[]
local ConfigMgr = GameTableDefine.ConfigMgr
local UnityHelper = CS.Common.Utils.UnityHelper
local CONFIG_PATH = nil
local CONFIG_PATH1 = "ConfigData/"
local CONFIG_PATH2 = "ConfigData2/"
local CONFIG_PATH3 = "ConfigData3/"
local CONFIG_PATH4 = "ConfigData4/"
local CONFIG_PATH5 = "ConfigData5/"
local GameLauncher = CS.Game.GameLauncher.Instance
local DeviceUtil = CS.Game.Plat.DeviceUtil

local CONFIG_TAG = 0
local NEED_RELOAD_CONFIG_SET = {}

local m_correctlyGrouped = false 

local remoteConfigTable = {
    ["test1"] = 1,
    ["test2"] = 2,
    ["test3"] = 3,
    ["test4"] = 4,
    ["test5"] = 5,
}

local userTypeToGroup = {
    [1] = "test1",
    [2] = "test2",
    [3] = "test3",
    [4] = "test4",
    [5] = "test5",
}

local configs = {

    "config_buildings",
    "config_district",
    "config_floors",
    "config_rooms",
    "config_furnitures",
    "config_furnitures_levels",
    "config_global",
    "config_company",
    "config_event",
    "config_task",
    --"config_star",
    --"config_character",
    "config_guide",
    --"config_gift",
    "config_character_name",
    "config_emergency",
    "config_dialog",
    --"config_total_ad_reward",
    "config_chat",
    "config_chat_condition",
    "config_car",
    --"config_house",
    --"config_carshop",
    "config_bank",
    "config_wealthrank",
    "config_shop",
    --"config_shop_frame",
    "config_pets",
    "config_employees",
    --
    "config_iap",
    --"config_wheel",
    "config_popup",
    "config_workshop",
    "config_products",
    --"config_order",
    "config_piggybank",
    "config_snack",
    "config_language",
    "config_activity_reward",
    "config_activity",
    "config_boost",
    --"config_activityrank",
    --"config_playername",
    --"config_token",
    --
    "config_country",
    "config_money",
    --"config_fragment_reward",
    "config_equipment",
    --"config_limitpack",
    --"config_payment",
    --"config_survey",
    "config_survey_new",
    --"config_rooms_instance",
    --"config_furniture_instance",
    --"config_furniture_level_instance",
    --"config_furniture_level_furID_instance",
    --"config_shop_frame_instance",
    --"config_achievement_instance",
    --"config_reward_instance",
    --"config_rewardID_instance",
    --"config_rewardType_instance",
    --"config_resource_instance",
    --"config_faq",
    --
    "config_league",
    "config_team_pool",
    "config_football_club",
    --"config_club_data",
    "config_stadium",
    --"config_training_ground",
    --"config_tactical_center",
    "config_health_center",
    --"config_develop",
    --"config_affair",
    --"config_stage",
    --"config_campaign",
    --"config_opponent",
    --"config_ui_redirect",
    "config_instance_bind",
    "config_iap_country",
    --"config_account",
    --"config_task_instance",
    --"config_mainline_pass",
    "config_mainline_stage",
    --"config_slot_machines",
    "config_cy_instance_skill",
    --"config_cy_instance_hero",
    --"config_cy_instance_task",
    "config_cy_instance_rooms",
    --"config_cy_instance_fur",
    --"config_cy_instance_furlevel",
    --"config_cy_instance_furlevel_byID",
    --"config_cy_instance_reward",
    --"config_cy_instance_res",
    --"config_cy_instance_shop",
    --"config_cy_instance_gifts",
    --"config_cy_instance_gifts_byShopID",
    "config_cycle_instance_global",
    --"config_cy_instance_roomsLevel",
    --"config_slot_machines_rewards"
}

---不需要一开始加载，需要时再加载
local NotEssentialConfigs = {
    --"config_buildings",
    --"config_district",
    --"config_floors",
    --"config_rooms",
    --"config_furnitures",
    --"config_furnitures_levels",
    --"config_global",
    --"config_company",
    --"config_event",
    --"config_task",
    "config_star",
    "config_character",
    --"config_guide",
    "config_gift",
    --"config_character_name",
    --"config_emergency",
    --"config_dialog",
    "config_total_ad_reward",
    --"config_chat",
    --"config_chat_condition",
    --"config_car",
    "config_house",
    "config_carshop",
    --"config_bank",
    --"config_wealthrank",
    --"config_shop",
    "config_shop_frame",
    --"config_pets",
    --"config_employees",
    --"config_iap",
    "config_wheel",
    --"config_popup",
    --"config_workshop",
    --"config_products",
    "config_order",
    --"config_piggybank",
    --"config_snack",
    --"config_language",
    --"config_activity_reward",
    --"config_activity",
    --"config_boost",
    "config_activityrank",
    "config_playername",
    "config_token",

    --"config_country",
    "config_money",
    "config_fragment_reward",
    --"config_equipment",
    "config_limitpack",
    "config_payment",
    "config_survey",
    --"config_survey_new",
    --"config_rooms_instance",
    --"config_furniture_instance",
    --"config_furniture_level_instance",
    "config_furniture_level_furID_instance",
    --"config_shop_frame_instance",
    --"config_achievement_instance",
    --"config_reward_instance",
    --"config_rewardID_instance",
    --"config_rewardType_instance",
    --"config_resource_instance",
    "config_faq",

    --"config_league",
    --"config_team_pool",
    --"config_football_club",
    "config_club_data",
    --"config_stadium",
    "config_training_ground",
    "config_tactical_center",
    --"config_health_center",
    "config_develop",
    "config_affair",
    "config_stage",
    "config_campaign",
    "config_opponent",
    --"config_ui_redirect",
    --"config_instance_bind",
    --"config_iap_country",
    "config_account",
    --"config_task_instance",
    "config_mainline_pass",
    --"config_mainline_stage",
    "config_slot_machines",
    --"config_cy_instance_skill",
    "config_cy_instance_hero",
    "config_cy_instance_task",
    --"config_cy_instance_rooms",
    "config_cy_instance_fur",
    --"config_cy_instance_furlevel",
    "config_cy_instance_furlevel_4",
    "config_cy_instance_furlevel_5",
    "config_cy_instance_furlevel_6",
    "config_cy_instance_furlevel_7",
    "config_cy_instance_reward",
    "config_cy_instance_res",
    "config_cy_instance_shop",
    "config_cy_instance_gifts_4",
    "config_cy_instance_gifts_5",
    "config_cy_instance_gifts_6",
    "config_cy_instance_gifts_7",
    --"config_cycle_instance_global",
    "config_cy_instance_roomsLevel",
    "config_slot_machines_rewards",
    "config_cy_instance_blueprint",
    "config_cy_blueprint_res",
    "config_cy_instance_rank",
    "config_cy_instance_rank_reward",
    "config_cy_instance_piggypack",
    "config_pass_task",
    "config_pass_rewards",
    "config_pass_game_tuibiji",
    "config_pass_game_tuibiji_byID",
    "config_pass_rewards",
    "config_pass_point_reward",
    --CEO模块相关内容
    "config_ceo_card",
    "config_ceo_chest",
    "config_ceo_key",
    "config_ceo_level",
    "config_ceo",
    "config_ceo_furniture_level",
    "config_ceo_keybundle",
}

local configsIAP = {
    "config_fund",
}
--function ConfigMgr:LoadConfig()
--    local GameTools = GameTools
--    GameTools:AddTimePoint("ConfigMgr:LoadConfig()")
--    self:CheckABTestConfig()
--    CONFIG_PATH = "ConfigData/"
--    if not UnityHelper.IsRuassionVersion() then
--        if self.userType and self.userType == "2" then
--            CONFIG_PATH = "ConfigData2/"
--        end
--    end
--    for k,v in pairs(configs) do
--        local realPath = CONFIG_PATH.. v
--        --GameTools:AddTimePoint(realPath)
--        self[v] = require(realPath)
--        --GameTools:CalcTimePointCost(realPath)
--    end
--
--    if ConfigMgr.config_global.enable_iap == 1 then
--        for k,v in pairs(configsIAP) do
--            self[v] = require(CONFIG_PATH..v)
--        end
--    end
--    GameTools:CalcTimePointCost("ConfigMgr:LoadConfig()")
--end

local function OnLoadConfigOver()
    if ConfigMgr.config_global.enable_iap == 1 then
        for k,v in pairs(configsIAP) do
            ConfigMgr[v] = require(CONFIG_PATH..v)
        end
    end
end

function ConfigMgr:DynamicLoadConfig(onEndCallback)
    local GameTools = GameTools
    GameTools:AddTimePoint("ConfigMgr:LoadConfig()")
    
    local pathIndex = 1
    local pathLength = #configs
    local loadingTimer
    local lastUpdateTime = os.time()
    local LoadingScreen = GameTableDefine.LoadingScreen
    loadingTimer = GameTimer:CreateNewMilliSecTimer(1,function()
        if pathIndex>pathLength then
            GameTimer:StopTimer(loadingTimer)
            OnLoadConfigOver()
            GameTools:CalcTimePointCost("ConfigMgr:LoadConfig()")
            if onEndCallback then
                onEndCallback()
            end
        else
            for i = pathIndex,pathLength do
                local filePath = configs[i]
                local realPath = CONFIG_PATH .. filePath
                -- 记录已加载的配置文件
                if CONFIG_TAG == 0 then
                    table.insert(NEED_RELOAD_CONFIG_SET, filePath)
                end

                ---- 同步加载另外一份配置文件
                --local tmpConf
                --if CONFIG_PATH == CONFIG_PATH1 then
                --    tmpConf = require(CONFIG_PATH2 .. filePath)
                --else
                --    tmpConf = require(CONFIG_PATH1 .. filePath)
                --end
                --GameTools:AddTimePoint(realPath)
                ConfigMgr[filePath] = require(realPath)
                local now = os.time()
                --超过0.3s 暂停加载一帧
                if now - lastUpdateTime > 0.3 or pathIndex == pathLength then
                    pathIndex = i + 1
                    break
                end
                --GameTools:CalcTimePointCost(realPath)
            end
            GameLauncher.updater:SetProgress(30+30 * (pathIndex-1)/pathLength)
        end
    end,true,true)
end

---检查分组是否合法, 如果不合法则使用默认分组
function ConfigMgr:CheckABTestConfig(group)
    if GameTableDefine.CurABTest_Key and GameTableDefine.CurABTest_Key ~= "" then        
        local remoteConfigData = LocalDataManager:GetRemoteConfigData()
        self.userType = remoteConfigTable[group] or remoteConfigTable[remoteConfigData.group] or nil
        
        -- 检查组名是否合法
        if self.userType then
            if self.userType == 1 then
                CONFIG_PATH = CONFIG_PATH1
            elseif self.userType == 2 then
                CONFIG_PATH = CONFIG_PATH2
            elseif self.userType == 3 then
                CONFIG_PATH = CONFIG_PATH3
            elseif self.userType == 4 then
                CONFIG_PATH = CONFIG_PATH4
            elseif self.userType == 5 then
                CONFIG_PATH = CONFIG_PATH5
            end
        end
        if not CONFIG_PATH then
            self:UseDefaultGroup()
        end
        
        -- 检查是否能找到对应的资源
        local testPath = configs[1]  --默认是config_buildings
        testPath = CONFIG_PATH .. testPath
        local hasAssert = UnityHelper.HasScriptAsset(testPath)
        if not hasAssert then
            self:UseDefaultGroup()
        end

        --上报用户属性数据
        GameSDKs:SetUserAttrToWarrior({ AB_test_inner = GameTableDefine.CurABTest_Key .. "_" .. tostring(self.userType) })
    end
end 

function ConfigMgr:UseDefaultGroup()
    self.userType = 1
    CONFIG_PATH = CONFIG_PATH1
end

--- 收到服务器分组结果，重新分组，并刷新配置
function ConfigMgr:ReloadConfig(tag)
    if GameTableDefine.CurABTest_Key and GameTableDefine.CurABTest_Key ~= "" then
        local group = 0
        if tag == "group_a" or tag == 1 then
            group = 1
        elseif tag == "group_b" or tag == 2 then
            group = 2
        else
            print("不支持其它分组, " .. group .. ", " .. tag)
            GameSDKs:TrackForeign("debugger", { system = "ABTest", desc = "错误的分组配置", value = "groupName = " .. tag })
            return
        end

        if self.userType and self.userType == tostring(group) then
            print("跟之前分组相同, 直接返回, " .. group)
            GameSDKs:TrackForeign("debugger", { system = "ABTest", desc = "跟之前分组相同", value = "groupName = " .. tag })
            return
        end

        self.userType = tostring(group)
        CS.UnityEngine.PlayerPrefs.SetString(GameTableDefine.CurABTest_Key, self.userType)
        CS.UnityEngine.PlayerPrefs.Save()

        if group == 1 then
            CONFIG_PATH = CONFIG_PATH1
        elseif group == 2 then
            CONFIG_PATH = CONFIG_PATH2
        end

        -- 跟之前分组不同，重新赋值
        print("切换分组: " .. group)
        for _, filePath in ipairs(NEED_RELOAD_CONFIG_SET) do
            ConfigMgr[filePath] = require(CONFIG_PATH .. filePath)
        end
        OnLoadConfigOver()
        -- 改变分组后还需要上报事件，上报用户属性数据
        GameSDKs:TrackForeign("debugger", { system = "ABTest", desc = "从服务器切换分组成功", value = "groupName = " .. tag })
        GameSDKs:SetUserAttrToWarrior({AB_test_inner = GameTableDefine.CurABTest_Key.."_"..tostring(self.userType)})
    end
end

--[[
    @desc: 提供给GM制定AB分组修改的指令
    author:{author} 
    time:2023-12-05 16:27:29
    --@group: 
    @return:
]]
function ConfigMgr:GMDefineABTestGroup(group)
    if GameTableDefine.CurABTest_Key and GameTableDefine.CurABTest_Key ~= "" then
        self.userType = tostring(group)
        CS.UnityEngine.PlayerPrefs.SetString(GameTableDefine.CurABTest_Key, self.userType)
        CS.UnityEngine.PlayerPrefs.Save()
    end
end

--[[
    @desc: 获取当前的地区码，用于PayerMax支付SDK
    author:{author}
    time:2023-12-25 11:29:33
    @return:
]]
function ConfigMgr:GetCurrentIAPCountryCfg(countryCode)
    --TODO:获取当前的地区码，用于PayerMax支付SDK
    -- local curCountryCode = "DE"
    if not countryCode or not self["config_iap_country"][countryCode] then
        return self["config_iap_country"].US
    end
    return self["config_iap_country"][countryCode]
end

function ConfigMgr:RequireConfigGroup()
    local remoteConfigData = LocalDataManager:GetRemoteConfigData()
    --是否有配置存档记录?
    if not remoteConfigData.group then
        self.userType = CS.UnityEngine.PlayerPrefs.GetString(GameTableDefine.OldABTest_Key, "0") or "0"
        if self.userType == "0" then
            DeviceUtil.InvokeNativeMethod("getRemoteConfig")
            GameSDKs:TrackForeign("remote_config", { state = 1 })
            return
        else
            remoteConfigData.group = "test" .. self.userType
            remoteConfigData.endTime = 1743955200 --2025.4.7 00:00:00
        end
    end
    
    if remoteConfigData.group then
        local now = GameTimeManager:GetCurLocalTime(true)
        if remoteConfigData.endTime and now <= remoteConfigData.endTime then --有结束时间且在期限内
            --根据group找到对应表
            self:CheckABTestConfig()
            --根据group找到对应表
            self:LoadConfigByGroup()
            ConfigMgr:SetCorrectlyGroupedMark(true)
            
        else    --没有结束时间或超出期限
            --清除配置存档数据时间数据
            remoteConfigData.endTime = nil
            DeviceUtil.InvokeNativeMethod("getRemoteConfig")
            GameSDKs:TrackForeign("remote_config", { state = 1 })
        end
    end

end

function ConfigMgr:LoadConfigByGroup()
    GameTableDefine.ConfigMgr:DynamicLoadConfig(function()
        CS.Common.Utils.XLuaManager.Instance:UnloadUnUseLuaFiles()
        ConfigLoadOver = true
        GameSDKs:TrackForeign("init", {init_id = 5, init_desc = "脚本初始化"})
        GameTableDefine.LoadingScreen:SetLoadingMsg("脚本初始化")
        GameLauncher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_1"))
        GameStateManager:AfterConfigLoaded()
    end)
    
    -- 根据实际使用的表保存组名
    local group = userTypeToGroup[self.userType]
    local remoteConfigData = LocalDataManager:GetRemoteConfigData()
    remoteConfigData.group = group

end

function ConfigMgr:SetCorrectlyGroupedMark(value)
    m_correctlyGrouped = value
end

function ConfigMgr:HasCorrectlyGrouped()
    return m_correctlyGrouped
end


local function Contains(list, str)
    for _, value in ipairs(list) do
        if value == str then
            return true
        end
    end
    return false
end

setmetatable(ConfigMgr,{
    __index = function(configManager,key)
        if Contains(NotEssentialConfigs,key) then
            if CONFIG_TAG == 0 then
                table.insert(NEED_RELOAD_CONFIG_SET, key)
            end

            GameTools:AddTimePoint(key)
            local tableValue = require(CONFIG_PATH..key)
            configManager[key] = tableValue
            GameTools:CalcTimePointCost(key)
            return tableValue
        else
            return nil
        end
    end
})