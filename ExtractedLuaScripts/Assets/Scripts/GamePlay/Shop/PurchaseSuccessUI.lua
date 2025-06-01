---@class PurchaseSuccessUI
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger

function PurchaseSuccessUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PURCHASESUCCESS_UI, self.m_view, require("GamePlay.Shop.PurchaseSuccessUIView"), self, self.CloseView)
    return self.m_view
end

function PurchaseSuccessUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PURCHASESUCCESS_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--商品id, 回调, 是否是礼物, 道具的数量(默认1个), 忽略钻石补偿(转盘需要先得到物品)
function PurchaseSuccessUI:SuccessBuy(shopId, cb, isGift, complex, ignoreCompensate, exitCb, extendParam)
    ---调用View中的"SuccessBuy",方法
    local complex = complex or 1
    local allType = {"income", "offline", "mood", "exp", "cash", "diamond", "ad", "monthd", "fund"}
    local value,typeName = ShopManager:GetValueByShopId(shopId)
    if type(value) == "number" then
        value = value * complex
    end    
    local cfg = ShopManager:GetCfg(shopId)
    if extendParam and tonumber(extendParam) and tonumber(extendParam) ~= 0 then
        value  = value * tonumber(extendParam)
    end
    local showValue = ShopManager:SetValueToShow(value, cfg)

    local title = ShopManager:GetTilet(cfg.type, shopId)

    local allShow = {}
    local tempdata = {}

    if cfg.type ~= 12 then
        if ShopManager:CheckBuyTimes(shopId) or ignoreCompensate then
            tempdata.icon = cfg.icon
            tempdata.show = showValue
            tempdata.name = cfg.name
            tempdata.typeName = typeName
            table.insert(allShow, tempdata)
        else
            local currCfg = ShopManager:GetCfg(shopId)
            if currCfg then 
                local backDiamond = 0
                --增加单个商品购买时判断是否转钻石
                if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
                    backDiamond = backDiamond + currCfg.param2[1]
                elseif currCfg.type == 6 or currCfg.type == 7 then--npc
                    backDiamond = backDiamond + currCfg.param[1]
                elseif currCfg.type == 5 then--免广告
                    backDiamond = backDiamond + currCfg.param[1]
                end

                if backDiamond > 0 then
                    tempdata = {}
                    tempdata.icon = "icon_shop_diamond_3"
                    tempdata.name = "TXT_SHOP_COMPENSATE"
                    tempdata.typeName = "diamond"
                    tempdata.show = Tools:SeparateNumberWithComma(backDiamond)
                    ResourceManger:AddDiamond(backDiamond, nil, nil, true)
                    -- GameSDKs:Track("get_diamond", {get = backDiamond, left = ResourceManger:GetDiamond(), get_way = "重复购买补偿"})
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "重复购买补偿", behaviour = 1, num_new = tonumber(backDiamond)})
                    table.insert(allShow, tempdata)
                end
            end
        end
    else
        local allParam = cfg.param
        local currCfg = nil
        local backDiamond = 0
        for k,v in pairs(allParam) do
            currCfg = ShopManager:GetCfg(v)

            if ShopManager:CheckBuyTimes(v)  or ignoreCompensate then
                value,typeName = ShopManager:GetValueByShopId(v)
                showValue = ShopManager:SetValueToShow(value, currCfg)
                tempdata = {}
                tempdata.icon = currCfg.icon
                tempdata.name = currCfg.name
                tempdata.typeName = typeName
                tempdata.show = showValue
                tempdata.shopId = v
                table.insert(allShow, tempdata)
            else--购买过,补偿钻石...或者以后考虑全改到同一个地方配置,免得以后忘了
                if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
                    backDiamond = backDiamond + currCfg.param2[1]
                elseif currCfg.type == 6 or currCfg.type == 7 then--npc
                    backDiamond = backDiamond + currCfg.param[1]
                elseif currCfg.type == 5 then--免广告
                    backDiamond = backDiamond + currCfg.param[1]
                end
            end
        end

        if backDiamond > 0 then
            tempdata = {}
            tempdata.icon = "icon_shop_diamond_3"
            tempdata.name = "TXT_SHOP_COMPENSATE"
            tempdata.typeName = "diamond"
            tempdata.show = Tools:SeparateNumberWithComma(backDiamond)
            ResourceManger:AddDiamond(backDiamond, nil, nil, true)
            -- GameSDKs:Track("get_diamond", {get = backDiamond, left = ResourceManger:GetDiamond(), get_way = "重复购买补偿"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "重复购买补偿", behaviour = 1, num_new = tonumber(backDiamond)})

            table.insert(allShow, tempdata)
        end
    end

    self:GetView():Invoke("SuccessBuy", shopId, allShow, cb, isGift, exitCb)
    
end

--商品id, 回调, 是否是礼物, 道具的数量(默认1个), 忽略钻石补偿(转盘需要先得到物品)
function PurchaseSuccessUI:SuccessBuyCar(carID, cb)
    self:GetView():Invoke("SuccessBuyCar", carID, cb)
end
--生成需要播放的东西的表(可以通过for循环添加到self.playList)--弃用
-- function PurchaseSuccessUI:createPlayList(shopId, complex)
--     if not self.playList then
--         self.playList = {}
--     end
--     local cfg = ShopManager:GetCfg(shopId)
--     local value,typeName = ShopManager:GetValueByShopId(shopId)
--     if complex and type(value) == "number" then
--         value = value  * complex
--     end
--     local showValue = ShopManager:SetValueToShow(value, cfg)
--     local tempdata = {}
--     tempdata[shopId] = {}
--     tempdata[shopId].icon = cfg.icon
--     tempdata[shopId].show = showValue
--     tempdata[shopId].name = cfg.name
--     tempdata[shopId].typeName = typeName
--     table.insert(self.playList, tempdata)
-- end

-- --播放 self.palyList 中的东西--弃用
-- function PurchaseSuccessUI:PlayList()
--     self:GetView():Invoke("PlayList")
-- end

function PurchaseSuccessUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PURCHASESUCCESS_UI)
    self.m_view = nil
    collectgarbage("collect")
end