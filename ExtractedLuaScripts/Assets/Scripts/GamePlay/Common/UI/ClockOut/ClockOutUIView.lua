--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-03-28 11:56:35
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local GameUIManager = GameTableDefine.GameUIManager
local ClockOutDataManager = GameTableDefine.ClockOutDataManager
local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr
local UnityHelper = CS.Common.Utils.UnityHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local EventManager = require("Framework.Event.Manager")

---@class ClockOutUIView:UIBaseView
---@field super UIBaseView
local ClockOutUIView = Class("ClockOutUIView", UIView)

function ClockOutUIView:ctor()
    self.super:ctor()
end

function ClockOutUIView:OnEnter()
    
end

function ClockOutUIView:OnExit()
    self.super:OnExit(self)

    if self.refreshTimer then
        GameTimer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
    if self.contentLoadTimer then
        GameTimer:StopTimer(self.contentLoadTimer)
        self.contentLoadTimer = nil
    end
    if self.addCreateBuildGos and Tools:GetTableSize(self.addCreateBuildGos) > 0 then
        for _, go in pairs(self.addCreateBuildGos) do
            GameObject.Destroy(go)
        end
        self.addCreateBuildGos = {}
    end

    if self.addCreateRewardsBtnGos and Tools:GetTableSize(self.addCreateRewardsBtnGos) then
        for _, go in pairs(self.addCreateRewardsBtnGos) do
            GameObject.Destroy(go)
        end
        self.addCreateRewardsBtnGos = {}
    end

    EventDispatcher:UnRegEvent("building_land_finish")
end

function ClockOutUIView:OpenView()
    if self.refreshTimer then
        GameTimer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
    local rootGoTran = self:GetGo("theme").transform
    for i = 1, rootGoTran.childCount do
        rootGoTran:GetChild(i - 1).gameObject:SetActive(false)
    end
    self.curTheme = ClockOutDataManager:GetActivityTheme()
    self.currRootGo = self:GetGoOrNil(self.curTheme)
    if not self.currRootGo then
        self:DestroyModeUIObject()
        return
    end
    
    self.currRootGo:SetActive(true)
    self:SetButtonClickHandler(self:GetComp(self.currRootGo, "MapRect/titlePivot/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self.rewardsDetails = self:GetGo(self.currRootGo, "reward")
    self:SetButtonClickHandler(self:GetComp(self.rewardsDetails, "", "Button"), function()
        self.rewardsDetails:SetActive(false)
     end)
    
    local isOpenedTips = ClockOutDataManager:IsPlayHelpTipsAnimation()
    
    if not isOpenedTips then
        local animation = self:GetComp(self.currRootGo, "MapRect/titlePivot/tipsBtn/icon", "Animation")
        AnimationUtil.Play(animation, "clockout_helpBtn")
    end
    self.clockOutHelpPanelGo = self:GetGo(self.currRootGo, "HelpInfo")
    self.clockOutHelpPanelGo:SetActive(false)
    self:SetButtonClickHandler(self:GetComp(self.currRootGo, "HelpInfo", "Button"), function()
        AnimationUtil.GotoAndStop(animation, "clockout_helpBtn")
        self.clockOutHelpPanelGo:SetActive(false)
    end)
    self:SetButtonClickHandler(self:GetComp(self.currRootGo, "MapRect/titlePivot/tipsBtn", "Button"), function()
        if not isOpenedTips then
            GameSDKs:TrackForeign("clockout_exposure", {type = "首次开启引导界面"})
            ClockOutDataManager:OpenClockOutHelpTips()
        end
        self.clockOutHelpPanelGo:SetActive(true)
     end)

    self.refreshTimer = GameTimer:CreateNewTimer(1, function() 
        self:RefreshLeftTimeDisplay()
    end, true, true)
    self.buildingsParentGo = self:GetGoOrNil(self.currRootGo, "MapRect/Viewport/Content/buildingPivot/buildingList")
    self.rewardsBtnParentGo = self:GetGoOrNil(self.currRootGo, "MapRect/Viewport/Content/levelList")
    self:_InitBuildintGosAndBtnGos()
    self:RefreshRewardsDisplay()
    self:RefreshCurOperationDisplay(true)
    if ClockOutDataManager:IsFirstEnterClockOutFlag() then
        GameSDKs:TrackForeign("clockout_exposure", {type = "首次进入活动界面"})
    end
    
    self.contentLoadTimer = GameTimer:CreateNewTimer(0.5, function()
        local doTweenGo = self:GetGoOrNil(self.currRootGo, "MapRect/Viewport/Content")
        local mapRect = self:GetComp(self.currRootGo, "MapRect", "MapRect")
        if doTweenGo and mapRect then
            UnityHelper.ClockOutUIDoTweenMove(mapRect, doTweenGo, 1, function(success) 
                local flag = 1
            end)
        end
        GameTimer:StopTimer(self.contentLoadTimer)
        self.contentLoadTimer = nil
    end, false, false)
end

function ClockOutUIView:_InitBuildintGosAndBtnGos()
    if not self.addCreateBuildGos then
        self.addCreateBuildGos = {}
    else
        if Tools:GetTableSize(self.addCreateBuildGos) > 0 then
            for _, go in pairs(self.addCreateBuildGos) do
                GameObject.Destroy(go)
            end
            self.addCreateBuildGos = {}
        end
    end
    if not self.addCreateRewardsBtnGos then
        self.addCreateRewardsBtnGos = {}
    else
        if Tools:GetTableSize(self.addCreateRewardsBtnGos) > 0 then
            for _, go in pairs(self.addCreateRewardsBtnGos) do
                GameObject.Destroy(go)
            end
            self.addCreateRewardsBtnGos = {}
        end
    end
    local normalGo = self:GetGoOrNil(self.buildingsParentGo, "temp_normal") --普通节点
    local specialGo = self:GetGoOrNil(self.buildingsParentGo, "temp_special") --大奖节点
    local specialBtnGo = self:GetGoOrNil(self.rewardsBtnParentGo, "temp_special")
    local normalBtnGo = self:GetGoOrNil(self.rewardsBtnParentGo, "temp_normal")
    local allRewardsData = ClockOutDataManager:GetAllRewardsData()
    for level, rewardData in pairs(allRewardsData) do
        local isSpecial = rewardData.rewardType == 1
        if isSpecial then
            self.addCreateBuildGos[level] = GameObject.Instantiate(specialGo, self.buildingsParentGo.transform)
            self.addCreateRewardsBtnGos[level] = GameObject.Instantiate(specialBtnGo, self.rewardsBtnParentGo.transform)
        else
            self.addCreateBuildGos[level] = GameObject.Instantiate(normalGo, self.buildingsParentGo.transform)
            self.addCreateRewardsBtnGos[level] = GameObject.Instantiate(normalBtnGo, self.rewardsBtnParentGo.transform)
        end
        self.addCreateBuildGos[level].name = self.addCreateBuildGos[level].name.."_"..tostring(level)
        self.addCreateRewardsBtnGos[level].name = self.addCreateRewardsBtnGos[level].name.."_"..tostring(level)
        -- self.addCreateBuildGos[level].transform:SetSiblingIndex(0)
        self.addCreateRewardsBtnGos[level].transform:SetSiblingIndex(0)
    end

    -- EventDispatcher:RegEvent("building_land_finish", function()
    --     local opLevel, opData, isMax = ClockOutDataManager:GetCurOpertionData()
    --     self:NextLevelBtnUnlock(opLevel - 2)
    --     self:RefreshRewardsDisplay()
    --     self:RefreshCurOperationDisplay()
    -- end)
    EventDispatcher:RegEvent("building_land_finish", handler(self, self.AnimationKeyFrameCallback))
end

function ClockOutUIView:RefreshRewardsDisplay()
    if not self.currRootGo or not self.addCreateBuildGos or not self.addCreateRewardsBtnGos then
        return
    end
    local allRewardsData = ClockOutDataManager:GetAllRewardsData()
    local opLevel, opData, isMax = ClockOutDataManager:GetCurOpertionData()
    local upgradeBtn = self:GetComp(self.currRootGo, "MapRect/btnPivot/buildBtn", "ButtonEx")
    local curLeftTickets = ClockOutDataManager:GetLeftTickets()
    if upgradeBtn then
        upgradeBtn.interactable = curLeftTickets > 0
    end
    for level, rewardData in pairs(allRewardsData) do
        local go = self.addCreateBuildGos[level]
        local btnGo = self.addCreateRewardsBtnGos[level]
        if not go or not btnGo then
            return
        end
        local buildGoAnimator = self:GetComp(go, "model", "Animator")
        local state = 0
        local btnState = 0
        if level == opLevel then
            state = 1
        end
        if rewardData.canClaimStatus then
            state = 2
            if rewardData.claimStatus then
                btnState = 2
            else
                if ClockOutDataManager:CheckCanClaimedReward(level) then
                    btnState = 1
                else
                    btnState = 0    
                end
            end
        else
            btnState = 3
        end
        if go then
            go:SetActive(true)
            if buildGoAnimator then
                buildGoAnimator:SetInteger("state", state)
            end
        end
        --设置领取按钮
        if btnGo then
            btnGo:SetActive(true)
            local btnGoAnimator = self:GetComp(btnGo, "block", "Animator")
            btnGoAnimator:SetInteger("state", btnState)
            self:GetGo(btnGo, "block/arrow"):SetActive(true)
            self:SetText(btnGo, "block/info/num", level)
            local dBtnGo = self:GetGo(btnGo, "block/buttons/freeBtn")
            local mBtnGo = self:GetGo(btnGo, "block/buttons/purchaseBtn")
            local curBtn = nil
            if rewardData.shopId  ~= 0 then
                --获取价格显示
                local priceStr = "$_"..rewardData.shopId
                local mainPrice = GameTableDefine.Shop:GetShopItemPrice(rewardData.shopId)
                dBtnGo:SetActive(false)
                mBtnGo:SetActive(true)
                self:SetText(mBtnGo, "text", mainPrice)
                curBtn = self:GetComp(mBtnGo, "", "Button")
            else
                dBtnGo:SetActive(true)
                mBtnGo:SetActive(false)
                curBtn = self:GetComp(dBtnGo, "", "Button")
            end
            -- curBtn.interactable = ClockOutDataManager:CheckCanClaimedReward(level)
            curBtn.interactable = true
            local rewardsGo = self:GetGo(btnGo, "block/rewards")
            -- for i = Tools:GetTableSize(rewardData.rewards_data) - 1, 1, -1 do
            --     if i < rewardsGo.transform.childCount then
            --         GameObject.Destroy(rewardsGo.transform.GetChild(i)
            --     end
            -- end
            local firstGo = rewardsGo.transform:GetChild(0).gameObject
            if Tools:GetTableSize(rewardData.rewardsData) < rewardsGo.transform.childCount then
                for i = Tools:GetTableSize(rewardData.rewardsData), rewardsGo.transform.childCount - 1 do
                    rewardsGo.transform:GetChild(i).gameObject:SetActive(false)
                end
            else
                local curChildCount = Tools:GetTableSize(rewardData.rewardsData) - rewardsGo.transform.childCount
                for i = 1,  curChildCount do
                    GameObject.Instantiate(firstGo, rewardsGo.transform)
                end
            end
            for index, rewarItemData in ipairs(rewardData.rewardsData) do
                local curGo = rewardsGo.transform:GetChild(index - 1).gameObject
                curGo:SetActive(true)
                local shopCfg = ConfigMgr.config_shop[rewarItemData.shopId]
                if shopCfg then
                    local amount = shopCfg.amount * rewarItemData.num
                    local amountStr  = tostring(amount)
                    local icon = shopCfg.icon
                    if shopCfg.type == 9 then
                        local resType = GameTableDefine.ResourceManger:GetShopCashType(shopCfg.country)
                        icon = GameTableDefine.ResourceManger:GetShopCashIcon(resType, shopCfg.icon)
                        local timeAmount = amount * 3600 / 30
                        local realTotalCount = GameTableDefine.FloorMode:GetTotalRent() * timeAmount
                        if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                            realTotalCount = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * timeAmount
                        end
                        amountStr = tostring(BigNumber:FormatBigNumber(realTotalCount))
                    end
                    if shopCfg.type == 8 then
                        local companyData  = GameTableDefine.CompanyMode:GetData()
                        local totalExp = 0
                        for roomKey,roomData in pairs(companyData or {}) do
                            totalExp = totalExp + GameTableDefine.CompanyMode:RoomExpAdd(roomKey,true)
                        end
                        amount = totalExp * amount * 3600
                        amountStr = tostring(BigNumber:FormatBigNumber(amount))
                    end
                    self:SetSprite(self:GetComp(curGo, "content/icon", "Image"), "UI_Shop", icon)
                    self:SetText(curGo, "account/num", amountStr)
                    local infoData = {}
                    infoData.infoTitle = GameTextLoader:ReadText(shopCfg.name)
                    infoData.infoDesc = GameTextLoader:ReadText(shopCfg.desc)
                    self:SetButtonClickHandler(self:GetComp(curGo,"content", "Button"), function()
                        self:OpenRewardInfo(curGo, infoData)
                    end)
                end
            end
            self:SetButtonClickHandler(curBtn, function() 
                if btnState == 0 or btnState == 3 then
                    self:ShowCanNotClaimTips(btnState)
                else
                    --TODO:领奖励的接口制作
                    -- GameSDKs:TrackForeign("clockout_reward", {level = level, state = "点击按钮"})
                    curBtn.interactable = false
                    if rewardData.shopId ~= 0 then
                        local shopId = rewardData.shopId
                        if shopId then
                            GameTableDefine.Shop:CreateClockOutDataItemOrder(shopId, curBtn)
                        end
                    else
                        local result = ClockOutDataManager:ClaimClockOutReward(level)
                        if result then
                            self:NextLevelBtnUnlock(level)
                            self:RefreshRewardsDisplay()
                        end
                    end
                end
                
            end)
        end
    end
end

function ClockOutUIView:RefreshCurOperationDisplay(refresh)
    if not refresh then
        return
    end
    if not self.currRootGo or not self.addCreateBuildGos or not self.addCreateRewardsBtnGos then
        return
    end
    local opLevel, opData, isMax = ClockOutDataManager:GetCurOpertionData()
    if opLevel == 0 then
        return
    end
    if isMax then
        self:GetGo(self.currRootGo, "MapRect/btnPivot"):SetActive(false)
        return
    end
    self:GetGo(self.currRootGo, "MapRect/btnPivot"):SetActive(true)
    local doTweenGo = self:GetGoOrNil(self.currRootGo, "MapRect/Viewport/Content")
    local mapRect = self:GetComp(self.currRootGo, "MapRect", "MapRect")
    local curOPBuildGo = self.addCreateBuildGos[opLevel]
    local curOPButtonGO = self.addCreateRewardsBtnGos[opLevel]
    local curAnimator = self:GetComp(curOPBuildGo, "model", "Animator")
    local curBtnAnimator = self:GetComp(self.addCreateRewardsBtnGos[opLevel], "block", "Animator")
    local curOPStr = GameTextLoader:ReadText("TXT_CLOCKOUT_FLOOR_INFO")
    curOPStr = string.gsub(curOPStr, "%[floor%]", tostring(opLevel))
    local curNeedTickets = opData.needTickets
    local curUsedTickets = opData.curTickets
    local curLeftTickets = ClockOutDataManager:GetLeftTickets()
    local iconTicketString = "icon_clockout_ticket_"..ClockOutDataManager:GetActivityTheme()
    local silder = self:GetComp(self.currRootGo, "MapRect/btnPivot/buildBtn/prog", "Slider")
    silder.value = 0
    if curNeedTickets ~= 0 then
        silder.value = curUsedTickets / curNeedTickets
    end
    self:SetText(self.currRootGo, "MapRect/btnPivot/buildBtn/prog/progNum/use", curUsedTickets)
    self:SetText(self.currRootGo, "MapRect/btnPivot/buildBtn/prog/progNum/need", curNeedTickets)
    self:SetText(self.currRootGo, "MapRect/btnPivot/buildBtn/ticket/num", curLeftTickets)
    self:SetSprite(self:GetComp(self.currRootGo, "MapRect/btnPivot/buildBtn/ticket/icon", "Image"), "UI_Shop", iconTicketString)
    self:SetText(self.currRootGo, "MapRect/btnPivot/buildBtn/floorNum", curOPStr)
    --TODO:要区分长按和短按的区别
    local upgradeBtn = self:GetComp(self.currRootGo, "MapRect/btnPivot/buildBtn", "ButtonEx")
    upgradeBtn.interactable = curLeftTickets ~= 0
    self:SetButtonClickHandler(upgradeBtn,function()
        if not self.isMoving then
            if mapRect and doTweenGo and curOPButtonGO then
                self.isMoving = true
                UnityHelper.ClockOutUIDoTweenMoveToDestGo(mapRect, doTweenGo, curOPButtonGO, 0.5, function(success) 
                    self.curOptionLevel = opLevel
                    self.isMoving = false
                end)
                
            end 
        end 
        
        local result, levelUp = ClockOutDataManager:AddClockOutTicketsToCurRewardItem(opLevel)
        if curAnimator and result and not levelUp then
            curAnimator:SetTrigger("building")
        end
        self:RefreshCurOperationDisplay(result)
        if levelUp then
            upgradeBtn.interactable = false
            -- self:RefreshRewardsDisplay()
            if curAnimator then
                curAnimator:Play("clockout_building_land", 0, 0)
            end
        end
    end)

    self:SetButtonHoldHandler(upgradeBtn,function()
        if not self.isMoving then
            if mapRect and doTweenGo and curOPButtonGO then
                self.isMoving = true
                UnityHelper.ClockOutUIDoTweenMoveToDestGo(mapRect, doTweenGo, curOPButtonGO, 0.5, function(success) 
                    self.curOptionLevel = opLevel
                    self.isMoving = false
                end)
                
            end 
        end 
        local result, levelUp = ClockOutDataManager:AddClockOutTicketsToCurRewardItem(opLevel)
        if curAnimator and result and not levelUp then
            curAnimator:SetTrigger("building")
        end
        self:RefreshCurOperationDisplay(result)
        if levelUp then
            upgradeBtn.interactable = false    
            if curAnimator then
                curAnimator:Play("clockout_building_land", 0, 0)
            end
            -- self:RefreshRewardsDisplay()
        end
    end, nil, 0.4, 0.13)
end


function ClockOutUIView:RefreshLeftTimeDisplay()
    local leftTime  = GameTableDefine.ClockOutDataManager:GetActivityLeftTime()
    if leftTime <= 0 then
        if self.refreshTimer then
            GameTimer:StopTimer(self.refreshTimer)
            self.refreshTimer = nil
        end
        self:DestroyModeUIObject()
    else
        local timeStr = GameTimeManager:FormatTimeLength(leftTime)
        self:SetText(self.currRootGo, "MapRect/titlePivot/timer/num", timeStr)
    end
end

function ClockOutUIView:IPABuyResult(shopId, success)
    self:RefreshRewardsDisplay()
end

function ClockOutUIView:OpenRewardInfo(curGo, infoData)
    local infoGo = self:GetGoOrNil(self.currRootGo, "reward")
    if infoGo.isActive then
        return
    end

    if infoGo and infoData then
        self:SetText(self.currRootGo, "reward/rewardInfo/title/txt", infoData.infoTitle or "Title-Null")
        self:SetText(self.currRootGo, "reward/rewardInfo/fix/txt", infoData.infoDesc or "Desc-Null")
        local locationPos = self:GetGoOrNil(curGo, "pivot")
        local rewardInfoGo = self:GetGoOrNil(self.currRootGo, "reward/rewardInfo")
        if rewardInfoGo and locationPos then
            local clampRectTransform = self:GetTrans(self.currRootGo, "reward")
            local arrowTrans = self:GetTrans(rewardInfoGo,"arrow")
            UnityHelper.ClampInfoUIPosition(rewardInfoGo.transform, arrowTrans,
                    locationPos.transform.position,clampRectTransform)
            --rewardInfoGo.transform.position = locationPos.transform.position
        end
        infoGo:SetActive(true)
    end
end

function ClockOutUIView:NextLevelBtnUnlock(level)
    if ClockOutDataManager:CheckCanClaimedReward(level + 1) then
        if self.addCreateRewardsBtnGos[level + 1] then
            local curBtnAnimator = self:GetComp(self.addCreateRewardsBtnGos[level + 1], "block", "Animator")
            if curBtnAnimator then
                curBtnAnimator:SetTrigger("unlocking")
            end
        end
    end
end

function ClockOutUIView:AnimationKeyFrameCallback()
    local opLevel, opData, isMax = ClockOutDataManager:GetCurOpertionData()
    self:NextLevelBtnUnlock(opLevel - 2)
    self:RefreshRewardsDisplay()
    self:RefreshCurOperationDisplay()
end

function ClockOutUIView:ShowCanNotClaimTips(state)
    local str = "Error:"..tostring(state)
    if state == 3 then
        str = GameTextLoader:ReadText("TXT_TIP_CLOCKOUT_LOCK1")
    elseif state == 0 then
        str = GameTextLoader:ReadText("TXT_TIP_CLOCKOUT_LOCK2")
    end
    EventManager:DispatchEvent("UI_NOTE", str)
end

return ClockOutUIView