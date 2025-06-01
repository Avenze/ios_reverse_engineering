local DataManager = GameTableDefine.FootballClubLeagueRankDataManager
local configManager = GameTableDefine.ConfigMgr
local FCStadiumUI = GameTableDefine.FCStadiumUI
local FootballClubModel = GameTableDefine.FootballClubModel

local isInited = false --是否已初始化

--联赛列表数据
DataManager.leagueListCfg = {} --记录排序后的结果,防止修改config元数据
--联赛状态枚举
DataManager.ELeagueState = {
    locked = 1, --未解锁
    unlockable = 2, --可解锁
    currentLeague = 3, --当前联赛
    accessible = 4 --可前往
}

--联赛排位数据
DataManager.leagueRankSorted = {}
--晋级名次
DataManager.riseRanking = 2

--初始化联赛列表数据
function DataManager:InitFootballClubLeagueData()
    if not isInited then
        --联赛列表数据
        for k, v in pairs(configManager.config_league[FootballClubModel.m_cfg.id]) do
            table.insert(DataManager.leagueListCfg, v)
        end
        table.sort(DataManager.leagueListCfg,function(a, b) --联赛等级从低到高排序
                return a.level > b.level    
            end)

        --联赛排位数据
        local currentLeagueRankList = self:RefreshCurrentLeagueRankConfig()

        isInited = true
    end
end

--更新联赛队伍config信息
function DataManager:RefreshCurrentLeagueRankConfig()
    DataManager.leagueRankSorted = {}
    local currentLeagueRankList = FootballClubModel:GetLeagueData()
    currentLeagueRankList = currentLeagueRankList.rankingList
    local teamCfg = configManager.config_team_pool[FootballClubModel.m_cfg.id]
    for i, m in pairs(currentLeagueRankList) do
        table.insert(DataManager.leagueRankSorted, {id = tonumber(i),point = m, cfg = teamCfg[tonumber(i)]})
    end

    --根据联赛积分排序
    table.sort(DataManager.leagueRankSorted, function(a, b)
        if a.point == b.point then
            return a.id < b.id
        end
        return a.point > b.point
    end)
end

--通过ID获取联赛信息
function DataManager:GetFootballLeagueCfgByID(id)
    if not DataManager.leagueListCfg then
        print("获取配置 [config_league] 失败")
    end

    for k, v in pairs(DataManager.leagueListCfg) do
        if v.id == id then
            return v
        end
    end
    return nil
end

--通过联赛等级获取联赛信息
function DataManager:GetFootballLeagueDataByLevel(LeagueLevel)
    if not DataManager.leagueListCfg then
        print("获取配置 [config_league] 失败")
    end
    return DataManager.leagueListCfg[#DataManager.leagueListCfg - LeagueLevel + 1]

end

--获取目标联赛状态
function DataManager:GetLeagueState(leagueID)
    local leagueCfg = self:GetFootballLeagueCfgByID(leagueID)
    local leagueData = FootballClubModel:GetLeagueData()
    local currentLeagueState = nil    
    if leagueData.currLeagueLV == leagueCfg.level then --当前的等级
        currentLeagueState = self.ELeagueState.currentLeague   
    elseif leagueData.leagueLV < leagueCfg.level then
        if leagueData.unlockable == leagueCfg.level  then  --可解锁的
            currentLeagueState = self.ELeagueState.unlockable
        else -- 锁着的
            currentLeagueState = self.ELeagueState.locked
        end
    else --可以选的
        currentLeagueState = self.ELeagueState.accessible 
    end
    return currentLeagueState
end

--获取玩家联赛config数据
function DataManager:GetPlayerLeagueCfg()
    local playerLeagueLevel = FootballClubModel:GetLeagueData().currLeagueLV
    return self:GetFootballLeagueDataByLevel(playerLeagueLevel)
end

--是否可切换到目标联赛
function DataManager:CanSwitchingLeague(leagueID)
    local state = self:GetLeagueState(leagueID)
    if state == self.EleagueState.accessible or state == self.EleagueState.locked then
        return true
    end
    return false
end

--根据队伍id获取当前联赛队伍信息
function DataManager:GetLeagueTeamDataByID(itemId)
    for k, v in pairs(DataManager.leagueRankSorted) do
        if v.id == itemId then
            return v
        end
    end
end

--根据队伍排名获取当前联赛队伍信息
function DataManager:GetCurrnetLeagueTeamArchivedDataByRanking(Ranking)
    return DataManager.leagueRankSorted[Ranking]
end

--获取联赛奖金
function DataManager:GetCurrentLeaguePrize()
    --排名收入计算公式=(球队总数-排名+1)/(球队总数)/(球队总数+1)*2*奖金池总数
    local teamCount = #DataManager.leagueRankSorted
    local playerLeagueRanking = self:GetLeagueRanking()
    local leagueArchivedData = FootballClubModel:GetLeagueData()
    local currentLeagueCfg = self:GetFootballLeagueDataByLevel(leagueArchivedData.currLeagueLV)
    local result = (teamCount- playerLeagueRanking +1)/(teamCount)/(teamCount+1) * 2 *currentLeagueCfg.pool
    return result
end

--获取玩家联赛排位
function DataManager:GetLeagueRanking()
    self:RefreshCurrentLeagueRankConfig()
    for k, v in pairs(DataManager.leagueRankSorted) do
        if v.id == 0 then 
            return k
        end
    end
end

--达到最大联赛等级
function DataManager:IsMaxLeagueLevel()
    local maxLevel = #DataManager.leagueListCfg
    local playerLeagueMax = FootballClubModel:GetLeagueData().leagueLV
    if playerLeagueMax >= maxLevel then
        return true
    else
        return false
    end
end

--达到已解锁最大联赛等级
function DataManager:IsMaxLeagueLevelUnlocked()
    local playerLeagueMax = FootballClubModel:GetLeagueData().leagueLV
    local playerLeague = FootballClubModel:GetLeagueData().currLeagueLV
    if playerLeagueMax <= playerLeague then
        return true
    else
        return false
    end
end

--检查是否可切换到目标联赛等级
function DataManager:CheckCanSwitchLeague(level)
    if level < 1 or level > #DataManager.leagueListCfg then
        return false
    end
    local leagueData = FootballClubModel:GetLeagueData()
    local canSwitchMax = leagueData.unlockable or leagueData.leagueLV
    if level > canSwitchMax then
        return false
    end
    return true
end