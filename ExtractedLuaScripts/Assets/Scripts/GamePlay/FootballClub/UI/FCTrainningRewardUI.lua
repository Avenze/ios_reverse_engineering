local FCTrainningRewardUI= GameTableDefine.FCTrainningRewardUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local TimerMgr = GameTimeManager
local UnityHelper = CS.Common.Utils.UnityHelper;
local FootballClubController = GameTableDefine.FootballClubController


FCTrainningRewardUI.ROOM_NUM = 10003


function FCTrainningRewardUI:GetView()      
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_TRAINING_REWARD_UI, self.m_view, require("GamePlay.FootballClub.UI.FCTrainningRewardUIView"), self, self.CloseView)
    return self.m_view
end
function FCTrainningRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_TRAINING_REWARD_UI)
    self.m_view = nil
    self.m_Model = nil
    collectgarbage("collect")
end

-------------model-------------
function FCTrainningRewardUI:GetUIModel()
    if not self.m_Model then
        local clubData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        local playerData = FootballClubModel:GetPlayerTeamData()
        local leagueData = FootballClubModel:GetLeagueData()
        local matchData = FootballClubModel:GetMatchData()
        local roomData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        local trainingGroundLV = roomData.LV
        local trainingDuration = roomData.trainingDuration
        local trainingProject = roomData.trainingProject
        local curTrainingGroundCfg = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].RoomInfo[trainingGroundLV]
        local nexTrainingGroundCfg = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].RoomInfo[trainingGroundLV + 1]
        local durationInfo = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].DurationInfo
        local projectInfo = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].ProjectInfo
        local teamData = FootballClubModel:GetTeamDataByID()
        local qualityLimit = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][clubData.LV].qualityLimit
        local strengthLimit = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][clubData.LV].strengthLimit
        local attrAddValue = self:GetTrainingRewardValue()
        local strengthCost = trainingDuration * projectInfo[trainingProject].cost *durationInfo[trainingDuration].punish
        local synthesizeAfterTraining = self:GetSynthesizeAfterTraining(leagueData,teamData.atk+ attrAddValue.atk, teamData.def+attrAddValue.def, teamData.ogz + attrAddValue.ogz)

        self.m_Model = 
        {
            LV = clubData.LV,
            SP = FootballClubModel:GetSP(),
            --SP = clubData.SP,
            SPlimit = clubData.SPlimit,
            roomLV = trainingGroundLV,
            durationInfo = durationInfo,
            projectInfo = projectInfo,
            trainingCfg = projectInfo[trainingProject],
            trainingDuration = trainingDuration, 
            trainingDurationMax = #ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].DurationInfo,
            strengthCost = strengthCost,

            abilityValue = teamData.synthesize,
            atk = teamData.atk,
            def = teamData.def,
            org = teamData.ogz,

            atkAdd = attrAddValue.atk,
            defAdd = attrAddValue.def,
            orgAdd = attrAddValue.ogz,
            SPlimitAdd = attrAddValue.strength,
            
            qualityLimit = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][clubData.LV].qualityLimit,
            strengthLimit = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][clubData.LV].strengthLimit,

            synthesize = synthesizeAfterTraining,
        }
        if nexTrainingGroundCfg then
            self.m_Model.upgradeCash = nexTrainingGroundCfg.upgradeCash
        end

    end
    return self.m_Model
end

function FCTrainningRewardUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

function FCTrainningRewardUI:GetCurLevelTraining(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end

    local buildLV = FCData.LV
    local trainingCfg = ConfigMgr.config_training_ground[buildingId].ProjectInfo[buildLV]
    local curTrainingType = trainingCfg.type
    local trainingTypeList = ConfigMgr.config_training_ground[buildingId].projectTypeInfo[curTrainingType]
    local nextLevelTrainingCfg = nil
    if trainingCfg.level < #trainingTypeList then
        nextLevelTrainingCfg = ConfigMgr.config_training_ground[buildingId].projectTypeInfo[curTrainingType][trainingCfg.level + 1]
    end
    return trainingCfg, nextLevelTrainingCfg
end

function FCTrainningRewardUI:GetCurTrainingData(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end

    local idle,remain
    local TrainingGroundData = FCData.TrainingGround
    local curTime = GameTimeManager:GetCurrentServerTime(true)

    if TrainingGroundData and TrainingGroundData.lastStarTime and TrainingGroundData.trainingDuration then
        if TrainingGroundData.lastStarTime + TrainingGroundData.trainingDuration * 3600 <= curTime then
            return true,0,0,nil
        else
            return false,TrainingGroundData.lastStarTime + TrainingGroundData.trainingDuration* 3600 - curTime,
            TrainingGroundData.trainingDuration* 3600,TrainingGroundData.trainingProject
        end
    else
        return true,0,0,nil
    end
end

--获得训练实际加成的数值
function FCTrainningRewardUI:GetTrainingRewardValue(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end
    local addValue = {}
    local TrainingGroundData = FCData.TrainingGround
    local qualityLimit = ConfigMgr.config_club_data[buildingId][FCData.LV].qualityLimit
    local strengthLimit = ConfigMgr.config_club_data[buildingId][FCData.LV].strengthLimit
    if TrainingGroundData.trainingProject and TrainingGroundData.trainingDuration then
        local playerTeam = FCData.playerTeam
        local projectCfg = ConfigMgr.config_training_ground[buildingId].ProjectInfo[TrainingGroundData.trainingProject]

        addValue.atk = projectCfg.subjectIncome[1] * TrainingGroundData.trainingDuration
        if qualityLimit < playerTeam.atk + projectCfg.subjectIncome[1] * TrainingGroundData.trainingDuration then
            addValue.atk = qualityLimit - playerTeam.atk
        end
        addValue.def = projectCfg.subjectIncome[2] * TrainingGroundData.trainingDuration
        if qualityLimit < playerTeam.def + projectCfg.subjectIncome[2] * TrainingGroundData.trainingDuration then
            addValue.def =qualityLimit - playerTeam.def
        end
        addValue.ogz = projectCfg.subjectIncome[3] * TrainingGroundData.trainingDuration
        if qualityLimit < playerTeam.ogz + projectCfg.subjectIncome[3] * TrainingGroundData.trainingDuration then
            addValue.ogz = qualityLimit - playerTeam.ogz
        end
        addValue.strength = projectCfg.subjectIncome[4] * TrainingGroundData.trainingDuration
        if strengthLimit < FCData.SPlimit + projectCfg.subjectIncome[4] * TrainingGroundData.trainingDuration then
            addValue.strength = strengthLimit - FCData.SPlimit
        end

    end

    return addValue
end


--训练的加成
function FCTrainningRewardUI:TrainingReward(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end
    local TrainingGroundData = FCData.TrainingGround
    if TrainingGroundData.trainingProject and TrainingGroundData.trainingDuration then
        local playerTeam = FCData.playerTeam
        local projectCfg = ConfigMgr.config_training_ground[buildingId].ProjectInfo[TrainingGroundData.trainingProject]
        playerTeam.atk = playerTeam.atk + projectCfg.subjectIncome[1] * TrainingGroundData.trainingDuration
        if playerTeam.atk > self.m_Model.qualityLimit then
            playerTeam.atk = self.m_Model.qualityLimit
        end
        playerTeam.def = playerTeam.def + projectCfg.subjectIncome[2] * TrainingGroundData.trainingDuration
        if playerTeam.def > self.m_Model.qualityLimit then
            playerTeam.def = self.m_Model.qualityLimit
        end
        playerTeam.ogz = playerTeam.ogz + projectCfg.subjectIncome[3] * TrainingGroundData.trainingDuration
        if playerTeam.ogz > self.m_Model.qualityLimit then
            playerTeam.ogz = self.m_Model.qualityLimit
        end
        FootballClubModel:ChangeSPLimit(FCData, projectCfg.subjectIncome[4] * TrainingGroundData.trainingDuration)
        LocalDataManager:WriteToFile()
    end
    self:EndTraining(FCData)

    --埋点
    GameSDKs:TrackForeign("fbclub", {ability_value_new = tonumber(self.m_Model.synthesize) or 0})
end


 --训练结束
 function FCTrainningRewardUI:EndTraining(FCData)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not FCData then
        return 
    end
    local TrainingGroundData = FCData.TrainingGround
    TrainingGroundData.lastStarTime = nil
    TrainingGroundData.trainingProject = nil
    TrainingGroundData.trainingDuration = nil    
    LocalDataManager:WriteToFile()

end



function FCTrainningRewardUI:GetSynthesizeAfterTraining(leagueData,atk,def,ogz )
    local leagueLV = leagueData.currLeagueLV
    local weight = ConfigMgr.config_league[FootballClubModel.m_cfg.id ][ leagueLV ].balance
    --综合
    local synthesize = ((weight * atk) / (weight + atk)) + 
        ((weight * def) / (weight + def)) + 
        ((weight * ogz) / (weight + ogz))

    return synthesize
end