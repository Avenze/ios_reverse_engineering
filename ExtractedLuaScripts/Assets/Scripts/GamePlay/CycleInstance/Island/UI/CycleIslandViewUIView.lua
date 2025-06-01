local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local ResourceManger = GameTableDefine.ResourceManger

local CycleIslandViewUIView = Class("CycleIslandViewUIView", UIView)

function CycleIslandViewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.instanceData = {}
    self.tiemr = nil
    self.rewardsDetails = nil
end

function CycleIslandViewUIView:OnEnter()
    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.rewardsDetails = self:GetGo("reward")
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"),function()
        self:DestroyModeUIObject()
        end
    )
    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self.rewardsDetails:SetActive(false)
    end)

    self.m_list = self:GetComp("background/BottomPanel/list", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data
    end)

    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateMilepostRewardList))
    self:SetListItemNameFunc(self.m_list, function(index)
        return "temp"
    end)
    --埋点:查看副本详情
    local buildingID = CityMode:GetCurrentBuilding()
    GameSDKs:TrackForeign("rank_activity", {name = "CycleInstance", operation = "1", score_new = tonumber(self.m_currentModel:GetCurInstanceKSLevel()) or 0, scene_id = buildingID})

end


function CycleIslandViewUIView:OnExit()
    if self.tiemr then
        GameTimer:_RemoveTimer(self.tiemr)
    end
    self.super:OnExit(self)
end

function CycleIslandViewUIView:InitView(instanceData)
    self.instanceData = instanceData
    local state = CycleInstanceDataManager:GetInstanceState()
    self.tiemr = GameTimer:CreateNewTimer(1,function()
            local timeRemaining = 0
            if state == CycleInstanceDataManager.instanceState.isActive then
                timeRemaining = CycleInstanceDataManager:GetLeftInstanceTime()
            else
                timeRemaining = CycleInstanceDataManager:GetInstanceRewardTime()
            end
            -- local h = os.date("%d", timeRemaining) * 24 + os.date("%H", timeRemaining)
            -- local m = os.date("%M", timeRemaining)
            local timeStr =  GameTimeManager:FormatTimeLength(timeRemaining)
            self:SetText("background/HeadPanel/banner/timer/num", timeStr)
        end,true,true)

    local locked = self:GetInstanceLocked()
    self:GetGo("background/HeadPanel/banner/locked"):SetActive(locked)
    if (state == CycleInstanceDataManager.instanceState.isActive or state == CycleInstanceDataManager.instanceState.awartable) and not locked then --已解锁

        self:GetGo("background/BottomPanel"):SetActive(true)
        self:GetGo("background/HeadPanel/banner/locked"):SetActive(false)

        self:ShowAchievementReward(state,locked)
    elseif locked then --未解锁
        --self:GetGo("background/HeadPanel/banner/timer"):SetActive(false)
        -- self:GetGo("background/HeadPanel/banner/milestone"):SetActive(false)
        self:GetGo("background/BottomPanel"):SetActive(false)
        self:GetGo("background/HeadPanel/banner/locked"):SetActive(true)
        --self:ShowAchievementReward(state,locked)
    end
end

function CycleIslandViewUIView:ShowAchievementReward(state,locked)

    --显示所有奖励
    local prefab = self:GetGo("background/BottomPanel/list/Viewport/Content/temp")
    self.m_data = GameTableDefine.CycleInstanceMilepostUI:CalculateData()
    self.m_list:UpdateData()
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    self:SetRewardProgress(currentModel:GetCurInstanceKSLevel(), #self.m_data)
    self:ShowButton(state,{})
    --判断当前是否有可领取的里程碑奖励，有的话直接点跳转过去
    local turnToIndex = currentModel:GetCurInstanceKSLevel()
    if turnToIndex == 0 then
        turnToIndex = 1
    end
    if turnToIndex >= Tools:GetTableSize(self.m_data) then
        turnToIndex = Tools:GetTableSize(self.m_data)
    end
    self:TurnPage(turnToIndex)
end

function CycleIslandViewUIView:GetAllRewardCount()
    local rewards = {}
    for k,v in pairs(CycleInstanceDataManager.config_achievement_instance) do
        rewards[v.reward_id] = (rewards[v.reward_id] or 0) + v.reward_num
    end

    return rewards
end

function CycleIslandViewUIView:ShowButton(state,rewards)
    if state == CycleInstanceDataManager.instanceState.isActive then
        --活动进行中,显示前往
        self:GetGo("background/BottomPanel/btn/gotoBtn"):SetActive(true)
        self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(false)
        self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/gotoBtn","Button"),function()
            --前往副本场景
            if self.m_currentGameState ~= GameStateManager.GAME_STATE_CYCLE_INSTANCE then
                GameStateManager:SetCurrentGameState(GameStateManager.GAME_STATE_CYCLE_INSTANCE)
            else
                EventManager:DispatchEvent("BACK_TO_SCENE")
                GameTableDefine.CityMode:EnterDefaultBuiding()
            end

            self:DestroyModeUIObject()
        end)
    elseif state == CycleInstanceDataManager.instanceState.awartable then
        
        self:GetGo("background/BottomPanel/btn/gotoBtn"):SetActive(false)

        local currentModel = CycleInstanceDataManager:GetCurrentModel()
        local allRewards = currentModel:GetAllSKRewardNotClaim()
        if Tools:GetTableSize(allRewards) <= 0 then
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(true)
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/confirmBtn","Button"),function()
                CycleInstanceDataManager:SetNoRewardFlag()
                self:DestroyModeUIObject()
                GameTableDefine.MainUI:CloseInstanceEntry()
            end)
        else
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(true)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(false)
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/claimBtn","Button"),function()
                GameTableDefine.CycleInstanceRewardUI:ShowAllNotClaimRewardsGet()
                CycleInstanceDataManager:SetNoRewardFlag()
                self:DestroyModeUIObject()
                GameTableDefine.MainUI:CloseInstanceEntry()
                
                --埋点:副本领奖
                GameSDKs:TrackForeign("rank_activity", {name = "CycleInstance", operation = "2", score_new = tonumber(self.m_currentModel:GetCurInstanceKSLevel()) or 0})

            end)
        end
        
    end
end

function CycleIslandViewUIView:ShowRewardsDetails(rewardType,name,go)
    local root = self.rewardsDetails
    local locationPos = self:GetGo(go,"locationPos")
    local view = self:GetGo(root,"rewardInfo")
    view.transform.position = locationPos.transform.position

    self.rewardsDetails:SetActive(true)
    local list = CycleInstanceDataManager.config_rewardType_instance[rewardType]
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

function CycleIslandViewUIView:GetInstanceLocked()
    return not CityMode:CheckBuildingSatisfy(200)
end

function CycleIslandViewUIView:UpdateMilepostRewardList(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.m_data[index]
    local doneGo = self:GetGoOrNil(go, "done")
    local claimGo = self:GetGoOrNil(go, "claim")
    local lockGo = self:GetGoOrNil(go, "lock")
    local curGo = nil
    if data.rewardStatus == 1 or data.rewardStatus == 2 then
        curGo = lockGo
    elseif data.rewardStatus == 3 then
        curGo = claimGo
    elseif data.rewardStatus == 4 then
        curGo = doneGo
    end
    doneGo:SetActive(data.rewardStatus == 4)
    claimGo:SetActive(data.rewardStatus == 3)
    lockGo:SetActive(data.rewardStatus == 1 or data.rewardStatus == 2)

    self:SetText(curGo, "level/num", tostring(data.level))
    self:SetText(curGo, "block/reward/num", tostring(data.count))
    self:SetSprite(self:GetComp(curGo, "block/reward/icon", "Image"), "UI_Shop", data.icon)
    local btn = self:GetComp(curGo, "block/reward", "Button")
    self:SetButtonClickHandler(btn, function()
        self:OpenRewardInfo(curGo, data)
    end)
end

function CycleIslandViewUIView:SetRewardProgress(curLevel, totalLevel)
    if totalLevel <= 0 then
        return
    end
    local proGo = self:GetGo("background/BottomPanel/list/Viewport/Content/prog")
    proGo:SetActive(true)
    local proRectTransform = self:GetComp("background/BottomPanel/list/Viewport/Content/prog","RectTransform")
    -- local sizeDelta = proGo.transform.RectTransform.sizeDelta
    -- proGo.transform.RectTransform.width 
    local sizeDelta = proRectTransform.sizeDelta
    sizeDelta.x = 170 * (totalLevel - 1)
    proRectTransform.sizeDelta = sizeDelta
    local proSlider = self:GetComp("background/BottomPanel/list/Viewport/Content/prog", "Slider")
    proSlider.value = curLevel / totalLevel
    self:GetComp("background/HeadPanel/banner/prog", "Slider").value = curLevel / totalLevel
    self:SetText("background/HeadPanel/banner/prog/progPoint/progress", curLevel)
    self:SetText("background/HeadPanel/banner/prog/progPoint/limit", totalLevel) 
end

function CycleIslandViewUIView:OpenRewardInfo(curGo, rewardInfoData)
    local infoGo = self:GetGoOrNil("reward")
    if infoGo.isActive then
        return
    end

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

function CycleIslandViewUIView:TurnPage(index)
    -- if self.__timers["TurnPage"] then
    --     GameTimer:StopTimer(self.__timers["TurnPage"])
    --     self.__timers["TurnPage"] = nil
    -- end
    -- self.__timers["TurnPage"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        
    -- end)
    self.m_list:ScrollTo(index or 0, 2)
end

return CycleIslandViewUIView
