local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FCTrainingGroundUI = GameTableDefine.FCTrainingGroundUI
local ResourceManger = GameTableDefine.ResourceManger
local FootballClubModel = GameTableDefine.FootballClubModel
local FCTrainningRewardUI = GameTableDefine.FCTrainningRewardUI
local FootballClubController = GameTableDefine.FootballClubController
local FootballClubScene = GameTableDefine.FootballClubScene


local FCTrainingGroundUIView = Class("FCTrainingGroundUIView", UIView)
local lastSelected = nil    --上次选择的


function FCTrainingGroundUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    
end
function FCTrainingGroundUIView:OnEnter()    
    self.m_Model = FCTrainingGroundUI:GetUIModel()
    self:Init()
    self:Refresh()    
end

function FCTrainingGroundUIView:Init()
    self.m_Model = FCTrainingGroundUI:GetUIModel()

    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
    --训练场升级btn
    self:SetButtonClickHandler(self:GetComp("RootPanel/TranningPanel/levelup/bg/btn/btn", "Button"), function()
        local FCState = FootballClubModel:GetCurrentState()
        if FCState == FootballClubModel.EFCState.InTraining then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_FBCLUB_TIP_1"))
            return
        end
        ResourceManger:SpendLocalMoney(self.m_Model.upgradeCash, nil, function(success)
            if success then
                FootballClubModel:RoomUpgrade(FCTrainingGroundUI.ROOM_NUM, function(success)            
                    if success then
                        lastSelected = self.m_Model.trainingProject
                        FCTrainingGroundUI:RefreshUIModel()
                        self:Refresh()
                        lastSelected = nil  --刷新完这次之后清空缓存
                    end                  
                end)
                GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 1, amount_new = tonumber(self.m_Model.upgradeCash) or 0, position = "["..tostring(10003).."]号俱乐部建筑事件"})  
            end                    
        end)               
    end)
    --训练时间-btn
    self:SetButtonClickHandler(self:GetComp("RootPanel/TranningPanel/product/time/btn1", "Button"), function()
        FCTrainingGroundUI:ChangeTrainingDuration(-1)
        self:Refresh()
    end)
    --训练时间+btn
    self:SetButtonClickHandler(self:GetComp("RootPanel/TranningPanel/product/time/btn2", "Button"), function()
        FCTrainingGroundUI:ChangeTrainingDuration(1)
        self:Refresh()
        --self:DestroyModeUIObject()
    end)
    --开始训练btn
    self:SetButtonClickHandler(self:GetComp("RootPanel/TranningPanel/product/btn", "Button"), function()
        local canSkip = ResourceManger:CheckDiamond(self.m_Model.trainingDuration)
        local spCost = FCTrainingGroundUI:SPCost() * -1
        FootballClubModel:ChangeSP(nil, spCost)  
        FCTrainingGroundUI:StarTraining()  
        self:Refresh()
    end)

    --跳过btn
    self:SetButtonClickHandler(self:GetComp("RootPanel/TranningPanel/product/btn/skip", "Button"), function()
        local idle, remain, duration = FCTrainingGroundUI:GetCurTrainingData()
        local skipHour =  math.ceil(remain/3600)
        local canSkip = ResourceManger:CheckDiamond(self.m_Model.durationInfo[skipHour].pass)
        if canSkip then
            self:DestroyModeUIObject()
            ResourceManger:SpendDiamond(self.m_Model.durationInfo[skipHour].pass, nil ,function()
                FCTrainingGroundUI:SkipTraining()
                FCTrainningRewardUI:GetView()

                 --埋点
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "跳过训练等待时间", behaviour = 2, num_new = tonumber(self.m_Model.durationInfo[skipHour].pass)})
            end)
        end

    end)


    self.m_list = self:GetComp("RootPanel/TranningPanel/product/scrollrect", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return Tools:GetTableSize(self.m_Model.projectTypeInfo)
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateTrainList))
    self:SetListItemNameFunc(self.m_list, function(index)       
        return "Item"
    end)     

    local progress = self:GetGo("RootPanel/TranningPanel/product/progress")
    local time = self:GetGo("RootPanel/TranningPanel/product/time")
    self:CreateTimer(100, function()
        local idle, remain, duration = FCTrainingGroundUI:GetCurTrainingData()
        progress:SetActive(not idle)
        time:SetActive(idle)
        if not idle then
            self:SetText("RootPanel/TranningPanel/product/progress/prog/txt",GameTimeManager:FormatTimeLength(remain))
            self:GetComp("RootPanel/TranningPanel/product/progress/prog","Slider").value = 1- remain/duration
        end

        if idle == false then
            local skipHour =  math.ceil(remain/3600)
            self:GetGo("RootPanel/TranningPanel/product/btn/skip/disabled"):SetActive(
                not ResourceManger:CheckDiamond(self.m_Model.durationInfo[skipHour].pass))
            self:SetText("RootPanel/TranningPanel/product/btn/skip/spend/num","-"..self.m_Model.durationInfo[skipHour].pass)
            self:SetText("RootPanel/TranningPanel/product/btn/skip/disabled/spend/num","-"..self.m_Model.durationInfo[skipHour].pass)
            
        end
    end,true,true)

    self.m_list:ScrollTo(self.m_Model.trainingProject and self.m_Model.trainingProject -1 or 1, 3)

end

--[[
    @desc: 
    author:{author}
    time:2023-07-14 17:51:58
    --@playFeel: 该次刷新界面是否播放feel
    @return:
]]
function FCTrainingGroundUIView:Refresh(playFeel)
    self.playFeel = playFeel
    self.m_Model = FCTrainingGroundUI:GetUIModel()
    self.m_Model.trainingProject = lastSelected or self.m_Model.trainingProject --刷新列表前设置缓存的训练项目
    self.m_list:UpdateData()

    local CanNotUpgrade = FCTrainingGroundUI:GetCanUpgrade()
    self:GetGo("RootPanel/TranningPanel/levelup/bg/btn/req"):SetActive(CanNotUpgrade and CanNotUpgrade == FCTrainingGroundUI.ECanNotUpgradeReason.NoReq)
    if self.m_Model.nexTrainingGroundCfg then
        self:SetImageSprite("RootPanel/TranningPanel/levelup/bg/btn/req/price/icon",self.m_Model.leagueConfig[self.m_Model.nexTrainingGroundCfg.upgradeLeague].iconUI)
    end
    self:GetGo("RootPanel/TranningPanel/levelup/bg/btn/dissabled"):SetActive(CanNotUpgrade and CanNotUpgrade == FCTrainingGroundUI.ECanNotUpgradeReason.NoMoney)
    self:SetText("RootPanel/TranningPanel/levelup/bg/btn/dissabled/price/num",self.m_Model.nexTrainingGroundCfg and Tools:SeparateNumberWithComma(self.m_Model.nexTrainingGroundCfg.upgradeCash) or 0)
    self:GetGo("RootPanel/TranningPanel/levelup/bg/btn/max"):SetActive(CanNotUpgrade and CanNotUpgrade == FCTrainingGroundUI.ECanNotUpgradeReason.IsMax)
    
    self:SetText("RootPanel/TranningPanel/levelup/bg/btn/btn/price/num", Tools:SeparateNumberWithComma(self.m_Model.upgradeCash or 0))
    self:SetText("RootPanel/TranningPanel/levelup/bg/level/bg/num", self.m_Model.LV)   

    self:GetGo("RootPanel/TranningPanel/levelup/bg/effect/effect1"):SetActive(self.m_Model.nextTrainingCfg)
    if self.m_Model.nextTrainingCfg then
        self:SetImageSprite("RootPanel/TranningPanel/levelup/bg/effect/effect1/icon",self.m_Model.nextTrainingCfg.icon)
        self:SetText("RootPanel/TranningPanel/levelup/bg/effect/effect1/txt",GameTextLoader:ReadText(self.m_Model.nextTrainingCfg.name))
        self:SetText("RootPanel/TranningPanel/levelup/bg/effect/effect1/level/num",self.m_Model.curTrainingCfg and self.m_Model.curTrainingCfg.levelShow or "") 
        self:SetText("RootPanel/TranningPanel/levelup/bg/effect/effect1/level/buff/txt/num",self.m_Model.nextTrainingCfg.levelShow) 
    end

    self:SetText("RootPanel/TranningPanel/product/btn/spend/num",math.ceil(FCTrainingGroundUI:SPCost()))
    self:SetText("RootPanel/TranningPanel/product/btn/disabled/spend/num",math.ceil( FCTrainingGroundUI:SPCost()))
    self:SetText("RootPanel/TranningPanel/product/time/bg/num/num",self.m_Model.trainingDuration )
    self:GetComp("RootPanel/TranningPanel/product/time/btn1","Button").interactable = self.m_Model.trainingDuration > 1
    self:GetComp("RootPanel/TranningPanel/product/time/btn2","Button").interactable = self.m_Model.trainingDuration < self.m_Model.trainingDurationMax

    local idle,remain,duration,project = FCTrainingGroundUI:GetCurTrainingData()
    self:GetGo("RootPanel/TranningPanel/product/btn/unchoose"):SetActive(not self.m_Model.trainingProject)
    local CanTraining,res = FCTrainingGroundUI:CanTraining()
    if CanTraining then
        self:GetGo("RootPanel/TranningPanel/product/btn/skip"):SetActive(false)
        self:GetGo("RootPanel/TranningPanel/product/btn/disabled"):SetActive(false)
        self:GetGo("RootPanel/TranningPanel/product/btn/unchoose"):SetActive(false)
    else
        self:GetGo("RootPanel/TranningPanel/product/btn/skip"):SetActive(res == FCTrainingGroundUI.ECanNotTraining.isBusy)
        self:GetGo("RootPanel/TranningPanel/product/btn/disabled"):SetActive(res == FCTrainingGroundUI.ECanNotTraining.physicallyInactive)
        self:GetGo("RootPanel/TranningPanel/product/btn/unchoose"):SetActive(res == FCTrainingGroundUI.ECanNotTraining.unChoose)
    end

    self.playFeel = false

end


function FCTrainingGroundUIView:UpdateTrainList(index, tran)
    index = index + 1
    local go = tran.gameObject
    local cfg = self.m_Model.trainingListHandler[index]
    if cfg.unlock > self.m_Model.LV then
        self:GetGo(go, "bg/locked"):SetActive(true)
        self:SetText(go, "bg/locked/lock_limit/num", cfg.unlock)
    else
        self:GetGo(go, "bg/locked"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp(go, "bg", "Button"), function()
            self.m_Model.lastSelected = self.m_Model.trainingProject 
            self.m_Model.trainingProject = cfg.subjectId     

            self:Refresh(true)
        end)
        if self.playFeel then
            if cfg.subjectId == self.m_Model.lastSelected then
                local feel = self:GetComp(go,"bg/chooseFB","MMFeedbacks")
                if feel then
                    feel:PlayFeedbacks()
                end
            end
            if cfg.subjectId == self.m_Model.trainingProject then
                local feel = self:GetComp(go,"bg/chooseFB","MMFeedbacks")
                if feel then
                    feel:PlayFeedbacks()
                end
            end 
        end


        self:SetText(go,"bg/name/name",GameTextLoader:ReadText(cfg.name))
        self:SetText(go,"bg/name/num",cfg.levelShow)

        self:SetSprite(self:GetComp(go,"bg/icon","Image"),"UI_Common",cfg.icon)
        self:SetText(go, "bg/buff/".."1/num", "+" .. cfg.subjectIncome[1])
        self:SetText(go, "bg/buff/".."2/num", "+" .. cfg.subjectIncome[2])
        self:SetText(go, "bg/buff/".."3/num", "+" .. cfg.subjectIncome[3])
        self:SetText(go, "bg/buff/".."4/num", "+" .. cfg.subjectIncome[4])
        
        local idle,remain,duration,project = FCTrainingGroundUI:GetCurTrainingData()
        self:GetGo(go,"bg/select"):SetActive(idle and cfg.subjectId == self.m_Model.trainingProject )
        self:GetGo(go,"bg/tranning-choose"):SetActive(not idle and cfg.subjectId == self.m_Model.trainingProject )
        self:GetGo(go,"bg/tranning-unchoose"):SetActive(not idle and  cfg.subjectId ~= self.m_Model.trainingProject )   

    end        
end   

function FCTrainingGroundUIView:OnExit()    
    self.m_Model = nil
    self.super:OnExit(self)
    FootballClubController:ShowFootballClubBuildings()

    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
    GameTimer:CreateNewTimer(0.02, function()
        FootballClubScene:SetRoomOnCenter(data, true,FootballClubModel.TrainingGroundID)
    end)
end


return FCTrainingGroundUIView
