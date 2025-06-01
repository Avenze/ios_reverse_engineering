 
local ConfigMgr = GameTableDefine.ConfigMgr
---@class CountryMode
local CountryMode = GameTableDefine.CountryMode

local FREE_CITY = 1
local EUROPE = 2

CountryMode.CurrentCountrySaveKey = "current_country"
CountryMode.SAVE_KEY = {
    [FREE_CITY] = "",                           --自由城存档的角标
    [EUROPE] = "Europe",                        --欧洲存档角标
}
local WORLD_SIZE = Tools:GetTableSize(CountryMode.SAVE_KEY) + 1
local SAVE_KEY = CountryMode.SAVE_KEY

function CountryMode:ctor()
    self.rooms = "rooms"                        --房间存档默认索引
    self.city_record_data = "city_record_data"  --大地图存档默认索引
    self.company_in_rooms = "company_in_rooms"  --公司默认存档索引
    self.greate_building = "greate_building"    --地图上的建筑
    self.room_progress = "room_progress"        --房间的等级的默认
    self.company_ui_data = "company_ui_data"    --公司UI的
    self.factory = "factory"                    --工厂存档默认索引
    self.football = "football"                  --足球俱乐部存档默认索引
end

--地区之间的区分管理
function CountryMode:OnEnter()
    self:InitConfig()
    self.countryData = LocalDataManager:GetDataByKey(CountryMode.CurrentCountrySaveKey)
    self:SetCurrCountry(self.countryData.current_country or 1)
    local buidingData = LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    if self.countryData.current_country == 2 and not buidingData.currBuidlingId then
        self.countryData.current_country = 1
        self:SetCurrCountry(1)
    end
end
function CountryMode:InitConfig()
    self.m_currCountry = 1
    self.m_countryCfg = ConfigMgr.config_country
    self.m_isSwitchCountry = false
    self.rooms = "rooms"                        --房间存档默认索引
    self.city_record_data = "city_record_data"  --大地图存档默认索引
    self.company_in_rooms = "company_in_rooms"  --公司默认存档索引
    self.greate_building = "greate_building"    --地图上的建筑
    self.room_progress = "room_progress"        --房间的等级的默认
    self.company_ui_data = "company_ui_data"    --公司UI的
    self.factory = "factory"                    --工厂存档默认索引
    self.football = "football"                  --足球俱乐部存档默认索引

end
--获取当前国家
function CountryMode:GetCurrCountry()
    return self.m_currCountry or 1 
end

---获取已购买的最新办公楼ID
function CountryMode:GetMaxDevelopCountryBuildingID()
    local countryConfig = ConfigMgr.config_country
    local buildingID = 100

    for id,cfg in pairs(countryConfig) do
        local data = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[id])
        if data and data.currBuidlingId and data.currBuidlingId ~= 0 then
            if data.currBuidlingId > buildingID then
                buildingID = data.currBuidlingId
            end
        end
    end
    return buildingID
end

--设置(修改)当前国家
function CountryMode:SetCurrCountry(type)
    for k,v in pairs(self.m_countryCfg or {}) do
        if type == v.id then 
            self.m_currCountry = type
            self.countryData.current_country = type
            LocalDataManager:WriteToFile()
        end
    end
    self.m_isSwitchCountry = true
    self:SetDataKeybyCurrCountry()
    self:SetInforKeybyCurrCountry()
end

--通过不同的国家设置不同的存档Key
function CountryMode:SetDataKeybyCurrCountry()
    self.rooms = "rooms" .. SAVE_KEY[self.m_currCountry]
    self.city_record_data = "city_record_data" .. SAVE_KEY[self.m_currCountry]
    self.company_in_rooms = "company_in_rooms" .. SAVE_KEY[self.m_currCountry]
    self.greate_building = "greate_building" .. SAVE_KEY[self.m_currCountry]
    self.room_progress = "room_progress" .. SAVE_KEY[self.m_currCountry]  
    self.company_ui_data = "company_ui_data" .. SAVE_KEY[self.m_currCountry]       
    self.factory = "factory" .. SAVE_KEY[self.m_currCountry]
    self.football = "football" .. SAVE_KEY[self.m_currCountry]
end

--设置一些信息的(默认钱的图片...)
function CountryMode:SetInforKeybyCurrCountry()
    self.cash_icon = "icon_cash_00" .. self.m_currCountry
end

--获取当前国家使用的国币
function CountryMode:GetCurrCountryCurrency()
    for k,v in pairs( ConfigMgr.config_money or {}) do
        if v.id == CountryMode:GetCurrCountry() then
            return v.resourceId
        end
    end
    return 2
end

function CountryMode:IsFreeCity()
    return self:GetCurrCountry() == 1
end

--检测某个国家是否已经解锁
function CountryMode:CheckCity(countyId)
    if countyId == 1  then
        return true
    end
    local data = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[countyId])
    if not data.district or not data.district.unlockingId or not data.district.currId then
        return false
    end      
    return true
end

function CountryMode:GetAreaName(key)
    if not key then 
        return
    end

    local areaId = self:GetCurrCountry()
    if CountryMode:IsFreeCity() then
        return key
    else
        return key..areaId
    end
end

function CountryMode:GetWordSize()
    return WORLD_SIZE
end

function CountryMode:GetCountryRooms(countryId)
    if SAVE_KEY[countryId] then
        return "rooms"..SAVE_KEY[countryId]
    end
    return "rooms"..SAVE_KEY[self:GetCurrCountry()]
end