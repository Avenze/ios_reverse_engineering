--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-08 19:59:20
    description:{description}
]]
local InstanceModel = GameTableDefine.InstanceModel
local InstanceAdUI = GameTableDefine.InstanceAdUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceAdUI:GetView()
    self:GetUIModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_AD_UI, self.m_view, require("GamePlay.Instance.UI.InstanceAdUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceAdUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_AD_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function InstanceAdUI:GetUIModel()
    local time = ConfigMgr.config_global.instance_iaa_resource * 60
    local resReward = InstanceModel:CalculateOfflineRewards(time, true, false)
    local _, moneyNum = GameTableDefine.InstanceModel:CalculateOfflineRewards(time, false, false)
    self.m_model = {
        resReward = resReward,
        money = moneyNum,
        resConfig = InstanceDataManager.config_resource_instance
    }
    return self.m_model
end

function InstanceAdUI:RefreshUIModel()
    self:GetUIModel()
end

function InstanceAdUI:ClaimResource(cb, onSuccess, onFail,id)

    local callback = function()
        local money = 0
        --local resFormat = {}
        --for i,v in pairs(self.m_model.resReward) do
        --    resFormat[i] = {[i] = self.m_model.resReward[i]}
        --    money = money + self.m_model.resConfig[i].price * self.m_model.resReward[i]
        --end
        --InstanceDataManager:AddProdutionsData(resFormat)
        local instanceBind = InstanceDataManager:GetInstanceBind()

        InstanceDataManager:AddCurInstanceCoin(self.m_model.money)
        EventManager:DispatchEvent("FLY_ICON", nil, instanceBind.cash_fly, nil, function()
            GameTableDefine.InstanceMainViewUI:Refresh()
        end)
        
        if cb then
            cb()
        end
    end
    --GameSDKs:Track("play_video", {video_id = 10003, current_money = GameTableDefine.ResourceManger:GetCash()})
    GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10012)
end

function InstanceAdUI:ShowPanel()
    self:GetView()
end