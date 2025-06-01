---@class FootballClubModel
local FootballClubModel = GameTableDefine.FootballClubModel
local ResMgr = GameTableDefine.ResourceManger
local CfgMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local ChatEventManager = GameTableDefine.ChatEventManager
local RankDataManager = GameTableDefine.FootballClubLeagueRankDataManager
local SoundEngine = GameTableDefine.SoundEngine
local GuideUI = GameTableDefine.GuideUI
local EventManager = require("Framework.Event.Manager")
local GuideManager = GameTableDefine.GuideManager
local CountryMode = GameTableDefine.CountryMode
local TimerMgr = GameTimeManager
local FCTrainingGroundUI= GameTableDefine.FCTrainingGroundUI
local FCHealthCenterUI= GameTableDefine.FCHealthCenterUI
local FootballClubController = GameTableDefine.FootballClubController
local MainUI = GameTableDefine.MainUI
local FCStadiumUI = GameTableDefine.FCStadiumUI
local FootballClubScene = nil
local LocalDataManager = LocalDataManager
-- FootballClubModel.totalDuration = 41    --比赛持续时间
-- FootballClubModel.triggerInterval = 1    --比赛计算触发间隔
FootballClubModel.totalDuration = nil       --比赛持续时间
FootballClubModel.triggerInterval = nil     --比赛计算触发间隔

FootballClubModel.ClubCenterID = 10001
FootballClubModel.StadiumID = 10002
FootballClubModel.TrainingGroundID = 10003
FootballClubModel.HealthCenterID = 10005

local SPFieldName = "SP"
local MatchChanceFieldName = "matchChance"

FootballClubModel.EFCState = {
    Unsigned = 1,   --未签约
    InTheGame = 2,  --比赛中
    GameSettlement = 3, --比赛结算
    InTraining = 4, --训练中
    TrainingSettlement = 5, --训练结算
    SeasonSettlement = 6,   --赛季结算
    Idle = 7, --闲置
}

FootballClubModel.gameData = nil --玩家比赛数据.缓存计算过的比赛过程,避免重复调用比赛过程计算

local isInited = false
local startCalculated = false

function FootballClubModel:GetUnlockFCData()
    local localData = LocalDataManager:GetCurrentRecord()
    for i=1,#CfgMgr.config_country do
        if CountryMode.SAVE_KEY and CountryMode.SAVE_KEY[i] then
            local tempFCname = "football" .. CountryMode.SAVE_KEY[i]
            local FAData = localData[tempFCname]
            if FAData and next(FAData) ~= nil then
                for k,v in pairs(CfgMgr.config_buildings) do
                    if v.country == i and FAData[v.mode_name] then
                        return v
                    end
                end
            end
        end
    end
    return nil 
end

function FootballClubModel:Init(cfg, go) 
    self.m_cfg = cfg     --config_buildings
    self.go = go    --FC预制体
    --处理数据
    self.totalDuration = CfgMgr.config_global.match_speed.duration    --比赛持续时间
    self.triggerInterval = CfgMgr.config_global.match_speed.interval    --比赛计算触发间隔
    --先检测初始化存档的数据
    self:InitFCData(cfg)
    
    --通过存档和配置表的数据初始化处理好游戏中需要的数据
    RankDataManager:InitFootballClubLeagueData()

    self.curFCState = self:GetCurrentState()    --当前状态

    --计算离线数据
    if not isInited then
        self:SettlementClubData()
    end

    isInited = true
end

function FootballClubModel:IsInitialized() 
    return isInited
end

--进入时
function FootballClubModel:OnEnter()
    --用处理好的数据初始化场景
    FootballClubScene = require("GamePlay.FootballClub.FootballClubScene")
    FootballClubScene:Init(self.m_cfg, self.go)    
    --维护一个计时器用来刷新比赛数据,保证比赛的数据只在这里刷新
    self.gameTimer = GameTimer:CreateNewMilliSecTimer(100,function ()
        if not self.gameData then
            return
        end
        local now = GameTimeManager:GetCurrentServerTime(true)
        local lastStartTime = self:GetMatchData().lastStarTime
        if self.curFCState == self.EFCState.InTheGame then
            local timePos = now - lastStartTime
            if not self.gameIntervalTimer then
                self.gameIntervalTimer = (now - lastStartTime) % self.triggerInterval
            end

            if self.gameIntervalTimer >= self.triggerInterval then
                self.gameIntervalTimer = 0
                self:GetTheGameReportByTimePos(self.gameData.playerData,self.gameData.enemyData,timePos,self.gameData)
            else
                self.gameIntervalTimer = self.gameIntervalTimer + 0.1
            end
        end

    end,true,true)
end

--退出时
function FootballClubModel:OnExit()
    if self.gameTimer then
        GameTimer:StopTimer(self.gameTimer)
    end
    FootballClubScene:OnExit()
    self.m_FCData = nil
end

function FootballClubModel:Update()
    if not self.IsInitialized() then
        return
    end 
    
    if not GameTableDefine.FloorMode:IsInFootballClub() then
        return
    end
    local Input = CS.UnityEngine.Input
    local UnityHelper = CS.Common.Utils.UnityHelper
    if GameConfig:IsDebugMode() then
        if GameDeviceManager:IsiOSDevice() then
        elseif GameDeviceManager:IsAndroidDevice() then
        else
            if Input.GetMouseButtonDown(2) then
                GameTableDefine.CheatUI:GetView()
            end
        end
    end

end

--初始化存档的数据
function FootballClubModel:InitFCData(cfg)
    self:GetFCDataById(cfg.id,cfg.country) 
    for i,v in pairs(CfgMgr.config_football_club[cfg.id]) do
        self:GetRoomDataById(v.id)
    end
    self:GetPlayerTeamData()
    self:GetLeagueData()
    self:GetMatchData()
end

--检查俱乐部是否存在
function FootballClubModel:CheckFCData(id)
    local key = CfgMgr.config_buildings[id].mode_name
    local countryId = CfgMgr.config_buildings[id].country
    local name = "football" .. CountryMode.SAVE_KEY[countryId]
    local FCCountryData =  LocalDataManager:GetCurrentRecord()[name]
    if FCCountryData then
        return FCCountryData[key]
    end
end

--通过buildingID获取当前地区足球俱乐部的存档数据
function FootballClubModel:GetFCDataById(id)
    if not self.m_FCData then
        local key = CfgMgr.config_buildings[id].mode_name
        local countryId = CfgMgr.config_buildings[id].country

        local allFootballClubData = LocalDataManager:GetDataByKey("football" .. CountryMode.SAVE_KEY[countryId])
        if not allFootballClubData[key] or Tools:GetTableSize(allFootballClubData[key]) == 0 then
            local playerTeamCfg = CfgMgr.config_team_pool[id][0]
            local clubCfg = CfgMgr.config_club_data[id][1]
            allFootballClubData[key] = 
            {
                LV = 1,
                curEXP = 0,
                SPlimit = playerTeamCfg.str,
                SP = playerTeamCfg.str,
                activation = true,
            }
            LocalDataManager:WriteToFile()
        end
        self.m_FCData = allFootballClubData[key]
    end
    return self.m_FCData
end


--改变SP
function FootballClubModel:ChangeSP(FCData, num)
    if not FCData then
        FCData = self.m_FCData
    end
    if not FCData then
        return
    end

    local curNum = LocalDataManager:DecryptField(FCData,SPFieldName)
    curNum = math.max(0,math.min(curNum + num,FCData.SPlimit))
    LocalDataManager:EncryptField(FCData,SPFieldName,curNum)

    --if not FCData then
    --    FCData = self.m_FCData
    --end
    --if not FCData then
    --    return
    --end
    --if FCData.SP + num > FCData.SPlimit then
    --    FCData.SP = FCData.SPlimit
    --
    --elseif FCData.SP + num < 0 then
    --    FCData.SP = 0
    --else
    --    FCData.SP = FCData.SP + num
    --end
    LocalDataManager:WriteToFile()

end

--改变SPLimit
function FootballClubModel:ChangeSPLimit(FCData, num)
    if not FCData then
        FCData = self.m_FCData
    end
    if not FCData or num < 0 then
        return 
    end
    FCData.SPlimit = FCData.SPlimit + num
    LocalDataManager:WriteToFile()

end

--刷新体力充能
function FootballClubModel:RefreshStrengthCharge()
    local healthCenterData = self:GetRoomDataById(self.HealthCenterID)   
    healthCenterData.useTime = TimerMgr:GetCurrentServerTime(true)
    LocalDataManager:WriteToFile()

end

--升级俱乐部等级
function FootballClubModel:UpgradeClubLevel(cb)
    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end
    local success = false
    if CfgMgr.config_club_data[self.m_cfg.id][self.m_FCData.LV].exp <= self.m_FCData.curEXP then
        self.m_FCData.LV = 1 + self.m_FCData.LV
        self.m_FCData.curEXP = self.m_FCData.curEXP - CfgMgr.config_club_data[self.m_cfg.id][self.m_FCData.LV].exp
        LocalDataManager:WriteToFile()
        success = true
    end
    if cb then
        cb(success)
    end
    MainUI:EnterFootballClubSetUI()
    
    EventManager:DispatchEvent("CLUB_EXPERIENCE_CHANGE")
    --埋点
    GameSDKs:TrackForeign("fbclub", {level_new = tonumber(self.m_FCData.LV) or 0})
end

--增加俱乐部经验
function FootballClubModel:AddClubEXP()
    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end
    self.m_FCData.curEXP = self.m_FCData.curEXP + 1

    MainUI:EnterFootballClubSetUI()

    LocalDataManager:WriteToFile()
end

--通过配置Id获取到房间的存档数据
function FootballClubModel:GetRoomDataById(roomId)
    local roomName 
    if not CfgMgr.config_football_club[self.m_cfg.id][roomId] then
        return
    end
    roomName = CfgMgr.config_football_club[self.m_cfg.id][roomId].objName
    local stateInit = 0
    if CfgMgr.config_football_club[self.m_cfg.id][roomId].unlockRoom == 0 then
        stateInit = 2
    end

    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end
    if not self.m_FCData[roomName] then
        self.m_FCData[roomName] = 
        --初始化房间数据
        {
            LV = 1,      
            state = stateInit,
            startTime = 0,
        }
        LocalDataManager:WriteToFile()
    end
    return self.m_FCData[roomName]
end

--房间升级
function FootballClubModel:RoomUpgrade(roomNum, cb)
    local success = false
    local roomData = self:GetRoomDataById(roomNum)
    local roomName = CfgMgr.config_football_club[self.m_cfg.id][roomNum].objName
        roomName = roomName:gsub("%u", function(c)
        return "_" .. c:lower()
    end)
    local MaxLV = #CfgMgr["config".. roomName][self.m_cfg.id]
    if roomNum == 10003 then
        MaxLV = #CfgMgr["config".. roomName][self.m_cfg.id].RoomInfo
    end
    if roomData.LV < MaxLV then
        roomData.LV = roomData.LV + 1
        success = true  
        self:AddClubEXP()
        LocalDataManager:WriteToFile()        
        EventManager:DispatchEvent("CLUB_EXPERIENCE_CHANGE")

        FootballClubController:PlayRoomUpgradeFB(roomNum)
    end
    if cb then
        cb(success)
    end
end

--获取到玩家的球队的存档数据
function FootballClubModel:GetPlayerTeamData()
    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end
    if not self.m_FCData.playerTeam then
        local cfg = CfgMgr.config_team_pool[self.m_cfg.id][0];
        self.m_FCData.playerTeam = cfg
        self.m_FCData.playerTeam.name = GameTextLoader:ReadText(cfg.name)
        LocalDataManager:WriteToFile()
    end
    self.m_FCData.playerTeam.level = self:GetLeagueData().currLeagueLV or 1
    return self.m_FCData.playerTeam
end

--改变玩家的存档中的属性 attributeType(属性类型) variation(改变量)
function FootballClubModel:SetPlayerAttributes(attributeType, variation)
    local playerData = self:GetPlayerTeamData()
    if playerData and playerData.attributeType then
        local targetValue = variation + playerData.attributeType
        if targetValue > 0 then
            playerData.attributeType = targetValue
            LocalDataManager:WriteToFile()
        end
    end
end

--获取联赛存档数据
function FootballClubModel:GetLeagueData()
    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end    
    if not self.m_FCData.league then
        self.m_FCData.league = 
        {               
            --已到达的联赛等级
            leagueLV = 1,
            --当前选择的联赛等级
            currLeagueLV = 1;
            --比赛机会
            matchChance = 1,
            --充能开始时间
            chargeTime = 0,
            --联赛列表
            rankingList = self:CreateRankList(1),
        }
        LocalDataManager:WriteToFile()
    end
    return self.m_FCData.league
end

--增加联赛的队伍的积分
function FootballClubModel:AddRankPoints(teamId, addPoint)
    teamId = tostring(teamId)
    local leagueData= self:GetLeagueData()
    if not leagueData.rankingList[teamId] then
        return
    end
    leagueData.rankingList[teamId] = leagueData.rankingList[teamId] + addPoint
    LocalDataManager:WriteToFile()
end

--根据联赛等级创建比赛列表
function FootballClubModel:CreateMatchListByLeague(leagueLV)
    local allTeamsAtTheCurrentLevel = {}
    local competitionTeam = {}
    local teamNum = CfgMgr.config_league[self.m_cfg.id][leagueLV].team
    for k,v in pairs(CfgMgr.config_team_pool[self.m_cfg.id]) do
        if v.level == leagueLV then
            table.insert(allTeamsAtTheCurrentLevel, v)
        end
    end
    -- for i=1, teamNum do
    --     local index = math.random(1, #allTeamsAtTheCurrentLevel)
    --     while allTeamsAtTheCurrentLevel[index].id == 0 do 
    --         index = math.random(1, #allTeamsAtTheCurrentLevel)                  
    --     end
    --     table.insert(competitionTeam, allTeamsAtTheCurrentLevel[index])
    --     table.remove(allTeamsAtTheCurrentLevel, index)               
    -- end 
    for i=1,#allTeamsAtTheCurrentLevel do
        if allTeamsAtTheCurrentLevel[i].id == 0 then
            table.remove(allTeamsAtTheCurrentLevel,i)
            break
        end
    end
    table.insert(allTeamsAtTheCurrentLevel,CfgMgr.config_team_pool[self.m_cfg.id][0])

    return allTeamsAtTheCurrentLevel
end

function FootballClubModel:CreateRankList(Leaguelevel)
    local rankList = {}
    local matchList = self:CreateMatchListByLeague(Leaguelevel)
    for k,v in pairs(matchList) do
        rankList[tostring(v.id)] = 0
    end
    return rankList
end

--获取比赛的存档数据
function FootballClubModel:GetMatchData()
    if not self.m_FCData then
        self.m_FCData = self:GetFCDataById(self.m_cfg.id) 
    end
    if not self.m_FCData.match then
        self.m_FCData.match = 
        {   
            --比赛次数
            frequency = 1,
            catchSP = 0,
        }
        LocalDataManager:WriteToFile()
    end
    return self.m_FCData.match
end

--记录比赛开始时间,并且作为需要结算比赛结果的标识
function FootballClubModel:RecordTheStartTimeOfTheGame()
    local FCData = self:GetFCDataById(self.m_cfg.id)
    local matchData = self:GetMatchData()
    matchData.lastStarTime = TimerMgr:GetCurrentServerTime(true)
    --记录比赛开始时的体力状态
    matchData.catchSP = self:GetSP()
    --matchData.catchSP = FCData.SP
    LocalDataManager:WriteToFile()
end

--清空比赛时间点
function FootballClubModel:ClearTheGameTimePoint()
    local matchData = self:GetMatchData()
    matchData.lastStarTime = nil
    LocalDataManager:WriteToFile()
end

--设置在比赛中状态
function FootballClubModel:SetMatchState(active)
    local matchData = self:GetMatchData()
    matchData.inGame = active
    LocalDataManager:WriteToFile()
end

--设置比赛结束状态
function FootballClubModel:SetEndOfMatchState(active)
    local matchData = self:GetMatchData()
    matchData.gameOver = active
    LocalDataManager:WriteToFile()
end

--获取玩家比赛数据 需要先开始一场比赛
function FootballClubModel:GetPlayerGameData()
    if self.gameData then
        return self.gameData
    else
        local playerData = FootballClubModel:GetTeamDataByID(0)
        local matchData = FootballClubModel:GetMatchData()
        local enemyData = FootballClubModel:GetTeamDataByID(FCStadiumUI:GetOpponent(0, matchData.frequency))
        self:StartAGame(playerData,enemyData)
        return self.gameData
    end
end

--增加比赛场次
function FootballClubModel:AddMatchFrequency()
    local Schedule = FCStadiumUI:GenerateASchedule()
    local matchData = self:GetMatchData()
    matchData.frequency = matchData.frequency + 1 
    if matchData.frequency > #Schedule * 2 then
        matchData.frequency = #Schedule * 2
    end
    LocalDataManager:WriteToFile()

end

--清空比赛场次
function FootballClubModel:ClearMatchFrequency()
    local matchData = self:GetMatchData()
    matchData.frequency = 1
    LocalDataManager:WriteToFile()

end

--通过球队id创建一个球队类型数据
function FootballClubModel:GetTeamDataByID(id,buff)
    local cfg
    local weight = 1
    local tacticalPool
    if not id or id == 0 then
        cfg = self:GetPlayerTeamData()
        tacticalPool = {}
    else
        cfg = CfgMgr.config_team_pool[self.m_cfg.id][id]
        tacticalPool = cfg.tacticId
    end
    for k,v in pairs(CfgMgr.config_league[self.m_cfg.id]) do
        if v.level == cfg.level then
            weight = v.balance
        end 
    end
    local teamCfg = 
    {   cfg = cfg,
        level = cfg.level,
        weight = weight,         
        tacticalPool = tacticalPool,
        atk = cfg.atk * (1 + (buff or 0)),
        def = cfg.def * (1 + (buff or 0)),
        ogz = cfg.ogz * (1 + (buff or 0)),               
        --进攻
        attack = (weight * (cfg.atk * (1 + (buff or 0)))) / (weight + (cfg.atk * (1 + (buff or 0)))),
        --防守
        defend = (weight * (cfg.def * (1 + (buff or 0)))) / (weight + (cfg.def * (1 + (buff or 0)))),
        --组织
        tactic = (weight * (cfg.ogz * (1 + (buff or 0)))) / (weight + (cfg.ogz * (1 + (buff or 0)))),
        --综合
        synthesize = 
            ((weight * (cfg.atk * (1 + (buff or 0)))) / (weight + (cfg.atk * (1 + (buff or 0))))) + 
            ((weight * (cfg.def * (1 + (buff or 0)))) / (weight + (cfg.def * (1 + (buff or 0))))) + 
            ((weight * (cfg.ogz * (1 + (buff or 0)))) / (weight + (cfg.ogz * (1 + (buff or 0))))),
    }
    return teamCfg
end

--开始一场比赛
function FootballClubModel:StartAGame(playerData,  enemyData)
    local lastMatchTime = self:GetMatchData().lastStarTime or 0
    local now = GameTimeManager:GetCurrentServerTime(true)
    local timaRemaining = now - lastMatchTime
    local gameState = self:GetTheGameReportByTimePos(playerData,enemyData,timaRemaining,nil)
    if playerData.cfg.id == 0 or enemyData.cfg.id == 0 then
        self.gameData = gameState
    end
end

--根据时点和随机种子获取比赛的战报
function FootballClubModel:GetTheGameReportByTimePos(playerData,  enemyData, timePos, currState)
    local matchData = self:GetMatchData()
    local key = matchData.lastStarTime or 0
    
    if not currState or Tools:GetTableSize(currState) == 0 then
        currState = 
        {   gameTime = 0,
            playerScore = 0,
            enemyScore = 0,
            atk = playerData,
            def = enemyData,
            focusPosition = 3,       
            report = {},
            playerData = playerData,
            enemyData = enemyData,
        }
        --先攻判定
        local locKey = tostring(((key + currState.gameTime)*12345)%10000)
        math.randomseed(locKey)
        if math.random(0, 1) == 1 then
            currState.atk = playerData
            currState.def = enemyData
        else
            currState.atk = enemyData
            currState.def = playerData
        end
    end    

    AttributesAffectedByBuff = function ()
        local attrAffected = currState.playerData
        if currState.def.cfg.id == 0 or currState.atk.cfg.id == 0 then
            local leagueData = self:GetLeagueData()
            local reducePerSecond = CfgMgr.config_league[self.m_cfg.id][leagueData.currLeagueLV].cost / self.totalDuration * FootballClubModel.triggerInterval
            if matchData.catchSP - (currState.gameTime / self.triggerInterval) * reducePerSecond <= 0 then
                attrAffected = self:GetTeamDataByID(attrAffected.cfg.id, -0.2)
                
                if currState.def.cfg.id == attrAffected.cfg.id then
                    currState.def = attrAffected
                else
                    currState.atk = attrAffected
                end
                -- print("attrAffected: \n", "[atk]:",attrAffected.atk,"[def]:",attrAffected.def,"[ogz]:",attrAffected.ogz,
                -- "[进攻方]:",currState.atk.cfg.id, "[atk]:",currState.atk.cfg.atk,"[def]:",currState.atk.cfg.def,"[ogz]:",currState.atk.cfg.ogz,
                -- "[防守方]:",currState.def.cfg.id,"[atk]:",currState.def.atk,"[def]:",currState.def.def,"[ogz]:",currState.def.ogz)
            end
        end

    end

    --拦截判定
    Intercept = function()
        local probability = ((((currState.def.tactic - currState.atk.tactic) * 0.7) + ((currState.def.defend - currState.atk.attack) * 0.3)) / (currState.atk.synthesize +currState.def.synthesize ) ) + 0.3
        local locKey = tostring(((key + currState.gameTime)*12345)%10000)
        print(locKey)
        math.randomseed(locKey)
        local hand = math.random(0, 1000)
        print("----------拦截判定[hand]", hand,"[判定值]:",probability * 1000,
        "[进攻方]:",currState.atk.cfg.id, "[atk]:",currState.atk.atk,"[def]:",currState.atk.def,"[ogz]:",currState.atk.ogz,"[attack]:",currState.atk.attack,"[defend]:",currState.atk.defend,"[tactic]:",currState.atk.tactic,"[synthesize]:",currState.atk.synthesize,
        "[防守方]:",currState.def.cfg.id,"[atk]:",currState.def.atk,"[def]:",currState.def.def,"[ogz]:",currState.def.ogz,"[attack]:",currState.def.attack,"[defend]:",currState.def.defend,"[tactic]:",currState.def.tactic,"[synthesize]:",currState.def.synthesize)
        return hand <= probability * 1000
    end
    --射门判定
    Shoot = function()
        local probability = ((((currState.atk.tactic - currState.def.tactic) * 0.3) + ((currState.atk.attack - currState.def.defend) * 0.7)) / (currState.atk.synthesize +currState.def.synthesize) ) + 0.4
        local locKey = tostring(((key + currState.gameTime)*12345)%10000)
        print(locKey)
        math.randomseed(locKey)
        local hand = math.random(0, 1000)
        print("-----------射门判定[hand]", hand,"[判定值]:",probability * 1000,
        "[进攻方]:",currState.atk.cfg.id, "[atk]:",currState.atk.atk,"[def]:",currState.atk.def,"[ogz]:",currState.atk.ogz,"[attack]:",currState.atk.attack,"[defend]:",currState.atk.defend,"[tactic]:",currState.atk.tactic,"[synthesize]:",currState.atk.synthesize,
        "[防守方]:",currState.def.cfg.id,"[atk]:",currState.def.atk,"[def]:",currState.def.def,"[ogz]:",currState.def.ogz,"[attack]:",currState.def.attack,"[defend]:",currState.def.defend,"[tactic]:",currState.def.tactic,"[synthesize]:",currState.def.synthesize)
        return hand <= probability * 1000
    end
    --得分
    GetScore = function()
        if currState.atk == playerData then
            currState.playerScore = currState.playerScore + 1
        else
            currState.enemyScore = currState.enemyScore + 1
        end
        --比赛喝彩场景表现
        if (playerData.cfg.id == 0 or enemyData.cfg.id == 0) and self.curFCState == self.EFCState.InTheGame then
            FootballClubController:PlayStadiumGoalFeel()
        end
    end
    --攻守交换
    ExchangeAD = function()
       --拦截成功
       local deposit = currState.atk
       currState.atk = currState.def
       currState.def = deposit    
    end
    --位置改变方法
    Advance = function()
        if currState.atk.cfg.id == playerData.cfg.id then
            currState.focusPosition = currState.focusPosition + 1
        else
            currState.focusPosition = currState.focusPosition - 1
        end        
    end
    --战报生成
    GenerateSignal = function(signalType)
        local atkString 
        local defString
        local info
        if currState.atk.cfg.id == playerData.cfg.id then
            atkString = "玩家"
            defString = "对手"
        else
            atkString = "对手"
            defString = "玩家"
        end 
        if signalType == 0 then --截断战报
            info = atkString .. "先攻"
        elseif signalType == 1 then
            info = atkString .. "被" .. defString .. "截断成功"
        elseif signalType == 2 then -- 射门战报
            info = atkString .. "被" .. defString .. "截断失败"
        elseif signalType == 3 then
            info = atkString .. "射门成功"
        elseif signalType == 4 then  
            info = atkString .. "射门失败"
        end
        print(info)
        table.insert(currState.report, info)
    end    
    --开始计算
    if timePos == 0 then
        GenerateSignal(0)
    end    
    while currState.gameTime <= timePos and currState.gameTime <= self.totalDuration do
        AttributesAffectedByBuff()  --buff属性计算
        if currState.focusPosition <= 4 and currState.focusPosition >= 2 then
            --拦截过程
            if Intercept() then
                GenerateSignal(1)
                ExchangeAD()   
            else
                GenerateSignal(2)
            end
            Advance()
        else
            --射门过程
            if Shoot() then
                GenerateSignal(3)
                GetScore()
            else
                GenerateSignal(4)
            end
            ExchangeAD()
            currState.focusPosition = 3
        end
        currState.gameTime = currState.gameTime + self.triggerInterval
    end
    key = tostring(os.time()%10000)
    math.randomseed(key:reverse():sub(1,10))
    return currState
end


--根据传入的俱乐部数据获取体力的变化速度/s
function FootballClubModel:GetSPSpeedByFCData(FCData, buildingId)
    if not FCData then
        FCData = self.m_FCData
    end
    if not FCData then
        return 
    end
    local SPSpend
    if FCData.match.lastStarTime and FCData.match.lastStarTime + self.totalDuration > TimerMgr:GetCurrentServerTime(true) then  
        return -1      --比赛中
    elseif FCData.TrainingGround.trainingProject and FCData.TrainingGround.trainingDuration then                     
        SPSpend = FCTrainingGroundUI:GetTrainingSPSpendByFCData(FCData, buildingId)                                                                                 
        return SPSpend --训练中
    else        
        SPSpend = FCHealthCenterUI:GetSPRecoverySpeed(FCData, buildingId)
        return SPSpend --闲置
    end
end

function FootballClubModel:GetBuildingIdByBuildingName(buildingName)
    for k,v in pairs(CfgMgr.config_buildings) do
        if v.mode_name == buildingName then
        return v.id
        end
    end    
end


--离线计算俱乐部数据
function FootballClubModel:SettlementClubData()
    if not self.m_FCData then
        return self
    end
    local now = GameTimeManager:GetCurServerOrLocalTime()
    local pastTime = now - (self.m_FCData.m_CurLastOfflineTime or now)
    
    --比赛机会充能
    local leagueData = self:GetLeagueData()
    local stadiumData = self:GetRoomDataById(self.StadiumID)
    local stadiumLV = stadiumData and stadiumData.LV
    local stadiumCfg = CfgMgr.config_stadium[self.m_cfg.id][stadiumLV]
    if leagueData and leagueData.chargeTime and stadiumData.state == 2 then
        local matchCharge = leagueData.chargeTime + pastTime
        if matchCharge < 0 then
            matchCharge = 0
        end
        local chargeNum = matchCharge // (CfgMgr.config_stadium[self.m_cfg.id][stadiumLV].matchCD * 3600)
        if chargeNum >= stadiumCfg.matchLimit then
            self:ChangeLeagueMatchChance(chargeNum)
            leagueData.chargeTime = 0
        else
            self:ChangeLeagueMatchChance(chargeNum)
            leagueData.chargeTime = matchCharge % (CfgMgr.config_stadium[self.m_cfg.id][stadiumLV].matchCD * 3600)
        end
    end
    
    --刷新体力充能
    local calTime = pastTime
    local matchData = self:GetMatchData()
    local trainingGroundData = self:GetRoomDataById(self.StadiumID) 
    if trainingGroundData and trainingGroundData.trainingDuration then
        local trainingDur = trainingGroundData.trainingDuration * 3600
        if now - (trainingGroundData.lastStarTime + trainingDur) > 0 and calTime > now - (trainingGroundData.lastStarTime + trainingDur) then
            calTime = now - (trainingGroundData.lastStarTime + trainingDur)
        end
    end
    if matchData and matchData.lastStarTime then
        if  now - (matchData.lastStarTime + self.totalDuration) > 0 and calTime > now - matchData.lastStarTime then
            calTime = now - matchData.lastStarTime
        end
    end
    local SPSpend = FCHealthCenterUI:GetSPRecoverySpeed(self.m_FCData, self.m_cfg.id)
    local SPRevert = SPSpend * calTime
    self:ChangeSP(self.m_FCData, SPRevert)

    LocalDataManager:WriteToFile()
end

--获取俱乐部当前状态
function FootballClubModel:GetCurrentState()
    local FCData = self:GetFCDataById(self.m_cfg.id)
    local currTime = TimerMgr:GetCurrentServerTime(true)
    local result = nil
    --已签约
    if FCData.activation then
        --比赛中
        if FCData.match and FCData.match.lastStarTime 
        and FCData.match.lastStarTime + self.totalDuration > currTime then  
            result = self.EFCState.InTheGame
    
        --比赛结算
        elseif FCData.match and FCData.match.lastStarTime
        and FCData.match.lastStarTime + self.totalDuration <= currTime then
            result = self.EFCState.GameSettlement
    
        --训练中    
        elseif FCData.TrainingGround.trainingProject 
        and FCData.TrainingGround.trainingDuration 
        and FCData.TrainingGround.lastStarTime 
        and FCData.TrainingGround.lastStarTime + (FCData.TrainingGround.trainingDuration * 60 * 60) > currTime then
            result = self.EFCState.InTraining
    
        --训练结算
        elseif FCData.TrainingGround.trainingProject 
        and FCData.TrainingGround.trainingDuration 
        and FCData.TrainingGround.lastStarTime 
        and FCData.TrainingGround.lastStarTime + (FCData.TrainingGround.trainingDuration * 60 * 60) <= currTime then  
            result = self.EFCState.TrainingSettlement
    
        --赛季结算
        elseif false then
            result = self.EFCState.SeasonSettlement
    
        --闲置                            
        else                            
            result = self.EFCState.Idle                       
        end
        
    --未签约
    else
        result = self.EFCState.Unsigned
    end
    if self.curFCState ~= result then
        EventManager:DispatchEvent("FC_STATE_CHANGE",self.curFCState ,result)
        self.curFCState = result
    end

    return result
end

--floorModel初始化时调用一次,在方法内用timer循环计算数据
function FootballClubModel:CalculateFCData()
    if not isInited then
        return
    end
    if not startCalculated then
        -- PayWeeklySalary = function(FCData, buildingId)
        --     if FCData.activation == nil then return end
        --     local clubCfg = CfgMgr.config_club_data[buildingId][FCData.ClubCenter.LV]
        --     ResMgr:SpendLocalMoney(clubCfg.salary, nil ,function(isEnough)
        --         if isEnough then
        --             FCData.activation = true
        --         else
        --             FCData.activation = false
        --         end            
        --         LocalDataManager:WriteToFile()
        --     end)          
        -- end
        
        for k,v in pairs(CfgMgr.config_country) do
            local AllFCData = LocalDataManager:GetCurrentRecord()["football" .. CountryMode.SAVE_KEY[v.id]]
            if AllFCData then
                for i,o in pairs(AllFCData) do
                    if o then
                        local buildingId = self:GetBuildingIdByBuildingName(i)
                        if self.calculateTimer then
                            GameTimer:StopTimer(self.calculateTimer)
                        end
                        self.calculateTimer = GameTimer:CreateNewMilliSecTimer(1000, function()
                            local leagurData = self:GetLeagueData()
                            local leagurCfg = CfgMgr.config_league[self.m_cfg.id][leagurData.currLeagueLV]
                            local SPSpend
                            local curState = self:GetCurrentState()
                            --比赛中
                            if curState == self.EFCState.InTheGame then  
                                SPSpend = -leagurCfg.cost/self.totalDuration
                            --训练中    
                            elseif curState == self.EFCState.InTraining then      
                                SPSpend = 0 --FCTrainingGroundUI:GetTrainingSPSpendByFCData(o, buildingId)     开始时全部扣除
                            --训练结算
                            elseif curState == self.EFCState.TrainingSettlement then  
                                SPSpend = FCHealthCenterUI:GetSPRecoverySpeed(o, buildingId)
                            --未签约
                            elseif curState == self.EFCState.Unsigned then  
                                SPSpend = 0
                            --比赛结算/赛季结算/闲置                            
                            else                            
                                SPSpend = FCHealthCenterUI:GetSPRecoverySpeed(o, buildingId)                            
                            end        
                            self:ChangeSP(o, SPSpend)

                            self:MatchChargeUpdate(o)
                            --local curState = self:GetCurrentState()

                        end, true, true)
                    end
                end
            end
        end    
    end
    startCalculated = true
end

--比赛充能
function FootballClubModel:MatchChargeUpdate(FCData)
    if not FCData then
        FCData = self.m_FCData
    end
    if not FCData then
        return 
    end
    local stadiumData = self:GetRoomDataById(self.StadiumID)
    local leagueData = self:GetLeagueData()

    if not leagueData.chargeTime then
        leagueData.chargeTime = 0
        LocalDataManager:WriteToFile()
    end
    
    if (not FCData.activation) and stadiumData.state ~= 2 then
        return
    end
    local stadiumCfg = CfgMgr.config_stadium[self.m_cfg.id][stadiumData.LV]
    if leagueData.chargeTime >= stadiumCfg.matchCD *3600 then
        local matchChance = self:GetMatchChange(leagueData)
        if matchChance < stadiumCfg.matchLimit then
            self:ChangeLeagueMatchChance(1)
        end
        leagueData.chargeTime = 0
    else
        leagueData.chargeTime = leagueData.chargeTime + 1
    end
    LocalDataManager:WriteToFile()
end

--改变比赛充能数量
function FootballClubModel:ChangeLeagueMatchChance(number)
    local FCData = self.m_FCData
    local leagueData = self:GetLeagueData()
    local stadiumLV = self:GetRoomDataById(self.StadiumID).LV
    local matchLimit = CfgMgr.config_stadium[self.m_cfg.id][stadiumLV].matchLimit
    local matchChance = self:GetMatchChange(leagueData)
    matchChance = math.max(0,math.min(matchChance + number,matchLimit))
    self:SetMatchChance(leagueData,matchChance)
    --if  leagueData.matchChance > matchLimit then
    --    leagueData.matchChance = matchLimit
    --end
    --if leagueData.matchChance < 0 then
    --    leagueData.matchChance = 0
    --end
    LocalDataManager:WriteToFile()
end

--设置俱乐部签约状态
function FootballClubModel:SetFCActivation(Activation)
    local FCData = self.m_FCData
    FCData.activation = Activation
    LocalDataManager:WriteToFile()
end

--重置赛季比赛积分
function FootballClubModel:ResetGamePoints()
    local leagueData = self:GetLeagueData()
    if leagueData.rankingList then
        for k,v in pairs(leagueData.rankingList) do
            leagueData.rankingList[k] = 0
        end
    end
    LocalDataManager:WriteToFile()

end

--结束联赛
function FootballClubModel:FinishSeason(rank)
    if RankDataManager:IsMaxLeagueLevelUnlocked() and not RankDataManager:IsMaxLeagueLevel() then
        local leagueData = self:GetLeagueData()
        local leagueLV = leagueData.leagueLV
        --可解锁联赛等级
        if rank <= 2 then
            leagueData.unlockable = leagueLV + 1
        else
            leagueData.unlockable = nil
        end
        --刷新联赛参赛队伍列表
        leagueData.rankingList = self:CreateRankList(leagueData.currLeagueLV)
        LocalDataManager:WriteToFile()
    end
    self:ClearMatchFrequency()
    self:SetFCActivation(false)
end

--切换联赛等级
function FootballClubModel:SwitchLeague(level)
    local leagueData = self:GetLeagueData()
    if level == leagueData.unlockable then
        leagueData.leagueLV = level
        leagueData.unlockable = nil 
    end
    leagueData.currLeagueLV = level
    --刷新联赛参赛队伍列表
    leagueData.rankingList = self:CreateRankList(level)

    LocalDataManager:WriteToFile()
end

--[[
    @desc: 游戏暂停，调用离线保存时间，退出副本和在副本中切换app到后台
    author:{gxy}
    time:2023-8-18 11:44:44
    @return:
]]
function FootballClubModel:OnPause()
    if not self.m_FCData then   --如果没有,就是还没开
        return
    end
    self.m_FCData.m_CurLastOfflineTime = GameTimeManager:GetCurServerOrLocalTime()
    LocalDataManager:WriteToFile()
end

--[[
    @desc: 游戏恢复，调用离线的计算，主要用于在副本中切到app后台
    author:{gxy}
    time:2023-8-18 11:44:59
    @return:
]]
function FootballClubModel:OnResume()
    self:SettlementClubData()
end

---获取体力的统一接口
function FootballClubModel:GetSP(FCData)
    if not FCData then
        FCData = self.m_FCData
    end
    if FCData then
        local curNum = LocalDataManager:DecryptField(FCData,SPFieldName)
        return curNum
    end
    return 0
end

--设置体力的统一接口
--function FootballClubModel:SetSP(num)
--    if self.m_FCData then
--        local curNum = LocalDataManager:DecryptField(self.m_FCData,SPFieldName)
--        curNum = curNum + num
--        LocalDataManager:EncryptField(self.m_FCData,SPFieldName,curNum)
--    end
--end

---获取比赛充能的统一接口
function FootballClubModel:GetMatchChange(leagueData)
    if leagueData then
        local curNum = LocalDataManager:DecryptField(leagueData, MatchChanceFieldName)
        return curNum
    end
    return 0
end

---设置比赛机会的统一接口
function FootballClubModel:SetMatchChance(leagueData, num)
    if leagueData then
        LocalDataManager:EncryptField(leagueData,MatchChanceFieldName,num)
    end
end