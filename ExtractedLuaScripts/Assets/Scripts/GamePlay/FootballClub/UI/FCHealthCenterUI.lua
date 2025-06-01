local FCHealthCenterUI= GameTableDefine.FCHealthCenterUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ResourceManger = GameTableDefine.ResourceManger
local EventManager = require("Framework.Event.Manager")
local ConfigMgr = GameTableDefine.ConfigMgr
local TimerMgr = GameTimeManager
local FootballClubController = GameTableDefine.FootballClubController

FCHealthCenterUI.ROOM_NUM = 10005
FCHealthCenterUI.ECanNotUpgradeReason = {
    NoMoney = 1,
    NoReq = 2,
    IsMaxHealth = 3,
}

function FCHealthCenterUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_HEALTH_CENTER_UI, self.m_view, require("GamePlay.FootballClub.UI.FCHealthCenterUIView"), self, self.CloseView)
    return self.m_view
end
function FCHealthCenterUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_HEALTH_CENTER_UI)
    self.m_view = nil
    self.m_Model= nil
    collectgarbage("collect")
end

-------------model-------------
function FCHealthCenterUI:GetUIModel()
    if not self.m_Model then
        local healthCenterData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)    
        local curHealthCenterCfg = ConfigMgr.config_health_center[FootballClubModel.m_cfg.id][healthCenterData.LV]
        local nexHealthCenterCfg = ConfigMgr.config_health_center[FootballClubModel.m_cfg.id][healthCenterData.LV + 1] or nil 
        self.m_Model = 
        {
            LV = healthCenterData.LV,
            LeagueData = FootballClubModel:GetLeagueData(),
            leagueConfig = ConfigMgr.config_league[FootballClubModel.m_cfg.id],
            SPlimit = FCData.SPlimit,
            SP = FootballClubModel:GetSP(),
            --SP = FCData.SP,
            strength = curHealthCenterCfg.strength, --当前恢复量
            efficiency = math.floor(curHealthCenterCfg.efficiency * 100) .. "%", --当前体力充能收益
            cd = curHealthCenterCfg.cd, --当前充能CD
            efficiencyNum = curHealthCenterCfg.efficiency * FCData.SPlimit,
            useTime = healthCenterData.useTime or 0,
            nexHealthCenterCfg = nexHealthCenterCfg,
        }
        if nexHealthCenterCfg then
            --升级现金
            self.m_Model.upgradeCash = nexHealthCenterCfg.upgradeCash
            --升级提高的体力
            self.m_Model.addStrength = nexHealthCenterCfg.strength - curHealthCenterCfg.strength
            --体力充能收益增量
            self.m_Model.addEfficiency = nexHealthCenterCfg.efficiency - curHealthCenterCfg.efficiency
            --CD变化量
            self.m_Model.redCd = curHealthCenterCfg.cd - nexHealthCenterCfg.cd 
        end       
    end
    return self.m_Model
end

function FCHealthCenterUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

--检查升级是否可用
function FCHealthCenterUI:GetCanUpgrade()
    if not self.m_Model.nexHealthCenterCfg then
        return self.ECanNotUpgradeReason.IsMaxHealth
    end
    local leagueData = self.m_Model.LeagueData
    if self.m_Model.nexHealthCenterCfg.upgradeLeague > leagueData.leagueLV then
        return self.ECanNotUpgradeReason.NoReq
    end
    if not ResourceManger:CheckLocalMoney( self.m_Model.nexHealthCenterCfg.upgradeCash) then
        return self.ECanNotUpgradeReason.NoMoney
    end
    
end

--检测加体力按钮是否可用 
function FCHealthCenterUI:CheckCanUse()
    local cd = self.m_Model.cd
    local canUse = FootballClubModel:GetRoomDataById(FCHealthCenterUI.ROOM_NUM).useTime == nil 
    or FootballClubModel:GetRoomDataById(FCHealthCenterUI.ROOM_NUM).useTime + cd * 60 * 60 < TimerMgr:GetCurrentServerTime(true)
    return canUse
end

--获取体力按钮CD
function FCHealthCenterUI:GetSPRecoveryCD()
    local cd = self.m_Model.cd
    local useTime = FootballClubModel:GetRoomDataById(FCHealthCenterUI.ROOM_NUM).useTime
    if useTime == nil then
        return 0
    else
        return (FootballClubModel:GetRoomDataById(FCHealthCenterUI.ROOM_NUM).useTime + cd * 60 * 60) - TimerMgr:GetCurrentServerTime(true)
    end
end

--使用加体力按钮
function FCHealthCenterUI:UseSPRecovery()
    local revertNum = FCHealthCenterUI.m_Model.efficiencyNum
    EventManager:DispatchEvent("FLY_ICON", nil, 101, nil, function()
        FootballClubModel:ChangeSP(nil, revertNum)
    end)
    
    FootballClubController:PlayUseSPChargeFeel()
    FootballClubModel:RefreshStrengthCharge()
    self:RefreshUIModel()
    self:GetView()
end

--获取体力恢复值/s
function FCHealthCenterUI:GetSPRecoverySpeed(FCData, buildingId)
    if not FCData then
        FCData = self.m_FCData
    end
    if not FCData then
        return 
    end
    local HealthCenterData = FCData.HealthCenter
    local SPSpend
    local healthCenterCfg = ConfigMgr.config_health_center[buildingId][HealthCenterData.LV]
    SPSpend = healthCenterCfg.strength / (60 * 60)
    if HealthCenterData.state ~= 2 then
        SPSpend = 0
    end
    return SPSpend
end


