--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-26 16:17:39
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")


local CycleInstanceSkillUIView = Class("CycleInstanceSkillUIView", UIView)
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

function CycleInstanceSkillUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function CycleInstanceSkillUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CycleInstanceSkillUIView:OnPause()

end

function CycleInstanceSkillUIView:OnResume()

end

function CycleInstanceSkillUIView:OnExit()

end

function CycleInstanceSkillUIView:ShowSkillPanel(skillData)
    -- local tempIcon = "btn_premiumpack10"
    --TODO：根据数据封装的模块获取当前的技能点数
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local curSkills = currentModel:GetCurSkillData()
    for i = 1, 3 do
        local panelGo = self:GetGoOrNil("RootPanel/"..i.."Panel")
        
        local curSkillData = skillData[i]
        local curSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(curSkills[i])
        local nextSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetNextSkillItemCfg(curSkills[i])
        local isMax = false
        if not nextSkillCfg then
            isMax = true
        end
        if panelGo and curSkillCfg then
            local curSkillPoints = currentModel:GetCurSkillPoints(curSkillCfg.skill_type)
            local isHaveEnoughPoint = isMax or curSkillPoints >= nextSkillCfg.res
            local tempIcon = curSkillCfg.skill_icon
            --技能图标
            self:SetSprite(self:GetComp(panelGo, "main/info/skill/iconAndLevel/icon", "Image"), "UI_Common", tempIcon)
            --技能名称
            self:SetText(panelGo, "main/info/skillName/text", GameTextLoader:ReadText(curSkillCfg.skill_name))
            --技能描述
            -- string.gsub(str, "%[roomName%]", roomName)
            local tmpBuffStr = curSkillCfg.buff
            if curSkillCfg.skill_type == 1 then
                tmpBuffStr = (tmpBuffStr - 1) * 100
            end
            local descStr = string.gsub(GameTextLoader:ReadText(curSkillCfg.skill_desc), "%[buff%]", string.format("%.2f", tmpBuffStr))
            self:SetText(panelGo, "main/info/descText", descStr)
            --当前等级
            self:SetText(panelGo, "main/info/skill/iconAndLevel/level/levelNum", tostring(curSkillCfg.skill_level))
            
            local tmpGo = self:GetGoOrNil(panelGo, "main/skillBook")
            local maxGo = self:GetGoOrNil(panelGo, "main/maxLevel")
            if tmpGo then
                tmpGo:SetActive(not isMax)
            end
            if maxGo then
                maxGo:SetActive(isMax)
            end
            if nextSkillCfg then
                --当前的技能点数
                self:SetText(panelGo, "main/upgradeBtn/skillbook/now/num", tostring(curSkillPoints), isHaveEnoughPoint and "92D40F" or "F80D0F")
                self:SetText(panelGo, "main/upgradeBtn/skillbook/cost/num", tostring(nextSkillCfg.res))
                self:SetSprite(self:GetComp(panelGo, "main/upgradeBtn/skillbook/now/icon", "Image"), "UI_Common", tempIcon)
                -- self:GetGo(panelGo, "main/upgradeBtn/skillbook/now/icon"):SetActive(true)
            end
            --设置按钮了
            -- self:GetGoOrNil(panelGo, "main/maxLevelBtn"):SetActive(isMax)
            -- self:GetGoOrNil(panelGo, "main/GotoBtn"):SetActive(not isHaveEnoughPoint and not isMax)
            -- self:GetGoOrNil(panelGo, "main/upgradeBtn"):SetActive(isHaveEnoughPoint and not isMax)
            local upgradeBtn = self:GetComp(panelGo, "main/upgradeBtn", "Button")
            -- local gotoBtn = self:GetComp(panelGo, "main/GotoBtn", "Button")
            if upgradeBtn then
                upgradeBtn.interactable = not isMax
                self:SetButtonClickHandler(upgradeBtn, function()
                    -- upgradeBtn.interactable = false
                    if isHaveEnoughPoint then
                        if currentModel:UpdateSkill(curSkillCfg.id) then
                            self:ShowSkillPanel(currentModel:GetCurSkillData())
                        end
                    else
                        GameTableDefine.ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
                            GameTableDefine.CycleInstanceShopUI:GetView()
                            self:DestroyModeUIObject()
                        end)
                        GameTableDefine.CycleInstancePopUI:PackTrigger(3)
                        
                    end
                end)
            end
        end
        
    end
end

return CycleInstanceSkillUIView



