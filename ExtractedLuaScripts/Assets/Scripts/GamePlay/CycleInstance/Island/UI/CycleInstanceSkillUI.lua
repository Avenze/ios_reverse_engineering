--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-26 14:49:36
]]

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleInstanceSkillUI = GameTableDefine.CycleInstanceSkillUI
local GameUIManager = GameTableDefine.GameUIManager
local EventManager = require("Framework.Event.Manager")

function CycleInstanceSkillUI:GetView()
    self:GetUIModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_SKILL_UI, self.m_view, require("GamePlay.CycleInstance.Island.UI.CycleInstanceSkillUIView"), self, self.CloseView)
    return self.m_view
end

function CycleInstanceSkillUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_SKILL_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--[[
    @desc: 获取当前技能的数据显示内容
    author:{author}
    time:2024-06-26 15:38:49
    @return:
]]
function CycleInstanceSkillUI:GetUIModel()
    local type1SkillItem = {}
    local type2SkillItem = {}
    local type3SkillItem = {}
    self.m_model = {4, 5, 6}
    return self.m_model
end

function CycleInstanceSkillUI:RefreshUIModel()
    self:GetUIModel()
end

function CycleInstanceSkillUI:ShowSkillPanel()
    self:GetView():Invoke("ShowSkillPanel", CycleInstanceDataManager:GetCurrentModel():GetCurSkillData())
end

function CycleInstanceSkillUI:GetCurSkillItemCfg(skillID)
    local config_skills = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_skill
    for k, v in pairs(config_skills) do
        for k2, v2 in pairs(v) do
            if v2.id == skillID then
                return v2
            end
        end
    end
    return nil
end

function CycleInstanceSkillUI:GetNextSkillItemCfg(skillID)
    local curCfg = self:GetCurSkillItemCfg(skillID)
    if not curCfg then
        return nil
    end
    local skillType = curCfg.skill_type
    local nextLevel = curCfg.skill_level + 1
    local config_skills = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_skill
    if not config_skills[skillType] and not config_skills[skillType][nextLevel] then
        return nil
    end
    return config_skills[skillType][nextLevel]
end