local SeasonPassUIView = require("GamePlay.Common.UI.SeasonPassUIView")
local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3  ---@type UnityEngine.Vector3
local AnimationUtil = CS.Common.Utils.AnimationUtil ---@type Common.Utils.AnimationUtil
local CoinPusherManager = GameTableDefine.CoinPusherManager
local ConfigMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local ShopManager = GameTableDefine.ShopManager
local FeelUtil = CS.Common.Utils.FeelUtil
local GameObject = CS.UnityEngine.GameObject ---@type UnityEngine.GameObject
local UnityEngineTime = CS.UnityEngine.Time ---@type UnityEngine.Time
local SeasonPassManager = GameTableDefine.SeasonPassManager
local ChooseUI = GameTableDefine.ChooseUI
local EventManager = require("Framework.Event.Manager")
local SoundEngine = GameTableDefine.SoundEngine


local rewardsConfig = ConfigMgr.config_pass_point_reward
local CollectList = {} ---@type SeasonPassFlyIconResInfo[]
local pushedDoubleList = {}
local doubleVFXDuration = 0
local doubleVFXFlyDuration = 0
local doubleVFXFlyTimer = 0
local doubleVFXTimer = 0


function SeasonPassUIView:ctorGame()
    self.m_gameRootGO = nil
    self.m_mapCellTable = nil
    self.m_columns = nil ---@type UnityEngine.Transform[]
    self.m_chooseBtn = nil
    self.m_playBtn = nil
    self.m_resetBtn = nil
    self.m_resetTipBtn = nil
    self.m_buyPackBtn = nil
    self.m_fistAnims = nil ---@type UnityEngine.Animator[]
    self.m_fistGOs = nil ---@type UnityEngine.GameObject[]
    self.m_pointRewardList = nil
    self.m_doubleVFX = nil
    self.m_doubleVFXCopy = nil
    self.m_doubleVFXTimer = nil
    self.m_doubleCurve = nil
    self.m_timer = nil
    CoinPusherManager:Init()

end


---加载完这一界面时调用
function SeasonPassUIView:OnEnterGameView()
    self.m_gameRootGO = self.m_subGODic[SeasonPassUIView.PageType.Game]
    self.m_timer = {}

    self.m_mapCellTable = {}
    self.m_columns = {}
    local mapRoot = self:GetGo(self.m_gameRootGO, "bg2/gamePanel/bg1/game/mask/columnGroup")
    local columnGOs = UnityHelper.GetAllChilds(mapRoot)
    for columnIndex = 0, columnGOs.Length - 1 do
        table.insert(self.m_columns, columnGOs[columnIndex])
        local rowGOs = UnityHelper.GetAllChilds(columnGOs[columnIndex])
        for rowIndex = 0, rowGOs.Length - 1 do
            if not self.m_mapCellTable[rowIndex + 1] then
                self.m_mapCellTable[rowIndex + 1] = {}
            end
            self.m_mapCellTable[rowIndex + 1][columnIndex + 1] = rowGOs[rowIndex]
        end
    end
    
    self.m_chooseBtn = self:GetComp(self.m_gameRootGO, "bg2/choosePanel/chooseBtn", "Button")
    self.m_playBtn = self:GetComp(self.m_gameRootGO, "bg2/btnBanel/trunBtn", "Button")
    self.m_resetBtn = self:GetComp(self.m_gameRootGO, "bg2/btnBanel/resetBtn", "Button")
    self.m_resetTipBtn = self:GetComp(self.m_gameRootGO, "bg2/btnBanel/cantResetBtn", "Button")
    self.m_buyPackBtn = self:GetComp(self.m_gameRootGO, "bg2/btnBanel/buyBtn", "Button")
    self.m_pointRewardList = self:GetComp(self.m_gameRootGO, "bg2/choosePanel/titleBanel/ScrollRectEx", "ScrollRectEx")
    self.m_doubleVFX = self:GetGo("vfx/doubleVFX")
    self.m_fistAnims = {}
    self.m_fistGOs = {}
    local fistRoot = self:GetGo(self.m_gameRootGO, "bg2/gamePanel/bg1/game/mask/fistGroup")
    local fistGOs = UnityHelper.GetAllChilds(fistRoot)
    for i = 0, fistGOs.Length - 1 do
        local fistGO = self:GetGo(fistGOs[i], "fist")
        local curAnimator = self:GetComp(fistGOs[i], "", "Animator")
        table.insert(self.m_fistAnims, curAnimator)
        table.insert(self.m_fistGOs, fistGO)
    end
    
    local curver = self:GetComp(self.m_doubleVFX, "", "Curver")
    self.m_doubleCurve = curver:GetCurve("double")
    doubleVFXDuration = self.m_doubleCurve.keys[2].time
    doubleVFXFlyDuration = self.m_doubleCurve.keys[1].time
    self:SetButtonClickHandler(self.m_playBtn, function()
        local canPush = CoinPusherManager:CanPush()
        local needNum = CoinPusherManager:GetNeedTicket()
        local ticketEnough = CoinPusherManager:GetTicketNum() >= needNum
        --local canPlay = canPush and ticketEnough
        if not canPush then
            return
        end
        if not ticketEnough then -- 门票不足时，点击抽奖按钮，若门票限时礼包限购次数>0，弹出门票限时礼包
            GameTableDefine.SeasonPassPackUI:OpenView()
            return
        end
        if not CoinPusherManager:CheckHaveOpenChooseView() then --- 如果这个活动周期内, 没有进入过choose页面, 先强制进一次
            self:OnShowGameChooseView()
            return
        end
        
        local pushColumn = CoinPusherManager:GetRandomPushColumn()
        if not pushColumn then
            return
        end
        for i = 1, #pushColumn do
            self:PushCoin(pushColumn[i])
        end
        SoundEngine:PlaySFX(SoundEngine.SEASONPASS_TUIBIJI_TUIBI)
        CoinPusherManager:AddPlayTime()
        CoinPusherManager:UseTicket(needNum)
        --2024-12-31fy添加用于埋点，玩小游戏成功一次
        GameSDKs:TrackForeign("pass_game_draw", {push = Tools:GetTableSize(pushColumn) or 0})
         --2024-12-25 fy添加通行证任务可领取红点
        self:RefreshTaskHintPoint()
        self:ShowPlayBtn()
        GameUIManager:SetEnableTouch(false, "推币机, 开始推币") -- 禁止输入
        self.m_playBtn.interactable = false
        self:RefreshGameHintPoint()
    end)
    
    self:SetButtonClickHandler(self.m_resetBtn, function()
        ChooseUI:CommonChoose("TXT_PASS_REWARD_CNYEAR_Reset", function()
            --2024-12-31fy添加用于埋点，手动重置埋点
            GameSDKs:TrackForeign("pass_game_reset", {time = CoinPusherManager:GetTotalResetMapTimes(), lasttime_ticket = CoinPusherManager:GetLastTimeCostTickets(), reset_type = 1})
            CoinPusherManager:ResetMap()
            CoinPusherManager:ResetPlayTime()
            self:InitMap()
            self:InitFistPos()
            self:RefreshGameView()
            
        end, true)
    end)
    
    self:SetButtonClickHandler(self.m_resetTipBtn, function()
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_PASS_DESC9_CNYEAR_RULE"))
    end)

    --2024-12-25 fy添加用于打开奖品选择界面
    self:SetButtonClickHandler(self.m_chooseBtn, function() 
        self:OnShowGameChooseView()
    end)

    self:SetButtonClickHandler(self.m_buyPackBtn, function()
        GameTableDefine.SeasonPassPackUI:OpenView()
    end)
    self:InitPointRewards()
    self:RefreshGameHintPoint()

end

function SeasonPassUIView:OnShowGameView()
    self:InitMap()
    self:InitFistPos()
    self:RefreshGameView()
end

function SeasonPassUIView:RefreshGameView()
    self:ShowPlayBtn()
    self:ShowPointRewards()
    self:ShowChooseBtn()
    self:ShowBuyPackBtn()
    self:ShowResetMapBtn()
end


---离开这一界面或关闭整个界面(当前正在此界面)时调用
function SeasonPassUIView:OnExitGameView(isCloseView)
    for k, v in pairs(self.m_timer) do
        GameTimer:StopTimer(v)
        v = nil
    end
    self:ResetDoubleVFX()
    GameTableDefine.MainUI:UpdateResourceUI()
    
end

function SeasonPassUIView:InitMap()
    local mapData = CoinPusherManager:GetMapData()
    for row = 1, #mapData do
        for column = 1, #mapData[row] do
            -- 显示每个格子中的内容
            self:RefreshMapCell(row, column)
        end
    end
end

function SeasonPassUIView:RefreshMapCell(row, column)
    local mapData = CoinPusherManager:GetMapData()
    local cell = self.m_mapCellTable[row][column]
    local awardCfg, shopCfg = CoinPusherManager:GetTheAwardCfd(row, column)
    self:SetSprite(self:GetComp(cell, "icon", "Image"), "UI_Shop", shopCfg.icon)
    local multiple = CoinPusherManager:GetTheMapDataMultiple(row, column)
    self:SetText(cell, "num", awardCfg.item_num * multiple)
    self:GetGo(cell, "double/1"):SetActive(shopCfg.type == 39)
    self:GetGo(cell, "double/2"):SetActive(mapData[row][column].double)
    if shopCfg.type == 9 then
        local shopAmount = shopCfg.amount
        self:SetText(cell, "num", math.floor(shopAmount * awardCfg.item_num * multiple * 60) .. "Min")
        if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
            local useIcon = shopCfg.icon.."_euro"
            self:SetSprite(self:GetComp(cell, "icon", "Image"), "UI_Shop", useIcon)
        end
    end
    self:SetButtonClickHandler(self:GetComp(cell, "icon", "Button"), function()
        local name = GameTextLoader:ReadText(shopCfg.name)
        local desc = GameTextLoader:ReadText(shopCfg.desc)
        self:OpenRewardInfo(cell, name, desc)
    end)
    
end

function SeasonPassUIView:InitAwardPos()
    local mapPos = CoinPusherManager:GetCurMapPos()
    for i = 1, #self.m_columns do
        self.m_columns[i].transform.position = self.m_fistGOs[i].transform.position
    end
end

function SeasonPassUIView:InitFistPos()
    local mapPos = CoinPusherManager:GetCurMapPos()
    for i = 1, #self.m_fistAnims do
        local indexStr = mapPos[i] == 0 and "" or ("_" .. mapPos[i])
        local clipName = "idle" .. indexStr
        AnimationUtil.AddKeyFrameEventOnObj(self.m_fistAnims[i].gameObject, "ANIM_END", function()
            self:InitAwardPos()
        end)
        self.m_fistAnims[i]:Play(clipName)
    end
end

function SeasonPassUIView:PushCoin(index)
    local animator = self.m_fistAnims[index]
    if self.m_timer[index] then
        GameTimer:StopTimer(self.m_timer[index])
        self.m_timer[index] = nil
    end
    
    AnimationUtil.AddKeyFrameEventOnObj(self.m_fistAnims[index].gameObject, "HIT_START", function()
        self.m_timer[index] = GameTimer:CreateNewMilliSecTimer(1, function()
            self.m_columns[index].transform.position = self.m_fistGOs[index].transform.position
        end, true, true)
        CoinPusherManager:PushCoin(index) --推币存档
    end)
    AnimationUtil.AddKeyFrameEventOnObj(self.m_fistAnims[index].gameObject, "HIT_STOP", function()
        GameTimer:StopTimer(self.m_timer[index])
        self.m_timer[index] = nil
       
        self:GetPushedAward(index)
        if Tools:GetTableSize(self.m_timer) == 0 then -- 推币结束判断,每次推币无论推几个, 都只会执行一次
            printf("推币结束")
            GameUIManager:SetEnableTouch(true, "推币机, 推币结束") -- 允许输入
            self:RefreshGameView()
            if Tools:GetTableSize(CollectList) == 0 then    -- 只有双倍球
                if #pushedDoubleList > 0 then
                    self:OnGetDoubleBall()
                end
            else
                GameUIManager:SetEnableTouch(false)
                self.m_playBtn.interactable = false
                self:FlyIcon(CollectList, function()    -- 有普通奖励
                    CollectList = {}
                    if not CoinPusherManager:CanPush() then
                        --2024-12-31fy添加用于埋点，自动重置埋点
                        GameSDKs:TrackForeign("pass_game_reset", {time = CoinPusherManager:GetTotalResetMapTimes(), lasttime_ticket = CoinPusherManager:GetLastTimeCostTickets(), reset_type = 2})
                        CoinPusherManager:ResetMap()
                        CoinPusherManager:ResetPlayTime()
                        self:InitMap()
                        self:InitFistPos()
                        self:RefreshGameView()
                        
                    end
                    GameUIManager:SetEnableTouch(true)
                    self:ShowPlayBtn()

                    if #pushedDoubleList > 0 then
                        self:OnGetDoubleBall()
                    end
                end)
            end
        end
    end)
    local mapPos = CoinPusherManager:GetCurMapPos()
    local indexStr = "_" .. (mapPos[index] + 1)
    local clipName = "hit" .. indexStr
    animator:Play(clipName)
end

function SeasonPassUIView:GetPushedAward(index)
    local mapPos = CoinPusherManager:GetCurMapPos()
    local pushedRow = 5 - mapPos[index] + 1
    local awardCfg, shopCfg = CoinPusherManager:GetTheAwardCfd(pushedRow, index)
    local multiple = CoinPusherManager:GetTheMapDataMultiple(pushedRow, index)
    ShopManager:Buy_LimitPackReward(shopCfg.id, false, function()
        print("SeasonPassUIView_Game Get ", shopCfg.id)
        if shopCfg.type == 39 then
            table.insert(pushedDoubleList, { row = pushedRow, column = index })
            return
        end
        self:CollectRewards(shopCfg, awardCfg.item_num * multiple)

        --通行证小游戏票数量变化埋点
        if shopCfg and shopCfg.type == 37 then
            local leftTicket = CoinPusherManager:GetTicketNum()
            GameSDKs:TrackForeign("pass_ticket", {behavior = 1,num = tonumber(multiple * awardCfg.item_num * shopCfg.amount),left = leftTicket,source = 3})
        end
        --2025-1-7fy 奖励获取埋点添加钻石,现金
        if shopCfg.type == 3 then
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证小游戏", behaviour = 1, num_new = tonumber(multiple * awardCfg.item_num * shopCfg.amount)})
        end
        if shopCfg.type == 9 then
            local resType = GameTableDefine.ResourceManger:GetShopCashType(shopCfg.country)
            local countryCode = 1
            local amount = multiple * awardCfg.item_num * shopCfg.amount * 3600 / 30
            local num = GameTableDefine.FloorMode:GetTotalRent() * amount
            if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                num = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * amount
                countryCode = 2
            end
            GameSDKs:TrackForeign("cash_event", {type_new = tonumber(countryCode), change_new = 0, amount_new = tonumber(num) or 0, position = "通行证小游戏"})
        end
    end, nil, multiple * awardCfg.item_num)
end

function SeasonPassUIView:CollectRewards(shopCfg, num)
    num = num or 1
    if CollectList[shopCfg.id] then
        CollectList[shopCfg.id].num = CollectList[shopCfg.id].num + num
    else
        CollectList[shopCfg.id] = { id = shopCfg.id, num = num }
    end
end

function SeasonPassUIView:ShowPlayBtn()
    local needNum = CoinPusherManager:GetNeedTicket()
    local haveNum = CoinPusherManager:GetTicketNum()
    self:SetText(self.m_playBtn.gameObject, "have", haveNum, needNum > haveNum and "ff1c1c" or "ffffff")
    self:SetText(self.m_playBtn.gameObject, "need", needNum)
    self:SetText(self.m_gameRootGO, "bg2/btnBanel/trunBtn/cantTrunMask/have", haveNum, needNum > haveNum and "ff1c1c" or "ffffff")
    self:SetText(self.m_gameRootGO, "bg2/btnBanel/trunBtn/cantTrunMask/need", needNum)
    --self.m_playBtn.interactable = haveNum >= needNum and CoinPusherManager:CanPush()
    self.m_playBtn.interactable = true
    self:GetGo(self.m_gameRootGO, "bg2/btnBanel/redTip"):SetActive(haveNum >= needNum)
end


function SeasonPassUIView:InitPointRewards()
    local count = #rewardsConfig
    self:SetListItemCountFunc(self.m_pointRewardList, function()
        return count
    end)
    self:SetListItemNameFunc(self.m_pointRewardList, function(index)       
        return "Item"
    end)    
    self:SetListUpdateFunc(self.m_pointRewardList, handler(self, self.UpdateRewardsList))
end

function SeasonPassUIView:UpdateRewardsList(index, trans)
    index = index + 1
    local go = trans.gameObject
    
    local curPoint, curLevel = CoinPusherManager:GetPointAndLevel()
    local nextLevel = ConfigMgr.config_pass_point_reward[curLevel + 1] and curLevel + 1 or curLevel
    local curMax = ConfigMgr.config_pass_point_reward[index].point
    self:SetText(go, "Reward/starLevel", curMax)
    local canClaim = CoinPusherManager:CheckCanClaim(index)
    local haveGot = (not canClaim) and nextLevel >= index
    self:GetGo(go, "Reward/done"):SetActive(haveGot)
    if index < nextLevel then
        self:GetComp(go, "Slider", "Slider").value = 1
    elseif index == nextLevel then
        local tmpCurLevel = curLevel == nextLevel and curLevel - 1 or curLevel
        local lastPoint = rewardsConfig[tmpCurLevel] and rewardsConfig[tmpCurLevel].point or 0
        local percentage = (curPoint - lastPoint) / (rewardsConfig[nextLevel].point - (rewardsConfig[tmpCurLevel] and rewardsConfig[tmpCurLevel].point or 0))
        self:GetComp(go, "Slider", "Slider").value = percentage
    else
        self:GetComp(go, "Slider", "Slider").value = 0
    end
    local animator = self:GetComp(go, "Reward", "Animator")
    if index > curLevel then
        animator:Play("UI_tuibiji_gameBth_reward_normal")
    elseif canClaim and (nextLevel > index or (index == #ConfigMgr.config_pass_point_reward) and index == curLevel) then
        animator:Play("UI_tuibiji_gameBth_reward_ready")
    elseif haveGot then
        animator:Play("UI_tuibiji_gameBth_reward_done")
    end
    local awardBtn = self:GetComp(go, "Reward", "Button")
    awardBtn.interactable = canClaim and (nextLevel > index or (index == #ConfigMgr.config_pass_point_reward) and index == curLevel) or
        index > curLevel

    self:SetButtonClickHandler(awardBtn, function()
        if nextLevel <= index and not (canClaim and nextLevel >= index) then
            local awardCfgList = ConfigMgr.config_pass_point_reward[index].normal_rewards
            local list = {} ---@type SeasonPassRewardInfoList[]
            for i = 1, #awardCfgList do
                local awardInfo = awardCfgList[i]
                local shopCfg = ShopManager:GetCfg(awardInfo.id)
                list[i] = {}
                list[i].icon = shopCfg.icon
                list[i].num = shopCfg.amount * awardInfo.num
            end
            self:OpenRewardsInfoWithIcon(awardBtn.gameObject, list)
            return
        end
        local awardCfgList = CoinPusherManager:GetPointAward(index).normal_rewards
        for i = 1, #awardCfgList do
            local awardInfo = awardCfgList[i]
            local shopCfg = ShopManager:GetCfg(awardInfo.id)
            self:CollectRewards(shopCfg, awardInfo.num)
            ShopManager:Buy_LimitPackReward(shopCfg.id, false, function()
                --通行证小游戏票数量变化埋点
                if shopCfg and shopCfg.type == 37 then
                    local leftTicket =CoinPusherManager:GetTicketNum()
                    GameSDKs:TrackForeign("pass_ticket", {behavior = 1,num = awardInfo.num * shopCfg.amount,left = leftTicket,source = 4})
                end
                --2025-1-7fy 奖励获取埋点添加钻石,现金
                if shopCfg.type == 3 then
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证游戏积分宝箱", behaviour = 1, num_new = tonumber(awardInfo.num * shopCfg.amount)})
                end
            end, nil, awardInfo.num)
        end
        self:ShowPointRewards()
        self:FlyIcon(CollectList, function()    -- 有普通奖励
            self:RefreshGameView()

            CollectList = {}
            if #pushedDoubleList > 0 then
                self:OnGetDoubleBall()
            end
        end)
    end)
end

function SeasonPassUIView:ShowPointRewards()
    self.m_pointRewardList:UpdateData(true)
    local curPoint, curLevel = CoinPusherManager:GetPointAndLevel()
    --self.m_pointRewardList:SetSnapIndex(curLevel)
    self:SetText(self.m_gameRootGO, "bg2/choosePanel/titleBanel/head/starLevel", curPoint)
    
    --锁定视角
    local curHighestLevel = CoinPusherManager:GetSmallestAvailable()
    if curHighestLevel >= 1 then   -- 不到一级时会抖一下
        local contentPos = self.m_pointRewardList.content.anchoredPosition
        contentPos.x = -(curHighestLevel - 1) * 150
        self.m_pointRewardList:ScrollToPos(contentPos)
    end

end

function SeasonPassUIView:OnGetDoubleBall()
    -- 播放双倍特效
    self.m_doubleVFXCopy = {}

    self.m_doubleVFX:SetActive(true)
    self.m_playBtn.interactable = false
    
    for i = 1, #pushedDoubleList do
        CoinPusherManager:ChooseADoubleAward(function(row, column)
            print("播放双倍特效  ", row, ", ", column)
            local posIndex = pushedDoubleList[i]
            local pos = self.m_mapCellTable[posIndex.row][posIndex.column].transform.position
            local targetPos = self.m_mapCellTable[row][column].transform.position
            posIndex.startPos = pos
            posIndex.endPos = targetPos
            posIndex.targetRow = row
            posIndex.targetColumn = column
            local vfx = self:GetGo(self.m_doubleVFX, "vfx")
            local newVFX = GameObject.Instantiate(vfx, self.m_doubleVFX.transform)
            newVFX.transform.position = pos
            newVFX:SetActive(true)
            table.insert(self.m_doubleVFXCopy, newVFX)
        end)
    end

    doubleVFXTimer = 0
    self.m_doubleVFXTimer = GameTimer:CreateNewMilliSecTimer(1, function()
        if doubleVFXFlyTimer < doubleVFXFlyDuration then
            doubleVFXFlyTimer = doubleVFXFlyTimer + UnityEngineTime.deltaTime
            local curValue = self.m_doubleCurve:Evaluate(doubleVFXFlyTimer / doubleVFXFlyDuration)
            for i = 1, #pushedDoubleList do
                local vfxInfo = pushedDoubleList[i]
                local VFXGo = self.m_doubleVFXCopy[i]
                VFXGo.transform.position = Vector3.Lerp(vfxInfo.startPos, vfxInfo.endPos, curValue)
            end
        else
            for i = 1, #pushedDoubleList do
                local vfxInfo = pushedDoubleList[i]
                local cell = self.m_mapCellTable[vfxInfo.targetRow][vfxInfo.targetColumn]
                local cellAnim = self:GetComp(cell, "num", "Animator")
                AnimationUtil.AddKeyFrameEventOnObj(self:GetGo(cell, "num"), "ANIM_NUM", function()
                    self:RefreshMapCell(vfxInfo.targetRow, vfxInfo.targetColumn)
                end)
                if not vfxInfo.isPlay then
                    vfxInfo.isPlay = true
                    cellAnim:Play("UI_tuibiji_gameui_itemnum_double")
                end
            end   
        end
        if doubleVFXTimer < doubleVFXDuration then
            doubleVFXTimer = doubleVFXTimer + UnityEngineTime.deltaTime
        else
            self:ResetDoubleVFX()

        end
    end, true, false)

end

function SeasonPassUIView:ResetDoubleVFX()
    if self.m_doubleVFXTimer then
        GameTimer:StopTimer(self.m_doubleVFXTimer)
        self.m_doubleVFXTimer = nil
    end
    if self.m_doubleVFXCopy then
        for i = #self.m_doubleVFXCopy, 1, -1 do
            GameObject.Destroy(self.m_doubleVFXCopy[i])
        end
        self.m_doubleVFXCopy = {}
    end
    self.m_doubleVFX:SetActive(false)
    self:ShowPlayBtn()
    doubleVFXTimer = 0
    doubleVFXFlyTimer = 0
    pushedDoubleList = {}
end

function SeasonPassUIView:ShowChooseBtn()
    self.m_chooseBtn.interactable = CoinPusherManager:GetPlayTime() == 0
end

function SeasonPassUIView:ShowBuyPackBtn()
    self.m_buyPackBtn.interactable = SeasonPassManager:CanBuyPack()
end

function SeasonPassUIView:RefreshGameHintPoint()
    if not self.m_gameHintPoint or self.m_gameHintPoint:IsNull() then
        self.m_gameHintPoint = self:GetGo("RootPanel/tabPanel/gameBtn/normal/tip")
    end
    if not self.m_gameHintPointSelect or self.m_gameHintPointSelect:IsNull() then
        self.m_gameHintPointSelect = self:GetGo("RootPanel/tabPanel/gameBtn/select/tip")
    end
    local canPush = CoinPusherManager:CanPush()
    local needNum = CoinPusherManager:GetNeedTicket()
    local ticketEnough = CoinPusherManager:GetTicketNum() >= needNum
    local canPlay = canPush and ticketEnough
    local point, level = CoinPusherManager:GetPointAndLevel()
    local available = false
    for i = 1, level do
        if CoinPusherManager:CheckCanClaim(i) then
            available = true
            break
        end
    end
    if canPlay or available then
        self.m_gameHintPoint:SetActive(true)
        self.m_gameHintPointSelect:SetActive(true)
        return true
    end
    self.m_gameHintPoint:SetActive(false)
    self.m_gameHintPointSelect:SetActive(false)
    
    return false
end

function SeasonPassUIView:ShowResetMapBtn()
    if CoinPusherManager:CanReset() then
        self.m_resetTipBtn.gameObject:SetActive(false)
        self.m_resetBtn.interactable = true
    else
        self.m_resetTipBtn.gameObject:SetActive(true)
        self.m_resetBtn.interactable = false
    end
end