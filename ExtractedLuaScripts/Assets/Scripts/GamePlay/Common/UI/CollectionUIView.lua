local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ConfigMgr = GameTableDefine.ConfigMgr
local CompanyMapInfoUI = GameTableDefine.CompanyMapInfoUI
local ShopManager = GameTableDefine.ShopManager

local CollectionUIView = Class("CollectionUIView", UIView)

function CollectionUIView:ctor()
    self.super:ctor()
end

function CollectionUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("Bgcover","Button"), function()
        self:DestroyModeUIObject()
    end)
    self.dropDownNum = {"quality", "unlock"}
    local names = {GameTextLoader:ReadText("TXT_COLLECTION_FILTER_QUALITY"), GameTextLoader:ReadText("TXT_COLLECTION_FILTER_UNLOCK"),
                    GameTextLoader:ReadText("TXT_COLLECTION_FILTER_REWARD")}
    -- self.dropDown = self:GetComp("RootPanel/comPanel/RoomTitle/BtnPanel/Dropdown", "TMP_Dropdown")        
    -- self:SetDropdownText(self.dropDown, 1, names[1])
    -- self:SetDropdownText(self.dropDown, 2, names[2])    
    -- --self:SetDropdownText(self.dropDown, 3, names[3])
    -- self:SetDropdownValueChangeHandler(self.dropDown,handler(self, self.UpdateCompanySortType))
    self.dropDown = self:GetComp("RootPanel/comPanel/RoomTitle/BtnPanel/Dropdown", "Toggle")
    if self.dropDown then
        self:SetToggleValueChangeHandler(self.dropDown, function(isOn)
            local index = 0
            if isOn then
                index = 1
            else
                index = 0
            end
            self:UpdateCompanySortType(index)
        end)
    end
    self:EmployeeHint()
    self.sortType = "quality"
    self.m_list = self:GetComp("RootPanel/comPanel/RoomPanel/BuidlingList", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateCompanyCollect))
end

function CollectionUIView:OnExit()
    self.super:OnExit(self)
    self.dropDown = nil
    self.dropDownNum = nil
    self.sortType = nil
    self.m_list = nil
    self.m_data = nil
end

function CollectionUIView:UpdateCompanySortType(index)
    if self.sortType ~= self.dropDownNum[index+1] then
        self.sortType = self.dropDownNum[index+1]
        self:Refresh(self.m_data)
    end
end

function CollectionUIView:RefreshTitle(unlockNum, totalNum)
    self:SetText("RootPanel/comPanel/RoomTitle/HeadPanel/title/name", unlockNum..'/'..totalNum)
    local progress = self:GetComp("RootPanel/comPanel/RoomTitle/HeadPanel/title/prog", "Slider")
    progress.value = unlockNum / totalNum
end

function CollectionUIView:UpdateCompanyCollect(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.m_data[index]
    local cfg = ConfigMgr.config_company[data.id]

    -- local bgImage = self:GetComp(go, "Btn", "Image")
    -- self:SetSprite(bgImage, "UI_BG", "icon_gallery_bg_Grade"..cfg.company_quality)

    -- local bg2Image = self:GetComp(go, "Btn/bg", "Image")
    -- self:SetSprite(bg2Image, "UI_BG", "icon_gallery_Grade"..cfg.company_quality)

    local qualityImage = self:GetComp(go, "Btn/bg/quality", "Image")
    self:SetSprite(qualityImage, "UI_Common", "icon_Grade".. cfg.company_quality)

    self:GetGo(go, "Btn/bg/hint"):SetActive(data.rewardAble)

    local iconImage = self:GetComp(go, "Btn/bg/icon", "Image")
    if data.lv > 0 then
        self:SetSprite(iconImage, "UI_Common", cfg.company_logo..GameConfig:GetLangageFileSuffix())
        self:SetText(go, "bg/name", GameTextLoader:ReadText("TXT_COMPANY_C"..data.id.."_NAME"))
        self:GetGo(go, "locked"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp(go, "Btn", "Button"), function()
            CompanyMapInfoUI:Refresh(data,cfg)
        end)
    else
        self:SetSprite(iconImage, "UI_Common", "icon_colleciton_locked")
        self:SetText(go, "bg/name", "???")
        self:GetGo(go, "locked"):SetActive(true)
        self:SetButtonClickHandler(self:GetComp(go, "Btn", "Button"), function()
        end)
        --self:SetSprite(iconImage, "UI_Common", "icon_NoCompany")
    end
end

function CollectionUIView:Refresh(data)
    self.m_data = data

    local cfg = ConfigMgr.config_company

    if self.sortType =="quality" then
        table.sort(self.m_data, function(a,b)
            local qualityA = cfg[a.id].company_quality
            local qualityB = cfg[b.id].company_quality
            if qualityA ~= qualityB then
                return qualityA < qualityB
            else
                return a.id > b.id
            end
        end)
    elseif self.sortType == "unlock" then
        table.sort(self.m_data, function(a,b)
            local unlockA = a.lv > 0
            local unlocakB = b.lv > 0
            local qualityA = cfg[a.id].company_quality
            local qualityB = cfg[b.id].company_quality
            if unlockA ~= unlocakB then--有人解锁有人没解锁
                return unlockA == true
            elseif qualityA ~= qualityB then
                return qualityA < qualityB
            else
                return a.id < b.id
            end
        end)
    end

    self.m_list:UpdateData()
end
function CollectionUIView:GetProgress(cfg)
    local buy = 0
    local total = 0
    for k,v in pairs(cfg or {}) do
        if not ShopManager:FirstBuy(v.shopId) then
            buy = buy + 1
        end
        total = total + 1
    end

    return buy,total
end
function CollectionUIView:RefreshEmployee()
    local root = self:GetGo("RootPanel/empPanel")

    local quitBtn = self:GetComp("Bgcover", "Button")
    self:SetButtonClickHandler(quitBtn, function()
        self:DestroyModeUIObject()
    end)

    local cfg = GameTableDefine.PersonInteractUI:GetPersonData()

    local buy = 0

    local data = {}
    local curr = nil
    local first = nil
    for k,v in pairs(cfg or {}) do
        curr = {}
        curr.cfg = v
        if v.shopId then
            first = ShopManager:FirstBuy(v.shopId)
        else
            first = false
        end        
        curr.first = first
        -- --排除低等级的重复类型的经理
        -- for i,o in pairs(data) do
        --     if o.cfg.person_type == curr.cfg.person_type and o.cfg.id < curr.cfg.id then
        --         table.remove(data, i) 
        --         table.insert(data, curr) 
        --         break      
        --     elseif o.cfg.person_type == curr.cfg.person_type and o.cfg.id > curr.cfg.id then
        --         break
        --     elseif i == Tools:GetTableSize(data) then
        --         table.insert(data, curr)
        --         break
        --     end
        -- end
        -- if Tools:GetTableSize(data) == 0 then
        --     table.insert(data, curr)           
        -- end
        table.insert(data, curr) 
        if not first then
            buy = buy + 1
        end
    end
    -- handlerData = function(data)
    --     --添加老板和阿珍
    --     for k,v in pairs(GameTableDefine.PersonInteractUI:GetspecialData()) do
    --         local curr = {}
    --         curr.first = false
    --         curr.cfg = v
    --         table.insert(data, curr)
    --     end
    -- end
    -- handlerData(data)

    local total = #data
    self:SetText(root, "RoomTitle/HeadPanel/title/name", buy .. "/" .. total)
    local progress = self:GetComp(root, "RoomTitle/HeadPanel/title/prog", "Slider")
    progress.value = buy / total


    table.sort(data, function(a, b)
        if a.first ~= b.first then
            return a.first == false
        else
            return a.cfg.id < b.cfg.id
        end
    end)

    self.employeeData = data
    self.employeeList = self:GetComp(root, "RoomPanel/BuidlingList", "ScrollRectEx")
    self:SetListItemCountFunc(self.employeeList, function()
        return #self.employeeData
    end)
    
    self:SetListUpdateFunc(self.employeeList, handler(self,self.RefreshEmployeeItem))
    self.employeeList:UpdateData()
end
function CollectionUIView:RefreshEmployeeItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.employeeData[index].cfg
    --local cfg = ConfigMgr.config_employees[data.id]

    local changeBtn = self:GetComp(go, "Btn/bg/changeBtn", "Button")
    local notHave = self.employeeData[index].first
    changeBtn.gameObject:SetActive(not notHave)
    self:GetGo(go, "Btn/bg/locked"):SetActive(notHave)
    if not notHave then--如果有了...
        local icon = self:GetComp(go, "Btn/bg/icon", "Image")
        if data.id == 1 or data.id == 2 then
            self:SetSprite(icon, "UI_BG", data.icon, nil, true)
        else
            self:SetSprite(icon, "UI_Shop", data.icon, nil, true)
        end
        
        if data.id == 1 then
            self:SetText(go, "Btn/bg/name", data.name)
        else
            self:SetText(go, "Btn/bg/name", GameTextLoader:ReadText(data.name))
        end        
        self:SetText(go, "Btn/bg/desc", GameTextLoader:ReadText(data.desc))

        local allType = {"mood", "income", "offline"}
        local currType = nil
        local currValue = 0
        for k,v in pairs(allType) do
            if data[v] ~= nil then
                currType = v
                currValue = data[v]
                break
            end
        end

        local buffRoot = self:GetGo(go, "Btn/bg/buff")
        for k,v in pairs(allType) do
            self:GetGo(buffRoot, v):SetActive(v == currType)
        end
        if currType then
            local buffGo = self:GetGo(buffRoot, currType)
            if currType == "income" then
                currValue = currValue * 100 .. "%"
            elseif currType == "offline" then
                --currValue = currValue .. "Hrs"
                currValue = currValue
            end
            self:SetText(buffGo, "num", currValue)
        end                
        self:SetButtonClickHandler(changeBtn, function()
            GameTableDefine.PersonInteractUI:OpenPersonInteractUI(data)
            self:GetGo("RootPanel/Tabs/empBtn/icon"):SetActive(false)
            self:Hideing()
        end)        
    end
end

function CollectionUIView:RefreshPet()
    local root = self:GetGo("RootPanel/petPanel")

    local quitBtn = self:GetComp("Bgcover", "Button")
    self:SetButtonClickHandler(quitBtn, function()
        self:DestroyModeUIObject()
    end)

    local cfg = ConfigMgr.config_pets

    local buy = 0

    local data = {}
    local curr = nil
    local first = nil
    for k,v in pairs(cfg or {}) do
        curr = {}
        curr.cfg = v
        first = ShopManager:FirstBuy(v.shopId)
        curr.first = first
        table.insert(data, curr)

        if not first then
            buy = buy + 1
        end
    end

    local total = #data
    self:SetText(root, "RoomTitle/HeadPanel/title/name", buy .. "/" .. total)
    local progress = self:GetComp(root, "RoomTitle/HeadPanel/title/prog", "Slider")
    progress.value = buy / total

    table.sort(data, function(a, b)
        if a.first ~= b.first then
            return a.first == false
        else
            return a.cfg.id < b.cfg.id
        end
    end)

    self.petData = data
    local list = self:GetComp(root, "RoomPanel/BuidlingList", "ScrollRectEx")
    self:SetListItemCountFunc(list, function()
        return #self.petData
    end)

    self:SetListUpdateFunc(list, handler(self,self.RefreshPetItem))
    list:UpdateData()
end
function CollectionUIView:RefreshPetItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    --local data = self.petData[index].cfg
    --local cfg = ConfigMgr.config_pets[data.id]
    local cfg = self.petData[index].cfg
    
    local notHave = ShopManager:FirstBuy(cfg.shopId)
    self:GetGo(go, "Btn/bg/locked"):SetActive(notHave)
    --self:GetGo(go, "Btn/bg/changeBtn"):SetActive(not notHave)
    if not notHave then--如果有了...
        local icon = self:GetComp(go, "Btn/bg/frame/icon", "Image")
        self:SetSprite(icon, "UI_Shop", cfg.icon, nil, true)

        self:SetText(go, "Btn/bg/name", GameTextLoader:ReadText(cfg.name))
        self:SetText(go, "Btn/bg/desc", GameTextLoader:ReadText(cfg.desc))

        local allType = {"mood", "income", "offline"}
        local currType = nil
        local currValue = 0
        for k,v in pairs(allType) do
            if cfg[v] ~= nil then
                currType = v
                currValue = cfg[v]
                break
            end
        end

        local buffRoot = self:GetGo(go, "Btn/bg/buff")
        for k,v in pairs(allType) do
            self:GetGo(buffRoot, v):SetActive(v == currType)
        end

        local buffGo = self:GetGo(buffRoot, currType)

        if currType == "income" then
            currValue = currValue * 100 .. "%"
        elseif currType == "offline" then
            --currValue = currValue .. "Hrs"
            currValue = currValue
        end

        self:SetText(buffGo, "num", currValue)
    end
end

function CollectionUIView:CloseIAP()
    --self:GetGo("RootPanel/Tabs/empBtn"):SetActive(false)
    --self:GetGo("RootPanel/Tabs/petBtn"):SetActive(false)
end

--隐藏UI,reverse 反转效果
function CollectionUIView:Hideing(reverse)
    local CanasGroup = self:GetComp("","CanvasGroup")
    if not reverse then           
        CanasGroup.alpha = 0
        CanasGroup.interactable = false
    else
        CanasGroup.alpha = 1
        CanasGroup.interactable = true
    end
end

--刷新员工页的红点
function CollectionUIView:EmployeeHint()
    self:GetGo("RootPanel/Tabs/empBtn/icon"):SetActive(GameTableDefine.DressUpDataManager:CheckNewDressNotViewed())
end

return CollectionUIView