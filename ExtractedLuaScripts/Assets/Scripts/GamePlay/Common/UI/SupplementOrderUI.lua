--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-08-13 15:27:08
    用于运营自动补单功能的UI
]]

local SupplementOrderUI = GameTableDefine.SupplementOrderUI
local GameUIManager = GameTableDefine.GameUIManager
local MainUI = GameTableDefine.MainUI

function SupplementOrderUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.SUPPLEMENT_ORDER_UI, self.m_view, require("GamePlay.Common.UI.SupplementOrderUIView"), self, self.CloseView)
    return self.m_view
end

function SupplementOrderUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.SUPPLEMENT_ORDER_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function SupplementOrderUI:OnRestorePurchaseCallback(successful, productId, extra)
    self:GetView():Invoke("OnRestorePurchaseCallback", successful, productId, extra)
end

--[[
    @desc: 解析当前补单相关内容对于之前restore为0不能补单的情况进行
    author:{author}
    time:2025-01-08 14:11:28
    --@shopID:
	--@sdkData: 
    @return:1-累充，2-通信证，3-下班打卡
]]
function SupplementOrderUI:ParseRestoreZeroRealItems(shopID, sdkData)
    local rewardsData = {}
    local isAccumulate = 0
    local shopCfg = GameTableDefine.ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return rewardsData, isAccumulate
    end
    -- {IsAccumulateItem = true}
    
    if sdkData and Tools:GetTableSize(sdkData) > 0 and sdkData.IsAccumulateItem then
        --标记这个是属于累充相关的物品
        rewardsData[shopID] = 1
        local tmpAccumulate = sdkData.IsAccumulateItem and GameTableDefine.AccumulatedChargeActivityDataManager:GetActivityIsOpen()
        if not tmpAccumulate then
            --转成钻石发放
            rewardsData = {}
            local getDiamondItemNum = shopCfg.restore_num or 0
            if getDiamondItemNum > 0 then
                rewardsData[5000] = getDiamondItemNum 
            end
            isAccumulate = 0
        else
            isAccumulate = 1
        end
        return rewardsData, isAccumulate
    end

    --下班打卡补单
    if sdkData and Tools:GetTableSize(sdkData) > 0 and sdkData.IsClockOutItem then
        rewardsData[shopID] = 1
        local tmpClockOut = sdkData.IsClockOutItem and GameTableDefine.ClockOutDataManager:GetActivityIsOpen()
        if not tmpClockOut then
            rewardsData = {}
            local getDiamondItemNum = shopCfg.restore_num or 0
            if getDiamondItemNum > 0 then
                rewardsData[5000] = getDiamondItemNum
            end
            isAccumulate = 0
        else
            isAccumulate = 3
        end
        return rewardsData, isAccumulate
    end

    if shopCfg.type == 12 then
        for _, id in pairs(shopCfg.param or {}) do
            if not rewardsData[id] then
                
                rewardsData[id] = 1
            else
                rewardsData[id] = rewardsData[id] + 1
            end
        end
    elseif shopCfg.type == 21 then
        -- realData.shopId  = item.id
        -- realData.num = item.num
        --这种需要依赖补单回调回来的数据结构进行补偿
        for _, item in pairs(sdkData or {}) do
            if item.shopId and item.num then
                if not rewardsData[item.shopId] then
                    rewardsData[item.shopId] = item.num
                else
                    rewardsData[item.shopId] = rewardsData[item.shopId] + item.num
                end
            end
        end
    elseif shopCfg.type == 40 or shopCfg.type == 41 then
        rewardsData[shopID] = 1
    else
        if not rewardsData[shopID] then
            rewardsData[shopID] = 1
        else
            rewardsData[shopID] = rewardsData[shopID] + 1
        end
    end

    --开始检测商品中有时效性的，如果不在实效内的话，转换成对应的补偿钻石
    local needDelKey = {}
    local addItems = {}
    for rewardID, num in pairs(rewardsData) do
        local rewardShopCfg = GameTableDefine.ConfigMgr.config_shop[rewardID]
        if not rewardShopCfg then
            table.insert(needDelKey, rewardID)
        else
            if rewardShopCfg.type == 40 or rewardShopCfg.type == 41 then
                --通信证如果不在开启期间也是转成钻石
                if not GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
                    --转成钻石发放
                    rewardsData = {}
                    local getDiamondItemNum = rewardShopCfg.restore_num or 0
                    if getDiamondItemNum > 0 then
                        rewardsData[5000] = getDiamondItemNum 
                    end
                    return rewardsData, isAccumulate
                else
                    isAccumulate = 2
                    return rewardsData, isAccumulate
                end
            elseif rewardShopCfg.type == 26 or rewardShopCfg.type == 27 or rewardShopCfg.type == 30 or rewardShopCfg.type == 23 or rewardShopCfg.type == 36 or rewardShopCfg.type == 22 then
                --判断副本是否开启中
                local isInstanceOpen = false
                local currInstanceID = GameTableDefine.CycleInstanceDataManager:GetCurActivityInstance()
                isInstanceOpen = currInstanceID and GameTableDefine.CycleInstanceDataManager:GetInstanceIsActive(currInstanceID)
                if not isInstanceOpen then
                    local getDiamondItemNum = rewardShopCfg.restore_num or 0
                    if getDiamondItemNum > 0 then
                        if addItems[5000] then
                            addItems[5000]  = addItems[5000] + getDiamondItemNum
                        else
                            addItems[5000] = getDiamondItemNum
                        end
                    end
                    table.insert(needDelKey, rewardID)
                end
            elseif rewardShopCfg.type == 37 then
                --通行证小游戏门票
                if not GameTableDefine.SeasonPassManager:GetActivityIsOpen() then
                    local getDiamondItemNum = rewardShopCfg.restore_num or 0
                    if getDiamondItemNum > 0 then
                        if addItems[5000] then
                            addItems[5000]  = rewardsData[5000] + getDiamondItemNum
                        else
                            addItems[5000] = getDiamondItemNum
                        end
                    end
                    table.insert(needDelKey, rewardID)
                end
            end
        end
    end
    for _, delKey in pairs(needDelKey) do
        if rewardsData[delKey] then
            rewardsData[delKey] = nil
        end
    end
    for key, value in pairs(addItems) do
        if rewardsData[key] then
            rewardsData[key]  = rewardsData[key] + value
        else
            rewardsData[key] = value
        end
    end
    return rewardsData, isAccumulate
end
