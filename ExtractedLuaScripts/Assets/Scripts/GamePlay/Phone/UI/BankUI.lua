local BankUI = GameTableDefine.BankUI
local ValueManager = GameTableDefine.ValueManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function BankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BANK_UI, self.m_view, require("GamePlay.Phone.UI.BankUIView"), self, self.CloseView)
    return self.m_view
end

function BankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.BANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function BankUI:ValueToShow(value)
    local valueShow = ""
    local valueNow = value
    if valueNow > 1000 then
        valueShow = "K"
        valueNow = valueNow / 1000
    end
    if valueNow > 1000 then
        valueShow = "M"
        valueNow = valueNow / 1000
    end
    if valueNow > 1000 then
        valueShow = "B"
        valueNow = valueNow / 1000
    end
    valueNow = math.modf(valueNow * 10) / 10
    valueNow = string.format("%.1f", valueNow)
    return valueNow .. valueShow
end

function BankUI:GetBankNum()
    -- if not GameConfig:IsIAP() then
    --     return 0
    -- end    
    --raiseAble = ValueManager:RaiseCashLevel(true)
    local raiseAble = false
    for k,v in pairs(ConfigMgr.config_money) do
        if ValueManager:RaiseCashLevel(true, k) then
            raiseAble = true
            break
        end
    end
    return raiseAble == true and 1 or 0
end

function BankUI:GetRankNum()
    return ValueManager:GetRankReward(true) == true and 1 or 0
end

function BankUI:CanLevelUpDepositLimit(moreyType)
    for k,v in pairs(ConfigMgr.config_money) do
        if k == moreyType then
            return ValueManager:RaiseCashLevel(true, k)
        end
    end
end