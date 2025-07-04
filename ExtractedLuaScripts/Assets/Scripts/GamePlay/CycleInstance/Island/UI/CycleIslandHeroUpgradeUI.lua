---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2024/6/26 19:48
---

---@class CycleIslandHeroUpgradeUI
local CycleIslandHeroUpgradeUI = GameTableDefine.CycleIslandHeroUpgradeUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function CycleIslandHeroUpgradeUI:ctor()

end

function CycleIslandHeroUpgradeUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_HERO_UPGRADE_UI, self.m_view, require("GamePlay.CycleInstance.Island.UI.CycleIslandHeroUpgradeUIView"), self, self.CloseView)
    return self.m_view
end

function CycleIslandHeroUpgradeUI:OpenView(hero_id)
    --暂时随机显示一个英雄的升级界面
    --local heroConfigs = ConfigMgr.config_cy_instance_hero
    --local heroCount = Tools:GetTableSize(heroConfigs)
    --local heroIndex = math.random(1,heroCount)
    --local heroID
    --local curIndex = 1
    --for k,v in pairs(heroConfigs) do
    --    if heroIndex == curIndex then
    --        heroID = k
    --        break
    --    end
    --    curIndex = curIndex + 1
    --end
    if hero_id then
        self:GetView()
        self.m_view:Invoke("Init",hero_id)
    end
end

function CycleIslandHeroUpgradeUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_HERO_UPGRADE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

return CycleIslandHeroUpgradeUI