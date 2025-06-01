--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-09 14:04:10
]]
local CycleInstanceAdUI = GameTableDefine.CycleInstanceAdUI
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleInstanceAdUI:GetView()
    self:GetUIModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_AD_UI, self.m_view, require("GamePlay.CycleInstance.Island.UI.CycleInstanceAdUIView"), self, self.CloseView)
    return self.m_view
end

function CycleInstanceAdUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_AD_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function CycleInstanceAdUI:GetUIModel()
    local time = ConfigMgr.config_global.instance_iaa_resource * 60
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local resReward = currentModel:CalculateOfflineRewards(time, true, false)
    local _, moneyNum = currentModel:CalculateOfflineRewards(time, false, false)
    self.m_model = {
        resReward = resReward,
        money = moneyNum,
        resConfig = currentModel.resourceConfig
    }
    return self.m_model
end

function CycleInstanceAdUI:RefreshUIModel()
    self:GetUIModel()
end

function CycleInstanceAdUI:ClaimResource(cb, onSuccess, onFail,id)

    local callback = function()
        local money = 0
        --local resFormat = {}
        --for i,v in pairs(self.m_model.resReward) do
        --    resFormat[i] = {[i] = self.m_model.resReward[i]}
        --    money = money + self.m_model.resConfig[i].price * self.m_model.resReward[i]
        --end
        --InstanceDataManager:AddProdutionsData(resFormat)
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()
        local currentModel = CycleInstanceDataManager:GetCurrentModel()
        currentModel:AddCurInstanceCoin(self.m_model.money)
        EventManager:DispatchEvent("FLY_ICON", nil, instanceBind.cash_fly, nil, function()
            -- GameTableDefine.CycleInstanceMainViewUI:Refresh()
        end)
        
        if cb then
            cb()
        end
    end
    
    GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10012)
end

function CycleInstanceAdUI:ShowPanel()
    self:GetView()
end