--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-26 16:17:39
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Color = CS.UnityEngine.Color
local ResMgr = GameTableDefine.ResourceManager

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleCastleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()

local CycleCastleSkillUIView = Class("CycleCastleSkillUIView", UIView)

function CycleCastleSkillUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function CycleCastleSkillUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CycleCastleSkillUIView:OnPause()

end

function CycleCastleSkillUIView:OnResume()

end

function CycleCastleSkillUIView:OnExit()

end

function CycleCastleSkillUIView:ShowSkillPanel(skillData)
    -- local tempIcon = "btn_premiumpack10"
    --TODO：根据数据封装的模块获取当前的技能点数
    local curSkills = CycleCastleModel:GetCurSkillData()
    for i = 1, 3 do
        local panelGo = self:GetGoOrNil("RootPanel/"..i.."Panel")
        
        local curSkillData = skillData[i]
        local curSkillCfg = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(curSkills[i])
        local nextSkillCfg = GameTableDefine.CycleCastleSkillUI:GetNextSkillItemCfg(curSkills[i])
        local isMax = false
        if not nextSkillCfg then
            isMax = true
        end
        if panelGo and curSkillCfg then
            local curSkillPoints = CycleCastleModel:GetCurSkillPoints(curSkillCfg.skill_type)
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
                        if CycleCastleModel:UpdateSkill(curSkillCfg.id) then
                            self:ShowSkillPanel(CycleCastleModel:GetCurSkillData())
                        end
                    else
                        GameTableDefine.ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
                            GameTableDefine.CycleCastleShopUI:GetView()
                            self:DestroyModeUIObject()
                        end)
                        GameTableDefine.CycleCastlePopUI:PackTrigger(3)
                        
                    end
                end)
            end
        end
        
    end
end

return CycleCastleSkillUIView



