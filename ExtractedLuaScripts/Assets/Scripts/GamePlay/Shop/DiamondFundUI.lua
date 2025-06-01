---@class DiamondFundUI
local DiamondFundUI = GameTableDefine.DiamondFundUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ShopManager = GameTableDefine.ShopManager
local StarMode = GameTableDefine.StarMode
local Shop = GameTableDefine.Shop
local IAP = GameTableDefine.IAP
local DeviceUtil = CS.Game.Plat.DeviceUtil

--奖励配置表
local cfg = ConfigMgr.config_fund
local shop = nil
local FOUND_SHOP_ID = 1067

function DiamondFundUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.DIAMONDFUNDUIVIEW_UI, self.m_view, require("GamePlay.Shop.DiamondFundUIView"), self, self.CloseView)
    return self.m_view
end

function DiamondFundUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.DIAMONDFUNDUIVIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

---是否购买钻石基金
function DiamondFundUI:IsBoughtFund()
    return not ShopManager:CheckBuyTimes(FOUND_SHOP_ID, 1)
end

--判断一个item能否进行获得(玩家存档,配置数据,第几个item)
function DiamondFundUI:IsCanGet(fundData, cfg, index)
    --local data = ConfigMgr.config_shop

    --星级不够
    if StarMode:GetStar() < cfg[index].fame then
        return false
    end

    if cfg[index].isPay then
        --需要购买的
        if self:IsBoughtFund() and
                fundData["fame" .. index] then
            return true
        else
            return false
        end
    else
        --免费的
        return fundData["fame" .. index] and true or false
    end
end

--判断是否存在有能领取但是没领取的奖励
function DiamondFundUI:IsCanDraw(fundData, cfg)
    shop = LocalDataManager:GetDataByKey("shop")
    if shop["fund_data"] == nil then
        shop["fund_data"] = {}
    end
    --不传入 fundData 时
    if fundData == nil then
        fundData = shop["fund_data"]
    end
    if cfg == nil then
        cfg = ConfigMgr.config_fund or {}
    end
    for i = 1, #cfg do
        if fundData["fame" .. i] == nil then
            fundData["fame" .. i] = true
        end
        if self:IsCanGet(fundData, cfg, i) then
            return true
        end
    end
    return false
end

---@return number,number,number 现价,原价,折扣比例
function DiamondFundUI:GetPrice()
    local shopID = FOUND_SHOP_ID
    --local discount = 1-(ConfigMgr.config_popup[FOUND_SHOP_ID].offvalue or 0.90)
    local discount = 0.1
    local price = Shop:GetShopItemPrice(shopID)
    local priceOriginal, priceNum, comma = IAP:GetPriceDouble(shopID)
    local cheatPrice = 0
    if priceNum then
        cheatPrice = tonumber(priceNum) / discount
    end
    if GameDeviceManager:IsiOSDevice() then
        if cheatPrice == 0 then
            cheatPrice = priceOriginal
        elseif tonumber(cheatPrice) then
            cheatPrice = DeviceUtil.InvokeNativeMethod("formaterPrice", cheatPrice)
        end
    else
        if priceNum then
            local isHaveUSDSymbol = string.find(priceOriginal, "%$")
            local head = string.gsub(priceOriginal,"%p","")
            head = string.gsub(head,"%d","")
            local back = ""

            local cheatPriceInt = math.floor( cheatPrice )
            local cheatPriceStr = tostring(cheatPriceInt)
            local digitDiff = #cheatPriceStr - #priceNum
            back = cheatPriceStr
            if comma then
                for k,v in pairs(comma) do
                    local front = string.sub(back, 1, k +digitDiff -1 )
                    local after = string.sub(back, k +digitDiff -1 +1)

                    back = front..v..after
                end
            end
            if isHaveUSDSymbol then
                cheatPrice = head.."$"..back
            else
                cheatPrice = head..back
            end
        else
            cheatPrice = priceOriginal
        end
    end
    if price == "loading..." then
        cheatPrice = price
    end
    return price,cheatPrice,discount
end

---是否解锁钻石基金，可领取第一个奖励时算解锁
function DiamondFundUI:IsUnlocked()
    return StarMode:GetStar() >= ConfigMgr.config_fund[1].fame
end