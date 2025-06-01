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
local CycleCastleRankUI = GameTableDefine.CycleCastleRankUI

local CycleCastleViewUIView = Class("CycleCastleViewUIView", UIView)

function CycleCastleViewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.instanceData = {}
    self.timer = nil
    self.rewardsDetails = nil
end

function CycleCastleViewUIView:OnEnter()
    self.rewardsDetails = self:GetGo("reward")
    self:SetButtonClickHandler(self:GetComp("background/quitBtn", "Button"),function()
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
    GameSDKs:TrackForeign("rank_activity", {name = "CycleInstance", operation = "1", score = tonumber(CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel()), scene_id = buildingID})

    --region 排行榜
    local redPoint = self:GetGo("background/BottomPanel/rank/redpoint")
    redPoint:SetActive(false)
    
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/rank/btn", "Button"),function()
        CycleCastleRankUI:GetView()
    end)
    
    -- 监听排行榜刷新名次
    self:GetGo("background/BottomPanel/rank"):SetActive(false)
    EventManager:RegEvent(GameEventDefine.RefreshCastleRankNum, function(rank_num)
        self:SetText("background/BottomPanel/rank/num", rank_num)
        self:GetGo("background/BottomPanel/rank"):SetActive(true)
    end)

    -- 初始化排行榜
    --if not GameTableDefine.CycleCastleRankManager:IsInit() then
    --    GameTableDefine.CycleCastleRankManager:Init()
    --end

    -- 进入副本引导页事件
    GameTableDefine.CycleCastleRankManager:EnterCycleCastleInstance()

    --- 排行榜 可领取奖励, 没有领取过的，显示 红点
    if GameTableDefine.CycleCastleRankManager:IsInit() then
        self.rank_timer = GameTimer:CreateNewTimer(1, function()
            if not self.rank_timer then
                return
            end
            local rank_red_point_enable = (GameTableDefine.CycleCastleRankManager:GetInstanceState() == CycleInstanceDataManager.instanceState.awartable) and not GameTableDefine.CycleCastleRankManager:HadClaimAward()
            redPoint:SetActive(rank_red_point_enable)
        end, true, true)
    end

    --endregion
end


function CycleCastleViewUIView:OnExit()
    if self.timer then
        GameTimer:StopTimer(self.timer)
    end

    if self.rank_timer then
        GameTimer:StopTimer(self.rank_timer)
        self.rank_timer = nil
    end

    EventManager:UnregEvent(GameEventDefine.RefreshCastleRankNum)
    self.super:OnExit(self)
end

function CycleCastleViewUIView:InitView(instanceData)
    self.instanceData = instanceData
    local state = CycleInstanceDataManager:GetInstanceState()
    self.timer = GameTimer:CreateNewTimer(1, function()
        local timeRemaining = 0
        if state == CycleInstanceDataManager.instanceState.isActive then
            timeRemaining = CycleInstanceDataManager:GetLeftInstanceTime()
        else
            timeRemaining = CycleInstanceDataManager:GetInstanceRewardTime()
        end
        -- local h = os.date("%d", timeRemaining) * 24 + os.date("%H", timeRemaining)
        -- local m = os.date("%M", timeRemaining)
        local timeStr = GameTimeManager:FormatTimeLength(timeRemaining)
        self:SetText("background/Title/timer/num", timeStr)
    end, true, true)

    local locked = self:GetInstanceLocked()
    self:GetGo("background/HeadPanel/banner/locked"):SetActive(locked)
    if (state == CycleInstanceDataManager.instanceState.isActive or state == CycleInstanceDataManager.instanceState.awartable) and not locked then --已解锁

        --self:GetGo("background/BottomPanel"):SetActive(true)
        self:GetGo("background/BottomPanel/locked"):SetActive(false)

        self:ShowAchievementReward(state,locked)
    elseif locked then --未解锁
        --self:GetGo("background/HeadPanel/banner/timer"):SetActive(false)
        -- self:GetGo("background/HeadPanel/banner/milestone"):SetActive(false)
        --self:GetGo("background/BottomPanel"):SetActive(true)
        self:GetGo("background/BottomPanel/locked"):SetActive(true)

        self:ShowAchievementReward(state,locked)
    end
end

function CycleCastleViewUIView:ShowAchievementReward(state,locked)

    --显示所有奖励
    local prefab = self:GetGo("background/BottomPanel/list/Viewport/Content/temp")
    self.m_data = CycleInstanceDataManager:GetCycleInstanceMilepostUI():CalculateData()
    self.m_list:UpdateData() 
    self:SetRewardProgress(CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel(), #self.m_data)
    if locked then
        self:GetGo("background/BottomPanel/btn"):SetActive(false)
    else
        self:ShowButton(state,{})
    end

    --判断当前是否有可领取的里程碑奖励，有的话直接点跳转过去
    local turnToIndex = CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel()
    if turnToIndex == 0 then
        turnToIndex = 1
    end
    if turnToIndex >= Tools:GetTableSize(self.m_data) then
        turnToIndex = Tools:GetTableSize(self.m_data)
    end
    self:TurnPage(turnToIndex)
end

function CycleCastleViewUIView:GetAllRewardCount()
    local rewards = {}
    for k,v in pairs(CycleInstanceDataManager.config_achievement_instance) do
        rewards[v.reward_id] = (rewards[v.reward_id] or 0) + v.reward_num
    end

    return rewards
end

function CycleCastleViewUIView:ShowButton(state,rewards)
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
        
        local allRewards = CycleInstanceDataManager:GetCurrentModel():GetAllSKRewardNotClaim()
        if Tools:GetTableSize(allRewards) <= 0 then
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(true)
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/confirmBtn","Button"),function()
                CycleInstanceDataManager:SetNoRewardFlag()
                self:DestroyModeUIObject()
                --GameTableDefine.MainUI:CloseInstanceEntry()
            end)
        else
            self:GetGo("background/BottomPanel/btn/claimBtn"):SetActive(true)
            self:GetGo("background/BottomPanel/btn/confirmBtn"):SetActive(false)
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/btn/claimBtn","Button"),function()
                GameTableDefine.CycleCastleRewardUI:ShowAllNotClaimRewardsGet()
                self:DestroyModeUIObject()
                --GameTableDefine.MainUI:CloseInstanceEntry()
                CycleInstanceDataManager:SetNoRewardFlag()
                
                --埋点:副本领奖
                GameSDKs:TrackForeign("rank_activity", {name = "CycleInstance", operation = "2", score = tonumber(CycleInstanceDataManager:GetCurrentModel():GetCurInstanceKSLevel())})

            end)
        end
        
    end
end

function CycleCastleViewUIView:ShowRewardsDetails(rewardType,name,go)
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

function CycleCastleViewUIView:GetInstanceLocked()
    return not CityMode:CheckBuildingSatisfy(200)
end

function CycleCastleViewUIView:UpdateMilepostRewardList(index, tran)
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

function CycleCastleViewUIView:SetRewardProgress(curLevel, totalLevel)
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
    self:GetComp("background/BottomPanel/prog", "Slider").value = curLevel / totalLevel
    self:SetText("background/BottomPanel/prog/progPoint/progress", curLevel)
    self:SetText("background/BottomPanel/prog/progPoint/limit", totalLevel) 
end

function CycleCastleViewUIView:OpenRewardInfo(curGo, rewardInfoData)
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
            local clampRectTransform = self:GetTrans("reward")
            local arrowTrans = self:GetTrans(rewardInfoGo,"arrow")
            UnityHelper.ClampInfoUIPosition(rewardInfoGo.transform, arrowTrans,
                    locationPos.transform.position,clampRectTransform)
            --rewardInfoGo.transform.position = locationPos.transform.position
        end
        infoGo:SetActive(true)
    end
end

function CycleCastleViewUIView:TurnPage(index)
    -- if self.__timers["TurnPage"] then
    --     GameTimer:StopTimer(self.__timers["TurnPage"])
    --     self.__timers["TurnPage"] = nil
    -- end
    -- self.__timers["TurnPage"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        
    -- end)
    self.m_list:ScrollTo(index or 0, 2)
end

return CycleCastleViewUIView
