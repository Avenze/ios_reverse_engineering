local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local Tween = CS.Common.Utils.DotweenUtil
local V2 = CS.UnityEngine.Vector2
local V3 = CS.UnityEngine.Vector3
local GameObject = CS.UnityEngine.GameObject
local FeelUtil = CS.Common.Utils.FeelUtil
local ResMgr = GameTableDefine.ResourceManger
local ActivityUI = GameTableDefine.ActivityUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local MainUI = GameTableDefine.MainUI
local RouletteUI = GameTableDefine.RouletteUI
local TimerMgr = GameTimeManager
local GameUIManager = GameTableDefine.GameUIManager;
local SoundEngine = GameTableDefine.SoundEngine
local ChooseUI = GameTableDefine.ChooseUI
local ShopUI = GameTableDefine.ShopUI

local WHEEL = "wheel"
local save = nil

local RouletteUIView = Class("RouletteUIView", UIView)
local timeStay
local allLight = nil
local allLightFeel = nil
local lightCount = 12    --固定12个灯


local lightTime = 1--亮灯与闪烁之间的时间间隔(秒)

local shingTime = 2--闪烁的时长(秒)
local shingBetween = 0.75--闪烁时,灯光变化的时间间隔(秒)

local rotateLength = 4--旋转时,亮的灯数(个)
local rotateDistance = 2--旋转时,两个亮的灯之间的间隔数目(个)
local rotateBetween = 0.1--旋转时,灯光变化的时间间隔(秒)

local initLightMode = nil--初始灯光效果用于调试
                --填false进入就会显示闪烁效果,填true显示旋转效果,填nil为正常

function RouletteUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_cusTimer = {}

    save = LocalDataManager:GetDataByKey(WHEEL)

end

function RouletteUIView:FirstTime(change)
    local freeBefor = save["first"]
    if freeBefor == nil and change then
        save["first"] = false
        LocalDataManager:WriteToFile()
    end

    return freeBefor == nil
end

function RouletteUIView:AdFirstTime(change)
    local AdFirst = save["AdFirst"]
    if AdFirst == nil and change then
        save["AdFirst"] = false
        LocalDataManager:WriteToFile()
    end

    return AdFirst == nil
end

function RouletteUIView:OnEnter()
    EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", false)
    
    local leaveBtn = self:GetComp("RootPanel/quitBtn","Button")
    self:SetButtonClickHandler(leaveBtn, function()
        GameSDKs:TrackForeign("wheel_use", {state = 3})
        self:DestroyModeUIObject()
    end)
    self.mfeel = self:GetComp("RootPanel/content", "MMFeedbacks")
    self.mfeel:Initialization()

    self:refreshRoulette()
    self:RefreshTurnButton()

    local diamondNeed = ConfigMgr.config_global.wheel_diamond
    self:SetText("RootPanel/rollBtn/text", diamondNeed)
    local turnBtn = self:GetComp("RootPanel/rollBtn", "Button")

    --local times = save["times"] or 0

    local diamondDispGo = self:GetGoOrNil("RootPanel/diamonds")
    if diamondDispGo then
        diamondDispGo:SetActive(true)
    end
    self:SetButtonClickHandler(turnBtn, function()
        if self:FirstTime() then
            self:FirstTime(true)
            self:LotteryTurntable(nil,true)
            -- GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "转盘", behaviour = 2, num = 0})
            return
        end
        if ResMgr:GetWheelTicket() > 0 then
            ResMgr:SpendWheelTicket(1, nil, function()
                GameSDKs:TrackForeign("wheel_ticket", {behavior = 2, num_new = 1})
                self:LotteryTurntable()
            end)
            return
        end
        local diamondEnough = ResMgr:CheckDiamond(diamondNeed)
        if diamondEnough then
            local originalDiamond = ResMgr:GetDiamond() - diamondNeed
            local originalCash = ResMgr:GetLocalMoney()
            ResMgr:SpendDiamond(diamondNeed, nil, function()
                self:LotteryTurntable()
                GameSDKs:TrackForeign("wheel_use", {state = 2})
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "转盘", behaviour = 2, num_new = tonumber(diamondNeed)})
            end)            
            MainUI:Forcedisplay(originalCash, originalDiamond)

        else
            -- ChooseUI:CommonChoose("TXT_TIP_DIAMOND_PURCHASE", function()
            --     GameSDKs:TrackForeign("wheel_use", {state = 4})
            --     ShopUI:TurnTo(1000)
            -- end, true)
            GameTableDefine.ShopInstantUI:EnterToDiamondBuy()
            if self.refreshDiamondTimer then
                GameTimer:StopTimer(self.refreshDiamondTimer)
                self.refreshDiamondTimer = nil
            end
            self.refreshDiamondTimer = GameTimer:CreateNewMilliSecTimer(500, function()
                self:RefreshDiamondText()
            end, true, true)
        end
        self:RefreshDiamondText()
    end)

    self:RefreshADButton()
    self:RefreshLight()
    self:RefreshBrustProgress()     --刷新抽奖进度
    GameSDKs:TrackForeign("wheel_use", {state = 0})
end

--抽奖表现
function RouletteUIView:LotteryTurntable(isBurst,isFirst)
    self:TurnRound(isBurst,isFirst)                --转转盘
    self:LightAnima(true)           --播放抽奖灯光
    self:RefreshBrustProgress()     --刷新抽奖进度
    --调用通行证任务接口，更新任务进度2024-12-23
    GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(3, 1)
end

function RouletteUIView:RefreshBrustProgress()
    local slider = self:GetComp("RootPanel/prog/Slider","Slider")
    slider.value = RouletteUI:SaveBurstTime(true) / RouletteUI:GoalBurstTime()
    self:SetText("RootPanel/prog/Slider/num",RouletteUI:SaveBurstTime(true).."/"..RouletteUI:GoalBurstTime())
    GameTableDefine.FloorMode:SetSceneWheelNum(RouletteUI:SaveBurstTime(true).."/"..RouletteUI:GoalBurstTime())
    local saveValue = RouletteUI:SaveBurstTime(true) 
    local GoalValue = RouletteUI:GoalBurstTime()
    if saveValue <= GoalValue then
        local feel = self:GetComp("RootPanel/prog/Slider/token/addFB", "MMFeedbacks")
        feel:PlayFeedbacks()  
    else    

    end

end 

function RouletteUIView:RefreshTurnButton()
    local root = self:GetGo("RootPanel/rollBtn")
    local isFirstTime = self:FirstTime()
    
    if not GameConfig.IsIAP() then
        local turnBtn = self:GetComp(root, "", "Burron")
        local diamondNeed = ConfigMgr.config_global.wheel_diamond
        if not ResMgr:CheckDiamond(diamondNeed) and not isFirstTime then
            turnBtn.interactable = false
        end
    end
    local wheelTickets = ResMgr:GetWheelTicket()
    self:SetText(root, "text_tk", tostring(wheelTickets))
    self:GetGo(root, "icon"):SetActive(not isFirstTime and wheelTickets <= 0)
    self:GetGo(root, "text"):SetActive(not isFirstTime and wheelTickets <= 0)
    self:GetGo(root, "free"):SetActive(isFirstTime)
    self:GetGo(root, "icon_tk"):SetActive(not isFirstTime and wheelTickets > 0)
    self:GetGo(root, "text_tk"):SetActive(not isFirstTime and wheelTickets > 0)
    self:SetText("RootPanel/wheelTickets/num", wheelTickets)
end

function RouletteUIView:RefreshADButton()
    local adBtn = self:GetComp("RootPanel/adBtn", "Button")

    local adText = self:GetComp("RootPanel/adBtn/time", "TMPLocalization")
    local adTime = RouletteUI:UpdateWheelCDTime(true)


    local getTimer = TimerMgr.FormatTimeLength
    adBtn.interactable = adTime == 0
    --adBtn.interactable = adTime >= 0
    if adTime > 0 then
        adText.gameObject:SetActive(true)

        timeStay = adTime
        local timeShow = nil
        if self.m_cusTimer["adTime"] == nil then
            self.m_cusTimer["adTime"] = GameTimer:CreateNewTimer(1, function()
                timeShow = getTimer(self, timeStay)
                adText.text = timeShow

                timeStay = timeStay - 1
                if timeStay < 0 then
                    self:RefreshADButton()
                end
            end, true, true)
        end
    else
        adText.gameObject:SetActive(false)

        if self.m_cusTimer["adTime"] then
            GameTimer:StopTimer(self.m_cusTimer["adTime"])
            self.m_cusTimer["adTime"] = nil
        end

        adText.text = GameTextLoader:ReadText("TXT_BTN_FREE")
    end

    if adTime == 0 then
    --if adTime >= 0 then
        local callBack = function()
            RouletteUI:UpdateWheelCDTime()
            self:RefreshADButton()
            if self:AdFirstTime() then
                self:AdFirstTime(true)
                self:LotteryTurntable(nil,true)
            else
                self:LotteryTurntable()
            end
        end

        self:SetButtonClickHandler(adBtn, function()            
            GameSDKs:PlayRewardAd(callBack, function()
                GameSDKs:TrackForeign("wheel_use", {state = 1})
            end,function()
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            end, 10011)
        end)
    end
end

function RouletteUIView:OnExit()
	self.super:OnExit(self)
    -- if self.__timers["adTime"] then
    --     GameTimer:StopTimer(self.__timers["adTime"])
    --     self.__timers["adTime"] = nil
    -- end
    -- if self.__timer["light"] then
    --     self.__timer["light"] = GameTimer:StopTimer(self.__timers["light"])
    -- end

    for k,v in pairs(self.m_cusTimer or {}) do
        GameTimer:StopTimer(v)
        self.m_cusTimer[k] = nil
    end
    self.m_cusTimer = nil
    if self.refreshDiamondTimer then
        GameTimer:StopTimer(self.refreshDiamondTimer)
        self.refreshDiamondTimer = nil
    end
    self.rotateSFX = nil
    self.shingSFX = nil
    self.shingRotateSFX = nil
    self.mfeel = nil
    self.lastCurve = nil
    self.mfeel = nil
    self.bindBtn = nil
    EventManager:UnregEvent("purchase_success_close")
    EventManager:UnregEvent("turnFinish")
    GameUIManager:SetEnableTouch(true, "转盘")
    allLight = nil
end

function RouletteUIView:makeChoose(isBurst)--确定选哪个
    local cfg = ConfigMgr.config_wheel
    --local data = LocalDataManager:GetDataByKey(WHEEL)
    local buyTime = save["times"] or 0
    local enableGift = {}
    local isSpecial = {}
    local haveSpecial = false

    local chance = {0}
    local totalChance = 0

    local specialChance = {0}
    local totalSpecialChance = 0

    local shopIndex = 1
    for k,v in pairs(cfg) do
        shopIndex = 1
        if v.num == 1 and ShopManager:BoughtBefor(v.shopId[shopIndex]) then
            shopIndex = 2
        end
        
        if shopIndex == 1 and v.num == 1 then
            isSpecial[v.shopId[shopIndex]] = true
            haveSpecial = true

            totalSpecialChance = totalSpecialChance + v.weight[shopIndex]
            table.insert(specialChance, totalSpecialChance)

        elseif shopIndex == 2 then
            isSpecial[v.shopId[shopIndex]] = false
            haveSpecial = false
            totalSpecialChance = totalSpecialChance + v.weight[shopIndex]
            table.insert(specialChance, totalSpecialChance)

        else
            table.insert(specialChance, totalSpecialChance)
        end

        table.insert(enableGift, v.shopId[shopIndex])
        
        totalChance = totalChance + v.weight[shopIndex]
        table.insert(chance, totalChance)
    end

    local ran = math.random(1, totalChance)
    local final = 0

    if isBurst then
        ran = math.random(1, totalSpecialChance)
        chance = specialChance
    end

    for k, v in pairs(chance) do
        if v >= ran then
            final = k
            break
        end
    end

    final = final - 1

    return final - 1, enableGift[final], isSpecial[enableGift[final]]
end

function RouletteUIView:try1000()
   ASD =  function () 
        local cfg = ConfigMgr.config_wheel
        local enableGift = {}
        local isSpecial = {}
        local haveSpecial = false

        local chance = {0}
        local totalChance = 0

        local specialChance = {0}
        local totalSpecialChance = 0

        for k,v in pairs(cfg) do                       
            totalSpecialChance = totalSpecialChance + v.weight[1]
            table.insert(specialChance, totalSpecialChance)
        
            table.insert(specialChance, totalSpecialChance)
        

            table.insert(enableGift, v.shopId[1])
        
            totalChance = totalChance + v.weight[1]
            table.insert(chance, totalChance)
        end

        local ran = math.random(1, totalChance)
        local final = 0
        for k, v in pairs(chance) do
            if v >= ran then
                final = k
                break
            end
        end
        return final -  2
    end
    local A = {}
    for i = 1, 1000 do 
        local index = ASD()
        if not A[index] then
            A[index] = 0
        end
        A[index] = A[index] + 1
    end
    return A
end





function RouletteUIView:TestChance()
    local goalIndex, shopId, isSpecial
    local allGift = {}
    local special = {}

    local buyTwoThoudand = function()
        allGift = {}
        special = {}

        for i = 1, 1000 do
            local isSpecial = (i % ConfigMgr.config_global.wheel_burst) == 0
            goalIndex, shopId, isSpecial = self:makeChoose(isSpecial)
            if allGift[goalIndex] == nil then
                allGift[goalIndex] = 0
            end
            allGift[goalIndex] = allGift[goalIndex] + 1
    
            local data = LocalDataManager:GetDataByKey(WHEEL)
            if data["times"] == nil then
                data["times"] = 0
            end
    
            data["times"] = data["times"] + 1
            data = LocalDataManager:GetDataByKey("shop")
            local times = data["times"]
            times["" .. shopId] = 1
    
            if isSpecial then
                special[shopId] = i
            end
        end
    end
    local cleanData = function()
        local data = LocalDataManager:GetDataByKey("shop")
        data["times"] = nil
        data = LocalDataManager:GetDataByKey(WHEEL)
        data["times"] = nil
    end

    local allSpecial = {}
    allSpecial[1057] = {}
    allSpecial[1058] = {}
    allSpecial[1059] = {}

    for j = 1, 300 do
        buyTwoThoudand()
        cleanData()
        for k,v in pairs(special) do
            table.insert(allSpecial[k], v)
        end
    end

    local total = 0
    local result = ""
    for k,v in pairs(allSpecial) do
        total = 0
        for k,v in pairs(v) do
            total = total + v
        end

        total = total / 300
        result = result .. "商品" .. k .. "平均在" .. total .. "得到\n"
    end

    local stop = nil
end

function RouletteUIView:TurnRound(isBurst,isFirst)
    --2023-2-3 修改
    --GameSDKs:TrackForeign("wheel_use", {state = 2})
    if not isBurst then
        self.rotateSFX = SoundEngine:PlaySFX(SoundEngine.WHEEL_ROTATE)
    end
    local config_wheel = ConfigMgr.config_wheel
    GameUIManager:SetEnableTouch(false, "转盘")

    local roulette = self:GetGo("RootPanel/content/area")

    --self:TestChance()
    --self:try1000()
    local goalIndex, shopId, isSpecial = self:makeChoose(isBurst)
    if isFirst then --广告和首次钻石抽奖固定得1004的奖励:15分钟的钱
        goalIndex, shopId, isSpecial = 4-1,1055,false
    end

    local cfg = ShopManager:GetCfg(shopId)
    
    local value,typeName = ShopManager:GetValueByShopId(shopId)
    
    ShopManager:Buy(shopId)--直接获得...
     --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
     if cfg.type == 9 then
        local type = GameTableDefine.CountryMode:GetCurrCountry()
        local amount = value
        local change = 0
        local position = "转盘奖励"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
     end
    -- if typeName == "diamond" then
    --     ResMgr:SpendDiamond(value)
    -- elseif typeName == "cash" then

    -- elseif typeName == "cash" then
    --     ResMgr:SpendCash(value)
    -- end

    --local data = LocalDataManager:GetDataByKey(WHEEL)
    if save["times"] == nil then
        save["times"] = 0
    end

    save["times"] = save["times"] + 1
    local shopName = ShopManager:GetShopString(value, cfg)
    GameSDKs:TrackForeign("wheel_reward", {reward_id = shopId, reward_name = shopName})

    if isSpecial then
        GameSDKs:TrackForeign("wheel_count", {reward_id = shopId, reward_count_new = tonumber(save["times"]) or 0})
        EventManager:DispatchEvent("WHEEL_SPECIAL")
    end
    local CalculateAngle = function(index)
        local A = #config_wheel
        index = index + 1
        local angle = 0
        if index == #config_wheel then
            angle = 360 - config_wheel[index].angle        
        else
            angle = config_wheel[index + 1].angle - config_wheel[index].angle
        end    
        return angle * 0.3
    end
    local  C = math.floor(CalculateAngle(goalIndex))
    local D = math.random(- C ,  C )
    local goalWheel = config_wheel[goalIndex + 1].angle + D

    local currFeel = self.mfeel.Feedbacks[0]

    self.lastCurve = self.lastCurve or 0
    currFeel.RemapCurveZero = self.lastCurve

    local startCurve = self.lastCurve--主要是需要保持和之前的一致
    local endCurve = goalWheel + math.random(40,40) * 360--圈数
    self.lastCurve = endCurve % 360

    currFeel.RemapCurveOne = endCurve
    currFeel.AnimateRotationDuration = math.random(7,7)--时长
    
    FeelUtil.PlayFeel(self.mfeel.gameObject, "turnFinish", false)

    if not isBurst then 
        local saveTime = RouletteUI:SaveBurstTime(true)
        RouletteUI:SaveBurstTime(false, saveTime + 1)
    else
        RouletteUI:SaveBurstTime(false, 0)
    end    
    self:RefreshBrustProgress()
	local diamondDispGo = self:GetGoOrNil("RootPanel/diamonds")
    local wheelTicketGo = self:GetGoOrNil("RootPanel/wheelTickets")
	if diamondDispGo then
        diamondDispGo:SetActive(false)
    end
    if wheelTicketGo then
        wheelTicketGo:SetActive(false)
    end
    EventManager:RegEvent("turnFinish", function()
        if diamondDispGo then
            diamondDispGo:SetActive(true)
        end
        if wheelTicketGo then
            wheelTicketGo:SetActive(true)
        end 
        SoundEngine:StopSFX(self.rotateSFX)
        -- if typeName == "diamond" then
        --     ResMgr:AddDiamond(value)
        -- elseif typeName == "cash" then
        --     ResMgr:AddCash(value, nil, nil, nil, true)
        -- end

        --奖励领取完才能点击，否则界面打开的空档可操作会导致报错和IOS闪退
        local blockGO = self:GetGoOrNil("block")
        if blockGO then
            blockGO:SetActive(true)
        end
        GameUIManager:SetEnableTouch(true, "转盘")

        MainUI:UpdateResourceUI()
        self:LightAnima(false)
        GameTableDefine.PurchaseSuccessUI:SuccessBuy(shopId, function()
            self:refreshRoulette()

            if not isBurst then
                self:RefreshLight(1)
            else
                self:LightAnima(false)
                self:RefreshLight(0)
            end

            self:RefreshTurnButton()
            if blockGO then
                blockGO:SetActive(false)
            end
        end, false, false, true, function()
            EventManager:DispatchEvent("ROTARY_TABLE_LOTTERY")
        end)
    end)
end

function RouletteUIView:RefreshLight(addValue)
    --初始化灯光

    local saveTime = RouletteUI:SaveBurstTime(true)
    local needTime = RouletteUI:GoalBurstTime()
    if saveTime > needTime then
        saveTime = needTime
    end

    if allLight == nil then--初始化边上的小灯
        allLight = {}
        allLightFeel = {}
        --一个个创建灯,然后把图片存下来
        --从saveTime开始往后,去点亮addValue个灯
        local prefab = self:GetGo("RootPanel/content/light/1")
        local parent = self:GetTrans("RootPanel/content/light")
        local go = nil

        local eachAngle = 360 / lightCount
        local currAngle = 0

        for i = 1, lightCount do
            go = GameObject.Instantiate(prefab, parent)
            go.name = i
            UnityHelper.SetLocalRotation(go.transform, 0, 0, currAngle)
            currAngle = currAngle - eachAngle
            --旋转
            allLight[i] = {self:GetGo(go, "on"), self:GetGo(go, "off")}
            allLightFeel[i] = self:GetComp(go, "lightFB", "MMFeedbacks")
            -- if i <= saveTime then
            --     allLight[i][1]:SetActive(true)
            -- end
        end

        prefab:SetActive(false)
        self:LightAnima(false)
        return
    end

    if saveTime >= needTime then--满足旋转条件,如果没有特殊商品了,就不再转了
        --灯光闪烁
        GameUIManager:SetEnableTouch(false, "转盘")
        self:LightAnima(false)
         --大保底赠送抽奖
         self.shingSFX = SoundEngine:PlaySFX(SoundEngine.WHEEL_SHING,false,function ()
            self:TurnRound(true)
            self:LightAnima(true)
        end)
        local feel = self:GetComp("RootPanel/prog/Slider/token/flyFB", "MMFeedbacks")
        feel:PlayFeedbacks()
        print("特殊抽奖动画")

        -- GameTimer:CreateNewTimer(lightTime, function()
        --     self:LightAnima(false)
        --     GameTimer:CreateNewTimer(shingTime, function()
        --         --大保底赠送抽奖
        --         self.shingSFX = SoundEngine:PlaySFX(SoundEngine.WHEEL_SHING,false,function ()
        --             self:TurnRound(true)
        --             self:LightAnima(true)
        --         end)
        --         local feel = self:GetComp("RootPanel/prog/Slider/token/flyFB", "MMFeedbacks")
        --         feel:PlayFeedbacks()
        --         print("特殊抽奖动画")
        --     end)
        -- end)

        -- GameTimer:CreateNewTimer(3, function()
        --     self:LightAnima(true)
        --     self:TurnRound(true)
        -- end)
        --self:TurnRound(true)
        --钻盘结束之后停止再次刷新灯光,全灭
    end
end

function RouletteUIView:LightAnima(turn)
    local total = lightCount
    local currImages = nil

    if self.m_cusTimer["light"] then
        GameTimer:StopTimer(self.m_cusTimer["light"])
    end

    if self.shingSFX then
        SoundEngine:StopSFX(self.shingSFX)
    end
    if self.shingRotateSFX then
        SoundEngine:StopSFX(self.shingRotateSFX)
    end

    if turn == true then--旋转转盘的动画
        self.shingRotateSFX = SoundEngine:PlaySFX(SoundEngine.WHEEL_SHING_ROTATE)

        local currIndex = 1
        local totalDis = {}
        local tempIndex = 1

        local turnLight = nil
        turnLight = function()
            currIndex = currIndex % total
            totalDis = {}

            local dealNum = total
            local lastIndex = currIndex
            while dealNum > 0 do
                table.insert(totalDis, lastIndex)
                lastIndex = lastIndex + rotateLength + rotateDistance
                lastIndex = lastIndex % total
                dealNum = dealNum - rotateLength - rotateDistance
            end

            for k,v in pairs(totalDis) do
                for i = 0, rotateLength - 1 do
                    tempIndex = v + i
                    if tempIndex > total then
                        tempIndex = tempIndex % total
                    end
                    if allLight[tempIndex] then
                        allLight[tempIndex][1]:SetActive(true)
                    end
                end
            end

            self.m_cusTimer["light"] = GameTimer:CreateNewTimer(rotateBetween, function()
                for k,v in pairs(totalDis) do
                    for i = 0, rotateLength - 1 do
                        tempIndex = v + i
                        if tempIndex > total then
                            tempIndex = tempIndex % total
                        end
                        if allLight[tempIndex] then
                            allLight[tempIndex][1]:SetActive(false)
                        end
                    end
                end

                currIndex = currIndex + rotateLength
                turnLight()
            end)
        end

        turnLight()

    elseif turn == false then--静止的动画
        --self.shingSFX = SoundEngine:PlaySFX(SoundEngine.WHEEL_SHING)

        local setImage = function(lightSet)
            for i = 1, total do
                currImages = allLight[i]
                if i % 2 == 0 then
                    currImages[1]:SetActive(lightSet)
                else
                    currImages[1]:SetActive(not lightSet)
                end
            end
        end

        local lastState = true
        self.m_cusTimer["light"] = GameTimer:CreateNewTimer(shingBetween, function()
            setImage(lastState)
            lastState = not lastState
        end, true)
    end
end

function RouletteUIView:ChangeLight(index, open)
    if allLight == nil or allLightFeel == nil then
        return
    end

    local currImage = allLight[index]
    local currFeel = allLightFeel[index]

    if currImage == nil or currFeel == nil then
        return
    end
    
    local toOpen = function(index)
        currFeel:PlayFeedbacks()
    end

    local toClose = function(index)
        currImage[1]:SetActive(false)
    end

    if open == true then
        toOpen(index)
    elseif open == false then
        toClose(index)
    else
        local isOpen = currImage[1].activeSelf
        if isOpen then
            toClose(index)
        else
            toOpen(index)
        end
    end
end

function RouletteUIView:refreshRoulette()--刷新转盘内容
    local root = self:GetGo("RootPanel/content/area")
    local cfg = ConfigMgr.config_wheel

    local num = #cfg
    local currNode = nil
    local currData = nil

    self:RefreshDiamondText()

    for i = 1, num do
        currNode = self:GetGo(root, i.."")
        currData = cfg[i]

        local image = self:GetComp(currNode, "icon", "Image")
        local bgImage = self:GetComp(currNode, "", "Image")
        local icon,value
        local bg = "bg_wheel_normal"
        local shopIndex = 1
        local mCfg


        if currData.num == 1 and ShopManager:BoughtBefor(currData.shopId[shopIndex]) then
            shopIndex = 2
            mCfg = ShopManager:GetCfg(currData.shopId[shopIndex])

            --特殊处理RectTransform
            local rect = self:GetComp(currNode,"icon","RectTransform")
            rect.anchoredPosition3D = V3(0,100,0)
            rect.sizeDelta = V2(180,180)
            local num = self:GetGo(currNode,"num")
            num:SetActive(true)
            local count = ShopManager:GetValue(mCfg)
            self:SetText(currNode,"num",count)
            local outline = self:GetComp(currNode,"icon","UI_outline")
            outline.OutlineWidth = 8
        end
        
        local iconBtn = self:GetComp(currNode, "icon", "Button")

        if shopIndex == 1 and currData.num == 1 then--特殊的            
            self:BindSpecialShow(i, iconBtn, currData.shopId[shopIndex])
        else--普通的
            self:BindSpecialShow(i, iconBtn, nil)            
            image.gameObject.transform.sizeDelta = V2(150,150)
        end
        
        bg = "bg_wheel_" .. currData.image

        icon = currData.icon[shopIndex]

        mCfg = ShopManager:GetCfg(currData.shopId[shopIndex])
        if mCfg.type == 9 then
            icon = mCfg.icon
        end
        value = ShopManager:GetValue(mCfg)
        value = ShopManager:GetWheelShow(value, mCfg)
        self:SetSprite(image, "UI_Shop", icon, nil, true)
        self:SetSprite(bgImage, "UI_Shop", bg, nil, true)
        if mCfg.type == 9 or mCfg.type == 8 then
            value = math.floor(mCfg.amount * 60 )
            self:SetText(currNode, "num", value .. "Min")
        else    
            self:SetText(currNode, "num", value .. "")
        end
    end
end

function RouletteUIView:BindSpecialShow(index, btn, shopId)
    if self.bindBtn == nil then
        self.bindBtn = {}
    end

    if self.bindBtn[index] == shopId then
        return
    end

    if shopId then
        self:SetButtonClickHandler(btn, function()
            self:ShowPetInfo(shopId)
        end)
    else
        self:SetButtonClickHandler(btn, function()
        end)
    end

    self.bindBtn[index] = shopId
end

function RouletteUIView:ShowPetInfo(shopId)
    local root = self:GetGo("RootPanel/petInfo")

    --从shopId,转换到config_pets,config_employees还有些绕
    --而且之后搞不好有不给宠物了,而是其他的,那就更麻烦了
    --先简单处理了...

    local cfgNeed = nil
    for k,v in pairs(ConfigMgr.config_pets) do
        if v.shopId == shopId then
            cfgNeed = v
            break
        end
    end

    if cfgNeed == nil then
        return
    end

    local icon = self:GetComp(root, "bg/frame/icon", "Image")
    self:SetSprite(icon, "UI_Shop", cfgNeed.icon, nil, true)
    self:SetText(root, "bg/name", GameTextLoader:ReadText(cfgNeed.name))
    self:SetText(root, "bg/desc", GameTextLoader:ReadText(cfgNeed.desc))

    local allType = {"mood", "income", "offline"}
    local currType = nil
    local currValue = 0
    for k,v in pairs(allType) do
        if cfgNeed[v] ~= nil then
            currType = v
            currValue = cfgNeed[v]
            break
        end
    end

    local buffRoot = self:GetGo(root, "bg/buff")
    for k,v in pairs(allType) do
        self:GetGo(buffRoot, v):SetActive(v == currType)
    end

    local buffGo = self:GetGo(buffRoot, currType)

    if currType == "income" then
        currValue = currValue * 100 .. "%"
    elseif currType == "offline" then
        --currValue = currValue .. "Hrs"
        currValue = currValue
    end

    self:SetText(buffGo, "num", currValue)

    local btnClose = self:GetComp(root, "", "Button")
    self:SetButtonClickHandler(btnClose, function()
        root:SetActive(false)
    end)

    root:SetActive(true)
end

--刷新钻石数量
function RouletteUIView:RefreshDiamondText()
    self:SetText("RootPanel/diamonds/num", Tools:SeparateNumberWithComma(ResMgr.GetDiamond()))
end


return RouletteUIView