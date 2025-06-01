local ShopAfterPerson = GameTableDefine.ShopAfterPerson
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local FloatUI = GameTableDefine.FloatUI
local TalkUI = GameTableDefine.TalkUI
local FloorMode = GameTableDefine.FloorMode
local PetMode = GameTableDefine.PetMode

local SHOP_PERSON = "shop_man"

local lastPersons = nil
local employees = nil
function ShopAfterPerson:ComeBefor(shopType, shopId)
    local data = LocalDataManager:GetDataByKey(SHOP_PERSON)
    if data.come == nil then
        data.come = {}
        return false
    end

    if data.come[""..shopType] == nil or data.come["" .. shopType] ~= shopId then
        data.come[""..shopType] = shopId
        LocalDataManager:WriteToFile()
        return false
    end

    return true
end

function ShopAfterPerson:GuideBefor()
    local data = LocalDataManager:GetDataByKey(SHOP_PERSON)
    if data.guid == nil then
        data.guid = true
        LocalDataManager:WriteToFile()
        return false
    end

    return true
end

function ShopAfterPerson:GetSkin(shopType)
    local cfg = ConfigMgr.config_shop
    local need = {}

    for k,v in pairs(cfg or {}) do
        if v.type == shopType then
            table.insert(need, k)
        end
    end

    if #need == 0 then
        return nil
    end

    local shopId = nil
    local npcIndex = nil
    for i = #need, 1, -1 do
        if not ShopManager:FirstBuy(need[i]) then
            shopId = need[i]
            npcIndex = i
            break
        end
    end

    if shopId == nil then
        return nil
    end

    if PetMode:GetPetLocalData(shopId) == nil then
        return nil
    end

    local nameHead = {[6] = "IncomeManager", [7] = "OfflineManager"}
    return nameHead[shopType] .. "_" .. npcIndex .. "_001", shopId, npcIndex
    --return nameHead[shopType] .. "_" .. result, result
end

function ShopAfterPerson:LastPerson(type, shopId, check)
    if lastPersons == nil then
        lastPersons = {}
    end

    if check then
        return lastPersons[type] == shopId
    end

    lastPersons[type] = shopId
end

function ShopAfterPerson:SetPerson(type, person)
    if employees == nil then
        employees = {}
    end

    employees[type] = person
end

function ShopAfterPerson:GetPerson(type)
    if employees == nil then
        employees = {}
    end

    return employees[type]
end

function ShopAfterPerson:BindTalkMessage(type, shopId, npcIndex)
    local employee = self:GetPerson(type)
    if not employee then
        return
    end

    local data = LocalDataManager:GetDataByKey(SHOP_PERSON)
    if not data.talk then
        data.talk = {}
    end

    if data.talk[""..shopId] == nil then
        GameTimer:CreateNewTimer(5, function()
            FloatUI:RemoveObjectCrossCamera(employee)
            FloatUI:SetObjectCrossCamera(employee, function(view)
                if view then
                    view:Invoke("AZhenTalk", function()
                        self:TalkMessage(type, shopId, npcIndex)
                    end)
                end
            end)
        end)
    end
end

function ShopAfterPerson:DeleteTalkMessage(type, shopId)
    local employees = self:GetPerson(type)
    if not employees then
        return
    end

    local data = LocalDataManager:GetDataByKey(SHOP_PERSON)
    if not data.talk then
        data.talk = {}
    end
    data.talk["" .. shopId] = true
    FloatUI:RemoveObjectCrossCamera(employees)
end

function ShopAfterPerson:TalkMessage(type, shopId, npcIndex)
    
    local id = {[6] = "income", [7] = "offline"}
    local valueName = {[6] = "incomeRate", [7] = "offlineLimit"}
    local mValue = nil

    if type == 6 then
        mValue = (FloorMode:GetCurrImprove() - 1 ) * 100
    elseif type == 7 then
        mValue = ShopManager:GetOfflineAdd() + ConfigMgr.config_global.offline_timelimit
    end

    TalkUI:OpenTalk(id[type] .. "_" ..npcIndex,
    {
        [valueName[type]] = mValue
    },
    function()--finish

    end,
    function()--begin
        self:DeleteTalkMessage(type, shopId)
    end)
end