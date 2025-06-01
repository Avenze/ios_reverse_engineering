---@class PetMode
local PetMode = GameTableDefine.PetMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local FloorMode = GameTableDefine.FloorMode
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local CountryMode = GameTableDefine.CountryMode
local MainUI = GameTableDefine.MainUI
local LocalDataManager = LocalDataManager

local EventManager = require("Framework.Event.Manager")
local SimpleMover = require "CodeRefactoring.Actor.Actors.SimpleMoverNew"
local ActorManager = require("CodeRefactoring.Actor.ActorManager")

function PetMode:Exit()
    self.pets = nil
    self.record = nil
end

function PetMode:Init()
    -- self:InitPetdata()
    self:GetPetsdata(true)
    self:GetBuffValue(nil, true)
end

--获取宠物的存档
function PetMode:GetPetsdata(refreshDataFShop, countryId)
    if refreshDataFShop or self.record == nil then
        local petsData = LocalDataManager:GetDataByKey("pets")  
        local isNeedSave = false
        local func = function(v, isEmp)
            local petId = tostring(v.shopId)
            petsData[petId] = {}
            if not isEmp then
                petsData[petId].level = 1
                petsData[petId].experience = 0
                petsData[petId].hungry = 0    
                petsData[petId].buff = {}
            end
            petsData[petId].area = CountryMode:GetCurrCountry()
            isNeedSave = true
        end
        for k,v in pairs(ConfigMgr.config_pets or {}) do
            if ShopManager:BoughtBefor(v.shopId) and not petsData[tostring(v.shopId)] then        
                func(v)
            end
        end
        for k,v in pairs(ConfigMgr.config_employees or {}) do
            if ShopManager:BoughtBefor(v.shopId) and not petsData[tostring(v.shopId)] then        
                func(v, true)
            end
        end
        if isNeedSave then
            LocalDataManager:WriteToFile()
        end
        self.record = {{},{}, petsData} -- 1 自由城， 2 欧洲 ， 3 全球
        for k,v in pairs(petsData or {}) do
            self.record[v.area or 1][k] = v
        end
    end

    if not countryId then
        countryId =  CountryMode:GetWordSize()
    end
    return self.record[countryId]
end

function PetMode:GetPetLocalData(petId, cId)
    local data = self:GetPetsdata(nil, cId)
    return data[tostring(petId)]
end

function PetMode:Upgrade(petId)
    local data = self:GetPetLocalData(petId)
    if not data then
        return
    end
    data.level = data.level + 1
    data.experience = 0
    self:GetBuffValue(nil, true)
    LocalDataManager:WriteToFile()
end

--通过宠物Id获得宠物配置
function PetMode:GetPetCfgByPetId(petId)
    if not self.m_petConfigDic then
        self.m_petConfigDic = {}
        for k,v in pairs(ConfigMgr.config_pets) do
            self.m_petConfigDic[v.shopId] = v
        end
    end
    return self.m_petConfigDic[tonumber(petId)]
end

function PetMode:GetEmployeesCfgByPetId(id)
    for k,v in pairs(ConfigMgr.config_employees) do
        if v.shopId == tonumber(id) then
            return v
        end
    end
end

--清除场景中的宠物(现在只用在作弊清除中)
function PetMode:CleanEntiey()
    if self.pets ~= nil then
        for k,v in pairs(self.pets) do
            v:Destroy()
        end
    end
    self.pets = nil
end

--刷新生成已经购买过的宠物
function PetMode:Refresh()
    if self.pets == nil then
        self.pets = {}
    end

    local cfg = ConfigMgr.config_pets

    local root = FloorMode:GetScene().m_personRoot[1]
    local initPos = nil
    local skinRoot = "Assets/Res/Prefabs/Animals/"
    local employeesSkinRoot = "Assets/Res/Prefabs/character/"
    local skinPath = nil

    local record = self:GetPetsdata(nil,CountryMode:GetCurrCountry())
    for k,r in pairs(record or {}) do
        local shopId = tonumber(k)
        local v = self:GetPetCfgByPetId(k)
        if self.pets[shopId] == nil then -- and ShopManager:BoughtBefor(v.shopId)
            if v then
                initPos = FloorMode:GetScene():GetOnePlace()
                skinPath = skinRoot ..v.prefab .. ".prefab"
                local onePet = SimpleMover:CreateActor()
                onePet:Init(root, skinPath, initPos, v.speed, v.scale)
                self.pets[shopId] = onePet
            end

            v = self:GetEmployeesCfgByPetId(k)
            if v and v.prefab then
                initPos = FloorMode:GetScene():GetOnePlace()
                skinPath = employeesSkinRoot .. v.prefab .. ".prefab"
                local oneWorker = SimpleMover:CreateActor()
                oneWorker:Init(root, skinPath, initPos, nil, nil, v.id)
                self.pets[v.shopId] = oneWorker
            end
        end
    end
end

--购买宠物时生成宠物
function PetMode:CreatePet(petId)
    local cfg = ConfigMgr.config_pets[petId]
    if cfg == nil or not FloorMode:CheckSceneOnArea() then
        return
    end
    if self.pets == nil then
        self.pets = {}
    end
    if self.pets[cfg.shopId] then
        return
    end

    local root = FloorMode:GetScene().m_personRoot[1]
    local initPos = FloorMode:GetScene():GetOnePlace()
    local skinPath = "Assets/Res/Prefabs/Animals/" .. cfg.prefab .. ".prefab"

    local onePet = SimpleMover:CreateActor()
    onePet:Init(root, skinPath, initPos, cfg.speed, cfg.scale)
    self.pets[cfg.shopId] = onePet
end
--购买保安时生成保安(保安现在和宠物是一样的)
function PetMode:CreateWorker(workerId)
    local cfg = ConfigMgr.config_employees[workerId]
    if cfg == nil and cfg.prefab == nil or not FloorMode:CheckSceneOnArea() then
        return
    end
    if self.pets == nil then
        self.pets = {}
    end
    if self.pets[cfg.shopId] then
        return
    end

    local root = FloorMode:GetScene().m_personRoot[1]
    local initPos = FloorMode:GetScene():GetOnePlace()
    local skinPath = "Assets/Res/Prefabs/character/" .. cfg.prefab .. ".prefab"

    local onePet = SimpleMover:CreateActor()
    onePet:Init(root, skinPath, nil, nil, nil, workerId)
    self.pets[cfg.shopId] = onePet
end


function PetMode:GetBuffValue(key, update, countryId)
    if not countryId then
        countryId = CountryMode:GetCurrCountry()
    end

    if key and self.buff and self.buff[countryId] and self.buff[countryId][key] and not update then
        return self.buff[countryId][key]
    end 

    local petData = self:GetPetsdata(update, countryId)
    local old_mood_improve = (self.buff ~= nil) and self.buff.mood_improve or 0
    local old_money_enhance = (self.buff ~= nil) and self.buff.money_enhance or 0
    self.buff = self.buff or {}
    self.buff[countryId] = {}
    self.buff[countryId] = {mood_improve = 0, money_enhance = 0, offline_limit = 0}
    for k,v in pairs(petData or {}) do
        local id = tonumber(k)
        --宠物
        local cfg = self:GetPetCfgByPetId(id)
        if cfg then
            local value = cfg.bonus_effect[v.level or 1] or 0
            self.buff[countryId][cfg.bonus_type] = self.buff[countryId][cfg.bonus_type] + value
        end
        --员工(员工也算在宠物管理中,包装不同)
        cfg = self:GetEmployeesCfgByPetId(id)
        if cfg then
            local value = cfg.bonus_effect[v.level or 1] or 0
            self.buff[countryId][cfg.bonus_type] = self.buff[countryId][cfg.bonus_type] + value
        end
    end
    if old_mood_improve ~= self.buff[countryId].mood_improve then
        GreateBuildingMana:RefreshImprove()
        ActorManager:RefreshEmployeesMood()
    end
    if old_money_enhance ~= self.buff[countryId].money_enhance then
        MainUI:RefreshCashEarn()
    end
    if key then
        return self.buff[countryId][key]
    end
end

function PetMode:GetMoodImprove(update)
    return self:GetBuffValue("mood_improve", update)
end

function PetMode:GetCashImprove(update, countryId)
    return self:GetBuffValue("money_enhance", update, countryId)
end

function PetMode:GetOfflineAdd(update, countryId)
    return self:GetBuffValue("offline_limit", update, countryId)
end

function PetMode:CheckAreaData(data)
    if CountryMode:IsFreeCity() then
        return data.area == 1 or not data.area
    else
        return data.area == 2
    end
end

function PetMode:IsPetData(data)
    return data.buff and data.hungry and data.experience
end

function PetMode:PetsTransfer(countryId, cb)
    local isNeedSave
    local petsData = LocalDataManager:GetDataByKey("pets")
    for i,v in pairs(petsData or {}) do
        if v.area ~= countryId then
            v.area = countryId
            isNeedSave = true
        end
    end
    if isNeedSave then
        LocalDataManager:WriteToFile()
    end
    self:Init()
    self:Refresh()
    EventManager:DispatchEvent("EVENT_SHOP_PEOPLE")
    if cb then cb () end
end

function PetMode:CheckPetsCanTrans(countryId)
    local isNeedSave
    local petsData = LocalDataManager:GetDataByKey("pets")
    for i,v in pairs(petsData or {}) do
        local arear = v.area
        if v.area ~= countryId then
            return true
        end
    end
end

---获取宠物零食数量的统一接口
function PetMode:GetPetFeed(type)
    type = tostring(type)
    local PetFeed = LocalDataManager:GetDataByKey("pet_feed")
    if PetFeed then
        return LocalDataManager:DecryptField(PetFeed,type)
    end
    return 0
end

---设置宠物零食数量的统一接口
function PetMode:SetPetFeed(type,num)
    type = tostring(type)
    local PetFeed = LocalDataManager:GetDataByKey("pet_feed")
    if PetFeed then
        LocalDataManager:EncryptField(PetFeed,type,num)
    end
end