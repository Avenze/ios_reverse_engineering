local FCStadiumUI = GameTableDefine.FCStadiumUI
local FootballClubModel = GameTableDefine.FootballClubModel
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI

local EventManager = require("Framework.Event.Manager")

FCStadiumUI.ROOM_NUM = 10002
FCStadiumUI.ECanNotUpgradeReason = {
    NoMoney = 1,
    NoReq = 2,
    IsMax = 3,
}

function FCStadiumUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_STADIUM_UI, self.m_view, require("GamePlay.FootballClub.UI.FCStadiumUIView"), self, self.CloseView)
    return self.m_view
end

function FCStadiumUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_STADIUM_UI)
    self.m_view = nil
    self.m_Model= nil
    collectgarbage("collect")
end

-------------model-------------
function FCStadiumUI:GetUIModel()
    if not self.m_Model then
        local playerData = FootballClubModel:GetPlayerTeamData()
        local leagueData = FootballClubModel:GetLeagueData()
        local matchData = FootballClubModel:GetMatchData()
        local roomData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        local stadiumLV = roomData.LV
        local stadiumConfig = ConfigMgr.config_stadium[FootballClubModel.m_cfg.id]
        local stadiumCfg = stadiumConfig[stadiumLV]
        local nextLevelStadiumCfg = stadiumConfig[stadiumLV + 1] or nil
        local teamList = self:CreateTeamList()
        local curLeagueCfg = ConfigMgr.config_league[FootballClubModel.m_cfg.id][leagueData.currLeagueLV]
        local curRoomCfg = ConfigMgr.config_stadium[FootballClubModel.m_cfg.id][stadiumLV]
        self.m_Model = 
        {
            --建筑等级
            LV = stadiumLV,
            --场馆config
            stadiumCfg = stadiumCfg,
            --当前容纳的人数
            currCapacity = stadiumCfg.seat,
            --不包含联赛加成的当前门票价格
            currUnitPriceWithoutAdd = stadiumCfg.ticket,
            --当前一张门票的价格
            currUnitPrice = stadiumCfg.ticket + curLeagueCfg.ticket,                        
            --下一级的人数
            nextCapacity = nil,
            --下一级的价格
            nextUnitPrice = nil,
            --玩家的名字
            playerTeamName = playerData.name,            
            --联赛的等级
            currLeague = leagueData.currLeagueLV,
            --比赛次数
            frequency = matchData.frequency,
            --总比赛次数
            totalFrequency = (#teamList - 1) * 2,
            --收益            
            ticketIncome = (stadiumCfg.ticket + curLeagueCfg.ticket) *stadiumCfg.seat,
            --比赛的机会
            matchChance = math.floor(FootballClubModel:GetMatchChange(leagueData)),
            --matchChance = math.floor(leagueData.matchChance),
            --比赛充能上限
            matchChanceLimit = curRoomCfg.matchLimit,
            --比赛的总时长
            totalDuration = FootballClubModel.totalDuration,
            --比赛队伍列表
            teamList = teamList,
            --玩家队伍信息
            playerTeam = FootballClubModel:GetTeamDataByID(),            
            --敌人队伍信息
            enemyTeam = FootballClubModel:GetTeamDataByID(self:GetOpponent(0,matchData.frequency)),     
            --当前等级配置
            stadiumCfg = stadiumCfg,
            --下一等级球馆配置
            nextLevelStadiumCfg = nextLevelStadiumCfg,
            --联赛表
            leagueConfig = ConfigMgr.config_league[FootballClubModel.m_cfg.id],
            --联赛数据
            LeagueData = leagueData,

        }
        
        if nextLevelStadiumCfg then
            for i =self.m_Model.LV ,#stadiumConfig do
                if stadiumConfig[i].seat > self.m_Model.currCapacity then
                    self.m_Model.nextCapacity = stadiumConfig[i].seat
                    self.m_Model.nextCapacityLevel = stadiumConfig[i].level
                    break
                end
            end
            for i =self.m_Model.LV ,#stadiumConfig do
                if stadiumConfig[i].ticket > self.m_Model.currUnitPriceWithoutAdd then
                    self.m_Model.nextUnitPrice = stadiumConfig[i].ticket
                    self.m_Model.nextUnitPriceLevel = stadiumConfig[i].level
                    break
                end
            end
        end
    end
    return self.m_Model
end

function FCStadiumUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

--检查升级是否可用
function FCStadiumUI:GetCanUpgrade()
    if not self.m_Model then
        self:RefreshUIModel()
    end
    if not self.m_Model.nextLevelStadiumCfg then
        return self.ECanNotUpgradeReason.IsMax
    end
    local leagueData = self.m_Model.LeagueData
    if self.m_Model.nextLevelStadiumCfg.upgradeLeague > leagueData.leagueLV then
        return self.ECanNotUpgradeReason.NoReq
    end
    if not ResourceManger:CheckLocalMoney( self.m_Model.nextLevelStadiumCfg.upgradeCash) then
        return self.ECanNotUpgradeReason.NoMoney
    end
    
end


--生成队伍列表
function FCStadiumUI:CreateTeamList()
    local teamCfg = ConfigMgr.config_team_pool[FootballClubModel.m_cfg.id]
    local leagueData = FootballClubModel:GetLeagueData()
    local teamList = {}
    for k,v in pairs(leagueData.rankingList) do
        table.insert(teamList, tonumber(k))
    end
    table.sort(teamList, function(a,b)
        return a < b
    end)
    return teamList
end

--生成赛程表
function FCStadiumUI:GenerateASchedule()    
    local teams = self:CreateTeamList()
    local numList = {}
    -- 将队伍平均分为两组
    local group1 = {}
    local group2 = {}
    for i = 1, #teams do
        if i % 2 == 1 then
            table.insert(group1, teams[i])
        else
            table.insert(group2, teams[i])
        end
    end
    local schedule = {}
    -- 打印比赛组合
    for round = 1, #teams - 1 do
        schedule[round] = {}               
        for i = 1, #group1 do
            table.insert(schedule[round], {group1[i],group2[i]})
        end
        -- 循环移位
        local last1 = table.remove(group1, #group1)
        local first2 = table.remove(group2, 1)
        table.insert(group1, 2, first2)
        table.insert(group2, last1)
    end   
    return schedule
end

--通过赛程表选择敌人
function FCStadiumUI:GetOpponent(teamID, frequency)
    local schedule = self:GenerateASchedule()
    if frequency > #schedule then
        frequency = frequency - #schedule
    end
    local opponents = schedule[frequency]
    local  opponentID
    -- 获取对手的ID
    for k,v in pairs(opponents) do
        if v[1] == teamID then 
            return v[2]
        elseif v[2] == teamID then
            return v[1]
        end
    end
end

--战术加成计算
function FCStadiumUI:TacticalBonus(teamData, tacticsData)

end

--比赛结束后积分的结算
function FCStadiumUI:GetLeaguePoints(preview)    
    local addIntegralList = {}
    local schedule = FCStadiumUI:GenerateASchedule()
    local frequency = self.m_Model.frequency
    if frequency > #schedule then
        frequency = frequency - #schedule
    end
    local schedule = schedule[frequency]
    local matchData = FootballClubModel:GetMatchData()
    for i=1,#schedule do
        local p1 = schedule[i][1]
        local p2 = schedule[i][2]
        local p1Team = FootballClubModel:GetTeamDataByID(p1)
        local p2Team = FootballClubModel:GetTeamDataByID(p2)
        local currState 
        if i == 1 then
            currState = FootballClubModel:GetPlayerGameData()
        else
            currState = FootballClubModel:GetTheGameReportByTimePos(p1Team, p2Team, self.m_Model.totalDuration)
        end
        if currState.playerScore > currState.enemyScore then
            addIntegralList[p1] = 3
            addIntegralList[p2] = 0
        elseif currState.playerScore < currState.enemyScore then
            addIntegralList[p1] = 0
            addIntegralList[p2] = 3
        elseif currState.playerScore == currState.enemyScore then
            addIntegralList[p1] = 1
            addIntegralList[p2] = 1
        end
    end
    if preview then
        return addIntegralList
    end
    for k,v in pairs(addIntegralList) do
        FootballClubModel:AddRankPoints(k, v)
    end
    self.m_Model = self:GetUIModel()
end

--获取同组其他队伍的比赛结果
function FCStadiumUI:GetOtherMatchResultInGroup()
    if not self.m_Model then
        self:GetUIModel()
    end
    local addIntegralList = {}
    local schedule = FCStadiumUI:GenerateASchedule()
    local frequency = self.m_Model.frequency
    if frequency > #schedule then
        frequency = frequency - #schedule
    end
    local schedule = schedule[frequency]
    if schedule[2] then
        for i=2,#schedule do    --从第二组开始计算
            local p1 = schedule[i][1]
            local p2 = schedule[i][2]
            local p1Team = FootballClubModel:GetTeamDataByID(p1)
            local p2Team = FootballClubModel:GetTeamDataByID(p2)
            local currState = FootballClubModel:GetTheGameReportByTimePos(p1Team, p2Team, self.m_Model.totalDuration)
            if currState.playerScore > currState.enemyScore then
                addIntegralList[p1] = 3
                addIntegralList[p2] = 0
            elseif currState.playerScore < currState.enemyScore then
                addIntegralList[p1] = 0
                addIntegralList[p2] = 3
            elseif currState.playerScore == currState.enemyScore then
                addIntegralList[p1] = 1
                addIntegralList[p2] = 1
            end
        end
        for k,v in pairs(addIntegralList) do
            FootballClubModel:AddRankPoints(k, v)
        end
    end
    self.m_Model = self:GetUIModel()
   
end

--开始比赛
function FCStadiumUI:StartTheGame(model)
    local FCState = FootballClubModel:GetCurrentState()
    if FCState == FootballClubModel.EFCState.InTraining then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_1"))
        return
    end
    FootballClubModel:ChangeLeagueMatchChance(-1)
    FootballClubModel:RecordTheStartTimeOfTheGame()
    FootballClubModel:SetMatchState(true)
    FootballClubModel:SetEndOfMatchState(false)
    local playerData = FootballClubModel:GetTeamDataByID(0)
    local matchData = FootballClubModel:GetMatchData()
    local enemyData = FootballClubModel:GetTeamDataByID(FCStadiumUI:GetOpponent(0, matchData.frequency))
    FootballClubModel:StartAGame(playerData,enemyData)

    self:CloseView()
    matchData.ScoreSettlement = false
    LocalDataManager:WriteToFile()

    --埋点
    GameSDKs:TrackForeign("fbclub", {match_number = 1})
end

--结束比赛
function FCStadiumUI:FinishMatch()
    --self:GetLeaguePoints()
    FootballClubModel:ClearTheGameTimePoint()
    FootballClubModel:AddMatchFrequency()
    FootballClubModel:SetMatchState(false)
    FootballClubModel:SetEndOfMatchState(true)
    ResourceManger:AddLocalMoney(self.m_Model.currCapacity* self.m_Model.currUnitPrice, nil, nil, nil ,nil , true)
    GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 0, amount_new = tonumber(self.m_Model.currCapacity* self.m_Model.currUnitPrice) or 0, position = "俱乐部比赛奖励"})
    EventManager:DispatchEvent("FLY_ICON", nil, 6, function()
        MainUI:RefreshCashEarn()
    end)

    self:CloseView()
end

function FCStadiumUI:GetRankingChange()
    local currentRanking = self.m_Model.LeagueData.rankingList
    local curRankingCopy = {}
    for k,v in pairs(currentRanking) do
        table.insert(curRankingCopy,{id = tonumber(k),point = v})
    end
    table.sort(curRankingCopy,function (a,b)
        if a.point == b.point  then
            return a.id < b.id 
        end
        return a.point > b.point 
    end)
    local curRanking = 1
    for k,v in ipairs(curRankingCopy) do
        if v.id == 0 then
            curRanking = k
        end
    end
    --计算比赛后的结果
    local addList = self:GetLeaguePoints(true)
    curRankingCopy = {}
    for k,v in pairs(currentRanking) do
        if addList[tonumber(k)] then
            table.insert(curRankingCopy,{id = tonumber(k),point = v + addList[tonumber(k)]})
        end
    end
    local afterRanking = 1
    table.sort(curRankingCopy,function (a,b)
        if a.point == b.point  then
            return a.id < b.id 
        end
        return a.point > b.point 
    end)
    for k,v in ipairs(curRankingCopy) do
        if v.id == 0 then
            afterRanking = k
        end
    end
    curRankingCopy = nil
    return curRanking - afterRanking --如果为正则排位上升,如果为负则排位下降
end

