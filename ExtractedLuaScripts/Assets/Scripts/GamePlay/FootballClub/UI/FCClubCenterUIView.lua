local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FCClubCenterUI= GameTableDefine.FCClubCenterUI
local FootballClubModel = GameTableDefine.FootballClubModel
local ResMgr = GameTableDefine.ResourceManger
local FootballClubController = GameTableDefine.FootballClubController
local FootballClubScene = GameTableDefine.FootballClubScene

local FCClubCenterUIView = Class("FCClubCenterUIView", UIView)
function FCClubCenterUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCClubCenterUIView:OnEnter()
    self.m_Model = FCClubCenterUI:GetUIModel()

    self:Init()
    self:Refresh()
    local slider = self:GetComp("RootPanel/InfoPanel/ability/strength/prog","Slider")
    self:SetText("RootPanel/InfoPanel/ability/strength/txt/num",self.m_Model.SPRevert)
    self:CreateTimer(1000, function()
        slider.value = self.m_Model.SP / self.m_Model.SPlimit
        self:SetText("RootPanel/InfoPanel/ability/strength/prog/num/num", math.floor(self.m_Model.SP))
        --self:SetText("RootPanel/InfoPanel/ability/strength/prog/num/num", math.floor(FootballClubModel.m_FCData.SP))
        self:SetText("RootPanel/InfoPanel/ability/strength/prog/num/max", FootballClubModel.m_FCData.SPlimit)
    end, true, true, true)       
end

function FCClubCenterUIView:Init()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:SetText("RootPanel/InfoPanel/teaminfo/paybtn/price/num",Tools:SeparateNumberWithComma(self.m_Model.renewal))
    local payBtn = self:GetComp("RootPanel/InfoPanel/teaminfo/paybtn","Button")
    self:SetButtonClickHandler(payBtn, function()
        ResMgr:SpendLocalMoney(self.m_Model.renewal, nil, function(isEnough)
            if isEnough then
                FootballClubModel:SetFCActivation(true)
                FootballClubModel:ResetGamePoints()
                self:GetGo("RootPanel/InfoPanel/teaminfo/paybtn/paid"):SetActive(true)
                GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 1, amount_new = tonumber(self.m_Model.renewal) or 0, position = "["..tostring(10001).."]号俱乐部建筑事件"})
            end                        
        end) 
        self:Refresh()    
    end)


    self:GetGo("RootPanel/InfoPanel/teaminfo/paybtn/paid"):SetActive(FootballClubModel.m_FCData.activation)
    
    self:SetText("RootPanel/InfoPanel/teaminfo/paybtn/dissabled/price/num",Tools:SeparateNumberWithComma(self.m_Model.renewal))
    if not FootballClubModel.m_FCData.activation and not ResMgr:CheckLocalMoney(self.m_Model.renewal) then
        self:GetGo("RootPanel/InfoPanel/teaminfo/paybtn/dissabled"):SetActive(true)
    else
        self:GetGo("RootPanel/InfoPanel/teaminfo/paybtn/dissabled"):SetActive(false)
    end
    
    local btn = self:GetComp("RootPanel/InfoPanel/teaminfo/name/changeicon","Button")
    self:SetButtonClickHandler(btn, function()
        GameTableDefine.BenameUI:ReClubName(function()
            FCClubCenterUI:RefreshUIModel()
            self:Refresh()
        end)
    end)
    --self:SetSprite(self:GetComp("RootPanel/InfoPanel/teaminfo/icon", "Image"), "UI_Shop", "")
    
    local curState = FootballClubModel:GetCurrentState()
   
    self:GetGo("RootPanel/InfoPanel/ability/title/Tranning"):SetActive(curState == FootballClubModel.EFCState.InTraining 
    or curState == FootballClubModel.EFCState.TrainingSettlement)
    self:GetGo("RootPanel/InfoPanel/ability/title/Rest"):SetActive(curState == FootballClubModel.EFCState.Idle 
    or curState == FootballClubModel.EFCState.Unsigned or curState == FootballClubModel.EFCState.SeasonSettlement)
    self:GetGo("RootPanel/InfoPanel/ability/title/Match"):SetActive(curState == FootballClubModel.EFCState.InTheGame 
    or curState == FootballClubModel.EFCState.GameSettlement)

    --self:SetText("RootPanel/title/bg/level", self.m_Model.LV)

    self:SetText("RootPanel/InfoPanel/teaminfo/ability/num", math.floor(self.m_Model.synthesize))
    self:SetText("RootPanel/InfoPanel/ability/strength/txt/num", self.m_Model.SPRevert)
    
    self:SetText("RootPanel/InfoPanel/ability/value/offense/value/num", self.m_Model.atk)
    self:SetText("RootPanel/InfoPanel/ability/value/defense/value/num", self.m_Model.def)
    self:SetText("RootPanel/InfoPanel/ability/value/organizational/value/num", self.m_Model.ogz)
    self:SetText("RootPanel/InfoPanel/ability/value/offense/value/limit", self.m_Model.limit)
    self:SetText("RootPanel/InfoPanel/ability/value/defense/value/limit", self.m_Model.limit)
    self:SetText("RootPanel/InfoPanel/ability/value/organizational/value/limit", self.m_Model.limit)
    self:GetComp("RootPanel/InfoPanel/ability/value/offense/bg/line","Image").fillAmount = self.m_Model.atk/self.m_Model.limit
    self:GetComp("RootPanel/InfoPanel/ability/value/defense/bg/line","Image").fillAmount = self.m_Model.def/self.m_Model.limit
    self:GetComp("RootPanel/InfoPanel/ability/value/organizational/bg/line","Image").fillAmount = self.m_Model.ogz/self.m_Model.limit
end

function FCClubCenterUIView:Refresh()    
    self.m_Model = FCClubCenterUI:GetUIModel()
    local paybtn = self:GetComp("RootPanel/InfoPanel/teaminfo/paybtn","Button")
    if FootballClubModel.m_FCData.activation == nil then
        paybtn.interactable = false
        self:SetText("RootPanel/InfoPanel/teaminfo/name/txt", "已支付")
    else
        paybtn.interactable = not FootballClubModel.m_FCData.activation
        self:SetText("RootPanel/InfoPanel/teaminfo/name/txt", self.m_Model.name)
    end
    --paybtn.interactable = FootballClubModel.m_FCData.activation == nil
end


function FCClubCenterUIView:OnExit()
    self.super:OnExit(self)
    self.m_Model = nil
    FootballClubController:ShowFootballClubBuildings()

    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
    GameTimer:CreateNewTimer(0.02, function()
        FootballClubScene:SetRoomOnCenter(data, true,FootballClubModel.ClubCenterID)
    end)
end

return FCClubCenterUIView
