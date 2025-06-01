--[[
    个人发展个人信息UIView
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-23 14:59:57
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local GameResMgr = require("GameUtils.GameResManager")
local UnityHelper = CS.Common.Utils.UnityHelper

local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr

local PersonalDevModel = GameTableDefine.PersonalDevModel
local FlyIconsUI = GameTableDefine.FlyIconsUI

local PersonalInfoUIView = Class("PersonalInfoUIView", UIView)
local EventManager = require("Framework.Event.Manager")

function PersonalInfoUIView:ctor()
    self.super:ctor()
end

function PersonalInfoUIView:OnEnter()
    print("PersonalInfoUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("quitBtn", "Button"), function()
        FlyIconsUI:SetScenceSwitchEffect(1, function()
            GameTableDefine.MainUI:Hideing(true)
            self:DestroyModeUIObject()
            FlyIconsUI:SetScenceSwitchEffect(-1)
        end)
        
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/NamePanel/name/bg", "Button"), function()
        self:OpenRenameUI()
    end)
    self.campaginBtn = self:GetComp("RootPanel/InfoPanel/BtnArea/confbtn", "Button")
    EventManager:RegEvent(GameEventDefine.PersonalDev_EnergyCover, function()
        self.campaginBtn.interactable = PersonalDevModel:GetCurEnergy() >= ConfigMgr.config_global.energy_campaign
        self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num1", PersonalDevModel:GetCurEnergy())
        self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num2", ConfigMgr.config_global.energy_uplimit)
        if self:GetGo("energyPanel").isActive then
            self:RefreshEnergyPanelDisp()
        end
    end)
    self.energyPanel = self:GetGo("energyPanel")
    self.energyPanel:SetActive(false)
    self:SetText("BtnArea/energytank_Btn/bg/num/num", PersonalDevModel:GetCurEnergyTanks())
    self:SetButtonClickHandler(self:GetComp("BtnArea/energytank_Btn", "Button"), function()
        self.energyPanel:SetActive(true)
        self:RefreshEnergyPanelDisp()
    end)
    --设置玩家名字
    self:SetText("RootPanel/NamePanel/name/txt", LocalDataManager:GetBossName())
    --stage相关控件获取
    self.m_SupportSlider = self:GetComp("RootPanel/InfoPanel/prog/bg/Slider", "Slider")
    self.m_StageSlider = self:GetComp("PassBanner/Slider_part", "Slider")
    self.m_StageItemGos = {}
    table.insert(self.m_StageItemGos, self:GetGo("PassBanner/stage_part/stage/2"))
    table.insert(self.m_StageItemGos, self:GetGo("PassBanner/stage_part/stage/3"))
    table.insert(self.m_StageItemGos, self:GetGo("PassBanner/stage_part/stage/4"))
    table.insert(self.m_StageItemGos, self:GetGo("PassBanner/stage_part/final"))
    --设置精力值显示
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num1_normal", PersonalDevModel:GetCurEnergy())
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num1_low", PersonalDevModel:GetCurEnergy())
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num2", ConfigMgr.config_global.energy_uplimit)
    --设置玩家头衔名称
    -- if PersonalDevModel:GetTitle() > 0 then
    --     local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    --     if curDevCfg then
    --         local titleTxt = GameTextLoader:ReadText(curDevCfg.name)
    --         self:SetText("RootPanel/TitlePanel/name/txt", titleTxt)
    --     end
    --     self:SetText("RootPanel/TitlePanel/star/num", PersonalDevModel:GetTitle())
    --     --设置是否解锁了2号场景
    --     local islock200 = false
    --     self:GetGo("RootPanel/InfoPanel/prog"):SetActive(not islock200)
    --     local supportValue = PersonalDevModel:GetSupportCount()
    --     local nextDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle() + 1]
    --     local levelStageCfg = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1]
    --     if nextDevCfg and levelStageCfg then
    --         islock200 = PersonalDevModel:GetPersonalDevLocked(nextDevCfg.scene)
    --         --如果有stage配置的设置方式
    --         local curStageCfg = levelStageCfg[PersonalDevModel:GetStage()]
    --         if not curStageCfg then
    --             curStageCfg = levelStageCfg[PersonalDevModel:GetStage() - 1]
    --         end
    --         if curStageCfg and nextDevCfg.stage > 0 and nextDevCfg.stage == Tools:GetTableSize(levelStageCfg) then
    --             local supportMax = curStageCfg.suppertorcount_limit
    --             local progressValue = supportValue / supportMax
    --             if progressValue > 1 then
    --                 progressValue = 1
    --             end
    --             self.m_SupportSlider.value = progressValue
    --             self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", supportValue)
    --             self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", supportMax)
    --             --设置相关的Stage显示和按钮内容
    --         else
    --             self.m_SupportSlider.value = 0
    --             self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", 0)
    --             self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", 0)
    --         end
    --     else
    --         self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", supportValue)
    --         self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", supportValue)
    --         self.m_SupportSlider.value = 1
    --     end
    --     local stageProgressDisp = nextDevCfg and levelStageCfg and nextDevCfg.stage > 0
    --     self:GetGo("PassBanner"):SetActive(stageProgressDisp)
    --     self:GetGo("RootPanel/InfoPanel/BtnArea"):SetActive(stageProgressDisp and not islock200)
    --     self:GetGo("RootPanel/InfoPanel/none"):SetActive(not stageProgressDisp or islock200)
    --     local strBanner = "TXT_TITLE_TIP_1"  --不满足条件
    --     if not stageProgressDisp then
    --         strBanner = "TXT_TITLE_TIP_2"  --已经满级了
    --     end
    --     self:SetText("RootPanel/InfoPanel/none/txt", GameTextLoader:ReadText(strBanner))
    --     if stageProgressDisp then
    --         for i = 1, Tools:GetTableSize(self.m_StageItemGos) do
    --             if i > nextDevCfg.stage then
    --                 self.m_StageItemGos[5 - i]:SetActive(false)
    --             else
    --                 self.m_StageItemGos[5 - i]:SetActive(true)
    --                 local btn = self:GetComp(self.m_StageItemGos[5-i], "rewards", "Button")
    --                 if PersonalDevModel:GetCurStageRewardsInfo() == i then
    --                     btn.gameObject:SetActive(true)
    --                     btn.interactable = true
    --                     self:SetButtonClickHandler(btn, function()
    --                         if PersonalDevModel:ClaimCurStageRewards() then
    --                             self:RefreshPersonInfo()
    --                         end
    --                     end)
    --                 else
    --                     btn.gameObject:SetActive(false)
    --                     btn.interactable = false
    --                 end
    --             end
    --         end
    --         self.m_StageSlider.value = (PersonalDevModel:GetStage() - 1)/nextDevCfg.stage
    --     end
    --     self.campaginBtn.interactable = PersonalDevModel:GetCurEnergy() >= ConfigMgr.config_global.energy_campaign and self.m_SupportSlider.value >= 1 and PersonalDevModel:GetCurStageRewardsInfo() == 0
    -- end
    self:RefreshPersonInfo()
    self:SetButtonClickHandler(self.campaginBtn, function()
        if PersonalDevModel:ConsumEnergy(ConfigMgr.config_global.energy_campaign) then
            self.campaginBtn.interactable = false
            self:OpenCampaignUI()
        end
    end)
    self:SetButtonClickHandler(self:GetComp("BtnArea/affairs_Btn", "Button"), function()
        -- if PersonalDevModel:GetCurAffairLimit() > 0 then
            self:OpenAffairUI()
        -- end
    end)

    local dressUpBtn = self:GetComp("BtnArea/costume_Btn", "Button")
    if dressUpBtn then
        local isActive = dressUpBtn.gameObject.isActive
        self:SetButtonClickHandler(dressUpBtn, function()
            FlyIconsUI:SetScenceSwitchEffect(1, function()
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
                table.sort(data, function(a, b)
                    if a.first ~= b.first then
                        return a.first == false
                    else
                        return a.cfg.id < b.cfg.id
                    end
                end)
                if Tools:GetTableSize(data) <= 0 then
                    return
                end
                dressUpBtn.interactable = false
                local roomPath = "Assets/Res/UI/PersonDecorationUI.prefab" 
                GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(this)
                    -- local OverlayCamera = self:GetComp(this, "Overlay Camera", "Camera")            
                    -- self:SetCameraToMainCamera(OverlayCamera)
                    GameTableDefine.PersonInteractUI:OpenPersonInteractUI(data[1].cfg, this, ENUM_GAME_UITYPE.PERSONAL_INFO_UI)
                    -- self:GetGo("RootPanel/panel/TitlePanel/empBtn/icon"):SetActive(false)
                    -- self:Hideing()
                    dressUpBtn.interactable = true
                    self:DestroyModeUIObject()
                    FlyIconsUI:SetScenceSwitchEffect(-1)
                end)
            end)
            
        end)
    end
end

function PersonalInfoUIView:OpenAffairUI()
    if PersonalDevModel:GetAffairsQueue() <= 0 then
        return
    end
    if PersonalDevModel:GetTitle() < 3 then
        return
    end
    GameTableDefine.PersonalAffairUI:OpenAffairUI()
    self:DestroyModeUIObject()
end

function PersonalInfoUIView:OpenRenameUI()
    GameTableDefine.BenameUI:ReBossName(function()
        self:SetText("RootPanel/NamePanel/name/txt", LocalDataManager:GetBossName())
    end)
end

function PersonalInfoUIView:OnExit()
    if self.roomGo then
        GameObject.Destroy(self.roomGo)
        self.roomGo = nil
    end
    EventManager:UnregEvent(GameEventDefine.PersonalDev_EnergyCover)
    self.super:OnExit(self)
end

--设置相机的渲染将小场景的相机加在主相机上
function PersonalInfoUIView:SetCameraToMainCamera(OverlayCamera)
    local mainCamera = GameTableDefine.GameUIManager:GetSceneCamera()
    UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
end

function PersonalInfoUIView:OpenPersonalInfoUI()
    --加载对应的一个perfab
    local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not curDevCfg then
        self:DestroyModeUIObject()
        FlyIconsUI:SetScenceSwitchEffect(-1)
        return
    end
     
    local roomPath = curDevCfg.info_perfab
    GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(go)
        local OverlayCamera = self:GetComp(go, "Overlay Camera", "Camera")            
        self:SetCameraToMainCamera(OverlayCamera)
        self.roomGo = go
        local bossParentTran = UnityHelper.FindTheChild(self.roomGo, "PersonPos")
        local oldBossGo = UnityHelper.FindTheChild(bossParentTran.gameObject, "Boss_001")
        if oldBossGo then
            oldBossGo.gameObject:SetActive(false)
        end
        local bossEn = GameTableDefine.FloorMode:GetCurBossEntity()
        if bossEn and bossEn:GetEntityGo() then
            self.curBossGo = UnityHelper.CopyGameByGo(bossEn:GetEntityGo(), bossParentTran.gameObject)
            self.curBossGo.transform.localPosition = oldBossGo.localPosition
            self.curBossGo.transform.localScale = oldBossGo.localScale
            self.curBossGo.transform.rotation = oldBossGo.rotation
            self.curBossGo:SetActive(true)
            PersonalDevModel:ClearCopyGameObjectStage(self.curBossGo)
            local actionID = math.random(1001, 1004)
            local animator = self:GetComp(self.curBossGo, "", "Animator")
            animator:SetInteger("Action",actionID)
        end
        GameTableDefine.MainUI:Hideing()
        FlyIconsUI:SetScenceSwitchEffect(-1)
    end)
end

--打开竞选的界面
function PersonalInfoUIView:OpenCampaignUI()
    GameTableDefine.PersonalPromoteUI:OpenPersonPromoteUI()
    self:DestroyModeUIObject()
end

--刷新显示精力购买面板内容
function PersonalInfoUIView:RefreshEnergyPanelDisp(isUse)
    self:SetButtonClickHandler(self:GetComp("energyPanel/bg", "Button"), function()
        self.energyPanel:SetActive(false)
    end)
    --设置精力值显示
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num1_normal", PersonalDevModel:GetCurEnergy())
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num1_low", PersonalDevModel:GetCurEnergy())
    self:SetText("BtnArea/energytank_Btn/energyArea/bg/num/num/num2", ConfigMgr.config_global.energy_uplimit)
    self:SetText("BtnArea/energytank_Btn/bg/num/num", PersonalDevModel:GetCurEnergyTanks())
    self:SetText("energyPanel/info/content/bg/time/bg/num", PersonalDevModel:GetCurEnergyTanks())
    local useBtn = self:GetComp("energyPanel/info/content/bg/income/BtnArea/UseBtn", "Button")
    useBtn.interactable = PersonalDevModel:GetCurEnergyTanks() > 0
    self:SetButtonClickHandler(useBtn, function()
        if PersonalDevModel:GetCurEnergy() >= ConfigMgr.config_global.energy_uplimit then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_ENERGY_FULL"))
        else
            if PersonalDevModel:ConsumEnergyTank(1) then
                useBtn.interactable = false
                self:RefreshEnergyPanelDisp()
                self.energyPanel:SetActive(false)
            end
        end
        
    end)
    local buyBtn = self:GetComp("energyPanel/info/content/bg/income/BtnArea/BuyBtn", "Button")
    buyBtn.interactable = GameTableDefine.ResourceManger:GetDiamond() >= ConfigMgr.config_global.energy_tank_price
    self:SetButtonClickHandler(buyBtn, function()
        if GameTableDefine.ResourceManger:GetDiamond() >= ConfigMgr.config_global.energy_tank_price then
            buyBtn.interactable = false
            GameTableDefine.ResourceManger:SpendDiamond(ConfigMgr.config_global.energy_tank_price)
            PersonalDevModel:AddEnergyTanks(1)
            self:RefreshEnergyPanelDisp()
        end
    end)
end

function PersonalInfoUIView:RefreshPersonInfo()
    if PersonalDevModel:GetTitle() > 0 then
        local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
        if curDevCfg then
            local titleTxt = GameTextLoader:ReadText(curDevCfg.name)
            self:SetText("RootPanel/TitlePanel/name/txt", titleTxt)
        end
        self:SetText("RootPanel/TitlePanel/star/num", GameTableDefine.StarMode:GetStar())
        --设置是否解锁了2号场景
        local islock200 = false
        self:GetGo("RootPanel/InfoPanel/prog"):SetActive(not islock200)
        local supportValue = PersonalDevModel:GetSupportCount()
        local nextDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle() + 1]
        local levelStageCfg = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1]
        if nextDevCfg and levelStageCfg then
            islock200 = PersonalDevModel:GetPersonalDevLocked(nextDevCfg.scene)
            --如果有stage配置的设置方式
            local curStageCfg = levelStageCfg[PersonalDevModel:GetStage()]
            if not curStageCfg then
                curStageCfg = levelStageCfg[PersonalDevModel:GetStage() - 1]
            end
            if curStageCfg and nextDevCfg.stage > 0 and nextDevCfg.stage == Tools:GetTableSize(levelStageCfg) then
                local supportMax = curStageCfg.suppertorcount_limit
                local progressValue = supportValue / supportMax
                if progressValue > 1 then
                    progressValue = 1
                end
                self.m_SupportSlider.value = progressValue
                self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", supportValue)
                self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", supportMax)
                --设置相关的Stage显示和按钮内容
            else
                self.m_SupportSlider.value = 0
                self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", 0)
                self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", 0)
            end
        else
            self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num1", supportValue)
            self:SetText("RootPanel/InfoPanel/prog/bg/Slider/num/num2", supportValue)
            self.m_SupportSlider.value = 1
        end
        local stageProgressDisp = nextDevCfg and levelStageCfg and nextDevCfg.stage > 0
        local isNeedGetAward = PersonalDevModel:GetCurStageRewardsInfo() > 0
        self:GetGo("PassBanner"):SetActive(stageProgressDisp)
        self:GetGo("RootPanel/InfoPanel/BtnArea"):SetActive(stageProgressDisp and not islock200 and not isNeedGetAward)
        self:GetGo("RootPanel/InfoPanel/none"):SetActive(not stageProgressDisp or islock200 or isNeedGetAward)
        local strBanner = "TXT_TITLE_TIP_1"  --不满足条件
        if islock200 then
            strBanner = "TXT_TITLE_TIP_1"
        elseif not nextDevCfg then
            strBanner = "TXT_TITLE_TIP_2"  --已经满级了
        end
        if stageProgressDisp then
            local tempDispGo = {}
            for i = 1, Tools:GetTableSize(self.m_StageItemGos) do
                local doneGo = self:GetGoOrNil(self.m_StageItemGos[5 - i], "done")
                local rewardsGo = self:GetGoOrNil(self.m_StageItemGos[5 - i], "rewards")
                local normalGo = self:GetGoOrNil(self.m_StageItemGos[5 - i], "normal")
                doneGo:SetActive(false)
                rewardsGo:SetActive(false)
                normalGo:SetActive(true)
                if i > nextDevCfg.stage then
                    self.m_StageItemGos[5 - i]:SetActive(false)
                else
                    self.m_StageItemGos[5 - i]:SetActive(true)
                    table.insert(tempDispGo, self.m_StageItemGos[5-i])
                    local btn = self:GetComp(self.m_StageItemGos[5-i], "rewards", "Button")
                    btn.interactable = false
                    -- if PersonalDevModel:GetCurStageRewardsInfo() + nextDevCfg.stage == 5 - i then
                    --     btn.gameObject:SetActive(true)
                    --     btn.interactable = true
                        
                    --     self:SetButtonClickHandler(btn, function()
                    --         if PersonalDevModel:ClaimCurStageRewards() then
                    --             self:RefreshPersonInfo()
                    --         end
                    --     end)
                    -- else
                    --     btn.gameObject:SetActive(false)
                    --     btn.interactable = false
                    -- end
                end
            end
            local tmpCount = Tools:GetTableSize(tempDispGo)
            if PersonalDevModel:GetCurStageRewardsInfo() > 0 and PersonalDevModel:GetCurStageRewardsInfo() <= tmpCount then
                local btn = self:GetComp(tempDispGo[tmpCount - PersonalDevModel:GetCurStageRewardsInfo() + 1], "rewards", "Button")
                btn.gameObject:SetActive(true)
                btn.interactable = true
                self:SetButtonClickHandler(btn, function()
                    if PersonalDevModel:ClaimCurStageRewards() then
                        btn.gameObject:SetActive(false)
                        self:RefreshPersonInfo()
                    end
                end)
            end
            for _, index in ipairs(PersonalDevModel:GetCurClaimedStageRewards()) do
                local tmpIndex = tmpCount - index + 1
                if tmpIndex > 0 and tmpIndex <= tmpCount then
                    local doneGo = self:GetGoOrNil(tempDispGo[tmpIndex], "done")
                    local rewardsGo = self:GetGoOrNil(tempDispGo[tmpIndex], "rewards")
                    local normalGo = self:GetGoOrNil(tempDispGo[tmpIndex], "normal")
                    doneGo:SetActive(true)
                    rewardsGo:SetActive(false)
                    normalGo:SetActive(false) 
                end
            end
            self.m_StageSlider.value = (PersonalDevModel:GetStage() - 1)/nextDevCfg.stage
        end
        if isNeedGetAward then
            strBanner = "TXT_TITLE_TIP_3"
        end
        self:SetText("RootPanel/InfoPanel/none/txt", GameTextLoader:ReadText(strBanner))
        --三级以后才能进行事务处理
        self:GetGo("BtnArea/affairs_Btn"):SetActive(PersonalDevModel:GetTitle() >= 3)
        self.campaginBtn.interactable = PersonalDevModel:GetCurEnergy() >= ConfigMgr.config_global.energy_campaign and self.m_SupportSlider.value >= 1 and PersonalDevModel:GetCurStageRewardsInfo() <= 0
    end
    self:InitPersonTipsDisplay()
    self:SetText("RootPanel/InfoPanel/BtnArea/confbtn/num/num", tostring(ConfigMgr.config_global.energy_campaign))
end

function PersonalInfoUIView:InitPersonTipsDisplay()
    local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    local nextDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle() + 1]
    local isMaxLvl = false
    if not nextDevCfg then
        isMaxLvl = true
    end
    -- PersonalDevModel:GetDefineHeadIconStr(title)
    --先设置当前的显示
    --头像
    self:SetSprite(self:GetComp("HelpInfo_person/bg/now/bg/head/mask/icon", "Image"), "UI_Shop", PersonalDevModel:GetCurrHeadIconStr())
    self:SetSprite(self:GetComp("HelpInfo_person/bg/now/bg/level/icon", "Image"), "UI_Common", curDevCfg.title_icon)
    self:SetText("HelpInfo_person/bg/now/bg/title/txt", GameTextLoader:ReadText(curDevCfg.name))
    self:SetText("HelpInfo_person/bg/now/bg/affair/num/num", tostring(curDevCfg.affairs_limit))
    --TODO:后面添加房车等相关资源的数据
    if isMaxLvl then
        self:GetGo("HelpInfo_person/bg/next"):SetActive(false)
        self:GetGo("HelpInfo_person/bg/arrow"):SetActive(false)
    else
        self:GetGo("HelpInfo_person/bg/next"):SetActive(true)
        self:GetGo("HelpInfo_person/bg/arrow"):SetActive(true)
        self:SetSprite(self:GetComp("HelpInfo_person/bg/next/bg/head/mask/icon", "Image"), "UI_Shop", PersonalDevModel:GetDefineHeadIconStr(PersonalDevModel:GetTitle() + 1))
        self:SetSprite(self:GetComp("HelpInfo_person/bg/next/bg/level/icon", "Image"), "UI_Common", nextDevCfg.title_icon)
        self:SetText("HelpInfo_person/bg/next/bg/title/txt", GameTextLoader:ReadText(nextDevCfg.name))
        self:SetText("HelpInfo_person/bg/next/bg/affair/num/num", tostring(nextDevCfg.affairs_limit))
        --TODO:后面添加房车等相关资源的数据
    end
end

return PersonalInfoUIView