local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local TimerMgr = GameTimeManager
local FCStadiumUI = GameTableDefine.FCStadiumUI
local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubScene = GameTableDefine.FootballClubScene
local FootballClubController = GameTableDefine.FootballClubController
local ResourceManger = GameTableDefine.ResourceManger
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local FCStadiumUIView = Class("FCStadiumUIView", UIView)

function FCStadiumUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCStadiumUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()

        self:DestroyModeUIObject()
    end)
    FCStadiumUI:RefreshUIModel()
    local model = FCStadiumUI:GetUIModel()
    local FCState = FootballClubModel:GetCurrentState()
    local infoPanelGo = self:GetGo("RootPanel/infoPanel")
    local matchPanelGo = self:GetGo("RootPanel/matchPanel")
    local normalGo = self:GetGo("RootPanel/matchPanel/info_area/normal")    
    local matchGo = self:GetGo("RootPanel/matchPanel/info_area/match")
    local income = self:GetGo("RootPanel/matchPanel/info_area/income")

    ---------------------------infoPanel------------------------------
    self:SetButtonClickHandler(self:GetComp("RootPanel/infoPanel/upgrade_area/info/btn/btn","Button"), function()
        if FCState == FootballClubModel.EFCState.GameSettlement then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_3"))
            return
        end
        ResourceManger:SpendLocalMoney(model.nextLevelStadiumCfg.upgradeCash, nil, function(success)
            if success then
                FootballClubModel:RoomUpgrade(FCStadiumUI.ROOM_NUM, function(success)
                    if success then
                        FCStadiumUI:RefreshUIModel()
                        self:OnEnter()  
                    end                  
                end)
                GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 1, amount_new = tonumber(model.nextLevelStadiumCfg.upgradeCash) or 0, position = "["..tostring(10002).."]号俱乐部建筑事件"})        
            end                    
        end)     

    end)
    local canUpgrade = FCStadiumUI:GetCanUpgrade()
    self:GetGo("RootPanel/tab/page_2/point"):SetActive(not canUpgrade)

    self:GetGo(infoPanelGo,"upgrade_area/info/btn/req"):SetActive(canUpgrade == FCStadiumUI.ECanNotUpgradeReason.NoReq)
    self:GetGo(infoPanelGo,"upgrade_area/info/btn/dissabled"):SetActive(canUpgrade == FCStadiumUI.ECanNotUpgradeReason.NoMoney)
    self:GetGo(infoPanelGo,"upgrade_area/info/btn/max"):SetActive(canUpgrade == FCStadiumUI.ECanNotUpgradeReason.IsMax)
    if model.nextLevelStadiumCfg then
        --升级按钮中需要改变的UI 
        self:SetText(infoPanelGo,"upgrade_area/info/btn/btn/price/num",Tools:SeparateNumberWithComma(model.nextLevelStadiumCfg.upgradeCash))
        self:SetText(infoPanelGo,"upgrade_area/info/btn/dissabled/price/num",Tools:SeparateNumberWithComma(model.nextLevelStadiumCfg.upgradeCash))
        local leagueCfg = model.leagueConfig[model.nextLevelStadiumCfg.upgradeLeague]
        self:SetSprite(self:GetComp(infoPanelGo,"upgrade_area/info/btn/req/price/icon","Image"),"UI_Common",leagueCfg.iconUI)
    end
    self:SetText(infoPanelGo ,"upgrade_area/info/level/bg/num", model.LV)
    
    self:SetText(infoPanelGo ,"income_area/seat/effect/num/num", Tools:SeparateNumberWithComma(model.currCapacity))
    self:GetGo(infoPanelGo,"income_area/seat/upgrade"):SetActive(model.nextCapacity)
    self:GetGo(infoPanelGo ,"income_area/seat/effect/num/add"):SetActive(model.nextCapacity)
    if model.nextCapacity then
        self:SetText(infoPanelGo ,"income_area/seat/upgrade/lv/num", model.nextCapacityLevel)
        self:SetText(infoPanelGo ,"income_area/seat/effect/num/add", "+"..Tools:SeparateNumberWithComma(model.nextCapacity - model.stadiumCfg.seat))
    end

    self:SetText(infoPanelGo ,"income_area/tickets/effect/num/num", Tools:SeparateNumberWithComma(model.currUnitPrice))
    self:GetGo(infoPanelGo,"income_area/tickets/upgrade"):SetActive(model.nextUnitPrice)
    self:GetGo(infoPanelGo,"income_area/tickets/effect/num/add"):SetActive(model.nextUnitPrice)
    self:GetGo(infoPanelGo,"income_area/tickets/effect/num/txt"):SetActive(model.nextUnitPrice)
    if model.nextUnitPrice then
        self:SetText(infoPanelGo ,"income_area/tickets/upgrade/lv/num", model.nextUnitPriceLevel)
        self:SetText(infoPanelGo ,"income_area/tickets/effect/num/add", Tools:SeparateNumberWithComma(model.nextUnitPrice - model.stadiumCfg.ticket))    
    end
    self:SetText(infoPanelGo,"income_area/tickets/name/tips/popup/league", GameTextLoader:ReadText(model.leagueConfig[model.currLeague].name))
    self:SetText(infoPanelGo,"income_area/tickets/name/tips/popup/num", Tools:SeparateNumberWithComma(model.leagueConfig[model.currLeague].ticket))
    
    ---------------------------normal------------------------------    

    if FCState ~= FootballClubModel.EFCState.InTheGame and model.FCState ~= FootballClubModel.EFCState.GameSettlement  then
        normalGo:SetActive(true)
        matchGo:SetActive(false)
        income:SetActive(false)
        self:SetButtonClickHandler(self:GetComp("RootPanel/matchPanel/info_area/normal/bg/title","Button"), function()
            --打开联赛界面
            GameTableDefine.FCLeagueRankUI:ShowRankList()
            self:DestroyModeUIObject()
        end)
        self:SetButtonClickHandler(self:GetComp("RootPanel/matchPanel/info_area/normal/btn","Button"), function()
            --开始比赛
            FCStadiumUI:StartTheGame(model)
        end)
        self:SetText("RootPanel/matchPanel/info_area/normal/btn/disabled/num/num2",model.matchChanceLimit)
        self:SetSprite(self:GetComp(normalGo,"bg/title/league","Image"),"UI_Common",model.leagueConfig[model.currLeague].icon)
        self:SetText(normalGo,"bg/title/txt/num/num1",model.frequency)
        self:SetText(normalGo,"bg/title/txt/num/num2",model.totalFrequency)
        self:SetText(normalGo, "bg/info/player/board/name", model.playerTeamName)
        self:SetText(normalGo, "bg/info/enemy/board/name", GameTextLoader:ReadText(model.enemyTeam.cfg.name))
        self:GetGo("RootPanel/matchPanel/info_area/normal/btn/disabled"):SetActive(model.matchChance < 1)
        self:SetSprite(self:GetComp(normalGo,"bg/info/player/bg","Image"),"UI_Common",model.playerTeam.cfg.iconBG)
        self:SetSprite(self:GetComp(normalGo,"bg/info/player/bg/icon","Image"),"UI_Common",model.playerTeam.cfg.icon)
        self:SetSprite(self:GetComp(normalGo,"bg/info/enemy/bg","Image"),"UI_Common",model.enemyTeam.cfg.iconBG)
        self:SetSprite(self:GetComp(normalGo,"bg/info/enemy/bg/icon","Image"),"UI_Common",model.enemyTeam.cfg.icon)
        self:SetText(normalGo,"bg/info/player/value/num/num", math.floor( model.playerTeam.synthesize))
        self:SetText(normalGo,"bg/info/enemy/value/num/num", math.floor(model.enemyTeam.synthesize))
        self:SetText("RootPanel/matchPanel/info_area/normal/reward/num/num",Tools:SeparateNumberWithComma(model.ticketIncome))
        self:SetText(normalGo,"btn/num/num1",model.matchChance)
        self:SetText(normalGo,"btn/num/num2",model.stadiumCfg.matchLimit)
    end
   
    ---------------------------InGame------------------------------


    ---------------------------GameSettlement------------------------------
    if FCState == FootballClubModel.EFCState.GameSettlement then
        normalGo:SetActive(false)
        matchGo:SetActive(false)
        income:SetActive(true)
        self:SetButtonClickHandler(self:GetComp("RootPanel/matchPanel/info_area/income/bg/title","Button"), function()
              --打开联赛界面
              GameTableDefine.FCLeagueRankUI:ShowRankList()
            self:DestroyModeUIObject()
        end)
        --比赛结算
        self:SetButtonClickHandler(self:GetComp("RootPanel/matchPanel/info_area/income/btn","Button"),function()
            FCStadiumUI:FinishMatch()
        end)
        --赛季结算
        self:SetButtonClickHandler(self:GetComp("RootPanel/matchPanel/info_area/income/end_btn","Button"),function()
            FCStadiumUI:FinishMatch()
            --跳转页面
            GameTableDefine.FCSettlementUI:GetView()
        end)

        self:GetGo("RootPanel/matchPanel/info_area/income/end_btn"):SetActive(model.frequency >= model.totalFrequency)
        self:SetSprite(self:GetComp(income,"bg/title/league","Image"),"UI_Common",model.leagueConfig[model.currLeague].icon)
        self:SetText(income,"bg/title/txt/num/num1",model.frequency)
        self:SetText(income,"bg/title/txt/num/num2",model.totalFrequency)
        local gameState = FootballClubModel:GetPlayerGameData()
        self:SetText("RootPanel/matchPanel/info_area/income/bg/banner/player",model.playerTeamName)
        self:SetText("RootPanel/matchPanel/info_area/income/bg/banner/enemy",GameTextLoader:ReadText(model.enemyTeam.cfg.name))

        self:SetImageSprite("RootPanel/matchPanel/info_area/income/bg/info/player/bg",model.playerTeam.cfg.iconBG)
        self:SetImageSprite("RootPanel/matchPanel/info_area/income/bg/info/player/bg/icon",model.playerTeam.cfg.icon)
        self:SetImageSprite("RootPanel/matchPanel/info_area/income/bg/info/enemy/bg",model.enemyTeam.cfg.iconBG)
        self:SetImageSprite("RootPanel/matchPanel/info_area/income/bg/info/enemy/bg/icon",model.enemyTeam.cfg.icon)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/player/bg/result/win"):SetActive(gameState.playerScore > gameState.enemyScore)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/player/bg/result/lose"):SetActive(gameState.playerScore < gameState.enemyScore)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/player/bg/result/draw"):SetActive(gameState.playerScore == gameState.enemyScore)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/enemy/bg/result/win"):SetActive(gameState.playerScore < gameState.enemyScore)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/enemy/bg/result/lose"):SetActive(gameState.playerScore > gameState.enemyScore)
        self:GetGo("RootPanel/matchPanel/info_area/income/bg/info/enemy/bg/result/draw"):SetActive(gameState.playerScore == gameState.enemyScore)
        self:SetText("RootPanel/matchPanel/info_area/income/bg/info/match/player/txt",gameState.playerScore)
        self:SetText("RootPanel/matchPanel/info_area/income/bg/info/match/enemy/txt",gameState.enemyScore)
        local rankingChange = FCStadiumUI:GetRankingChange()
        self:SetText("RootPanel/matchPanel/info_area/income/income_area/rank/num/num",math.abs(rankingChange))
        self:GetGo("RootPanel/matchPanel/info_area/income/income_area/rank/num/up"):SetActive(rankingChange >= 0)
        self:GetGo("RootPanel/matchPanel/info_area/income/income_area/rank/num/down"):SetActive(rankingChange < 0)
        if gameState.playerScore > gameState.enemyScore then
            --self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/txt","+")
            self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/num",3)

        elseif gameState.playerScore == gameState.enemyScore then
            --self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/txt","+")
            self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/num",1)
        else
            --self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/txt","+")
            self:SetText("RootPanel/matchPanel/info_area/income/income_area/point/num/num",0)
        end
        self:SetText("RootPanel/matchPanel/info_area/income/income_area/income/num/txt/num",Tools:SeparateNumberWithComma(model.currUnitPrice * model.currCapacity))
    end
end


--进行比赛
function FCStadiumUIView:PlayTheGame(model)
    local matchData = FootballClubModel:GetMatchData()
    local matchGo = self:GetGo("RootPanel/matchPanel/match")
    self:GetGo(matchGo, "play/1"):SetActive(false)
    local slider = self:GetComp(matchGo, "play/2/imitate/Slider", "Slider")
    local currTimePos = 0
    local playerScore = 0
    local enemyScore = 0
    self.currState = {}    
    self:CreateTimer(1000, function()        
        currTimePos = TimerMgr:GetCurrentServerTime(true) - matchData.lastStarTime - 2
        if currTimePos < 0 then return end
        if currTimePos < model.totalDuration then
            self.currState = FootballClubModel:GetTheGameReportByTimePos(model.playerTeam, model.enemyTeam, currTimePos, self.currState)          
            self:SetText(matchGo, "info/battle/score/player", self.currState.playerScore)
            self:SetText(matchGo, "info/battle/score/enemy", self.currState.enemyScore)                     
            self:SetText(matchGo, "info/battle/time/num", TimerMgr:FormatTimeLength(model.totalDuration - currTimePos))
            slider.value = (self.currState.focusPosition - 1) * 0.25            
            self.m_list:UpdateData()
            self.m_list:ScrollTo(#self.currState.report or 0, 3)
        else
            self:StopTimer()
            self:AttributeComparison(model)            
        end
    end ,true, false)
    self:SetListItemCountFunc(self.m_list, function()
        return #self.currState.report
    end)
    self:GetGo(matchGo, "play/2"):SetActive(true)
end


--刷新战报列表
function FCStadiumUIView:UpdateReportList(index, tran)
    index = index + 1
    local go = tran.gameObject
    self:SetText(go, "bg/txt", self.currState.report[index - 1])
    self:SetText(go, "time/num", index)
end

function FCStadiumUIView:OnExit()
	self.super:OnExit(self)
    self.currState = nil
    FootballClubController:ShowFootballClubBuildings()

    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
    GameTimer:CreateNewTimer(0.02, function()
        FootballClubScene:SetRoomOnCenter(data, true,FootballClubModel.StadiumID)
    end)
    
end

return FCStadiumUIView