local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local ResourceManger = GameTableDefine.ResourceManger

local InstanceViewUIView = Class("InstanceViewUIView", UIView)

function InstanceViewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.instanceData = {}
    self.tiemr = nil
    self.rewardsDetails = nil
end

function InstanceViewUIView:OnEnter()
    self.rewardsDetails = self:GetGo("reward")
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"),function()
        self:DestroyModeUIObject()
        end
    )
    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self.rewardsDetails:SetActive(false)
    end)

    --埋点:查看副本详情
    local buildingID = CityMode:GetCurrentBuilding()
    GameSDKs:TrackForeign("rank_activity", {name = "LimitInstance", operation = "1", score_new = tonumber(InstanceDataManager:GetCurInstanceKSLevel()) or 0, scene_id = buildingID})

end


function InstanceViewUIView:OnExit()
    if self.tiemr then
        GameTimer:_RemoveTimer(self.tiemr)
    end
    self.super:OnExit(self)
end

function InstanceViewUIView:InitView(instanceData)
    self.instanceData = instanceData
    local state = InstanceDataManager:GetInstanceState()
    self.tiemr = GameTimer:CreateNewTimer(1,function()
            local timeRemaining = 0
            if state == InstanceDataManager.instanceState.isActive then
                timeRemaining = InstanceDataManager:GetLeftInstanceTime()
            else
                timeRemaining = InstanceDataManager:GetInstanceRewardTime()
            end
            -- local h = os.date("%d", timeRemaining) * 24 + os.date("%H", timeRemaining)
            -- local m = os.date("%M", timeRemaining)
            local timeStr =  GameTimeManager:FormatTimeLength(timeRemaining)
            self:SetText("background/HeadPanel/banner/timer/num", timeStr)
        end,true,true)

    local locked = self:GetInstanceLocked()
    if (state == InstanceDataManager.instanceState.isActive or state == InstanceDataManager.instanceState.awartable) and not locked then --已解锁
        --self:GetGo("background/HeadPanel/banner/timer"):SetActive(true)
        self:GetGo("background/HeadPanel/banner/milestone"):SetActive(true)
        self:GetGo("background/BottomPanel"):SetActive(true)
        self:GetGo("background/HeadPanel/banner/locked"):SetActive(false)

        --显示进度和进度条
        local achievementConfig = InstanceDataManager.config_achievement_instance
        local achievementLevel = InstanceDataManager:GetCurInstanceKSLevel()
        local slider = self:GetComp("background/HeadPanel/banner/milestone/Slider","Slider")
        local tableLenguth = Tools:GetTableSize(achievementConfig)
        slider.value = achievementLevel/tableLenguth
        self:SetText("background/HeadPanel/banner/milestone/prog_txt/progress",achievementLevel)
        self:SetText("background/HeadPanel/banner/milestone/prog_txt/limit",tableLenguth)
        self:SetText("background/HeadPanel/banner/milestone/Slider/Background/Fill Area/icon/num", achievementLevel)
        self:GetGo("background/HeadPanel/banner/milestone/prog_txt"):SetActive(false)
        local targetPosUI = self:GetGo("background/HeadPanel/banner/milestone/Slider/Background/Fill Area/bg").transform:GetChild(achievementLevel).gameObject
        local targetPosUIRect = self:GetComp(targetPosUI, "", "RectTransform")
        self:GetComp("background/HeadPanel/banner/milestone/Slider/Background/Fill Area/icon", "RectTransform").anchoredPosition  = targetPosUIRect.anchoredPosition
        self:ShowAchievementReward(state,locked)
    elseif locked then --未解锁
        --self:GetGo("background/HeadPanel/banner/timer"):SetActive(false)
        self:GetGo("background/HeadPanel/banner/milestone"):SetActive(false)
        self:GetGo("background/BottomPanel"):SetActive(false)
        self:GetGo("background/HeadPanel/banner/locked"):SetActive(true)
        self:ShowAchievementReward(state,locked)
    end
end

function InstanceViewUIView:ShowAchievementReward(state,locked)

    if state == InstanceDataManager.instanceState.isActive then
        local callback = function(go,id,...)
            local root = go
            local index = id
            local image = self:GetComp(root,"icon","Image")
            local qualityImage = self:GetComp(root,"lv","Image")
            --设置图片
            local awardConfig = InstanceDataManager.config_rewardType_instance[id][1]
            self:SetSprite(image, "UI_Common", awardConfig.icon, nil, true)
            self:SetSprite(qualityImage, "UI_Common", awardConfig.quality, nil, true)
            --设置数量
            local all = self:GetAllRewardCount()
            local count = all[index] or 0
            self:SetText(root,"count/num",count)
            --设置彩蛋点击事件
            local btn = self:GetComp(root,"","Button")
            self:SetButtonClickHandler(btn,function(...)
                self:ShowRewardsDetails(index,awardConfig.name,root)
            end,nil,awardConfig.name)
        end
        --显示所有奖励
        local prefab = self:GetGo("background/BottomPanel/preview/reward/temp")
        local rewaedTypeCount = Tools:GetTableSize(InstanceDataManager.config_rewardType_instance)
        Tools:SetTempGo(prefab,rewaedTypeCount,true,callback)
        self:ShowButton(state,{})

    elseif state == InstanceDataManager.instanceState.awartable then
        local callback = function(go,id,...)
            local root = go
            local index = id
            local image = self:GetComp(root,"icon","Image")
            local qualityImage = self:GetComp(root,"lv","Image")
            --设置图片
            local awardConfig = InstanceDataManager.config_rewardType_instance[id][1]
            self:SetSprite(image, "UI_Common", awardConfig.icon, nil, true)
            self:SetSprite(qualityImage, "UI_Common", awardConfig.quality, nil, true)
            --设置数量
            local arg_Level = select (1,...)
            local level = arg_Level
            local all = InstanceModel:GetLevelReward(level)
            local count = all[index] or 0
            self:SetText(root,"count/num",count)
            --设置彩蛋点击事件
            -- local btn = self:GetComp(root,"Button")
            local btn = root:GetComponent("Button")
            self:SetButtonClickHandler(btn,function()
                self:ShowRewardsDetails(index,awardConfig.name,root)
            end)
        end
        --显示获得的奖励,不包括已经开启的奖励
        local prefab = self:GetGo("background/BottomPanel/preview/reward/temp")
        local currentLevel = InstanceDataManager:GetCurInstanceKSLevel()
        local rewards = InstanceModel:GetRewardNotOpened()
        local count = #rewards
        Tools:SetTempGo(prefab,count,true,callback,currentLevel)
        self:ShowButton(state,rewards)
    end

end

function InstanceViewUIView:GetAllRewardCount()
    local rewards = {}
    for k,v in pairs(InstanceDataManager.config_achievement_instance) do
        rewards[v.reward_id] = (rewards[v.reward_id] or 0) + v.reward_num
    end

    return rewards
end

function InstanceViewUIView:ShowButton(state,rewards)
    if state == InstanceDataManager.instanceState.isActive then
        --活动进行中,显示前往
        self:GetGo("background/BottomPanel/btn/gotoBtn"):SetActive(true)
        self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(false)
        self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/gotoBtn","Button"),function()
            --前往副本场景
            if self.m_currentGameState ~= GameStateManager.GAME_STATE_INSTANCE then
                GameStateManager:SetCurrentGameState(GameStateManager.GAME_STATE_INSTANCE)
            else
                EventManager:DispatchEvent("BACK_TO_SCENE")
                GameTableDefine.CityMode:EnterDefaultBuiding()
            end

            self:DestroyModeUIObject()
        end)
    elseif state == InstanceDataManager.instanceState.awartable then
        if Tools:GetTableSize(rewards) <= 0 then --没有奖品,显示确认
            self:GetGo("background/BottomPanel/btn/gotoBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(true)
            if( InstanceDataManager:GetCurInstanceKSLevel() > 0) then
                self:GetGo("background/BottomPanel/preview/noreward"):SetActive(false)
                self:GetGo("background/BottomPanel/preview/claimed"):SetActive(true)
            else
                self:GetGo("background/BottomPanel/preview/noreward"):SetActive(true)
                self:GetGo("background/BottomPanel/preview/claimed"):SetActive(false)
            end
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/confirmBtn","Button"),function()
                InstanceDataManager:SetNoRewardFlag()
                --没有奖励就直接关闭该界面了
                self:DestroyModeUIObject()
                GameTableDefine.MainUI:CloseInstanceEntry()
            end)
        else    --有奖品,显示领奖
            self:GetGo("background/BottomPanel/btn/gotoBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(true)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(false)
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/claimBtn","Button"),function()
                self:DestroyModeUIObject()
                GameTableDefine.MainUI:CloseInstanceEntry()
                --领奖
                --step1.获取奖励给予
                if rewards and Tools:GetTableSize(rewards) > 0 then
                    InstanceDataManager:OpenAllEggsRewardToGet(rewards)
                    --step2.打开奖励面板
                    GameTableDefine.InstanceRewardUI:GetView()
                    --埋点:副本领奖
                    GameSDKs:TrackForeign("rank_activity", {name = "LimitInstance", operation = "2", score_new = tonumber(InstanceDataManager:GetCurInstanceKSLevel()) or 0})

                end

            end)
        end
    end
end

function InstanceViewUIView:ShowRewardsDetails(rewardType,name,go)
    local root = self.rewardsDetails
    local locationPos = self:GetGo(go,"locationPos")
    local view = self:GetGo(root,"rewardInfo")
    view.transform.position = locationPos.transform.position

    self.rewardsDetails:SetActive(true)
    local list = InstanceDataManager.config_rewardType_instance[rewardType]
    local result = {
        atLeast = {},
        maybe = {}
    }
    for k,v in pairs(list) do
        if v.random == 0 then
            table.insert( result.atLeast, v )
        else
            table.insert( result.maybe, v )
        end
    end

    self:SetText("reward/rewardInfo/title/txt",GameTextLoader:ReadText(name))

    --显示保底
    self:GetGo("reward/rewardInfo/fix"):SetActive(#result.atLeast > 0)
    local atLeastPrefab = self:GetGo(root,"rewardInfo/fix/reward/temp")
    Tools:SetTempGo(atLeastPrefab,#result.atLeast,true,function(go,index)
        local rewardCfg = result.atLeast[index]
        local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
        local image = self:GetComp(go,"icon","Image")

        if shopCfg.type == 9 then
            local resType = ResourceManger:GetShopCashType(shopCfg.country)
            local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
            self:SetSprite(image, "UI_Shop", icon, nil, true)
            self:SetText(go,"num",shopCfg.amount.."H")
        else
            self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
            self:SetText(go,"num",shopCfg.amount)
        end
    end)

    --显示可能
    self:GetGo("reward/rewardInfo/random"):SetActive(#result.maybe > 0 )
    local maybePrefab = self:GetGo(root,"rewardInfo/random/reward/temp")
    Tools:SetTempGo(maybePrefab,#result.maybe,true,function(go,index)
        local rewardCfg = result.maybe[index]
        local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
        local image = self:GetComp(go,"icon","Image")

        if shopCfg.type == 9 then
            local resType = ResourceManger:GetShopCashType(shopCfg.country)
            local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
            self:SetSprite(image, "UI_Shop", icon, nil, true)
            self:SetText(go,"num",shopCfg.amount.."H")
        else
            self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
            self:SetText(go,"num",shopCfg.amount)
        end
    end)

end

function InstanceViewUIView:GetInstanceLocked()
    return not CityMode:CheckBuildingSatisfy(200)
end

return InstanceViewUIView
