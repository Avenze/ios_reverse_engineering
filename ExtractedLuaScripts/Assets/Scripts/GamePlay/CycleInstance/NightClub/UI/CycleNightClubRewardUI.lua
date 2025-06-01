--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-01 12:18:23
]]
local CycleNightClubModel = nil
---@class CycleNightClubRewardUI
local CycleNightClubRewardUI = GameTableDefine.CycleNightClubRewardUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CEODataManager = GameTableDefine.CEODataManager
local FlyIconsUI = GameTableDefine.FlyIconsUI
local ResourceManger = GameTableDefine.ResourceManger

function CycleNightClubRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_REWARD_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--[[
    @desc:里程碑界面获取单个里程碑奖励发放 
    author:{author}
    time:2024-07-02 12:22:13
    --@rewards: 
    @return:
]]
function CycleNightClubRewardUI:ShowGetReward(rewards,isShopUIRequire, scrollIndex)
    local shopCfg = ConfigMgr.config_shop[rewards.shop_id]
    if shopCfg.type == 42 then
        return
    end
    if shopCfg.type == 44 then
        self:GetView():Invoke("ShowCEOCardsGet", rewards,isShopUIRequire, scrollIndex)
        return
    end
    self:GetView():Invoke("ShowGetReward", rewards,isShopUIRequire, scrollIndex)
end

function CycleNightClubRewardUI:GetAwardByShopId(conf, isNotSendCEOReard)
    local shopCfg = ConfigMgr.config_shop[conf.shop_id]
    if shopCfg.type == 3 or shopCfg.type == 4 or shopCfg.type == 29 or shopCfg.type == 42 or shopCfg.type == 43 or shopCfg.type == 44 then
        local amount = shopCfg.amount * conf.count
        if shopCfg.type == 3 then
            ResourceManger:AddDiamond(amount)
            --埋点
            --GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "循环副本里程碑", behaviour = 1, num_new = amount})
        elseif shopCfg.type == 4 then
            ResourceManger:AddTicket(amount)
--            GameSDKs:TrackForeign("ad_ticket", {behavior = 1, num_new = amount, source = "里程碑奖励"})
        elseif shopCfg.type == 29 then
            ResourceManger:AddWheelTicket(amount)
--            GameSDKs:TrackForeign("wheel_ticket", {behavior = 1, num_new = amount})
        elseif shopCfg.type == 42 and not isNotSendCEOReard then
            --CEO宝箱
            GameTableDefine.CEODataManager:OpenCEOBox(shopCfg.param[1], amount, false, nil, 2)
        elseif shopCfg.type == 43 and not isNotSendCEOReard then
            --CEO钥匙
            --GameSDKs:TrackForeign("ceo_key_change", {type = shopCfg.param[1], source = "玩具副本领取单个里程碑奖励", num = tonumber(amount)})
            GameTableDefine.CEODataManager:AddCEOKey(shopCfg.param[1], amount)
        elseif shopCfg.type == 44 and not isNotSendCEOReard then
            --CEO卡牌
            local lastDispRewards = {}
            for i = 1, amount do
                local ceoid = GameTableDefine.CEODataManager:GetCEOCardReward(shopCfg.param[1])
                local tmpTranDiamond = GameTableDefine.CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
                if tmpTranDiamond > 0 then
                    if not lastDispRewards.diamonds then
                        lastDispRewards.diamonds = tmpTranDiamond
                    else
                        lastDispRewards.diamonds  = lastDispRewards.diamonds + tmpTranDiamond
                    end
                    --给钻石
                    --GameSDKs:TrackForeign("ceo_card_change", {type = shopCfg.param[1], result = "diamond", source = "单个里程碑奖励获取"})
                    ResourceManger:AddDiamond(tmpTranDiamond)
                else
                    if not lastDispRewards.ceoids then
                        lastDispRewards.ceoids = {}
                    end
                    if not lastDispRewards.ceoids[ceoid] then
                        lastDispRewards.ceoids[ceoid] = 1
                    else
                        lastDispRewards.ceoids[ceoid]  = lastDispRewards.ceoids[ceoid] + 1
                    end
                    --给卡
                    --GameSDKs:TrackForeign("ceo_card_change", {type = shopCfg.param[1], result = tostring(ceoid), source = "单个里程碑奖励获取"})
                    GameTableDefine.CEODataManager:GetCEOCardByCEOID(ceoid)
                end
            end
            lastDispRewards.shop_id = conf.shop_id
            return true, lastDispRewards
        end
    else
        --首先判断是否要转换成钻石发放
        local addDiamond = CycleNightClubModel:GetSameShopItemConverToDiamond(conf.shop_id)
        if addDiamond > 0 then
            ResourceManger:AddDiamond(addDiamond)
        end

        ----小时现金
        --if shopCfg.type == 9 then
        --    local resType = ResourceManger:GetShopCashType(shopCfg.country)
        --    local cashType = 2
        --    local countryCode = 1
        --    local amount = shopCfg.amount * self.config_cy_instance_reward[level].count * 3600 / 30
        --    local num = GameTableDefine.FloorMode:GetTotalRent() * amount
        --    if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
        --        num = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * amount
        --        cashType = 6
        --        countryCode = 2
        --    end
        --    ResourceManger:Add(cashType, num, nil, nil, true)
        --    GameSDKs:TrackForeign("cash_event", {type_new = tonumber(countryCode), change_new = 0, amount_new = tonumber(num) or 0, position = "副本里程碑奖励"})
        --else
            GameTableDefine.ShopManager:Buy(conf.shop_id, false, nil, nil)
        --end
    end
end

--[[
    @desc:获取所有当前没有领取的里程碑奖励内容 
    author:{author}
    time:2024-07-02 12:22:43
    @return:
]]
function CycleNightClubRewardUI:ShowAllNotClaimRewardsGet(is_rank)
    CycleNightClubModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
    local allRewards
    if is_rank then
        allRewards = GameTableDefine.CycleNightClubRankManager:GetRankReward(true)
    else
        allRewards = CycleNightClubModel:GetAllSKRewardNotClaim()
    end

    local newAllRewards = {}
    --2025-3-4添加检测其相关内容根据CEO版本需要进行调整和修改
    --step1.首先把箱子替换出来，开箱且需要检测箱子类型，先开普通箱子，再开金色箱子
    -- itemReward = {shop_id = 1123,count = 1, level = 1}
    local normalBoxes = 0
    local premiumBoxes = 0
    local normalCards = 0
    local premiumCards = 0
    local normalKeys = 0
    local premiumKeys = 0
    local transformCEOIds = {}

    for _, itemReward in pairs(allRewards) do
        local shopCfg = ConfigMgr.config_shop[itemReward.shop_id]
        if shopCfg then
            if shopCfg.type == 42 or shopCfg.type == 44 or shopCfg.type == 43 then
                if shopCfg.type == 42 then
                    if shopCfg.param[1] == "normal" then
                        normalBoxes  = normalBoxes + itemReward.count
                    elseif shopCfg.param[1] == "premium" then
                        premiumBoxes  = premiumBoxes + itemReward.count
                    end
                end
                if shopCfg.type == 44 then
                    if shopCfg.param[1] == "normal" then
                        normalCards  = normalCards + itemReward.count
                    elseif shopCfg.param[1] == "premium" then
                        premiumCards  = premiumCards + itemReward.count
                    end
                end
                if shopCfg.type == 43 then
                    if shopCfg.param[1] == "normal" then
                        normalKeys  = normalKeys + itemReward.count
                    elseif shopCfg.param[1] == "premium" then
                        premiumKeys  = premiumKeys + itemReward.count
                    end
                end
            else
                table.insert(newAllRewards, itemReward)
            end
        end
    end
    --没有ceo卡，没有宝箱的情况下
    local isCEOHaveReward = normalBoxes > 0 or premiumBoxes > 0 or normalCards > 0 or premiumCards > 0 or normalKeys > 0 or premiumKeys > 0
    --实际发放奖励
    if not isCEOHaveReward then
        for k, v in pairs(allRewards) do
            if is_rank then
                self:GetAwardByShopId(v)
            else
                CycleNightClubModel:RealGetRewardByLevel(v.level)
            end
        end
        if Tools:GetTableSize(allRewards) > 0 then
            self:GetView():Invoke("ShowAllNotClaimRewardsGet", allRewards)
        end
        return
    end

    --在有宝箱和CEO卡片的奖励情况下的逻辑拆解

    local normalBoxrewards = {} --普通宝箱产出的内容，预处理，还没有真正发放
    local premiumBoxrewards = {} --豪华宝箱产出的内容，预处理，还没有真正发放
    local allSpawnCeoIds = {} --箱子，卡牌产生的CEOIDs，还未真正发放，经过钻石转换过滤有的实际获得卡牌
    local cardAndBoxDiamonds = 0 --宝箱，CEO获取转换的钻石数量累计，用于最后添加显示
    local normalBoxExtendParam = {}
    local premiumBoxExtendParam = {}
    --BoxRerewards {{shopID = {num = 2, extendData = {ceoid1, ceoid2}}}}
    if normalBoxes > 0 then
        GameSDKs:TrackForeign("ceo_chest_change", {type = "normal", num = tonumber(normalBoxes), source = "副本一键领取奖励宝箱获取"})
        for i = 1, normalBoxes do
            local normalBoxReward = CEODataManager:GetBoxRewards("normal")
            table.insert(normalBoxrewards, normalBoxReward)
            for shopId, itemData in pairs(normalBoxReward) do
                local shopCfg = ConfigMgr.config_shop[shopId]
                if shopCfg then
                    if shopCfg.type == 44 and itemData.extendData then
                        for index, ceoid in pairs(itemData.extendData) do
                            local transDiamond = CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
                            if transDiamond > 0 then
                                --给钻石
                                GameSDKs:TrackForeign("ceo_card_change", {type = "normal", result = "diamond", source = "一键领取里程碑奖励开箱子获取"})
                                GameTableDefine.ResourceManger:AddDiamond(transDiamond)
                                cardAndBoxDiamonds  = cardAndBoxDiamonds + transDiamond
                            else
                                if allSpawnCeoIds[ceoid] then
                                    allSpawnCeoIds[ceoid]  = allSpawnCeoIds[ceoid] + 1
                                else
                                    allSpawnCeoIds[ceoid] = 1
                                end
                                GameSDKs:TrackForeign("ceo_card_change", {type = "normal", result = tostring(ceoid), source = "一键领取里程碑奖励开箱子获取"})
                            end
                            --用于CEO宝箱开箱的额外参数
                            if not normalBoxExtendParam[i] then
                                normalBoxExtendParam[i] = {}
                            end
                            if not normalBoxExtendParam[i][shopId] then
                                normalBoxExtendParam[i][shopId] = {}
                            end
                            table.insert(normalBoxExtendParam[i][shopId], ceoid)
                        end
                    elseif shopCfg.type == 3 then
                        GameTableDefine.ResourceManger:AddDiamond(itemData.num)
                        cardAndBoxDiamonds  = cardAndBoxDiamonds + itemData.num
                    elseif shopCfg.type == 43 then
                        if shopCfg.param[1] == "normal" then
                            normalKeys  = normalKeys + itemData.num
                        elseif shopCfg.param[1] == "premium" then
                            premiumKeys  = premiumKeys + itemData.num
                        end
                    end
                end
            end
        end
    end

    if premiumBoxes > 0 then
        GameSDKs:TrackForeign("ceo_chest_change", {type = "premium", num = tonumber(premiumBoxes), source = "副本一键领取奖励宝箱获取"})
        for i = 1, premiumBoxes do
            local premiumBoxReward = CEODataManager:GetBoxRewards("premium")
            table.insert(premiumBoxrewards, premiumBoxReward)
            for shopId, itemData in pairs(premiumBoxReward) do
                local shopCfg = ConfigMgr.config_shop[shopId]
                if shopCfg then
                    if shopCfg.type == 44 and itemData.extendData then
                        for _, ceoid in pairs(itemData.extendData) do
                            local transDiamond = CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
                            if transDiamond > 0 then
                                --给钻石
                                GameSDKs:TrackForeign("ceo_card_change", {type = "premium", result = "diamond", source = "一键领取里程碑奖励开箱子获取"})
                                GameTableDefine.ResourceManger:AddDiamond(transDiamond)
                                cardAndBoxDiamonds  = cardAndBoxDiamonds + transDiamond
                            else
                                if allSpawnCeoIds[ceoid] then
                                    allSpawnCeoIds[ceoid]  = allSpawnCeoIds[ceoid] + 1
                                else
                                    allSpawnCeoIds[ceoid] = 1
                                end
                                GameSDKs:TrackForeign("ceo_card_change", {type = "premium", result = tostring(ceoid), source = "一键领取里程碑奖励开箱子获取"})
                            end
                            --用于CEO宝箱开箱的额外参数
                            if not premiumBoxExtendParam[i] then
                                premiumBoxExtendParam[i] = {}
                            end
                            if not premiumBoxExtendParam[i][shopId] then
                                premiumBoxExtendParam[i][shopId] = {}
                            end
                            table.insert(premiumBoxExtendParam[i][shopId], ceoid)
                        end
                    elseif shopCfg.type == 3 then
                        GameTableDefine.ResourceManger:AddDiamond(itemData.num)
                        cardAndBoxDiamonds  = cardAndBoxDiamonds + itemData.num
                    elseif shopCfg.type == 43 then
                        if shopCfg.param[1] == "normal" then
                            normalKeys  = normalKeys + itemData.num
                        elseif shopCfg.param[1] == "premium" then
                            premiumKeys  = premiumKeys + itemData.num
                        end
                    end
                end
            end
        end
    end

    if normalCards > 0 then
        for i = 1, normalCards do
            local ceoid = CEODataManager:GetCEOCardReward("normal")
            local transDiamond = CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
            if transDiamond > 0 then
                --给钻石
                GameSDKs:TrackForeign("ceo_card_change", {type = "normal", result = "diamond", source = "一键领取里程碑奖励获取"})
                GameTableDefine.ResourceManger:AddDiamond(transDiamond)
                cardAndBoxDiamonds  = cardAndBoxDiamonds + transDiamond
            else
                if allSpawnCeoIds[ceoid] then
                    allSpawnCeoIds[ceoid]  = allSpawnCeoIds[ceoid] + 1
                else
                    allSpawnCeoIds[ceoid] = 1
                end
                GameSDKs:TrackForeign("ceo_card_change", {type = "normal", result = tostring(ceoid), source = "一键领取里程碑奖励获取"})
            end
        end
    end


    if premiumCards > 0 then
        for i = 1, premiumCards do
            local ceoid = CEODataManager:GetCEOCardReward("premium")
            local transDiamond = CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
            if transDiamond > 0 then
                --给钻石
                GameSDKs:TrackForeign("ceo_card_change", {type = "premium", result = "diamond", source = "一键领取里程碑奖励获取"})
                GameTableDefine.ResourceManger:AddDiamond(transDiamond)
                cardAndBoxDiamonds  = cardAndBoxDiamonds + transDiamond
            else
                if allSpawnCeoIds[ceoid] then
                    allSpawnCeoIds[ceoid]  = allSpawnCeoIds[ceoid] + 1
                else
                    allSpawnCeoIds[ceoid] = 1
                end
                GameSDKs:TrackForeign("ceo_card_change", {type = "premium", result = tostring(ceoid), source = "一键领取里程碑奖励获取"})
            end
        end
    end

    local beforeBoxPurchse = function()
        for ceoid, num in pairs(allSpawnCeoIds) do
            for i = 1, num do
                CEODataManager:GetCEOCardByCEOID(ceoid)
            end
        end
        if normalKeys > 0 then
            GameSDKs:TrackForeign("ceo_key_change", {type = "normal", source = "玩具副本结束一键领取所有里程碑奖励", num = tonumber(normalKeys)})
            CEODataManager:AddCEOKey("normal", normalKeys, true)
        end
        if premiumKeys > 0 then
            GameSDKs:TrackForeign("ceo_key_change", {type = "premium", source = "玩具副本结束一键领取所有里程碑奖励", num = tonumber(premiumKeys)})
            CEODataManager:AddCEOKey("premium", premiumKeys, true)
        end
        --这里如果是宝箱和卡的话就不给东西了，放在上面单独处理了
        for k, v in pairs(allRewards) do
            if is_rank then
                self:GetAwardByShopId(v, true)
            else
                CycleNightClubModel:RealGetRewardByLevel(v.level, true)
            end
        end
    end
    local afterBoxPurchse = function()
        --做存显示用的相关内容
        if normalKeys > 0 then
            FlyIconsUI:ShowCEOAddKeyAnim("normal", normalKeys, false, nil, nil)
        end
        if premiumKeys > 0 then
            FlyIconsUI:ShowCEOAddKeyAnim("premium", premiumKeys, false, nil, nil)
        end
        --调用结算展示UI
        if Tools:GetTableSize(newAllRewards) > 0 or isCEOHaveReward then
            -- allRewards, extendDiamond, ceoCards, normalKeys, premiumKeys
            self:GetView():Invoke("ShowAllNotClaimRewardsGetHaveCeoReward", newAllRewards, cardAndBoxDiamonds, allSpawnCeoIds, normalKeys, premiumKeys)
        end
    end
    beforeBoxPurchse()
    if normalBoxes > 0 or premiumBoxes > 0 then
        if normalBoxes > 0 and premiumBoxes > 0 then
            GameTableDefine.CEOBoxPurchaseUI:SuceessOpenCEOBox("normal", normalBoxrewards, normalBoxExtendParam, function()
            end)

            GameTableDefine.CEOBoxPurchaseUI:SuceessOpenCEOBox("premium", premiumBoxrewards, premiumBoxExtendParam, function()
                afterBoxPurchse()
            end)
        elseif normalBoxes > 0 and premiumBoxes <= 0 then
            GameTableDefine.CEOBoxPurchaseUI:SuceessOpenCEOBox("normal", normalBoxrewards, normalBoxExtendParam, function()
                afterBoxPurchse()
            end)
        elseif normalBoxes <= 0 and premiumBoxes > 0 then
            GameTableDefine.CEOBoxPurchaseUI:SuceessOpenCEOBox("premium", premiumBoxrewards, premiumBoxExtendParam, function()
                afterBoxPurchse()
            end)
        end
    else
        afterBoxPurchse()
    end
end