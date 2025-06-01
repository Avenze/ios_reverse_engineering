--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:11:12
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper
local GlintingManager = CS.Common.Utils.GlintingManager.Instance

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local CycleNightClubHeroManager = GameTableDefine.CycleNightClubHeroManager
local ChooseUI = GameTableDefine.ChooseUI
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourcesManager = GameTableDefine.ResourceManger
local CycleNightClubMainViewUI = GameTableDefine.CycleNightClubMainViewUI
local CycleNightClubBuildingUI = GameTableDefine.CycleNightClubBuildingUI
local GameTimeManager = GameTimeManager
local GameTimer = GameTimer
local FlyIconsUI = GameTableDefine.FlyIconsUI
local BluePrintManager = GameTableDefine.CycleNightClubBluePrintManager

local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil
local ResEnoughColor = UnityHelper.GetColor("#FFFFFF")
local CashNotEnoughColor = UnityHelper.GetColor("#FF6262")
local ExpNotEnoughColor = UnityHelper.GetColor("#FF6262")
local GuideManager = GameTableDefine.GuideManager

---@class CycleNightClubBuildingUIView :UIBaseView
local CycleNightClubBuildingUIView = Class("CycleNightClubBuildingUIView", UIView)

function CycleNightClubBuildingUIView:ctor()
    self.super:ctor()
    self.m_data = {}

    self.RoomTitlePanel = nil
    self.RoomInfoPanel = nil
    self.BG = nil
    self.RoomCarteen = nil
    self.RoomDormitory = nil

    self.matierial = nil
    self.matierial_1 = nil
    self.matierialImage = nil
    self.stuckIcon = nil
    --self.resourceImage = nil
    self.furImage = nil
    self.progressSlider = nil
    self.progressProductImage = nil
    self.progressBonus = nil
    self.progressBonusNumText = nil
    self.progressEmployee = nil
    self.progressResouce = nil
    self.progressResouceImage = nil
    self.upgradeMaxlvl = nil
    self.upgradeBtnGO = nil
    self.feel = nil
    self.upgradeBtn = nil
    self.employeeItem = nil
    self.animator = nil
    self.cameraFocus = nil
    self.m_employeeIconImage = nil ---@type UnityEngine.UI.Image
    self.m_employeeTempOnImage = nil ---@type UnityEngine.UI.Image
    self.m_employeeTempOffImage = nil ---@type UnityEngine.UI.Image
    
    self.UItype = nil    --1是工厂,2是补给,3是港口

    self.m_currentInstanceModel = nil ---@type CycleNightClubModel
    self.m_workerIconImage = nil ---@type UnityEngine.UI.Image
    --家具
    self.m_furLevelCashNow = nil ---@type UnityEngine.UI.Text
    self.m_lastFurUpgradePressTipTime = nil ---上次触发家具升级提示(缺钱或需要升级房间)的时间
    --新英雄(配方)UI
    self.m_heroIconImage = nil ---@type UnityEngine.UI.Image
    self.m_heroNameText =  nil ---@type UnityEngine.UI.Text
    self.m_heroLevelText =  nil ---@type UnityEngine.UI.Text
    self.m_heroUpgradeCostText =  nil ---@type UnityEngine.UI.Text
    self.m_heroUpgradeResNowText =  nil ---@type UnityEngine.UI.Text
    self.m_heroUpgradeBtn =  nil ---@type UnityEngine.UI.Button
    self.m_heroMaxGO =  nil ---@type UnityEngine.GameObject
    self.m_heroCurMagnificationText =  nil ---@type UnityEngine.UI.Text
    self.m_heroNextMagnificationText =  nil ---@type UnityEngine.UI.Text
    self.m_heroProductionIconImage = nil ---@type UnityEngine.UI.Image
    self.m_heroTextAnimator = nil ---@type UnityEngine.Animator
    --房间升级
    self.m_roomUpgradeShowPanelNormalBtn = nil ---@type UnityEngine.UI.Button -平常状态
    self.m_roomUpgradeShowPanelUpgradeBtn = nil ---@type UnityEngine.UI.Button -可升级房间状态
    self.m_roomUpgradeShowPanelMaxBtn =  nil ---@type UnityEngine.UI.Button -房间升满时的状态
    self.m_roomUpgradePanelBtn = nil ---@type UnityEngine.UI.Button
    self.m_roomUpgradePanelCostCashText = nil ---@type UnityEngine.UI.Text
    self.m_roomUpgradePanelCostTimeText = nil ---@type UnityEngine.UI.Text
    self.m_roomUpgradePanelGO = nil ---@type UnityEngine.GameObject
    self.m_roomUpgradeRemainingTimeText = nil ---@type UnityEngine.UI.Text
    self.m_roomUpgradeSkipBtn = nil ---@type UnityEngine.UI.Button
    self.m_roomUpgradeSkipCostText = nil ---@type UnityEngine.UI.Text
    self.m_roomUpgradeTimeSlider = nil ---@type UnityEngine.UI.Slider
    self.m_roomUpgradePanelCoinNotEnoughGO = nil ---@type UnityEngine.GameObject -房间升级钱不够时显示
    self.m_roomUpgradeFurLevelSlider = nil ---@type UnityEngine.UI.Slider -家具等级到可以升级房间的进度
    self.m_personTalkTalkGO = nil ---@type UnityEngine.GameObject -员工对话气泡,显示房间升级后关闭
    self.m_personTalkText = nil ---@type UnityEngine.UI.Text
    self.m_roomLevelText = nil ---@type UnityEngine.UI.Text
    self.m_personTalkBtn = nil ---@type UnityEngine.UI.Button

    self.m_isShowUpgradePanel = nil ---@type boolean -是否应该打开升级界面
    self.m_notPlayExitCameraMove = false ---不要播放退出时的还原镜头

    self.m_glintingTimer = nil
    self.m_glintingStopTime = nil

    --对话
    self.m_haveTalkContent = false ---@type boolean -是否有要显示的对话内容(强制显示的引导提示)
    self.m_personTalkRandomTxt = nil ---显示的随机对话内容
    self.m_personTalkHideTime = 0 ---什么时候关闭显示
    self.m_personTalkRandomIndex = 0 ---上次显示的随机文字，这次不能和上次一样
    --self.m_personTalkFeedback = nil ---@type MoreMountains.Feedbacks.MMFeedback
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local isOpen = false

function CycleNightClubBuildingUIView:OnEnter()

    self.m_currentInstanceModel = CycleInstanceDataManager:GetCurrentModel()

    roomsConfig = self.m_currentInstanceModel.roomsConfig
    furnitureLevelConfig = self.m_currentInstanceModel.furnitureLevelConfig
    furnitureConfig = self.m_currentInstanceModel.furnitureConfig
    resConfig = self.m_currentInstanceModel.resourceConfig

    self.m_haveTalkContent = false

    self.RoomTitlePanel = self:GetGo("RootPanel/RoomInfo")
    self.RoomInfoPanel = self:GetGo("RootPanel/RoomTitle")
    self.BG = self:GetGo("RootPanel/bg")
    self.RoomCarteen = self:GetGo("RootPanel/RoomCarteen")
    self.RoomDormitory = self:GetGo("RootPanel/RoomDormitory")

    self.matierial = self:GetGo("RootPanel/RoomInfo/product/bg/matierial")
    self.matierial_1 = self:GetGo("RootPanel/RoomInfo/product/bg/1")
    self.matierialImage = self:GetComp("RootPanel/RoomInfo/product/bg/matierial/logo", "Image")
    self.stuckIcon = self:GetGo("RootPanel/RoomInfo/product/bg/matierial/stuckIcon")
    --self.resourceImage = self:GetComp("RootPanel/RoomInfo/product/bg/production/type/resource", "Image")
    self.furImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/icon", "Image")
    self.progressSlider = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress", "Slider")
    self.progressProductImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/bonus/icon", "Image")
    self.progressBonus = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/bonus")
    self.progressBonusNumText = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/bonus/num","TMPLocalization")
    self.progressEmployee = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/effect/employee")
    self.progressResouce = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce")
    self.progressResouceImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce", "Image")
    self.upgradeMaxlvl = self:GetGo("RootPanel/RoomInfo/upgrade/bg/maxlvl")
    self.upgradeBtnGO = self:GetGo("RootPanel/RoomInfo/upgrade/bg/btn")
    self.feel = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/Fill Area/Fill/vfx/fb", "MMFeedbacks")
    self.upgradeBtn = self:GetComp("RootPanel/RoomInfo/upgrade/bg/btn", "ButtonEx")
    self.employeeItem = self:GetGo("RootPanel/RoomInfo/employee/bg/Temp")
    self.animator = self:GetComp("RootPanel/RoomInfo/workstate/bg/toggle", "Animator")
    self.cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    self.m_employeeIconImage = self:GetComp("RootPanel/RoomInfo/employee/icon_bg/Icon","Image")
    self.m_employeeTempOffImage = self:GetComp("RootPanel/RoomInfo/employee/bg/Temp/off","Image")
    self.m_employeeTempOnImage = self:GetComp("RootPanel/RoomInfo/employee/bg/Temp/on","Image")

    self.m_workerIconImage = self:GetComp("RootPanel/PersonTalk/icon","Image")
    --家具
    self.m_furLevelCashNow = self:GetComp("RootPanel/RoomInfo/upgrade/bg/btn/cash/now/num","TMPLocalization")
    --新英雄(配方)UI
    self.m_heroIconImage = self:GetComp("RootPanel/RoomInfo/workstate/bg/icon_bg/icon","Image")
    self.m_heroNameText = self:GetComp("RootPanel/RoomInfo/workstate/bg/name","TMPLocalization")
    self.m_heroLevelText = self:GetComp("RootPanel/RoomInfo/workstate/bg/level/num","TMPLocalization")
    self.m_heroUpgradeCostText = self:GetComp("RootPanel/RoomInfo/workstate/bg/btn/cash/cost/num","TMPLocalization")
    self.m_heroUpgradeResNowText = self:GetComp("RootPanel/RoomInfo/workstate/bg/btn/cash/now/num","TMPLocalization")
    self.m_heroUpgradeBtn = self:GetComp("RootPanel/RoomInfo/workstate/bg/btn","ButtonEx")
    self.m_heroMaxGO = self:GetGo("RootPanel/RoomInfo/workstate/bg/maxlvl")
    self.m_heroCurMagnificationText = self:GetComp("RootPanel/RoomInfo/workstate/bg/bonus/num1","TMPLocalization")
    self.m_heroNextMagnificationText = self:GetComp("RootPanel/RoomInfo/workstate/bg/bonus/maxBonus/num2","TMPLocalization")
    self.m_heroProductionIconImage = self:GetComp("RootPanel/RoomInfo/workstate/bg/bonus/icon", "Image")
    self.m_heroTextAnimator = self:GetComp("RootPanel/RoomInfo/workstate/bg/bonus","Animator")

    --房间升级
    self.m_roomUpgradeInfoGO = self:GetGo("RootPanel/updataRoom/info")
    self.m_roomUpgradeSkipInfoGO = self:GetGo("RootPanel/updataRoom/skipInfo")
    self.m_roomUpgradeShowPanelNormalBtn = self:GetComp("RootPanel/RoomTitle/HeadPanel/btn","Button")
    self.m_roomUpgradeShowPanelUpgradeBtn = self:GetComp("RootPanel/RoomTitle/HeadPanel/upgradeBtn","Button")
    self.m_roomUpgradeShowPanelMaxBtn = self:GetComp("RootPanel/RoomTitle/HeadPanel/maxBtn","Button")
    self.m_roomUpgradePanelBtn = self:GetComp("RootPanel/updataRoom/info/btn","Button")
    self.m_roomUpgradePanelCostCashText = self:GetComp("RootPanel/updataRoom/info/matierial/costIcon/count/needNum","TMPLocalization")
    self.m_roomUpgradePanelHaveCashText = self:GetComp("RootPanel/updataRoom/info/matierial/costIcon/count/haveNum","TMPLocalization")
    self.m_roomUpgradePanelCostTimeText = self:GetComp("RootPanel/updataRoom/info/matierial/costTimeIcon/time/num","TMPLocalization")
    self.m_roomUpgradePanelGO = self:GetGo("RootPanel/updataRoom")
    self.m_roomUpgradeRemainingTimeText = self:GetComp("RootPanel/updataRoom/skipInfo/prog/FillArea/timer","TMPLocalization")
    self.m_roomUpgradeSkipBtn = self:GetComp("RootPanel/updataRoom/skipInfo/SkipBtn","Button")
    self.m_roomUpgradeSkipCostText = self:GetComp("RootPanel/updataRoom/skipInfo/SkipBtn/cost","TMPLocalization")
    self.m_roomUpgradeTimeSlider = self:GetComp("RootPanel/updataRoom/skipInfo/prog/FillArea","Slider")
    self.m_roomUpgradeFurLevelSlider = self:GetComp("RootPanel/RoomTitle/progress","Slider")
    self.m_personTalkTalkGO = self:GetGo("RootPanel/PersonTalk/talk")
    self.m_personTalkText = self:GetComp("RootPanel/PersonTalk/talk/content","TMPLocalization")
    self.m_roomUpgradePanelCoinNotEnoughGO = self:GetGoOrNil("RootPanel/updataRoom/info/btn/disabled")
    self.m_roomLevelText = self:GetComp("RootPanel/RoomTitle/HeadPanel/title/levelNum","TMPLocalization")
    self.m_personTalkBtn = self:GetComp("RootPanel/PersonTalk","Button")
    --self.m_personTalkFeedback = self:GetComp("RootPanel/PersonTalk/talk/content/openFB","MMFeedbacks")
    --家具等级奖励,每升到一定的值自动获取一次升级奖励。
    local rewardParent = self:GetGo("RootPanel/RoomTitle/progress/milepointIcons")
    self.m_furLevelRewardGOs = {}
    for i = 1, 3 do
        self.m_furLevelRewardGOs[i] = self:GetGo(rewardParent,"icon_"..i)
    end

    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)

    self:SetButtonClickHandler(self.m_heroUpgradeBtn,function()
        if self:OnHeroUpgradeBtnDown(true) then
            self.m_heroTextAnimator:Play("speed1",0,0.0)
        end
    end)

    self:SetButtonHoldHandler(self.m_heroUpgradeBtn,function()
        if self:OnHeroUpgradeBtnDown(false) then
            self.m_heroTextAnimator:Play("speed2",0,0.0)
        end
    end, nil, 0.4, 0.13)

    self:SetButtonClickHandler(self.m_roomUpgradeShowPanelNormalBtn,function()
        self:InitUpgradePanel(true)
    end)
    self:SetButtonClickHandler(self.m_roomUpgradeShowPanelUpgradeBtn,function()
        self:InitUpgradePanel(true)
    end)
    self:SetButtonClickHandler(self.m_roomUpgradeShowPanelMaxBtn,function()
        self:InitUpgradePanel(true)
    end)

    self:SetButtonClickHandler(self.upgradeBtn, function()
         self:OnFurUpgradeBtnClicked(true)
    end)
    --连点升级按钮
    self:SetButtonHoldHandler(self.upgradeBtn, function()
        local curTime = GameTimeManager:GetCurrentServerTime()
        if not self.m_lastFurUpgradePressTipTime or self.m_lastFurUpgradePressTipTime + 2 <= curTime then
            if not self:OnFurUpgradeBtnClicked(true) then
                self.m_lastFurUpgradePressTipTime = curTime
                print("连点升级按钮"..curTime)
            end
        else
             self:OnFurUpgradeBtnClicked(false)
        end
    end,nil, 0.4, 0.13)

    self:SetButtonClickHandler(self.m_roomUpgradeSkipBtn, handler(self,self.OnUpgradeSkipBtnDown))

    self:SetButtonClickHandler(self.m_roomUpgradePanelBtn,handler(self,self.OnRoomUpgradeBtnDown))
    self:SetButtonClickHandler(self.m_personTalkBtn,handler(self,self.OnPersonTalkBtnDown))
    --CycleIslandMainViewUI:SetAchievementActive(false)

    self:CreateTimer(1000,handler(self,self.OnUpdate),true)

    GameTableDefine.CycleNightClubMainViewUI:SetEventActive(false)
    --GameTableDefine.CycleNightClubMainViewUI:SetPackActive(false)
end

function CycleNightClubBuildingUIView:OnExit()
    --GameTableDefine.CycleNightClubMainViewUI:SetPackActive(true)
    GameTableDefine.CycleNightClubMainViewUI:SetEventActive(true)

    --CycleIslandMainViewUI:SetAchievementActive(true)
    self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
    currentLabel = 1

    --工厂还原家具闪烁
    if self.m_glintingTimer then
        self:StopGlinting()
    end

    --关闭检测对话过期的Timer
    if self.m_personTalkRandomTxtTimer then
        GameTimer:StopTimer(self.m_personTalkRandomTxtTimer)
        self.m_personTalkRandomTxtTimer = nil
    end

    --如果退出时是为了播放升级动画，那就别还原摄像机
    if not self.m_notPlayExitCameraMove then
        local SceneObjectRange = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI, self.m_guid).m_uiObj
        SceneObjectRange = self:GetGo("SceneObjectRange")
        local cameraFocus = self:GetComp(SceneObjectRange, "", "CameraFocus")
        self.m_currentInstanceModel:LookAtSceneGO(self.roomID, selectIndex, cameraFocus, true)
    end
    --self.m_currentInstanceModel:ShowSelectFurniture(nil)
end

---刷新房间固定信息,只会在界面打开时执行一次
function CycleNightClubBuildingUIView:RefreshRoomInfo()
    local roomCfg = roomsConfig[self.roomID]

    -- 房间名
    self:SetText("RootPanel/RoomTitle/HeadPanel/title/name", GameTextLoader:ReadText(roomCfg.name))
    --房间图标
    local roomIcon = self:GetComp("RootPanel/RoomTitle/roomIcon","Image")
    if roomIcon and roomCfg.icon_type then
        self:SetSprite(roomIcon,"UI_Common",roomCfg.icon_type)
    end
    --说话的员工Icon
    if roomCfg.worker_icon then
        self:SetSprite(self.m_workerIconImage,"UI_Common",roomCfg.worker_icon)
    end

    if roomCfg.room_category == 1 then
        self.RoomInfoPanel:SetActive(true)
        self.RoomTitlePanel:SetActive(true)
        self.BG:SetActive(true)
        self.RoomCarteen:SetActive(false)
        self.RoomDormitory:SetActive(false)

        --设置员工Icon
        if roomCfg.worker_exist then
            self:SetSprite(self.m_employeeIconImage,"UI_Common",roomCfg.worker_exist)
        end
    elseif roomCfg.room_category == 2 then
        self.RoomInfoPanel:SetActive(false)
        self.RoomTitlePanel:SetActive(true)
        self.BG:SetActive(true)
        self.RoomCarteen:SetActive(false)
        self.RoomDormitory:SetActive(true)
    elseif roomCfg.room_category == 3 then
        self.RoomInfoPanel:SetActive(false)
        self.RoomTitlePanel:SetActive(true)
        self.BG:SetActive(true)
        self.RoomCarteen:SetActive(true)
        self.RoomDormitory:SetActive(false)
    end
end

---刷新家具等级有关联的信息
function CycleNightClubBuildingUIView:RefreshFurnitureInfo()
    local roomID = self.roomID
    local roomCfg = roomsConfig[self.roomID]

    --获取所有家具信息
    self.factoryFurData = self.m_currentInstanceModel:GetCurRoomData(roomID).furList
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
    local nextFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

    --计算所有产出
    local productionID = roomCfg.production
    local productionNum, expNum, pointNum = self.m_currentInstanceModel:GetRoomProduction(self.roomID)
    local productionCfg = resConfig[productionID]
    local showMatNum = roomCfg.material[2] and tonumber(productionNum) * roomCfg.material[2]


    --获取原料信息
    local showNeed = Tools:GetTableSize(roomCfg.material) > 1
    local isResEnough = true --检测当前的消耗是否足够
    if showNeed then
        local needID = roomCfg.material[1]
        --local resCfg = resConfig[needID]
        --local matList = self.m_currentInstanceModel.portExport
        --库存
        local storedResData = self.m_currentInstanceModel:GetProdutionsData()
        local needResCount = BigNumber:Multiply(productionNum, roomCfg.material[2])
        local storedResCount = storedResData[tostring(needID)] or 0
        if not BigNumber:CompareBig(storedResCount,needResCount) then
            isResEnough = false
        end
    end

    --计算材料消耗
    local needCount,resCfg = self.m_currentInstanceModel:GetRoomMatCost(self.roomID)

    self.m_haveTalkContent = false

    -- 生产栏
    if showNeed then
        self.matierial:SetActive(true)
        self.matierial_1:SetActive(true)
        self:SetText("RootPanel/RoomInfo/product/bg/matierial/count/num", BigNumber:FormatBigNumber(needCount), not isResEnough and "FF1414" or "FFFFFF")
        self:SetSprite(self.matierialImage, "UI_Common", resCfg.icon)
        self.stuckIcon:SetActive(not isResEnough)
        if not isResEnough then
            --self.m_personTalkText.text = GameTextLoader:ReadText("TXT_INSTANCE_WORKER_TALK_2")
            self.m_haveTalkContent = true
            self:PlayTextReveal("TXT_INSTANCE_WORKER_TALK_2")
        end
    else
        self.matierial:SetActive(false)
        self.matierial_1:SetActive(false)
    end
    self:SetText("RootPanel/RoomInfo/product/bg/cooltime/time/num", roomCfg.bastCD)
    local data = BluePrintManager:GetProductionDataByProductID(productionID)
    local level = data.starLevel or 0
    local bpConfig = BluePrintManager:GetBPConfigByProductionLevel(productionID,level)
    local productIcon = bpConfig.icon_head
    --self:SetSprite(self.resourceImage, "UI_Common", productIcon)
    local bluePrintMoneyBuff,bluePrintMileBuff = BluePrintManager:GetProductBuffValue(productionID)
    local productPrice = resConfig[productionID].price
    local income = BigNumber:Multiply(bluePrintMoneyBuff * productPrice,productionNum)
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/resource/count/num", BigNumber:FormatBigNumber(income))
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/exp/count/num", BigNumber:FormatBigNumber(expNum))
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/point/count/num", BigNumber:FormatBigNumber(pointNum))

    -- 升级栏
    self:SetSprite(self.furImage, "UI_Common", currentFurLevelCfg.icon)
    self:SetText("RootPanel/RoomInfo/upgrade/bg/name", GameTextLoader:ReadText(currentFurCfg.name))
    self:SetText("RootPanel/RoomInfo/upgrade/bg/level/num", currentFurLevelCfg.level)

    if currentFurLevelCfg.stage_show == 0 then--防止特效突然闪到一开始的位置
        self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/Fill Area/Fill/vfx/fx"):SetActive(false)
    end
    self.progressSlider.value = currentFurLevelCfg.stage_show
    if currentFurLevelCfg.stage_show == 0 then
        self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/Fill Area/Fill/vfx/fx"):SetActive(true)
    end
    self:SetSprite(self.progressProductImage, "UI_Common", productIcon)
    self:SetSprite(self.m_heroProductionIconImage, "UI_Common", productIcon)
    if not nextFurLevelCfg then
        self.progressBonus:SetActive(false)
    else
        local productionNumNext = self.m_currentInstanceModel:GetRoomProductionByFurId(self.roomID, nextFurLevelCfg.id)
        local incomeNext = BigNumber:Multiply(bluePrintMoneyBuff * productPrice,productionNumNext)
        
        self.progressBonusNumText.text = BigNumber:FormatBigNumberSmall(BigNumber:Subtract(incomeNext, income)) .. "/" .. roomCfg.bastCD .. "s"
    end

    --if currentFurLevelCfg.worker_show then
    --    self.progressEmployee:SetActive(true)
    --    self.progressResouce:SetActive(false)
    --else
    --    self.progressEmployee:SetActive(false)
    --    self.progressResouce:SetActive(true)
    --    self:SetText("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce/icon/num", currentFurLevelCfg.magnification_show)
    --    self:SetSprite(self.progressResouceImage, "UI_Common", productIcon)
    --end
    do
        self.progressEmployee:SetActive(false)
        self.progressResouce:SetActive(true)
        self:SetText("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce/icon/num", string.format("%.2f",currentFurLevelCfg.magnification_show) or "1")
        self:SetSprite(self.progressResouceImage, "UI_Common", productIcon)
    end
    local cost = nextFurLevelCfg and nextFurLevelCfg.cost
    local buffID = self.m_currentInstanceModel:GetSkillIDByType(self.m_currentInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self.m_currentInstanceModel:GetSkillBufferValueBySkillID(buffID)
    cost = cost and BigNumber:Divide(cost,buffValue) or 0
    self:SetText("RootPanel/RoomInfo/upgrade/bg/btn/cash/cost/num", BigNumber:FormatBigNumber(cost))
    --self:SetText("RootPanel/RoomInfo/upgrade/bg/btn/cash/now/num", self.m_currentInstanceModel:GetCurInstanceCoinShow())
    self.m_furLevelCashNow.text = self.m_currentInstanceModel:GetCurInstanceCoinShow()
    self.upgradeMaxlvl:SetActive(not nextFurLevelCfg)
    self.upgradeBtnGO:SetActive(nextFurLevelCfg)

    local isCashEnough = not BigNumber:CompareBig(cost,self.m_currentInstanceModel:GetCurInstanceCoin())
    self.upgradeBtn.interactable = nextFurLevelCfg and isCashEnough and true or false
    self.m_furLevelCashNow.color = isCashEnough and ResEnoughColor or CashNotEnoughColor

    --判断是否正在销售
    local isSelling = self.m_currentInstanceModel:ProductIsSelling(roomCfg.production)
    if not isSelling then
        --self.m_personTalkText.text = GameTextLoader:ReadText("TXT_INSTANCE_WORKER_TALK_1")
        self.m_haveTalkContent = true
        self:PlayTextReveal("TXT_INSTANCE_CY3_WORKER_TALK")
    end

    self:UpdatePersonTalk()
end

---播放打字效果
function CycleNightClubBuildingUIView:PlayTextReveal(txtID)
    --这个方法连点会有BUG,所以还是开关物体.
    --self.m_personTalkFeedback:StopFeedbacks()
    --self.m_personTalkFeedback:PlayFeedbacks()
    if self.m_curPersonTxtID == txtID then
        return
    end
    self.m_curPersonTxtID = txtID
    self.m_personTalkText.text = GameTextLoader:ReadText(txtID)


    self.m_personTalkTalkGO:SetActive(false)
    self.m_personTalkTalkGO:SetActive(true)
end

function CycleNightClubBuildingUIView:UpdatePersonTalk(forceHide)

    if forceHide then
        self.m_personTalkTalkGO:SetActive(false)
        return
    end

    if self.m_isShowUpgradePanel then
        self.m_personTalkTalkGO:SetActive(false)
        return
    end

    if self.m_haveTalkContent then
        --有强制引导
        self.m_personTalkTalkGO:SetActive(true)
    else
        if self.m_personTalkRandomTxt then
            if GameTimeManager:GetCurrentServerTime() >= self.m_personTalkHideTime then
                self.m_personTalkTalkGO:SetActive(false)
                self.m_personTalkRandomTxt = nil
                if self.m_personTalkRandomTxtTimer then
                    GameTimer:StopTimer(self.m_personTalkRandomTxtTimer)
                    self.m_personTalkRandomTxtTimer = nil
                end
            else
                self.m_personTalkTalkGO:SetActive(true)
            end
        else
            self.m_personTalkTalkGO:SetActive(false)
        end
    end
end

---房间升级进度条和按钮的状态
function CycleNightClubBuildingUIView:RefreshRoomUpgradeInfo()
    --房间升级进度条
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig

    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    local roomLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel)
    local roomFurLevelRange = roomLevelCfg.fur_levelRange
    local roomLevelMax = self.m_currentInstanceModel:GetRoomMaxLevel(self.roomID)

    self.m_roomLevelText.text = tostring(roomLevel)

    local value = 1.0 * (currentFurLevelCfg.level - roomFurLevelRange[1] ) / (roomFurLevelRange[2] - roomFurLevelRange[1])
    if currentFurLevelCfg.level - roomFurLevelRange[1] <= 1 then--防止特效突然闪到一开始的位置
        self:GetGo("RootPanel/RoomTitle/progress/Fill Area/Fill/vfx/fx"):SetActive(false)
    end
    self.m_roomUpgradeFurLevelSlider.value = value
    if currentFurLevelCfg.level - roomFurLevelRange[1] <= 1 then
        self:GetGo("RootPanel/RoomTitle/progress/Fill Area/Fill/vfx/fx"):SetActive(true)
    end

    if roomFurLevelRange and roomLevel < roomLevelMax then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/btn/icon"):SetActive(true)
        self.m_roomUpgradeShowPanelMaxBtn.gameObject:SetActive(false)
        if value >= 1.0 then
            --可以升级,显示UpgradeBtn
            local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
            self.m_roomUpgradeShowPanelNormalBtn.gameObject:SetActive(false)
            self.m_roomUpgradeShowPanelUpgradeBtn.gameObject:SetActive(true)
            self.m_roomUpgradeShowPanelUpgradeBtn.interactable = not roomData.isUpgrading
            --显示房间可升级气泡
            local room = self.m_currentInstanceModel:GetScene():GetRoomByID(self.roomID)
            if room then
                room:ShowBubble(CycleInstanceDefine.BubbleType.CanUpgrade)
            end
        else
            --不可以升级,显示NormalBtn
            self.m_roomUpgradeShowPanelNormalBtn.gameObject:SetActive(true)
            self.m_roomUpgradeShowPanelUpgradeBtn.gameObject:SetActive(false)
        end
    else
        self.m_roomUpgradeShowPanelNormalBtn.interactable = true
        --self.m_roomUpgradeShowPanelBtn.gameObject:SetActive(false)
        --self.m_roomUpgradeFurLevelSlider.gameObject:SetActive(false)
        --满级改变升级按钮从 '↑' 变成 '!',显示MaxBtn
        self.m_roomUpgradeShowPanelMaxBtn.gameObject:SetActive(true)
        self.m_roomUpgradeShowPanelNormalBtn.gameObject:SetActive(false)
        self.m_roomUpgradeShowPanelUpgradeBtn.gameObject:SetActive(false)

        --满级隐藏Lv,levelNum节点,显示Max节点
        self:GetGo("RootPanel/RoomTitle/HeadPanel/title/Lv"):SetActive(false)
        self:GetGo("RootPanel/RoomTitle/HeadPanel/title/levelNum"):SetActive(false)
        self:GetGo("RootPanel/RoomTitle/HeadPanel/title/max"):SetActive(true)
    end
end

---房间是否需要升级，满足升级房间的家具等级条件
function CycleNightClubBuildingUIView:RoomNeedUpgrade()
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
    local nextFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

    --判断房间等级需求
    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    if nextFurLevelCfg.room_level and nextFurLevelCfg.room_level > roomLevel then
        return true
    else
        return false
    end
end

---点击升级按钮
---@return boolean 是否升级成功
function CycleNightClubBuildingUIView:OnFurUpgradeBtnClicked(showResNotEnoughTip)
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
    local nextFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

    --判断房间等级需求
    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    if nextFurLevelCfg.room_level and nextFurLevelCfg.room_level > roomLevel then
        if showResNotEnoughTip then
            EventManager:DispatchEvent("UI_NOTE", string.format(GameTextLoader:ReadText("TXT_INSTANCE_TIP_ROOM_UPGRADE")))
        end
        return false
    end

    local cost = nextFurLevelCfg and nextFurLevelCfg.cost
    local buffID = self.m_currentInstanceModel:GetSkillIDByType(self.m_currentInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self.m_currentInstanceModel:GetSkillBufferValueBySkillID(buffID)
    cost = cost and BigNumber:Divide(cost,buffValue)
    local canBuy = cost and BigNumber:CompareBig(self.m_currentInstanceModel:GetCurInstanceCoin(), cost)
    if not canBuy then
        --钱不够，购买提示
        --if showResNotEnoughTip then
        --    ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
        --        GameTableDefine.CycleNightClubShopUI:GetView()
        --    end)
        --end
        return false
    end
    self.m_currentInstanceModel:BuyFurniture(self.roomID,selectIndex,nextFurLevelCfg.id)
    self:RefreshFurnitureInfo()

    self.feel:PlayFeedbacks()
    self:StartGlinting()
    if nextFurLevelCfg.milePoint_node then
        self:RefreshFurLevelReward(true)
    end
    GameTableDefine.CycleNightClubPopUI:PackTrigger(5, self.roomID)
    
    return true
end

function CycleNightClubBuildingUIView:ShowFactoryUI(roomID, select, isFirst)
    --printf("ShowFactoryUI")
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    self.UItype = 1

    self.roomID = roomID

    --**********************************显示UI*************************************
    --房间
    self:RefreshRoomInfo()
    --家具相关
    self:RefreshFurnitureInfo()
    self:RefreshFurLevelReward(false)
    --英雄
    self:RefreshHero()
    --房间升级进度
    self:RefreshRoomUpgradeInfo()
    --房间升级面板
    self:InitUpgradePanel()

    if isFirst then
        --将相机焦点移动至所选设备位置
        --self.m_currentInstanceModel:LookAtSceneGO(self.roomID, 1, self.cameraFocus)
        --将相机焦点移动至roomBox
        local currentScene = self.m_currentInstanceModel:GetScene()
        local room = currentScene:GetRoomByID(roomID)
        currentScene:LookAtGameObject(room.roomGO.roomBox, self.cameraFocus)
    end
end

function CycleNightClubBuildingUIView:ShowSupplyBuildingUI(roomID, select, isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    self.UItype = 2
    local roomCfg = roomsConfig[roomID]

    self.roomID= roomID

    --**********************************数据整理*************************************

    --获取所有家具信息
    self.SupplyBuildingFurData = self.m_currentInstanceModel:GetCurRoomData(roomID).furList
    local currentFurLevelCfg = furnitureLevelConfig[self.SupplyBuildingFurData[tostring(selectIndex)].id]
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --计算所有供给
    --local supplySeatSum = self.m_currentInstanceModel:GetRoomSeatCount(roomID)
    --local supplyHungerSum = self.m_currentInstanceModel:GetRoomHunger(roomID)
    --local supplyPhysicalSum = self.m_currentInstanceModel:GetRoomPhysical(roomID)

    --**********************************显示UI*************************************

    self:RefreshRoomInfo()

    --将相机焦点移动至所选设备位置
    self.m_currentInstanceModel:LookAtSceneGO(self.roomID, 1, self.cameraFocus)
   
end

function CycleNightClubBuildingUIView:UpdateSupplyBuildingFurItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local currentFurData = self.SupplyBuildingFurData[tostring(index)]
    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]

    local selected = self:GetGo(go,"Btn/selected")
    local unlocked = self:GetGo(go,"Btn/unlocked")
    local locked = self:GetGo(go,"Btn/locked")
    local root = nil
    if selectIndex == index then
        root = selected
        selected:SetActive(true)
        unlocked:SetActive(false)
        locked:SetActive(false)
    else
        selected:SetActive(false)

        if currentFurData.state == 0 then
            root = locked
            unlocked:SetActive(false)
            locked:SetActive(true)
        else
            root = unlocked
            unlocked:SetActive(true)
            locked:SetActive(false)
        end
    end
    local image = self:GetComp(root, "icon", "Image")
    self:SetSprite(image,"UI_Common", currentFurLevelCfg.icon)
    local showLevel = currentFurLevelCfg.level
    if currentFurData.state == 0 then
        showLevel = 0
    end
    self:SetText(root,"level/num", showLevel)
    self:SetButtonClickHandler(self:GetComp(go, "Btn","Button"), function()
        selectIndex = index
        self:ShowSupplyBuildingUI(self.roomID,selectIndex)
        self:SelectFurniture(index,currentFurData)
    end)
    if isOpen and index == selectIndex then
        self:SelectFurniture(index,currentFurData)
    end
end

function CycleNightClubBuildingUIView:ShowWharfUI(roomID,select,isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end

    self.UItype = 3
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID
    self.btnPanel:SetActive(false)
    --**********************************数据整理*************************************

    --获取所有家具信息
    self.wharfFurData = self.m_currentInstanceModel:GetCurRoomData(roomID).furList
    local curFurLevelID = self.wharfFurData[tostring(selectIndex)].id
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --**********************************显示UI*************************************
    --title
    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/title/name",GameTextLoader:ReadText(roomCfg.name))
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need"):SetActive(false)
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(true)
    local storage = currentFurLevelCfg.storage
    if storage <= 0 then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(false)
    else
        local productions = self.m_currentInstanceModel:GetProdutionsData()
        local storage = productions[tostring(currentFurLevelCfg.resource_type)] or 0
        storage = math.floor(storage)
        local showStr = Tools:SeparateNumberWithComma(storage).."/"..currentFurLevelCfg.storage
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/storage/item/base", showStr)
        local materialCfg = resConfig[currentFurLevelCfg.resource_type]
        self:SetImageSprite("RootPanel/RoomTitle/HeadPanel/bg/storage/item/icon",materialCfg.icon)
    end

    --显示点击的设备信息
    self:SetImageSprite("RootPanel/PortInfo/furniture/info/main/icon",currentFurLevelCfg.icon)
    self:SetText("RootPanel/PortInfo/furniture/info/main/name",GameTextLoader:ReadText(currentFurCfg.name))
    self:SetText("RootPanel/PortInfo/furniture/info/main/level/bg/num",currentFurLevelCfg.level)
    self:SetText("RootPanel/PortInfo/furniture/info/main/desc",GameTextLoader:ReadText(currentFurCfg.desc))

    local currentFurMaxLevel = self:GetFurnitureMaxlevel(currentFurLevelCfg.furniture_id)
    local buyButton = self:GetComp("RootPanel/PortInfo/furniture/info/main/btn","Button")
    local maxButton = self:GetComp("RootPanel/PortInfo/furniture/info/main/maxlvl","Button")
    local isMaxLevel = currentFurLevelCfg.level >= currentFurMaxLevel

    local willBuy = currentFurLevelCfg.level
    if self.wharfFurData[tostring(selectIndex)].state ~= 0 then
        willBuy = willBuy + 1
    end
    local willBuyFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurLevelCfg.furniture_id, willBuy)
    if isMaxLevel then
        buyButton.gameObject:SetActive(false)
        maxButton.gameObject:SetActive(true)
    else
        buyButton.gameObject:SetActive(true)
        maxButton.gameObject:SetActive(false)
        local canBuy,conditions = self.m_currentInstanceModel:CheckFuinitureCondition(willBuyFurLevelCfg.id)
        local showConditionTips = false
        --buyButton.interactable = canBuy
        self:SetText(buyButton.gameObject,"num",Tools:SeparateNumberWithComma(conditions))
        self:SetButtonClickHandler(buyButton,function()
            if willBuyFurLevelCfg.conditionID ~= 0 then --是船
                local matFurLevelCfg = furnitureLevelConfig[willBuyFurLevelCfg.conditionID]

                if self.wharfFurData[tostring(selectIndex-6)].state ~= 1 then
                    showConditionTips = true
                end
            end

            -- 购买
            if canBuy then
                if showConditionTips then
                    local conditionFurLevelCfg = furnitureLevelConfig[willBuyFurLevelCfg.conditionID]
                    local currentFurCfg = furnitureConfig[conditionFurLevelCfg.furniture_id]
                    local showText = string.format(GameTextLoader:ReadText("TXT_TIP_LACK_FACILITY"),GameTextLoader:ReadText(currentFurCfg.name))
                    EventManager:DispatchEvent("UI_NOTE", showText)
                    return
                end
                local cost = willBuyFurLevelCfg.cost
                self.m_currentInstanceModel:BuyFurniture(self.roomID,selectIndex,willBuyFurLevelCfg.id)
            end
            self:ShowWharfUI(self.roomID,selectIndex)
        end)
    end

    local isPort = true
    if currentFurLevelCfg.storage > 0 then    --选中的item是码头
        isPort = true
    else
        isPort = false
    end

    self:GetGo("RootPanel/PortInfo/furniture/info/main/openState"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/storage"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/benifit"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/localization"):SetActive(not isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/cooltime"):SetActive(not isPort)

    if isPort then  --码头信息
        local isOpen = self.wharfFurData[tostring(selectIndex)].isOpen --港口开关
        local toggle = self:GetComp("RootPanel/PortInfo/furniture/info/main/openState","Toggle")

        if self.wharfFurData[tostring(selectIndex)].state == 1 then
            toggle.interactable = true
            toggle.isOn = not isOpen
        else
            toggle.interactable = false
            toggle.isOn = true
        end

        self:SetToggleValueChangeHandler(toggle,function(bool)
            --print("ToggleValueChange",selectIndex,currentFurLevelCfg.id)
            if  lastSelectedIndex == selectIndex then

                self.m_currentInstanceModel:SetRoomFurnitureData(roomID,selectIndex,currentFurLevelCfg.id,{isOpen = not bool})
                local furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(roomID,selectIndex)
                -- local doorPathHead = "Miscellaneous/Environment/Port_1/model/Easter_Men_0"
                -- local doorPath = doorPathHead..selectIndex
                local doorGO = self:GetGo(furGO,"Door")
                if bool then
                    --关
                    local feel = self:GetComp(doorGO,"closeFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                else
                    --开
                    local feel = self:GetComp(doorGO,"openFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                end
            end

        end)


        local storage = currentFurLevelCfg.storage  --库存
        local stotageStr = Tools:SeparateNumberWithComma(storage)
        if currentFurLevelCfg.level < currentFurMaxLevel then
            stotageStr = stotageStr ..Tools:ChangeTextColor("+"..Tools:SeparateNumberWithComma( willBuyFurLevelCfg.storage - storage),"57c92f")
        end
        if willBuy == 1 then
            stotageStr =  storage
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/storage/num",stotageStr)

        local storage = currentFurLevelCfg.storage  --预期收入
        local sellingPrice = storage * resConfig[currentFurLevelCfg.resource_type].price
        local sellingPriceStr = Tools:SeparateNumberWithComma(sellingPrice)
        if currentFurLevelCfg.level < currentFurMaxLevel then
            local nextSellingPrice = willBuyFurLevelCfg.storage * resConfig[currentFurLevelCfg.resource_type].price
            sellingPriceStr = sellingPriceStr..Tools:ChangeTextColor("+"..  Tools:SeparateNumberWithComma(nextSellingPrice - sellingPrice),"57c92f")
        end
        if willBuy == 1 then
            sellingPriceStr = Tools:SeparateNumberWithComma(sellingPrice)
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/benifit/num",sellingPriceStr)
    else

        local partLevelID = currentFurLevelCfg.conditionID  --船停靠码头
        local partlevelCfg = furnitureLevelConfig[partLevelID].furniture_id
        local partCfg = furnitureConfig[partlevelCfg]
        local stotageStr = GameTextLoader:ReadText(partCfg.name)
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/localization/num",stotageStr)

        local shipCD = currentFurLevelCfg.shipCD  --船CD
        local shipCDStr =  shipCD.."s"
        if currentFurLevelCfg.level < currentFurMaxLevel then
            local cdReduce = willBuyFurLevelCfg.shipCD - shipCD
            shipCDStr = shipCD.."s"..Tools:ChangeTextColor(cdReduce.."s","57c92f")
        end
        if willBuy == 1 then
            shipCDStr =  shipCD.."s"
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/cooltime/num",shipCDStr)

    end


    --显示item
    local furnitureListScroll = self:GetComp("RootPanel/PortInfo/furniture/list", "ScrollRectEx")
    self:SetListItemCountFunc(furnitureListScroll, function()
        return Tools:GetTableSize(self.wharfFurData)
    end)
    self:SetListUpdateFunc(furnitureListScroll, handler(self, self.UpdateWharfFurItem))
    furnitureListScroll:UpdateData()

    lastSelectedIndex = selectIndex
end

function CycleNightClubBuildingUIView:UpdateWharfFurItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local currentFurData = self.wharfFurData[tostring(index)]
    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]
    go.name = currentFurLevelCfg.furniture_id

    local selected = self:GetGo(go,"Btn/selected")
    local unlocked = self:GetGo(go,"Btn/unlocked")
    local locked = self:GetGo(go,"Btn/locked")
    local root = nil
    if selectIndex == index then
        root = selected
        selected:SetActive(true)
        unlocked:SetActive(false)
        locked:SetActive(false)
    else
        selected:SetActive(false)

        if currentFurData.state == 0 then
            root = locked
            unlocked:SetActive(false)
            locked:SetActive(true)
        else
            root = unlocked
            unlocked:SetActive(true)
            locked:SetActive(false)
        end
    end
    local image = self:GetComp(root, "icon", "Image")
    self:SetSprite(image,"UI_Common", currentFurLevelCfg.icon)
    local showLevel = currentFurLevelCfg.level
    if currentFurData.state == 0 then
        showLevel = 0
    end
    self:SetText(root,"level/num",showLevel)
    self:SetButtonClickHandler(self:GetComp(go, "Btn","Button"), function()
        selectIndex = index
        --print("selectIndex",selectIndex)
        self:ShowWharfUI(self.roomID,selectIndex)

        if selectIndex > 6 then
            self:SelectFurniture(index - 6,self.wharfFurData[tostring(selectIndex-6)])
        else
            self:SelectFurniture(index,currentFurData)
        end
    end)

    if isOpen and index == selectIndex then
        self:SelectFurniture(index,currentFurData)
    end

end

function CycleNightClubBuildingUIView:GetFurnitureMaxlevel(furnitureID)
    local furnitureLevelConfig_furID = self.m_currentInstanceModel.furnitureLevelConfig_furID
    local furLevelCfgs = furnitureLevelConfig_furID[furnitureID]
    local max = 0
    for k,v in pairs(furLevelCfgs) do
        if v.furniture_id == furnitureID and v.level >= max then
            max = v.level
        end
    end
    return max
end

function CycleNightClubBuildingUIView:SelectFurniture(index,furData)

    --将相机焦点移动至所选设备位置
    --local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    --self.m_currentInstanceModel:LookAtSceneGO(self.roomID,index,cameraFocus)
    --所选设备闪烁
    local prebuy = furData.state == 0
    local roomCfg = roomsConfig[self.roomID]
    local furGO = nil
    furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(self.roomID,index)

    -- if roomCfg.room_category == 2 or  roomCfg.room_category == 3 then
    --     furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(self.roomID,index,1)
    -- else
    --     furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(self.roomID,index)
    -- end

    self.m_currentInstanceModel:ShowSelectFurniture(furGO,prebuy)
end

--region 英雄
---刷新英雄信息
function CycleNightClubBuildingUIView:RefreshHero()
    local roomCfg = roomsConfig[self.roomID]
    local heroID = roomCfg.hero_id
    local heroData = CycleNightClubHeroManager:GetHeroData(heroID)
    local heroLevel = heroData.level
    local heroConfig = CycleNightClubHeroManager:GetHeroConfig(heroID,heroLevel)

    self.m_heroLevelText.text = tostring(heroLevel)
    self:SetSprite(self.m_heroIconImage,"UI_Common",heroConfig.icon)
    self.m_heroNameText.text = GameTextLoader:ReadText(heroConfig.name)
    self.m_heroUpgradeCostText.text = BigNumber:FormatBigNumber(heroConfig.res)
    self.m_heroUpgradeResNowText.text = self.m_currentInstanceModel:GetCurHeroExpResShow()
    self.m_heroCurMagnificationText.text = string.format("%.2f",heroConfig.buff)

    if CycleNightClubHeroManager:IsMaxLevel(heroID) then
        self.m_heroMaxGO:SetActive(true)
        self.m_heroUpgradeBtn.gameObject:SetActive(false)
        local nextBuffGO = self:GetGoOrNil("RootPanel/RoomInfo/workstate/bg/bonus/maxBonus")
        if nextBuffGO then
            nextBuffGO:SetActive(false)
        end
    else
        self.m_heroMaxGO:SetActive(false)
        self.m_heroUpgradeBtn.gameObject:SetActive(true)
        local heroNextConfig = CycleNightClubHeroManager:GetHeroConfig(heroID,heroLevel+1)
        self.m_heroNextMagnificationText.text = string.format("%.2f",heroNextConfig.buff)

        local isEnough = not BigNumber:CompareBig(heroConfig.res,self.m_currentInstanceModel:GetCurHeroExpRes())
        self.m_heroUpgradeResNowText.color = isEnough and ResEnoughColor or ExpNotEnoughColor
        self.m_heroUpgradeBtn.interactable = isEnough
        if not isEnough then
            GameTableDefine.CycleNightClubPopUI:PackTrigger(2)
        end
    end
end

---英雄升级按钮
function CycleNightClubBuildingUIView:OnHeroUpgradeBtnDown(showResNotEnoughTip)
    local roomCfg = roomsConfig[self.roomID]
    local heroID = roomCfg.hero_id
    local result,nextLevelCfg = CycleNightClubHeroManager:UpgradeHero(heroID)
    if result == CycleNightClubHeroManager.HeroUpgradeResult.Success then
        self:RefreshHero()
        self:RefreshFurnitureInfo()
        CycleNightClubMainViewUI:Refresh()
        return true
    elseif result == CycleNightClubHeroManager.HeroUpgradeResult.ResNotEnough then
        --if showResNotEnoughTip then
        --    ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
        --        GameTableDefine.CycleNightClubShopUI:GetView()
        --    end)
        --end
    elseif result == CycleNightClubHeroManager.HeroUpgradeResult.LevelMax then
        --满级
    end
end
--endregion

--region 房间升级


function CycleNightClubBuildingUIView:OnUpdate()
    if not self.roomID or not roomsConfig then
        return
    end

    local roomConfig = roomsConfig[self.roomID]

    if roomConfig.room_category == 1 then

        --及时刷新英雄经验值和家具升级的钱
        self.m_heroUpgradeResNowText.text = self.m_currentInstanceModel:GetCurHeroExpResShow()
        self.m_furLevelCashNow.text = self.m_currentInstanceModel:GetCurInstanceCoinShow()

        self:RefreshRoomUpgradePanelDynamic()

        --及时刷新家具升级按钮的状态,(如果性能不理想就注释掉)
        local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
        local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
        local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
        local nextFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

        local cost = nextFurLevelCfg and nextFurLevelCfg.cost
        local buffID = self.m_currentInstanceModel:GetSkillIDByType(self.m_currentInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
        local buffValue = self.m_currentInstanceModel:GetSkillBufferValueBySkillID(buffID)
        cost = cost and BigNumber:Divide(cost,buffValue) or 0

        local isCashEnough = not BigNumber:CompareBig(cost,self.m_currentInstanceModel:GetCurInstanceCoin())
        self.upgradeBtn.interactable = nextFurLevelCfg and isCashEnough and true or false
        self.m_furLevelCashNow.color = isCashEnough and ResEnoughColor or CashNotEnoughColor

        --及时刷新英雄经验的颜色,(如果性能不理想就注释掉)
        if self.m_heroUpgradeBtn.gameObject.activeInHierarchy then
            local roomCfg = roomsConfig[self.roomID]
            local heroID = roomCfg.hero_id
            local heroData = CycleNightClubHeroManager:GetHeroData(heroID)
            local heroLevel = heroData.level
            local heroConfig = CycleNightClubHeroManager:GetHeroConfig(heroID,heroLevel)
            local isEnough = not BigNumber:CompareBig(heroConfig.res,self.m_currentInstanceModel:GetCurHeroExpRes())
            self.m_heroUpgradeResNowText.color = isEnough and ResEnoughColor or ExpNotEnoughColor
            self.m_heroUpgradeBtn.interactable = isEnough
        end
    end
end

---判断是否该显示房间升级界面. 默认不打开，升级中打开
function CycleNightClubBuildingUIView:InitUpgradePanel(isClickUpgradeBtn)

    local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
    --local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    --local maxLevel = self.m_currentInstanceModel:GetRoomMaxLevel(self.roomID)

    if isClickUpgradeBtn then
        --开或关界面
        if self.m_isShowUpgradePanel then
            self.m_isShowUpgradePanel = false
        else
            self.m_isShowUpgradePanel = true
        end
    end
    if not self.m_isShowUpgradePanel then
        --升级中要打开界面
        if roomData.isUpgrading then
            self.m_isShowUpgradePanel = true
        end
    else
        --满级就不能打开界面了
        --if roomLevel>=maxLevel then
        --    self.m_isShowUpgradePanel = false
        --end
    end

    if self.m_isShowUpgradePanel then
        self.m_roomUpgradePanelGO:SetActive(true)
        self:UpdatePersonTalk(true)
        self:RefreshRoomUpgradePanel()
    else
        self.m_roomUpgradePanelGO:SetActive(false)
        self:UpdatePersonTalk()
    end
end

---刷新房间升级界面里显示的动态信息,倒计时，升级按钮，当前钱的数量
function CycleNightClubBuildingUIView:RefreshRoomUpgradePanelDynamic()

    if not self.m_isShowUpgradePanel then
        return
    end

    local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    --升级中
    if roomData.isUpgrading then
        self.m_roomUpgradeInfoGO:SetActive(false)
        self.m_roomUpgradeSkipInfoGO:SetActive(true)

        --显示倒计时
        local skipDiamond = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
        local curTime = GameTimeManager:GetCurrentServerTime()
        local roomNextLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel+1)
        local remainingTime = roomData.completeTime - curTime
        if remainingTime <= 0 then
            --通知Model更新
            self.m_currentInstanceModel:UpgradeRoomComplete(self.roomID)
            --隐藏Finish气泡
            local room = self.m_currentInstanceModel:GetScene():GetRoomByID(self.roomID)
            room:HideBubble(CycleInstanceDefine.BubbleType.IsFinish)
            remainingTime = 0
            --立即刷新界面
            self.m_roomUpgradeTimeSlider.value = 1 - remainingTime / roomNextLevelCfg.upgrade_time
            self.m_roomUpgradeSkipCostText.text = "0"
            self.m_roomUpgradeTimeSlider.value = 1
        else
            local timeStr = GameTimeManager:FormatTimeLength(remainingTime)
            self.m_roomUpgradeRemainingTimeText.text = timeStr
            local needDiamond = skipDiamond * math.ceil(remainingTime/60)
            self.m_roomUpgradeSkipCostText.text = Tools:SeparateNumberWithComma(needDiamond)
            local isEnough = ResourcesManager:CheckDiamond(needDiamond)
            --TODO 改变按钮颜色
            if isEnough then

            else

            end
            self.m_roomUpgradeTimeSlider.value = 1 - remainingTime / roomNextLevelCfg.upgrade_time
        end
    elseif roomData.needShowUpgradeAnim then
        --房间升级后的表现(无论有没有家具变化)
        local roomID = self.roomID
        self.m_notPlayExitCameraMove = true
        self:DestroyModeUIObject()
        CycleNightClubBuildingUI:DoFactoryUpgradeProcess(roomID,1)
        --if roomData.upgradeNodeFurID then
        --    --房间升级后的表现(有家具变化)
        --    local roomID = self.roomID
        --    self.m_notPlayExitCameraMove = true
        --    self:DestroyModeUIObject()
        --    CycleNightClubBuildingUI:DoFactoryUpgradeProcess(roomID,1)
        --else
        --    --房间升级后的表现(没有家具变化)
        --    self.m_isShowUpgradePanel = false
        --    self.m_roomUpgradePanelGO:SetActive(false)
        --    self:UpdatePersonTalk()
        --
        --    roomData.needShowUpgradeAnim = false
        --
        --    self:RefreshRoomUpgradeInfo()
        --    self:RefreshFurLevelReward(false)
        --end
    else
        self.m_roomUpgradeSkipInfoGO:SetActive(false)

        local roomNextLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel+1)
        if roomNextLevelCfg then
            self.m_roomUpgradeInfoGO:SetActive(true)
            local haveCoin = self.m_currentInstanceModel:GetCurInstanceCoin()
            --local upgradeCostCoin = roomNextLevelCfg.upgrade_cost
            local upgradeCostCoin = self.m_currentInstanceModel:GetRoomUpgradeCost(self.roomID,roomLevel+1)
            local isEnough = not BigNumber:CompareBig(upgradeCostCoin,haveCoin)
            self.m_roomUpgradePanelBtn.interactable = isEnough and self:RoomNeedUpgrade()
            self.m_roomUpgradePanelHaveCashText.color = isEnough and ResEnoughColor or CashNotEnoughColor
            self.m_roomUpgradePanelHaveCashText.text = BigNumber:FormatBigNumber(self.m_currentInstanceModel:GetCurInstanceCoin())
            if self.m_roomUpgradePanelCoinNotEnoughGO then
                self.m_roomUpgradePanelCoinNotEnoughGO:SetActive(not isEnough)
            end
        else
            self.m_roomUpgradeInfoGO:SetActive(false)
        end
    end
end

---房间升级进度节点,显示在UpgradePanel上
function CycleNightClubBuildingUIView:GetRoomUpgradeNodeList(roomID)
    local nodeList = {1}
    local index = 2
    local roomLevelConfigs = self.m_currentInstanceModel.config_cy_instance_roomsLevel[roomID]
    for level,roomLevelConfig in ipairs(roomLevelConfigs) do
        if roomLevelConfig.show_bool then
            nodeList[index] = level
            index = index + 1
        end
    end
    if #nodeList < 3 then
        printf("房间"..roomID.."配置的升级节点数量小于3,所以为了不报错而变为前一个存在的节点+1")
        for i = #nodeList+1, 3 do
            nodeList[i] = nodeList[i-1] + 1
        end
    end
    return nodeList
end

---刷新房间升级界面里显示的所有信息
function CycleNightClubBuildingUIView:RefreshRoomUpgradePanel()

    if not self.m_isShowUpgradePanel then
        return
    end

    local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    --升级中
    if roomData.isUpgrading then
        self.m_roomUpgradeInfoGO:SetActive(false)
        self.m_roomUpgradeSkipInfoGO:SetActive(true)

        --显示倒计时
        local skipDiamond = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
        local curTime = GameTimeManager:GetCurrentServerTime()
        local roomNextLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel+1)
        local remainingTime = roomData.completeTime - curTime
        if remainingTime <= 0 then
            --通知Model更新
            self.m_currentInstanceModel:UpgradeRoomComplete(self.roomID)
            --隐藏Finish气泡
            local room = self.m_currentInstanceModel:GetScene():GetRoomByID(self.roomID)
            room:HideBubble(CycleInstanceDefine.BubbleType.IsFinish)
            remainingTime = 0
            --立即刷新界面
            self.m_roomUpgradeTimeSlider.value = 1 - remainingTime / roomNextLevelCfg.upgrade_time
            self.m_roomUpgradeSkipCostText.text = "0"
            self.m_roomUpgradeTimeSlider.value = 1
        else
            local timeStr = GameTimeManager:FormatTimeLength(remainingTime)
            self.m_roomUpgradeRemainingTimeText.text = timeStr
            local needDiamond = skipDiamond * math.ceil(remainingTime/60)
            self.m_roomUpgradeSkipCostText.text = Tools:SeparateNumberWithComma(needDiamond)
            local isEnough = ResourcesManager:CheckDiamond(needDiamond)
            --TODO 改变按钮颜色
            if isEnough then

            else

            end
            self.m_roomUpgradeTimeSlider.value = 1 - remainingTime / roomNextLevelCfg.upgrade_time
        end
    elseif roomData.needShowUpgradeAnim then
        --房间升级后的表现(无论有没有家具变化)
        local roomID = self.roomID
        self.m_notPlayExitCameraMove = true
        self:DestroyModeUIObject()
        CycleNightClubBuildingUI:DoFactoryUpgradeProcess(roomID,1)
        --if roomData.upgradeNodeFurID then
        --    --房间升级后的表现(有家具变化)
        --    local roomID = self.roomID
        --    self.m_notPlayExitCameraMove = true
        --    self:DestroyModeUIObject()
        --    CycleNightClubBuildingUI:DoFactoryUpgradeProcess(roomID,1)
        --else
        --    --房间升级后的表现(没有家具变化)
        --    self.m_isShowUpgradePanel = false
        --    self.m_roomUpgradePanelGO:SetActive(false)
        --    self.m_personTalkTalkGO:SetActive(self.m_haveTalkContent)
        --
        --    roomData.needShowUpgradeAnim = false
        --
        --    self:RefreshRoomUpgradeInfo()
        --end
    else
        self.m_roomUpgradeInfoGO:SetActive(true)
        self.m_roomUpgradeSkipInfoGO:SetActive(false)

        local roomNextLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel+1)

        local roomMaxLevel = self.m_currentInstanceModel:GetRoomMaxLevel(self.roomID)
        local roomLevelNodeList = self:GetRoomUpgradeNodeList(self.roomID)
        local roomCfg = self.m_currentInstanceModel:GetRoomConfigByID(self.roomID)

        local panelRootGO = nil

        if roomNextLevelCfg then
            panelRootGO = self.m_roomUpgradeInfoGO
            local haveCoin = self.m_currentInstanceModel:GetCurInstanceCoin()
            --local upgradeCostCoin = roomNextLevelCfg.upgrade_cost
            local upgradeCostCoin = self.m_currentInstanceModel:GetRoomUpgradeCost(self.roomID,roomLevel+1)

            local isEnough = not BigNumber:CompareBig(upgradeCostCoin,haveCoin)
            self.m_roomUpgradePanelBtn.interactable = isEnough and self:RoomNeedUpgrade()
            self.m_roomUpgradePanelCostCashText.text = BigNumber:FormatBigNumber(upgradeCostCoin)
            self.m_roomUpgradePanelHaveCashText.color = isEnough and ResEnoughColor or CashNotEnoughColor
            self.m_roomUpgradePanelHaveCashText.text = BigNumber:FormatBigNumber(self.m_currentInstanceModel:GetCurInstanceCoin())
            self.m_roomUpgradePanelCostTimeText.text = string.format("%.1fMin",roomNextLevelCfg.upgrade_time/60)
            if self.m_roomUpgradePanelCoinNotEnoughGO then
                self.m_roomUpgradePanelCoinNotEnoughGO:SetActive(not isEnough)
            end
        else
            self.m_roomUpgradeInfoGO:SetActive(false)
            panelRootGO = self:GetGo(self.m_roomUpgradePanelGO,"maxRoom")
            panelRootGO:SetActive(true)
            --没有下一级,显示满级该显示的内容
        end

        --等级进度图标
        for i = 1, 3 do
            local levelRootGO = self:GetGo(panelRootGO,"schedule/level"..i)
            local nodeLevel = roomLevelNodeList[i] ---节点对应的房间等级
            if nodeLevel <= roomMaxLevel then
                if nodeLevel <= roomLevel then
                    local openGO = self:GetGo(levelRootGO,"open")
                    openGO:SetActive(true)
                    local offGO = self:GetGoOrNil(levelRootGO,"off")
                    if offGO then
                        offGO:SetActive(false)
                    end

                    self:SetText(openGO,"levelNum",tostring(nodeLevel))
                    local image = self:GetComp(levelRootGO,"open/roomIcon","Image")
                    self:SetSprite(image,"UI_Common",roomCfg.decorate_icon[i])
                else
                    self:GetGo(levelRootGO,"open"):SetActive(false)
                    local offGO = self:GetGoOrNil(levelRootGO,"off")
                    if offGO then
                        offGO:SetActive(true)
                        self:SetText(offGO,"levelNum",tostring(nodeLevel))
                    end

                    local image = self:GetComp(levelRootGO,"off/roomGrayIcon","Image")
                    self:SetSprite(image,"UI_Common",roomCfg.decorate_icon[i])
                end
            else
                levelRootGO:SetActive(false)
            end
        end

        --等级进度Arrow
        for i = 1, 2 do
            local arrowRootGO = self:GetGo(panelRootGO,"schedule/arrow"..i)
            local nodeLevel = roomLevelNodeList[i+1] ---节点对应的房间等级
            if nodeLevel <= roomMaxLevel then
                if nodeLevel <= roomLevel then
                    self:GetGo(arrowRootGO,"greenArrow"):SetActive(true)
                    self:GetGo(arrowRootGO,"grayArrow"):SetActive(false)
                else
                    self:GetGo(arrowRootGO,"greenArrow"):SetActive(false)
                    self:GetGo(arrowRootGO,"grayArrow"):SetActive(true)
                end
            else
                arrowRootGO:SetActive(false)
            end
        end
    end
end

---按下房间升级界面中的升级按钮
function CycleNightClubBuildingUIView:OnRoomUpgradeBtnDown()
    local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
    --升级中
    if not roomData.isUpgrading then
        if self:RoomNeedUpgrade() then
            local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
            local maxLevel = self.m_currentInstanceModel:GetRoomMaxLevel(self.roomID)
            if roomLevel < maxLevel then
                local result,_ = self.m_currentInstanceModel:UpgradeRoom(self.roomID)
                if result == CycleInstanceDefine.RoomUpgradeResult.Success then
                    self:RefreshRoomUpgradePanel()
                    self:DestroyModeUIObject()
                elseif result == CycleInstanceDefine.RoomUpgradeResult.ResNotEnough then
                    --ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
                    --    self:DestroyModeUIObject()
                    --    GameTableDefine.CycleNightClubShopUI:GetView()
                    --end)
                end
            else
                printf("已经满级,无法升级")
            end
        end
    end
end

---按下房间升级跳过按钮
function CycleNightClubBuildingUIView:OnUpgradeSkipBtnDown()
    local roomData = self.m_currentInstanceModel:GetCurRoomData(self.roomID)
    if roomData.completeTime == 0 then
        return
    end
    local curTime = GameTimeManager:GetCurrentServerTime()
    local endPoint = roomData.completeTime
    local timeNeed = endPoint - curTime
    local skipDiamond = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    local diamondNeed = skipDiamond * math.ceil(timeNeed / 60)
    local isEnough = ResourcesManager:CheckDiamond(diamondNeed)

    --self.m_roomUpgradeSkipCostText = tostring(diamondNeed * math.ceil(timeNeed/60))

    if isEnough then
        ResourcesManager:SpendDiamond(diamondNeed, nil, function(success)
            if success then
                roomData.completeTime = 0
                self:RefreshRoomUpgradePanel()
                CycleInstanceDataManager:GetCycleInstanceMainViewUI():Refresh()
                LocalDataManager:WriteToFile()
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "加速副本房间升级", behaviour = 2, num = diamondNeed})
            end
        end)
    else
        --跳转商城
        ChooseUI:Choose("TXT_INSTANCE_SHOP_TIP",function()
            GameTableDefine.CycleNightClubShopUI:GetView()
        end)
    end
end

---点击对话框
function CycleNightClubBuildingUIView:OnPersonTalkBtnDown()
    local roomID = self.roomID
    local roomCfg = roomsConfig[self.roomID]

    --判断是否上架
    local isSelling = self.m_currentInstanceModel:ProductIsSelling(roomCfg.production)
    if not isSelling then
        self.m_notPlayExitCameraMove = true
        GameUIManager:SetEnableTouch(false)
        self:DestroyModeUIObject(false,function()
            --打开码头界面
            local sellsID = CycleInstanceDataManager:GetCurrentModel():GetRoomDataByType(4)
            local sellID = sellsID[1].roomID
            CycleInstanceDataManager:GetCurrentModel():GetScene():LookAtSceneGO(sellID,nil,nil,nil,function()
                GameTableDefine.CycleNightClubSellUI:ShowWharfUI(sellID)
                GameTimer:CreateNewTimer(0.5,function()
                    GameUIManager:SetEnableTouch(true)
                    GuideManager.currStep = 15501
                    GuideManager:ConditionToStart()
                end)
            end)
        end)
        return
    end

    --计算所有产出
    local productionNum, expNum, pointNum = self.m_currentInstanceModel:GetRoomProduction(self.roomID)

    --获取原料信息
    local showNeed = Tools:GetTableSize(roomCfg.material) > 1
    --检测当前的消耗是否足够
    if showNeed then
        local needID = roomCfg.material[1]
        --库存
        local storedResData = self.m_currentInstanceModel:GetProdutionsData()
        local needResCount = BigNumber:Multiply(productionNum, roomCfg.material[2])
        local storedResCount = storedResData[tostring(needID)] or 0
        if not BigNumber:CompareBig(storedResCount,needResCount) then
            local resRoomID = self.m_currentInstanceModel:GetRoomByProduction(needID)
            self.m_notPlayExitCameraMove = true
            self:DestroyModeUIObject(false,function()
                GameUIManager:SetEnableTouch(false)
                CycleInstanceDataManager:GetCurrentModel():GetScene():LookAtSceneGO(resRoomID,nil,nil,nil,function()
                    CycleNightClubBuildingUI:ShowFactoryUI(resRoomID)
                    GameTimer:CreateNewTimer(0.5,function()
                        GameUIManager:SetEnableTouch(true)
                    end)
                end)
            end)
            return
        end
    end

    if not self.m_haveTalkContent then
        local textLen = roomCfg.txt_list and #roomCfg.txt_list or 0
        if textLen > 0 then
            --随机一个和上次不一样的对话
            local curIndex = math.random(1,textLen)
            if curIndex == self.m_personTalkRandomIndex then
                curIndex = curIndex + 1
                if curIndex > textLen then
                    curIndex = 1
                end
            end
            self.m_personTalkRandomIndex = curIndex
            local txt = roomCfg.txt_list[curIndex]
            self.m_personTalkRandomTxt = GameTextLoader:ReadText(txt)
            --self.m_personTalkText.text = self.m_personTalkRandomTxt
            self:PlayTextReveal(txt)
            --显示3秒
            self.m_personTalkHideTime = GameTimeManager:GetCurrentServerTime() + 3
            self:UpdatePersonTalk()
            if not self.m_personTalkRandomTxtTimer then
                self.m_personTalkRandomTxtTimer = GameTimer:CreateNewTimer(1,function()
                    self:UpdatePersonTalk()
                end,true)
            end
            return
        end
    end

    if not self.m_haveTalkContent then
        self:DestroyModeUIObject()
    end
end

---启动和更新家具闪烁
function CycleNightClubBuildingUIView:StartGlinting()
    --self.m_glintingStopTime = GameTimeManager:GetCurrentServerTime() + GlintingTime

    --新规则的家具闪烁
    local furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(self.roomID,1)
    GlintingManager:DoGlinting(furGO)
    local room = self.m_currentInstanceModel:GetScene():GetRoomByID(self.roomID)
    GlintingManager:DoGlinting(room.roomGO.modelRoot)

    self.m_glintingStopTime = GameTimeManager:GetCurrentServerTimeInMilliSec()/1000.0 + GlintingManager:ResetGlinting()

    if not self.m_glintingTimer then
        self.m_glintingTimer = GameTimer:CreateNewTimer(0.01,function()
            local time = GameTimeManager:GetCurrentServerTimeInMilliSec()/1000.0
            if time >= (self.m_glintingStopTime or 0)then
                self:StopGlinting()
            end
        end,true,true)
    end
end

---关闭家具闪烁
function CycleNightClubBuildingUIView:StopGlinting()
    if not self.m_glintingTimer then
        return
    end
    GameTimer:StopTimer(self.m_glintingTimer)
    self.m_glintingTimer = nil

    local furGO = self.m_currentInstanceModel:GetSceneRoomFurnitureGo(self.roomID,1)
    GlintingManager:RevertGlinting(furGO)
    local room = self.m_currentInstanceModel:GetScene():GetRoomByID(self.roomID)
    GlintingManager:RevertGlinting(room.roomGO.modelRoot)
end

--endregion

---刷新家具等级奖励
---@param isUpgrade boolean -是否是升级导致的刷新
function CycleNightClubBuildingUIView:RefreshFurLevelReward(isUpgrade)

    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local furniture_id = currentFurLevelCfg.furniture_id
    --local currentFurCfg = furnitureConfig[furniture_id]

    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
    local roomLevelCfg = self.m_currentInstanceModel:GetRoomLevelConfig(self.roomID,roomLevel)
    local curRoomLevelRewards = {}
    local roomFurLevelRange = roomLevelCfg.fur_levelRange
    --可能会有性能问题.
    --遍历这个家具的FurLevelConfig找出该房间等级对应的里程碑奖励节点.
    for i = roomFurLevelRange[1], roomFurLevelRange[2] do
        local furLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(furniture_id,i)
        if furLevelCfg.milePoint_node then
            curRoomLevelRewards[#curRoomLevelRewards+1] = furLevelCfg
        end
    end
    --理论上是3个.
    local rewardGOCount = #self.m_furLevelRewardGOs
    for i = 1, rewardGOCount do
        local offGO = self:GetGo(self.m_furLevelRewardGOs[i],"off")
        offGO:SetActive(currentFurLevelCfg.level>=curRoomLevelRewards[i].level)
        local rewardText = self:GetComp(self.m_furLevelRewardGOs[i],"Lv","TMPLocalization")
        rewardText.text = BigNumber:FormatBigNumber(curRoomLevelRewards[i].milePoint_node)
    end

    if isUpgrade then
        if currentFurLevelCfg.milePoint_node then
            --飞图标 副本积分
            local currentIndex = 1
            for i = 1, 3 do
                if curRoomLevelRewards[i].level == currentFurLevelCfg.level then
                    currentIndex = i
                    break
                end
            end
            FlyIconsUI:ShowCycleMilepost(currentIndex,"Instance4_Milepost_Fly",BigNumber:FormatBigNumber(currentFurLevelCfg.milePoint_node),function()
                self.m_currentInstanceModel:AddScore(currentFurLevelCfg.milePoint_node)
                CycleNightClubMainViewUI:PlayMilestoneAnim()
            end)
        end
    end

end

---检查是否需要开启房间升级引导(暂时没启用)
--function CycleNightClubBuildingUIView:CheckRoomUpgradeGuide()
--    --1.是否是1号房间
--    if self.roomID ~= 1021 then
--        return false
--    end
--    --2.是否触发过引导
--    self.m_currentInstanceModel:IsGuideCompleted()
--    local curFurLevelID = self.factoryFurData["1"].id --当前选中的家具levelID
--    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
--    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
--    local nextFurLevelCfg = self.m_currentInstanceModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)
--    --3.房间等级能否升级
--    --判断房间等级需求
--    local roomLevel = self.m_currentInstanceModel:GetRoomLevel(self.roomID)
--    if nextFurLevelCfg.room_level and nextFurLevelCfg.room_level > roomLevel then
--
--    else
--        return false
--    end
--    --4.是否有钱升级
--
--end


return CycleNightClubBuildingUIView
