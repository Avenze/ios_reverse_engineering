
local CompanysUI = GameTableDefine.CompanysUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local StarMode = GameTableDefine.StarMode
local CountryMode = GameTableDefine.CountryMode

local EventManager = require("Framework.Event.Manager")

local COMPANYS_UI_DATA = CountryMode.company_ui_data--引进界面的公司id,刷星时间等

function CompanysUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.COMPANYS_UI, self.m_view, require("GamePlay.Floors.UI.CompanysUIView"), self, self.CloseView)
    return self.m_view
end

function CompanysUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.COMPANYS_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CompanysUI:ExcludeCompany(companyId, add_or_remove)
    -- local save = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    -- if not save.excludeCompany then
    --     save.excludeCompany = {}
    -- end
    -- save.excludeCompany["id"..companyId] = add_or_remove and add_or_remove or nil
    -- LocalDataManager:WriteToFile()
end

function CompanysUI:IsCompanyUnlock(companyId, toUnlock)
    local cfg = ConfigMgr.config_company[companyId] or {}
    if not cfg.lock then
        return true
    end
    local curCmpCountryStr = "company_ui_data"
    local errorCmpCountryStr = "company_ui_dataEurope"
    if cfg.country == 1 then
        curCmpCountryStr = "company_ui_data"
    elseif cfg.country == 2 then
        curCmpCountryStr = "company_ui_dataEurope"
    end
    
    --已有存档错误的修正
    if CountryMode:GetCurrCountry() == 1 then
        errorCmpCountryStr = "company_ui_dataEurope"
    elseif CountryMode:GetCurrCountry() == 2 then
        errorCmpCountryStr = "company_ui_data"
    end

    local save = LocalDataManager:GetDataByKey(curCmpCountryStr)
    if not save.companyUnlock then
        save.companyUnlock = {}
    end

    if toUnlock then
        save.companyUnlock["company"..companyId] = true
        LocalDataManager:WriteToFile()
    end

    --这里为了解决有的数据存到另外个地区里面去了要做容错检测了
    local curCountryUIData = CountryMode.company_ui_data
    local isSaveUnLock = save.companyUnlock["company"..companyId]
    if not isSaveUnLock then
        --如果是假，再去另外个存档里面读一次数据
        local tmpSave = LocalDataManager:GetDataByKey(errorCmpCountryStr)
        if tmpSave and tmpSave.companyUnlock then
            isSaveUnLock = tmpSave.companyUnlock["company"..companyId]
        end
    end
    -- return save.companyUnlock["company"..companyId] and true or false
    return isSaveUnLock and true or false
end

function CompanysUI:MakeEnableCompanys()
    --local currStar = StarMode:GetStar() + 1
    local currCity = LocalDataManager:GetDataByKey(CountryMode.city_record_data).currBuidlingId
    -- local currScene = 1
    -- if currCity then
    --     currScene = ConfigMgr.config_buildings[currCity].index
    -- end
    local tempQuality = ConfigMgr.config_buildings[currCity].company_qualities or {}
    local needMix = tempQuality[1]
    local needMax = tempQuality[2]

    local roomList = FloorMode:GetCurrFloorConfig().room_list
    local need = {}
    local cfg_room = ConfigMgr.config_rooms

    local save = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    -- if not save.excludeCompany then
    --     save.excludeCompany = {}
    -- end
    -- local excludeCompanys = save.excludeCompany--原来邀请了的公司就不会再出现在公司列表
    -- for i = 1, #roomList do
    --     local activeCompanyId = CompanyMode:CompIdByRoomIndex(cfg_room[roomList[i]].room_index)
    --     if activeCompanyId ~= nil then
    --         existCompany[activeCompanyId] = 1
    --     end
    -- end

    for k,v in ipairs(ConfigMgr.config_company) do
        if v.company_quality >= needMix and 
            v.company_quality <= needMax and          
            (v.lock == 0 or self:IsCompanyUnlock(v.id)) and
            v.country == CountryMode:GetCurrCountry()
            then
            need[v.id] = v
        end
    end
    self.companysPool = need
    return self.companysPool
end

--从companysPool中选needNum个
--其中资质最高的要求留2个,其余的随机...
function CompanysUI:RandomCompanysId(needNum)
    local totalNum = #self.companysPool
    if needNum == nil then
        needNum = 5
    end

    local currCity = LocalDataManager:GetDataByKey(CountryMode.city_record_data).currBuidlingId
    local tempQuality = ConfigMgr.config_buildings[currCity].company_qualities or {}
    local needMax = tempQuality[2]

    --生成的序列,把最高星级要求的保存起来
    local allCompanys = {}
    local maxCompanys = {}
    for k in pairs(self.companysPool) do
        allCompanys[#allCompanys + 1] = self.companysPool[k].id
    end

    self:randomData(allCompanys)
    --往fromIds补充需要的公司id
    local result = {}

    --往fromIds补充n个最高等级的
    local index = 1
    local addNum = 0

    --补充剩余的
    addNum = needNum - #result
    for i = 1, #allCompanys do
        while result[index] ~= nil do
            index = index + 1
        end
        
        if index > needNum then break end

        result[index] = allCompanys[i]
        index = index + 1
        addNum = addNum - 1

        if addNum == 0 then break end
    end

    self:randomData(result)
    return result
end

function CompanysUI:randomData(array)
    for i = #array, 1, -1 do
        local tempSave = array[i]
        local randomIndex = math.random(1,i)
        array[i] = array[randomIndex]
        array[randomIndex] = tempSave
    end
end

function CompanysUI:RefreshCompany(byFree)
    local currRoomId = "roomDefault"
    local lastRoomData = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    --local lastTime = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)

    lastRoomData["companys"] = self:RandomCompanysId()

    if byFree then
        lastRoomData["freeFreshTime"] = GameTimeManager:GetCurrentServerTime() + ConfigMgr.config_global.reroll_cooltime
    end

    lastRoomData["needAni"] = true

    LocalDataManager:WriteToFile()
    --2024-9-13fy添加，af打点上报刷新公司列表
    GameSDKs:TrackControlCheckData("af", "af,corp_refresh_1", {})
end

function CompanysUI:GetCurrCompanysId()
    local currRoomId = "roomDefault"
    local lastRoomData = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    if not lastRoomData["companys"] then
        lastRoomData["companys"] = self:RandomCompanysId()
    end

    return lastRoomData["companys"]
end

function CompanysUI:GetNextRefreshTime()
    local lastTime = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    if not lastTime["freeFreshTime"] then
        lastTime["freeFreshTime"] = GameTimeManager:GetCurrentServerTime(true)
    end

    return lastTime["freeFreshTime"]
end

function CompanysUI:NeedAni()
    local save = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    if save["needAni"] == nil then
        save["needAni"] = true
    end

    if save["needAni"] then
        save["needAni"] = false
        --LocalDataManager:WriteToFile()
        return true
    end

    return false
end

function CompanysUI:IdsToDatas(ids)
    local result = {}
    for v in pairs(ids) do
        result[#result + 1] = ConfigMgr.config_company[ids[v]]
    end

    return result
end

function CompanysUI:IdsToDatasSort(ids)
    local result = {}
    for index, v in ipairs(ids) do
        table.insert(result, ConfigMgr.config_company[v])
    end

    return result
end

function CompanysUI:OpenView()
    local ids = self:GetCurrCompanysId()
    self:GetView():Invoke("Refresh", self:IdsToDatas(ids))
end

function CompanysUI:SpecialOpenView(type)
    local ids = ConfigMgr.config_global.guide_company[type]
    local lastRoomData = LocalDataManager:GetDataByKey(CountryMode.company_ui_data)
    LocalDataManager:WriteToFile()
    lastRoomData["companys"] = ids    
    self:GetView():Invoke("Refresh", self:IdsToDatasSort(ids), true)
end

function CompanysUI:AfterInvite(companyId, haveEff)
    if GameUIManager:IsUIOpen(7) then
        CompanysUI:GetView():DestroyModeUIObject()
    end
    if haveEff then
        if GameUIManager:IsUIOpen(5) then
            RoomBuildingUI:GetView():DestroyModeUIObject()
        end
    else
        if GameUIManager:IsUIOpen(5) then
            RoomBuildingUI:ShowRoomPanelInfo(FloorMode.m_curRoomId)
        end
    end
end

EventManager:RegEvent("INVITE_COMPANY", function(companyId, haveEff)
    CompanysUI:AfterInvite(companyId, haveEff)
end);