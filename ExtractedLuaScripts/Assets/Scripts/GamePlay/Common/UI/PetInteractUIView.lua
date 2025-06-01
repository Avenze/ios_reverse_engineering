local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local PetListUI = GameTableDefine.PetListUI
local BenameUI = GameTableDefine.BenameUI
local ConfigMgr = GameTableDefine.ConfigMgr
local PetInteractUI = GameTableDefine.PetInteractUI
local ChooseUI = GameTableDefine.ChooseUI
local MainUI = GameTableDefine.MainUI
local GuideManager = GameTableDefine.GuideManager
local ShopUI = GameTableDefine.ShopUI
local TimerMgr = GameTimeManager
local GameUIManager = GameTableDefine.GameUIManager
local ActivityUI = GameTableDefine.ActivityUI
local PetMode = GameTableDefine.PetMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
local Input = CS.UnityEngine.Input
local TouchPhase = CS.UnityEngine.TouchPhase

local PetInteractUIView = Class("PetInteractUIView", UIView)

function PetInteractUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function PetInteractUIView:OnEnter()
    local GuideData = LocalDataManager:GetDataByKey("guide_data")  
    --引导
    if not GuideData["done70"] then
        GuideManager.currStep = 700
        GuideManager:ConditionToStart()
        GuideManager:ConditionToEnd()
        GuideData["done70"] = true
    end    
    self:SetButtonClickHandler(self:GetComp("quitBtn","Button"), function()
        self:DestroyModeUIObject()
                
    end)            
end

function PetInteractUIView:OpenUI(cfg, this)
    self:Init(cfg.shopId)
    self.this = this 
    self:InitPetMods(cfg)  
    self:Refresh()           
    self:RefshList()      
end

function PetInteractUIView:Init(petId)
    self.petData = PetMode:GetPetLocalData(petId)
    self.cfgSnack = ConfigMgr.config_snack
    self.petId = petId
    --self.petFeedData = LocalDataManager:GetDataByKey("pet_feed")
    self.petRotateNum = 0    
end

function PetInteractUIView:Refresh()    
    if not self.selectedSnack then
        self.selectedSnack = 1001
    end
    local petData = PetMode:GetPetLocalData(self.petId)
    local cfg  = PetMode:GetPetCfgByPetId(self.petId)  
    --------------------------------------------------------------------------------------
    self:SetText("RootPanel/HeadPanel/name/txt", petData.name or GameTextLoader:ReadText(cfg.name))  
    self:SetText("RootPanel/statePanel/bg/level/num", petData.level)
    local isIncome = cfg.income ~= nil
    local isOffline = cfg.offline ~= nil
    local isMood =  cfg.mood ~= nil 
    self:GetGo("RootPanel/statePanel/bg/data/buff/income"):SetActive(isIncome)    
    self:GetGo("RootPanel/statePanel/bg/data/buff/offline"):SetActive(isOffline)    
    self:GetGo("RootPanel/statePanel/bg/data/buff/mood"):SetActive(isMood)      
    if isIncome then
        self:SetText("RootPanel/statePanel/bg/data/buff/income/num",  cfg.bonus_effect[petData.level] * 100 .. "%" )    
    elseif isOffline then
        self:SetText("RootPanel/statePanel/bg/data/buff/offline/num",  cfg.bonus_effect[petData.level])  
    elseif isMood then
        self:SetText("RootPanel/statePanel/bg/data/buff/mood/num",  cfg.bonus_effect[petData.level])         
    end
    local isLevelMax = petData.level >= #cfg.exp_limit + 1
    self:GetGo("RootPanel/statePanel/bg/data/bg"):SetActive(not isLevelMax)
    self:GetGo("RootPanel/statePanel/bg/data/max"):SetActive(isLevelMax)                   
    self:GetGo("RootPanel/snackPanel/info/bg/maxlvl"):SetActive(isLevelMax)     
    self:GetGo("RootPanel/snackPanel/info/bg/feedBtn"):SetActive(not isLevelMax) 
    self:GetGo("RootPanel/snackPanel/info/bg/shopBtn"):SetActive(not isLevelMax) 
    self:GetGo("RootPanel/snackPanel/info/bg/upgradeBtn"):SetActive(not isLevelMax)
    if isLevelMax then
        self:SetText("RootPanel/statePanel/bg/data/bg/exp/icon/lvl", "MAX")
        self:GetGo("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/icon"):SetActive(false)
        self:GetGo("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/IncreasedValue"):SetActive(false)
        self:GetGo("RootPanel/statePanel/bg/data/buff/income/VolumeUp/icon"):SetActive(false)
        self:GetGo("RootPanel/statePanel/bg/data/buff/income/VolumeUp/IncreasedValue"):SetActive(false)
        self:GetGo("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/icon"):SetActive(false)
        self:GetGo("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/IncreasedValue"):SetActive(false)
        local isIncome = cfg.income ~= nil
        local isOffline = cfg.offline ~= nil
        local isMood =  cfg.mood ~= nil
        self:SetText("RootPanel/statePanel/bg/data/buff/income/VolumeUp/OriginalValue", isIncome and cfg.bonus_effect[petData.level] * 100 .. "%" or cfg.bonus_effect[petData.level])
    else
        self:GetGo("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/icon"):SetActive(true)
        self:GetGo("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/IncreasedValue"):SetActive(true)
        self:GetGo("RootPanel/statePanel/bg/data/buff/income/VolumeUp/icon"):SetActive(true)
        self:GetGo("RootPanel/statePanel/bg/data/buff/income/VolumeUp/IncreasedValue"):SetActive(true)
        self:GetGo("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/icon"):SetActive(true)
        self:GetGo("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/IncreasedValue"):SetActive(true)
        local isIncome = cfg.income ~= nil
        local isOffline = cfg.offline ~= nil
        local isMood =  cfg.mood ~= nil
        if isIncome then
            self:SetText("RootPanel/statePanel/bg/data/buff/income/VolumeUp/OriginalValue", isIncome and cfg.bonus_effect[petData.level] * 100 .. "%" or cfg.bonus_effect[petData.level])
            self:SetText("RootPanel/statePanel/bg/data/buff/income/VolumeUp/IncreasedValue", isIncome and cfg.bonus_effect[petData.level + 1] * 100 .. "%" or cfg.bonus_effect[petData.level + 1])

        elseif isOffline then
            self:SetText("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/OriginalValue", isOffline and cfg.bonus_effect[petData.level] or cfg.bonus_effect[petData.level])
            self:SetText("RootPanel/statePanel/bg/data/buff/offline/VolumeUp/IncreasedValue", isOffline and cfg.bonus_effect[petData.level + 1] or cfg.bonus_effect[petData.level + 1])

        elseif isMood then
            self:SetText("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/OriginalValue", isIncome and cfg.bonus_effect[petData.level] or cfg.bonus_effect[petData.level])
            self:SetText("RootPanel/statePanel/bg/data/buff/mood/VolumeUp/IncreasedValue", isIncome and cfg.bonus_effect[petData.level + 1] or cfg.bonus_effect[petData.level + 1])

        end

        local bgRoot = self:GetGo("RootPanel/statePanel/bg/data/bg")
        self:GetGo("RootPanel/statePanel/bg/data/max"):SetActive(false)
        local hungrySlider = self:GetComp(bgRoot, "hunger/info/progress", "Slider")
        local experienceSlider = self:GetComp(bgRoot, "exp/info/progress", "Slider")
        --实时刷新的部分
        self:CreateTimer(1000, function()
            local isNoNextExp = false
            if not cfg.exp_limit[petData.level] then
                isNoNextExp = true
            end
            hungrySlider.value = petData.hungry / cfg.max_hungry
            if isNoNextExp then
                experienceSlider.value = 1
            else
                experienceSlider.value = petData.experience / cfg.exp_limit[petData.level]
            end
            
            self:SetText(bgRoot, "hunger/info/progress/pro", math.floor(petData.hungry/cfg.max_hungry * 10000)/100 .. "%") 
            self:SetText(bgRoot, "exp/info/progress/pro", math.floor(experienceSlider.value * 10000)/100 .. "%")
            local hungryDisp = petData.hungry
            if hungryDisp > cfg.max_hungry then
                hungryDisp = cfg.max_hungry
            end
            self:SetText(bgRoot, "hunger/info/time", hungryDisp .. "/" .. cfg.max_hungry)        
            if petData.hungry == 0 then
                self:SetText(bgRoot, "exp/info/num", "+0/s")
            else            
                self:SetText(bgRoot, "exp/info/num", "+" .. PetInteractUI:ExpSpeed(cfg.shopId) .. "/s") 
            end

            if not isNoNextExp then
                self:SetText("RootPanel/statePanel/bg/data/bg/exp/info/num", math.floor(petData.experience) ..  "/" .. math.floor(cfg.exp_limit[petData.level]))
            end
            self:SetText("RootPanel/statePanel/bg/data/bg/exp/icon/lvl", "Lv" .. petData.level)
            local expBuffRemain = PetInteractUI:GetExpBuffRemain(cfg.shopId)
            local showBuffInfo = expBuffRemain and expBuffRemain > 0
            if showBuffInfo then
                self:SetText("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_basedata", "+" .. string.format("%.1f", ConfigMgr.config_global.pet_exp_basespeed) .. "/s")
                self:SetText("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_adddata", "+" .. string.format("%.1f", PetInteractUI:ExpSpeed(cfg.shopId) - ConfigMgr.config_global.pet_exp_basespeed) .. "/s")
                self:SetText("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_remainder", "(" .. GameTimeManager:FormatTimeLength(expBuffRemain) .. ")")
            end
            self:GetGo("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_basedata"):SetActive(showBuffInfo)
            self:GetGo("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_adddata"):SetActive(showBuffInfo)
            self:GetGo("RootPanel/statePanel/bg/data/bg/exp/info/num/ExpValue/num_remainder"):SetActive(showBuffInfo)
            
        end, true, true, true)
        
        local fillImage = self:GetComp(bgRoot, "exp/info/progress/FillArea/Fill", "Image")
        local pitchImage = self:GetComp(bgRoot, "exp/info/progress/FillArea/Fill/Pitch", "Image")
        if petData.hungry > 0 then
            fillImage.color  = UnityHelper.GetColor("#67BF94")
            pitchImage.color  = UnityHelper.GetColor("#87DFB4")
        else
            fillImage.color  = UnityHelper.GetColor("#A3A8A6")
            pitchImage.color  = UnityHelper.GetColor("#BCBFBE")
        end
        self:GetGo("RootPanel/snackPanel/info/bg/upgradeBtn"):SetActive(petData.experience >= cfg.exp_limit[petData.level] and petData.level < #cfg.exp_limit + 1)
        local petFeedCount = PetMode:GetPetFeed(tostring(self.selectedSnack))
        self:GetGo("RootPanel/snackPanel/info/bg/feedBtn"):SetActive(petFeedCount > 0)
        self:GetGo("RootPanel/snackPanel/info/bg/shopBtn"):SetActive(petFeedCount <= 0)
        --self:GetGo("RootPanel/snackPanel/info/bg/feedBtn"):SetActive(self.petFeedData[tostring(self.selectedSnack)] and self.petFeedData[tostring(self.selectedSnack)] > 0)
        --self:GetGo("RootPanel/snackPanel/info/bg/shopBtn"):SetActive(not self.petFeedData[tostring(self.selectedSnack)] or self.petFeedData[tostring(self.selectedSnack)] <= 0)
    end            
    --------------------------------------------------------------------------------------                    
    local icon = self:GetComp("RootPanel/snackPanel/info/bg/icon", "Image")    
    self:SetSprite(icon, "UI_Shop", self.cfgSnack[self.selectedSnack].icon, nil, true)   
    self:SetText("RootPanel/snackPanel/info/bg/name", GameTextLoader:ReadText(self.cfgSnack[self.selectedSnack].name))
    self:SetText("RootPanel/snackPanel/info/bg/desc", string.format(GameTextLoader:ReadText(self.cfgSnack[self.selectedSnack].desc), math.floor( self.cfgSnack[self.selectedSnack].exp_duration / 60)))
    self:SetText("RootPanel/snackPanel/info/bg/property/hunger/num", "+" .. self.cfgSnack[self.selectedSnack].hunger_add)
    self:SetText("RootPanel/snackPanel/info/bg/property/exp/num", "+" .. self.cfgSnack[self.selectedSnack].exp_add/100 .. "/s")
    --self:SetText("RootPanel/snackPanel/info/bg/property/duration/num", self.cfgSnack[self.selectedSnack].exp_add .. "s")            
    
    --local iconExp = self:GetComp("RootPanel/snackPanel/info/bg/property/exp/icon", "Image") 
    --if self.selectedSnack == 1001 then
    --    self:SetSprite(iconExp, "UI_Shop", "icon_snack_exp_1", nil, true) 
    --elseif self.selectedSnack == 1002 then
    --    self:SetSprite(iconExp, "UI_Shop", "icon_snack_exp_2", nil, true) 
    --elseif self.selectedSnack ==1003 then
    --    self:SetSprite(iconExp, "UI_Shop", "icon_snack_exp_3", nil, true)             
    --end
    --                
    --向左按钮
    self:SetButtonClickHandler(self:GetComp("leftBtn", "Button"), function()
        local newcfg = self:ChoosePet(true)
        self:OpenUI(newcfg, self.this)
    end)
    --向右按钮
    self:SetButtonClickHandler(self:GetComp("rightBtn", "Button"), function()
        local newcfg = self:ChoosePet(false)        
        self:OpenUI(newcfg, self.this)
    end)
    --改名按钮
    self:SetButtonClickHandler(self:GetComp("RootPanel/HeadPanel/name/renameBtn", "Button"), function()
        BenameUI:RePetName(self.petId, function()
            self:Refresh()
            PetListUI:RefreshPetList()
        end)
    end)
    --投喂按钮
    self:SetButtonClickHandler(self:GetComp("RootPanel/snackPanel/info/bg/feedBtn", "Button"), function()
        if petData.hungry + self.cfgSnack[self.selectedSnack].hunger_add <= cfg.max_hungry then
            PetInteractUI:FeedPet(self.petId, self.selectedSnack, function (isSuccess)
                if isSuccess then                
                    self:PlayPetAnimation(self.petMod,"feed")
                    self:RefshPetList()
                    EventManager:DispatchEvent("FEED_PET")
                    GameSDKs:TrackForeign("pet_record", {id = self.petId, level_new = tonumber(petData.level) or 0, operation_type = 1})
                end
            end)  
        else
           ChooseUI:Choose("TXT_TIP_PET_FEED", function ()
                PetInteractUI:FeedPet(self.petId, self.selectedSnack, function (isSuccess)
                    if isSuccess then                
                        self:PlayPetAnimation(self.petMod,"feed")
                        self:RefshPetList()
                        self:Refresh(self.petId)
                        self.m_list:UpdateData()
                        EventManager:DispatchEvent("FEED_PET")
                        GameSDKs:TrackForeign("pet_record", {id = self.petId, level = petData.level, operation_type = 1})
                    end
                end)
           end)
        end        
        self:Refresh(self.petId)
        self.m_list:UpdateData()        
    end)
    --商城按钮
    self:SetButtonClickHandler(self:GetComp("RootPanel/snackPanel/info/bg/shopBtn", "Button"), function()
        ShopUI:TurnTo(1074)
        GameSDKs:TrackForeign("pet_record", {id = tostring(self.petId), level = petData.level, operation_type = 3})
    end)
    --换装按钮
    self:SetButtonClickHandler(self:GetComp("skinBtn", "Button"), function()
        
    end)
    --升级按钮
    self:SetButtonClickHandler(self:GetComp("upgradeBtn", "Button"), function()
        PetInteractUI:Upgrade(self.petId)
        self:Refresh(self.petId)
        MainUI:RefreshCashEarn()
        self:PlayPetAnimation(self.petMod,"upGrade")
        self:RefshPetList()
        GameSDKs:TrackForeign("pet_record", {id = self.petId, level = petData.level, operation_type = 2})
    end)
end

--赋值宠物模型
function PetInteractUIView:InitPetMods(cfg)
    local parent = self:GetGo(self.this, "PetPos") 
    for k,v in pairs(parent.transform) do
        GameObject.Destroy(v.gameObject)
    end
    local string = cfg.prefab .. "_show"
    local petPath = "Assets/Res/Prefabs/Animals/".. string ..".prefab"
    GameResMgr:AInstantiateObjectAsyncManual(petPath, self, function(this)
        UnityHelper.AddChildToParent(parent.transform, this.transform)
        this.transform.localScale  = this.transform.localScale * cfg.show
        self.petMod = this
        local animator = self:GetComp(this,"","Animator")
        if animator and not animator:IsNull() then
            animator:Update()
        end
        -- this.transform.parent = parent.transform
        -- this.transform.position = parent.transform.position
        -- this.transform.rotation = parent.transform.rotation
        -- local A = this.transform.localScale.oneVector 
        -- this.transform.localScale  =   A * cfg.scale        
    end)
end

function PetInteractUIView:RefshList()
    self.m_list = self:GetComp("RootPanel/snackPanel/list", "ScrollRectEx")    

    self:SetListItemCountFunc(self.m_list, function()        
        return Tools:GetTableSize(self.cfgSnack)
    end)
     self:SetListItemNameFunc(self.m_list, function(index)       
        return "Item"
    end)    
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateList))
    
    self.m_list:UpdateData()
end

function PetInteractUIView:UpdateList(index, tran)
    index = index + 1
    local go = tran.gameObject  
    local icon = self:GetComp(go,"Btn/normal/icon", "Image")
    self:SetSprite(icon, "UI_Shop", self.cfgSnack[1000 + index].icon, nil, true)
    local num = PetMode:GetPetFeed(tostring(index + 1000))
    --local num = self.petFeedData[tostring(index + 1000)]
    if not num then
        num = 0
    end
    self:SetText(go, "Btn/normal/img/num", num)
    self:SetButtonClickHandler(self:GetComp(go, "Btn", "Button"), function()
        self.selectedSnack = index + 1000
        self:Refresh(self.petId)
        self.m_list:UpdateData()
    end)
    self:GetGo(go, "Btn/normal/selected"):SetActive(self.selectedSnack - 1000 == index)
end

--播发宠物的动画
function PetInteractUIView:PlayPetAnimation(petMod,type)
    local animator = self:GetComp(petMod, "", "Animator")
    --local audioSource = self:GetComp(petMod, "", "AudioSource")    
    if type == "feed" then
        AnimationUtil.AddKeyFrameEventOnObj(petMod, "FEED_END", function()
            animator:SetInteger("Action",1)
		end)
        animator:SetInteger("Action",3)
        local feedBack = self:GetComp(self.this, "feedFeedback" ,"MMFeedbacks")
        feedBack:PlayFeedbacks()
        --audioSource:Play()
        --self:BackToIdle(7)
    elseif type == "upGrade" then
        animator:SetInteger("Action",7)
        local feedBack = self:GetComp(self.this, "upgradeFeedback" ,"MMFeedbacks")
        feedBack:PlayFeedbacks()  
        --audioSource:Play()
        self:BackToIdle(3)
    end
end
--回归IDLE动画
-- function PetInteractUIView:BackIdle()
--     local animator = self:GetComp(self.petMod, "", "Animator")
--     if not animator then
--         return
--     end
--     -- 0 表示的动画层Layer为 0
--     local state = animator:GetCurrentAnimatorStateInfo(0)
--     local bool = state:IsName("Idle")
--     if not state.normalizedTime then
--         return
--     end
--     if not bool and state.normalizedTime >= 1 then
--         animator:SetInteger("Action",1)
--     end
-- end
--回归Idle
function PetInteractUIView:BackToIdle(type)
    local animator = self:GetComp(self.petMod, "", "Animator")
    local clips = animator.runtimeAnimatorController.animationClips
    local length = clips[type].length - 0.1
    self.backIdle = 
    GameTimer:CreateNewMilliSecTimer(length * 1000, function()       
        if  GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_INTERACT_UI) and self.petMod and animator then
            animator = self:GetComp(self.petMod, "", "Animator")  
            animator:SetInteger("Action",1) 
        end                    
    end, false, false)
end

--左右选择的方法() direction 为 true 为左减, 为 false 为右加
function PetInteractUIView:ChoosePet(direction)
    GameTimer:StopTimer(self.backIdle)
    if animator then animator:Stop() end
    local list = PetListUI:GetPets()
    local num 
    for k,v in pairs(list) do
        if self.petId == tonumber(v) then
            num = k
            break
        end
    end
    if direction then
        if num == 1 then
            num = list[#list]
        else
            num = list[num - 1]
        end
    else
        if num == #list then
            num = list[1]
        else
            num = list[num + 1]
        end
    end
    return PetMode:GetPetCfgByPetId(num)
end

--刷新petlist
function PetInteractUIView:RefshPetList()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_LIST_UI) then
        --local petListUIView = PetListUI:GetView()
        --if petListUIView and petListUIView.m_list then
        --    petListUIView.m_list:UpdateData()
        --end
        PetListUI:RefreshFeed()
        PetListUI:RefreshPetList()
        PetListUI:RefreshEmployee()
    end 
end

-- 滑行屏幕旋转宠物操作
-- function PetInteractUIView:SlidePet()    
--     local distance = 10 
--     self.slideTime = GameTimer:CreateNewMilliSecTimer(50, function()
--         if math.abs(self.petRotateNum) > 5 then
--             local speed = math.abs(self.petRotateNum/(2 * 3))
--             if self.petRotateNum > 0 then
--                 self.petRotateNum = self.petRotateNum  - speed
--                 if not self.petMod then return end     
--                 self.petMod.transform:Rotate(Vector3.up * speed * 1)
--             else
--                 self.petRotateNum = self.petRotateNum  + speed
--                 if not self.petMod then return end     
--                 self.petMod.transform:Rotate(Vector3.up * speed * -1)
--             end                         
--         end 
--     end, true, true)
-- end

-- --检测鼠标的位移量用于旋转的计算
-- function PetInteractUIView:CalculateMouseDisplacement()
--     local starFingerPos
--     local endFingerPos
--     local Distance
--     local cd = 100
--     self.mouseTime = GameTimer:CreateNewMilliSecTimer(10, function()
--         cd = cd - 1
--         if cd <= 0 then
--             starFingerPos = nil
--         end  
--         if Input.GetMouseButtonDown(0) then
--             starFingerPos = Input.mousePosition
--             cd = 100            
--         end
--         if starFingerPos and Input.mousePosition then
--             Distance = starFingerPos.x - Input.mousePosition.x
--         end
--         if starFingerPos and math.abs(Distance) > 100 then
--             if Distance * self.petRotateNum >= 0 then
--                 self.petRotateNum = self.petRotateNum + Distance                
--             else
--                 self.petRotateNum = Distance
--             end                        
--             starFingerPos = Input.mousePosition
--         end
--         if Input.GetMouseButtonUp(0) then
--             starFingerPos = nil      
--         end   
--         -- if starFingerPos and endFingerPos then            
--         --     Distance = Vector3.Distance(starFingerPos, endFingerPos)
--         --     if  Distance >= 100 then                
--         --         starFingerPos = nil
--         --         endFingerPos = nil
--         --         Distance = nil
--         --     end
--         -- end
        
--         -- cd = cd - 1
--         -- if cd <= 0 then
--         --     starFingerPos = nil
--         --     endFingerPos = nil
--         --     Distance = nil
--         -- end
--     end, true, true)
-- end

function PetInteractUIView:OnExit()
    GameTimer:StopTimer(self.backIdle)
    GameObject.Destroy(self.this)
    self.this = nil
    MainUI:Hideing(true)
    PetListUI:Hideing(true)
	self.super:OnExit(self)
end

return PetInteractUIView