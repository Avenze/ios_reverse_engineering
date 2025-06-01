---@class MainUI
local MainUI = GameTableDefine.MainUI
local CountryMode = GameTableDefine.CountryMode
local ResourceManger = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local QuestManager = GameTableDefine.QuestManager
local CityMode = GameTableDefine.CityMode
local EventManager = require("Framework.Event.Manager")
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local DressUpDataManager = GameTableDefine.DressUpDataManager
local DiamondShopUI = GameTableDefine.DiamondShopUI
local CfgMgr = GameTableDefine.ConfigMgr
local CollectionUI = GameTableDefine.CollectionUI
local ChatUI = GameTableDefine.ChatUI
local BankUI = GameTableDefine.BankUI
local ShopUI = GameTableDefine.ShopUI
local StarMode = GameTableDefine.StarMode
local RouletteUI = GameTableDefine.RouletteUI
local BoardUI = GameTableDefine.BoardUI
local PowerManager = GameTableDefine.PowerManager

function MainUI:GetView()
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.MAIN_UI, self.m_view, require("GamePlay.Common.UI.MainUIView"), self, self.CloseView)
    return self.m_view
end

function MainUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.MAIN_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function MainUI:Init(isInFloor)
    --TODO:測試用的數據
    if GameDeviceManager:IsEditor() then
        -- self.supplementOrderInfo = {}
        -- local item1 = {}
        -- item1.serialId = "1231234"
        -- item1.orderId = "1234"
        -- item1.productId = "cy4_piggypack_1"
        -- self.supplementOrderInfo[item1.serialId] = item1
        -- local item2 = {}
        -- item2.serialId = "1231235"
        -- item2.orderId = "1235"
        -- item2.productId = "cy4_pack_5"
        -- self.supplementOrderInfo[item2.serialId] = item2
    end

    if not self.m_view then
        return
    end
    self:UpdateHint()
    self:GetView():Invoke("SetUIStatus", isInFloor)
    CityMode:InitDistricts(true)
end

function MainUI:UpdateHint()
    self:UpdateResourceUI()
    self:RefreshQuestHint()
    self:RefreshBoardUnread()
    self:RefreshDiamondHint()
    self:RefreshDiamondShop()
    self:RefreshCashEarn()
    self:SetPhoneNum()
    self:RefreshStarState()
    self:RefreshCollectionHint()
    self:RefreshWheelHint()
    self:RefreshDiamondFund()
    self:RefreshGrowPackageBtn()
    self:RefreshLicenseState()
    self:RefreshActivityHint()
    self:RefreshInstanceentrance()

end

function MainUI:ChangeUIStatus(isInFloor)
    if not self.m_view then
        return
    end

    self:GetView():Invoke("SetUIStatus", isInFloor)
    CityMode:InitDistricts(true)
end

function MainUI:HideButton(buttonName, reOpen)
    self:GetView():Invoke("HideButton", buttonName, reOpen)
end

function MainUI:UpdateResourceUI()
	--SetResourceInfo(cash, diamond, water, power)   
    local cash = ResourceManger:GetLocalMoney() 
    local diamond = ResourceManger:GetDiamond()
    local power, water = PowerManager:GetCurrentPower()
    local totalPower = PowerManager:GetTotalPower()
    MainUI:GetView():Invoke("SetResourceInfo", cash, diamond, water, power, totalPower)
end

function MainUI:RefreshCashEarn()--每分钟赚钱显示
    MainUI:GetView():Invoke("RefreshCashEarn", ResourceManger:CashCurrMax(1))
end

function MainUI:SetEventSponsorHint(enable, eventId)--虽然可以配置多个id,但是每回只能出现一个,所以要多个的话,需要多创建几个,然后调整一些结构之类的
    self:GetView():Invoke("SetEventSponsorHint", enable, eventId)
end

function MainUI:SetEventBatmanHint(enable)
    self:GetView():Invoke("SetEventBatmanHint", enable)
end

function MainUI:SetPhoneNum()
    local num = ChatUI:GetActiveChatNum()
    local bank = BankUI:GetBankNum()
    local rank = BankUI:GetRankNum()
    self:GetView():Invoke("SetPhoneNum", num + bank + rank)
end

function MainUI:PlaySkipNight()
    self:GetView():Invoke("PlaySkipNight")    
end

function MainUI:SetEventRoomBrokenHint(roomIndex, type, roomGo, enable, brokenId)
    self:GetView():Invoke("SetEventRoomBrokenHint", roomIndex, type, roomGo,  enable, brokenId)
end

function MainUI:SetFPS(fps)
    self:GetView():Invoke("SetFPS", fps)
end

function MainUI:RefreshCollectionHint(companyLvUp, firstInvite)
    if companyLvUp or firstInvite then
        self:GetView():Invoke("RefreshCollectionHing", true)
        return
    end
    -- local _,__,rewardAble = CollectionUI:CalculateData()
    -- rewardAble = DressUpDataManager:CheckNewDressNotViewed()
    -- self:GetView():Invoke("RefreshCollectionHing", rewardAble)
end

function MainUI:RefreshQuestHint()--任务红点
    local num = QuestManager:GetQuestClaimableNumber()
    self:GetView():Invoke("SetQuestHint", num)
end

function MainUI:RefreshBoardUnread()
    --2024-8-13添加用于检测订单问题的相关内容
    local isHaveSupplementOrder = false
    local orderData = self:GetInitSupplementOrder()
    if orderData and Tools:GetTableSize(orderData) > 0 then
        isHaveSupplementOrder = true
    end
    local showRadPoint = (not BoardUI.isOverTime) and BoardUI.cacheData and  BoardUI.cacheData.unRead
    self:GetView():SetHaveBoardUnread(showRadPoint or isHaveSupplementOrder)
end

function MainUI:PlayStarAnim()--播放主界面知名度图标的扫光动效
    self:GetView():Invoke("PlayStarAnim")
end

function MainUI:RefreshStarState()--星级显示
    self:GetView():Invoke("RefreshStarState")
end

function MainUI:RefreshLicenseState()--刷新建筑许可证
    self:GetView():Invoke("RefreshLicenseState")
end
function MainUI:RefreshFactorytips()--刷新工厂UI提示
    self:GetView():Invoke("RefreshFactorytips")
end
function MainUI:RefreshFactoryGuideUI(bool)
    self:GetView():Invoke("RefreshFactoryGuideUI", bool)
end

function MainUI:RefreshFootballClubGuideUI(bool)
    self:GetView():Invoke("RefreshFootballClubGuideUI", bool)
end

function MainUI:RefreshRewardDiamond()--商城免费钻石奖励
    --self:GetView():Invoke("RefreshRewardDiamond")
end

function MainUI:RefreshDiamondHint()--钻石奖励红点
    if not GameConfig.IsIAP() then
        local rewardAble = DiamondRewardUI:ClamADRewards(true)
        self:GetView():Invoke("SetDiamondHint", rewardAble)
    end
end
function MainUI:RefreshPetHint()--宠物红点
    self:GetView():Invoke("RefreshPetHint")
end
function MainUI:RefreshActivityHint()--活跃度的红点
    self:GetView():Invoke("RefreshActivityHint")
end
function MainUI:RefreshInstanceentrance()--刷新副本入口
    self:GetView():Invoke("CheckHaveActiveInstance")
    self:CheckHavePreviewInstance() -- 刷新副本入口的时候也刷新预告
end

function MainUI:RefreshSeasonPassBtn()
    self:GetView():Invoke("RefreshSeasonPassBtn")
end

function MainUI:CheckHavePreviewInstance()
    self:GetView():Invoke("CheckHavePreviewInstance")
end

function MainUI:RefreshWheelHint()
   if FloorMode:CheckWheelGo() then
        local cdTime = RouletteUI:UpdateWheelCDTime(true)

        EventManager:DispatchEvent("WHEEL_NOTE", cdTime)
        
        self:GetView():Invoke("SetWheelHint", cdTime)
   end 
end

---刷新月卡奖励提示
function MainUI:RefreshMonthCardHint()
    self:GetView():Invoke("RefreshMonthCardHint")
end

function MainUI:RefreshLeagueLevel()
    self:GetView():Invoke("RefreshLeagueLevel")
end

function MainUI:RefreshFootBallLevel()
    self:GetView():Invoke("RefreshFootBallLevel")
end


function MainUI:SetWheelBtnActive(bool)
    self:GetView():Invoke("SetWheelBtnActive", bool)
end
function MainUI:RefreshNewPlayerPackage(refresh)
    self:GetView():Invoke("RefreshNewPlayerPackage", refresh)
end

function MainUI:RefreshDiamondShop()--钻石商城红点
    local rewardAble = false
    local curRecord = LocalDataManager:GetCurrentRecord()
    -- if GameConfig:IsIAP() then
        if ShopUI:RewardDiamondCD() <= 0 then
            rewardAble = true
        end
        if not curRecord.getFollowDiamond or curRecord.getFollowDiamond == 0 then
            --没有领取过钻石
            rewardAble = true
        end
    -- else
    --     local isFree = DiamondShopUI:CheckFreeDiamond()
    --     local isCd = DiamondShopUI:CanWatchAd()
    --     rewardAble = isFree or isCd
    -- end

    self:GetView():Invoke("SetDiamondShopHint", rewardAble)
end
function MainUI:RefreshDiamondFund() --钻石基金红点
    self:GetView():Invoke("RefreshDiamondFund")
end
function MainUI:RefreshGrowPackageBtn() --刷新成长基金的按钮
    self:GetView():Invoke("RefreshGrowPackageBtn")
end
function MainUI:ShowEnergyRoom()
    local roomsData = FloorMode:GetAllRoomsLocalData()
    for k,data in pairs(roomsData or {}) do
        if data.type == 5 and not data.unlock then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_ELECTRIC_LOCKED"))
            return
        end
    end

    if GameStateManager:IsInCity() then
        -- local id = CityMode:GetCurrentBuilding()
        -- GameStateManager:EnterBuildingFloor({id = id, config = CityMode.configCityData[id], defaultRoomCategory = 5})
        GameUIManager:SetEnableTouch(false)
        CityMode:EnterDefaultBuiding(5)
    else
        FloorMode:GetScene():ShowEnergyRoom()
    end
end

function MainUI:NotCashChange(get, pay, lastCash, isMax)
    self:GetView():Invoke("NotCashChange", get, pay, lastCash, isMax)
end

function MainUI:GetObj(name)
    local mView = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.MAIN_UI, self:GetView().m_guid)
    return mView:GetGo(name)
end

function MainUI:InitCameraScale(name, cb, isback)
    if name then
        self:GetView():Invoke("InitCameraScale", name, cb, isback)
    end
end

function MainUI:PlayUIAnimation(enable)
    self:GetView():Invoke("PlayUIAnimation", enable)
end

function MainUI:BackToCity(cb)
    self:GetView():Invoke("BackToCity", cb)
end

function MainUI:MakeEff(roomIndex, currType, improve)
    self:GetView():Invoke("MakeEff", roomIndex, currType, improve)
end

function MainUI:SetMeetingEventHint(enable)
    self:GetView():Invoke("SetMeetingEventHint", enable)
end

function MainUI:SetFestivalActivityBtn(bool)
    self:GetView():Invoke("SetFestivalActivityBtn", bool)
end

function MainUI:SetFloorIndex(index, target)
    index = index or 1
    local cfg = FloorMode:GetCurrFloorConfig()
    local upEnable = index < cfg.floor_count
    local downEnable = index > 1
    if cfg.floor_count == 1 then
        upEnable = false
        downEnable = false
    end
    self:GetView():Invoke("SetSwitchFloorButton", upEnable, downEnable, target, index)
end

function MainUI:SetHouseIndex(index, target)
    index = index or 1
    local cfg = target.m_hCfg
    local upEnable = index < cfg.floor_num
    local downEnable = index > 1
    self:GetView():Invoke("SetSwitchFloorButton", upEnable, downEnable, target, index)
end

function MainUI:GuideTimeUIState(isPlay)
    self:GetView():Invoke("GuideTimeUIState", isPlay)
end

function MainUI:FragmentActivity(isFloor)
    self:GetView():Invoke("FragmentActivity", isFloor)
end

function MainUI:LimitPackActivity(isFloor)
    self:GetView():Invoke("LimitPackActivity", isFloor)
end

function MainUI:LimitChooseActivity(isFloor)
    self:GetView():Invoke("LimitChooseActivity", isFloor)
end

function MainUI:RefreshFirstPurchaseBtn(isFloor)
    self:GetView():Invoke("RefreshFirstPurchaseBtn", isFloor)
end

function MainUI:SetCityHintNum(num)
    self:GetView():Invoke("SetCityHintNum", num)
end

function MainUI:EnterFactorySetUI()
    self:GetView():Invoke("EnterFactorySetUI")
end

function MainUI:ExitFactorySetUI()
    self:GetView():Invoke("ExitFactorySetUI")
end

function MainUI:EnterFootballClubSetUI()
    self:GetView():Invoke("EnterFootballClubSetUI")
end

function MainUI:RefreshPiggyBankBtn(playAnim)
    self:GetView():Invoke("RefreshPiggyBankBtn", playAnim)
end

function MainUI:Forcedisplay(money, diamonds)
    self:GetView():Invoke("Forcedisplay",money, diamonds)
end

function MainUI:AddMultiple(data, show, callBack, isArray, check) --data {type1, value1, type2, value2, type3, value3}
    local addCash = 0
    local addDiamond = 0
    local addStar = 0
    local allValue = {[2] = addCash, [3] = addDiamond, [5] = addStar}--只是和你说对应代表加什么

    local allIndex = {1, 3, 5}
    local currValue = nil
    if isArray then
        for k2,v2 in pairs(data) do
            for k,v in pairs(allIndex) do
                if v2[v] then
                    currValue = allValue[v2[v]]
                    allValue[v2[v]] = allValue[v2[v]] + v2[v + 1]
                end
            end
        end
    else
        for k,v in pairs(allIndex) do
            if data[v] then
                currValue = allValue[data[v]]
                allValue[data[v]] = allValue[data[v]] + data[v + 1]
            end
        end
    end

    if check then
        return allValue
    end
    
    if show then
        if allValue[2] > 0 then
            EventManager:DispatchEvent("FLY_ICON", nil, 2, nil, function()
                ResourceManger:AddCash(allValue[2], nil, callBack, show)
            end)
        end
        if allValue[3] > 0 then
            EventManager:DispatchEvent("FLY_ICON", nil, 3, nil, function()
                ResourceManger:AddDiamond(allValue[3], nil, callBack, show)
            end)
        end
        if allValue[5] > 0 then
            StarMode:StarRaise(allValue[5], show, callBack)
            EventManager:DispatchEvent("FLY_ICON", nil, 5, nil)
        end
    else
        if allValue[2] then
            ResourceManger:AddCash(allValue[2], nil, callBack, show)
        end
        if allValue[3] then
            ResourceManger:AddDiamond(allValue[3], nil, callBack, show)
        end
        if allValue[5] then
            StarMode:StarRaise(allValue[5], show, callBack)
        end
    end
end

--隐藏MainUI
function MainUI:Hideing(reverse)
    self:GetView():Invoke("Hideing", reverse)
end

--强制隐藏MainUI，不被UIManager唤醒
function MainUI:ForceHide(hide)
    if self.m_view then
        if hide then
            self.m_view.forceHide = true
            self.m_view.m_uiObj:SetActive(false)
        else
            self.m_view.forceHide = false
        end
    end
end

--清空事件UI
function MainUI:ClearEventUI()
    self:GetView():Invoke("ClearEventUI")
end
function MainUI:SetPowerBtnState(enable)
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    self:GetView():Invoke("SetPowerBtnState", enable)
end

function MainUI:ReOpenActivityRankBtn()
    self:GetView():Invoke("ReOpenActivityRankBtn")
end

function MainUI:CheckTransformAsset()
    self:GetView():Invoke("CheckTransformAsset")
end

function MainUI:OpenAccumulatedChargeActivity()
    self:GetView():Invoke("RefreshAccumulatedChargeActivity")
end

function MainUI:RefreshQuestionSurvey()
    self:GetView():Invoke("RefreshQuestionSurvey")
end

function MainUI:CloseInstanceEntry()
    self:GetView():Invoke("CloseInstanceEntry")
end


function MainUI:OpenClockOutActivity()
    self:GetView():Invoke("RefreshClockOutActivity")
end
--补单增加的相关功能
--查询成功，直接开始调用补单接口
-- DeviceUtil.InvokeNativeMethod("replenishOrder", serialId, productId)
--查询接口
--DeviceUtil.InvokeNativeMethod("queryOrder", queryType)
--queryType:1 初始化查询，2setting界面查询
--data.queryOrderInfo.query_order_successful, data.queryOrderInfo.serialId, data.queryOrderInfo.productId
function MainUI:OnInitQueryOrderCallback(query_order_successful, datas, queryType)
    if query_order_successful then
        self.supplementOrderInfo = {}
        
        for k, v in pairs(datas or {}) do
            local supplementItem = {}
            supplementItem.serialId = v.serialId
            supplementItem.productId =  v.productId
            supplementItem.orderId = v.orderId
            self.supplementOrderInfo[v.serialId] = supplementItem
        end
    end
    if queryType == 2 then
        local haveData = nil
        local datas = self:GetInitSupplementOrder()
        for _, v in pairs(datas or {}) do
            haveData = v
            break
        end
        
        if haveData and haveData.serialId and haveData.productId then
            local iapCfg = GameTableDefine.IAP:ProductIDToCfg(haveData.productId)
            -- if iapCfg and iapCfg.restore == 1 then
            if iapCfg then
                GameTableDefine.SettingUI:OnCheckRussionPurchaseCallback(true, haveData.serialId, haveData.productId, haveData.orderId)
            end
        end
		
		if not query_order_successful then
            GameTableDefine.SettingUI:OnCheckRussionPurchaseCallback(false, nil, nil, nil)
        end
    elseif queryType == 1 then
        if self.m_view then
            --刷新红点提示
            self:RefreshBoardUnread()
        end
    end
end

--[[
    @desc:获取补单数据
    author:{author}
    time:2024-08-13 12:19:45
    @return:
]]
function MainUI:GetInitSupplementOrder()
    return self.supplementOrderInfo or {}
end

--[[
    @desc: 补单回调
    author:{author}
    time:2024-08-13 14:18:32
    @return:
]]
function MainUI:OnRestorePurchaseCallback(successful, productId, orderId, type, extra)
    if self.supplementOrderInfo and self.supplementOrderInfo[orderId] and self.supplementOrderInfo[orderId].productId and self.supplementOrderInfo[orderId].productId == productId then
        if successful then
            self:ClearSupplementOrderData(orderId)
        end
        if type == 1 then
            GameTableDefine.SupplementOrderUI:OnRestorePurchaseCallback(successful, productId, extra)
        elseif type == 2 then
            GameTableDefine.SettingUI:OnRestorePurchaseCallback(successful, productId, extra)
        end
    end
end

function MainUI:ClearSupplementOrderData(orderId)
    if self.supplementOrderInfo and self.supplementOrderInfo[orderId] then
        self.supplementOrderInfo[orderId] = nil
    end
    self:RefreshBoardUnread()
end

EventManager:RegEvent("NOT_CASH_CHANGE", function(get, pay, lastCash, isMax)
    MainUI:NotCashChange(get, pay, lastCash, isMax)
end);

EventManager:RegEvent("SHOW_TYPE_EFF", function(roomIndex, currType, sameTypeNum)
    MainUI:MakeEff(roomIndex, currType, sameTypeNum)
end);

EventManager:RegEvent("NewDressupItemGet", function()
    MainUI:RefreshPetHint() 
end);
EventManager:RegEvent("CLUB_EXPERIENCE_CHANGE", function()
    MainUI:RefreshFootBallLevel()
end)