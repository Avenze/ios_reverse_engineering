local Class = require("Framework.Lua.Class")

local UIBaseView = require("Framework.UI.View")

local GameResMgr = require("GameUtils.GameResManager")
local GameObject = CS.UnityEngine.GameObject
local LocalDataManager = LocalDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local HouseMode = GameTableDefine.HouseMode
local CashEarn = GameTableDefine.CashEarn
local CountryMode = GameTableDefine.CountryMode
local FloorMode = GameTableDefine.FloorMode
local FlyIconsUI = GameTableDefine.FlyIconsUI
local UnityHelper = CS.Common.Utils.UnityHelper
local ActorManager = GameTableDefine.ActorManager
local Vector3 = CS.UnityEngine.Vector3
local BuyCarManager = GameTableDefine.BuyCarManager
---@class StatisticUIView:UIBaseView
---@field super UIBaseView
local StatisticUIView = Class("StatisticUIView", UIBaseView)

function StatisticUIView:ctor()
end

function StatisticUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/top/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/bg", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function StatisticUIView:OnExit(view)
    self.super:OnExit(self)
    if self.statisticSceneModel then
        GameObject.Destroy(self.statisticSceneModel)
        self.statisticSceneModel = nil
    end
end

function StatisticUIView:OpenSelfStatistic()
    
    --step.1显示玩家的基本信息
    --boss头像，名字，知名度，当前地区的挣钱效率，区域进度
    local headIcon = "head_" .. LocalDataManager:GetBossSkin()
    local bossName = LocalDataManager:GetBossName() or ""
    local curStar = StarMode:GetStar()
    local text = GameTextLoader:ReadText("TXT_MISC_INCOME_RATE")
    -- local num = GameTableDefine.FloorMode:GetTotalRent()
    --                 if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
    --                     num = GameTableDefine.FloorMode:GetTotalRent(nil, 2)
    --                 end
    local countryID = CountryMode:GetCurrCountry()
    local makeMoneyEff = tostring((FloorMode:GetTotalRent(nil, countryID)) * 2).."/m" --根据地区来进行显示的
    local curBuildingID = CountryMode:GetMaxDevelopCountryBuildingID() --包含当前地区问题了
    local curBuildingName = GameTextLoader:ReadText("TXT_BUILDING_B"..curBuildingID.."_NAME")
    local houseID = math.ceil(tonumber(curBuildingID) / 100)
    self:SetSprite(self:GetComp("RootPanel/medium/businessCard/title/head/icon", "Image"), "UI_BG", headIcon)
    self:GetComp("RootPanel/medium/businessCard/title/name/txt","TMPLocalization").text = bossName
    self:GetComp("RootPanel/medium/businessCard/title/reputation/info/num", "TMPLocalization").text = curStar
    self:GetComp("RootPanel/medium/businessCard/title/income/info/num", "TMPLocalization").text = makeMoneyEff
    self:GetComp("RootPanel/medium/businessCard/title/area/info/txt", "TMPLocalization").text = curBuildingName
    self:SetText("RootPanel/medium/businessCard/title/area/info/num", tostring(houseID).."-")
    self:SetButtonClickHandler(self:GetComp("RootPanel/medium/businessCard/title/name", "Button"), function()
        self:OpenRenameUI()
    end)

    --TODO:暂时需要隐藏功能的按钮
    self:GetGo("RootPanel/medium/businessCard/btn_area/btn_house"):SetActive(false)
    self:GetGo("RootPanel/medium/businessCard/btn_area/btn_car"):SetActive(false)
    local btnEquipment = self:GetComp("RootPanel/medium/businessCard/btn_area/btn_equipment", "Button")
    self:SetButtonClickHandler(btnEquipment, function()
        btnEquipment.interactable = false
        local roomPath = "Assets/Res/UI/PersonDecorationUI.prefab" 
        GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(this)
            local OverlayCamera = self:GetComp(this, "Overlay Camera", "Camera")            
            self:SetCameraToMainCamera(OverlayCamera)
            local cfg = GameTableDefine.PersonInteractUI:GetPersonData()

            local buy = 0
            local data = {}
            local curr = nil
            local first = nil
            for k, v in pairs(cfg or {}) do
                curr = {}
                curr.cfg = v
                if v.shopId then
                    first = GameTableDefine.ShopManager:FirstBuy(v.shopId)
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
            GameTableDefine.PersonInteractUI:OpenPersonInteractUI(data[1].cfg, this, ENUM_GAME_UITYPE.STATISTIC_UI)
            -- self:GetGo("RootPanel/panel/TitlePanel/empBtn/icon"):SetActive(false)
            btnEquipment.interactable = true
            self:DestroyModeUIObject()
        end)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/medium/businessCard/btn_area/btn_pet", "Button"), function()
        GameTableDefine.PetListUI:GetView()
        GameTableDefine.PetListUI:RefreshEmployee()
        self:DestroyModeUIObject()
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/bottom/Btn_story", "Button"), function()
        GameTableDefine.StoryLineUI:ShowStoryLineUI()
    end)
    self:LoadStatisticModelScene(true)
end

function StatisticUIView:OpenOtherPlayerStatistic(bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName)
    --step1隐藏需要隐藏的节点
    self:GetGo("RootPanel/top"):SetActive(false)
    self:GetGo("RootPanel/bottom"):SetActive(false)
    self:GetGo("RootPanel/medium/businessCard/btn_area"):SetActive(false)
    self:GetGo("RootPanel/medium/businessCard/title/name"):SetActive(false)

    local headIcon = "head_" .. bossSkin
    local bossName = playerName
    local curStar = start
    local text = GameTextLoader:ReadText("TXT_MISC_INCOME_RATE")
    -- local num = GameTableDefine.FloorMode:GetTotalRent()
    --                 if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
    --                     num = GameTableDefine.FloorMode:GetTotalRent(nil, 2)
    --                 end
    local contryID = contry_id 
    local makeMoneyEff = tostring(curMoneyEff * 2).."/m" --根据地区来进行显示的
    local curBuildingID = sceneID --包含当前地区问题了
    local curBuildingName = GameTextLoader:ReadText("TXT_BUILDING_B"..curBuildingID.."_NAME")
    local houseID = math.ceil(tonumber(curBuildingID) / 100)
    self:SetSprite(self:GetComp("RootPanel/medium/businessCard/title/head/icon", "Image"), "UI_BG", headIcon)
    self:GetComp("RootPanel/medium/businessCard/title/name/txt","TMPLocalization").text = bossName
    self:GetComp("RootPanel/medium/businessCard/title/reputation/info/num", "TMPLocalization").text = curStar
    self:GetComp("RootPanel/medium/businessCard/title/income/info/num", "TMPLocalization").text = makeMoneyEff
    self:GetComp("RootPanel/medium/businessCard/title/area/info/txt", "TMPLocalization").text = curBuildingName
    self:SetText("RootPanel/medium/businessCard/title/area/info/num", tostring(houseID).."-")

    self:LoadStatisticModelScene(false)
end
 
function StatisticUIView:LoadStatisticModelScene(isPlayer)
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/StatisticScene.prefab",self,function(go)
        self.statisticSceneModel = go
        if not self.newBossGo and isPlayer then
            self:LoadSelfModel()
        elseif not self.newBossGo and not isPlayer then
            --TODO:暂时采用当前玩家的，等后续装扮功能完成后再封装
            self:LoadSelfModel()
        end
    end)
end

function StatisticUIView:LoadOtherModel()
    if self.statisticSceneModel then

    end
end

function StatisticUIView:LoadSelfModel()
    if self.statisticSceneModel then
        --step1.根据玩家的当前外观加载玩家的显示
        local curBoss = ActorManager:GetFloorBossEntity() 
        local charNodeGo = self.statisticSceneModel.transform:Find("object_mainCharacter")
        local expCharGo = charNodeGo:Find("Boss_001")
        self.newBossGo = GameObject.Instantiate(curBoss.gameObject, charNodeGo)
        self.newBossGo.name = "BossChar"
        self.newBossGo.transform.position = expCharGo.position
        self.newBossGo.transform.eulerAngles = expCharGo.eulerAngles
        self.newBossGo.transform.localScale = expCharGo.localScale
        expCharGo.gameObject:SetActive(false)
        self.newBossGo:SetActive(true)
        --step2.检测房子的显示,现在是在环境预制中放了5个房产，根据当前解锁房子的数量来对应进行显示的，后期会根据需求修改
        local houseNodeGo = self.statisticSceneModel.transform:Find("object_house")
        local hData = LocalDataManager:GetDataByKey("houses")
        if hData and hData.d then
            local houseNum = Tools:GetTableSize(hData.d)
            if houseNum >= 5 then
                houseNum = 5
            end
            if houseNum > 0 then
                local curHouseSel = houseNodeGo:Find("House_"..houseNum)
                curHouseSel.gameObject:SetActive(true)
            end
        end
        --step3.当前车的相关内容
        local curCarID = BuyCarManager:GetDrivingCar()
        local object_carGo = self.statisticSceneModel.transform:Find("object_car")
        if curCarID and curCarID > 0 and object_carGo then
            local bossCar = GameObject.Find("BossCar")
            local expCarGo = object_carGo:Find("BossCar_001")
            if bossCar then
                self.curBossCar = GameObject.Instantiate(bossCar, object_carGo)
                self.curBossCar.name = "CurBossCar"
                self.curBossCar.transform.position = expCarGo.position
                self.curBossCar.transform.eulerAngles = expCarGo.eulerAngles
                self.curBossCar.transform.localScale = expCarGo.localScale
                expCarGo.gameObject:SetActive(false)
                self.curBossCar:SetActive(true)
            end
        else
            local expCarGo = object_carGo:Find("BossCar_001")
            expCarGo.gameObject:SetActive(false)
        end

        --step3.宠物相关
        --     local parent = self:GetGo(self.this, "PetPos") 
        -- for k,v in pairs(parent.transform) do
        --     GameObject.Destroy(v.gameObject)
        -- end
        -- local string = cfg.prefab .. "_show"
        -- local petPath = "Assets/Res/Prefabs/Animals/".. string ..".prefab"
        -- GameResMgr:AInstantiateObjectAsyncManual(petPath, self, function(this)
        --     UnityHelper.AddChildToParent(parent.transform, this.transform)
        --     this.transform.localScale  = this.transform.localScale * cfg.show
        --     self.petMod = this
        --     -- this.transform.parent = parent.transform
        --     -- this.transform.position = parent.transform.position
        --     -- this.transform.rotation = parent.transform.rotation
        --     -- local A = this.transform.localScale.oneVector 
        --     -- this.transform.localScale  =   A * cfg.scale        
        -- end)
        local object_petGo = self.statisticSceneModel.transform:Find("object_pet")
        local expPetGo = object_petGo:Find("DogGhost2_show")
        local petCfg = nil
        local curPets = GameTableDefine.PetListUI:GetPets()
        local isHavePet = false
        if Tools:GetTableSize(curPets) > 0 then
            local randomIndex = math.random(1, Tools:GetTableSize(curPets))
            local getPetShopID = curPets[randomIndex]
            local shopCfg = ConfigMgr.config_shop[tonumber(getPetShopID)]
            if shopCfg and shopCfg.param[1] and tonumber(shopCfg.param[1]) > 0 then
                local petCfg = ConfigMgr.config_pets[tonumber(shopCfg.param[1])]
                if petCfg then
                    local petPrefabStr = petCfg.prefab .. "_show"
                    local petPath = "Assets/Res/Prefabs/Animals/".. petPrefabStr ..".prefab"
                    GameResMgr:AInstantiateObjectAsyncManual(petPath, self, function(go)
                        self.curPetGo = go
                        self.curPetGo.name = "CurPet"
                        UnityHelper.AddChildToParent(object_petGo, self.curPetGo.transform)
                        self.curPetGo.transform.localScale  = expPetGo.localScale
                        self.curPetGo.transform.position = expPetGo.position
                        self.curPetGo.transform.eulerAngles = expPetGo.eulerAngles
                        expPetGo.gameObject:SetActive(false)
                        self.curPetGo:SetActive(true)
                        isHavePet = true       
                    end)
                end
            end
        end
        if not isHavePet then
            expPetGo.gameObject:SetActive(false)
        end
    end
end

function StatisticUIView:OpenRenameUI()
    GameTableDefine.BenameUI:ReBossName(function()
        self:SetText("RootPanel/medium/businessCard/title/name/txt", LocalDataManager:GetBossName())
    end)
end

function StatisticUIView:SetCameraToMainCamera(OverlayCamera)
    local mainCamera = GameTableDefine.GameUIManager:GetSceneCamera()
    UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
end

return StatisticUIView