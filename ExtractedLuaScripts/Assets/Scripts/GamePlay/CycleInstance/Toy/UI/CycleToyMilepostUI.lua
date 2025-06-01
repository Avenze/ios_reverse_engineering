--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-29 11:09:58
    里程碑奖励UI
]]
---@class CycleToyMilepostUI
local CycleToyMilepostUI = GameTableDefine.CycleToyMilepostUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local EventManager = require("Framework.Event.Manager")

function CycleToyMilepostUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_MILEPOST_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyMilepostUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyMilepostUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_MILEPOST_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function CycleToyMilepostUI:Refresh(scrollIndex,scrollToNewest)
    local curCfgData = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_reward
    local datas, curData = self:CalculateData()
    self:GetView():Invoke("ShowMilepostPanel", datas, curData, scrollIndex,scrollToNewest)
end

function CycleToyMilepostUI:CalculateData()
    local data = {}
    local curData = {}
    --local curRewardCfg = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_reward or ConfigMgr.config_cy_instance_reward[GameTableDefine.CycleInstanceDataManager:GetInstanceBind().id]
    --curRewardCfg = CycleInstanceDataManager:GetCurrentModel():HaveRemoteAwardConfig() and CycleInstanceDataManager:GetCurrentModel():GetRemoteAwardConfig() or curRewardCfg

    for k, v in ipairs(CycleInstanceDataManager:GetCurrentModel().config_cy_instance_reward) do
        local cur = {}
        local infoTitle = tostring(k).."资源包"
        local infoDesc = tostring(k).."奖励内容描述"
        local rewardIcon = ""
        local rewardCount = v.count
        local rewardStatus, pro = self:GetRewardStatusByCfg(v) --当前的奖励状态（1-未解锁，2-当前进行中，3-已解锁未领取，4-已领取
        local shopID = v.shop_id
        local shopCfg = ConfigMgr.config_shop[shopID]
        if shopCfg then
            infoTitle = GameTextLoader:ReadText(shopCfg.name)
            infoDesc = GameTextLoader:ReadText(shopCfg.desc)
        end
        cur.info = {}
        cur.info.infoTitle = infoTitle
        cur.info.infoDesc = infoDesc
        cur.icon = shopCfg.icon
        if shopCfg.type == 9 then
            if shopCfg.country == 0 then
                rewardCount = tostring(math.floor(rewardCount*60)).."Min"
                if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                    cur.icon = cur.icon.."_euro"
                end
            elseif shopCfg.country == 2 then
                cur.icon = cur.icon.."_euro"
            end
        end
        cur.count = rewardCount
        cur.level = v.level
        cur.isSp = v.sp_sign == 1
        cur.experience = v.experience
        cur.rewardStatus = rewardStatus
        cur.shop_id = cur.shop_id
        data[k] = cur
        if rewardStatus == 2 then
            curData.data = cur
            curData.progressData = pro
        end
    end
    if not curData then
        curData.data = data[#data]
        curData.progressData = {}
    end
    return data, curData
end

function CycleToyMilepostUI:GetRewardStatusByCfg(itemCfg)
    local result = 1
    --TODO:获取当前的里程碑经验
    local curMileExperience = CycleInstanceDataManager:GetCurrentModel():GetCurInstanceScore()
    local beforeitemCfg = nil
    local curRewardCfg = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_reward or ConfigMgr.config_cy_instance_reward[1]
    if itemCfg.level > 1 then
        beforeitemCfg = curRewardCfg[itemCfg.level - 1]
    end
    
    local curSKLevel = CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel()
    if itemCfg.level <= curSKLevel then
        if CycleInstanceDataManager:GetCurrentModel():IsLevelRewardClaimed(itemCfg.level) then
            result = 4
        else
            result = 3
        end
        return result, {}
    end
    
    local curMaxExp = itemCfg.experience
    local curExp = curMileExperience
    local beforeExp = 0
    if beforeitemCfg then
        if beforeitemCfg.level == curSKLevel then
        -- if curMileExperience >= beforeitemCfg.experience and curMileExperience < itemCfg.experience then
            result = 2
            beforeExp = beforeitemCfg.experience
        end
    elseif itemCfg.level == 1 then
        result = 2
    end
    return result, {curExp = curExp, beforeExp = beforeExp, curMaxExp = curMaxExp}
end

function CycleToyMilepostUI:ShowMilepostPanel(scrollIndex)
    self:Refresh(scrollIndex,true)
end
