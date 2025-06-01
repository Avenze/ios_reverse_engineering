local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local UnityHelper = CS.Common.Utils.UnityHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil

local FootballClubController = GameTableDefine.FootballClubController
local MainUI = GameTableDefine.MainUI
local FloorMode = GameTableDefine.FloorMode
local FloatUI = GameTableDefine.FloatUI
local HouseContractUI = GameTableDefine.HouseContractUI
local ResMgr = GameTableDefine.ResourceManger
local FCStadiumUI = GameTableDefine.FCStadiumUI
local FCClubCenterUI = GameTableDefine.FCClubCenterUI
local FCHealthCenterUI = GameTableDefine.FCHealthCenterUI
local FCTacticalCenterUI = GameTableDefine.FCTacticalCenterUI
local FCTrainingGroundUI = GameTableDefine.FCTrainingGroundUI
local CfgMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local ChatEventManager = GameTableDefine.ChatEventManager
local SoundEngine = GameTableDefine.SoundEngine
local GuideUI = GameTableDefine.GuideUI
local GuideManager = GameTableDefine.GuideManager
local FootballClubModel = GameTableDefine.FootballClubModel
local FCRoomUnlockUI = GameTableDefine.FCRoomUnlockUI
local FootballClubScene = GameTableDefine.FootballClubScene
local ChooseUI = GameTableDefine.ChooseUI
local FCTrainningRewardUI = GameTableDefine.FCTrainningRewardUI
local GameClockManager = GameTableDefine.GameClockManager


local footballClubConfig = CfgMgr.config_football_club[FootballClubModel.m_cfg.id]
local ClubCenterID = 10001
local StadiumID = 10002
local TrainingGroundID = 10003
local HealthCenterID = 10005
local unSignBubble = nil

--初始化
function FootballClubController:Init(sceneGo, footballClubData)
    --初始化字段
    self.sceneGo = sceneGo
    self.footballClubData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    self.m_floatUI = {}
    self.clubCenterCups = nil
    self.curFCState = nil

    self:OnEnter(sceneGo)
end

--进入时
function FootballClubController:OnEnter(sceneGo)
    FootballClubScene:SwitchNightPoint(not GameClockManager.isDay)

    --场景中的gameObject
    for k, v in pairs(footballClubConfig) do
        local buildFunction = self:GetBuildingCreateFunByName(v.objName)
        if buildFunction then
            buildFunction(self, sceneGo[v.objName], v.id)
        end
    end
    self:ShowFootballClubBuildings()
    self:RefreshCupShow()

    --新手引导
    GuideManager.currStep = 21001
    GuideManager:ConditionToStart()

    --注册事件
    EventManager:RegEvent(
        "FC_STATE_CHANGE",
        function(last, cur)
            local matchData = FootballClubModel:GetMatchData()
            if cur == FootballClubModel.EFCState.InTraining then
                self:PlayTrainingGroundFeel()
            elseif cur == FootballClubModel.EFCState.TrainingSettlement then
                self:StopTrainingGroundFeel()
                if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.FC_TRAINING_GROUND_UI) then
                    FCTrainingGroundUI:CloseView()
                    FCTrainningRewardUI:GetView()
                end
            elseif cur == FootballClubModel.EFCState.InTheGame then
                self:PlayStadiumInGameFeel()
                self.inGameSound = SoundEngine:PlayBackgroundMusic(SoundEngine.FOOTBALL_IN_GAME, true)
            elseif cur == FootballClubModel.EFCState.GameSettlement then
                if not matchData.ScoreSettlement then
                    FCStadiumUI:GetLeaguePoints()
                    matchData.ScoreSettlement = true
                end

                SoundEngine:StopAllSFX(self.inGameSound)
                self:PlayStadiumEndGameFeel()
                FootballClubScene:PlayFCBGM()
            end
            LocalDataManager:WriteToFile()
        end
    )

    --进入场景时根据当前状态进行特殊处理
    self:StateOnEnterHandle()
    --不根据当前状态检查的处理
    if self:CheckSPChageReady() then
        --self:PlaySPChargeReadyFeel()
    end

    --埋点
    GameSDKs:TrackForeign("fbclub", {enter = 1})

end

function FootballClubController:StateOnEnterHandle()
    local FCState = FootballClubModel:GetCurrentState()
    local matchData = FootballClubModel:GetMatchData()
    local teamList = FCStadiumUI:CreateTeamList()
    local totalFrequency = (#teamList - 1) * 2
    local current = GameTimeManager:GetCurrentServerTime(true)
    if FCState == FootballClubModel.EFCState.Idle then
        if matchData.frequency >= totalFrequency and matchData.gameOver then
            GameTableDefine.FCSettlementUI:GetView()
        end
    elseif FCState == FootballClubModel.EFCState.InTraining then
        self:PlayTrainingGroundFeel()
    elseif FCState == FootballClubModel.EFCState.TrainingSettlement then
        self:StopTrainingGroundFeel()
    elseif FCState == FootballClubModel.EFCState.InTheGame then
        local playerData = FootballClubModel:GetTeamDataByID(0)
        local matchData = FootballClubModel:GetMatchData()
        local enemyData = FootballClubModel:GetTeamDataByID(FCStadiumUI:GetOpponent(0, matchData.frequency))
        FootballClubModel:StartAGame(playerData, enemyData)
        self:PlayStadiumInGameFeel()
        self.inGameSound = SoundEngine:PlaySFX(SoundEngine.FOOTBALL_IN_GAME)
    elseif FCState == FootballClubModel.EFCState.GameSettlement then
        if not matchData.ScoreSettlement then
            FCStadiumUI:GetLeaguePoints()
            matchData.ScoreSettlement = true
        end
        self:PlayStadiumEndGameFeel()
    elseif FCState == FootballClubModel.EFCState.Unsigned then
        self:ShowToBeSignedBubble(true)
    end
    return false
end

--退出时
function FootballClubController:OnExit()
end

--通过名字选择场景中建筑初始化方法
function FootballClubController:GetBuildingCreateFunByName(name)
    local funName = name .. "Create"
    funName = funName:gsub("^%l", string.upper)
    return self[funName]
end

--设置场景按钮
function FootballClubController:SetSceneButtonClickHandler(go, cb)
    FloorMode:GetScene():SetButtonClickHandler(go, cb)
end

--将视角移动到指定gameObject
function FootballClubController:LookAtWorkShop(go)
    local UIPosition = FloorMode:GetScene():GetGo(go, "UIPosition")
    FloorMode:GetScene():LocatePosition(UIPosition.transform.position, true)
end

--播放进入房间的音乐
function FootballClubController:PlayRoomSound(soundPath)
    SoundEngine:PlaySFX(soundPath)
end

--生成悬浮图标
function FootballClubController:CreateFloatUI(id, go, funcName, dis, ...)
    if not self.m_floatUI[id] then
        self.m_floatUI[id] = {}
        self.m_floatUI[id].go = go
        local arg = {...}
        FloatUI:SetObjectCrossCamera(
            self.m_floatUI[id],
            function(view)
                if view then
                    view:Invoke(funcName, arg)
                end
            end,
            nil,
            dis or 0
        )
    else
        if self.m_floatUI[id].view then
            local arg = {...}
            self.m_floatUI[id].view:Invoke(funcName, arg)
        end
    end
end

--销毁悬浮图标
function FootballClubController:DestoryFloatUI(id)
    if self.m_floatUI[id] then
        FloatUI:RemoveObjectCrossCamera(self.m_floatUI[id])
        self.m_floatUI[id] = nil
    end
end

--显示俱乐部建筑
function FootballClubController:ShowFootballClubBuildings()
    for k, v in pairs(footballClubConfig) do
        local roomName = v.objName
        local roomData = FootballClubModel:GetRoomDataById(v.id)
        if roomData.state == 0 then
            self.sceneGo[roomName].model:SetActive(false)
            local show = true
            if v.unlockRoom then
                local unlockRoomData = FootballClubModel:GetRoomDataById(v.unlockRoom)
                if not unlockRoomData or unlockRoomData.state ~= 2 then
                    show = false
                end
            end
            self.sceneGo[roomName].roomBox:SetActive(show)
            self.sceneGo[roomName].UIPosition:SetActive(true)
            FootballClubScene:GetGo(self.sceneGo[roomName].UIPosition, "unlockable_btn"):SetActive(show)
        elseif roomData.state == 1 then
            --显示建造悬浮图标
            local buildCfg = v
            local waitTime = roomData.startTime + v.unlockTime
            self:CreateFloatUI(v.id, self.sceneGo[roomName].root, "ShowFootballBuildingUnlockButton", nil, buildCfg, waitTime)

            self.sceneGo[roomName].model:SetActive(false)
            self.sceneGo[roomName].roomBox:SetActive(false)
            self.sceneGo[roomName].UIPosition:SetActive(true)
            FootballClubScene:GetGo(self.sceneGo[roomName].UIPosition, "unlockable_btn"):SetActive(false)
        elseif roomData.state == 2 then
            if v.id == ClubCenterID then --管理中心
                if not self.footballClubData.activation then
                    self:ShowToBeSignedBubble(true)
                else
                    self:ShowToBeSignedBubble(false)
                end
            end
            if self.footballClubData.activation and v.id == HealthCenterID then --医疗中心
                self:ShowHealthCenterBubble(true)
            end
            if self.footballClubData.activation and v.id == TrainingGroundID then --训练场
                self:ShowTrainingCenterBubble(true)
            end
            if self.footballClubData.activation and v.id == StadiumID then --球场
                self:ShowStadiumBubble(true)
            end
            self.sceneGo[roomName].model:SetActive(true)
            self.sceneGo[roomName].roomBox:SetActive(true)
            self.sceneGo[roomName].UIPosition:SetActive(true)
            FootballClubScene:GetGo(self.sceneGo[roomName].UIPosition, "unlockable_btn"):SetActive(false)
        end
    end
end

function FootballClubController:BuyRoomFinished(roomID)
    self:DestoryFloatUI(roomID)
    local roomData = FootballClubModel:GetRoomDataById(roomID)
    roomData.state = 2
    local now = GameTimeManager:GetCurrentServerTime(true)
    local cd = CfgMgr.config_health_center[FootballClubModel.m_cfg.id][roomData.LV].cd * 3600
    roomData.useTime = now - cd * 0.8
    LocalDataManager:WriteToFile()

    self:ShowFootballClubBuildings()
    local feel = FootballClubScene:GetComp(self.sceneGo[footballClubConfig[roomID].objName].buildingFB, "buildFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

function FootballClubController:PlayRoomUpgradeFB(roomID)
    local feel = FootballClubScene:GetComp(self.sceneGo[footballClubConfig[roomID].objName].buildingFB, "upgradeFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--刷新管理中心模型的奖杯
function FootballClubController:RefreshCupShow()
    if not self.clubCenterCups or next(self.clubCenterCups) == nil then
        self.clubCenterCups = {}
        local count = Tools:GetTableSize(CfgMgr.config_league[FootballClubModel.m_cfg.id])
        for i = 1, count do
            self.clubCenterCups[i] = FootballClubScene:GetGo(self.sceneGo["ClubCenter"].model, "Club_Center_cup_0" .. i)
        end
    end
    local leagueData = FootballClubModel:GetLeagueData()
    for i = 1, Tools:GetTableSize(self.clubCenterCups) do
        self.clubCenterCups[i]:SetActive(leagueData.leagueLV == i)
    end
end

--显示待签约气泡
function FootballClubController:ShowToBeSignedBubble(Active)
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local roomCfg = footballClubConfig[ClubCenterID]
    local roomName = roomCfg.objName
    local roomData = FCData[roomName]
    if not unSignBubble or unSignBubble:IsNull() then
        local roomPath = "Assets/Res/UI/FCContractUI.prefab"
        self.loadingSignedActive = Active
        if not self.loadingSigned then
            self.loadingSigned = true
            GameResMgr:AInstantiateObjectAsyncManual(
                roomPath,
                self,
                function(this)
                    unSignBubble = this
                    UnityHelper.AddChildToParent(self.sceneGo[roomName].UIPosition.transform, unSignBubble.transform)
                    unSignBubble:SetActive(self.loadingSignedActive)
                    --添加点击事件
                    self:SetSceneButtonClickHandler(
                        --FootballClubScene:GetGo(unSignBubble,"Icon/Pad"),
                        unSignBubble,
                        function()
                            self:ClickClubCenter(self.sceneGo[roomName].root, roomCfg.id, roomData)
                        end
                    )
                end
            )
        end
    else
        unSignBubble:SetActive(Active)
    end
end


--显示球馆气泡
function FootballClubController:ShowStadiumBubble(Active)
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local roomCfg = footballClubConfig[StadiumID]
    local roomName = roomCfg.objName
    local roomData = FCData[roomName]
    if FCData.activation then
        self:CreateFloatUI(StadiumID, self.sceneGo[roomName].root, "ShowFCStadiumBubble", "model/Football_Field_01/Football_Field_01", Active)
    end
end

--显示训练中心气泡
function FootballClubController:ShowTrainingCenterBubble(Active)
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local roomCfg = footballClubConfig[TrainingGroundID]
    local roomName = roomCfg.objName
    local roomData = FCData[roomName]
    if FCData.activation then
        self:CreateFloatUI(TrainingGroundID, self.sceneGo[roomName].root, "ShowFCTrainingCenterBubble", "model/Training_course", Active)
    end
end

--显示医疗中心气泡
function FootballClubController:ShowHealthCenterBubble(Active)
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local roomCfg = footballClubConfig[HealthCenterID]
    local roomName = roomCfg.objName
    local roomData = FCData[roomName]
    if FCData.activation then
        self:CreateFloatUI(HealthCenterID, self.sceneGo[roomName].root, "ShowFCHealthCenterBubble", "model/Health_Center_Room/Health_Center_Room", Active)
    end
end

--播放训练场动效
function FootballClubController:PlayTrainingGroundFeel()
    local roomCfg = footballClubConfig[TrainingGroundID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB

    local feel = FootballClubScene:GetComp(buildingFB, "trainingFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--停止播放训练场动效
function FootballClubController:StopTrainingGroundFeel()
    local roomCfg = footballClubConfig[TrainingGroundID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB

    if self.stopTimer then
        GameTimer:StopTimer(self.stopTimer)
        self.stopTimer = nil
    end
    self.stopTimer = GameTimer:CreateNewTimer(1,function()
        local feel = FootballClubScene:GetComp(buildingFB, "training_finishFB", "MMFeedbacks")
        if feel then
            feel:ResetFeedbacks()
            feel:PlayFeedbacks()
        end
    
        local model = self.sceneGo[roomName].model
        --K125 退出场景时调用的话 时可能报错导致无法继续游戏,所以加个容错.
        local traniningItems = FootballClubScene:GetGoOrNil(model, "traniningItems")
        if traniningItems then
            traniningItems:SetActive(false)
        end
    end)

end

--检查体力恢复是否充能完毕
function FootballClubController:CheckSPChageReady()
    local healthCenterData = FootballClubModel:GetRoomDataById(HealthCenterID)
    local needTime = CfgMgr.config_health_center[FootballClubModel.m_cfg.id][healthCenterData.LV].strength * 3600
    local now = GameTimeManager:GetCurrentServerTime()
    if healthCenterData.useTime and healthCenterData.useTime + needTime <= now then
        return true
    else
        return false
    end
end

--播放医疗中心充能完毕动效
function FootballClubController:PlaySPChargeReadyFeel()
    local roomCfg = footballClubConfig[HealthCenterID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB
    local feel = FootballClubScene:GetComp(buildingFB, "readyFB", "MMFeedbacks")
    if feel then
        self.SPRead = true
        feel:PlayFeedbacks()
    end

end

--播放医疗中心使用充能动效
function FootballClubController:PlayUseSPChargeFeel()
    local roomCfg = footballClubConfig[HealthCenterID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB
    local feel = FootballClubScene:GetComp(buildingFB, "useFB", "MMFeedbacks")
    if feel then
        self.SPRead = false
        feel:PlayFeedbacks()
    end
end

--播放球馆开始比赛动效
function FootballClubController:PlayStadiumInGameFeel()
    local roomCfg = footballClubConfig[StadiumID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB
    local feel = FootballClubScene:GetComp(buildingFB, "beginFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--播放球馆进球动效
function FootballClubController:PlayStadiumGoalFeel()
    local roomCfg = footballClubConfig[StadiumID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB
    local feel = FootballClubScene:GetComp(buildingFB, "goalFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--播放球馆结束比赛动效
function FootballClubController:PlayStadiumEndGameFeel()
    local roomCfg = footballClubConfig[StadiumID]
    local roomName = roomCfg.objName
    local buildingFB = self.sceneGo[roomName].buildingFB
    local feel = FootballClubScene:GetComp(buildingFB, "endFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--根据状态改变情况判断是否哦可以播放建筑起泡动画
function FootballClubController:CheckPlayFeelOnStateChange()
    if FootballClubModel.curFCState == self.curFCState then
        return false
    else
        self.curFCState = FootballClubModel.curFCState
        return true
    end
end

----------------------------建筑方法------------------------------
function FootballClubController:ClubCenterCreate(go, id) --管理中心
    local roomData = FootballClubModel:GetRoomDataById(id)
    self:SetSceneButtonClickHandler(
        go.roomBox,
        function()
            self:ClickClubCenter(go.root, id, roomData)
        end
    )
end

function FootballClubController:ClickClubCenter(go, id, roomDataArg)
    local roomData = roomDataArg or FootballClubModel:GetRoomDataById(id)
    self:LookAtWorkShop(go)
    if roomData.state == 0 then
        FCRoomUnlockUI:Show(id, go)
    elseif roomData.state == 2 then
        FootballClubController:ShowToBeSignedBubble(false)
        FCClubCenterUI:GetView()
    end
end

function FootballClubController:StadiumCreate(go, id) --运动场
    local roomData = FootballClubModel:GetRoomDataById(id)

    self:SetSceneButtonClickHandler(
        go.roomBox,
        function()
            self:ClickStadium(go.root, id, roomData)
        end
    )
end

function FootballClubController:ClickStadium(go, id, roomDataArg)
    local roomData = roomDataArg or FootballClubModel:GetRoomDataById(id)

    self:LookAtWorkShop(go)
    if roomData.state == 0 then
        FCRoomUnlockUI:Show(id, go)
    elseif roomData.state == 2 then
        if self:CheckHaveSigned() then
            local FCState = FootballClubModel:GetCurrentState()
            if FCState == FootballClubModel.EFCState.InTheGame then
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_3"))
                return
            end
            FootballClubController:ShowStadiumBubble(false)
            FCStadiumUI:GetView()
        end
    end
end

function FootballClubController:TrainingGroundCreate(go, id) --训练场
    local roomData = FootballClubModel:GetRoomDataById(id)

    self:SetSceneButtonClickHandler(
        go.roomBox,
        function()
            self:ClickTrainingGround(go.root, id, roomData)
        end
    )
end

function FootballClubController:ClickTrainingGround(go, id, roomDataArg)
    local roomData = roomDataArg or FootballClubModel:GetRoomDataById(id)

    self:LookAtWorkShop(go)
    if roomData.state == 0 then
        FCRoomUnlockUI:Show(id, go)
    elseif roomData.state == 2 then
        --UI
        local FCState = FootballClubModel:GetCurrentState()
        if FCState == FootballClubModel.EFCState.InTheGame or FCState == FootballClubModel.EFCState.GameSettlement then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_3"))
            return
        end
        if FCState == FootballClubModel.EFCState.TrainingSettlement then
            FCTrainningRewardUI:GetView()
        else
            if self:CheckHaveSigned() then
                FCTrainingGroundUI:GetView()
                self:ShowTrainingCenterBubble(false)
            end
        end
    end
end

function FootballClubController:HealthCenterCreate(go, id) --健康中心
    local roomData = FootballClubModel:GetRoomDataById(id)

    self:SetSceneButtonClickHandler(
        go.roomBox,
        function()
            self:ClickHealthCenter(go.root, id, roomData)
        end
    )
end

function FootballClubController:ClickHealthCenter(go, id, roomDataArg)
    local roomData = roomDataArg or FootballClubModel:GetRoomDataById(id)

    self:LookAtWorkShop(go)
    if roomData.state == 0 then
        FCRoomUnlockUI:Show(id, go)
    elseif roomData.state == 2 then
        local FCState = FootballClubModel:GetCurrentState()
        if FCState == FootballClubModel.EFCState.InTheGame or FCState == FootballClubModel.EFCState.GameSettlement then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_3"))
            return
        end
        if self:CheckHaveSigned() then
            FCHealthCenterUI:GetView()
            self:ShowHealthCenterBubble(false)
        end
    end
end

function FootballClubController:TacticalCenterCreate(go, id) --战术中心
    local roomData = FootballClubModel:GetRoomDataById(id)

    self:SetSceneButtonClickHandler(
        go.roomBox,
        function()
            self:ClickTacticalCenter()
        end
    )
end

function FootballClubController:ClickTacticalCenter(go, id, roomDataArg)
    local roomData = roomDataArg or FootballClubModel:GetRoomDataById(id)

    self:LookAtWorkShop(go)
    if roomData.state == 0 then
        FCRoomUnlockUI:Show(id, go)
    elseif roomData.state == 2 then
        if self:CheckHaveSigned() then
            FCTacticalCenterUI:GetView()
        end
    end
end

--检查是否签约
function FootballClubController:CheckHaveSigned()
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    if FCData and FCData.activation then
        return true
    end
    ChooseUI:CommonChoose(
        GameTextLoader:ReadText("TXT_FBCLUB_101_10_DESC"),
        function()
            self:ClickClubCenter(self.sceneGo["ClubCenter"].root, ClubCenterID)
        end,
        false,
        function()
        end,
        GameTextLoader:ReadText("TXT_FBCLUB_101_9_DESC")
    )
    return false
end
-------------------------------------------------------------------

return FootballClubController
