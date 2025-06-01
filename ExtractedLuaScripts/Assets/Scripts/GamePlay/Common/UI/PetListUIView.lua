local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local PetMode = GameTableDefine.PetMode
local ShopUI = GameTableDefine.ShopUI
local MainUI = GameTableDefine.MainUI
local ShopManager = GameTableDefine.ShopManager
local PetListUI = GameTableDefine.PetListUI
local GameUIManager = GameTableDefine.GameUIManager
local PetInteractUI = GameTableDefine.PetInteractUI
local TimerMgr = GameTimeManager
local GameObject = CS.UnityEngine.GameObject
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

---@class PetListUIView:UIBaseView
local PetListUIView = Class("PetListUIView", UIView)

function PetListUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self:ctorCEO()
end

function PetListUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/panel/TitlePanel/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/panel/PetPanel/RewardPanel/shopBtn","Button"), function()
        ShopUI:TurnTo(1066)
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/panel/empPanel/RewardPanel/shopBtn","Button"), function()
        ShopUI:TurnTo(1053)
    end)

    self:OnEnterCEO()
    GameSDKs:TrackForeign("ceo_list", {source = "主界面入口"})
    --self:GetGo("RootPanel/panel/PetPanel/PetList/empty"):SetActive(Tools:GetTableSize(PetListUI:GetPets()) == 0)
    self:EmployeeHint()
    self:PetListHint()
    self:CEOHint()
    self:Init()
        
    self:CreateTimer(1000, function()
        self:Refresh()
    end, true, true)
end

--数据初始化
function PetListUIView:Init()
    self.cfgPet = ConfigMgr.config_pets
    self.pets = PetListUI:GetPets()
    self.cfgGlobal = ConfigMgr.config_global
    self.petfeed = LocalDataManager:GetDataByKey("pet_feed")
    self.petFeedBtn = self:GetComp("RootPanel/panel/PetPanel/RewardPanel/freeBtn","Button")
    if not self.petfeed["time_point"] then
        self.petfeed["time_point"] = TimerMgr:GetCurrentServerTime(true)            
        LocalDataManager:WriteToFile()    
    end
    self:RefreshFeed()
    self:RefreshList()

    local ceoUnlocked = GameTableDefine.CEODataManager:GetGuideTriggered()
    if ceoUnlocked then
        self:InitCEO()
    else
        local ceoBtn = self:GetGo("RootPanel/panel/TitlePanel/ceoBtn")
        ceoBtn:SetActive(false)
        GameTimer:CreateNewMilliSecTimer(1,function()
            local petBtn = self:GetComp("RootPanel/panel/TitlePanel/petBtn","Button")
            petBtn.onClick:Invoke()
        end)
    end
end

--刷新
function PetListUIView:Refresh()
    self:SetPetFeedBtn()   
    --self.m_list:UpdateData()
    --self:RefreshList()     
end

--设置领取宠物零食按钮
function PetListUIView:SetPetFeedBtn()    
    --self:SetText("RootPanel/panel/RewardPanel/freeBtn/text", "领取")
    local value = self.petfeed["time_point"] - TimerMgr:GetCurrentServerTime(true)
    local isReady = value <= 0
    self.petFeedBtn.interactable = (isReady)
    --self:GetGo(self.petFeedBtn.gameObject, "icon"):SetActive(isReady)
    self:GetGo(self.petFeedBtn.gameObject, "text"):SetActive(isReady)
    self:GetGo(self.petFeedBtn.gameObject, "time"):SetActive(not isReady)
    self:SetText(self.petFeedBtn.gameObject, "time", TimerMgr:FormatTimeLength(value))
    self:SetButtonClickHandler(self.petFeedBtn, function()
        local type = self.cfgGlobal.free_petsnack[1]
        local num = self.cfgGlobal.free_petsnack[2]                 
        PetListUI:PetFeed(type, num, function ()
            self.petfeed["time_point"] = TimerMgr:GetCurrentServerTime(true) + self.cfgGlobal.free_petsnack[3]
            self:Refresh()        
        end)
    end)
end
--刷新零食数量
function PetListUIView:RefreshFeed()  
    -- for i=1,3 do
    --     local path = "RootPanel/panel/SnackPanel/bg/" .. i
    --     local feedId = "100" .. i
    --     local feed = self:GetGo(path)
    --     if not self.petfeed[feedId] then
    --         self.petfeed[feedId] = 0
    --     end
    --     --feed:SetActive(self.petfeed[feedId] > 0)
    --     self:SetText(feed, "num", self.petfeed[feedId])
    -- end
    local prototype = self:GetGo("RootPanel/panel/PetPanel/SnackPanel/bg/1")
    prototype:SetActive(false)
    local parent = self:GetGo("RootPanel/panel/PetPanel/SnackPanel/bg")
    local num = Tools:GetTableSize(ConfigMgr.config_snack)
    for i=1,num do
        local Go 
        if self:GetGoOrNil(parent, "feed" .. i ) then
            Go = self:GetGo(parent, "feed" .. i )
        else
            Go = GameObject.Instantiate(prototype, parent.transform)
        end        
        local feedId = 1000 + i
        local petFeedCount = PetMode:GetPetFeed(tostring(feedId))
        self:SetText(Go, "num", petFeedCount)
        --self:SetText(Go, "num", self.petfeed[tostring(feedId)] or 0)
        local image = self:GetComp(Go, "icon", "Image")
        self:SetSprite(image, "UI_Shop", ConfigMgr.config_snack[feedId].icon, nil, true)
        Go:SetActive(true)
        Go.name = "feed" .. i 
    end    
end
--刷新list
function PetListUIView:RefreshList()

    self.m_data = {}
    local data = PetMode:GetPetsdata()
    for k,v in pairs(data or {}) do
        if PetMode:IsPetData(v) then
            local cfg = PetMode:GetPetCfgByPetId(k)
            table.insert(self.m_data, {id = k, cfg = cfg})
        end
    end
    table.sort(self.m_data, function(a, b)
        return tonumber(a.id) < tonumber(b.id)
    end)
    self.m_list = self:GetComp("RootPanel/panel/PetPanel/PetList", "ScrollRectEx")    

    self:SetListItemCountFunc(self.m_list, function()        
        return Tools:GetTableSize(PetListUI:GetPets())
    end)
     self:SetListItemNameFunc(self.m_list, function(index)       
        return "Item"
    end)    
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateList))
    
    self.m_list:UpdateData()
    --self:GetGo("RootPanel/panel/PetPanel/PetList/empty"):SetActive(Tools:GetTableSize(PetListUI:GetPets()) == 0)
end
--Item的设置
function PetListUIView:UpdateList(index, tran)
    index = index + 1
    local go = tran.gameObject
    -- local cfg  = self.m_data[index] PetMode:GetPetCfgByPetId(PetListUI:GetPets()[index])   
    -- local petData = PetListUI:GetPetsdata()[tostring(cfg.shopId)]    
    local data = self.m_data[index]
    local petData = PetMode:GetPetLocalData(data.id)
    local cfg = data.cfg
    local icon = self:GetComp(go,"bg/frame/avatar/icon", "Image")
    local hungrySlider = self:GetComp(go,"bg/frame/data/bg/hunger/info/progress", "Slider")
    local experienceSlider = self:GetComp(go, "bg/frame/data/bg/exp/info/progress", "Slider")    

    ---------------------------------------------------------------- 
    self:SetSprite(icon, "UI_Shop", cfg.icon, nil, true) 
    local isLevelMax = petData.level >= #cfg.exp_limit + 1 
    self:GetGo(go, "bg/frame/data/bg"):SetActive(not isLevelMax)
    self:GetGo(go, "bg/frame/max"):SetActive(isLevelMax)
    self:GetGo(go, "bg/interactBtn/icon"):SetActive(not isLevelMax)
    if isLevelMax then
        self:SetText(go, "bg/frame/data/bg/exp/lvl/num", "MAX")
        
    else
        self:SetText(go, "bg/frame/data/bg/exp/lvl/num", "Lv" .. petData.level)
        
        local fillImage = self:GetComp(go, "bg/frame/data/bg/exp/info/progress/Fill Area/Fill", "Image")
        local pitchImage = self:GetComp(go, "bg/frame/data/bg/exp/info/progress/Fill Area/Fill/pitch", "Image")     
        if petData.hungry > 0 then
            fillImage.color  = UnityHelper.GetColor("#67BF94")
            pitchImage.color  = UnityHelper.GetColor("#87DFB4")
        else
            fillImage.color  = UnityHelper.GetColor("#A3A8A6")
            pitchImage.color  = UnityHelper.GetColor("#BCBFBE")
        end   
        self:CreateTimerByGo(1000, function()
            if not go then

            else
                local isNoExp = false
                if not cfg.exp_limit[petData.level] then
                    isNoExp = true
                end
                hungrySlider.value = petData.hungry / cfg.max_hungry
                if isNoExp then
                    experienceSlider.value = 1
                else
                    experienceSlider.value = petData.experience / cfg.exp_limit[petData.level]
                end
                self:SetText(go, "bg/frame/data/bg/hunger/info/progress/pro", math.floor(petData.hungry / cfg.max_hungry * 10000)/100 .. "%")
                if not isNoExp then
                    self:SetText(go, "bg/frame/data/bg/exp/info/progress/pro", math.floor(petData.experience) .. "/" .. math.floor(cfg.exp_limit[petData.level]))
                end
                local dispHungry = petData.hungry
                if dispHungry > cfg.max_hungry then
                    dispHungry = cfg.max_hungry
                end
                self:SetText(go, "bg/frame/data/bg/hunger/info/time", dispHungry .. "/" .. cfg.max_hungry)
                if petData.hungry == 0 then
                    self:SetText(go, "bg/frame/data/bg/exp/num","+0/s")
                else
                    self:SetText(go, "bg/frame/data/bg/exp/num","+" .. PetInteractUI:ExpSpeed(cfg.shopId) .. "/s")
                end

                local expBuffRemain = PetInteractUI:GetExpBuffRemain(cfg.shopId)
                local showBuffInfo = expBuffRemain and expBuffRemain > 0
                if showBuffInfo then
                    self:SetText(go, "bg/frame/data/bg/exp/EXPvalue/num_basedata", "+" .. string.format("%.1f", ConfigMgr.config_global.pet_exp_basespeed) .. "/s")
                    self:SetText(go, "bg/frame/data/bg/exp/EXPvalue/num_adddata", "+" .. string.format("%.1f", PetInteractUI:ExpSpeed(cfg.shopId) - ConfigMgr.config_global.pet_exp_basespeed) .. "/s")
                    self:SetText(go, "bg/frame/data/bg/exp/EXPvalue/num_remainder", "(" .. GameTimeManager:FormatTimeLength(expBuffRemain) .. ")")
                end
                self:GetGo(go, "bg/frame/data/bg/exp/EXPvalue/num_basedata"):SetActive(showBuffInfo)
                self:GetGo(go, "bg/frame/data/bg/exp/EXPvalue/num_adddata"):SetActive(showBuffInfo)
                self:GetGo(go, "bg/frame/data/bg/exp/EXPvalue/num_remainder"):SetActive(showBuffInfo)
            end
        end, true, true, go)     
        self:GetGo(go,"bg/interactBtn/icon"):SetActive(PetInteractUI:DetectOnePet(cfg.shopId))
        local image = self:GetComp(go, "bg/frame/data/bg/exp/info/image", "Image")
        if cfg.exp_limit[petData.level] and petData.experience >= cfg.exp_limit[petData.level] then
            self:SetSprite(image, "UI_Common", "icon_pet_exp_max", nil, true) 
        else
            if petData.hungry == 0 then
                self:SetSprite(image, "UI_Common", "icon_pet_exp_off", nil, true) 
            else
                self:SetSprite(image, "UI_Common", "icon_pet_exp_on", nil, true)                
            end
        end
    end

    ---------------------------------------------------------------- 
    self:SetText(go, "bg/property/desc", GameTextLoader:ReadText(cfg.desc))
    self:SetText(go, "bg/property/name", petData.name or GameTextLoader:ReadText(cfg.name)) -- petData.name   
    local isIncome = cfg.income ~= nil
    local isOffline = cfg.offline ~= nil
    local isMood =  cfg.mood ~= nil 
    self:GetGo(go ,"bg/property/buff/income"):SetActive(isIncome)    
    self:GetGo(go ,"bg/property/buff/offline"):SetActive(isOffline)    
    self:GetGo(go ,"bg/property/buff/mood"):SetActive(isMood)      
    if isIncome then
        self:SetText(go, "bg/property/buff/income/num",  cfg.bonus_effect[petData.level] * 100 .. "%" )    
    elseif isOffline then
        self:SetText(go, "bg/property/buff/offline/num",  cfg.bonus_effect[petData.level])  
    elseif isMood then
        self:SetText(go, "bg/property/buff/mood/num",  cfg.bonus_effect[petData.level])         
    end
    ----------------------------------------------------------------             
    self:SetButtonClickHandler(self:GetComp(go ,"bg/interactBtn", "Button"), function()               
        local path = "Assets/Res/UI/PetFeedUI.prefab"
        GameResMgr:AInstantiateObjectAsyncManual(path, self, function(this)
            local OverlayCamera = self:GetComp(this, "Overlay Camera", "Camera")            
            self:SetCameraToMainCamera(OverlayCamera)
            PetInteractUI:OpenUI(cfg, this)
            MainUI:Hideing()
            self:Hideing()            
        end)            
    end)
end

--设置相机的渲染将小场景的相机加在主相机上
function PetListUIView:SetCameraToMainCamera(OverlayCamera)
    local mainCamera = GameUIManager:GetSceneCamera()
    UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
end

function PetListUIView:OnExit()
    self:OnExitCEO()
    for k,v in pairs(self.goTimerList or {}) do
        GameTimer:StopTimer(v)
    end
	self.super:OnExit(self)
    self.cfgPet = nil
    self.pets = nil
    self.cfgGlobal = nil
end

--隐藏
function PetListUIView:Hideing(reverse)
    local CanasGroup = self:GetComp("RootPanel","CanvasGroup")
    if not reverse then           
        CanasGroup.alpha = 0
        --CanasGroup.interactable = false
        CanasGroup.blocksRaycasts = false
    else
        CanasGroup.alpha = 1
        --CanasGroup.interactable = true
        CanasGroup.blocksRaycasts = true
    end
    self:EmployeeHint()
    self:PetListHint()
    self:CEOHint()
end 

--创建一种以为gameObject为Key的循环时间  
function PetListUIView:CreateTimerByGo(intervalInMilliSec, func, isLoop, execImmediately, gameObject)
    if not self.goTimerList then
        self.goTimerList = {}
    end
    if self.goTimerList[gameObject] then
        GameTimer:StopTimer(self.goTimerList[gameObject])
    end
    if isLoop then    
        self.goTimerList[gameObject] = GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, isLoop, execImmediately)
    else
        GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, false, execImmediately)
    end    
end

---------把员工显示的相关逻辑挪到这个界面的代码添加2023-2-9
function PetListUIView:RefreshEmployee()
    local root = self:GetGo("RootPanel/panel/empPanel")
    local cfg = GameTableDefine.PersonInteractUI:GetPersonData()

    local buy = 0
    local data = {}
    local curr = nil
    local first = nil
    for k, v in pairs(cfg or {}) do
        curr = {}
        curr.cfg = v
        if v.shopId then
            first = ShopManager:FirstBuy(v.shopId)
        else
            first = false
        end
        curr.first = first
        table.insert(data, curr)
        if not first then
            buy = buy + 1
        end
    end

    local total = Tools:GetTableSize(data)
    -- self:SetText(root, "RoomTitle/HeadPanel/title/name", buy.."/"..total)
    -- local progress = self:GetComp(root, "RoomTitle/HeadPanel/title/prog", "Slider")
    -- progress.value = buy/total
    table.sort(data, function(a, b)
        if a.first ~= b.first then
            return a.first == false
        else
            return a.cfg.id < b.cfg.id
        end
    end)
    self.employeeData = data
    self.employeeList = self:GetComp("RootPanel/panel/empPanel/RoomPanel/BuidlingList", "ScrollRectEx")
    self:SetListItemCountFunc(self.employeeList, function()
        return #self.employeeData
    end)
    self:SetListUpdateFunc(self.employeeList, handler(self, self.RefreshEmployeeItem))
    self.employeeList:UpdateData()
end

function PetListUIView:RefreshEmployeeItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.employeeData[index].cfg
    local changeBtn = self:GetComp(go, "Btn/bg/changeBtn", "Button")
    changeBtn.interactable = true
    local notHave = self.employeeData[index].first
    changeBtn.gameObject:SetActive(not notHave)
    self:GetGo(go, "Btn/bg/locked"):SetActive(notHave)
    if not notHave then
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
        for k, v in pairs(allType) do
            if data[v] ~= nil then
                currType = v
                currValue = data[v]
                break
            end
        end
        local buffRoot = self:GetGo(go, "Btn/bg/buff")
        for k, v in pairs(allType) do
            self:GetGo(buffRoot, v):SetActive(v == currType)
        end
        if currType then
            local buffGo = self:GetGo(buffRoot, currType)
            if currType == "income" then
                currValue = currValue * 100 .."%"
            elseif currType == "offline" then
                currValue = currValue
            end
            self:SetText(buffGo, "num", currValue)
        end
    --     local roomPath = "Assets/Res/UI/PersonDecorationUI.prefab"    
    -- GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(this)
    --     local OverlayCamera = self:GetComp(this, "Overlay Camera", "Camera")            
    --     self:SetCameraToMainCamera(OverlayCamera)        
    --     self.roomGo  = this
    --     self.variable = PersonInteractUI:GetPersonDataById(cfg.id)
    --     self:Refresh()
    -- end)
        self:SetButtonClickHandler(changeBtn, function()
            changeBtn.interactable = false
            local roomPath = "Assets/Res/UI/PersonDecorationUI.prefab" 
            GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(this)
                local OverlayCamera = self:GetComp(this, "Overlay Camera", "Camera")            
                self:SetCameraToMainCamera(OverlayCamera)
                GameTableDefine.PersonInteractUI:OpenPersonInteractUI(data, this)
                self:GetGo("RootPanel/panel/TitlePanel/empBtn/icon"):SetActive(false)
                self:Hideing()
                changeBtn.interactable = true
            end)
        end)
    end
end

function PetListUIView:EmployeeHint()
    self:GetGo("RootPanel/panel/TitlePanel/empBtn/icon"):SetActive(GameTableDefine.DressUpDataManager:CheckNewDressNotViewed())
end

function PetListUIView:PetListHint()
    self:GetGo("RootPanel/panel/TitlePanel/petBtn/icon"):SetActive(PetInteractUI:DetectStarvationOrUpgrade())
end

return PetListUIView