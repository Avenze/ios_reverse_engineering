---@class PetListUI
local PetListUI = GameTableDefine.PetListUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local PetInteractUI = GameTableDefine.PetInteractUI
local CountryMode = GameTableDefine.CountryMode
local PetMode = GameTableDefine.PetMode
local EventManager = require("Framework.Event.Manager")

function PetListUI:GetView()
    PetListUI.PetListUIViewClass = require("GamePlay.Common.UI.PetListUIView")
    require("GamePlay.Common.UI.CEO.CEOListUIView")
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PET_LIST_UI, self.m_view, PetListUI.PetListUIViewClass, self, self.CloseView)
    return self.m_view
end

function PetListUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PET_LIST_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--获取到购买过的宠物的列表
function PetListUI:GetPets()
    local cfgPet = ConfigMgr.config_pets
    local pets = {}    
    -- self:InitPetdata()                      
    local PetsData = PetMode:GetPetsdata()
    for k,v in pairs(PetsData) do
        if PetMode:IsPetData(v) then
            table.insert(pets, k)
        end
    end
    table.sort(pets, function(a, b)
        return tonumber(a) < tonumber(b)
    end)
    return pets
end

--领取宠物零食
function PetListUI:PetFeed(type, num, cb)
    local type = type or 1
    for k,v in pairs(ConfigMgr.config_pets) do
        if k == type then
            type = tostring(type)
            local num = num or 1  
            --local PetFeed = LocalDataManager:GetDataByKey("pet_feed")
            local petFeedCount = PetMode:GetPetFeed(type)
            petFeedCount = petFeedCount + num
            PetMode:SetPetFeed(type, petFeedCount)
            LocalDataManager:WriteToFile()
            self:RefreshFeed()
            PetInteractUI:RefreshFeedList()
            if cb then
                cb()
            end 
            break
        end  
    end    
end

--隐藏
function PetListUI:Hideing(reverse)
    self:GetView():Invoke("Hideing", reverse)
end

--刷新零食
function PetListUI:RefreshFeed()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
        self:GetView():Invoke("RefreshFeed")
    end    
end

--刷新列表
function PetListUI:RefreshPetList()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
        self:GetView():Invoke("RefreshList")
    end    
end

--显示CEO列表
function PetListUI:ShowCEOPanel()
    self:GetView()
end

--刷新CEO列表
function PetListUI:RefreshCEOPanel()
    if self.m_view then
        self.m_view:InitCEO()
    end
end


function PetListUI:RefreshEmployee()
    self:GetView():Invoke("RefreshEmployee")
end