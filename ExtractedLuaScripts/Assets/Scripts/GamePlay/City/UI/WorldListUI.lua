local WorldListUI = GameTableDefine.WorldListUI
local StarMode = GameTableDefine.StarMode
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CityMode = GameTableDefine.CityMode
local CountryMode = GameTableDefine.CountryMode

function WorldListUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.WORLD_LIST_UI, self.m_view, require("GamePlay.City.UI.WorldListUIView"), self, self.CloseView)
    return self.m_view
end

function WorldListUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.WORLD_LIST_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--判断当前有无能去的其他国家(mainui的moving按钮的红点显示)
function WorldListUI:MovingBtnHint()
    local data = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[2])
    local cfgCountry= ConfigMgr.config_country 
    local boolStar = false
    local boolCity = true
    for k,v in pairs(cfgCountry) do
        if StarMode:GetStar() >= v.starNeed and v.starNeed ~= 0 then
              boolStar = true
              break
        end
    end        
    if data.district and data.district.unlockingId and data.district.currId then
        boolCity = false                          
    end
    
    return boolStar and boolCity
end