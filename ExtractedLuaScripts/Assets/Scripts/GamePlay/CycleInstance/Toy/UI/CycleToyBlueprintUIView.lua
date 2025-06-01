
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3
local Input = CS.UnityEngine.Input
local UILayer = CS.UnityEngine.LayerMask.NameToLayer("UI")
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local UnityTime = CS.UnityEngine.Time

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local CycleToyBluePrintManager = GameTableDefine.CycleToyBluePrintManager
local GameTimer = GameTimer
local PRODUCT_MODEL_PATH = "Assets/Res/Prefabs/Toy_factory/toy/"
local AnimationUtil = CS.Common.Utils.AnimationUtil
local LoadAnimName = "ToyBlueprintModel_scale"
local UnloadAnimName = "ToyBlueprintModel_downscale"
local CycleToyBlueprintUI = GameTableDefine.CycleToyBlueprintUI

local ResTypeCount = 4
local StarGOPathName = {
    [1] = "star/star_1",
    [2] = "star/star_2",
    [3] = "star/star_3",
    [4] = "star/star_4",
    [5] = "star/star_5",
}

local GroupIndex = {
    [1] = 207,
    [2] = 208,
    [3] = 209
}

local DEFAULT_ROTATE_SPEED = -30
local ROTATE_CD = 1

---@class ResCombineGroup
---@field curIconImage UnityEngine.UI.Image
---@field curCountText UnityEngine.UI.Text
---@field nextIconImage UnityEngine.UI.Image
---@field nextCountText UnityEngine.UI.Text
---@field upgradeBtn UnityEngine.UI.Button
--@field vfxAnimation UnityEngine.Animation
local ResCombineGroup = {}

---@class CycleToyBlueprintUIView:UIBaseView
local CycleToyBlueprintUIView = Class("CycleToyBlueprintUIView", UIView)

function CycleToyBlueprintUIView:ctor()
    self.super:ctor()

    self.m_modelPivot = nil ---@type UnityEngine.Transform
    self.m_productModelGO = nil ---@type UnityEngine.GameObject
    self.m_bluePrintModelGO = nil ---@type UnityEngine.GameObject
    self.m_bluePrintModelAnimator = nil ---@type UnityEngine.Animator

    self.m_resTitleImageList = {} ---@type UnityEngine.UI.Image[]
    self.m_resNumTextList = {} ---@type UnityEngine.UI.Text[]
    self.m_productionScrollRectEX = nil ---@type UnityEngine.UI.ScrollRectEx
    self.m_starGOListOn = {} ---@type UnityEngine.GameObject[]
    self.m_starGOListOff = {} ---@type UnityEngine.GameObject[]
    self.m_productionNameText = nil ---@type UnityEngine.UI.Text
    self.m_productionUpgradeBtn = nil ---@type UnityEngine.UI.Button
    self.m_productionUpgradeBtnMaxMark = nil ---@type UnityEngine.GameObject
    self.m_productionUpgradeResTypeIcon = nil ---@type UnityEngine.UI.Image
    self.m_productionUpgradeResCountText = nil ---@type UnityEngine.UI.Image
    self.m_buffMile1Text = nil ---@type UnityEngine.UI.Text
    self.m_buffMile2Text = nil ---@type UnityEngine.UI.Text
    self.m_buffMile2ArrowGO = nil ---@type UnityEngine.GameObject
    self.m_buffMoney1Text = nil ---@type UnityEngine.UI.Text
    self.m_buffMoney2Text = nil ---@type UnityEngine.UI.Text
    self.m_buffMoney2ArrowGO = nil ---@type UnityEngine.GameObject
    self.m_roomNameText = nil ---@type UnityEngine.UI.Text
    self.m_productionIcon = nil ---@type UnityEngine.UI.Image

    self.m_resCombineGroupList = nil ---@type ResCombineGroup[]

    self.m_currentModel = nil ---@type CycleToyModel
    self.m_resConfigs = nil
    self.m_bpConfigList = nil ---@type table<number,ConfigBluePrint[]> -玩具ID为key的蓝图配置
    self.m_productionConfigs = nil
    self.m_toyCount = 0

    self.m_selectedProductionIndex = -1---正在显示的玩具index
    self.m_currentModelPath = nil ---当前正显示的模型路径
    self.m_needUnlockIndex = nil ---需要播放解锁动画的index
    self.m_loadAnimLength = 1
    self.m_unLoadAnimLength = 1

    self.m_lastUnlockAnimation = nil ---记录上次播放解锁动画的Animation,下次遇到需要还原动画
    self.m_lastUnlockAnimName = nil
    self.m_lastUnlockTrans = nil
    self.m_currentModelName = nil
    self.m_unloadAnimTimer = nil
    self.m_loadAnimTimer = nil
end

function CycleToyBlueprintUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("background/Title/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.m_resConfigs = CycleToyBluePrintManager:GetResConfigs()
    self.m_bpConfigList = self.m_currentModel.config_cy_instance_blueprint
    self.m_productionConfigs = CycleToyBluePrintManager:GetProductionConfigs()
    self.m_toyCount = #self.m_productionConfigs

    --资源栏
    local resParentGO = self:GetGo("background/Title")
    for i = 1, ResTypeCount do
        self.m_resTitleImageList[i] = self:GetComp(resParentGO,"res_"..i.."/icon","Image")
        self.m_resNumTextList[i] = self:GetComp(resParentGO,"res_"..i.."/num","TMPLocalization")
    end

    --产品详情
    self.m_productionNameText = self:GetComp("background/resPanel/upgradePanel/text","TMPLocalization")
    local starParentGO = self:GetGo("background/3DShow")
    for i = 1, CycleToyBluePrintManager.PRODUCTION_LEVEL_MAX do
        local starGO = self:GetGo(starParentGO,StarGOPathName[i])
        self.m_starGOListOn[i] = self:GetGo(starGO,"open")
        self.m_starGOListOff[i] = self:GetGo(starGO,"off")
    end

    --产品列表
    self.m_productionScrollRectEX = self:GetComp("background/BottomPanel/list","ScrollRectEx")
    self:SetListItemNameFunc(self.m_productionScrollRectEX,function(index)
        return "temp"
    end)
    self:SetListItemCountFunc(self.m_productionScrollRectEX,function()
        return self.m_toyCount
    end)

    --产品升级界面
    self.m_productionUpgradeBtn = self:GetComp("background/resPanel/upgradePanel/btn","Button")
    self:SetButtonClickHandler(self.m_productionUpgradeBtn,handler( self,self.OnProductionUpgradeBtnDown))
    self.m_productionUpgradeBtnMaxMark = self:GetGo(self.m_productionUpgradeBtn.gameObject,"max")
    self.m_productionUpgradeResTypeIcon =
        self:GetComp("background/resPanel/upgradePanel/btn/blueprint/cost/icon","Image")
    self.m_productionUpgradeResCountText =
        self:GetComp("background/resPanel/upgradePanel/btn/blueprint/cost/num","TMPLocalization")
    self.m_buffMile1Text =
        self:GetComp("background/resPanel/upgradePanel/buffShow/milepoint/num1","TMPLocalization")
    self.m_buffMile2Text =
        self:GetComp("background/resPanel/upgradePanel/buffShow/milepoint/num2","TMPLocalization")
    self.m_buffMoney1Text =
        self:GetComp("background/resPanel/upgradePanel/buffShow/money/num1","TMPLocalization")
    self.m_buffMoney2Text =
        self:GetComp("background/resPanel/upgradePanel/buffShow/money/num2","TMPLocalization")
    self.m_roomNameText =
        self:GetComp("background/resPanel/upgradePanel/toy/roomName/bg/text","TMPLocalization")
    self.m_buffMile2ArrowGO = self:GetGo("background/resPanel/upgradePanel/buffShow/milepoint/arr")
    self.m_buffMoney2ArrowGO = self:GetGo("background/resPanel/upgradePanel/buffShow/money/arr")
    self.m_productionIcon = self:GetComp("background/resPanel/upgradePanel/toy/bg/toyIcon","Image")

    --升级材料合成界面
    self.m_resCombineGroupList = {}
    local resCombinePanelGO = self:GetGo("background/resPanel/exchangePanel")
    for i = 1, ResTypeCount-1 do
        local group = {} ---@type ResCombineGroup
        self.m_resCombineGroupList[i] = group
        local groupParentGO = self:GetGo(resCombinePanelGO,"ex_"..i)
        group.curIconImage = self:GetComp(groupParentGO,"Icons/res_"..i,"Image")
        group.curCountText = self:GetComp(group.curIconImage.gameObject,"num","TMPLocalization")
        group.nextIconImage = self:GetComp(groupParentGO,"Icons/res_"..(i+1),"Image")
        group.nextCountText = self:GetComp(group.nextIconImage.gameObject,"num","TMPLocalization")
        group.upgradeBtn = self:GetComp(groupParentGO,"btn","Button")
        --group.vfxAnimation = self:GetComp(groupParentGO,"vfx_fly_icon","Animation")
        local groupIndex = i
        self:SetButtonClickHandler(group.upgradeBtn,function()
            self:OnCombineBtnDown(groupIndex)
        end)
    end

    self:SetListUpdateFunc(self.m_productionScrollRectEX,handler(self,self.UpdateProductList))

    self:SlideProduct()
    self:CalculateMouseDisplacement()
    self:LoadBluePrintModel()
end

function CycleToyBlueprintUIView:InitCamera()
    local camera = self:GetComp(self.m_bluePrintModelGO,"ModelCamera","Camera")
    if camera then
        local modelIcon = self:GetComp("background/3DShow/Model","Image")
        local renderTexture = modelIcon.material:GetTexture("_BaseMap")
        if renderTexture then
            camera.targetTexture = renderTexture
        end
    end
end

function CycleToyBlueprintUIView:OnExit()

    local camera = self:GetComp(self.m_bluePrintModelGO,"ModelCamera","Camera")
    if camera then
        camera.targetTexture = nil
    end

    self.super:OnExit(self)

    if self.m_bluePrintModelGO and not self.m_bluePrintModelGO:IsNull() then
        UnityHelper.DestroyGameObject(self.m_bluePrintModelGO)
        self.m_bluePrintModelGO = nil
        self.m_modelPivot = nil
    end

    if self.m_slideTimer then
        GameTimer:StopTimer(self.m_slideTimer)
    end
    if self.m_mouseTimer then
        GameTimer:StopTimer(self.m_mouseTimer)
    end
end


function CycleToyBlueprintUIView:Init(productID)
    self:FindUnlockProduction()
    self.m_productionScrollRectEX:UpdateData(true)
    local targetIndex = 1
    if productID then
        local findIndex = self:GetProductIndex(productID)
        if findIndex ~= -1 then
            targetIndex = findIndex
        end
    end
    self:SetShowProductionIndex(targetIndex)
    self:InitTitlePanel()
    self:InitResCombiningPanel()
    self:PlayUnlockProductAnim()
end

---找到刚解锁的ProductionIndex
function CycleToyBlueprintUIView:FindUnlockProduction()

    local lastUnlockProductID = CycleToyBluePrintManager:GetLastUnlockProductID() or 0
    local needUnlockProductIndex = nil
    local productCount = #self.m_productionConfigs
    for index = 1, productCount do
        local productionCfg = self.m_productionConfigs[index]
        local productID = productionCfg.id
        if productID>lastUnlockProductID then
            local isUnlocked = self:IsProductUnlock(productID)
            if isUnlocked then
                needUnlockProductIndex = index
            else
                break
            end
        end
    end
    if needUnlockProductIndex then
        self.m_needUnlockIndex = needUnlockProductIndex
    end
end

---解锁流程
function CycleToyBlueprintUIView:PlayUnlockProductAnim()

    local needUnlockProductIndex = self.m_needUnlockIndex
    if needUnlockProductIndex then
        local productionCfg = self.m_productionConfigs[needUnlockProductIndex]
        local productID = productionCfg.id
        GameUIManager:SetEnableTouch(false)
        --1.滑动到解锁的位置
        self.m_productionScrollRectEX:ScrollTo(needUnlockProductIndex)
        --2.等待1s , scrollRect滑动结束
        GameTimer:CreateNewTimer(1,function()
            --3.播放解锁动画
            local trans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(needUnlockProductIndex-1)
            if not trans or trans:IsNull() then
                trans = self.m_productionScrollRectEX:GetScrollItem(needUnlockProductIndex-1)
            end
            local lockAnimation = self:GetComp(trans.gameObject,"lockMask","Animation")
            local find, name = AnimationUtil.GetFirstClipName(lockAnimation)
            if find then
                AnimationUtil.Play(lockAnimation, name, function()
                    --4.记录需要还原的动画
                    --AnimationUtil.Play(lockAnimation,name,nil,0)
                    self.m_lastUnlockAnimation = lockAnimation
                    self.m_lastUnlockAnimName = name
                    self.m_lastUnlockTrans = trans

                    CycleToyBluePrintManager:SetLastUnlockProductID(productID)
                    lockAnimation.gameObject:SetActive(false)
                    self.m_needUnlockIndex = nil
                    self:UpdateProductList(needUnlockProductIndex-1,trans)
                    GameUIManager:SetEnableTouch(true)
                end)
            else
                lockAnimation.gameObject:SetActive(false)
                GameUIManager:SetEnableTouch(true)
            end
        end)
    end
end

---单纯刷新星级
function CycleToyBlueprintUIView:UpdateProductItemStar(go, level)
    for i = 1, CycleToyBluePrintManager.PRODUCTION_LEVEL_MAX do
        local starGO = self:GetGoOrNil(go,StarGOPathName[i])
        if starGO then
            self:GetGo(starGO,"off"):SetActive(i>level)
            self:GetGo(starGO,"open"):SetActive(i<=level)
        end
    end
end

---产品是否解锁
function CycleToyBlueprintUIView:IsProductUnlock(productID)
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local baseBpConfig = bluePrintConfigs[1]
    local roomID = baseBpConfig.room_id

    local isUnlocked = self.m_currentModel:RoomIsUnlock(roomID)
    return isUnlocked
end

---单纯刷新产品可升级标志
function CycleToyBlueprintUIView:RefreshAllProductItemUpgradeableMark()
    local productCount = #self.m_productionConfigs
    for index = 1, productCount do
        local productionCfg = self.m_productionConfigs[index]
        local productID = productionCfg.id
        local isUnlocked = self:IsProductUnlock(productID)
        if isUnlocked then
            local trans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(index-1)
            if trans and not trans:IsNull() then
                self:GetGo(trans.gameObject,"upgradeIcon"):SetActive(CycleToyBluePrintManager:CanUpgradeProduction(productID))
            end
        end
    end
end

function CycleToyBlueprintUIView:UpdateProductList(index, trans)
    index = index + 1
    local go = trans.gameObject

    --基础信息
    local productionCfg = self.m_productionConfigs[index]
    local productID = productionCfg.id
    local productIconImage = self:GetComp(go,"toyIcon","Image")
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local toyData = CycleToyBluePrintManager:GetProductionDataByProductID(productID)
    local level = toyData.starLevel or 1
    local bpConfigNow = bluePrintConfigs[level]
    self:SetSprite(productIconImage,"UI_Common",bpConfigNow.icon)

    self:UpdateProductItemStar(go,level)

    --是否解锁,正在解锁中的也有锁
    local isUnlocked = self:IsProductUnlock(productID) and index ~= self.m_needUnlockIndex
    self:GetGo(go,"lockMask"):SetActive(not isUnlocked)
    --是否可升级
    local canUpgrade = CycleToyBluePrintManager:CanUpgradeProduction(productID)
    self:GetGo(go,"upgradeIcon"):SetActive(isUnlocked and canUpgrade)
    --是否选中
    local selectedMarkGO = self:GetGo(go,"select")
    selectedMarkGO:SetActive(self.m_selectedProductionIndex == index)

    --是否需要还原动画
    if not isUnlocked and trans == self.m_lastUnlockTrans then
        AnimationUtil.Play(self.m_lastUnlockAnimation,self.m_lastUnlockAnimName,nil,0)
        self.m_lastUnlockTrans = nil
        self.m_lastUnlockAnimation = nil
        self.m_lastUnlockAnimName = nil
    end

    --点击
    local clickBtn = self:GetComp(go,"","Button")
    clickBtn.interactable = isUnlocked
    self:SetButtonClickHandler(clickBtn,function()
        if isUnlocked then
            self:SetShowProductionIndex(index)
        end
    end)
end

function CycleToyBlueprintUIView:GetProductIndex(productID)
    local productCount = #self.m_productionConfigs
    for i = 1, productCount do
        local productionCfg = self.m_productionConfigs[i]
        local id = productionCfg.id
        if id == productID then
            return i
        end
    end
    return -1
end

---选中对应产品
function CycleToyBlueprintUIView:SetShowProductionIndex(index)
    local lastIndex = self.m_selectedProductionIndex
    if lastIndex == index then
        return
    end

    self.m_selectedProductionIndex = index

    if lastIndex > 0 then
        local lastSelectedTrans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(lastIndex-1)
        if lastSelectedTrans and not lastSelectedTrans:IsNull() then
            local selectedMarkGO = self:GetGo(lastSelectedTrans.gameObject,"select")
            selectedMarkGO:SetActive(false)
        end
    end

    local selectedTrans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(index-1)
    if not selectedTrans then
        selectedTrans = self.m_productionScrollRectEX:GetScrollItem(index-1)
    end
    if selectedTrans and not selectedTrans:IsNull() then
        local selectedMarkGO = self:GetGo(selectedTrans.gameObject,"select")
        selectedMarkGO:SetActive(true)
    end

    local productionCfg = self.m_productionConfigs[self.m_selectedProductionIndex]
    local productID = productionCfg.id
    CycleToyBlueprintUI:OnSelectProduction(productID)

    self:RefreshProductionView()
end

function CycleToyBlueprintUIView:RefreshTitle()
    for i = 1, ResTypeCount do
        self.m_resNumTextList[i].text = tostring(CycleToyBluePrintManager:GetUpgradeResCount(self.m_resConfigs[i].id))
    end
end

function CycleToyBlueprintUIView:RefreshProductionView()
    local productionCfg = self.m_productionConfigs[self.m_selectedProductionIndex]
    local productID = productionCfg.id
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local baseBpConfig = bluePrintConfigs[1]
    --产品的名称在产品表中没有配置，是配在蓝图表中的
    self.m_productionNameText.text = GameTextLoader:ReadText(baseBpConfig.name)

    local productionData = CycleToyBluePrintManager:GetProductionDataByProductID(productID)
    local level = productionData.starLevel or 0
    for i = 1, CycleToyBluePrintManager.PRODUCTION_LEVEL_MAX do
        self.m_starGOListOff[i]:SetActive(i>level)
        self.m_starGOListOn[i]:SetActive(i<=level)
    end
    --升级所需材料
    local needResID,needResCount = CycleToyBluePrintManager:GetProductionUpgradeResCount(productID)
    if needResID and needResCount then
        local resConfig = CycleToyBluePrintManager:GetResConfigsByID(needResID)
        local haveResCount = CycleToyBluePrintManager:GetUpgradeResCount(needResID)
        self.m_productionUpgradeBtn.interactable = haveResCount >= needResCount
        self.m_productionUpgradeBtnMaxMark:SetActive(false)
        if resConfig.icon then
            self:SetSprite(self.m_productionUpgradeResTypeIcon,"UI_Common",resConfig.icon)
        end
        self.m_productionUpgradeResCountText.text = tostring(needResCount)
    else
        --已经满级
        self.m_productionUpgradeBtn.interactable = false
        self.m_productionUpgradeBtnMaxMark:SetActive(true)
    end
    --Buff
    local bpConfigNow = bluePrintConfigs[level]
    local bpConfigNext = bluePrintConfigs[level+1]
    if bpConfigNext then
        self.m_buffMile1Text.text = "x"..tostring(bpConfigNow.mile_buff)
        self.m_buffMile2Text.text = "x"..tostring(bpConfigNext.mile_buff)
        self.m_buffMoney1Text.text = "x"..tostring(bpConfigNow.money_buff)
        self.m_buffMoney2Text.text = "x"..tostring(bpConfigNext.money_buff)

        self.m_buffMile2Text.gameObject:SetActive(true)
        self.m_buffMile2ArrowGO.gameObject:SetActive(true)
        self.m_buffMoney2Text.gameObject:SetActive(true)
        self.m_buffMoney2ArrowGO.gameObject:SetActive(true)
    else
        self.m_buffMile1Text.text = "x"..tostring(bpConfigNow.mile_buff)
        --self.m_buffMile2Text.text = tostring(bpConfigNow.mile_buff)
        self.m_buffMoney1Text.text = "x"..tostring(bpConfigNow.money_buff)
        --self.m_buffMoney2Text.text = tostring(bpConfigNow.money_buff)
        self.m_buffMile2Text.gameObject:SetActive(false)
        self.m_buffMile2ArrowGO.gameObject:SetActive(false)
        self.m_buffMoney2Text.gameObject:SetActive(false)
        self.m_buffMoney2ArrowGO.gameObject:SetActive(false)
    end
    --RoomName
    local roomCfg = self.m_currentModel:GetRoomConfigByID(baseBpConfig.room_id)
    self.m_roomNameText.text = GameTextLoader:ReadText(roomCfg.name)
    self:SetSprite(self.m_productionIcon,"UI_Common",bpConfigNow.icon)

    --3D Model
    self:PlayChangeModelAnim(bpConfigNow.model)
end

function CycleToyBlueprintUIView:InitTitlePanel()
    for i = 1, ResTypeCount do
        local resConfig = self.m_resConfigs[i]
        self:SetSprite(self.m_resTitleImageList[i],"UI_Common",resConfig.icon)
    end
    self:RefreshTitle()
end

function CycleToyBlueprintUIView:InitResCombiningPanel()
    for i = 1, ResTypeCount-1 do
        local group = self.m_resCombineGroupList[i]

        local curResConfig = self.m_resConfigs[i]
        local nextResConfig = self.m_resConfigs[i+1]

        self:SetSprite(group.curIconImage,"UI_Common",curResConfig.icon)
        self:SetSprite(group.nextIconImage,"UI_Common",nextResConfig.icon)

        group.curCountText.text = tostring(nextResConfig.cost_num)
        group.nextCountText.text = "1"
    end

    self:RefreshResCombiningPanel()
end

function CycleToyBlueprintUIView:OnProductionUpgradeBtnDown()
    local productID = self.m_productionConfigs[self.m_selectedProductionIndex].id
    local result = CycleToyBluePrintManager:TryUpgradeProduction(productID)
    if result == CycleToyBluePrintManager.BluePrintUpgradeResult.Success then
        self:RefreshProductionView()
        local selectedTrans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(self.m_selectedProductionIndex-1)
        if selectedTrans and not selectedTrans:IsNull() then
            local level = CycleToyBluePrintManager:GetProductionDataByProductID(productID).starLevel
            local bpConfigNow = CycleToyBluePrintManager:GetBPConfigByProductionLevel(productID,level)
            local go = selectedTrans.gameObject
            self:UpdateProductItemStar(selectedTrans.gameObject,level)
            local productIconImage = self:GetComp(go,"toyIcon","Image")
            self:SetSprite(productIconImage,"UI_Common",bpConfigNow.icon)
        end
        self:RefreshTitle()
        self:RefreshResCombiningPanel()
        self:RefreshAllProductItemUpgradeableMark()
        CycleToyBlueprintUI:OnUpgradeProduction(productID)
    elseif result == CycleToyBluePrintManager.BluePrintUpgradeResult.ResNotEnough then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("升级材料不足"))
    elseif result == CycleToyBluePrintManager.BluePrintUpgradeResult.ResNotEnough then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("已经升到满级"))
    end
end

---刷新升级产品按钮的状态
function CycleToyBlueprintUIView:RefreshProductUpgradePanelState()
    local productionCfg = self.m_productionConfigs[self.m_selectedProductionIndex]
    local productID = productionCfg.id
    --升级所需材料
    local needResID,needResCount = CycleToyBluePrintManager:GetProductionUpgradeResCount(productID)
    if needResID and needResCount then
        --local resConfig = CycleToyBluePrintManager:GetResConfigsByID(needResID)
        local haveResCount = CycleToyBluePrintManager:GetUpgradeResCount(needResID)
        self.m_productionUpgradeBtn.interactable = haveResCount >= needResCount
        --self.m_productionUpgradeBtnMaxMark:SetActive(false)
        --if resConfig.icon then
        --    self:SetSprite(self.m_productionUpgradeResTypeIcon,"UI_Common",resConfig.icon)
        --end
        --self.m_productionUpgradeResCountText.text = tostring(needResCount)
    else
        --已经满级
        --self.m_productionUpgradeBtn.interactable = false
        --self.m_productionUpgradeBtnMaxMark:SetActive(true)
    end
end

---第groupIndex个合成按钮按下
function CycleToyBlueprintUIView:OnCombineBtnDown(groupIndex)
    local nextResID = self.m_resConfigs[groupIndex+1].id
    if CycleToyBluePrintManager:TryCombineUpgradeRes(nextResID) then
        self:RefreshResCombiningPanel()
        self:RefreshAllProductItemUpgradeableMark()
        self:RefreshProductUpgradePanelState()
        local flyIcon = GroupIndex[groupIndex]
        EventManager:DispatchEvent("FLY_ICON", nil, flyIcon,nil, function()
            self:RefreshTitle()
        end)
        --播放合成特效
        --local group = self.m_resCombineGroupList[groupIndex]
        --local animation = group.vfxAnimation
        --local find, name = AnimationUtil.GetFirstClipName(animation)
        --if find then
        --    animation.gameObject:SetActive(true)
        --    AnimationUtil.Play(animation, name, function()
        --        self.m_resCombineGroupList[groupIndex].vfxAnimation.gameObject:SetActive(false)
        --        self:RefreshTitle()
        --    end)
        --else
        --    self:RefreshTitle()
        --end
    else
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("合成材料不足"))
    end
end

---刷新资源置换界面
function CycleToyBlueprintUIView:RefreshResCombiningPanel()
    for i = 1, ResTypeCount-1 do
        local groupIndex = i
        local nextResID = self.m_resConfigs[groupIndex+1].id

        local canCombine = CycleToyBluePrintManager:CanCombineUpgradeRes(nextResID)
        local group = self.m_resCombineGroupList[i]
        group.upgradeBtn.interactable = canCombine
    end
end

---加载对应模型到节点下
function CycleToyBlueprintUIView:LoadModel(modelName, callback)
    local modelPath = PRODUCT_MODEL_PATH..modelName..".prefab"
    self.m_currentModelPath = modelPath
    GameResMgr:AInstantiateObjectAsyncManual(modelPath, self, function(go)
        self.m_productModelGO = go
        if modelPath~=self.m_currentModelPath then
            UnityHelper.DestroyGameObject(go)
            return
        end
        UnityHelper.AddChildToParent(self.m_modelPivot, go.transform)
        UnityHelper.SetGameObjectLayerRecursively(go,UILayer)
        if callback then
            callback()
        end
    end)
end

function CycleToyBlueprintUIView:PlayUnloadAnim(callback)
    if self.m_unloadAnimTimer then
        return
    end
    self.m_bluePrintModelAnimator:CrossFade(UnloadAnimName,0.1)
    self.m_unloadAnimTimer = GameTimer:CreateNewTimer(self.m_unLoadAnimLength,function()
        self.m_unloadAnimTimer = nil
        if callback then
            callback()
        end
    end)
end

function CycleToyBlueprintUIView:PlayLoadAnim(callback)
    self.m_bluePrintModelAnimator:CrossFade(LoadAnimName,0.1)
    self.m_loadAnimTimer = GameTimer:CreateNewTimer(self.m_loadAnimLength,function()
        self.m_loadAnimTimer = nil
        if callback then
            callback()
        end
    end)
end

function CycleToyBlueprintUIView:PlayChangeModelAnim(modelName)
    --等待3D模型节点加载完成
    if not self.m_modelPivot then
        return
    end
    self.m_currentModelName = modelName
    local preModelTrans = self.m_productModelGO and self.m_productModelGO.transform or nil
    if not preModelTrans then
        if self.m_modelPivot.childCount > 0 then
            preModelTrans = self.m_modelPivot:GetChild(0)
        end
    end
    if preModelTrans and not preModelTrans:IsNull() then
        if self.m_currentModelName == preModelTrans.gameObject.name then
            return
        end
        self:PlayUnloadAnim(function()
            --删除旧模型
            UnityHelper.DestroyGameObject(preModelTrans.gameObject)
            self.m_productModelGO = nil
            self:LoadModel(self.m_currentModelName,function()
                self:PlayLoadAnim()
            end)
        end)
    else
        self:LoadModel(self.m_currentModelName,function()
            self:PlayLoadAnim()
        end)
    end
end

---加载场景中存放模型的节点
function CycleToyBlueprintUIView:LoadBluePrintModel()
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/CycleInstance/Toy/ToyBlueprintModel.prefab",self,function(go)
        self.m_bluePrintModelGO = go
        self:InitCamera()
        self.m_bluePrintModelAnimator = self:GetComp(go,"","Animator")
        self.m_modelPivot = self:GetTrans(go,"pivot")
        --获取动画时长.
        self.m_loadAnimLength = UnityHelper.GetAnimationLength(self.m_bluePrintModelAnimator,LoadAnimName)
        self.m_unLoadAnimLength = UnityHelper.GetAnimationLength(self.m_bluePrintModelAnimator,UnloadAnimName)

        self:RefreshProductionView()
    end)
end

--滑行屏幕旋转操作
function CycleToyBlueprintUIView:SlideProduct()
    self.m_rotateNum = 0
    self.m_autoRotateCD = 0
    self.m_slideTimer = GameTimer:CreateNewMilliSecTimer(10, function()
        if not self.m_productModelGO then
            return
        end

        local speed = 0
        if math.abs(self.m_rotateNum) < 3 then
            --自动旋转
            if self.m_autoRotateCD < 0 then
                speed = DEFAULT_ROTATE_SPEED * UnityTime.deltaTime
            else
                self.m_autoRotateCD = self.m_autoRotateCD - UnityTime.deltaTime
            end
        else
            --滑屏惯性旋转
            speed = self.m_rotateNum * 0.02
            self.m_rotateNum = self.m_rotateNum * 0.95
            self.m_autoRotateCD = ROTATE_CD
        end
        if speed ~= 0 then
            self.m_productModelGO.transform:Rotate(Vector3.up * (-speed))
        end
    end, true, true)
end

--检测鼠标的位移量用于旋转的计算
function CycleToyBlueprintUIView:CalculateMouseDisplacement()

    local dragArea = self:GetGo("background/3DShow/DragArea")
    UnityHelper.AddUIEventTrigger(dragArea,EventType.Drag,function(pointerEventData)
        local dragDelta = pointerEventData.delta
        self.m_rotateNum = self.m_rotateNum + dragDelta.x
    end)
end

function CycleToyBlueprintUIView:GetHighestBtn()
    local highestIndex = 1
    for i = self.m_toyCount, 1,-1 do
        --基础信息
        local productionCfg = self.m_productionConfigs[i]
        local productID = productionCfg.id

        local isUnlocked = CycleToyBluePrintManager:IsProductUnlock(productID)
        if isUnlocked then
            highestIndex = i
            break
        end
    end

    local highestTrans = self.m_productionScrollRectEX:GetScrollItem(highestIndex-1)
    if highestTrans then
        local btn = self:GetComp(highestTrans.gameObject,"","Button")
        return btn
    end
    return nil
end

function CycleToyBlueprintUIView:GetComp(obj, child, uiType)
    if obj == "GetHighestBtn" then
        return self:GetHighestBtn()
    else
        return self:getSuper(CycleToyBlueprintUIView).GetComp(self,obj, child,uiType)
    end
end

return CycleToyBlueprintUIView