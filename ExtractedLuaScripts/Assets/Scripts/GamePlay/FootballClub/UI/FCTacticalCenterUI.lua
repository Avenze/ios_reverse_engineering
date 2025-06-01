local FCTacticalCenterUI= GameTableDefine.FCTacticalCenterUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local EventManager = require("Framework.Event.Manager")
local ConfigMgr = GameTableDefine.ConfigMgr

FCTacticalCenterUI.ROOM_NUM = 10005

function FCTacticalCenterUI:GetView()      
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_TACTICAL_CENTER_UI, self.m_view, require("GamePlay.FootballClub.UI.FCTacticalCenterUIView"), self, self.CloseView)
    return self.m_view
end
function FCTacticalCenterUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_TACTICAL_CENTER_UI)
    self.m_view = nil
    self.m_Model = nil
    collectgarbage("collect")
end

-------------model-------------
function FCTacticalCenterUI:GetUIModel()
    if not self.m_Model then
        local tacticalCenterData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        local curTacticalCenterCfg = ConfigMgr.config_tactical_center[FootballClubModel.m_cfg.id][tacticalCenterData.LV]
        local nexTacticalCenterCfg = ConfigMgr.config_tactical_center[FootballClubModel.m_cfg.id][tacticalCenterData.LV + 1] or nil 
        GetSkillList = function()
            local skillList = {}
            for i=1, 3 <= tacticalCenterData.LV and tacticalCenterData.LV or 3 do
                local curCfg = ConfigMgr.config_tactical_center[FootballClubModel.m_cfg.id][i]
                if Tools:GetTableSize(skillList) == 0 then
                    table.insert(skillList, curCfg.tacticId)                    
                else
                    for k,v in ipairs(skillList) do
                        if math.floor(v / 100) == math.floor(curCfg.tacticId / 100) then
                            skillList[k] = curCfg.tacticId
                            break
                        else
                            if k == Tools:GetTableSize(skillList) then
                                table.insert(skillList, curCfg.tacticId)
                                break
                            end           
                        end
                    end
                end
            end
            return skillList
        end
        self.m_Model = 
        {
            LV = tacticalCenterData.LV,
            skillList = GetSkillList(),
            

        }
        if nexTacticalCenterCfg then
            self.m_Model.upgradeCash = nexTacticalCenterCfg.upgradeCash - curTacticalCenterCfg.upgradeCash


        end
    end
    return self.m_Model
end   

function FCTacticalCenterUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end