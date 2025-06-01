--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 15:57:17
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local InstanceDataManager = GameTableDefine.InstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local InstanceModel = GameTableDefine.InstanceModel

local RewardLevelToColor = {
    [1] = "#00C3DB",
    [2] = "#DBEC00",
    [3] = "#FF9BF5",
    [4] = "#F83232"
}

---@class InstanceMilepostUIView:UIBaseView
local InstanceMilepostUIView = Class("InstanceMilepostUIView", UIView)

function InstanceMilepostUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_curLevel = 0
    self.m_claimBtn = nil ---@type UnityEngine.UI.Button
    self.m_bottomGO = nil ---@type UnityEngine.GameObject
    self.m_rewardList = nil ---@type UnityEngine.UI.ScrollRectEx
end

function InstanceMilepostUIView:OnEnter()

    --self:SetButtonClickHandler(self:GetComp("reward","Button"), function()
    --    self:GetGo("reward"):SetActive(false)
    --end)

    self.m_timer = GameTimer:CreateNewTimer(1,function ()
        --self:Show()
        self:ShowTimeRemaining()
    end,true,true)

    --数据准备
    local currentLevelScore = InstanceDataManager:GetCurInstanceScore()
    local currentAchievement = InstanceDataManager:GetCurInstanceKSLevel()
    local maxLevel = InstanceModel:GetMaxAchievementLevel()

    local targetLevel = currentAchievement + 1
    if currentAchievement >=  maxLevel then
        targetLevel = maxLevel
    end
    self.m_curLevel = currentAchievement

    local achievementConfig = InstanceDataManager.config_achievement_instance[targetLevel]
    local currentLevelScoreMax = achievementConfig.condition


    self.m_claimBtn = self:GetComp("RootPanel/bottom/RewardBtn","Button")
    self.m_bottomGO = self:GetGo("RootPanel/bottom")
    self:SetButtonClickHandler(self.m_claimBtn,handler(self,self.OnClaimBtnDown))

    self:InitHead(currentLevelScore,currentLevelScoreMax)
    self:InitReward()
    self:RefreshClaimBtn()
end

function InstanceMilepostUIView:OnExit()
    if self.m_timer then
        GameTimer:_RemoveTimer(self.m_timer)
    end
	self.super:OnExit(self)
end

function InstanceMilepostUIView:InitHead(currentLevelScore,currentLevelScoreMax)

    self:SetButtonClickHandler(self:GetComp("RootPanel/head/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    local slider = self:GetComp("RootPanel/head/currentProg/prog","Slider")
    slider.value = currentLevelScore/currentLevelScoreMax

    local currentLevelScoreStr = Tools:SeparateNumberWithComma(currentLevelScore)
    local currentLevelScoreMaxStr = Tools:SeparateNumberWithComma(currentLevelScoreMax)
    self:SetText("RootPanel/head/currentProg/prog/prog_txt/progress",currentLevelScoreStr)
    self:SetText("RootPanel/head/currentProg/prog/prog_txt/limit",currentLevelScoreMaxStr)
    self:SetText("RootPanel/head/level/num",self.m_curLevel)
end

function InstanceMilepostUIView:InitReward()
    local slider = self:GetComp("RootPanel/reward/list/Viewport/Content/progbar","Slider")
    local curLevel = InstanceDataManager:GetCurInstanceKSLevel()
    local isMaxLevel = false
    local levels = #InstanceDataManager.config_achievement_instance
    if curLevel == levels then
        isMaxLevel = true
    end
    local nextLevel
    if isMaxLevel then
        nextLevel = curLevel
    else
        nextLevel = curLevel+1
    end
    local nextLevelCfg = InstanceDataManager.config_achievement_instance[nextLevel]
    local curLevelScore = InstanceDataManager:GetCurInstanceScore()
    local nextLevelNeedScore = nextLevelCfg.condition
    if curLevel == 0 then
        slider.value = (curLevelScore/nextLevelNeedScore * 0.5)/(levels-0.5)
    else
        slider.value = (curLevel -0.5 + curLevelScore/nextLevelNeedScore * 1)/(levels-0.5)
    end

    self.m_rewardList = self:GetComp("RootPanel/reward/list","ScrollRectEx")
    self:SetListItemCountFunc(self.m_rewardList, function()
        return #InstanceDataManager.config_achievement_instance
    end)
    self:SetListItemNameFunc(self.m_rewardList, function(index)
        return "temp"
    end)
    self:SetListUpdateFunc(self.m_rewardList, handler(self, self.UpdateListItem))
    self.m_rewardList:UpdateData(true)
    self.m_rewardList:ScrollTo(curLevel-1)
    slider.gameObject:SetActive(true)
end

function InstanceMilepostUIView:RefreshClaimBtn()
    self.m_bottomGO:SetActive(InstanceDataManager:IsAnyRewardCanClaim())
end

---@param index number
---@param tran UnityEngine.Transform
function InstanceMilepostUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject

    local achievementConfig = InstanceDataManager.config_achievement_instance[index]
    local rewardConfig = InstanceDataManager.config_rewardType_instance[achievementConfig.reward_id][1]
    local level = achievementConfig.level

    local onGoingGO = self:GetGo(go,"ongoing")
    local claimGO = self:GetGo(go,"claim")
    local doneGO = self:GetGo(go,"done")

    local showGO
    if level<=self.m_curLevel then
        if InstanceDataManager:IsRewardClaimed(level) then
            showGO = doneGO
        else
            showGO = claimGO
            local claimBtn = self:GetComp(claimGO,"block/reward","Button")
            self:SetButtonClickHandler(claimBtn,function()
                self:OnLevelRewardBtnDown(level)
            end)
        end
    else
        showGO = onGoingGO
        local lightImage = self:GetComp(onGoingGO,"block/reward/light","Image")
        if lightImage then
            local colorStr = RewardLevelToColor[rewardConfig.type] or RewardLevelToColor[1]
            local color = UnityHelper.GetColor(colorStr,lightImage.color.a)
            lightImage.color = color
        end
    end

    onGoingGO:SetActive(onGoingGO == showGO)
    claimGO:SetActive(claimGO == showGO)
    doneGO:SetActive(doneGO == showGO)
    --显示对应里程碑等级
    self:SetText(showGO,"level/num",level)
    --显示对应奖励的等级图标
    local qualityIcon = self:GetComp(showGO,"block/quality","Image")
    self:SetSprite(qualityIcon,"UI_Common",rewardConfig.quality)
    --显示对应奖励的宝箱图标
    local rewardIcon = self:GetComp(showGO,"block/reward/icon","Image")
    self:SetSprite(rewardIcon,"UI_Common",rewardConfig.icon,nil,nil,true)
    --显示对应奖励的宝箱数量
    self:SetText(showGO,"block/reward/num","x"..achievementConfig.reward_num)

    --显示可能
    self:ShowMaybe(showGO,achievementConfig)
end

function InstanceMilepostUIView:ShowMaybe(itemRootGO,achievementConfig)
    --显示可能
    local rewards = self:GetRewardPreview(achievementConfig.reward_id)
    local maybePrefab = self:GetGo(itemRootGO,"block/info/list/item")
    Tools:SetTempGo(maybePrefab,#rewards.maybe,true,function(go,index)
        local rewardCfg = rewards.maybe[index]
        local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
        local image = self:GetComp(go,"icon","Image")
        local resType = ResourceManger:GetShopCashType(shopCfg.country)
        local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
        self:SetSprite(image, "UI_Shop", icon, nil, true)

        if shopCfg.type == 9 then
            local resType = ResourceManger:GetShopCashType(shopCfg.country)
            local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
            self:SetSprite(image, "UI_Shop", icon, nil, true)
            self:SetText(go,"num","x"..shopCfg.amount.."H")
        else
            self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
            self:SetText(go,"num","x"..shopCfg.amount)
        end
    end)
end

---获取某等级的奖励
function InstanceMilepostUIView:OnLevelRewardBtnDown(level)
    if InstanceDataManager:SetRewardClaimed(level) then
        local rewards = InstanceModel:GetRewardByLevel(level,true)
        if rewards and next(rewards)~=nil then
            InstanceDataManager:OpenAllEggsRewardToGet(rewards,true)
            --step2.打开奖励面板
            GameTableDefine.InstanceRewardUI:Show(function()
                self.m_rewardList:UpdateData(true)
                self:RefreshClaimBtn()
                if GameTableDefine.InstanceMainViewUI.m_view then
                    GameTableDefine.InstanceMainViewUI.m_view:RefreshMilepost()
                end
            end)
        end
    end
end

---获取全部奖励
function InstanceMilepostUIView:OnClaimBtnDown()
    local anyRewardCanClaim = InstanceDataManager:IsAnyRewardCanClaim()
    if anyRewardCanClaim then
        local rewards = InstanceModel:GetRewardNotOpened()
        if rewards and next(rewards)~=nil then
            InstanceDataManager:SetAllRewardClaimed()
            InstanceDataManager:OpenAllEggsRewardToGet(rewards,true)
            --step2.打开奖励面板
            GameTableDefine.InstanceRewardUI:Show(function()
                self.m_rewardList:UpdateData(true)
                self:RefreshClaimBtn()
                if GameTableDefine.InstanceMainViewUI.m_view then
                    GameTableDefine.InstanceMainViewUI.m_view:RefreshMilepost()
                end
            end)
        end
    end
end

--function InstanceMilepostUIView:Show()
--    --tital
--    self:SetButtonClickHandler(self:GetComp("RootPanel/title/HeadPanel/bg/title","Button"),function()
--        self:GetGo("tipsPanel"):SetActive(true)
--    end)
--
--    local state = InstanceDataManager:GetInstanceState()
--    local TimeRemaining = 0
--
--    --banner
--    local nextAchievementConfig = self:GetNextAchievementConfig()
--    local rewardLevel = nextAchievementConfig.reward_id
--    self:ShowRewardBannerByID(rewardLevel,nextAchievementConfig)
--
--    local currentEx = InstanceDataManager:GetCurInstanceScore()
--    local maxEx = nextAchievementConfig.condition
--    local currentExStr = Tools:SeparateNumberWithComma(currentEx)
--    local maxExStr = Tools:SeparateNumberWithComma(maxEx)
--    self:SetText("RootPanel/banner/bg/prog/bg/prog_num/num",currentExStr)
--    self:SetText("RootPanel/banner/bg/prog/bg/prog_num/limit",maxExStr)
--    self:GetComp("RootPanel/banner/bg/prog","Slider").value = currentEx / maxEx
--
--    --Rewards
--    local rewardsRoot = self:GetGo("RootPanel/rewards")
--    local rewardConfig = InstanceDataManager.config_rewardType_instance[rewardLevel][1]
--    for i=1,12 do
--        local go = self:GetGo(rewardsRoot,"item"..i)
--        rewardConfig = InstanceDataManager.config_rewardType_instance[InstanceDataManager.config_achievement_instance[i].reward_id][1]
--
--        self:SetText(go,"num/txt",InstanceDataManager.config_achievement_instance[i].reward_num)
--        self:SetText(go,"unlocked/num/txt",InstanceDataManager.config_achievement_instance[i].reward_num)
--        self:SetText(go,"now/num/txt",InstanceDataManager.config_achievement_instance[i].reward_num)
--        self:GetGo(go,"unlocked"):SetActive(nextAchievementConfig.level > i)
--        self:GetGo(go,"now"):SetActive(nextAchievementConfig.level == i)
--
--        self:SetSprite(self:GetComp(go,"level","Image"), "UI_Common", rewardConfig.quality, nil, true)
--        self:SetSprite(self:GetComp(go,"orna/icon","Image"), "UI_Common", rewardConfig.icon, nil, true)
--
--        self:SetButtonClickHandler(self:GetComp(go,"","Button"),function(...)
--            local rewardGO = self:GetGo("reward")
--            rewardGO:SetActive(true)
--            local rewardInfo = self:GetGo(rewardGO,"rewardInfo")
--            local locationPos = self:GetGo(go,"locationPos")
--            rewardInfo.transform.position = locationPos.transform.position
--            local achievementConfig = InstanceDataManager.config_achievement_instance[i]
--            local rewards = self:GetRewardPreview(achievementConfig.reward_id)
--            local arg = ...
--            self:SetText("reward/rewardInfo/title/txt",GameTextLoader:ReadText(arg[1]))
--
--            --显示保底
--            self:GetGo("reward/rewardInfo/fix"):SetActive(#rewards.atLeast > 0)
--
--            local atLeastPrefab = self:GetGo("reward/rewardInfo/fix/reward/temp")
--            Tools:SetTempGo(atLeastPrefab,#rewards.atLeast,true,function(go,index)
--                local rewardCfg = rewards.atLeast[index]
--                local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
--                local image = self:GetComp(go,"icon","Image")
--
--                if shopCfg.type == 9 then
--                    local resType = ResourceManger:GetShopCashType(shopCfg.country)
--                    local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
--                    self:SetSprite(image, "UI_Shop", icon, nil, true)
--                    self:SetText(go,"num",shopCfg.amount.."H")
--                else
--                    self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
--                    self:SetText(go,"num",shopCfg.amount)
--                end
--            end)
--            --显示可能
--            self:GetGo("reward/rewardInfo/random"):SetActive(#rewards.maybe > 0)
--
--            local maybePrefab = self:GetGo("reward/rewardInfo/random/reward/temp")
--            Tools:SetTempGo(maybePrefab,#rewards.maybe,true,function(go,index)
--                local rewardCfg = rewards.maybe[index]
--                local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
--                local image = self:GetComp(go,"icon","Image")
--                local resType = ResourceManger:GetShopCashType(shopCfg.country)
--                local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
--                self:SetSprite(image, "UI_Shop", icon, nil, true)
--
--                if shopCfg.type == 9 then
--                    local resType = ResourceManger:GetShopCashType(shopCfg.country)
--                    local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
--                    self:SetSprite(image, "UI_Shop", icon, nil, true)
--                    self:SetText(go,"num",shopCfg.amount.."H")
--                else
--                    self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
--                    self:SetText(go,"num",shopCfg.amount)
--                end
--            end)
--
--        end,nil, rewardConfig.name)
--    end
--end

function InstanceMilepostUIView:ShowTimeRemaining()

    local timeRemaining = InstanceDataManager:GetLeftInstanceTime()
    local d =  timeRemaining // 86400
    local h = math.floor( timeRemaining % 86400 / 3600 )
    local m = math.floor( timeRemaining % 86400 % 3600 /60 )

    local timeStr =  string.format("%dd%dh%dm",d,h,m)

    self:SetText("RootPanel/head/time/time",timeStr)
end

function InstanceMilepostUIView:GetNextAchievementConfig()
    local nextLevel = self:GetNextRewardLevel()
    return InstanceDataManager.config_achievement_instance[nextLevel]
end

--获取下一级的成就等级
function InstanceMilepostUIView:GetNextRewardLevel()
    local maxlevel = Tools:GetTableSize(InstanceDataManager.config_achievement_instance)
    local currentAchievementLevel = InstanceDataManager:GetCurInstanceKSLevel()
    local nextlevel = currentAchievementLevel+1
    if currentAchievementLevel == maxlevel then
        nextlevel = currentAchievementLevel
    end
    local nextAchievementData = InstanceDataManager.config_achievement_instance[nextlevel]

    return nextAchievementData.level
end

----根据奖励等级显示banner
--function InstanceMilepostUIView:ShowRewardBannerByID(level,nextAchievementConfig)
--    local curBanner = nil
--    local bannerList = {
--        self:GetGo("RootPanel/banner/bg/banner_C"),
--        self:GetGo("RootPanel/banner/bg/banner_B"),
--        self:GetGo("RootPanel/banner/bg/banner_A"),
--        self:GetGo("RootPanel/banner/bg/banner_S")
--    }
--    for i, banner in ipairs(bannerList) do
--        banner:SetActive(level == i)
--        self:SetText(banner,"reward/num","x"..nextAchievementConfig.reward_num)
--        if level == i then
--            curBanner = banner
--        end
--    end
--
--    -- 显示奖励预览
--    local rewards = self:GetRewardPreview(nextAchievementConfig.reward_id)
--    local maybePrefab = self:GetGo(curBanner,"reward_list/list/item")
--    Tools:SetTempGo(maybePrefab,#rewards.maybe,true,function(go,index)
--        local rewardCfg = rewards.maybe[index]
--        local shopCfg = ConfigMgr.config_shop[rewardCfg.shop_id]
--        local image = self:GetComp(go,"icon","Image")
--        local resType = ResourceManger:GetShopCashType(shopCfg.country)
--        local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
--        self:SetSprite(image, "UI_Shop", icon, nil, true)
--
--        if shopCfg.type == 9 then
--            local resType = ResourceManger:GetShopCashType(shopCfg.country)
--            local icon = ResourceManger:GetShopCashIcon(resType,shopCfg.icon)
--            self:SetSprite(image, "UI_Shop", icon, nil, true)
--            self:SetText(go,"num",shopCfg.amount.."H")
--        else
--            self:SetSprite(image, "UI_Shop", shopCfg.icon, nil, true)
--            self:SetText(go,"num",shopCfg.amount)
--        end
--    end)
--end


--获取奖励预览数据
function InstanceMilepostUIView:GetRewardPreview(rewardType)
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
    return result
end

return InstanceMilepostUIView