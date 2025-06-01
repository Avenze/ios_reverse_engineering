--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 13:44:58
]]
---@class InstanceMainViewUI
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceMainViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI, self.m_view, require("GamePlay.Instance.UI.InstanceMainViewUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceMainViewUI:CloseView()
    EventManager:DispatchEvent("BACK_TO_SCENE")
    GameTableDefine.CityMode:EnterDefaultBuiding()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function InstanceMainViewUI:OpenUI()
    self:GetView()
end

function InstanceMainViewUI:Refresh()
    if self.m_view then
        self.m_view:Invoke("Show")
    end
end

function InstanceMainViewUI:Exit()
    if self.m_view then
        self.m_view:Invoke("DestroyModeUIObject")
    end
end


function InstanceMainViewUI:CallNotify(notifyType,...)
    if self.m_view then
        local args = {...}
        self.m_view:Invoke("CallNotify",notifyType,...)
    end
end

function InstanceMainViewUI:SetAchievementActive(active)
    if self.m_view then
        self.m_view:Invoke("SetAchievementActive",active)
    end
end

function InstanceMainViewUI:SetEventActive(active)
    if self.m_view then
        self.m_view:Invoke("SetEventActive",active)
    end
end

function InstanceMainViewUI:SetEventIAAActive(active)
    if self.m_view then
        self.m_view:Invoke("SetEventIAAActive",active)
    end
end

function InstanceMainViewUI:SetPackActive(active)
    if self.m_view then
        self.m_view:Invoke("SetPackActive",active)
    end
end

function InstanceMainViewUI:RefreshPackButton()
    if self.m_view and self.m_view.RefreshPackButton then
        self.m_view:RefreshPackButton()
    end
end

---播放里程碑分数奖励动画
function InstanceMainViewUI:PlayMilestoneAnim()
    if self.m_view then
        self.m_view:PlayMilestoneAnim()
    end
end