---@class CycleNightClubRankManager
local CycleNightClubRankManager = GameTableDefine.CycleNightClubRankManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local ReportRankTimerId
local IsInCycleInstanceUI
local IsInCycleInstanceMainUI
local IsInCycleInstanceRankUI

local LastRequestState = false

local autoRefreshRate = 30 -- 自动刷新频率/秒
local playerRefreshRate = 60 -- 玩家刷新间隔
local robot_name_set

function CycleNightClubRankManager:GMOpenRankSystem()
    self.enable = true
end

--[[
    @desc: 初始化问卷调查数据内容
    author:{author}
    time:2023-03-29 11:01:10
    @return:
]]
function CycleNightClubRankManager:Init(saveData)
    -- 禁用排行榜
    --if true then
    --    print("禁用排行榜")
    --    return
    --end

    self.enable = true
    if not saveData or next(saveData) == nil then
        print("Rank Log: 初始化了一个不存在的循环副本 存档")
        return
    end
    
    self.saveData = saveData
    self.instance_id = tonumber(saveData.m_Instance_id)
    self.instance_index = tonumber(saveData.m_InstanceID)

    self.player_id = GameSDKs:GetCurUserID()
    
    if not self.saveData.NightClubRankData then
        self.saveData.NightClubRankData = {}
    end

    -- 作弊标识
    if not self.saveData.NightClubRankData.cheat_tag then
        self.saveData.NightClubRankData.cheat_tag = false
    end

    -- 上次请求时间
    if not self.saveData.NightClubRankData.latest_request_time then
        self.saveData.NightClubRankData.latest_request_time = 0
    end

    -- 奖励领取时间
    if not self.saveData.NightClubRankData.claim_award_time then
        self.saveData.NightClubRankData.claim_award_time = 0
    end

    -- 机器人随机名字存档
    if not self.saveData.NightClubRankData.robot_names then
        self.saveData.NightClubRankData.robot_names = {}
    end

    -- 服务器积分存档
    if not self.saveData.NightClubRankData.latest_server_score then
        self.saveData.NightClubRankData.latest_server_score = 0
    end

    if self.saveData.NightClubRankData.cheat_tag and not self.saveData.NightClubRankData.server_cheat_tag then
        self:NoticeServerCheat()
    end

    self.isInit = true
    LocalDataManager:WriteToFile()
end

function CycleNightClubRankManager:IsInit()
    return self.isInit
end

function CycleNightClubRankManager:GetInstanceId()
    return self.instance_id
end

--- 进入排行榜界面
function CycleNightClubRankManager:EnterCycleNightClubInstanceRankUI()
    IsInCycleInstanceRankUI = true
    self:GetReportRank(2)
end

--- 退出排行榜界面
function CycleNightClubRankManager:ExistCycleNightClubInstanceRankUI()
    IsInCycleInstanceRankUI = false
end

--- 进入副本界面
function CycleNightClubRankManager:EnterCycleNightClubInstanceMainUI()
    IsInCycleInstanceMainUI = true
    -- 30秒更新上传玩家代币总和
    ReportRankTimerId = GameTimer:CreateNewTimer(autoRefreshRate, function()
        self:GetReportRank()
    end, true, true)
end

--- 退出副本界面
function CycleNightClubRankManager:ExistCycleNightClubInstanceMainUI()
    IsInCycleInstanceMainUI = false
    self:GetReportRank() -- 退出副本界面时，检查一下上报
    if ReportRankTimerId then
        GameTimer:StopTimer(ReportRankTimerId)
        ReportRankTimerId = nil
    end
end

--- 进入副本引导界面
function CycleNightClubRankManager:EnterCycleNightClubInstance()
    IsInCycleInstanceUI = true
    self:GetReportRank(1)
end

--- 退出副本引导界面
function CycleNightClubRankManager:ExistCycleNightClubInstance()
    IsInCycleInstanceUI = false
end

--- 代币发生改变时
function CycleNightClubRankManager:ChangeSlotCoin()
    self:GetReportRank()
end

--- 当前分组scene_id 100、200、300、400、500、600
function CycleNightClubRankManager:GetRankSceneId()
    local replace_str = "group_member_" .. self.instance_id .. "_" .. self.instance_index .. "_"
    local group_key_string = string.gsub(self.saveData.NightClubRankData.group_key, replace_str, "")
    local str = Tools:SplitString(group_key_string, "_")

    return str[2] or 0
end

--- 当前副本内分组
function CycleNightClubRankManager:GetRankGroupKey()
    if self.saveData and self.saveData.NightClubRankData and self.saveData.NightClubRankData.group_key and self:GetRemainTime() > 0 then
        --local replace_str = "group_member_" .. self.instance_id .. "_" .. self.instance_index .. "_"
        --local group_key_string = string.gsub(self.saveData.NightClubRankData.group_key, replace_str, "")
        --group_key_string = string.gsub(group_key_string, "00", "")

        local group_key_table = Tools:SplitString(self.saveData.NightClubRankData.group_key, "_")
        local group = group_key_table[1] or ""
        local member = group_key_table[2] or ""
        local instance_id = group_key_table[3] or ""
        local instance_index = group_key_table[4] or ""
        local language = group_key_table[5] or ""
        local scene_id = group_key_table[6] or ""
        local group_id = group_key_table[7] or ""
        if language ~= "" and scene_id ~= "" and group_id ~= "" then
            -- 只替换场景id中的00，不替换group_id
            return language .. "_" .. string.gsub(scene_id, "00", "") .. "_" .. group_id
        end
    end

    return ""
end

--- 当前副本内排名
function CycleNightClubRankManager:GetRankNum()
    if self.saveData and self.saveData.NightClubRankData and self.saveData.NightClubRankData.rank_num and self:GetRemainTime() > 0 then
        return self.saveData.NightClubRankData.rank_num
    end

    return 0
end

--- 返回拉霸机历史获得代币数量
function CycleNightClubRankManager:GetUserHistorySlotCoin()
    if self.saveData and self.saveData.NightClubRankData and GameTableDefine.CycleInstanceDataManager:GetCurrentModel().GetHistorySlotCoin and self:GetRemainTime() > 0 then
        return GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetHistorySlotCoin()
    end

    return 0
end

---获得当前里程碑
function CycleNightClubRankManager:GetCurInstanceKSLevel()
    return GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel()
end

---排行奖励内容
function CycleNightClubRankManager:GetRankReward(is_get_award)
    if true then -- 新的排行榜奖励配置，要用V2版本的逻辑；新的排行榜奖励配置，要用V2版本的逻辑；新的排行榜奖励配置，要用V2版本的逻辑
        return self:GetRankRewardV2(is_get_award)
    end
    
    local reward_list = {}
    if self:HadClaimAward() then
        return reward_list
    end
    
    local award_list = self:GetAwardList(self.saveData.NightClubRankData.rank_num)
    for i, v in pairs(award_list) do
        local award_conf = Tools:SplitString(v, ":", true)
        local shop_id = award_conf[1] or 0
        local award_num = award_conf[2] or 0
        local shop_conf = ConfigMgr.config_shop[shop_id]
        if shop_conf and shop_conf.type == 35 then
            reward_list[shop_conf.param3[1]] = award_num
        end
    end
    
    return reward_list
end

---排行奖励内容V2，带CEO奖励
function CycleNightClubRankManager:GetRankRewardV2(is_get_award)
    local reward_list = {}
    if self:HadClaimAward() then
        return reward_list
    end

    local award_list = self:GetAwardList(self.saveData.NightClubRankData.rank_num)
    for i, v in pairs(award_list) do
        local award_conf = Tools:SplitString(v, ":", true)
        local shop_id = award_conf[1] or 0
        local award_num = award_conf[2] or 0
        local shop_conf = ConfigMgr.config_shop[shop_id]
        if shop_conf then
            table.insert(reward_list, { shop_id = shop_id, count = award_num })
        end
    end

    if is_get_award then
        self.saveData.NightClubRankData.claim_award_time = os.time()
    end

    return reward_list
end

---排行奖励详细内容，老版领取方式，不带CEO奖励
function CycleNightClubRankManager:GetRankRewardDetail()
    local reward_list = {}
    if self:HadClaimAward() then
        return reward_list
    end

    local award_list = self:GetAwardList(self.saveData.NightClubRankData.rank_num)
    for _, v in pairs(award_list) do
        local award_conf = Tools:SplitString(v, ":", true)
        local shop_id = award_conf[1] or 0
        local award_num = award_conf[2] or 0
        local shop_conf = ConfigMgr.config_shop[shop_id]
        local rewards = {}
        local rank_set = {}
        local rank_ids = shop_conf.param
        local rank_weight = shop_conf.param2
        for i = 1, #rank_ids do
            local tmp_shop_id = rank_ids[i]
            local tmp_shop_weight = rank_weight[i] or 0
            for _ = 1, tmp_shop_weight do
                table.insert(rank_set, tmp_shop_id)
            end
        end

        rank_set = Tools:Shuffle(rank_set)
        for _ = 1, award_num do
            local shop_config_id = rank_set[math.random(#rank_set)]
            GameTableDefine.ShopManager:Buy(shop_config_id, false, nil, nil)

            local addDiamond = InstanceDataManager:GetSameShopItemConverToDiamond(shop_config_id)
            if addDiamond > 0 then
                GameTableDefine.ResourceManger:AddDiamond(addDiamond)
                InstanceDataManager:SetConvertDiamondIDs(shop_config_id)
            end

            table.insert(rewards, { shop_config_id })
        end

        reward_list[shop_conf.param3[1]] = {
            type = shop_conf.param3[1],
            count = #rewards,
            icon = "Icon_egg_"..shop_conf.param3[1],
            icon_broken = "Icon_egg_"..tostring(shop_conf.param3[1]).."_broken",
            name = "TXT_INSTANCE_EasterEgg_"..tostring(shop_conf.param3[1]),
            quality = "icon_egg_quality_"..tostring(shop_conf.param3[1]),
            rewardList = rewards,
            getRewardList = {},
            rewardIsGet = false
        }
    end

    self.saveData.NightClubRankData.claim_award_time = os.time()
    return reward_list
end

---获得奖励列表
function CycleNightClubRankManager:GetAwardList(rank_num)
    local award_list = {}
    if not rank_num or rank_num == 0 then
        return award_list
    end

    local rank_reward_conf = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_rank_reward
    local award_conf = rank_reward_conf and rank_reward_conf[self:GetRankSceneId()] or nil
    if not award_conf then
        return award_list
    end

    local default_award_list = {}
    for i, config in pairs(award_conf) do
        local min_rank_num = config.num[1] or 0
        local max_rank_num = config.num[2] or 0
        if min_rank_num == 0 then
            default_award_list = config.shop_id or {}
        end

        if min_rank_num == rank_num then
            award_list = config.shop_id or {}
            break
        end

        if max_rank_num and (min_rank_num < rank_num and max_rank_num >= rank_num) then
            award_list = config.shop_id or {}
            break
        end
    end

    if #award_list == 0 then
        award_list = default_award_list
    end

    return award_list
end

---获得活动状态，看是否有变化，是否需要再刷新一次数据
function CycleNightClubRankManager:GetInstanceState()
    local state
    if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
        state = InstanceDataManager:GetInstanceState()
    elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        state = CycleInstanceDataManager:GetInstanceState()
    end

    return state
end

---获得活动剩余时间 or 奖励领取剩余时间
function CycleNightClubRankManager:GetRemainTime(only_active)
    local remain_time_sec = 0
    if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
        local state = InstanceDataManager:GetInstanceState()
        if state == InstanceDataManager.instanceState.isActive then
            remain_time_sec = InstanceDataManager:GetLeftInstanceTime()
        else
            if not only_active then
                remain_time_sec = InstanceDataManager:GetInstanceRewardTime()
            end
        end
    elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        local state = CycleInstanceDataManager:GetInstanceState()
        if state == CycleInstanceDataManager.instanceState.isActive then
            remain_time_sec = CycleInstanceDataManager:GetLeftInstanceTime()
        else
            if not only_active then
                remain_time_sec = CycleInstanceDataManager:GetInstanceRewardTime()
            end
        end
    end

    return remain_time_sec
end

---获得活动结束时间
function CycleNightClubRankManager:GetInstanceEndTime()
    local remain_time_sec = 0
    if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
        remain_time_sec = InstanceDataManager:GetInstanceEndTime()
    elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        remain_time_sec = CycleInstanceDataManager:GetInstanceEndTime()
    end

    return remain_time_sec
end

---排行奖励是否可领
function CycleNightClubRankManager:ClaimEnable()
    return self.isInit and #self:GetRankReward() > 0
end

---排行奖励是否领取
function CycleNightClubRankManager:HadClaimAward()
    return self.saveData.NightClubRankData.claim_award_time > 0
end

-- 处理一下机器人的分数，5的倍数
function CycleNightClubRankManager:FormatRobotSocre(score)
    local a = math.floor(score / 5)
    local b = score % 5
    local c = math.floor(b / 3)
    return 5 * (a + c)
end

-- 名字合集
function CycleNightClubRankManager:RobotNameConf()
    local name_conf = {}
    for instance_id, instance_conf in pairs(ConfigMgr.config_cy_instance_rank) do
        for scene_id, scene_conf in pairs(instance_conf) do
            for robot_id, robot_conf in pairs(scene_conf) do
                table.insert(name_conf, robot_conf.name)
            end
        end
    end

    return Tools:Shuffle(name_conf)
end

-- 获取机器人名字
function CycleNightClubRankManager:GetRobotName(robot_id)
    if self.saveData.NightClubRankData.robot_names and self.saveData.NightClubRankData.robot_names[tostring(robot_id)] then
        return self.saveData.NightClubRankData.robot_names[tostring(robot_id)]
    end

    if not robot_name_set then
        robot_name_set = self:RobotNameConf()
    end

    local new_name = robot_name_set[math.floor(robot_id)]
    self.saveData.NightClubRankData.robot_names[tostring(robot_id)] = new_name
    return new_name
end

---合并本地机器人数据
function CycleNightClubRankManager:MergeRobot(group_key, rank_data, group_created_at)
    local player_datas = {}
    local score = self:GetUserHistorySlotCoin()
    for i, user_data in pairs(rank_data) do
        table.insert(player_datas, user_data) -- 加入玩家数据
        if user_data.user_id == self.player_id then
            rank_data[i].score = score
            break -- 更新一下玩家积分，保持最新的积分排名
        end
    end

    local group_data = Tools:SplitString(tostring(group_key), '_')
    local scene_id = math.floor(group_data and group_data[#group_data - 1] or 0)
    local robotConfig
    if ConfigMgr.config_cy_instance_rank[self.instance_id] and scene_id > 0 then
        robotConfig = ConfigMgr.config_cy_instance_rank[self.instance_id][tostring(scene_id)]
    end

    if robotConfig then
        for robot_id, robot_conf in pairs(robotConfig) do
            local robot_time = math.min(self:GetInstanceEndTime(), os.time()) - group_created_at
            local robot_score = Tools:Calc(robot_conf.formula, { T = math.max(0, robot_time), A = robot_conf.A, B = robot_conf.B, C = robot_conf.C })

            local skin_id
            local hat_id
            local bag_id
            local configEquip = ConfigMgr.config_equipment
            if robot_conf.equipment then
                for i, equip_id in pairs(robot_conf.equipment) do
                    local equip_part = configEquip[equip_id] and configEquip[equip_id].part
                    if equip_part == 0 then
                        skin_id = equip_id
                    end

                    if equip_part == 1 then
                        hat_id = equip_id
                    end

                    if equip_part == 2 then
                        bag_id = equip_id
                    end
                end
            end

            local robot_data = { user_id = robot_id, username = self:GetRobotName(robot_id), score = robot_score, gender = robot_conf.boss, skin = skin_id, hat = hat_id, bag = bag_id, is_robot = true }
            table.insert(player_datas, robot_data) -- 加入机器人数据
        end
    end
    
    table.sort(player_datas, function(a, b) 
        return tonumber(a.score) > tonumber(b.score)
    end)

    local rank_num = 1
    self.saveData.NightClubRankData.rank_data = {}
    for i, user_data in pairs(player_datas) do
        user_data.score = math.floor(self:FormatRobotSocre(user_data.score))
        user_data.rank = rank_num
        self.saveData.NightClubRankData.rank_data[rank_num] = user_data
        if user_data.user_id == self.player_id then
            self.saveData.NightClubRankData.rank_num = rank_num
            self.saveData.NightClubRankData.user_rank_data = user_data
        end

        rank_num = rank_num + 1
    end
end

--- 刷新 排行榜数据
function CycleNightClubRankManager:DealRankData(data)
    --if not self.saveData.NightClubRankData.group_key and data.group_key then
    if data.group_key then -- 分组标识，覆盖 以服务器为准，不然排行会跟服务器不一致
        self.saveData.NightClubRankData.group_key = data.group_key
    end

    if data.group_created_at then -- 分组创建时间，覆盖 以服务器为准，不然排行会跟服务器不一致
        self.saveData.NightClubRankData.group_created_at = data.group_created_at
    end

    if data.rank_data then -- 服务器返回数据
        self.saveData.NightClubRankData.server_rank_data = data.rank_data
        -- 合并本地机器人数据
        self:MergeRobot(data.group_key, data.rank_data, data.group_created_at)
    end

    self:RefreshRankNum() -- 刷新玩家排名
    if IsInCycleInstanceRankUI then -- 在排行榜界面，刷新排行榜
        self:RefreshRankData()
    end
end

-- 使用存档数据进行界面数据的更新
function CycleNightClubRankManager:UseOldData()
    local old_group_key = self.saveData.NightClubRankData.group_key
    local old_rank_data = self.saveData.NightClubRankData.server_rank_data
    local old_group_created_at = self.saveData.NightClubRankData.group_created_at
    if old_rank_data and old_group_key and old_group_created_at then
        -- 合并本地机器人数据
        self:MergeRobot(old_group_key, old_rank_data, old_group_created_at)
    end

    self:RefreshRankNum() -- 刷新玩家排名
    if IsInCycleInstanceRankUI then -- 在排行榜界面，刷新排行榜
        self:RefreshRankData()
    end
end

--- 刷新排行榜排名
function CycleNightClubRankManager:RefreshRankNum()
    if not self.enable then
        return
    end
    
    --print("Rank Log: 刷新排行榜排名...")
    if self.saveData.NightClubRankData.rank_num then
        EventManager:DispatchEvent(GameEventDefine.RefreshNightClubRankNum)
    end
end

--- 刷新排行榜数据
function CycleNightClubRankManager:RefreshRankData()
    if not self.enable then
        return
    end
    
    --print("Rank Log: 刷新排行榜数据...")
    --IsInCycleInstanceRankUI = false -- 处于排行榜界面时，是否需要一直刷新
    if self.saveData.NightClubRankData.rank_data then
        EventManager:DispatchEvent(GameEventDefine.RefreshNightClubRankData)
    end
end

--- 玩家排名
function CycleNightClubRankManager:GetUserRankNum()
    return self.saveData.NightClubRankData.rank_num
end

--- 所有玩家排行信息
function CycleNightClubRankManager:GetRankData()
    return self.saveData.NightClubRankData.rank_data
end

--- 玩家排名信息
function CycleNightClubRankManager:GetUserRankInfo()
    return self.saveData.NightClubRankData.user_rank_data
end

--- 上报检查
function CycleNightClubRankManager:ReportCheck()
    if not self.isInit then
        return false
    end
    
    if self.saveData.NightClubRankData.cheat_tag then
        print("Rank Log: 上报检查, 作弊玩家...")
        return false
    end

    local curSkLv = self:GetCurInstanceKSLevel()
    if not curSkLv or curSkLv < 1 then
        print("Rank Log: 上报检查, 里程碑未达到1级...")
        return false
    end

    if not self.saveData.NightClubRankData.first_slot_time then
        print("Rank Log: 上报检查, 还没使用过拉霸机...")
        return false
    end

    local score = self:GetUserHistorySlotCoin()
    if score > self.saveData.NightClubRankData.latest_server_score then
        print("Rank Log: 上报检查, 积分有变化, 可上报: ", score, self.saveData.NightClubRankData.latest_server_score)
        return true
    end

    -- 活动时间检查
    local remain_time_sec = self:GetRemainTime()
    if remain_time_sec <= 0 then
        self:UseOldData() -- 使用存档数据进行界面数据的更新
        print("Rank Log: 上报检查, 活动已结束, 不用上传积分...")
        return false
    end

    return true
end

---上报排行榜 1为里程碑界面, 2为排行榜界面需要弹服务器错误提示
---@param trigger_type number
function CycleNightClubRankManager:ReportRank(trigger_type)
    local score = self:GetUserHistorySlotCoin()
    print("Rank Log: 上报排行榜: ", score)
    -- 处于副本内时，刷新 排名 todo 是不是进入副本就会一直上报、更新了？
    GameServerHttpClient:ReportRank(self.instance_id, self.instance_index, score, function(ret)
        LastRequestState = ret and ret.errno == 0
        GameSDKs:TrackForeign("rank_data", { type = 1, result = LastRequestState and 1 or 2 })
        if ret.errno == 0 then
            self.saveData.NightClubRankData.latest_request_time = os.time()
            self.saveData.NightClubRankData.latest_server_score = score -- 更新最近上报分数，分组信息存储
            local skinId, hatId, bagId = GameServerHttpClient:GetUserDressUp()
            self.saveData.NightClubRankData.latest_server_skin_id = skinId
            self.saveData.NightClubRankData.latest_server_hat_id = hatId
            self.saveData.NightClubRankData.latest_server_bag_id = bagId
            self.saveData.NightClubRankData.latest_server_instance_state = self:GetInstanceState()
            
            self:DealRankData(ret)
        end

        if trigger_type == 2 and not LastRequestState then
            EventManager:DispatchEvent(GameEventDefine.ServerError)
        end
    end)
end

-- 请求服务器排行榜数据
function CycleNightClubRankManager:GetServerReportRank(trigger_type)
    GameServerHttpClient:GetReportRank(self.instance_id, self.instance_index, function(ret)
        LastRequestState = ret and ret.errno == 0
        GameSDKs:TrackForeign("rank_data", { type = 2, result = LastRequestState and 1 or 2 })
        if LastRequestState then
            self.saveData.NightClubRankData.latest_request_time = os.time()
            self.saveData.NightClubRankData.latest_server_instance_state = self:GetInstanceState()
            self:DealRankData(ret)
        end

        -- 排行榜界面，重试界面提示
        if trigger_type == 2 and not LastRequestState then
            EventManager:DispatchEvent(GameEventDefine.ServerError)
        end
    end)
end

---获取排行榜
---@return table
function CycleNightClubRankManager:GetReportRank(trigger_type)
    if not self:ReportCheck() then
        return
    end

    local score = self:GetUserHistorySlotCoin()
    if score > self.saveData.NightClubRankData.latest_server_score then -- 积分增加了，上报，拉取最新数据
        print("Rank Log: 积分增加了，上报玩家数据，拉取最新数据...")
        self:ReportRank(trigger_type)
    else
        -- 上次请求失败，直接拉取最新数据
        if not LastRequestState or self.saveData.NightClubRankData.latest_server_instance_state ~= self:GetInstanceState() then
            print("Rank Log: 上次请求失败 或 副本状态改变，直接拉取最新数据...")
            self:GetServerReportRank(trigger_type)
            return
        end

        if trigger_type and os.time() - self.saveData.NightClubRankData.latest_request_time <= playerRefreshRate then
            print("Rank Log: 频繁摘取数据, 使用存档数据...")
            self:UseOldData()
        else
            local skinId, hatId, bagId = GameServerHttpClient:GetUserDressUp()
            if skinId ~= self.saveData.NightClubRankData.latest_server_skin_id or hatId ~= self.saveData.NightClubRankData.latest_server_hat_id or bagId ~= self.saveData.NightClubRankData.latest_server_bag_id then
                print("Rank Log: 间隔时间内，玩家装扮变了，上报玩家数据，拉取最新数据...")
                self:ReportRank(trigger_type)
            else
                print("Rank Log: 无需上报，直接拉取最新数据...")
                self:GetServerReportRank(trigger_type)
            end
        end
    end
end

---排行榜作弊检查
--  1. 当前持有总钻石量>50万，视为作弊用户
--  2. 单次钻石变化量>6万，视为作弊用户
function CycleNightClubRankManager:CheatCheck(old_diamond, change_value)
    local cheat_tag = false
    if math.abs(change_value) > 60000 or old_diamond + change_value > 500000 then
        cheat_tag = true
    end

    print("Rank Log: 作弊 old_diamond, change_value: ", old_diamond, change_value)
    if not cheat_tag then
        return
    end

    if self.isInit and not self.saveData.NightClubRankData.server_cheat_tag then
        self.saveData.NightClubRankData.cheat_tag = true
        self:NoticeServerCheat()
    end
end

function CycleNightClubRankManager:NoticeServerCheat()
    GameServerHttpClient:CheatTag(self.instance_id, self.instance_index, function(ret)
        if ret and ret.errno == 0 then
            self.saveData.NightClubRankData.server_cheat_tag = true
        end
    end)
end

---获取玩家是否为作弊玩家
---@return boolean
function CycleNightClubRankManager:CheatTag()
    return self.saveData.NightClubRankData.cheat_tag
end

--- 第一次拉霸机后，解锁排行榜
function CycleNightClubRankManager:unlockRankBoard()
    if not self.saveData.NightClubRankData.first_slot_time then
        self.saveData.NightClubRankData.first_slot_time = os.time()
        
        -- 解锁后，获取数据，显示排行榜按钮
        self:GetReportRank()
    end
end

