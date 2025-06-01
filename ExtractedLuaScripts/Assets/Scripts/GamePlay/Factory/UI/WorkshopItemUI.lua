local WorkshopItemUI = GameTableDefine.WorkshopItemUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FactoryMode = GameTableDefine.FactoryMode
local CfgMgr = GameTableDefine.ConfigMgr
local TimerMgr = GameTimeManager

local EventManager = require("Framework.Event.Manager")

function WorkshopItemUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.WORKSHOP_ITEM_UI, self.m_view, require("GamePlay.Factory.UI.WorkshopItemUIView"), self, self.CloseView)
    return self.m_view
end

function WorkshopItemUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.WORKSHOP_ITEM_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function WorkshopItemUI:OpenUI(workshopId)
    self:GetView():Invoke("OpenUI", workshopId)
end

--buff道具的增加
function WorkshopItemUI:AddBuffProps(type, num, cb)
    local num = num or 1
    local type = tostring(type)
    local factoryPropsData = LocalDataManager:GetDataByKey("factory_props")
    if  not factoryPropsData.buff then
        factoryPropsData.buff = {}
    end
    if not factoryPropsData.buff[type] then
        factoryPropsData.buff[type] = num
    else
        factoryPropsData.buff[type] = factoryPropsData.buff[type] + num
    end
    LocalDataManager:WriteToFile()
    if cb then
        cb()
    end 
end

--buff道具的减少
function WorkshopItemUI:SpendBuffProps(type, num, cb)
    local num = num or 1
    local type = tostring(type)
    local  isEnough = false
    local factoryPropsData = LocalDataManager:GetDataByKey("factory_props")
    if not factoryPropsData.buff then
        factoryPropsData.buff = {}
    end
    if not factoryPropsData.buff[type] then
        factoryPropsData.buff[type] = 0        
    elseif factoryPropsData.buff[type] >= num then
        factoryPropsData.buff[type] = factoryPropsData.buff[type] - num
        isEnough = true
    elseif factoryPropsData.buff[type] < num then

    end
    LocalDataManager:WriteToFile() 
    if cb then
        cb(isEnough)
    end 
end
--获取此类工厂buff道具的数量
function WorkshopItemUI:GetBuffPropNum(type)
    local type = tostring(type)
    local factoryPropsData = LocalDataManager:GetDataByKey("factory_props")
    if not factoryPropsData.buff then
        return 0
    end
    if not factoryPropsData.buff[type] then
        return 0
    else
        return factoryPropsData.buff[type]
    end 
end

--工厂加上加速buff type 配置的buff类型 1,2,3
function WorkshopItemUI:AccelerateProduction(type, workshopId)
    local workshopData = FactoryMode:GetWorkShopdata(workshopId)
    local cfgBoots = CfgMgr.config_boost
    if not workshopData.buff then
        workshopData.buff = {}
    end    
    workshopData.buff.type = type
    workshopData.buff.timePoint = TimerMgr:GetCurrentServerTime(true) + cfgBoots[type].duration
    LocalDataManager:WriteToFile()    
end

--通过ShopId反过来获得type
function WorkshopItemUI:GetTypeByShopId(shopId)
    local cfgBoots = CfgMgr.config_boost
    for k,v in pairs(cfgBoots) do
        if v.shopId == shopId then
            return k
        end
    end
end