---@class ShopManager
local ShopManager = GameTableDefine.ShopManager
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger
local PiggyBankUI = GameTableDefine.PiggyBankUI
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local CompanyMode = GameTableDefine.CompanyMode
local IAP = GameTableDefine.IAP
local MainUI = GameTableDefine.MainUI
local json = require("rapidjson")
local Shop = GameTableDefine.Shop
local TimerMgr = GameTimeManager
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local PetMode = GameTableDefine.PetMode
local CityMode = GameTableDefine.CityMode
local StarMode = GameTableDefine.StarMode
local ValueManager = GameTableDefine.ValueManager
local PetListUI = GameTableDefine.PetListUI
local PetInteractUI = GameTableDefine.PetInteractUI
local WorkshopItemUI = GameTableDefine.WorkshopItemUI
local DressUpDataManager = GameTableDefine.DressUpDataManager
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI

local DeviceUtil = CS.Game.Plat.DeviceUtil

local SHOP = "shop"


ShopManager.ItemType = {
    Diamond = 3,
    InCome = 6,
    Offline = 7,
    Pet = 13,
    Employee = 14,
    Equipment = 20,
}

local localData = nil
local valueGetter = nil
local cbGetter = nil
local enableBuyer = nil
local showGetter = nil
local wheelShower = nil
local cfgShop = nil
local shopName = nil

local typeToName = {[3] = "钻石", [4] = "广告券", [5] = "永久免广告", [6] = "收入倍率", [7] = "离线时长", [8] = "公司经验", [9] = "现金", [10] = "钻石月卡", [11] = "车", [12] = "捆绑包", [13] = "宠物", [14] = "员工", [16] = "实钞",
                    [26] = "循环副本商店经验",[27] = "循环副本商店技能书",[30] = "循环副本商店扭蛋币"}
local typeToName_en = {[3] = "diamond", [6] = "income", [7] = "offline", [8] = "exp", [9] = "cash", [4] = "mood", [16] = "realcash"}--4填mood有些渊源,平时不用

--礼包码禁止发放的类型2024-8-6
--D-兑换码-v2的文档中定义的
local giftCodeProhibitTypes = {
    11,16,17,21,22,24,25,28,31,32
}

--[[
    @desc:检测是否不是钻石货架上需要给予双倍的钻石商品 
    author:{author}
    time:2024-08-12 16:49:19
    --@shopID: 
    @return:
]]
function ShopManager:CheckDiamondShopIsDouble(shopID)
    for i,v in ipairs(ConfigMgr.config_shop_frame or {}) do
        if v.frame == "frame2" then
            for k, m in pairs(v.contents or {}) do
                if m.id == shopID then
                    return true
                end
            end
        end
    end
    return false
end
--------------购买--------------
--[[
    @desc: 通过礼包码获得的商品的处理接口，实际发放到玩家
    author:{author}
    time:2024-08-05 18:57:12
    rewardDatas:{shopid = num}
    @return:
]]
function ShopManager:BuyByGiftCode(rewardDatas, callback, isRestoreOrder, notNeedTrack, extendDatas, openSource)
    local realTypeRewardsDatas = {} --按类型的奖励一般是可叠加的，比如钻石3，绿钞2，欧元6，公司经验8
    local realIDRewardsDatas = {}
    local typeRewardIDAndTimes = {} ---类型物品的ID和数量也需要进入商品购买里面
    local displayDatas = {}
    --整合商品类型，根据不同的类型进行特殊处理，处理规则策划文档：D-兑换码-v2:商品需求说明
    --礼包已经在上一层处理过，已转换成具体的商品了，所以这里不在处理礼包，礼包数量已经置为0了
    for k, v in pairs(rewardDatas) do
        if v > 0 then
            local realTotalCount = 0
            local isTypeRewards = false
            local currUsetype = 0
            local notCalToRewards = false --已经完全转换不用再放到最后的奖励里面添加了
            local currCfg = self:GetCfg(k)
            if currCfg then
                currUsetype = currCfg.type
                --根据实际规则给予玩家奖励
                if currCfg.type == 3 or currCfg.type == 17 then
                    isTypeRewards = true
                    currUsetype = 3
                    if self:CheckDiamondShopIsDouble(k) then
                        local isFirstBuy = FirstPurchaseUI:IsFirstDouble(k)
                        if isFirstBuy then
                            realTotalCount  = realTotalCount + (currCfg.amount * 2)
                            realTotalCount  = realTotalCount + ((v - 1)*currCfg.amount)
                        else
                            realTotalCount  = realTotalCount + (v * currCfg.amount)
                        end
                    else
                        realTotalCount  = realTotalCount + (v * currCfg.amount)
                    end
                elseif currCfg.type == 5 or currCfg.type == 6 or currCfg.type == 7 or currCfg.type == 13 or currCfg.type == 14 then
                    isTypeRewards = false
                    local isFirstBuy = ShopManager:FirstBuy(k)
                    local leftCount = v
                    if isFirstBuy then
                        realTotalCount = 1
                        leftCount = v - 1
                    else
                        notCalToRewards = true
                    end
                    if leftCount > 0 then
                        --转钻石
                        if currCfg.type == 13 or currCfg.type == 14 then
                            if currCfg.param2 and currCfg.param2[1] then
                                if not realTypeRewardsDatas[3] then
                                    realTypeRewardsDatas[3] = currCfg.param2[1] * leftCount
                                else
                                    realTypeRewardsDatas[3] = realTypeRewardsDatas[3] + (currCfg.param2[1] * leftCount)
                                end
                            end
                        else
                            if currCfg.param and currCfg.param[1] then
                                if not realTypeRewardsDatas[3] then
                                    realTypeRewardsDatas[3] = currCfg.param[1] * leftCount
                                else
                                    realTypeRewardsDatas[3] = realTypeRewardsDatas[3] + (currCfg.param[1] * leftCount)
                                end
                            end
                        end
                    end
                elseif currCfg.type == 9 then
                    --现金奖励，欧元，绿钞
                    isTypeRewards = true
                    local resType = GameTableDefine.ResourceManger:GetShopCashType(currCfg.country)
                    currUsetype = 2
                    local amount = currCfg.amount * v * 3600 / 30
                    realTotalCount = GameTableDefine.FloorMode:GetTotalRent() * amount
                    if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                        currUsetype = 6
                        realTotalCount = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * amount
                    end
                elseif currCfg.type == 8 then
                    --公司经验
                    isTypeRewards = true
                    currUsetype = 8
                    local companyData = CompanyMode:GetData()
                    local totalExp = 0
                    for roomKey,roomData in pairs(companyData or {}) do
                        totalExp = totalExp + CompanyMode:RoomExpAdd(roomKey,true)
                    end
                    realTotalCount = totalExp * v * currCfg.amount * 3600
                else
                    realTotalCount = currCfg.amount * v
                end
            end
            if not notCalToRewards then
                if isTypeRewards then
                    if not realTypeRewardsDatas[currUsetype] then
                        realTypeRewardsDatas[currUsetype] = realTotalCount
                    else
                        realTypeRewardsDatas[currUsetype] = realTypeRewardsDatas[currUsetype] + realTotalCount
                    end
                else
                    if not realIDRewardsDatas[k] then
                        realIDRewardsDatas[k]  = realTotalCount
                    else
                        realIDRewardsDatas[k]  = realIDRewardsDatas[k] + realTotalCount
                    end
                end
                if not typeRewardIDAndTimes[k] then
                    typeRewardIDAndTimes[k] = v
                else
                    typeRewardIDAndTimes[k]  = typeRewardIDAndTimes[k] + v
                end
            else
                if not typeRewardIDAndTimes[k] then
                    typeRewardIDAndTimes[k] = 1
                end
            end
        end
    end

    --首先给类型方式的奖励
    for rewardType, rewardNum in pairs(realTypeRewardsDatas) do
        local displayItem = {}
        --钻石3，绿钞2，欧元6，公司经验8
        if rewardType == 3 then
            GameTableDefine.ResourceManger:AddDiamond(rewardNum)
            displayItem.icon = "icon_shop_diamond_1"
            displayItem.num = rewardNum
            if not notNeedTrack then
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "运营-运营兑换码", behaviour = 1, num_new = tonumber(rewardNum)})
            end
        elseif rewardType == 2 then
            GameTableDefine.ResourceManger:Add(rewardType, rewardNum, nil, nil, true)
            displayItem.icon = "icon_shop_cash_1"
            displayItem.num = rewardNum
        elseif rewardType == 6 then
            GameTableDefine.ResourceManger:Add(rewardType, rewardNum, nil, nil, true)
            displayItem.icon = "icon_shop_cash_1_euro"
            displayItem.num = rewardNum
        elseif rewardType == 8 then
            CompanyMode:AddExp(rewardNum)
            displayItem.icon = "icon_shop_exp_1"
            displayItem.num = rewardNum
        end

        if rewardType == 2 or rewardType == 6 or rewardType == 8 then
            displayItem.num = BigNumber:FormatBigNumber(displayItem.num)
        end
        table.insert(displayDatas, displayItem)
        GameTableDefine.MainUI:UpdateResourceUI()
    end

    --保存商品购买信息
    for rewardID, rewardNum in pairs(typeRewardIDAndTimes) do
        local shopCfg = ConfigMgr.config_shop[rewardID]
        if shopCfg then
            --保存商品购买记录
            local save = self:GetLocalData()
            save["times"] = save["times"] or {}
            local times = save["times"]
            times[""..rewardID] = (times[""..rewardID] or 0) + 1
        end
    end

    ---用于结算展示用的CEO数据
    local ceoCardDispDatas = {}
    for rewardID, rewardNum in pairs(realIDRewardsDatas) do
        local shopCfg = ConfigMgr.config_shop[rewardID]
        local displayItem = {}
        if shopCfg then
            local extendNum = 0 --用于特殊的商品需要转换的计算如副本的英雄经验需要再次计算
            local save = self:GetLocalData()
            if shopCfg.type == 5 then
                --免广告
                save["noAD"] = true
                MainUI:HideButton("NoAdBtn")
            elseif shopCfg.type == 6 then
                if not save["cash"] then
                    save["cash"] = 0
                end
                save["cash"] = save["cash"] + (rewardNum * shopCfg.amount)
                if GameStateManager:IsInFloor() then
                    PetMode:Init()
                end
            elseif shopCfg.type == 7 then
                if not save["time"] then
                    save["time"] = 0
                end

                save["time"] = save["time"] + (rewardNum * shopCfg.amount)
                if GameStateManager:IsInFloor() then
                    PetMode:Init()
                end
            elseif shopCfg.type == 13 or shopCfg.type == 14 then
                local param = shopCfg.param[1]
                local cfgPet = ConfigMgr.config_pets[param]
                local allFun = {"income", "offline", "mood"}
                local saveName = {"cash", "time", "mood"}
                local petSave = nil
                for k,v in pairs(allFun) do
                    petSave = "p" .. saveName[k]
                    if cfgPet[v] then
                        if not save[petSave] then
                            save[petSave] = 0
                        end

                        save[petSave] = save[petSave] + cfgPet[v]
                    end
                end
                if GameStateManager:IsInFloor() then
                    PetMode:Init()
                    PetMode:CreatePet(param)
                end
            elseif shopCfg.type == 18 then
                PetListUI:PetFeed(shopCfg.param[1], rewardNum, nil)
            elseif shopCfg.type == 19 then
                WorkshopItemUI:AddBuffProps(WorkshopItemUI:GetTypeByShopId(rewardID), rewardNum)
            elseif shopCfg.type == 20 then
                DressUpDataManager:GetNewDressUpItem(shopCfg.param[1], rewardNum)
            elseif shopCfg.type == 29 then
                --转盘卷
                GameTableDefine.ResourceManger:AddWheelTicket(rewardNum)
            elseif shopCfg.type == 37 then
                --通行证小游戏门票
                if GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
                    -- 给通行证小游戏票
                    local gameManager = GameTableDefine.SeasonPassManager:GetCurGameManager()
                    if not gameManager then
                        return
                    end
                    if gameManager.AddTicket then
                        gameManager:AddTicket(rewardNum)
                    end
                end
            elseif shopCfg.type == 10 then
                if not save["dia"] then
                    save["dia"] = {}
                end

                local nowTime = TimerMgr:GetCurrentServerTime()
                local holdTime = (shopCfg.param2 and shopCfg.param2[1] or 30) - 1
                if holdTime then
                    holdTime = holdTime * 86400--单位秒
                end

                local data = {}
                data["last"] = nowTime + holdTime--结束的时间
                data["num"] = shopCfg.param1--每日领取的数量
                data["get"] = nowTime - 86400 --上次领取的时间

                save["dia"] = data

                ResMgr:AddDiamond(shopCfg.amount)
                GameTableDefine.MainUI:UpdateResourceUI()
            elseif shopCfg.type == 26 or shopCfg.type == 27 or shopCfg.type == 30 or shopCfg.type == 23 or shopCfg.type == 36 or shopCfg.type == 22 then
                if shopCfg.type == 26 then
                    extendNum = self:GetValueByShopId(rewardID)
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().ChangeCurHeroExpRes then
                        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():ChangeCurHeroExpRes(extendNum)
                    end
                elseif shopCfg.type == 27 then
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().AddBuySkillTimes then
                        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():AddBuySkillTimes(rewardID)
                    end
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().AddSkillPoints then
                        displayItem.param = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():AddSkillPoints(rewardNum)
                    end
                elseif shopCfg.type == 30 then
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().ChangeSlotCoin then
                        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():ChangeSlotCoin(rewardNum)
                    end
                elseif shopCfg.type == 23 then
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetLandMarkCanPurchas() then
                        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():SetLandMarkCanPurchas()
                        --移除地标礼包购买
                        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():RemoveTrigger(1, rewardID)
                    end
                elseif shopCfg.type == 36 then
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().GetBluePrintManager then
                        ---@type CycleToyBluePrintManager
                        local bluePrintManager = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetBluePrintManager()
                        bluePrintManager:ChangeUpgradeResCount(tonumber(shopCfg.param[1]),rewardNum)
                        if not isRestoreOrder and not notNeedTrack then
                            GameSDKs:TrackForeign("cy_bp_res", { source = "礼包码", num = tonumber(rewardNum), type = 1 })
                        end
                    end
                elseif shopCfg.type == 22 then
                    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel().BuySlotPiggyBank then
                        rewardNum = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():BuySlotPiggyBank()
                        if GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_PIGGY_BANK_UI) then
                            GameTableDefine.CycleNightClubSlotMachineUI:RefreshPiggyBank()
                            GameTableDefine.CycleNightClubMainViewUI:RefreshPiggyBank()
                        end
                    end
                    
                end
            elseif shopCfg.type == 43 then
                --2025-2-11 添加CEO的箱子钥匙 fy
                local flag = rewardNum
                if openSource and not notNeedTrack then
                    --2-单个里程碑开箱,3-兑换码开箱,4-商城钥匙开箱
                    local sourceDesc = "宝箱开启获取"
                    if openSource > 1 then
                        if openSource == 2 then
                            sourceDesc = "单个里程碑开箱子获取"
                        elseif openSource == 3 then
                            sourceDesc = "兑换码开箱获取"
                        elseif openSource == 4 then
                            sourceDesc = "商城钥匙开箱获取"
                        elseif openSource == 5 then
                            sourceDesc = "下班打卡活动"
                        end
                    end
                    GameSDKs:TrackForeign("ceo_key_change", {type = shopCfg.param[1], source = sourceDesc, num = tonumber(rewardNum)})
                end
                GameTableDefine.CEODataManager:AddCEOKey(shopCfg.param[1], rewardNum)
            elseif shopCfg.type == 42 then
                --2025-2-11添加CEO的宝箱
                local flag = rewardNum
                GameTableDefine.CEODataManager:OpenCEOBox(shopCfg.param[1], rewardNum, false, nil, 3)
            elseif shopCfg.type == 44 then
                --2025-2-11 CEO的随机卡牌
                --通过箱子过来的卡牌获取
                if extendDatas then
                    for _, ceoid in pairs(extendDatas or {}) do
                        local transformDiamond = GameTableDefine.CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
                        local sourceDesc = ""
                        if openSource and not notNeedTrack then
                            --2-单个里程碑开箱,3-兑换码开箱,4-商城钥匙开箱
                            if openSource > 1 then
                                if openSource == 2 then
                                    sourceDesc = "单个里程碑开箱子获取"
                                elseif openSource == 3 then
                                    sourceDesc = "兑换码开箱获取"
                                elseif openSource == 4 then
                                    sourceDesc = "商城钥匙开箱获取"
                                elseif openSource == 5 then
                                    sourceDesc = "下班打卡活动"
                                end
                            end
                        end
                        if transformDiamond > 0 then
                            --给钻石
                            if sourceDesc ~= "" then
                                GameSDKs:TrackForeign("ceo_card_change", {type = tostring(shopCfg.param[1]), result = "diamond", source = sourceDesc})
                            end
                            GameTableDefine.ResourceManger:AddDiamond(transformDiamond)
                        else
                            if sourceDesc ~= "" then
                                GameSDKs:TrackForeign("ceo_card_change", {type = tostring(shopCfg.param[1]), result = tostring(ceoid), source = sourceDesc})
                            end
                            GameTableDefine.CEODataManager:GetCEOCardByCEOID(ceoid)
                            if not ceoCardDispDatas[ceoid] then
                                ceoCardDispDatas[ceoid] = 1
                            else
                                ceoCardDispDatas[ceoid] = ceoCardDispDatas[ceoid] + 1
                            end
                        end
                    end
                else
                    local ceoType = shopCfg.param[1]
                    local ceoIds = {}
                    for i = 1, rewardNum do
                        local ceoid = GameTableDefine.CEODataManager:GetCEOCardReward(ceoType)
                        GameSDKs:TrackForeign("ceo_card_change", {type = tostring(shopCfg.param[1]), result = tostring(ceoid), source = "兑换码直接获取"})
                        GameTableDefine.CEODataManager:GetCEOCardByCEOID(ceoid)
                        if not ceoCardDispDatas[ceoid] then
                            ceoCardDispDatas[ceoid] = 1
                        else
                            ceoCardDispDatas[ceoid] = ceoCardDispDatas[ceoid] + 1
                        end
                    end
                end
            elseif shopCfg.type == 4 then
                --广告卷发放
                GameTableDefine.ResourceManger:AddTicket(rewardNum, nil, nil)
            end
            if shopCfg.type ~= 44 and shopCfg.type ~= 42 then
                displayItem.shop_id = rewardID
                displayItem.icon = shopCfg.icon
                displayItem.num = rewardNum
                if shopCfg.type == 26 then
                    displayItem.num = extendNum
                end
                --TODO:判断是否要大数字显示
                if shopCfg.type == 8 or shopCfg.type == 9 or shopCfg.type == 26 then
                    displayItem.num = BigNumber:FormatBigNumber(displayItem.num)
                end
                table.insert(displayDatas, displayItem)
            end
        end
    end

    --结算展示CEO卡牌的内容
    for ceoid, num in pairs(ceoCardDispDatas) do
        local displayItem = {}
        displayItem.shop_id = ceoid
        displayItem.icon = ""
        displayItem.num = num
        displayItem.icon_altas = "UI_Common"
        local ceoCfg = ConfigMgr.config_ceo[ceoid]
        if ceoCfg then
            displayItem.icon = ceoCfg.ceo_card
        end
        table.insert(displayDatas, displayItem)
    end
    if callback then
        callback(displayDatas)
    end
end

--[[
    @desc:检测当前商品ID是否可用于礼包码发放 
    author:{author}
    time:2024-08-06 10:11:11
    --@shopID: 
    --@num: 添加的数量
    --@extendDatas: {shopID, extendParam} --2025-2-11暂时为类型为44随机卡牌约定的参数给的
    @return:true可以用于礼包码发放，false不能用于礼包码发放
]]
function ShopManager:CheckShopItemCanUseInGiftCode(shopID, num)
    local curCfg = self:GetCfg(shopID)
    if not curCfg then
        return false
    end
    for k, type in pairs(giftCodeProhibitTypes) do
        if curCfg.type == type then
            return false
        end
    end
    if curCfg.type == 21 or curCfg.type == 40 or curCfg.type == 41 then
        return false
    end
    --钻石月卡
    if curCfg.type == 10 then
        if num > 1 then
            return false
        else
            --检测当前是否有月卡生效
            local shopData,diamondGet = self:BuyDiamonCardData()
            if not shopData then
                return true
            else
                local MonthCardEndTime = shopData.last
                local now = TimerMgr:GetCurrentServerTime()
                if now > MonthCardEndTime + 86400 then
                    return true
                else
                    return false
                end
            end
        end
    end
    --礼包
    if curCfg.type == 12 then
        if curCfg.param and Tools:GetTableSize(curCfg.param) > 0 then
            for _, includeID in pairs(curCfg.param) do
                if not self:CheckShopItemCanUseInGiftCode(includeID, 1) then
                    return false
                end
            end
        else
            return false
        end
    end

    --成长基金
    if curCfg.type == 15 then
        if num > 1 then
            return false
        else
            return self:CheckBuyTimes(shopID, 1)
        end
    end

    --副本相关奖励，检测副本是否有效
    if curCfg.type == 26 or curCfg.type == 27 or curCfg.type == 30 or curCfg.type == 23 or curCfg.type == 36 or curCfg.type == 22 then
        if curCfg.activity and Tools:GetTableSize(curCfg.activity) > 0 then
            if curCfg.activity[1] == "0" then
                return false
            else
                local conditions = Tools:SplitString(curCfg.activity[1], ":", true)
                if Tools:GetTableSize(conditions) < 2 then
                    return false;
                end
                if conditions[1] ~= 3 then
                    return false
                end
                if GameTableDefine.CycleInstanceDataManager:GetInstanceIsActive(conditions[2]) then
                    if curCfg.type == 23 then
                        if num > 1 then
                            return false
                        end
                        --如果地标能购买
                        if not GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetLandMarkCanPurchas() then
                            return false
                        end
                    end
                    return true
                else

                    return false
                end
            end
        else
            return false
        end
    end
    --如果是通行证小游戏门票需要判断是否在活动中2025-1-20 fy
    if curCfg.type == 37 then
        --通行证小游戏门票
        if not GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
            return false
        end
    end
    return true
end

function ShopManager:Buy(id, check, callBack, beforCallBack, isGift)--直接调用会消耗钻石
    local currCfg = self:GetCfg(id)
    if not currCfg then
        return
    end

    local payType = 5--无
    local cost = 0
    local goodId = nil

    if currCfg.iap_id ~= nil then--现金
        payType = 4
        cost = Shop:GetShopItemPrice(id, true)
        goodId = IAP:GetPurchaseId(currCfg.iap_id)
    end
    if currCfg.diamond and currCfg.diamond > 0 then--钻石
        payType = 3
        cost = currCfg.diamond

        if currCfg.type == 22 or currCfg.type == 25 then
            local discount = GameTableDefine.InstanceDataManager:GetLastOneDayDiscount() or 0
            if discount > 0 and discount <= 1 then
                cost = currCfg.diamond * (1 - discount)
            end
        end
        goodId = id
    end
    if currCfg.adTime and currCfg.adTime > 0 then--广告次数
        payType = 6
    end

    local value = self:GetValue(currCfg)--能够获得的值,如公司总经验,得到的钱,钻石等

    if check then--是否只是判定能否购买
        local result = false

        if payType == 3 then
            result = ResMgr:CheckDiamond(cost)
        elseif payType == 4 then
            result = true
        elseif payType == 6 then
            result = self:SpendADTime(true, currCfg.adTime)
        end

        return result, value, currCfg.type
    end

    local buyCb = function()
        local save = self:GetLocalData()

        save["times"] = save["times"] or {}
        local times = save["times"]

        local afterBuy = function()
            if currCfg.type ~= 12 then
                if beforCallBack then beforCallBack() end--在次数增加之前,回调,主要是影响是否购买过的判断...
                times[""..id] = (times[""..id] or 0) + 1
                --K136 购买钻石后 标记使用了首充双倍次数
                if currCfg.type == 3 then
                    FirstPurchaseUI:SetNotFirstDouble(id)
                end
            end

            if currCfg.type == 6 or currCfg.type == 7 then
                EventManager:DispatchEvent("EVENT_SHOP_PEOPLE")
            end

            if callBack then callBack() end--因为这个回调和表现相关,需要实际购买完成全部实现之后才调用,包括购买次数

            if payType == 4 and not isGift then

                GameSDKs:TrackForeign("purchase", {product_id = IAP:GetPurchaseId(currCfg.iap_id), price = cost, state = 4})
                -- GameSDKs:TrackControl("af", "af,af_purchase", {af_revenue = cost, af_currency = "USD"})
            end

            LocalDataManager:WriteToFile()
        end

        local cb = self:GetCB(currCfg)--获得购买相应需要调用的方法

        if currCfg.type ~= 12 then--单件
            cb(value, currCfg, afterBuy)
        elseif currCfg.type == 12 then--礼包
            cb(value, currCfg)

            if beforCallBack then beforCallBack() end--在次数增加之前,回调,主要是影响是否购买过的判断...

            local allPackage = currCfg.param
            if not allPackage then
                return
            end

            local tempCfg = nil
            local tempCb = nil
            for k,v in pairs(allPackage) do
                tempCfg = self:GetCfg(v)
                if tempCfg then
                    if self:CheckBuyTimes(v) then
                        tempCb = self:GetCB(tempCfg)
                        value = self:GetValue(tempCfg)

                        if tempCb then
                            tempCb(value, tempCfg, nil)

                            times[""..v] = (times[""..v] or 0) + 1
                            if tempCfg.type == 6 or tempCfg.type == 7 then
                                EventManager:DispatchEvent("EVENT_SHOP_PEOPLE")
                            elseif tempCfg.type == 13 then
                                PetMode:Init()
                                PetMode:CreatePet(tempCfg.param)
                                if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
                                    PetListUI:RefreshPetList()
                                end
                            end
                        end
                    end
                end
            end

            afterBuy()
        end

        -- if payType == 3 or payType == 4 then
        --     GameSDKs:Track("store_success", {goods_id =  goodId, goods_type = ShopManager:TypeToName(currCfg.type)})
        -- end

        LocalDataManager:WriteToFile()
    end


    if payType == 4 and not isGift then
        local firstPurchase = self:IsFirstPurchase(currCfg.iap_id)
        if firstPurchase then
            --local groupTag = LocalDataManager:GetDataByKey(SHOP).group_tag
            --GameSDKs:TrackForeign("first_purchase", {product_id = IAP:GetPurchaseId(currCfg.iap_id), price = cost,group_tag = groupTag})
        else
            GameSDKs:TrackForeign("purchase", {product_id = IAP:GetPurchaseId(currCfg.iap_id), price = cost, state = 5})
        end
    end
    if (payType == 3 or payType == 4) and not isGift then
        GameSDKs:TrackForeign("store", {source = 1, operation_type = 2, product_id = goodId, pay_type = payType, cost_num_new = tonumber(cost) or 0})
    end
    self:ToBuy(currCfg, buyCb)
end

---是否是首充
function ShopManager:IsFirstPurchase(iap_id)
    local firstPurchaseData = LocalDataManager:GetDataByKey("firstPurchase")
    if not firstPurchaseData.firstBuyID then
        firstPurchaseData.firstBuyID = iap_id
        return true
    else
        return false
    end
end

---@param complex number 只在免费购买时给多份道具时使用，cost=nil 暂时只在限时礼包中用到
function ShopManager:Buy_LimitPackReward(id, callBack, beforCallBack, isGift,complex)--直接调用会消耗钻石
    local currCfg = self:GetCfg(id)
    if not currCfg then
        return
    end

    complex = complex or 1
    local cfgAmount = self:GetValue(currCfg)
    if currCfg.type == 13 then
        cfgAmount = currCfg.amount
    end
    if currCfg.type == 14 then
        cfgAmount = currCfg.amount
    end
    local value = cfgAmount
    if currCfg.type == 26 or currCfg.type == 31 or currCfg.type == 32 then
        value = BigNumber:Multiply( cfgAmount,complex)--大数 副本英雄经验，副本货币等
    else
        value = cfgAmount * complex--能够获得的值,如公司总经验,得到的钱,钻石等
    end

    local buyCb = function(complex)
        local save = self:GetLocalData()

        save["times"] = save["times"] or {}
        local times = save["times"]

        local afterBuy = function()
            if currCfg.type ~= 12 then
                if beforCallBack then beforCallBack() end--在次数增加之前,回调,主要是影响是否购买过的判断...
                times[""..id] = (times[""..id] or 0) + 1
            end

            if currCfg.type == 6 or currCfg.type == 7 then
                EventManager:DispatchEvent("EVENT_SHOP_PEOPLE")
            end

            if callBack then callBack() end--因为这个回调和表现相关,需要实际购买完成全部实现之后才调用,包括购买次数

            LocalDataManager:WriteToFile()
        end

        local cb = self:GetCB(currCfg)--获得购买相应需要调用的方法

        if currCfg.type ~= 12 then--单件
            if self:CheckBuyTimes(id) then
                cb(value, currCfg, afterBuy, complex)
            else
                --超过购买次数，转换为钻石,因为在PurchaseSuccessUI中给了一遍,所以也不写在这里了
                if beforCallBack then beforCallBack(false) end
            end
        elseif currCfg.type == 12 then--礼包
            cb(value, currCfg)

            if beforCallBack then beforCallBack() end--在次数增加之前,回调,主要是影响是否购买过的判断...

            local allPackage = currCfg.param
            if not allPackage then
                return
            end

            local tempCfg = nil
            local tempCb = nil
            for k,v in pairs(allPackage) do
                tempCfg = self:GetCfg(v)
                if tempCfg then
                    if self:CheckBuyTimes(v) then
                        tempCb = self:GetCB(tempCfg)
                        value = self:GetValue(tempCfg)

                        if tempCb then
                            tempCb(value, tempCfg, nil, complex)

                            times[""..v] = (times[""..v] or 0) + 1
                            if tempCfg.type == 6 or tempCfg.type == 7 then
                                EventManager:DispatchEvent("EVENT_SHOP_PEOPLE")
                            elseif tempCfg.type == 13 then
                                PetMode:Init()
                                PetMode:CreatePet(tempCfg.param)
                                if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
                                    PetListUI:RefreshPetList()
                                end

                            end
                        end
                    end
                end
            end

            afterBuy()
        end

        LocalDataManager:WriteToFile()
    end

    buyCb(complex)
    --self:ToBuy(currCfg, buyCb)
end

function ShopManager:Init()
    EventManager:RegEvent("SHOP_BUY_SUCCESS", function(shopId)
        self:InvokeBuySuccess(shopId)
    end)
    EventManager:RegEvent("SHOP_BUY_FAIL", function(shopId)
        self:InvokeBuyFail(shopId)
    end)
    --2024/2/21 老存档新增首充埋点的判断条件
    local firstPurchaseData = LocalDataManager:GetDataByKey("firstPurchase")
    if not firstPurchaseData.initialized then
        local save = self:GetLocalData()
        save["times"] = save["times"] or {}
        local times = save["times"]
        for shopId,v in pairs(times) do
            local t = v or 0
            if t>0 then
                local shopCfg = ConfigMgr.config_shop[tonumber(shopId)]
                if shopCfg and shopCfg.iap_id then
                    firstPurchaseData.firstBuyID = shopCfg.iap_id
                    break
                end
            end
        end
        firstPurchaseData.initialized = true
        LocalDataManager:WriteToFile()
    end
end

function ShopManager:refreshBuySuccess(successCb)
    if self.shopSuccessCbs == nil then
        self.shopSuccessCbs = {}
    end

    if successCb then
        table.insert(self.shopSuccessCbs, successCb)
    else
        --- not safe
        table.remove(self.shopSuccessCbs, #self.shopSuccessCbs)
    end
end

function ShopManager:InvokeBuySuccess(shopId)
    local shopCfg = ConfigMgr.config_shop[shopId]
    if shopCfg and shopCfg.type == 17 then
        GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 2, order_state_desc = "收到小猪购买成功回调SHOP_BUY_SUCCESS"})
    end
    --这里加入一个互斥购买设置的逻辑
    self:SetBuyExclusionShopItem(shopId)
    if self.shopSuccessCbs == nil then
        self.shopSuccessCbs = {}
        return
    end

    if shopCfg and shopCfg.type == 17 then
        GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 3, order_state_desc = "开始执行小猪购买成功回调"})
    end

    local successCb = self.shopSuccessCbs[#self.shopSuccessCbs]
    if successCb then successCb(shopId) end
    --判断是否是花钱购买的商品，如果是加入一个立即存档的功能
    if shopCfg.iap_id then
        LocalDataManager:WriteToFileInmmediately()
        LocalDataManager:UpdateLoadLocalData()
    end
end

function ShopManager:refreshBuyFail(failCb)
    if self.shopFailCbs == nil then
        self.shopFailCbs = {}
    end

    if failCb then
        table.insert(self.shopFailCbs, failCb)
    else
        table.remove(self.shopFailCbs, #self.shopFailCbs)
    end
end

function ShopManager:InvokeBuyFail(shopId)
    if self.shopFailCbs == nil then
        self.shopFailCbs = {}
        return
    end

    local failCb = self.shopFailCbs[#self.shopFailCbs]
    if failCb then failCb(shopId) end
end

function ShopManager:SpendADTime(check, adtimeSpend)--国内看广告累计次数用于商城购买
    local save = self:GetLocalData()
    local spendTime = save["adUse"] or 0
    local adData = LocalDataManager:GetDataByKey("ad_data")
    local totalTime = adData.totalAdTime or 0
    if check then
        return totalTime - spendTime >= adtimeSpend, totalTime - spendTime
    end

    if save["adUse"] == nil then
        save["adUse"] = 0
    end

    save["adUse"] = save["adUse"] + adtimeSpend
    LocalDataManager:WriteToFile()
end

function ShopManager:TypeToName(typeId, en)
    local root = en ~= nil and typeToName_en or typeToName
    return root[typeId] or nil
end

function ShopManager:BuyFailed(id)
    local currCfg = self:GetCfg(id)
    local payType = 5--无
    if currCfg.iap_id ~= nil then--现金
        payType = 4
    end
    if currCfg.diamond and currCfg.diamond > 0 then--钻石
        payType = 3
    end
    if currCfg.adTime and currCfg.adTime > 0 then
        payType = 6
    end

    local cost = currCfg.diamond
    -- if currCfg.diamond == nil and currCfg.iap_id == nil then
    --     payType = 5
    --     cost = 0
    -- end
    if payType == 4 then
        cost = Shop:GetShopItemPrice(id, true)
    end
    if payType == 3 or payType == 4 then
        GameSDKs:TrackForeign("store", {source = 1, operation_type = 3, product_id = IAP:GetPurchaseId(currCfg.iap_id), pay_type = payType, cost_num_new = tonumber(cost) or 0})
    end
end
------获取-----------------------
function ShopManager:IsNoAD()--是否购买了免广告
    local save = self:GetLocalData()
    return save["noAD"] or false
end
function ShopManager:IsBuyNewGift()--是否购买了新手礼包
    local save = self:GetLocalData()
    return save["new"] or false
end
function ShopManager:canBuyNewGift(shopId, currTime)--新手礼包再改
    --改成带计时的
    local save = self:GetLocalData()
    local isBuy = self:BoughtBefor(shopId)
    if isBuy then
        return false
    end

    local shopCfg = ConfigMgr.config_shop[shopId]
    if shopCfg.param2 and shopCfg.param2[1] and shopCfg.param2[2] then
        local conditionType = shopCfg.param2[1]
        local condition = shopCfg.param2[2]
        -- 6是场景，5是星级
        if conditionType == 5 then
            local curStar = StarMode:GetStar()
            if curStar < condition then
                return false
            end
        elseif conditionType == 6 then
            local currBuilding = CityMode:GetCurrentBuilding() or 0
            if currBuilding < condition then
                return false
            end
        end

    end
    --查看是否过期
    local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(shopId)
    if isTimeGift and leftTime == 0 then
        return false
    end
    -- if save["frame7"] == nil then
    --     save["frame7"] = {}
    -- end
    -- local newData = save["frame7"]
    -- local currData = newData[shopId .. ""]
    -- local now = currTime ~= nil and currTime or TimerMgr:GetNetWorkTimeSync(true)
    -- if currData == nil then
    --     local activeTime = shopCfg.param2[3] or 86400
    --     if activeTime < 0 then
    --         newData["" .. shopId] = activeTime
    --     else
    --         newData["" .. shopId] = now +  activeTime 
    --     end
    --     currData = newData["" .. shopId]
    --     LocalDataManager:WriteToFile()
    --     return true, activeTime
    -- end
    -- if currData < 0 then--不需要事件计时
    --     return true, -1
    -- end

    -- if now > currData then--过期了
    --     return false, 0
    -- end

    -- local timeStay = currData - now
    local timeStay = 0
    return true, timeStay
end


function ShopManager:BoughtNPCPackage()--是否购买了npc捆绑包
    local save = self:GetLocalData()
    return save["frame10"] or false
end

function ShopManager:GetDevelopId()--成长礼包当前等级,好像已经没有用了
    local save = self:GetLocalData()
    return save["frame8"]
end

function ShopManager:BuyDiamonCardData()--钻石月卡
    local save = self:GetLocalData()
    local cfg = self:GetCfg(1016)
    return save["dia"] or nil, cfg.param[1]--{last, num, get} 
end

function ShopManager:GetDiamondCardReward(check, cb, now, failCb)--领取钻石月卡奖励
    local save = self:GetLocalData()
    local data,diamondGet = self:BuyDiamonCardData()

    if now == nil then
        now = TimerMgr:GetNetWorkTimeSync(true)
        --now = TimerMgr:GetCurrentServerTime()
    end

    local nowDay = os.date("%d", now)
    local lastGet = data ~= nil and data.get or 0
    local lastDay = os.date("%d", lastGet)

    if check then
        if data == nil then
            return false
        end
        return nowDay ~= lastDay
    end

    if data == nil or nowDay == lastDay then
        if failCb then failCb() end
        return
    end

    save["dia"].get = TimerMgr:GetNetWorkTimeSync(true)
    --save["dia"].get = TimerMgr:GetCurrentServerTime()

    ResMgr:AddDiamond(diamondGet, nil, cb, true)
    -- GameSDKs:Track("get_diamond", {get = diamondGet, left = ResMgr:GetDiamond(), get_way = "钻石月卡领取"})
    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石月卡领取", behaviour = 1, num_new = tonumber(diamondGet)})
end

--获取赚钱效率的提升值
function ShopManager:GetCashImprove(update, countryId)--单位0.5,1
    -- local save = self:GetLocalData()
    -- local people = save["cash"] or 0
    -- local pet = PetMode:GetCashImprove(update)
    return PetMode:GetCashImprove(update, countryId)
end

--获取离线奖励时长的提升值
function ShopManager:GetOfflineAdd(update, countryId)--单位小时
    -- local save = self:GetLocalData()
    -- local perople = save["time"] or 0
    -- local pet = PetMode:GetOfflineAdd(update, countryId)
    return PetMode:GetOfflineAdd(update, countryId)
end

--获得心情提升的提升值
function ShopManager:GetMoodImprove(update)--心情,目前只有宠物有
    -- local save = PetInteractUI:GetLocalData()
    return PetMode:GetMoodImprove(update)
end


function ShopManager:CheckBuyTimes(id, checkTime)--剩余购买次数是否足够
    if checkTime == 0 then--无限购买
        return true
    end

    local cfg = self:GetCfg(id)
    if not cfg.numLimit then
        return true
    end

    local save = self:GetLocalData()
    local times = save["times"] or {}--times...购买次数,名字起的不太好,和离线时长只差了一个s
    local currTimes = times[""..id] or 0
    local compareWith = checkTime or cfg.numLimit
    if not compareWith then
        return true
    end

    return currTimes < compareWith
end

---检查是否应该返还钻石
function ShopManager:CheckIfBackDiamond(id)
    --剩余购买次数是否足够
    if not self:CheckBuyTimes(id) then
        local backDiamond = 0
        local currCfg = ShopManager:GetCfg(id)
        --超过购买次数，转换为钻石
        if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
            backDiamond = backDiamond + currCfg.param2[1]
        elseif currCfg.type == 6 or currCfg.type == 7 then--npc
            backDiamond = backDiamond + currCfg.param[1]
        elseif currCfg.type == 5 then--免广告 --这里应该写错了, 4是广告券, 5是免广告商品
            backDiamond = backDiamond + currCfg.param[1]
        end

        return true,backDiamond
    end
    --- 免广告判断
    local currCfg = ShopManager:GetCfg(id)
    local isADTicket = false
    if currCfg.type == 4 and ShopManager:IsNoAD() then
        local backDiamond = 0
        backDiamond = backDiamond + currCfg.param[1]
        isADTicket = true
        return true, backDiamond, isADTicket
    end
    
    return false, 0, isADTicket
end

---记录限次礼包购买次数，限时礼包的购买次数每次开启活动会重置,与此同时整个Shop存档中还有个Times有这个Id不会重置.
function ShopManager:AddLimitPackBuyTimes(id)
    local save = self:GetLocalData()
    local limitPackTimes = save["limitPackTimes"]
    if not limitPackTimes then
        limitPackTimes = {}
        save["limitPackTimes"] = limitPackTimes
    end
    limitPackTimes[""..id] = (limitPackTimes[""..id] or 0)+1
end

---限时礼包剩余购买次数是否足够,限时礼包购买次数由运营数据决定.限时礼包的购买按钮会用这个判断是否可以点击.
function ShopManager:CheckLimitPackBuyTimes(id, available_num)
    available_num = available_num or 0
    if available_num == 0 then--无限购买
        return true
    end

    local save = self:GetLocalData()
    local limitPackTimes = save["limitPackTimes"] or {}
    local currTimes = limitPackTimes[""..id] or 0

    return currTimes < available_num
end

---清空限时礼包的购买次数
function ShopManager:ClearLimitPackBuyTimes(id)
    local save = self:GetLocalData()
    local limitPackTimes = save["limitPackTimes"]
    if limitPackTimes then
        limitPackTimes[""..id] = 0
    end
end

function ShopManager:CleanShopData()
    local data = LocalDataManager:GetDataByKey(SHOP)
    for k,v in pairs(data or {}) do
        data[k] = nil
    end
    LocalDataManager:WriteToFile()
end

--返回对应id的商品的config
function ShopManager:GetCfg(id, type)
    if cfgShop == nil then
        cfgShop = ConfigMgr.config_shop
    end

    local currCfg = {}
    if not cfgShop[id] then
        return nil
    end
    for k,v in pairs(cfgShop[id]) do
        currCfg[k] = v
    end
    if not currCfg then
        return nil
    end

    if type ~= nil and currCfg.type ~= type then
        return nil
    end
    if currCfg.type == 9 and currCfg.country == 0 then
        if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
            currCfg.icon = currCfg.icon .. "_euro"
        end
    end

    return currCfg
end

--根据不同的支付类型,调用不同的方法
function ShopManager:ToBuy(cfg, buyCb)
    if cfg.iap_id == nil then--非付费
        if cfg.diamond then--钻石
            local cost = cfg.diamond
            if cfg.type == 22 or cfg.type == 25 then
                local discount = GameTableDefine.InstanceDataManager:GetLastOneDayDiscount() or 0
                if discount > 0 and discount <= 1 then
                    cost = cfg.diamond * (1 - discount)
                end
            end
            ResMgr:SpendDiamond(cost, nil, buyCb)
            -- GameSDKs:Track("cost_diamond", {cost = cfg.diamond, left = ResMgr:GetDiamond(), cost_way = "商场"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = typeToName[cfg.type] or "商城", behaviour = 2, num_new = tonumber(cost)})
        elseif cfg.adTime then--广告
            self:SpendADTime(false, cfg.adTime)
            if buyCb then buyCb() end
        else--其他捆绑包赠送
            if buyCb then buyCb() end
        end
    else
        buyCb()
    end
end

--获取存档
function ShopManager:GetLocalData()
    if localData then
        return localData
    end

    localData = LocalDataManager:GetDataByKey(SHOP)
    return localData
end


function ShopManager:GetValueByShopId(shopId)
    local cfg = self:GetCfg(shopId)
    local value, typeName = self:GetValue(cfg)
    return value, typeName
end

--能否购买的方法回调
function ShopManager:EnableBuy(id)
    local cfg = self:GetCfg(id)

    --增加一个超时商品的检测，是否超时 fengyu, 2030-6-13
    if self:CheckShopItemTimeLimit(id) then
        return false
    end
    if enableBuyer then
        local v = enableBuyer[cfg.type]
        if v then
            return v(cfg, id)
        else
            return not self:BoughtBefor(id)
        end
    end

    enableBuyer = {}
    enableBuyer[12] = function(config)--捆绑包
        if self:BoughtBefor(config.id) then
            return false
        end

        local packageType = config.param3[1]
        if packageType == 1 then--新手礼包
            return self:canBuyNewGift(config.id)
        elseif packageType == 2 then--成长礼包
            local condition = config.param2
            local valueNeed = condition[2]

            if condition[1] == 5 then
                local currStar = StarMode:GetStar()
                return currStar >= valueNeed
            elseif condition[1] == 6 then
                return CityMode:CheckBuildingSatisfy(valueNeed)
            elseif condition[1] == 7 then
                return ValueManager:GetValue() >= valueNeed
            end
        end

        return not self:BoughtBefor(config.id)
    end

    enableBuyer[10] = function(config)--月卡
        local data = self:BuyDiamonCardData()
        if data == nil then
            return true
        end
        local endTime = data.last
        local now = TimerMgr:GetCurrentServerTime()
        if now > endTime + 86400 then
            return true
        else
            return false
        end
    end

    local v = enableBuyer[cfg.type]
    if v then
        return v(cfg)
    else
        return not self:BoughtBefor(id)
    end
end

--获取商品的显示名称
function ShopManager:GetShopString(mValue, cfg)
    if shopName then
        local v = shopName[cfg.type]
        local typeName = self:TypeToName(cfg.type) or ""
        if v then
            return v(mValue, cfg, typeName)
        else
            return typeName .. mValue
        end
    end

    shopName = {}
    shopName[13] = function(value, config, name)
        local data = config.param or {}
        local petId = data[1] or 0
        local cfgPet = ConfigMgr.config_pets[petId] or {}
        local petName = cfgPet.name or nil
        if petName ~= nil then
            return GameTextLoader:ReadText(petName)
        end
        return "unknow pet"
    end

    if shopName then
        local v = shopName[cfg.type]
        local typeName = self:TypeToName(cfg.type) or ""
        if v then
            return v(mValue, cfg, typeName)
        else
            return typeName .. mValue
        end
    end
end

--转盘上商品的名称
function ShopManager:GetWheelShow(mValue, cfg)--轮盘上不同商品显示数量...
    if wheelShower then
        local v = wheelShower[cfg.type]
        if v then
            return v(mValue, cfg)
        end

        return ""
    end

    wheelShower = {}
    wheelShower[3] = function(value, config)
        return config.amount
    end

    wheelShower[9] = function(value, config)
        return Tools:SeparateNumberWithComma(value)
    end
    wheelShower[8] = function(value, config)
        return Tools:SeparateNumberWithComma(value)
    end

    wheelShower[9] = function(value, config)
        return Tools:SeparateNumberWithComma(value)
    end

    wheelShower[13] = function(value, config)
        local data = config.param or {}
        local petId = data[1] or 0
        local cfgPet = ConfigMgr.config_pets[petId] or {}
        local petName = cfgPet.name or nil
        if petName ~= nil then
            return GameTextLoader:ReadText(petName)
        end
        return "Pet"
    end

    if wheelShower then
        local v = wheelShower[cfg.type]
        if v then
            return v(mValue, cfg)
        end

        return ""
    end
end

--把value转换为string,加各种修饰支付,格式
function ShopManager:SetValueToShow(mValue, cfg)--对应界面显示奖励数量的形式,挺多地方用,就集合起来了
    if showGetter then
        if cfg then
            local v = showGetter[cfg.type]
            if v then
                return v(mValue, cfg)
            end
        end

        return mValue
    end

    showGetter = {}
    showGetter[3] = function(amount)
        return Tools:SeparateNumberWithComma(amount)
    end
    showGetter[9] = function(amount)
        return Tools:SeparateNumberWithComma(amount)
    end

    showGetter[6] = function(value)
        return value * 100 .. "%"
    end
    showGetter[7] = function(value)
        --return value .. "Hrs"
        return value
    end
    showGetter[8] = function(value)
        return Tools:SeparateNumberWithComma(value)
    end

    showGetter[13] = function(value, config)
        if config then
            local petCfg = ConfigMgr.config_pets[config.param[1]]
            local result = {}
            if petCfg.income then
                result.income = petCfg.income * 100 .. "%"
            end
            if petCfg.offline then
                --result.offline = petCfg.offline .. "Hrs"
                result.offline = petCfg.offline
            end
            if petCfg.mood then
                result.mood = petCfg.mood
            end
            return result
        else
            return value
        end
    end
    showGetter[14] = function(cfg)
        local result = {income = 0}
        if cfg then
            if cfg.income then
                result = {income  = cfg.income * 100 .. "%"}
            end
            if cfg.offline then
                --result.offline = petCfg.offline .. "Hrs"
                result = {offline = cfg.offline}
            end
            if cfg.mood then
                result = {mood = cfg.mood}
            end

        end
        return result
    end
    showGetter[15] = function(value, config)
        return nil
    end
    showGetter[17] = function(amount)
        local earnings = PiggyBankUI:GetEarnings()
        return Tools:SeparateNumberWithComma(earnings.num)
    end

    showGetter[18] = function(amount)
        return Tools:SeparateNumberWithComma(amount)
    end

    showGetter[16] = function(amount)
        return Tools:SeparateNumberWithComma(amount)
    end

    showGetter[25] = function(amount)
        return Tools:SeparateNumberWithComma(math.floor(amount))
    end

    --新副本分钟英雄经验
    showGetter[26] = function(amount)
        return BigNumber:FormatBigNumber(amount)
    end

    --新副本经验书
    showGetter[27] = function(amount)
        return Tools:SeparateNumberWithComma(amount)
    end

    --新副本分钟货币
    showGetter[31] = function(amount)
        return BigNumber:FormatBigNumber(amount)
    end

    --新副本分钟积分
    showGetter[32] = function(amount)
        return BigNumber:FormatBigNumber(amount)
    end

    if showGetter then
        local v = showGetter[cfg.type]
        if v then
            return v(mValue, cfg)
        end

        return mValue
    end
end

--获得购买成功后显示的标题
function ShopManager:GetTilet(type, shopId, param3)--获得货架标题
    local allType = {--类型标题
        [9] = "TXT_SHOP_CASH",
        [8] = "TXT_SHOP_EXP",
        [13] = "TXT_SHOP_PET",
        [3] = "TXT_SHOP_DIAMOND",
        [5] = "TXT_SHOP_AD",
        [6] = "TXT_SHOP_INCOME",
        [7] = "TXT_SHOP_OFFLINE",
        [10] = "TXT_SHOP_MONTH_DIAMOND",
        [15] = "TXT_SHOP_FUND",
        [17] = "TXT_SHOP_PIGGYBANK",
        [18] = "TXT_SHOP_SNACK",
        [20] = "TXT_SHOP_EQUIPMENT",
    }

    if allType[type] then
        return allType[type]
    end

    local packageName = {--包裹标题
        [1066] = "TXT_SHOP_PETPACK",
        [1053] = "TXT_SHOP_MANAGERPACK",
        [1037] = "TXT_SHOP_STARTERPACK",
        [1068] = "TXT_SHOP_ADFREEPACK"
    }

    if packageName[shopId] then
        return packageName[shopId]
    end
    local newPackageName = {--包裹标题
        [6] = "TXT_SHOP_RANK_REWARD",
    }
    if newPackageName[param3] then
        return newPackageName[param3]
    end
    return "TXT_SHOP_PREMIUMPACK"--应该就只剩下成长礼包了
end

--根据传入数据,获得奖励的数值
function ShopManager:GetValue(mCfg)--能获得奖励数,如果是buff则为当前的状态
    if valueGetter then
        local v = valueGetter[mCfg.type]
        if v then
            return v(mCfg.amount, mCfg)
        end

        return 0
    end

    valueGetter = {}--数字具体对应功能看config_shop的type
    valueGetter[3] = function(amount, cfg)
        local firstBuy = FirstPurchaseUI:IsFirstDouble(cfg.id)
        if firstBuy then--礼包送的钻石没有双倍
            amount = amount * 2
        end
        return amount, "diamond"
    end
    valueGetter[4] = function(amount)
        return amount, "ticket"
    end
    valueGetter[29] = function(amount)
        return amount, "Wheel_Ticket"
    end
    valueGetter[8] = function(amount)
        local companyData = CompanyMode:GetData()
        local totalExp = 0
        for k,v in pairs(companyData or {}) do
            totalExp = totalExp + CompanyMode:RoomExpAdd(k,true)
        end
        return math.floor(totalExp * amount * 3600), "exp"
    end
    valueGetter[9] = function(amount,cfg)
        local each30sEarn = FloorMode:GetTotalRent(nil, cfg.country) - FloorMode:GetEmployeePay()
        if each30sEarn < 0 then
            each30sEarn = 0
        end
        local earnTimes = amount * 120
        return math.floor(each30sEarn * earnTimes), "cash"
    end

    valueGetter[5] = function(amount)
        return amount, "ad"
    end
    valueGetter[6] = function(amount)
        return amount, "income"
    end
    valueGetter[7] = function(amount)
        return amount, "offline"
    end
    valueGetter[10] = function(amount)
        return amount, "monthd"
    end
    valueGetter[13] = function(amount, cfg)
        local cfgPet = ConfigMgr.config_pets[cfg.param[1]]
        local allValue = {}
        if cfgPet.income then
            allValue.income = cfgPet.income
        end
        if cfgPet.offline then
            allValue.offline = cfgPet.offline
        end
        if cfgPet.mood then
            allValue.mood = cfgPet.mood
        end
        return allValue, "pet"
        -- local allValue = {}
        -- if cfgPet.income then
        --     return cfgPet.income, "pet"
        -- end
        -- if cfgPet.offline then
        --     return cfgPet.offline, "pet"
        -- end
        -- if cfgPet.mood then
        --     return cfgPet.mood, "pet"
        -- end
        -- return amount, "pet"
    end

    valueGetter[14] = function(amount, cfg)
        local cfg = ConfigMgr.config_employees[cfg.param[1]]
        local allValue = {}
        if cfg.income then
            allValue.income = cfg.income
        end
        if cfg.offline then
            allValue.offline = cfg.offline
        end
        if cfg.mood then
            allValue.mood = cfg.mood
        end
        return allValue, "emplo"
    end
    valueGetter[15] = function(amount, cfg)
        return 0, "fund"
    end

    valueGetter[17] = function(amount, cfg)
        return amount, "diamond"
    end

    valueGetter[18] = function(amount, cfg)
        return amount, "snack"
    end
    valueGetter[19] = function(amount, cfg)
        return amount, "boost"
    end

    valueGetter[20] = function(amount, cfg)
        return amount, "dressup"
    end
    ---直接加当前区域现金的添加2022-10-24
    valueGetter[16] = function(amount, InitConfigs)
        return amount, "realcash"
    end
    -- "instance_time", "instance_landmark"
    valueGetter[22] = function (amount, cfg)
        return amount, "instance_time"
    end
    valueGetter[23] = function (amount, cfg)
        return amount, "instance_landmark"
    end

    valueGetter[24] = function(amount, cfg)
        return amount, "instance_cash"
    end

    valueGetter[25] = function(amount, cfg)
        local now = GameTimeManager:GetCurrentServerTimeInMilliSec()
        local time = amount * 60 * 60
        if not self.m_lastTimeBuy25 then
            self.m_lastTimeBuy25 = {}
        end
        if  not self.m_lastTimeBuy25[time] or now - self.m_lastTimeBuy25[time].lastTime >= 1000  then
            local resReward, moneyNum = GameTableDefine.InstanceModel:CalculateOfflineRewards(time,false,false)
            self.m_lastTimeBuy25[time] = {
                lastTime = now,
                money = moneyNum
            }
        end

        return self.m_lastTimeBuy25[time].money , "instance_cash"
    end

    --副本分钟英雄经验
    valueGetter[26] = function(amount, cfg)
        local time = amount
        local minuteNum = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetExpOutputPerMin()
        local num = BigNumber:Multiply(minuteNum,time)
        return num , "instanceHeroExp"
    end

    --副本技能书
    valueGetter[27] = function(amount, cfg)
        return amount, "instanceSkillBook"
    end

    --副本拉霸机扭蛋币
    valueGetter[30] = function(amount, cfg)
        return amount, "instanceSlotMachineCoin"
    end

    --副本分钟货币(某些副本是取最高房间的收入，某些副本是全部房间收入)
    valueGetter[31] = function(amount, cfg)
        local time = amount
        local inCome = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetRewardInComePerMinute()
        local moneyNum = BigNumber:Multiply(inCome,time)
        return moneyNum,"cycle_instance_cash"
    end

    --副本分钟积分
    valueGetter[32] = function(amount, cfg)
        local time = amount
        local minuteNum = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetPointsOutputPerMin()
        local moneyNum = BigNumber:Multiply(minuteNum,time)
        return moneyNum,"cycle_instance_points"
    end

    --副本钻石
    valueGetter[33] = function(amount, cfg)
        return amount,"cycle_instance_diamond"
    end

    --副本蓝图材料
    valueGetter[36] = function(amount, cfg)
        return amount,"cycle_instance_blueprint"
    end

    --通行证小游戏票
    valueGetter[37] = function(amount, cfg)
        return amount,"pass_game_ticket"
    end

    --通行证小游戏积分
    valueGetter[38] = function(amount, cfg)
        return amount,"pass_game_score"
    end

    --通行证小游戏双倍球
    valueGetter[39] = function(amount, cfg)
        return amount,"pass_game_double"
    end

    --高级通行证
    valueGetter[40] = function(amount, cfg)
        return amount,"pass_premium"
    end

    --豪华通行证
    valueGetter[41] = function(amount, cfg)
        return amount,"pass_luxury"
    end

    valueGetter[43] = function(amount, cfg)
        return amount, "ceoChest"
    end
    local v = valueGetter[mCfg.type]
    if v then
        return v(mCfg.amount, mCfg)
    end

    return 0
end

--是否为第一次购买
function ShopManager:FirstBuy(id)
    local save = self:GetLocalData()
    save["times"] = save["times"] or {}
    local times = save["times"]
    if not times[""..id] then
        times[""..id] = 0
    end
    return times[""..id] == 0
end

--是否购买过
function ShopManager:BoughtBefor(id)
    if id == nil then
        return false
    end

    local save = self:GetLocalData()
    save["times"] = save["times"] or {}
    local times = save["times"]
    if not times[""..id] then
        times[""..id] = 0
    end
    return times[""..id] > 0
end

--获取已经购买次数
function ShopManager:GetBoughtTimes(id)
    if id == nil then
        return 0
    end

    local save = self:GetLocalData()
    save["times"] = save["times"] or {}
    local times = save["times"]
    if not times[""..id] then
        return 0
    end
    return times[""..id]
end

--重置双倍
function ShopManager:ResetDoubleDiamond()
    local shopIdList = {1000, 1001, 1002, 1003, 1004, 1005}
    local save = self:GetLocalData()
    save["times"] = save["times"] or {}
    local times = save["times"]
    for k,v in pairs(shopIdList) do
        if times[tostring(v)] then
            times[tostring(v)] = nil
        end
    end
end

--检测是否重置双倍
function ShopManager:CheckResetDoubleDiamond(data)

    if not data then return end
    if tonumber(data.activityType) == 3 then --活动类型3 是首充双倍重置
        local save = self:GetLocalData()
        local canResetId = true
        if not save.resetId then
            save.resetId = {}
        end
        for k,v in pairs(save.resetId) do
            if  v == data.instanceID then
                canResetId = false
                break
            end
        end
        if canResetId then
            save.resetId[tostring(Tools:GetTableSize(save.resetId) + 1)] = data.instanceID
            --self:ResetDoubleDiamond()
            local doubleDiamondData = GameTableDefine.FirstPurchaseUI:GetSaveData()
            doubleDiamondData.reset = false
            doubleDiamondData.open_conditions = data.open_conditions   -- 开启条件
            local now = GameTimeManager:GetTheoryTime()
            if data.endTime and tonumber(data.endTime) then
                doubleDiamondData.endTime = tonumber(data.endTime)
                doubleDiamondData.startTime = tonumber(data.startTime) or now
            else
                doubleDiamondData.endTime = now + 1440 * 60
                doubleDiamondData.startTime = now
            end
            LocalDataManager:WriteToFile()

            GameTableDefine.ActivityRemoteConfigManager:CheckResetDoubleEnable()
        end
    end
end

---@return function value和complex不要一起用, value已经是cfg.amount * complex的结果了
function ShopManager:GetCB(shopCfg)--获得购买效果的回调
    local typeId = shopCfg.type
    if cbGetter then
        if GameTableDefine.CycleInstanceDataManager:GetCurrentModel() then
            GameTableDefine.CycleInstanceDataManager:GetCurrentModel():RemoveTrigger(1, shopCfg.id)

        end
        EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", false)
        return cbGetter[typeId]
    end

    cbGetter = {}--数字具体对应功能看config_shop的type
    cbGetter[3] = function(value, cfg, cb, complex)

        local firstTime = FirstPurchaseUI:IsFirstDouble(cfg.id)
        local diamondAdd = cfg.amount
        if complex then
            diamondAdd = diamondAdd * complex
        end
        if cfg.param == nil and firstTime then
            diamondAdd = diamondAdd * 2
        end

        ResMgr:AddDiamond(diamondAdd, nil, cb, true)

        local way = nil
        if not cfg.param3 then
            way = tostring(cfg.id).."Unknow"
        else
            if cfg.param3[1] == "shop" then
                way = "商店购买"
            elseif cfg.param3[1] == "pack" then
                way = "礼包"
            elseif cfg.param3[1] == "wheel" then
                way = "转盘"
            elseif cfg.param3[1] == "activity" then
                way = "活跃度"
            elseif cfg.param3[1] == "rank" then
                way = "定时活动"
            elseif cfg.param3[1] == "yunying" then
                way = "运营"
            elseif cfg.param3[1] == "payment" then
                way = "累充"
            elseif cfg.param3[1] == "limitpack" then
                way = "限时礼包"
            elseif cfg.param3[1] == "instance" then
                way = "限时副本"
            end
        end


        -- GameSDKs:Track("get_diamond", {get = diamondAdd, left = ResMgr:GetDiamond(), get_way = way})
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = way, behaviour = 1, num_new = tonumber(diamondAdd)})
    end

    cbGetter[4] = function(value, cfg, cb, complex)
        local amount = cfg.amount
        if complex then
            amount = amount * complex
        end
        --广告卷
        ResMgr:AddTicket(amount, nil, cb)
    end
    cbGetter[29] = function(value, cfg, cb, complex)
        local amount = cfg.amount
        if complex then
            amount = amount * complex
        end
        --转盘卷
        ResMgr:AddWheelTicket(amount, nil, cb)
    end
    cbGetter[8] = function(value, cfg, cb, complex)
        local amount = cfg.amount * 3600
        if complex then
            amount = amount * complex
        end
        CompanyMode:AddExp(amount,true)
        if cb then cb() end
    end
    cbGetter[9] = function(value, cfg, cb)
        -- ResMgr:AddCash(value, nil, cb, true, true)
        -- 修改购买现金用
        ResMgr:AddLocalMoney(value, nil, cb, cfg.country ,nil , true)
        local countryType = 1
        if not cfg.country or cfg.country == 0 then
            countryType = GameTableDefine.CountryMode:GetCurrCountry() or 1
        end
        local position = "["..tostring(cfg.id).."]".."号商品购买"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(countryType) or 0, change_new = 0, amount_new = tonumber(value) or 0, position = position})
    end

    local save = self:GetLocalData()
    cbGetter[5] = function(value, cfg, cb)
        save["noAD"] = true
        MainUI:HideButton("NoAdBtn")
        if cb then cb() end
    end
    cbGetter[6] = function(value, cfg, cb)
        if not save["cash"] then
            save["cash"] = 0
        end

        save["cash"] = save["cash"] + cfg.amount
        -- MainUI:RefreshCashEarn()
        if cb then cb() end
        PetMode:Init()
        if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.SHOP_UI) then
            GameTableDefine.ShopUI:UpdateAllShowItem()
        end
    end
    cbGetter[7] = function(value, cfg, cb)
        if not save["time"] then
            save["time"] = 0
        end

        save["time"] = save["time"] + cfg.amount
        if cb then cb() end
        PetMode:Init()
        if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.SHOP_UI) then
            GameTableDefine.ShopUI:UpdateAllShowItem()
        end
        if GameTableDefine.OfflineRewardUI:HaveOfflineReward() then
            GameTableDefine.OfflineRewardUI:LoopCheckRewardValue(function()
                GameTableDefine.OfflineRewardUI:GetView()
            end, false)
        end
    end
    cbGetter[10] = function(value, cfg, cb)
        if not save["dia"] then
            save["dia"] = {}
        end

        local nowTime = TimerMgr:GetCurrentServerTime()
        local holdTime = (cfg.param2 and cfg.param2[1] or 30) - 1
        if holdTime then
            holdTime = holdTime * 86400--单位秒
        end

        local data = {}
        data["last"] = nowTime + holdTime--结束的时间
        data["num"] = cfg.param1--每日领取的数量
        data["get"] = nowTime - 86400 --上次领取的时间

        save["dia"] = data

        ResMgr:AddDiamond(cfg.amount, nil, cb, true)
        -- GameSDKs:Track("get_diamond", {get = cfg.amount, left = ResMgr:GetDiamond(), get_way = "钻石月卡"})
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石月卡", behaviour = 1, num_new = tonumber(cfg.amount)})
    end
    cbGetter[12] = function(value, cfg, cb)
        -- if cfg.id ~= 1037 then--更新成长礼包的最后一个
        --     save["frame8"] = cfg.id .. ""
        -- else
        --     save["new"] = true
        --     MainUI:HideButton("PackBtn")
        -- end
        local save = self:GetLocalData()

        save["times"] = save["times"] or {}
        local times = save["times"]
        times["" .. cfg.id] = (times[""..cfg.id] or 0) + 1

        if cfg.param3 then
            local type = cfg.param3[1]
            if type == 1 then--新手礼包
                MainUI:RefreshNewPlayerPackage(true)
            elseif type == 2 then--成长礼包
                save["frame8"] = cfg.id .. ""
                MainUI:RefreshGrowPackageBtn()--增加时刷新成长基金按钮的状态
            elseif type == 3 then--npc礼包
                save["frame10"] = true
            end
        end


        if cb then cb() end
    end
    cbGetter[13] = function(value, cfg, cb)--宠物
        -- wenhao 待删除 20221025
        local param = cfg.param[1]
        local cfgPet = ConfigMgr.config_pets[param]
        local allFun = {"income", "offline", "mood"}
        local saveName = {"cash", "time", "mood"}
        local petSave = nil
        for k,v in pairs(allFun) do
            petSave = "p" .. saveName[k]
            if cfgPet[v] then
                if not save[petSave] then
                    save[petSave] = 0
                end

                save[petSave] = save[petSave] + cfgPet[v]
            end
        end
        if cb then cb() end
        LocalDataManager:WriteToFile()
        if GameStateManager:IsInFloor() then
            PetMode:Init()
            PetMode:CreatePet(param)
        end
        if GameTableDefine.GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
            PetListUI:RefreshPetList()
        end
        GameSDKs:TrackForeign("pet_record", {id = cfg.id, operation_type = 4})
        --PetMode:RefreshEntity()
        -- GreateBuildingMana:RefreshImprove()
        -- MainUI:RefreshCashEarn()
    end
    cbGetter[14] = function(value, cfg, cb)--员工
        --员工,和宠物一样...
        -- wenhao 待删除 20221025
        local param = cfg.param[1]
        local cfgPet = ConfigMgr.config_employees[param]
        local allFun = {"income", "offline", "mood"}
        for k,v in pairs(allFun) do
            if cfgPet[v] then
                if not save["p"..v] then
                    save["p" .. v] = 0
                end

                save["p" .. v] = save["p"..v] + cfgPet[v]
            end
        end
        if cb then cb() end

        PetMode:Init()
        --PetMode:RefreshEntity()
        PetMode:CreateWorker(param)
        -- GreateBuildingMana:RefreshImprove()
        -- MainUI:RefreshCashEarn()
    end
    cbGetter[15] = function(value, cfg, cb)--成长基金                
        if cb then
            cb()
        end
    end
    cbGetter[16] = function(value, cfg, cb)
        ResMgr:AddLocalMoney(value, nil, cb, cfg.country ,nil , true)
        if cb then
            cb()
        end
    end
    cbGetter[17] = function(value, cfg, cb)--存钱罐
        GameSDKs:TrackForeign("money_box", {id = tostring(cfg.id or ""), order_state = 6, order_state_desc = "执行发放小猪奖励"})
        PiggyBankUI:GetReward()
        --MainUI:RefreshPiggyBankBtn()   -- 重复了，GetReward内会调用此方法 
        if cb then
            cb()
        end
    end
    cbGetter[18] = function(value, cfg, cb)--宠物零食    
        PetListUI:PetFeed(cfg.param[1], value, cb)
    end
    cbGetter[19] = function(value, cfg, cb) --工厂道具
        WorkshopItemUI:AddBuffProps(WorkshopItemUI:GetTypeByShopId(cfg.id), value)
        if cb then
            cb()
        end
    end
    cbGetter[20] = function(value, cfg, cb) -- 装扮物品（时装（戏服），挂件）
        DressUpDataManager:GetNewDressUpItem(cfg.param[1], value or cfg.amount)
        if cb then
            cb()
        end
    end
    cbGetter[21] = function(value, cfg, cb)
        -- 限时礼包
        if GameTableDefine.LimitPackUI:GetLimitPackReward(cfg) then
            --限时礼包购买次数加1
            self:AddLimitPackBuyTimes(cfg.id)
        elseif GameTableDefine.LimitChooseUI:GetLimitChooseReward(cfg) then
            --限时多选一礼包
        else

        end
        if cb then
            cb()
        end
    end

    cbGetter[22] = function(value, cfg, cb) --副本商品
        --2025-4-29副本小猪的实际发放
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():BuySlotPiggyBank()
        if cb then
            cb()
        end
    end

    cbGetter[23] = function(value, cfg, cb) --副本地标
        if cb then
            cb()
        end
    end

    cbGetter[24] = function(value, cfg, cb) --副本货币
        if cb then
            cb()
        end
    end

    cbGetter[25] = function(value, cfg, cb) --副本时间货币
        if cb then
            cb()
        end
        local time = cfg.amount * 60 * 60
        local _,money = GameTableDefine.InstanceModel:CalculateOfflineRewards(time,false,false)
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "副本货币包", behaviour = 2, num_new = tonumber(cfg.diamond)})
    end

    cbGetter[26] = function(value, cfg, cb, complex) --新副本英雄经验值
        if cb then
            cb()
        end
    end

    cbGetter[27] = function(value, cfg, cb, complex) --新副本经验书
        if cb then
            cb()
        end
    end

    cbGetter[30] = function(value, cfg, cb) --新副本拉霸机币
        if cb then
            cb()
        end
    end

    cbGetter[31] = function(value, cfg, cb, complex) --新副本分钟货币
        if cb then
            cb()
        end
    end

    cbGetter[32] = function(value, cfg, cb, complex) --新副本分钟积分
        if cb then
            cb()
        end
    end
    cbGetter[33] = function(value, cfg, cb, complex) --新副本钻石
        if cb then
            cb()
        end
    end
    cbGetter[36] = function(value, cfg, cb, complex) --新副本蓝图材料
        if cb then
            cb()
        end
    end

    cbGetter[37] = function(value, cfg, cb, complex) --通行证小游戏票
        -- 给通行证小游戏票
        local gameManager = GameTableDefine.SeasonPassManager:GetCurGameManager()
        if not gameManager then
            return
        end
        if gameManager.AddTicket then
            gameManager:AddTicket(value)
        end
        if cb then
            cb()
        end
    end

    cbGetter[38] = function(value, cfg, cb, complex) --通行证小游戏积分
        -- 给通行证小游戏积分
        local gameManager = GameTableDefine.SeasonPassManager:GetCurGameManager()
        if not gameManager then
            return
        end
        if gameManager.AddPoint then
            gameManager:AddPoint(value)
        end
        if cb then
            cb()
        end
    end

    cbGetter[39] = function(value, cfg, cb, complex) --通行证小游戏双倍球
        --TODO 给通行证小游戏双倍球
        if cb then
            cb()
        end
    end

    cbGetter[40] = function(value, cfg, cb, complex) --高级通行证
        --TODO 给高级通行证
        if cb then
            cb()
        end
    end

    cbGetter[41] = function(value, cfg, cb, complex) --豪华通行证
        --TODO 给豪华通行证
        if cb then
            cb()
        end
    end

    --CEO钥匙购买
    cbGetter[43] = function(value, cfg, cb)
        GameSDKs:TrackForeign("ceo_key_change", {type = cfg.param[1], source = "商城钥匙直购", num = tonumber(cfg.amount)})
        GameTableDefine.CEODataManager:AddCEOKey(cfg.param[1], cfg.amount)
        if cb then
            cb()
        end
    end

    if GameTableDefine.CycleInstanceDataManager:GetCurrentModel() then
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():RemoveTrigger(1, shopCfg.id)
    end
    EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", false)
    return cbGetter[typeId]
end

--[[
    @desc: 检测子项商品是否有不能购买的,返回不能购买的商品ID列表，如果没有就返回空
    author:{author}
    time:2023-05-15 17:13:40
    --@shopID: 
    @return:true说明这个子项买过，不能再购买了
]]
function ShopManager:CheckChildShopItemBuyTimes(shopID)
    local cfg = ConfigMgr.config_shop[shopID]
    if not cfg then
        return nil
    end
    if cfg.type ~= 12 then
        return nil
    end

    for k, id in ipairs(cfg.param) do
        if not self:CheckBuyTimes(id) then
            return true
        end
    end

    return nil
end

--[[
    @desc:设置购买成功商品相对应的互斥商品 
    author:{author}
    time:2023-06-13 11:45:30
    --@shopID: 
    @return:
]]
function ShopManager:SetBuyExclusionShopItem(shopID)
    local shopCfg = ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return
    end
    if shopCfg.param_extend and Tools:GetTableSize(shopCfg.param_extend) > 0 then
        local save = self:GetLocalData()
        save["times"] = save["times"] or {}
        local times = save["times"]
        for k, v in pairs(shopCfg.param_extend) do
            if times[""..v] then
                if ShopManager:CheckBuyTimes(v, times[""..v]) then
                    times[""..v] = times[""..v] + 1
                end
            else
                times[""..v] = 1
            end
        end
        LocalDataManager:WriteToFile()
    end
end

--[[
    @desc: 检测具有时效性商品是否有超时,这里要去popup配置表里面复查
    author:{author}
    time:2023-06-13 15:10:18
    --@shopID: 
    @return:false没有超时，不是时效商品也是没有超时的
]]
function ShopManager:CheckShopItemTimeLimit(shopID)
    if not ConfigMgr.config_popup[shopID] then
        return false
    end
    local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(shopID)
    if isTimeGift and leftTime == 0 then
        return true
    end
    return false
end

--[[
    @desc: 检测互斥物品是否购买过
    author:{author}
    time:2023-06-26 11:50:25
    --@shopID: 
    @return:
]]
function ShopManager:CheckExclusionShopBuy(shopID)
    local shopCfg = ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return true
    end
    return false
end