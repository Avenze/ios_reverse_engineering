local UnityHelper = CS.Common.Utils.UnityHelper;
local FCTrainingGroundUI= GameTableDefine.FCTrainingGroundUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local EventManager = require("Framework.Event.Manager")
local TimerMgr = GameTimeManager
local FootballClubController = GameTableDefine.FootballClubController


FCTrainingGroundUI.ROOM_NUM = 10003
FCTrainingGroundUI.ECanNotTraining = {
    physicallyInactive = 1, --体力不足
    isBusy = 2,  --正在训练
    unChoose = 3 --未选择
}

FCTrainingGroundUI.ECanNotUpgradeReason = {
    NoMoney = 1,
    NoReq = 2,
    IsMax = 3,
}


function FCTrainingGroundUI:GetView()      
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_TRAINING_GROUND_UI, self.m_view, require("GamePlay.FootballClub.UI.FCTrainingGroundUIView"), self, self.CloseView)
    return self.m_view
end
function FCTrainingGroundUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_TRAINING_GROUND_UI)
    -- package.loaded["GamePlay.FootballClub.UI.FCTrainingGroundUIView"] = nil
    -- UnityHelper.RefreshAssets() 
    self.m_view = nil
    self.m_Model = nil
    collectgarbage("collect")
end

-------------model-------------
function FCTrainingGroundUI:GetUIModel()
    if not self.m_Model then
        local playerData = FootballClubModel:GetPlayerTeamData()
        local leagueData = FootballClubModel:GetLeagueData()
        local matchData = FootballClubModel:GetMatchData()
        local roomData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        local trainingGroundLV = roomData.LV
        local lastStarTime = roomData.lastStarTime
        local curLevelTrainingCfg , nextLevelTrainingCfg = self:GetNextLevelTraining()
        local _,_,_,selectProject = self:GetCurTrainingData()
        local curTrainingGroundCfg = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].RoomInfo[trainingGroundLV]
        local nexTrainingGroundCfg = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].RoomInfo[trainingGroundLV + 1]
        local durationInfo = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].DurationInfo
        local projectInfo = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].ProjectInfo
        local projectTypeInfo = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].projectTypeInfo
        self.m_Model = 
        {
            LV = trainingGroundLV,
            leagueData = leagueData,
            leagueConfig = ConfigMgr.config_league[FootballClubModel.m_cfg.id],
            durationInfo = durationInfo,
            projectInfo = projectInfo,
            projectTypeInfo = projectTypeInfo,
            trainingDuration = 1,
            lastStarTime = lastStarTime,
            trainingProject = selectProject,       
            curTrainingCfg = curLevelTrainingCfg,
            nextTrainingCfg = nextLevelTrainingCfg,
            trainingDurationMax = #ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].DurationInfo,
            curTrainingGroundCfg = curTrainingGroundCfg,
            nexTrainingGroundCfg = nexTrainingGroundCfg,
        }
        self.m_Model.trainingListHandler = self:TrainingListHandler()
        if nexTrainingGroundCfg then
            self.m_Model.upgradeCash = nexTrainingGroundCfg.upgradeCash
        end
    end
    return self.m_Model
end

function FCTrainingGroundUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

--检查升级是否可用
function FCTrainingGroundUI:GetCanUpgrade()
    if not self.m_Model.nextTrainingCfg then
        return self.ECanNotUpgradeReason.IsMax
    end
    local leagueData = self.m_Model.leagueData
    if self.m_Model.nexTrainingGroundCfg.upgradeLeague > leagueData.leagueLV then
        return self.ECanNotUpgradeReason.NoReq
    end
    if not ResourceManger:CheckLocalMoney( self.m_Model.nexTrainingGroundCfg.upgradeCash) then
        return self.ECanNotUpgradeReason.NoMoney
    end
    
end

--修改训练时长
function FCTrainingGroundUI:ChangeTrainingDuration(changeNum)
    local model = self:GetUIModel()
    local trainingDuration = model.trainingDuration
    if trainingDuration + changeNum > #model.durationInfo then
        model.trainingDuration = 1
    elseif trainingDuration + changeNum < 1 then
        model.trainingDuration = #model.durationInfo
    else
        model.trainingDuration = trainingDuration + changeNum
    end
    return model.trainingDuration
end

--当前选择下的消耗体力消耗
function FCTrainingGroundUI:SPCost()
    local projectCfg = self.m_Model.projectInfo[self.m_Model.trainingProject]
    local durationCfg = self.m_Model.durationInfo[self.m_Model.trainingDuration]    
    local result = 0
    if projectCfg then
        result = projectCfg.cost * tonumber(durationCfg.punish) * self.m_Model.trainingDuration
        return result
    end
    return 0
end

--是否能训练
function FCTrainingGroundUI:CanTraining()
    local FCData = FootballClubModel.m_FCData
    if not FCData or not self.m_Model then
        return false
    end

    if not self.m_Model.trainingProject then
        return false,FCTrainingGroundUI.ECanNotTraining.unChoose
    end

    local TrainingGroundData = FCData.TrainingGround
    if TrainingGroundData.trainingProject and TrainingGroundData.trainingDuration and TrainingGroundData.lastStarTime then
        if TrainingGroundData.trainingDuration * 3600 + TrainingGroundData.lastStarTime > GameTimeManager:GetCurrentServerTime(true) then
            return false,FCTrainingGroundUI.ECanNotTraining.isBusy
        end
    end

    local cost = self:SPCost()
    if cost > FootballClubModel:GetSP() then
    --if cost > FCData.SP then
        return false ,FCTrainingGroundUI.ECanNotTraining.physicallyInactive
    else
        return true
    end
end 

--开始训练
function FCTrainingGroundUI:StarTraining()
    local TrainingGroundData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
    TrainingGroundData.lastStarTime = TimerMgr:GetCurrentServerTime(true)
    TrainingGroundData.trainingProject = self.m_Model.trainingProject
    TrainingGroundData.trainingDuration = self.m_Model.trainingDuration 
    LocalDataManager:WriteToFile()
    self:RefreshUIModel()

    --埋点
    GameSDKs:TrackForeign("fbclub", {training_time_new = tonumber(TrainingGroundData.trainingDuration) or 0})

end

--获取体力的消耗速度/s
function FCTrainingGroundUI:GetTrainingSPSpendByFCData(FCData, buildingId)
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
        local durationCfg = ConfigMgr.config_training_ground[buildingId].DurationInfo[TrainingGroundData.trainingDuration]
        local reCost = -projectCfg.cost / 3600
        return reCost
    end
    return 0
end

function FCTrainingGroundUI:GetNextLevelTraining(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end

    local buildLV = FootballClubModel:GetRoomDataById(self.ROOM_NUM).LV
    if buildLV + 1 > #ConfigMgr.config_training_ground[buildingId].ProjectInfo then
        return nil ,nil
    end
    local nextLevelTrainingCfg = ConfigMgr.config_training_ground[buildingId].ProjectInfo[buildLV + 1]
    local curTrainingType = nextLevelTrainingCfg.type
    local trainingTypeList = ConfigMgr.config_training_ground[buildingId].projectTypeInfo[curTrainingType]
    local trainingCfg = nil
    if nextLevelTrainingCfg.level > 1 then
        trainingCfg = trainingTypeList[nextLevelTrainingCfg.level - 1]
    end
    return trainingCfg, nextLevelTrainingCfg
end

function FCTrainingGroundUI:GetCurTrainingData(FCData, buildingId)
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
        if TrainingGroundData.lastStarTime > curTime then
            TrainingGroundData.lastStarTime = curTime
        end
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

function FCTrainingGroundUI:SkipTraining(FCData, buildingId)
    if not FCData then
        FCData = FootballClubModel.m_FCData
    end
    if not buildingId then
        buildingId = FootballClubModel.m_cfg.id
    end
    if not FCData then
        return 
    end
    local roomData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
    if roomData.lastStarTime then
        roomData.lastStarTime = GameTimeManager:GetCurrentServerTime(true) - roomData.trainingDuration * 3600
        LocalDataManager:WriteToFile()
        self:RefreshUIModel()
    end
end

function FCTrainingGroundUI:TrainingListHandler()
    local trainingListHandler = {}
    local roomID = self.m_Model.LV
    local typeNum = 1
    for typeK,typeV in pairs(self.m_Model.projectTypeInfo) do
        local type = typeK
        for k,v in pairs(typeV) do
            if k == 1 then
                trainingListHandler[typeNum] = v
            end
            if v.unlock <= self.m_Model.LV then
                trainingListHandler[typeNum] = v
            else
                break
            end
        end
        typeNum = typeNum + 1
    end
    table.sort(trainingListHandler,function(a,b)
        return a.type < b.type
    end)
    return trainingListHandler
end
