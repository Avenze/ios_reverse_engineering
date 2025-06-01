local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FootballClubModel = GameTableDefine.FootballClubModel
local FCHealthCenterUI = GameTableDefine.FCHealthCenterUI
local ResourceManger = GameTableDefine.ResourceManger
local TimerMgr = GameTimeManager
local FootballClubController = GameTableDefine.FootballClubController
local FootballClubScene = GameTableDefine.FootballClubScene

local FCHealthCenterUIView = Class("FCHealthCenterUIView", UIView)
function FCHealthCenterUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end
function FCHealthCenterUIView:OnEnter()
    self.m_Model = FCHealthCenterUI:GetUIModel()
    self:Init()
    self:Refresh()
    self:CreateTimer(
        1000,
        function()
            self:SetText("RootPanel/TranningPanel/product/prog/bg/up/now/now_num", string.format("%.2f", FootballClubModel:GetSP()))
            --self:SetText("RootPanel/TranningPanel/product/prog/bg/up/now/now_num", string.format("%.2f", (FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id).SP)))
            local SPRecoveryCD = FCHealthCenterUI:GetSPRecoveryCD()
            if SPRecoveryCD > 0 then
                self:SetText("RootPanel/TranningPanel/product/strength/time/time", GameTimeManager:FormatTimeLength(SPRecoveryCD or 0))
                local value = (self.m_Model.cd * 3600 - SPRecoveryCD) / (self.m_Model.cd * 3600)
                self:GetComp("RootPanel/TranningPanel/product/strength/time", "Slider").value = value
            else
                self:Refresh()
            end
        end,
        true,
        true,
        true
    )
end
function FCHealthCenterUIView:Init()
    self:SetButtonClickHandler(
        self:GetComp("BgCover", "Button"),
        function()
            self:DestroyModeUIObject()
        end
    )
    local tranningPanelGo = self:GetGo("RootPanel/TranningPanel")

    local function revertSP()
        FCHealthCenterUI:UseSPRecovery()
        self:Refresh()
    end

    self:SetButtonClickHandler(
        self:GetComp(tranningPanelGo, "levelup/bg/btn/btn", "Button"),
        function()
            ResourceManger:SpendLocalMoney(
                self.m_Model.upgradeCash,
                nil,
                function(success)
                    if success then
                        FootballClubModel:RoomUpgrade(
                            FCHealthCenterUI.ROOM_NUM,
                            function(success)
                                if success then
                                    FCHealthCenterUI:RefreshUIModel()
                                    self:Refresh()
                                end
                            end
                        )
                        GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 1, amount_new = tonumber(self.m_Model.upgradeCash) or 0, position = "["..tostring(10005).."]号俱乐部建筑事件"})
                    end
                end
            )
        end
    )

    local useBtn = self:GetComp(tranningPanelGo, "product/strength/btn/btn", "Button")
    self:SetButtonClickHandler(
        useBtn,
        function()
            if self.m_Model.SP + self.m_Model.efficiencyNum > self.m_Model.SPlimit then
                --TXT_FBCLUB_105_6_DESC
                --EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText(""))
                local isBlock = false
                GameTableDefine.ChooseUI:CommonChoose(
                    GameTextLoader:ReadText("TXT_FBCLUB_105_6_DESC"),
                    function()
                        revertSP()
                    end,
                    true,
                    function()
                    end
                )
                return
            end
            revertSP()
        end
    )
end

function FCHealthCenterUIView:Refresh()
    self.m_Model = FCHealthCenterUI:GetUIModel()

    self:SetText("RootPanel/TranningPanel/levelup/bg/level/bg/num", self.m_Model.LV)
    self:SetText("RootPanel/TranningPanel/levelup/bg/btn/btn/price/num", Tools:SeparateNumberWithComma(self.m_Model.upgradeCash or 0))
    local tranningPanelGo = self:GetGo("RootPanel/TranningPanel")
    self:SetText(tranningPanelGo, "levelup/bg/effect/effect1/txt/num", string.format("%.2f", self.m_Model.strength)) --体力值
    self:GetGo(tranningPanelGo, "levelup/bg/effect/effect1/txt/buff"):SetActive(self.m_Model.upgradeCash)
    if self.m_Model.upgradeCash then
        self:SetText(tranningPanelGo, "levelup/bg/effect/effect1/txt/buff/num", string.format("%.2f", self.m_Model.addStrength))
    end
    self:SetText(tranningPanelGo, "levelup/bg/effect/effect2/txt/num", string.format("%.2f",self.m_Model.cd)) --CD
    self:GetGo(tranningPanelGo, "levelup/bg/effect/effect2/txt/buff"):SetActive(self.m_Model.upgradeCash)
    if self.m_Model.upgradeCash then
        self:SetText(tranningPanelGo, "levelup/bg/effect/effect2/txt/buff/num", string.format("%.2f", self.m_Model.redCd))
    end
    --升级按钮相关
    local reason = FCHealthCenterUI:GetCanUpgrade()
    self:GetGo(tranningPanelGo, "levelup/bg/btn/dissabled"):SetActive(reason == FCHealthCenterUI.ECanNotUpgradeReason.NoMoney)
    if self.m_Model.nexHealthCenterCfg then
        self:SetText("RootPanel/TranningPanel/levelup/bg/btn/dissabled/price/num", Tools:SeparateNumberWithComma(self.m_Model.nexHealthCenterCfg.upgradeCash))
    end
    self:GetGo(tranningPanelGo, "levelup/bg/btn/req"):SetActive(reason == FCHealthCenterUI.ECanNotUpgradeReason.NoReq)
    if self.m_Model.nexHealthCenterCfg then
        self:SetImageSprite("RootPanel/TranningPanel/levelup/bg/btn/req/price/icon", self.m_Model.leagueConfig[self.m_Model.nexHealthCenterCfg.upgradeLeague].iconUI)
    end
    self:GetGo(tranningPanelGo, "levelup/bg/btn/max"):SetActive(reason == FCHealthCenterUI.ECanNotUpgradeReason.IsMaxHealth)

    self:SetText(tranningPanelGo, "product/strength/desc", Tools:FormatString(GameTextLoader:ReadText("TXT_FBCLUB_105_2_DESC"), self.m_Model.efficiency))
    self:SetText(tranningPanelGo, "product/strength/btn/btn/num/num", math.floor(self.m_Model.efficiencyNum))
    local SPRecoveryCD = FCHealthCenterUI:GetSPRecoveryCD()
    local showSPCD = SPRecoveryCD
    if SPRecoveryCD < 0 then
        showSPCD = 0
    end
    self:SetText(tranningPanelGo, "product/strength/time/time", GameTimeManager:FormatTimeLength(showSPCD))
    local useBtn = self:GetComp(tranningPanelGo, "product/strength/btn/btn", "Button")
    self:GetGo(tranningPanelGo, "product/strength/btn/dissabled"):SetActive(SPRecoveryCD > 0)
    self:GetComp(tranningPanelGo, "product/strength/time", "Slider").value = (self.m_Model.cd * 3600 - SPRecoveryCD) / (self.m_Model.cd * 3600)
end

function FCHealthCenterUIView:OnExit()
    self.m_Model = nil
    self.super:OnExit(self)
    FootballClubController:ShowFootballClubBuildings()

    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    local data = {m_cameraSize = cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position = cameraFocus.transform.position}
    GameTimer:CreateNewTimer(
        0.02,
        function()
            FootballClubScene:SetRoomOnCenter(data, true, FootballClubModel.HealthCenterID)
        end
    )
end

return FCHealthCenterUIView
