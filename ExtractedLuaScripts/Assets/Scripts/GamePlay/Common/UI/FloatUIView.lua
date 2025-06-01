
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local CompanyEmployee = require "GamePlay.Floors.Actors.CompanyEmployee"
local Bus = require "CodeRefactoring.Actor.Actors.BusNew"
local ActivityUI = GameTableDefine.ActivityUI

local UnityHelper = CS.Common.Utils.UnityHelper
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local Button = CS.UnityEngine.UI.Button
local AnimationUtil = CS.Common.Utils.AnimationUtil
local EventTriggerListener = CS.Common.Utils.EventTriggerListener


local GuideUI = GameTableDefine.GuideUI
local FactoryMode = GameTableDefine.FactoryMode
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local CityMode = GameTableDefine.CityMode
local ResMgr = GameTableDefine.ResourceManger
local TimerMgr = GameTimeManager
local RoomUnlockUI = GameTableDefine.RoomUnlockUI
local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI
local Event001UI = GameTableDefine.Event001UI
local Event003UI = GameTableDefine.Event003UI
local Event004UI = GameTableDefine.Event004UI
local Event005UI = GameTableDefine.Event005UI
local Event006UI = GameTableDefine.Event006UI
local Event101UI = GameTableDefine.InstanceAdUI
local SceneChatInfoUI = GameTableDefine.SceneChatInfoUI
local CompanysUI = GameTableDefine.CompanysUI
local SoundEngine = GameTableDefine.SoundEngine
local CompanyLvUpUI = GameTableDefine.CompanyLvUpUI
local GuideManager = GameTableDefine.GuideManager
local StarMode = GameTableDefine.StarMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local BuyCarManager = GameTableDefine.BuyCarManager
local chooseUI = GameTableDefine.ChooseUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local FootballClubController = GameTableDefine.FootballClubController
local FootballClubModel = GameTableDefine.FootballClubModel
local FCStadiumUI = GameTableDefine.FCStadiumUI
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FloatUIView = Class("FloatUIView", UIView)

local unlock3dButton = "unlock3dButton"
local cashTip = "cashTip"
local LeakageUI = "LeakageUI"
local poweroffUI = "PoweroffUI"
local offDut = "offDut"
local officeEmpty = "officeEmpty"
local companyLevelUp = "companyLevelUp"

function FloatUIView:ctor()
    self.super:ctor()
    self.m_allGameObjects = {}
    self.m_temp3dObject = {}
    self.m_parms = {}
end

function FloatUIView:OnEnter()
    for k, transform in pairs(self.m_uiObj.transform or {}) do
        self.m_allGameObjects[transform.name] = transform.gameObject
    end
    self:Init()
end

function FloatUIView:OnPause()
    --print("FloatUIView:OnPause")
end

function FloatUIView:OnResume()
    --print("FloatUIView:OnResume")
end

function FloatUIView:OnExit()
    self.super:OnExit(self)
    --print("Exit FloatUIView")
end

function FloatUIView:SetEntity(go, hander)
    if not self.m_uiObj or self.m_uiObj:IsNull() then
        return
    end
    self.m_entityGo = go
    self.m_hander = hander
    self:Show()
    self.m_locationTrans = self:GetTrans(go, "UIPosition")
    GameUIManager:UpdateFloatUIEntity(self, self.m_locationTrans)
end

function FloatUIView:CheckViewFree()
    if self.m_uiObj and not self.m_uiObj:IsNull() then
       return not self.m_uiObj.activeSelf
    end
    return false
end

function FloatUIView:Hide()
    if self.m_uiObj and not self.m_uiObj:IsNull() then
        self.m_uiObj:SetActive(false)
    end
end

function FloatUIView:NotHide()
    if self.m_uiObj and not self.m_uiObj:IsNull() then
        self.m_uiObj:SetActive(true)
    end
end

function FloatUIView:Show()
    local buildingActiveInHierarchy = true
    if self.m_entityGo then
        buildingActiveInHierarchy = self.m_entityGo.activeInHierarchy
    end
    if self.m_uiObj and not self.m_uiObj:IsNull() then
        self.m_uiObj:SetActive(true and buildingActiveInHierarchy)
    end
end

function FloatUIView:Init(isOutOfScreen)
    self:StopTimer()
    self:HideAllGo(true, isOutOfScreen)
    self.m_darkRoomId = nil
    self.m_entityGo = nil
    self.m_hander = nil
    self.m_locationTrans = nil
    if self.m_parms.enableGo then
        for k,n in pairs(self.m_parms.enableGo or {}) do
            if not k:IsNull() then k:SetActive(false) end
        end
        self.m_parms.enableGo = nil
    end
    self.m_parms = {}
    GameUIManager:UpdateFloatUIEntity(self, nil)
--  self:ClearAllAnimationHander()
end

function FloatUIView:HideAllGo(hideRoot, isOutOfScreen)
    for k, go in pairs(self.m_allGameObjects or {}) do
        if type(go) ~= "number" and not go:IsNull() and go.activeSelf then
            go:SetActive(false)
        end
    end
    for k, go in pairs(self.m_temp3dObject or {}) do
        if type(go) ~= "number" and not go:IsNull() and go.activeSelf then
            go:SetActive(false)
        end
    end
    if self.m_darkRoomId then
        local scene = FloorMode:GetScene()
        scene:SetRoom3dHintVisible(self.m_darkRoomId, scene.FLAG_DARK_BROKEN, false)
    end
    self.m_temp3dObject = {}
    if hideRoot then self:Hide() end
end

function FloatUIView:ShowBuilingBumble(state, info, icon, buildingGo, buildingId)
    local go = self:GetGo("BuildingBumble")
    local countDownGo = self.m_allGameObjects["BuidlingUnlockingUI"]
    self:StopTimer()
    if state ~= -1 then
        if state < TimerMgr:GetCurrentServerTime(true) then
            countDownGo:SetActive(false)
            go:SetActive(true)
            self:GetGo(go, "new"):SetActive(false)
            self:GetGo(go, "finished"):SetActive(true)
            self:GetGo(buildingGo, "VFX_unlocking"):SetActive(false)
            self:SetText("BuildingBumble/finished/name", info)
            self:SetImageSprite("BuildingBumble/finished/building", "icon_building_" ..math.ceil((buildingId or 0) / 100))
            return
        end

        self:GetGo(buildingGo, "VFX_unlocking"):SetActive(true)
        go:SetActive(false)
        countDownGo:SetActive(true)
        self:SetButtonClickHandler(self:GetComp("BuidlingUnlockingUI/SkipBtn", "Button"), function()
            UnlockingSkipUI:ShowBuildingSkipUI(icon, state)
        end)
        self.endPoint = state
        self:CreateTimer(1000, function()
            local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
            local timeTxt = TimerMgr:FormatTimeLength(t)
            if t > 0 then
                self:SetText("BuidlingUnlockingUI/timer", timeTxt)
                local progress = self:GetComp("BuidlingUnlockingUI/prog", "Slider")
                progress.value = 1 - t / icon.unlock_time
            else
                self:StopTimer()
                CityMode:UnlockBuidlingComplete()
            end
        end, true, true)
    else
        go:SetActive(true)
        self:GetGo(go, "new"):SetActive(true)
        self:GetGo(go, "finished"):SetActive(false)
        self:SetText("BuildingBumble/new/name", info)
        self:SetImageSprite("BuildingBumble/new", icon)
        self:SetImageSprite("BuildingBumble/new/building", "icon_building_"..math.ceil((buildingId or 0) / 100))
    end
end

function FloatUIView:ParkingLotBabo()
    self.m_allGameObjects["OrderAreaBubble"]:SetActive(true)
end


function FloatUIView:ShowFactoryBumble(config)
    local root = self.m_allGameObjects["FactoryBumble"]
    root:SetActive(true)
    local workShopData = FactoryMode:GetWorkShopdata(config.id)
    --local productData = WorkShopInfoUI:GetProductsData()
    --生产物体的图片
    local image = self:GetComp(root, "buildingInfo/productBubble/icon", "Image")   
    --生产的进度
    local schedule = self:GetComp(root, "buildingInfo/productBubble/prog/bar", "Image")
    local icon = self:GetComp(root, "buildingInfo/productBubble/prog/bar", "Image")

    if not workShopData then
        root:SetActive(false)
        return
    end

    if  workShopData["state"] == 2 then
        root:SetActive(true)
        self:GetGo(root, "buildingInfo/productBubble/icon"):SetActive(true)
        self:GetGo(root, "buildingInfo/productBubble/prog/bar"):SetActive(true)
        local cfgProduct =  ConfigMgr.config_products[workShopData["productId"]] 
        local CfgWorkShop = ConfigMgr.config_workshop
        self:SetSprite(image, "UI_Common", cfgProduct["icon"])
        schedule.fillAmount = 1
        local icon = self:GetComp(root, "buildingInfo/productBubble/prog/bar", "Image")
        local boost = self:GetGo(root,"buildingInfo/productBubble/warning/boost")
        local full = self:GetGo(root,"buildingInfo/productBubble/warning/full")
        local lack = self:GetGo(root,"buildingInfo/productBubble/warning/lack")
        icon.color = UnityHelper.GetColor("#89F263")
        boost:SetActive(false)
        full:SetActive(false)
        lack:SetActive(false) 
        local isFull =  false       
        local isLack =  false
        local useBuff = false
        local num = 40
        local base_time = FactoryMode:GetSpeed(config.id)
        self:CreateTimer(25, function()            
            if num >= 40 then
                --加速buff
                if not useBuff and FactoryMode:CheckBuffUsefor(workShopData) then
                    icon.color = UnityHelper.GetColor("#82E7F0")
                    useBuff = true
                    boost:SetActive(true) 
                elseif useBuff and not FactoryMode:CheckBuffUsefor(workShopData) then                    
                    useBuff = false
                    boost:SetActive(false) 
                    icon.color = UnityHelper.GetColor("#89F263")
                end   
                --爆仓
                if not isFull and WorkShopInfoUI:storageLimit() <= 0  then
                    icon.color = UnityHelper.GetColor("#FFE193")
                    full:SetActive(true)
                    isFull = true
                elseif isFull and WorkShopInfoUI:storageLimit() > 0  then
                    isFull = false
                    full:SetActive(false)
                    icon.color = UnityHelper.GetColor("#89F263")
                end          
                --消耗不足
                if not isLack and not WorkShopInfoUI:EnoughPartsToProduce(workShopData["productId"]) then
                    icon.color = UnityHelper.GetColor("#FF8787")
                    lack:SetActive(true) 
                    isLack = true
                elseif isLack and WorkShopInfoUI:EnoughPartsToProduce(workShopData["productId"]) then
                    isLack = false
                    lack:SetActive(false) 
                    icon.color = UnityHelper.GetColor("#89F263")
                end       
                num = 0           
            end
            num = num + 1                                             
            --正常走过程
            --local bonus = (CfgWorkShop[config.id]["room_bonus"][workShopData.Lv] / 100) + 1
            if not isLack and not isFull then                
                local t =  ((TimerMgr:GetSocketTime() - workShopData.timePoint) % base_time)                                          
                schedule.fillAmount = (t / base_time) 
            end                  
        end, true, true)
    else
        FactoryMode:RefreshFloatUI(config.id)
    end          
end
--用于工厂的悬浮气泡使用加速道具时的显示效果
function FloatUIView:ShowFactorySuperSpeedBoost(cfg, workshopid)
    local root = self.m_allGameObjects["FactoryBumble"]
    self:GetGo(root,"buildingInfo/timerBubble"):SetActive(true)
    self:GetGo(root,"buildingInfo/productBubble"):SetActive(false) 
    self:SetSprite(self:GetComp(root, "buildingInfo/timerBubble/dial", "Image"), "UI_Float", "time_dial_" .. cfg.quaility)
    self:SetSprite(self:GetComp(root, "buildingInfo/timerBubble/dial/pointer", "Image"), "UI_Float", "time_pointer_" .. cfg.quaility)
    self:SetSprite(self:GetComp(root, "buildingInfo/timerBubble/dial/center", "Image"), "UI_Float", "time_center_" .. cfg.quaility)    
    GameUIManager:SetEnableTouch(false)
    --完成动画后的CB
    local cb = function()
        self:GetGo(root, "buildingInfo/timerBubble"):SetActive(false)
        self:GetGo(root,"buildingInfo/productBubble"):SetActive(true)
        GameUIManager:SetEnableTouch(true) 
    end
    local feel  = self:GetComp(root, "buildingInfo/timerBubble/timerFB", "MMFeedbacks")
    local fbx = self:GetComp(FactoryMode:GetWorkShopRoot(workshopid), "UIPosition/SparkleExplosionYellow", "ParticleSystem")
    feel.Feedbacks[3].BoundParticleSystem = fbx    
    if feel then
        feel.Events.OnComplete:AddListener(function()
            cb()
        end)
        feel:PlayFeedbacks()
    end   
end


function FloatUIView:ShowFactoryUnlockButtton(config, timeWait, state)
    self.m_allGameObjects["FactoryUnlockingUI"]:SetActive(true)
    self.endPoint = timeWait
    self.config = config
    --跳过直接解锁
    self:SetButtonClickHandler(self:GetComp("FactoryUnlockingUI/SkipBtn", "Button"), function(config, timeWait)
        UnlockingSkipUI:ShowWorkShopSkipSkipUI(self.config, self.endPoint)
    end)
    local progress = self:GetComp("FactoryUnlockingUI/prog", "Slider")
    self:CreateTimer(1000,function()
        if FactoryMode:GetWorkShopdata(self.config.id).state == 0 then    
            local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
            local timeTxt = TimerMgr:FormatTimeLength(t)
            if t > 0 then
                self:SetText("FactoryUnlockingUI/timer", timeTxt)                
                if progress then
                    progress.value = 1 - t / config.unlock_times
                end                
            else            
                self:StopTimer()  
                self.m_allGameObjects["FactoryUnlockingUI"]:SetActive(false)  
                -- self:DestroyModeUIObject() 
                FactoryMode:Build(config.id)  
                FactoryMode:RefreshFloatUI(config.id)
                EventManager:DispatchEvent("UPGRADE_FACTORY")                 
            end
        else
            self.m_allGameObjects["FactoryUnlockingUI"]:SetActive(false)          
            self:StopTimer() 
        end    
    end, true, true)        
end

function FloatUIView:ShowIntanceBuildingUnlockButtton(config, timeWait, handler)
    self.m_allGameObjects["UnlockingUI"]:SetActive(true)
    self.endPoint = timeWait
    self.config = config
    --跳过直接解锁
    self:SetButtonClickHandler(self:GetComp("UnlockingUI/SkipBtn", "Button"), function(config, timeWait)
        UnlockingSkipUI:ShowInstanceBuildingSkipUI(self.config, self.endPoint,handler)
    end)
    local progress = self:GetComp("UnlockingUI/prog", "Slider")
    self:CreateTimer(1000,function()
        if InstanceModel:GetRoomDataByID(self.config.id).state == 1 then    
            local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
            local timeTxt = TimerMgr:FormatTimeLength(t)
            if t > 0 then
                self:SetText("UnlockingUI/timer", timeTxt)                
                if progress then
                    progress.value = 1 - t / config.unlock_times
                end                
            else            
                self:StopTimer()  
                self.m_allGameObjects["UnlockingUI"]:SetActive(false)  
                -- self:DestroyModeUIObject() 
                local roomData = InstanceModel:GetRoomDataByID(config.id)
                InstanceDataManager:SetRoomData(config.id,roomData.buildTimePoint,2)
                InstanceModel:RefreshScene()  
                --FactoryMode:RefreshFloatUI(config.id)
                --EventManager:DispatchEvent("UPGRADE_FACTORY")                 
            end
        else
            self.m_allGameObjects["UnlockingUI"]:SetActive(false)          
            self:StopTimer() 
        end    
    end, true, true)        
end


function FloatUIView:ShowRoomUnlockButtton(unlock, toUnlock, cash, timeWait, companyLeave, config, 
    needCompany, offWork, brokenCfg, canLevelUp, companyId)
    self:HideAllGo(false, true)
    if toUnlock then--等待解锁
        if timeWait <= TimerMgr:GetCurrentServerTime(true) then
            self:StopTimer()
            FloorMode:RefreshFloorScene(config.room_index, config.id)
            return
        end

        self:NotHide()
        self.m_allGameObjects["UnlockingUI"]:SetActive(true)

        --再加一个绑定按钮,立刻解锁并刷星界面
        self:SetButtonClickHandler(self:GetComp("UnlockingUI/SkipBtn", "Button"), function()
            UnlockingSkipUI:Show(config, timeWait)
        end)
        self.endPoint = timeWait
        self:CreateTimer(1000, function()
            local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
            local timeTxt = TimerMgr:FormatTimeLength(t)
            if t > 0 then
                self:SetText("UnlockingUI/timer", timeTxt)
                local progress = self:GetComp("UnlockingUI/prog", "Slider")
                if progress then
                    progress.value = 1 - t / config.unlock_times
                end
            else
                self:StopTimer()
                FloorMode:RefreshFloorScene(config.room_index, config.id)--还是说直接关掉用一个新的比较合适
                --刷新界面
                GuideManager:ConditionToStart()
            end
        end, true, true)
    elseif brokenCfg then--破损
        local debuff = brokenCfg.emergency_3d[config.category[2]]
        local bindClick = function()
            CompanyEmployee:RequestRoomService(self.m_hander, brokenCfg.id)
            if self.m_temp3dObject[debuff] and self.m_temp3dObject[debuff] ~= -1 and self.m_hander.idleService then
                local unclickGo  = self:GetGo(self.m_temp3dObject[debuff], "unclick")
                local clickGo  = self:GetGo(self.m_temp3dObject[debuff], "click")
                unclickGo:SetActive(false)
                clickGo:SetActive(true)
                self:StopTimer()
            end
        end
        local loadHandler = function(go)
            self.m_darkRoomId = config.id
            local scene = FloorMode:GetScene()
            scene:SetRoom3dHintVisible(config.id, scene.FLAG_DARK_BROKEN, true)
            EventManager:DispatchEvent("room_broke", go, bindClick)
            local cb = function()
                local unclickGo  = self:GetGo(self.m_temp3dObject[debuff], "unclick")
                local clickGo  = self:GetGo(self.m_temp3dObject[debuff], "click")
                unclickGo:SetActive(self.m_hander.idleService == nil)
                clickGo:SetActive(self.m_hander.idleService ~= nil)
            end
            if not self.m_hander.idleService then
                self:CreateTimer(100, function() 
                    if self.m_hander.idleService then 
                        cb()
                        self:StopTimer() 
                    end
                end, true)
            end
            cb()
        end
        self:Show3DMode(debuff, "Assets/Res/UI/"..debuff..".prefab", bindClick, loadHandler)
    elseif canLevelUp then--升级
        local loadHandler = function(go)            
            EventManager:DispatchEvent("compnay_levle_up", go, function()
                CompanyLvUpUI:Refresh(companyId)
            end)
        end

        self:Show3DMode(companyLevelUp, "Assets/Res/UI/CompanyLevelUpModel.prefab", function()            
            CompanyLvUpUI:Refresh(companyId)
        end, loadHandler)

    elseif unlock == false then--点击解锁
        local scene = FloorMode:GetScene()
        if StarMode:GetStar() < (config.star or 0) then
            self.m_allGameObjects["RoomStar"]:SetActive(true)
            local go = self.m_allGameObjects["RoomStar"]
            local curP = StarMode:GetStar() / config.star
            go:SetActive(true)
            self:SetText(go, "reward/num", config.star)
            self:SetText(go, "curr", StarMode:GetStar().."/"..config.star)
            self:GetComp(go, "progress", "Slider").value = curP
            scene:SetRoom3dHintVisible(config.id, scene.FLAG_DARK_START, true)
            return
        end
        scene:SetRoom3dHintVisible(config.id, scene.FLAG_DARK_START, false)
        self.m_allGameObjects["RoomStar"]:SetActive(false)
        self:Show3DMode(unlock3dButton, "Assets/Res/UI/unlockable_btn.prefab", function()
            RoomUnlockUI:Show(config)--打开解锁界面
        end)
    elseif companyLeave then--有公司离开
        self:Show3DMode(cashTip, "Assets/Res/UI/CashTipUI.prefab")
    elseif needCompany then--招聘
        self:StopTimer()
        self:Show3DMode(officeEmpty, "Assets/Res/UI/OfiiceEmptyUI.prefab")
    end
end

function FloatUIView:ShowFootballBuildingUnlockButton(arg)
    self.m_allGameObjects["ClubUnlockingUI"]:SetActive(true)
    self.config = arg[1]
    self.endPoint = arg[2]
    --跳过直接解锁
    self:SetButtonClickHandler(self:GetComp("ClubUnlockingUI/SkipBtn", "Button"), function(config, timeWait)
        UnlockingSkipUI:ShowFootballClubSkipUI(self.config, self.endPoint)
    end)
    local progress = self:GetComp("ClubUnlockingUI/prog", "Slider")
    local buildData = GameTableDefine.FootballClubModel:GetRoomDataById(self.config.id)
    self:CreateTimer(1000,function()

            local t = self.endPoint - TimerMgr:GetCurrentServerTime(true)
            local timeTxt = TimerMgr:FormatTimeLength(t)
            if t > 0 then
                self:SetText("ClubUnlockingUI/timer", timeTxt)                
                if progress then
                    progress.value = 1 - t / self.config.unlockTime
                end                
            else            
                self:StopTimer()  
                self.m_allGameObjects["ClubUnlockingUI"]:SetActive(false)  
                self:DestroyModeUIObject() 
                GameTableDefine.FootballClubController:BuyRoomFinished(self.config.id)
                -- FactoryMode:RefreshFloatUI(self.config.id)
                --EventManager:DispatchEvent("UPGRADE_FACTORY")                 
            end

    end, true, true)        
end

function FloatUIView:Show3DMode(typeName, path, bindClick, loadHandler)
    if not typeName then
        return
    end

    local hideAll = function()
        for k, go in pairs(self.m_temp3dObject or {}) do
            if type(go) ~= "number" and not go:IsNull() and go.activeSelf then
                go:SetActive(false)
            end
        end
    end

    self.m_temp3dObject[typeName] = -1
    local trans = self:GetTrans(self.m_locationTrans.gameObject, typeName)
    if trans then--如果已经有了
        hideAll()
        local go = trans.gameObject
        self.m_temp3dObject[typeName] = go
        self.m_temp3dObject[typeName]:SetActive(true)
        self:SetClickHandler(self.m_temp3dObject[typeName], bindClick)
        if loadHandler then 
            loadHandler(self.m_temp3dObject[typeName]) 
        end
        return
    end

    GameResMgr:AInstantiateObjectAsyncManual(path,self,function(childGo)
        if self.m_temp3dObject[typeName] ~= -1 then--这个childGo还是会生成...
            UnityHelper.DestroyGameObject(childGo)
            return
        end
        hideAll()
        self:Load3dDone(childGo, typeName)
        
        self.m_temp3dObject[typeName].name = typeName
        self:SetClickHandler(self.m_temp3dObject[typeName], bindClick)
        if loadHandler then 
            loadHandler(self.m_temp3dObject[typeName]) 
        end
    end)
end

function FloatUIView:Load3dDone(childGo, type)
    if self.m_locationTrans and not self.m_locationTrans:IsNull() then
        UnityHelper.AddChildToParent(self.m_locationTrans.transform, childGo.transform)
        if self.m_temp3dObject[type] == -1 then
            self.m_temp3dObject[type] = childGo
        end
    else
        UnityHelper.DestroyGameObject(childGo)
    end
end

function FloatUIView:ShowEventBumble(type, clickHander)
    self.m_allGameObjects["EventBumble"]:SetActive(true)
    local allUI = {}
    allUI[1] = Event001UI
    allUI[2] = Event004UI
    allUI[100] = Event003UI
    allUI[101] = Event101UI
    allUI[3] = Event005UI
    allUI[4] = Event006UI
    allUI[5] = Event001UI

    self:SetButtonClickHandler(self:GetComp("EventBumble/icon", "Button"), function()
        if clickHander then
            clickHander()
        else
            allUI[type]:ShowPanel(type)
        end
    end)
end

function FloatUIView:AZhenTalk(clickHander)
    self.m_allGameObjects["EventBumble"]:SetActive(true)
    self:SetButtonClickHandler(self:GetComp("EventBumble/icon", "Button"), function()
        if clickHander then
            clickHander()
        end
    end)
end

function FloatUIView:WheelNote(clickHander)
    self.m_allGameObjects["WheelBumble"]:SetActive(true)
    self:SetButtonClickHandler(self:GetComp("WheelBumble/icon", "Button"), function()
        if clickHander then clickHander() end
    end)
end

function FloatUIView:ShowGarageBumble()
    self.m_allGameObjects["GarageBumble"]:SetActive(true)

    self:SetText("GarageBumble/carName/text", "textContent")
    -- self:SetButtonClickHandler(self:GetComp("GarageBumble/icon", "Button"), function()
    -- end)
end

function FloatUIView:showChatEvent(conditionId)
    self.m_allGameObjects["EventBumble"]:SetActive(true)
    self:SetButtonClickHandler(self:GetComp("EventBumble/icon", "Button"), function()
        SceneChatInfoUI:Refresh(conditionId)
    end)
end

function FloatUIView:ShowNpcFloat(person)
    self.m_parms.person = person
    self.m_parms.enableGo = {}
    self.m_allGameObjects["Npc"]:SetActive(true)
    if GameConfig:IsDebugMode() then
        self:GetGo(self.m_allGameObjects["Npc"], "debug"):SetActive(true)
        self:CreateTimer(1,function()
            local txt = GameConfig.showfps and person:GetDebugInfo() or ""
            self:SetText(self.m_allGameObjects["Npc"], "debug", txt)
        end, true, true)
    end
end

function FloatUIView:ShowPersonActionHint(actionName, lastAction, hasNoBumble, args)
    local showClose = false
    if not actionName then
        if lastAction then
            actionName = lastAction
            showClose = true
            hasNoBumble = true
        else
            return
        end
    end

    local go = self:GetGo(self.m_allGameObjects["Npc"], actionName)
    go:SetActive(true)

    self.m_parms.enableGo[go] = true
    local anim = go:GetComponent("Animation")
    if anim and AnimationUtil.GetAnimationState(anim, "Bumble_open") then
        if hasNoBumble then
            self:AddAnimationHander(anim)
            AnimationUtil.Play(anim, showClose and "Bumble_close" or "Bumble_open", function()
                if not showClose then
                    return
                end
                if self.m_parms.enableGo then
                    self.m_parms.enableGo[go] = nil
                end
            end)
            self.m_parms.behaviourHint = not showClose
            self:ShowMoodTransfer()
            if showClose and actionName == "ConferenceBumble" and tonumber(args) then
                self:SetText(go, "num", "+" .. Tools:SeparateNumberWithComma(tonumber(args)))
            end
        else
            AnimationUtil.GotoAndStop(anim, "Bumble_close") -- KEY_FRAME_ANIM_END
            self.m_parms.behaviourHint = true
            self:ShowMoodTransfer()
        end
    end
end

function FloatUIView:ShowMoodTransfer()
    local moodIndicator = 0
    if self.m_parms.person and self.m_parms.behaviourHint then
        moodIndicator = self.m_parms.person.m_moodTransferVlaue or 0
    end
    if self.m_parms.lastMoodIndicator == moodIndicator then
        return
    end

    local moodUpGo = self:GetGo(self.m_allGameObjects["Npc"], "MoodIncrease_Indicator")
    local moodDownGo = self:GetGo(self.m_allGameObjects["Npc"], "MoodDecrease_Indicator")
    moodUpGo:SetActive(moodIndicator > 0)
    moodDownGo:SetActive(moodIndicator < 0)
    self.m_parms.enableGo[moodUpGo] = nil
    self.m_parms.enableGo[moodDownGo] = nil
    if moodIndicator ~= 0 then
        local curMood = moodIndicator > 0 and moodUpGo or moodDownGo
        local num = math.abs(moodIndicator)
        for i,child in pairs(curMood.transform) do
            child.gameObject:SetActive(i < num)
        end
        self.m_parms.enableGo[curMood] = true
    end
    self.m_parms.lastMoodIndicator = moodIndicator
end

function FloatUIView:HidePersonActionHint(actionName)
    if not actionName or self.m_allGameObjects["Npc"]:IsNull() then
        return
    end
    local go = self:GetGo(self.m_allGameObjects["Npc"], actionName)
    go:SetActive(false)
    self.m_parms.behaviourHint = false
    if self.m_parms.enableGo then
        self.m_parms.enableGo[go] = nil
    end
    self:ShowMoodTransfer()
end

function FloatUIView:ShowPersonMoodState(moodHint)
    local go = self:GetGo(self.m_allGameObjects["Npc"], moodHint)
    if go and not go:IsNull() then
        go:SetActive(true)
        local anim = go:GetComponent("Animation")
        self:AddAnimationHander(anim)
        AnimationUtil.Play(anim, "MoodBumble_Anim", function()
            go:SetActive(false)
            if self.m_parms.enableGo then
                self.m_parms.enableGo[go] = nil
            end
        end)
        if self.m_parms.enableGo then
            self.m_parms.enableGo[go] = true
        end
    end
end

function FloatUIView:ShowPropertyWorking(percentage)
    local go = self.m_allGameObjects["RepairTimer"]
    go:SetActive(true)

    percentage = 1 - math.min(math.max(0, percentage / 100), 1)
    local image = self:GetComp(go, "bg", "Image")
    image.fillAmount = percentage
end

function FloatUIView:ResetBuyCar()
    local go = self.m_allGameObjects["BuyCar"]
    self:GetGo(go, "carName"):SetActive(true)
    self:GetGo(go, "carInfo"):SetActive(false)
end

function FloatUIView:ShowInfo(carId, shopId)
    local canBuy = BuyCarManager:Buy(carId, shopId, true)
    local btn = self:GetComp("BuyCar/carInfo/btn", "Button")
    btn.interactable = canBuy == 1 or canBuy == -2

    local go = self.m_allGameObjects["BuyCar"]
    self:GetGo(go, "carName"):SetActive(false)
    self:GetGo(go, "carInfo"):SetActive(true)
end

function FloatUIView:InitBuyCar(data, cb)--{id,num,price}
    local go = self.m_allGameObjects["BuyCar"]
    go:SetActive(true)

    local cfg = ConfigMgr.config_car[data.id]
    local img = self:GetComp(go, "carName/logo", "Image")
    local img2 = self:GetComp(go, "carInfo/logo", "Image")
    self:SetDynamicLocalizeText("FloatUIView_InitBuyCar", function()
        local name = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_NAME")
        local desc = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_DESC")
        self:SetText(go, "carName/text", name)
        self:SetText(go, "carInfo/name", name)
        self:SetText(go, "carInfo/des", desc)
        local txtValue = GameTextLoader:ReadText("TXT_CONTRACT_CAR_CONTENT")
        txtValue = string.format(txtValue, data.value)
        self:SetText(go, "carInfo/wealth/num", txtValue)
    end)
    self:SetText(go, "carInfo/btn/num", Tools:SeparateNumberWithComma(data.price))
    self:SetSprite(img, "UI_Common", cfg.logo)
    self:SetSprite(img2, "UI_Common", cfg.logo)
    self:GetGo(go, "carName"):SetActive(true)
    self:GetGo(go, "carInfo"):SetActive(false)
    self:GetGo(go, "carInfo/wealth"):SetActive(true)

    local simple = self:GetComp(go, "carName", "Button")
    self:SetButtonClickHandler(simple, function()
        FloorMode:GetScene():ResetChooseCar(data.id)
    end)

    local btn = self:GetComp("BuyCar/carInfo/btn", "Button")
    btn.interactable = cb(true)

    self:SetButtonClickHandler(btn, function()
        if cb then cb() end
    end)
end

function FloatUIView:ShowPersonTalkingPop(text, moodState)
    local go = self.m_allGameObjects["Dialog"]
    go:SetActive(true)
    self:SetText(go, "text", text)
    self:SetSprite(self:GetComp(go, "mood", "Image"), "UI_Float", "icon_mood_"..moodState, nil, true)
    local anim = go:GetComponent("Animation")
    self:AddAnimationHander(anim)
    AnimationUtil.Play(anim, "Dialog_Anim", function()
        go:SetActive(false)
    end)
end

function FloatUIView:InitCarPortBumbel(data, cb, isSelect, whenSell)
    local go = self.m_allGameObjects["GarageBumble"]
    go:SetActive(true)
    if not data then
        self:GetGo(go, "carName"):SetActive(not isSelect)
        self:GetGo(go, "carInfo"):SetActive(isSelect)
        return
    end

    local cfg = ConfigMgr.config_car[data.id]
    local img = self:GetComp(go, "carName/logo", "Image")
    local img2 = self:GetComp(go, "carInfo/logo", "Image")
    self:SetDynamicLocalizeText("FloatUIView_InitCarPortBumbel", function()
        local name = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_NAME")
        local desc = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_DESC")
        self:SetText(go, "carName/text", name)
        self:SetText(go, "carInfo/name", name)
        self:SetText(go, "carInfo/des", desc)
        local txtCar = GameTextLoader:ReadText("TXT_CONTRACT_CAR_CONTENT")
        txtCar = string.format(txtCar, data.value)
        self:SetText(go, "carInfo/wealth/num", txtCar)
    end)   
    self:SetText(go, "carInfo/btn/num", data.price)
    self:SetSprite(img, "UI_Common", cfg.logo)
    self:SetSprite(img2, "UI_Common", cfg.logo)
    self:GetGo(go, "carInfo/wealth"):SetActive(true)
    self:GetGo(go, "carName"):SetActive(not isSelect)
    self:GetGo(go, "carInfo"):SetActive(isSelect)

    local doneBtn = self:GetComp("carInfo/doneBtn", "Button")
    local equipBtn = self:GetComp("carInfo/equipBtn", "Button")
    equipBtn.gameObject:SetActive(BuyCarManager:GetDrivingCar() ~= data.id)
    doneBtn.gameObject:SetActive(BuyCarManager:GetDrivingCar() == data.id)
    self:SetButtonClickHandler(self:GetComp(go, "carName", "Button"), function()
        if cb then cb() end
    end)
    self:SetButtonClickHandler(equipBtn, function()
        local id = BuyCarManager:GetDrivingCar(data.id)
        Bus:GetCarEntity(id)
        doneBtn.gameObject:SetActive(id == data.id)
        equipBtn.gameObject:SetActive(id ~= data.id)
    end)

    local sellBtn = self:GetComp("carInfo/sellBtn", "Button")
    self:SetButtonClickHandler(sellBtn, function()
        local add = data.price * ConfigMgr.config_global.car_sell_price
        chooseUI:EarnCash(add, function()
            if whenSell then whenSell() end
            self:Hide()
        end, "TXT_TIP_CAR_SELL")
        -- chooseUI:ChooseMore("TXT_TIP_CAR_SELL", math.floor(data.price * ConfigMgr.config_global.car_sell_price), function()
        --     if whenSell then whenSell() end
        --     self:Hide()
        -- end)
    end)
end

function FloatUIView:RefreshCarPortBumble(isSelect, carId)
    local go = self.m_allGameObjects["GarageBumble"]
    self:GetGo(go, "carName"):SetActive(not isSelect)
    self:GetGo(go, "carInfo"):SetActive(isSelect)
    if isSelect then
        local id = BuyCarManager:GetDrivingCar()

        local doneBtn = self:GetComp("carInfo/doneBtn", "Button")
        local equipBtn = self:GetComp("carInfo/equipBtn", "Button")
        doneBtn.gameObject:SetActive(id == carId)
        equipBtn.gameObject:SetActive(id ~= carId)
    end
end

--设置副本人物气泡UI
function FloatUIView:RefreshInstanceWorkerBubble(typeB, state)
    local typeB = typeB
    for k,v in pairs(self.m_allGameObjects) do
        if not v or v:IsNull() then
            return
        end
        v:SetActive(false)
    end
    local go = self.m_allGameObjects["InstanceWorkerBumble"]
    local infoGo = self:GetGo(go, "Info")
    for k,v in pairs(infoGo.transform) do
        v.gameObject:SetActive(false)
    end    
    if typeB == nil then
        self:StopTimer()
        return
    end    
    local imageSlider = nil
    local inHunger = state.hungry < 20
    local inSleepy = state.physical < 20
    local iconName = "icon_resource_1"
    if state.productionID and state.productionID ~= 0 then
        iconName = "icon_resource_" .. state.productionID
    end
    local loadtime = 180       
    if typeB == "product" then
        loadtime = 10
        self:GetGo(infoGo, "productBubble"):SetActive(true)
        imageSlider = self:GetComp(infoGo, "productBubble/prog/bar", "Image")
        
        if inHunger or inSleepy then
            imageSlider.color = UnityHelper.GetColor("#FF2C3D")
        else
            imageSlider.color = UnityHelper.GetColor("#89F263")
        end
        self:GetGo(infoGo, "warning/hunger"):SetActive(inHunger)
        self:GetGo(infoGo, "warning/physical"):SetActive(inSleepy)
        local icon = self:GetComp(infoGo, "productBubble/icon", "Image")
        local productionIcon = self:GetComp(infoGo, "productBubble/production/icon", "Image")
        self:SetSprite(icon, "UI_Common", iconName)
        self:SetSprite(productionIcon, "UI_Common", iconName)
        local furLevelID = InstanceModel.roomsData[state.roomId].furList[tostring(state.index)].id
        local prodCount = InstanceModel:GetFurLevelCfgAttrSum(furLevelID,"product")

        if not InstanceModel:GetLandMarkCanPurchas() then
            local instanceBind = InstanceDataManager:GetInstanceBind()
            local landmarkID = instanceBind.landmark_id
            local shopCfg = ConfigMgr.config_shop[landmarkID]
            local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
            prodCount = math.floor(prodCount * (1 + resAdd/100))
        end

        if inHunger and inSleepy then
            prodCount = prodCount * 0.6
        elseif inHunger or inSleepy then
            prodCount = prodCount * 0.8
        end
        prodCount = math.floor(prodCount * 10) / 10
        self:SetText(infoGo, "productBubble/production/num", "+" .. prodCount)
    elseif typeB == "eat" then
        loadtime = 90
        self:GetGo(infoGo, "eatBubble"):SetActive(true)
        imageSlider =  self:GetComp(infoGo, "eatBubble/prog/bar", "Image")
        local icon = self:GetComp(infoGo, "eatBubble/icon", "Image")
    elseif typeB == "sleep" then
        loadtime = 180
        self:GetGo(infoGo, "sleepBubble"):SetActive(true)
        imageSlider =  self:GetComp(infoGo, "sleepBubble/prog/bar", "Image")
    elseif typeB == "state" then
        self:GetGo(infoGo, "stateBubble"):SetActive(true)
        self:GetGo(infoGo, "stateBubble/hunger"):SetActive(inHunger)
        self:GetGo(infoGo, "stateBubble/physical"):SetActive(inSleepy)
    end
    go:SetActive(true)
    local pollTime = 100
    local addCoefficient = pollTime/1000
    local addFrequency = loadtime / addCoefficient
    self:CreateTimer(pollTime, function()     
        if imageSlider then
            if typeB == "product" then   
                state.workProgress = state.workProgress + state.speed * addCoefficient         
                imageSlider.fillAmount = state.workProgress
                if state.workProgress >= 1 then
                    state.workProgress = 0
                    self:GetGo(infoGo, "productBubble/production"):SetActive(true)
                end                
            elseif typeB == "eat" then                
                state.hungry = state.hungry + (state.speed/addFrequency)        
                imageSlider.fillAmount = state.hungry/100
            elseif typeB == "sleep" then                  
                state.physical = state.physical + (state.speed/addFrequency)                                      
                imageSlider.fillAmount = state.physical/100
            end            
        end
    end, true, true, true)
end
 
--刷新副本的船的UI
function FloatUIView:RefreshShipBubbles(loadValue, isLeave, isOpen, iconId)
    local imageSlider = nil
    local go = self.m_allGameObjects["InstanceShipBumble"]
    for k,v in pairs(self.m_allGameObjects) do
        if v and (not v:IsNull()) then
            v:SetActive(false)
        end
    end
    if isLeave then
        self:StopTimer()
        return
    end    
    go:SetActive(true)
    local infoGo = self:GetGo(go, "Info")
    self:GetGo(infoGo, "loadingBubble"):SetActive(not isLeave)
    local icon = self:GetComp(infoGo, "loadingBubble/icon", "Image")
    local iconName = "icon_resource_" .. iconId    
    self:SetSprite(icon, "UI_Common", iconName)
    local imageSlider = self:GetComp(infoGo, "loadingBubble/prog/bar", "Image")    
    if not isLeave then
        local loadtime = ConfigMgr.config_global.instance_ship_loadtime
        local pollTime = 100
        local addValue = (pollTime/1000)/loadtime
        pollTime = pollTime * 0.7 --表现效果补正
        self:CreateTimer(pollTime, function()     
            if imageSlider then
                loadValue = loadValue + addValue
                imageSlider.fillAmount = loadValue
            end
            if loadValue > 1 then
                self:StopTimer()
            end
        end, true, true, true)            
    else
        self:StopTimer()
    end      
end


-- function FloatUIView:ShowCarPortBumble(data, cb, isSelect, whenSell)--{id,num,price}
--     local go = self.m_allGameObjects["GarageBumble"]
--     go:SetActive(true)
--     if not data then
--         self:GetGo(go, "carName"):SetActive(not isSelect)
--         self:GetGo(go, "carInfo"):SetActive(isSelect)
--         return
--     end

--     local cfg = ConfigMgr.config_car[data.id]

--     local name = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_NAME")
--     local desc = GameTextLoader:ReadText("TXT_CAR_C"..data.id.."_DESC")
--     local img = self:GetComp(go, "carName/logo", "Image")
--     local img2 = self:GetComp(go, "carInfo/logo", "Image")

--     self:SetText(go, "carName/text", name)
--     self:SetText(go, "carInfo/name", name)
--     self:SetText(go, "carInfo/des", desc)
--     self:SetText(go, "carInfo/btn/num", data.price)
--     self:SetSprite(img, "UI_Common", cfg.logo)
--     self:SetSprite(img2, "UI_Common", cfg.logo)

--     self:GetGo(go, "carName"):SetActive(not isSelect)
--     self:GetGo(go, "carInfo"):SetActive(isSelect)

--     local doneBtn = self:GetComp("carInfo/doneBtn", "Button")
--     local equipBtn = self:GetComp("carInfo/equipBtn", "Button")
--     equipBtn.gameObject:SetActive(BuyCarManager:GetDrivingCar() ~= data.id)
--     doneBtn.gameObject:SetActive(BuyCarManager:GetDrivingCar() == data.id)
--     self:SetButtonClickHandler(self:GetComp(go, "carName", "Button"), function()
--         if cb then cb() end
--     end)
--     self:SetButtonClickHandler(equipBtn, function()
--         local id = BuyCarManager:GetDrivingCar(data.id)
--         Bus:GetCarEntity(id)
--         doneBtn.gameObject:SetActive(id == data.id)
--         equipBtn.gameObject:SetActive(id ~= data.id)
--     end)

--     local sellBtn = self:GetComp("carInfo/sellBtn", "Button")
--     self:SetButtonClickHandler(sellBtn, function()
--         chooseUI:ChooseMore("TXT_TIP_CAR_SELL", math.floor(data.price * ConfigMgr.config_global.car_sell_price), function()
--             if whenSell then whenSell() end
--             self:Hide()
--         end)
--     end)
-- end

-- function FloatUIView:ShowCarPortDetails()
--     local go = self.m_allGameObjects["GarageBumble"]
--     self:GetGo(go, "carName"):SetActive(false)
--     self:GetGo(go, "carInfo"):SetActive(true)
-- end

function FloatUIView:ShowInstanceSpacialGOPop(active)
    local go = self:GetGo("InstanceLandmarkBumble")
    go:SetActive(active)
end

function FloatUIView:CheckGoIsHave(goName)
    local go = self.m_allGameObjects[goName]
    
end

-- 建筑中心气泡改用模型显示
-- function FloatUIView:ShowClubCenterBubble(active)
--     self:GetGo("FootballClubBumble/buildingInfo/renewalBubble"):SetActive(active)
--     self:SetButtonClickHandler(self:GetComp("FootballClubBumble/buildingInfo/renewalBubble/icon","Button"),function()
--         FootballClubController:ClickClubCenter(FootballClubController.sceneGo["ClubCenter"].root,10001)
--         self:ShowClubCenterBubble(false)
--     end)
-- end

--显示俱乐部健康中心气泡
function FloatUIView:ShowFCHealthCenterBubble(args)

    local roomData = FootballClubModel:GetRoomDataById(FootballClubModel.HealthCenterID)
    local roomCfg = ConfigMgr.config_health_center[FootballClubModel.m_cfg.id][roomData.LV]
    local active = args[1]
    local lastStartTime = roomData.useTime
    local duration = roomCfg.cd
    self:CloseAllFCChildNodes()
    self:GetGo("FootballClubBumble"):SetActive(active)
    self:GetGo("FootballClubBumble/buildingInfo/renewalBubble"):SetActive(active)
    if not active or not lastStartTime then
        self:GetGo("FootballClubBumble"):SetActive(false)
        return
    end
    duration = duration * 3600 
    self:CreateTimer(100,function()
        lastStartTime = roomData.useTime
        local curTime = GameTimeManager:GetCurrentServerTime(true)
        local image = self:GetComp("FootballClubBumble/buildingInfo/renewalBubble/prog","Image")
        if not image then
            return
        end
        if curTime >= lastStartTime + duration then
            image.color = UnityHelper.GetColor("#84de24")
            if not FootballClubController.SPRead then
                FootballClubController:PlaySPChargeReadyFeel()
                
            end
            --播放充能ani
            local ani = self:GetComp("FootballClubBumble/buildingInfo/renewalBubble", "Animation")
            AnimationUtil.Play(ani, "renewalBubble", function()
            end)
            self:StopTimer()
        else
            image.color = UnityHelper.GetColor("#f9de35")
            --播放充能ani
            local ani = self:GetComp("FootballClubBumble/buildingInfo/renewalBubble", "Animation")
            AnimationUtil.GotoAndStop(ani, "renewalBubble")
        end
        image.fillAmount = (curTime - lastStartTime) / duration
    end,true,true)

    --添加气泡点击事件
    self:SetButtonClickHandler(self:GetComp("FootballClubBumble/buildingInfo/renewalBubble","Button"),function ()
        local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][FootballClubModel.HealthCenterID]
        local roomName = buildCfg.objName
        FootballClubController:ClickHealthCenter(FootballClubController.sceneGo[roomName].root,FootballClubModel.HealthCenterID)
    end)
    
end

--显示俱乐部训练中心气泡
function FloatUIView:ShowFCTrainingCenterBubble(args)
    local active = args[1]
    local roomData = FootballClubModel:GetRoomDataById(FootballClubModel.TrainingGroundID)
    local roomCfg = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id][roomData.LV]
    local trainingProject = roomData.trainingProject
    local lastStartTime = roomData.lastStarTime
    local duration = roomData.trainingDuration
    self:CloseAllFCChildNodes()
    self:GetGo("FootballClubBumble"):SetActive(active)
    self:GetGo("FootballClubBumble/buildingInfo/trainningBubble"):SetActive(active)
    local isPlayFinish = false
    if not active or not trainingProject then
        self:GetGo("FootballClubBumble"):SetActive(false)
        return
    end
    local sprite = ConfigMgr.config_training_ground[FootballClubModel.m_cfg.id].ProjectInfo[trainingProject].bubble
    self:SetSprite(self:GetComp("FootballClubBumble/buildingInfo/trainningBubble/center/icon","Image"),"UI_Common",sprite)
    duration = duration * 3600

    self:CreateTimer(100,function()
        local curTime = GameTimeManager:GetCurrentServerTime(true)
        local image = self:GetComp("FootballClubBumble/buildingInfo/trainningBubble/prog","Image")
        if not image then
            return
        end
        if curTime >= lastStartTime + duration then
            image.color = UnityHelper.GetColor("#84de24")
            if not isPlayFinish then
                --播放充能ani
               local ani = self:GetComp("FootballClubBumble/buildingInfo/trainningBubble", "Animation")
               AnimationUtil.Play(ani, "trainningBubble", function()
               end)
               isPlayFinish = true
            end
        else
            image.color = UnityHelper.GetColor("#f9de35")
            --停止播放充能ani
            local ani = self:GetComp("FootballClubBumble/buildingInfo/trainningBubble", "Animation")
            AnimationUtil.GotoAndStop(ani, "trainningBubble")
            isPlayFinish = false
        end
        image.fillAmount = (curTime - lastStartTime) / duration
    end,true,true,true)

    --添加气泡点击事件
    self:SetButtonClickHandler(self:GetComp("FootballClubBumble/buildingInfo/trainningBubble","Button"),function ()
        local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][FootballClubModel.TrainingGroundID]
        local roomName = buildCfg.objName
        FootballClubController:ClickTrainingGround(FootballClubController.sceneGo[roomName].root,FootballClubModel.TrainingGroundID)
    end)
end

--显示场馆气泡
function FloatUIView:ShowFCStadiumBubble(Active)
    self:ShowFCMatchChargeBubble({false, nil})
    self:ShowFCMatchScoreBubble({false})
    self:ShowFCMatchResultBubble({false})
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    local footballClubConfig = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id]
    local roomCfg = footballClubConfig[FootballClubModel.StadiumID]
    local roomName = roomCfg.objName
    local roomData = FCData[roomName]
    self.FCState = FootballClubModel:GetCurrentState()
    if FootballClubModel:GetCurrentState() == FootballClubModel.EFCState.InTheGame then
        self:ShowFCMatchScoreBubble(Active)
    elseif FootballClubModel:GetCurrentState() == FootballClubModel.EFCState.GameSettlement then
        self:ShowFCMatchResultBubble(Active)
    else
        local stadiumCfg = ConfigMgr.config_stadium[FootballClubModel.m_cfg.id][roomData.LV]
        local args = {Active[1], stadiumCfg}
        self:ShowFCMatchChargeBubble(args)
    end
    self.lastFCState = self.FCState

end


--显示比赛充能气泡
function FloatUIView:ShowFCMatchChargeBubble(args)
    local active = args[1]
    local stadiumCfg = args[2]
    local waiting = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/waiting")
    local ready = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/ready")
    local matching = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching")
    local endNode = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/end")
    self:CloseAllFCChildNodes()
    if not active then
        self:GetGo("FootballClubBumble"):SetActive(false)
        return
    end

    waiting:SetActive(false)
    ready:SetActive(false)
    matching:SetActive(false)
    endNode:SetActive(false)
    self:GetGo("FootballClubBumble"):SetActive(true)
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(true)
    local leagueData = FootballClubModel:GetLeagueData()
    local matchChange = FootballClubModel:GetMatchChange(leagueData)
    waiting:SetActive(matchChange < 1)
    ready:SetActive(matchChange >= 1)
    if matchChange >= 1 then
        --播放动画
        if FootballClubController:CheckPlayFeelOnStateChange() then
            local feel = self:GetComp(ready, "bg/openFB", "MMFeedbacks")
            feel:PlayFeedbacks()
        end
    end
    local show = false
    self:CreateTimer(
        100,
        function()
            local curMatchChange = FootballClubModel:GetMatchChange(leagueData)
            if curMatchChange >= 1 then
                waiting:SetActive(curMatchChange < 1)
                ready:SetActive(curMatchChange >= 1)
                show = true
                self:SetText("FootballClubBumble/buildingInfo/matchBubble/ready/bg/bg/match/num/num1", math.floor(curMatchChange))
                self:SetText("FootballClubBumble/buildingInfo/matchBubble/ready/bg/bg/match/num/num2", stadiumCfg.matchLimit)
            else
                self:SetText("FootballClubBumble/buildingInfo/matchBubble/waiting/bg/match/num/num1", math.floor(curMatchChange))
                self:GetComp("FootballClubBumble/buildingInfo/matchBubble/waiting/bg/Slider", "Slider").value = leagueData.chargeTime / (stadiumCfg.matchCD * 3600)
                self:SetText("FootballClubBumble/buildingInfo/matchBubble/waiting/bg/Slider/time", GameTimeManager:FormatTimeLength(stadiumCfg.matchCD * 3600 - leagueData.chargeTime))
            end
        end,
        true,
        true
    )
    --添加气泡点击事件
    self:SetButtonClickHandler(
        self:GetComp("FootballClubBumble/buildingInfo/matchBubble/waiting/bg", "Button"),
        function()
            local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][FootballClubModel.StadiumID]
            local roomName = buildCfg.objName
            FootballClubController:ClickStadium(FootballClubController.sceneGo[roomName].root, FootballClubModel.StadiumID)
        end
    )
    self:SetButtonClickHandler(
        self:GetComp("FootballClubBumble/buildingInfo/matchBubble/ready/bg", "Button"),
        function()
            local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][FootballClubModel.StadiumID]
            local roomName = buildCfg.objName
            FootballClubController:ClickStadium(FootballClubController.sceneGo[roomName].root, FootballClubModel.StadiumID)
        end
    )
end


--显示比赛比分气泡
function FloatUIView:ShowFCMatchScoreBubble(args)
    local GAME_DURATION_SHOW = 90
    local totalDuration = FootballClubModel.totalDuration    --比赛实际持续时间
    local active = args[1]
    local matchData = FootballClubModel:GetMatchData()
    local FCData = FootballClubModel:GetFCDataById()
    --local roomData = FootballClubModel:GetRoomDataById(FootballClubModel.StadiumID)
    local timePos = matchData.lastStarTime or 0
    local currState = nil

    local waiting = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/waiting")
    local ready = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/ready")
    local matching = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching")
    local endNode = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/end")

    self:CloseAllFCChildNodes()
    local now = GameTimeManager:GetCurrentServerTime(true)
    active = active and now - timePos <= totalDuration
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(active)
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching"):SetActive(active)
    waiting:SetActive(false)
    ready:SetActive(false)
    endNode:SetActive(false)
    if not active then
        self:GetGo("FootballClubBumble"):SetActive(false)
        active = true
        return
    end
    
    self:GetGo("FootballClubBumble"):SetActive(true)
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(true)
    matching:SetActive(true)
    --播放动画
    if FootballClubController:CheckPlayFeelOnStateChange() then
        local feel = self:GetComp(matching,"bg/openFB","MMFeedbacks")
        feel:PlayFeedbacks()
    end
    local gameData = FootballClubModel:GetPlayerGameData()
    local playerData = gameData.playerData
    local enemyData = gameData.enemyData
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/time/player/name",playerData.cfg.name)
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/time/enemy/name",GameTextLoader:ReadText(enemyData.cfg.name))
    self:SetImageSprite("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/player/bg",playerData.cfg.iconBG)
    self:SetImageSprite("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/player/bg/icon",playerData.cfg.icon)
    self:SetImageSprite("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/enemy/bg",enemyData.cfg.iconBG)
    self:SetImageSprite("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/enemy/bg/icon",enemyData.cfg.icon)
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/match/player/txt",0)
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/match/enemy/txt",0)

    self:CreateTimer(100,function()
        gameData = FootballClubModel:GetPlayerGameData()
        local curTime = GameTimeManager:GetCurrentServerTime()
        if curTime - timePos >= totalDuration then
            local args = {true,playerData,enemyData, totalDuration, currState}
            self:ShowFCMatchResultBubble(args)
            self:StopTimer()
        end
        local curTimeMill = GameTimeManager:GetCurrentServerTimeInMilliSec() / 1000
        local gameProgressShow = (curTimeMill - timePos) * GAME_DURATION_SHOW / FootballClubModel.totalDuration
        local M = gameProgressShow // 60
        local S = math.floor(gameProgressShow % 60)
        if M < 10 then
            M = "0"..math.modf(M)
        end
        if S < 10 then
            S = "0"..math.modf(S)
        end
        self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/time/time/bg/time",M..":"..S)
      
        self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/match/player/txt",gameData.playerScore)
        self:SetText("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/match/enemy/txt",gameData.enemyScore)
        local slider = self:GetComp("FootballClubBumble/buildingInfo/matchBubble/matching/bg/time/player/Slider","Slider")
        local curSP = FootballClubModel:GetSP()
        slider.value = curSP/FCData.SPlimit
        --slider.value = FCData.SP/FCData.SPlimit
        local enemySlifer = self:GetComp("FootballClubBumble/buildingInfo/matchBubble/matching/bg/time/enemy/Slider","Slider")
        enemySlifer.value = 1 - 0.2*((curTime - timePos)/totalDuration)
        self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/player/buff/temp"):SetActive(curSP == 0)
        --self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching/bg/bg/info/player/buff/temp"):SetActive(FCData.SP == 0)
    end,true,true,true)

end

--显示比赛结果气泡
function FloatUIView:ShowFCMatchResultBubble(args)
    local active = args[1]
    local gameData = FootballClubModel:GetPlayerGameData()

    local playerData = gameData.playerData
    local enemyData = gameData.enemyData
    local currState = nil

    local waiting = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/waiting")
    local ready = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/ready")
    local matching = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching")
    local endNode = self:GetGo("FootballClubBumble/buildingInfo/matchBubble/end")

    self:CloseAllFCChildNodes()
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(active)
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble/matching"):SetActive(active)
    if not active then
        self:GetGo("FootballClubBumble"):SetActive(false)
        active = true
        return
    end
    waiting:SetActive(false)
    ready:SetActive(false)
    matching:SetActive(false)
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(true)
    self:GetGo("FootballClubBumble"):SetActive(true)
    endNode:SetActive(true)
    --播放动画
    if FootballClubController:CheckPlayFeelOnStateChange() then
        local feel = self:GetComp(endNode, "bg/openFB", "MMFeedbacks")
        feel:PlayFeedbacks()
    end

    currState = gameData
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/end/bg/bg/match/num/num1", currState.playerScore)
    self:SetText("FootballClubBumble/buildingInfo/matchBubble/end/bg/bg/match/num/num2", currState.enemyScore)

    --添加气泡点击事件
    self:SetButtonClickHandler(
        self:GetComp("FootballClubBumble/buildingInfo/matchBubble/end/bg", "Button"),
        function()
            local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][FootballClubModel.StadiumID]
            local roomName = buildCfg.objName
            FootballClubController:ClickStadium(FootballClubController.sceneGo[roomName].root, FootballClubModel.StadiumID)
        end
    )
end


--关闭所有FC的子节点
function FloatUIView:CloseAllFCChildNodes()
    self:GetGo("FootballClubBumble/buildingInfo/matchBubble"):SetActive(false)
    self:GetGo("FootballClubBumble/buildingInfo/trainningBubble"):SetActive(false)
    self:GetGo("FootballClubBumble/buildingInfo/renewalBubble"):SetActive(false)
end

function FloatUIView:PersonalDevNpcTalk(talkContent, type)
    local go = self.m_allGameObjects["ElectionBumble"]
    go:SetActive(true)
    local answerDispGo = self:GetGoOrNil(go, "AnswerBumble")
    if not answerDispGo then
        return
    end
    answerDispGo:SetActive(false)
    --玩家回答的气泡
    if type == 1 then
        if answerDispGo then
            self:SetText(answerDispGo, "bg/text", talkContent)
            answerDispGo:SetActive(true)
        end
    end
end

return FloatUIView