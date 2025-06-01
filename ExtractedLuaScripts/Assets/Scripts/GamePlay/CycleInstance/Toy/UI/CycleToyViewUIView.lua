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

---@class CycleToyViewUIView:UIBaseView
local CycleToyViewUIView = Class("CycleToyViewUIView", UIView)

function CycleToyViewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.tiemr = nil
    self.rewardsDetails = nil

    self.m_currentModel = nil ---@type CycleInstanceModelBase
    self.m_list = nil ---@type UnityEngine.UI.ScrollRectEx
    self.m_lockList = nil ---@type UnityEngine.UI.ScrollRectEx

    self.m_bottomPanel = nil ---@type UnityEngine.GameObject
    self.m_bottomPanelLock = nil ---@type UnityEngine.GameObject
end

function CycleToyViewUIView:OnEnter()
    self.rewardsDetails = self:GetGo("reward")
    self:SetButtonClickHandler(self:GetComp("background/quitBtn", "Button"),function()
        self:DestroyModeUIObject()
        end
    )
    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self.rewardsDetails:SetActive(false)
    end)

    ---已解锁奖励时的list
    self.m_bottomPanel = self:GetGo("background/BottomPanel")
    self.m_list = self:GetComp("background/BottomPanel/list", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data
    end)

    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateMilepostRewardList))
    self:SetListItemNameFunc(self.m_list, function(index)
        return "temp"
    end)

    ---未解锁奖励时的list
    self.m_bottomPanelLock = self:GetGo("background/BottomPanel_lock")
    self.m_lockList = self:GetComp("background/BottomPanel_lock/list", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_lockList, function()
        return #self.m_data
    end)

    self:SetListUpdateFunc(self.m_lockList, handler(self, self.UpdateMilepostRewardList))
    self:SetListItemNameFunc(self.m_lockList, function(index)
        return "temp"
    end)
end

function CycleToyViewUIView:GetCurrentActivityState()
    return CycleInstanceDataManager:GetInstanceState(self.m_currentModel.instance_id)
end

function CycleToyViewUIView:CanEnterCurrentActivity()
    local state = self:GetCurrentActivityState()
    if state == CycleInstanceDataManager.instanceState.isActive then
        return true
    end
end

function CycleToyViewUIView:GetCurrentScrollRect()
    --未解锁奖励，并且活动结束了就显示变灰的Panel
    local state = self:GetCurrentActivityState()
    if state == CycleInstanceDataManager.instanceState.isActive then
        return self.m_list
    end
    local locked = self:GetInstanceLocked()
    if not locked then
        locked = self.m_currentModel:GetCurInstanceKSLevel() == 0
    end
    if locked then
        return self.m_lockList
    else
        return self.m_list
    end
end

function CycleToyViewUIView:GetCurrentBottomPanel(changePanelState)
    --未解锁奖励，并且活动结束了就显示变灰的Panel
    local state = self:GetCurrentActivityState()
    if state == CycleInstanceDataManager.instanceState.isActive then
        if changePanelState then
            self.m_bottomPanel:SetActive(true)
            self.m_bottomPanelLock:SetActive(false)
        end
        return self.m_bottomPanel
    end
    local locked = self:GetInstanceLocked()
    if not locked then
        locked = self.m_currentModel:GetCurInstanceKSLevel() == 0
    end
    if changePanelState then
        self.m_bottomPanel:SetActive(not locked)
        self.m_bottomPanelLock:SetActive(locked)
    end
    if locked then
        return self.m_bottomPanelLock
    else
        return self.m_bottomPanel
    end
end

function CycleToyViewUIView:OnExit()
    if self.tiemr then
        GameTimer:_RemoveTimer(self.tiemr)
    end
    self.super:OnExit(self)
end

function CycleToyViewUIView:InitView()
    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.tiemr = GameTimer:CreateNewTimer(1,function()
        local state = self:GetCurrentActivityState()
            local timeRemaining = 0
            if state == CycleInstanceDataManager.instanceState.isActive then
                timeRemaining = CycleInstanceDataManager:GetLeftInstanceTime(self.m_currentModel.instance_id)
            else
                timeRemaining = CycleInstanceDataManager:GetInstanceRewardTime(self.m_currentModel.instance_id)
            end
            local timeStr =  GameTimeManager:FormatTimeLength(timeRemaining)
            self:SetText("background/Title/timer/num", timeStr)
        end,true,true)
    self:ShowAchievementReward()

    --埋点:查看副本详情
    local buildingID = CityMode:GetCurrentBuilding()
    GameSDKs:TrackForeign("rank_activity",
            {name = "CycleInstance",
             operation = "1",
             score = tonumber(self.m_currentModel:GetCurInstanceKSLevel()),
             scene_id = buildingID}
    )

end

function CycleToyViewUIView:ShowAchievementReward()
    self:GetCurrentBottomPanel(true)
    --显示所有奖励
    self.m_data = CycleInstanceDataManager:GetCycleInstanceMilepostUI(self.m_currentModel.instance_id):CalculateData()
    local scrollRect = self:GetCurrentScrollRect()
    scrollRect:UpdateData()
    self:SetRewardProgress(self.m_currentModel:GetCurInstanceKSLevel(), #self.m_data)

    self:ShowButton()

    --判断当前是否有可领取的里程碑奖励，有的话直接点跳转过去
    local turnToIndex = self.m_currentModel:GetCurInstanceKSLevel()
    if turnToIndex == 0 then
        turnToIndex = 1
    end
    if turnToIndex >= Tools:GetTableSize(self.m_data) then
        turnToIndex = Tools:GetTableSize(self.m_data)
    end
    self:TurnPage(turnToIndex)
end

function CycleToyViewUIView:ShowButton()
    local bottomPanel = self:GetCurrentBottomPanel()
    local state = self:GetCurrentActivityState()
    if state == CycleInstanceDataManager.instanceState.isActive then
        --活动进行中,显示前往
        self:GetGo(bottomPanel,"btn/gotoBtn"):SetActive(true)
        self:GetGo(bottomPanel,"btn/claimBtn"):SetActive(false)
        self:GetGo(bottomPanel,"btn/confirmBtn"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp(bottomPanel,"btn/gotoBtn","Button"),function()
            --前往副本场景
            if self:CanEnterCurrentActivity() then
                GameStateManager:SetCurrentGameState(GameStateManager.GAME_STATE_CYCLE_INSTANCE)
            --else
            --    EventManager:DispatchEvent("BACK_TO_SCENE")
            --    GameTableDefine.CityMode:EnterDefaultBuiding()
            end

            self:DestroyModeUIObject()
        end)
    elseif state == CycleInstanceDataManager.instanceState.awartable then
        
        self:GetGo(bottomPanel,"btn/gotoBtn"):SetActive(false)
        
        local allRewards = self.m_currentModel:GetAllSKRewardNotClaim()
        if Tools:GetTableSize(allRewards) <= 0 then
            self:GetGo(bottomPanel,"btn/claimBtn"):SetActive(false)
            self:GetGo(bottomPanel,"btn/confirmBtn"):SetActive(true)
            self:SetButtonClickHandler(self:GetComp(bottomPanel,"btn/confirmBtn","Button"),function()
                CycleInstanceDataManager:SetNoRewardFlag()
                self:DestroyModeUIObject()
                --GameTableDefine.MainUI:CloseInstanceEntry()
            end)
        else
            self:GetGo(bottomPanel,"btn/claimBtn"):SetActive(true)
            self:GetGo(bottomPanel,"btn/confirmBtn"):SetActive(false)
            self:SetButtonClickHandler(self:GetComp(bottomPanel,"btn/claimBtn","Button"),function()
                GameTableDefine.CycleToyRewardUI:ShowAllNotClaimRewardsGet()
                CycleInstanceDataManager:SetNoRewardFlag()
                self:DestroyModeUIObject()
                --GameTableDefine.MainUI:CloseInstanceEntry()
                
                --埋点:副本领奖
                GameSDKs:TrackForeign("rank_activity",
                        {name = "CycleInstance",
                         operation = "2",
                         score = tonumber(self.m_currentModel:GetCurInstanceKSLevel()
                         )})
            end)
        end
    end
    local showLockMark = self:GetInstanceLocked()
    if showLockMark then
        self:GetGo("background/BottomPanel/btn"):SetActive(false)
    end
    self:GetGo(bottomPanel,"locked"):SetActive(showLockMark)
end

function CycleToyViewUIView:GetInstanceLocked()
    return not CityMode:CheckBuildingSatisfy(200)
end

function CycleToyViewUIView:UpdateMilepostRewardList(index, tran)
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

function CycleToyViewUIView:SetRewardProgress(curLevel, totalLevel)
    if totalLevel <= 0 then
        return
    end
    local bottomPanel = self:GetCurrentBottomPanel()
    local proGo = self:GetGo(bottomPanel,"list/Viewport/Content/prog")
    proGo:SetActive(true)
    local proRectTransform = self:GetComp(bottomPanel,"list/Viewport/Content/prog","RectTransform")
    -- local sizeDelta = proGo.transform.RectTransform.sizeDelta
    -- proGo.transform.RectTransform.width 
    local sizeDelta = proRectTransform.sizeDelta
    sizeDelta.x = 170 * (totalLevel - 1)
    proRectTransform.sizeDelta = sizeDelta
    local proSlider = self:GetComp(bottomPanel,"list/Viewport/Content/prog", "Slider")
    proSlider.value = curLevel / totalLevel
    self:GetComp(bottomPanel,"prog", "Slider").value = curLevel / totalLevel
    self:SetText(bottomPanel,"prog/progPoint/progress", curLevel)
    self:SetText(bottomPanel,"prog/progPoint/limit", totalLevel)
end

function CycleToyViewUIView:OpenRewardInfo(curGo, rewardInfoData)
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

function CycleToyViewUIView:TurnPage(index)
    -- if self.__timers["TurnPage"] then
    --     GameTimer:StopTimer(self.__timers["TurnPage"])
    --     self.__timers["TurnPage"] = nil
    -- end
    -- self.__timers["TurnPage"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        
    -- end)
    local scrollRect = self:GetCurrentScrollRect()
    scrollRect:ScrollTo(index or 0, 2)
end

return CycleToyViewUIView
