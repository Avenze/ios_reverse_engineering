---@class CommonRewardUI
local CommonRewardUI = GameTableDefine.CommonRewardUI
local GameUIManager = GameTableDefine.GameUIManager
local CountryMode = GameTableDefine.CountryMode
local ShopManager = GameTableDefine.ShopManager

function CommonRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.COMMON_REWARD_UI, self.m_view, require("GamePlay.Common.UI.CommonRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CommonRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.COMMON_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")

    if self.m_onCloseCallback then
        self.m_onCloseCallback()
        self.m_onCloseCallback = nil
    end
end

---逐个显示奖励.
function CommonRewardUI:ShowRewardsOneByOne(rewards,onCloseCallback)
    self.m_onCloseCallback = onCloseCallback
    if Tools:GetTableSize(rewards) > 0 then
        self:GetView():Invoke("ShowRewardsOneByOne", rewards)
    end
end

---通用奖励显示的数值和Icon
---@return string,string showValue,showIcon
function CommonRewardUI:GetShowValueString(itemShopID,itemCount)
    local value,typeName = ShopManager:GetValueByShopId(itemShopID)
    local cfgShop = ShopManager:GetCfg(itemShopID)
    if tonumber(value) ~= nil then
        value = value * itemCount
    end
    local showValue = ShopManager:SetValueToShow(value, cfgShop)
    local showIcon = cfgShop.icon
    if tonumber(value) == nil or typeName == "offline" or typeName == "income"then
        showValue = "x1"
    elseif typeName == "cash" then
        --local minutesStr = "x"..math.floor(itemCount * cfgShop.amount * 60) .. "Min"
        --showValue = minutesStr
        if CountryMode.m_currCountry == 1 then
            showIcon = cfgShop.icon
        elseif CountryMode.m_currCountry == 2 then
            showIcon = cfgShop.icon .. "_euro"
        end
    elseif typeName == "exp" then
        --    local minutesStr = "x"..math.floor(itemCount * cfgShop.amount * 60) .. "Min"
        --    showValue = minutesStr
    else
        showValue = "x"..showValue
    end

    return showValue,showIcon
end