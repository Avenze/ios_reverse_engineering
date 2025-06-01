--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-26 14:49:36
]]

-- local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleCastleModel = nil
local CycleCastleSkillUI = GameTableDefine.CycleCastleSkillUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local EventManager = require("Framework.Event.Manager")

function CycleCastleSkillUI:GetView()
    CycleCastleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
    self:GetUIModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_SKILL_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleSkillUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleSkillUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_SKILL_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--[[
    @desc: 获取当前技能的数据显示内容
    author:{author}
    time:2024-06-26 15:38:49
    @return:
]]
function CycleCastleSkillUI:GetUIModel()
    local type1SkillItem = {}
    local type2SkillItem = {}
    local type3SkillItem = {}
    self.m_model = {4, 5, 6}
    return self.m_model
end

function CycleCastleSkillUI:RefreshUIModel()
    self:GetUIModel()
end

function CycleCastleSkillUI:ShowSkillPanel()
    self:GetView():Invoke("ShowSkillPanel", CycleCastleModel:GetCurSkillData())
end

function CycleCastleSkillUI:GetCurSkillItemCfg(skillID)
    for k, v in pairs(ConfigMgr.config_cy_instance_skill[CycleInstanceDataManager:GetCurrentModel().instance_id]) do
        for k2, v2 in pairs(v) do
            if v2.id == skillID then
                return v2
            end
        end
    end
    return nil
end

function CycleCastleSkillUI:GetNextSkillItemCfg(skillID)
    local curCfg = self:GetCurSkillItemCfg(skillID)
    if not curCfg then
        return nil
    end
    local skillType = curCfg.skill_type
    local nextLevel = curCfg.skill_level + 1
    local instance_id = CycleInstanceDataManager:GetCurrentModel().instance_id
    local config_cy_instance_skill = ConfigMgr.config_cy_instance_skill[instance_id]
    if not config_cy_instance_skill[skillType] or not config_cy_instance_skill[skillType][nextLevel] then
        return nil
    end
    return config_cy_instance_skill[skillType][nextLevel]
end