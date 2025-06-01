--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-29 11:26:48
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
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local CycleInstanceMilepostUIView = Class("CycleInstanceMilepostUIView", UIView)

function CycleInstanceMilepostUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CycleInstanceMilepostUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("reward", "Button"), function()
        self:GetGo("reward"):SetActive(false)
    end)
    self.m_list = self:GetComp("RootPanel/milestonePanel/reward/list", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        local currentModel = CycleInstanceDataManager:GetCurrentModel()
        return Tools:GetTableSize(currentModel.config_cy_instance_reward)
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateMilepostRewardList))
    self:SetListItemNameFunc(self.m_list, function(index)
        return "temp"
    end)
    self.tiemr = GameTimer:CreateNewTimer(1,function()
        local currentModel = CycleInstanceDataManager:GetCurrentModel()
        local timeRemaining = 0
        local state = CycleInstanceDataManager:GetInstanceState()
        if state == CycleInstanceDataManager.instanceState.isActive then
            timeRemaining = CycleInstanceDataManager:GetLeftInstanceTime()
        else
            timeRemaining = CycleInstanceDataManager:GetInstanceRewardTime()
        end
        -- local h = os.date("%d", timeRemaining) * 24 + os.date("%H", timeRemaining)
        -- local m = os.date("%M", timeRemaining)
        local timeStr =  GameTimeManager:FormatTimeLength(timeRemaining)
        self:SetText("RootPanel/milestonePanel/title/timer/num", timeStr)
        --里程碑节点相关内容
        local nextLevel = currentModel:GetCurInstanceKSLevel() + 1
        local beforeLevel = currentModel:GetCurInstanceKSLevel()
        if nextLevel > Tools:GetTableSize(currentModel.config_cy_instance_reward) then
            nextLevel = Tools:GetTableSize(currentModel.config_cy_instance_reward)
        end
        if beforeLevel < 0 then
            beforeLevel = 0
        end
        
        local beforeExp = 0
        if beforeLevel > 0 then
            beforeExp = currentModel.config_cy_instance_reward[beforeLevel].experience
        end
        local curExp = currentModel:GetCurInstanceScore()
        -- local curCfg = CycleInstance.config_cy_instance_reward[currentModel.GetCurInstanceKSLevel]
        local maxExp = currentModel.config_cy_instance_reward[nextLevel].experience
        local proValue = tonumber(BigNumber:Divide(curExp, maxExp))
        local icon = ConfigMgr.config_shop[currentModel.config_cy_instance_reward[nextLevel].shop_id].icon
        local shopCfg = ConfigMgr.config_shop[currentModel.config_cy_instance_reward[nextLevel].shop_id]
        if shopCfg.type == 9 then
            if shopCfg.counrty == 0 then
                if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                    icon = icon.."_euro"
                end
            elseif shopCfg.country == 2 then
                icon = icon.."_euro"
            end
        end
        self:GetComp("RootPanel/milestonePanel/title/info/currentProg/prog", "Slider").value = tonumber(proValue)
        self:SetText("RootPanel/milestonePanel/title/info/currentProg/prog/progPoint/limit", BigNumber:FormatBigNumber(maxExp))
        self:SetText("RootPanel/milestonePanel/title/info/currentProg/prog/progPoint/progress", BigNumber:FormatBigNumber(curExp))
        self:SetText("RootPanel/milestonePanel/title/info/progLevel/progress", tostring(currentModel:GetCurInstanceKSLevel()))
        self:SetText("RootPanel/milestonePanel/title/info/progLevel/limit", tostring(Tools:GetTableSize(currentModel.config_cy_instance_reward)))
        self:SetSprite(self:GetComp("RootPanel/milestonePanel/title/info/currentProg/reward/icon", "Image"), "UI_Shop", icon)
        if proValue >= 1 then
            GameTableDefine.CycleInstanceMilepostUI:Refresh()
            if self.tiemr then
                GameTimer:StopTimer(self.tiemr)
                self.tiemr = nil
            end
        end
    end,true,true)

    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("head/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CycleInstanceMilepostUIView:OnPause()

end

function CycleInstanceMilepostUIView:OnResume()
end

function CycleInstanceMilepostUIView:OnExit()
    if self.tiemr then
        GameTimer:_RemoveTimer(self.tiemr)
    end
end

function CycleInstanceMilepostUIView:ShowMilepostPanel(data, curData, index)
    -- local cur = {}
    --     --TODO:待实装内容
    --     local infoTitle = tostring(k).."资源包"
    --     local infoDesc = tostring(k).."奖励内容描述"
    --     local rewardIcon = ""
    --     local rewardCount = v.count
    --     local rewardStatus = 1 --当前的奖励状态（1-未解锁，2-当前进行中，3-已解锁未领取，4-已领取
    --     local shopID = v.shop_id
    --     cur.info = {}
    --     cur.info.infoTitle = infoTitle
    --     cur.info.infoDesc = infoDesc
    --      cur.icon = rewardIcon
    --     cur.count = rewardCount
    --     cur.level = v.level
    --     cur.experience = v.experience
    --     cur.shop_id = cur.shop_id
    -- if curData and curData.data and curData.progressData then
    --     local curMaxExp = curData.progressData.curMaxExp or 1
    --     local curExp = curData.progressData.curExp or 1
    --     local beforeExp = curData.progressData.beforeExp or 0
    --     -- "InstanceNewMilepostUI(Clone)/RootPanel/milestonePanel/title/info/currentProg/prog", "Slider"
    --     self:GetComp("RootPanel/milestonePanel/title/info/currentProg/prog", "Slider").value = (curExp - beforeExp) / (curMaxExp - beforeExp)
    --     self:SetText("RootPanel/milestonePanel/title/info/currentProg/prog/progPoint/limit", tostring(curMaxExp))
    --     self:SetText("RootPanel/milestonePanel/title/info/currentProg/prog/progPoint/progress", tostring(CycleInstanceModel:GetCurInstanceKSLevel()))
    --     self:SetText("RootPanel/milestonePanel/title/info/progLevel/progress", tostring(curData.data.level or 1))
    --     self:SetText("RootPanel/milestonePanel/title/info/progLevel/limit", tostring(#data))
    --     self:SetSprite(self:GetComp("RootPanel/milestonePanel/title/info/currentProg/reward/icon", "Image"), "UI_Shop", curData.data.icon)
    -- end
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.m_data = data
    self.m_list:UpdateData()
    local scrollIndex = index or 1
    if not index then
        local isHaveNoClaimed = false
            --这里要获取当前没有领取的奖励
            for i = currentModel:GetCurInstanceKSLevel(), 1, -1 do
                if self.m_data[i] and self.m_data[i].rewardStatus == 3 then
                    scrollIndex = i
                    isHaveNoClaimed = true
                    break
                end
            end
        if not isHaveNoClaimed then
            self.m_list:ScrollTo(currentModel:GetCurInstanceKSLevel())
        else
            self.m_list:ScrollTo(scrollIndex)
        end
    else
        self.m_list:ScrollTo(scrollIndex)
    end
    
end

function CycleInstanceMilepostUIView:UpdateMilepostRewardList(index, tran)
    
    index = index + 1
    local go = tran.gameObject
    local data = self.m_data[index]
    local doneGo = self:GetGoOrNil(go, "done")
    local nextGo = self:GetGoOrNil(go, "next")
    local claimGo = self:GetGoOrNil(go, "claim")
    local lockGo = self:GetGoOrNil(go, "lock")
    local curGo = nil
    if data.rewardStatus == 1 then
        curGo = lockGo
    elseif data.rewardStatus == 2 then
        curGo = nextGo
    elseif data.rewardStatus == 3 then
        curGo = claimGo
    elseif data.rewardStatus == 4 then
        curGo = doneGo
    end
    doneGo:SetActive(data.rewardStatus == 4)
    nextGo:SetActive(data.rewardStatus == 2)
    claimGo:SetActive(data.rewardStatus == 3)
    lockGo:SetActive(data.rewardStatus == 1)

    --step.1设置等级
    self:SetText(curGo, "block/level/num", tostring(data.level))
    --step.2设置数量
    self:SetText(curGo, "block/reward/num", tostring(data.count))
    --setp.3设置icon
    self:SetSprite(self:GetComp(curGo, "block/reward/icon", "Image"), "UI_Shop", data.icon)

    local curBtn = self:GetComp(curGo, "block/reward", "Button")
    if curBtn then
        curBtn.interactable = true
        self:SetButtonClickHandler(curBtn, function()
            if data.rewardStatus == 3 then
                curBtn.interactable = false
                local currentModel = CycleInstanceDataManager:GetCurrentModel()
                local rewards = currentModel:GetRewardByLevel(data.level)
                if rewards and next(rewards) ~= nil then
                    local getFlag, dispRewards = currentModel:RealGetRewardByLevel(data.level)
                    if getFlag then
                        GameTableDefine.CycleInstanceRewardUI:ShowGetReward(rewards)
                        GameTableDefine.CycleIslandMainViewUI:Refresh()
                    end
                end
            elseif data.rewardStatus == 1 or data.rewardStatus == 2 then
                self:OpenRewardInfo(curGo, data)
            end
        end)
    end
end

function CycleInstanceMilepostUIView:OpenRewardInfo(curGo, rewardInfoData)
    local infoGo = self:GetGoOrNil("reward")
    if infoGo.isActive then
        return
    end
    -- cur.info.infoTitle = infoTitle
    --     cur.info.infoDesc = infoDesc
    if infoGo and rewardInfoData.info then
        self:SetText("reward/rewardInfo/title/txt", rewardInfoData.info.infoTitle or "Title-Null")
        self:SetText("reward/rewardInfo/fix/txt", rewardInfoData.info.infoDesc or "Desc-Null")
        local locationPos = self:GetGoOrNil(curGo, "block/reward/pivot")
        local rewardInfoGo = self:GetGoOrNil("reward/rewardInfo")
        if rewardInfoGo and locationPos then
            rewardInfoGo.transform.position = locationPos.transform.position
        end
        infoGo:SetActive(true)
    end
end

return CycleInstanceMilepostUIView