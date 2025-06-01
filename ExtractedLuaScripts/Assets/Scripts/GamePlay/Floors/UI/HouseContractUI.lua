local HouseContractUI = GameTableDefine.HouseContractUI

local GameUIManager = GameTableDefine.GameUIManager
local CfgMgr = GameTableDefine.ConfigMgr
local HouseMode = GameTableDefine.HouseMode
local EventManager = require("Framework.Event.Manager")

function HouseContractUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.HOUSE_CONTRACT_UI, self.m_view, require("GamePlay.Floors.UI.HouseContractView"), self, self.CloseView)
    return self.m_view
end

function HouseContractUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.HOUSE_CONTRACT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function HouseContractUI:ShowPanel(cfg)
    local cfg = CfgMgr.config_house[cfg.id]
    local data = HouseMode:GetLocalData()
    local image = "icon_house_" .. cfg.id
    local name = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.id.."_NAME")
    local des = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.id.."_DESC")
    local price = string.format(GameTextLoader:ReadText("TXT_CONTRACT_HOUSE_CONTENT_1"), Tools:SeparateNumberWithComma(cfg.price))
    local carportNum = string.format(GameTextLoader:ReadText("TXT_CONTRACT_HOUSE_CONTENT_2"), #cfg.garage)
    -- local own = GameTextLoader:ReadText("TXT_CONTRACT_HOUSE_CONTENT_3")
    self:GetView():Invoke("ShowPanel", cfg, image, name, des, price, carportNum)
end
