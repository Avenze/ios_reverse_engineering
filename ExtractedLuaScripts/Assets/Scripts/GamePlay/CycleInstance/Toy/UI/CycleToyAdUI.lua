--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-09 14:04:10
]]
local CycleToyModel = nil ---@type CycleToyModel
local CycleToyAdUI = GameTableDefine.CycleToyAdUI
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleToyAdUI:GetView()
    CycleToyModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
    self:GetUIModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_AD_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyAdUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyAdUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_AD_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function CycleToyAdUI:GetUIModel()
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local time = currentModel.config_global.instance_iaa_resource * 60

    local resReward, money, exp, point = currentModel:CalculateOfflineRewards(time,false, false)
    
    self.m_model = {
        resReward = resReward,
        money = money,
        resConfig = currentModel.resourceConfig
    }
    return self.m_model
end

function CycleToyAdUI:RefreshUIModel()
    self:GetUIModel()
end

function CycleToyAdUI:ClaimResource(cb, onSuccess, onFail,id)

    local callback = function()
        local money = 0
        --local resFormat = {}
        --for i,v in pairs(self.m_model.resReward) do
        --    resFormat[i] = {[i] = self.m_model.resReward[i]}
        --    money = money + self.m_model.resConfig[i].price * self.m_model.resReward[i]
        --end
        --InstanceDataManager:AddProdutionsData(resFormat)
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()

        CycleToyModel:AddCurInstanceCoin(self.m_model.money)
        EventManager:DispatchEvent("FLY_ICON", nil, instanceBind.cash_fly, nil, function()
            -- GameTableDefine.CycleInstanceMainViewUI:Refresh()
        end)
        
        if cb then
            cb()
        end
    end
    
    GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10012)
end

function CycleToyAdUI:ShowPanel()
    self:GetView()
end