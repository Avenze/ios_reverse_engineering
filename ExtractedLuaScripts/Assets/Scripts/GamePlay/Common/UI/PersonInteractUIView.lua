local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local GameUIManager = GameTableDefine.GameUIManager

local ConfigMgr = GameTableDefine.ConfigMgr
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local MainUI = GameTableDefine.MainUI
local DressUpDataManager = GameTableDefine.DressUpDataManager
local PersonInteractUI = GameTableDefine.PersonInteractUI
local GuideManager = GameTableDefine.GuideManager
---@class PersonInteractUIView:UIBaseView
local PersonInteractUIView = Class("PersonInteractUIView", UIView)
local Vector3 = CS.UnityEngine.Vector3
local Input = CS.UnityEngine.Input

function PersonInteractUIView:ctor()
    self.super:ctor()
    --self.m_data = {}
    self.goodsCfg = nil ---这一分类下的所有config
    self.m_needShowCfg = nil ---所有需要显示的Config(只显示解锁的)
    self.m_listGO = nil
    self.m_emptyGO = nil ---@type UnityEngine.GameObject 没有换装时显示空的提示
    self.m_personIndex = 1
    self.m_isBoss = false
    self.m_personDataList = nil
    self.m_selectPart = 1
end

function PersonInteractUIView:OnEnter()
    self.m_listGO = self:GetGo("RootPanel/equipmentPanel/list")
    self.m_emptyGO = self:GetGo("RootPanel/equipmentPanel/empty")
    --红点
    DressUpDataManager:SetNewDressNotViewed(false)
    MainUI:RefreshCollectionHint()
    --引导
    local GuideData = LocalDataManager:GetDataByKey("guide_data")
    if not GuideData["done900"] then
        GuideManager.currStep = 900
        GuideManager:ConditionToStart()
        GuideManager:ConditionToEnd()
        GuideData["done900"] = true
        LocalDataManager:WriteToFile()
    end

    self:SetButtonClickHandler(self:GetComp("quitBtn","Button"), function()
        self:DestroyModeUIObject()
        -- MainUI:Hideing(true)
        -- GameTableDefine.CollectionUI:Hideing(true)
    end)
    self:SetButtonClickHandler(self:GetComp("leftBtn","Button"), function()
        self:SwitchVariable(true)
    end)
    self:SetButtonClickHandler(self:GetComp("rightBtn","Button"), function()
        self:SwitchVariable()
    end)

    self:InitEvent()
    --self:InitLabelPage()
    --self:SetTemps(dfType)
    self:InitGoodsPage()
    ----旋转初始化
    self.rotateNum = 0
    self:SlidePet()
    self:CalculateMouseDisplacement()
    self.m_constructTriggerGO = self:GetGoOrNil("ContrusctTrigger")
end

function PersonInteractUIView:SetConfigs(part)
    self.m_selectPart = part
    local goodsConfigs = PersonInteractUI:GetEquipmentCfg()[part]
    self.m_needShowCfg = {}
    local index = 1
    for k,v in ipairs(goodsConfigs) do
        if self:CheckHave(v) then
            self.m_needShowCfg[index] = v
            index = index+1
        end
    end
end

function PersonInteractUIView:OnExit()
    GameTimer:StopTimer(self.mouseTime)
    GameTimer:StopTimer(self.slideTime)
    GameTimer:StopTimer(self.backIdle)
    --添加安卓返回键关闭的逻辑处理
    -- self:DestroyModeUIObject()
    local ExitFunc = function()
        GameObject.Destroy(self.roomGo)
        self.roomGo = nil
        MainUI:Hideing(true)
    end

    if self.m_LastUIType then
        if self.m_LastUIType == ENUM_GAME_UITYPE.PERSONAL_INFO_UI then
            GameTableDefine.PersonalInfoUI:OpenPersonalInfoUI(ExitFunc)
        elseif self.m_LastUIType == ENUM_GAME_UITYPE.STATISTIC_UI then
            GameTableDefine.StatisticUI:OpenSelfStatistic()
            ExitFunc()
        end
    else
        ExitFunc()
        GameTableDefine.PetListUI:Hideing(true)
    end
    self.super:OnExit(self)
end

--事件注册
function PersonInteractUIView:InitEvent()
    EventManager:RegEvent("ChangeDressUpSuccess", function(personID, type, part, oldID, newID)
        DressUpDataManager:ChangeDressUp(personID, type, part, oldID, newID)
        PersonInteractUI:GetEquipmentCfg(true)
        --PersonInteractUI:GetPersonData(true)
        self:RefreshInfo()
    end)
end

--刷新显示,刷新角色GO,信息,EquipList
function PersonInteractUIView:Refresh()
    self:RefreshInfo()
    self:SwitchPersonGo()
end

---设置当前换装角色是否是BOSS
function PersonInteractUIView:CurPersonIsBoss()
    local personData = PersonInteractUI:GetPersonData()[self.m_personIndex]
    self.m_isBoss = personData.id == 1 or personData.id == 2
end

---创建标价签
function PersonInteractUIView:RefreshPage()
    if self.m_selectPart == 4 and not self.m_isBoss then
        self:SetConfigs(2)
    end
    local pageCount = Tools:GetTableSize(PersonInteractUI:GetEquipmentCfg())
    self:SetTempGo(self:GetGo("RootPanel/partPanel/ScrollRectEx/Viewport/Content/item"), pageCount, function(i, go)
        self:SetTemp(i, go)
    end)
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function PersonInteractUIView:SetTempGo(temp, num, cb)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    for i = 1,num do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        go:SetActive(true)
        go.name = "temp" .. i
        if cb then
            cb(i, go)
        end
    end
end

---对单个temp进行设置
---@param go UnityEngine.GameObject
function PersonInteractUIView:SetTemp(index, go)
    local num = 1
    local cfg
    local part
    local bgBtn = self:GetComp(go, "bg", "Button")
    local equipCfg = PersonInteractUI:GetEquipmentCfg()
    for k,v in pairs(equipCfg) do
        if num == index then
            if k ~= 4 or self.m_isBoss then --BOSS才显示身体页
                cfg = v
                part = k
                bgBtn.interactable = (k ~= self.m_selectPart)
                go:SetActive(true)
                break
            else
                --type==4 身体 只有BOSS才显示
                go:SetActive(false)
                return
            end
        end
        num = num + 1
    end
    if not self.tempGo then
        self.tempGo = {}
    end
    self.tempGo[part] = bgBtn
    local icon = self:GetComp(go, "bg/icon", "Image")
    local iconPath = "Icon_equipment_hat"
    if part == 1 then -- 头
        iconPath = "Icon_equipment_hat"
    elseif part == 2 then --包
        iconPath = "Icon_equipment_backpack"
    elseif part == 0 then --套装
        iconPath = "Icon_equipment_costume"
    elseif part == 4 then --衣服(Boss专用)
        iconPath = "Icon_equipment_cloth"
    end
    self:SetSprite(icon, "UI_Common", iconPath)
    self:SetButtonClickHandler(bgBtn, function()
        self:ShowInfo()
        self:SetConfigs(part)
        self.currChoice = nil

        self:SwitchPersonGo()
        self:SetTemps(part)
        self:InitGoodsList()
    end)
end

--刷新temp 的 interactable
function PersonInteractUIView:SetTemps(type)
    for k,v in pairs(self.tempGo) do
        v.interactable = (k ~= type)
    end
end

--创建物品页
function PersonInteractUIView:InitGoodsPage()
    self.goodsList = self:GetComp("RootPanel/equipmentPanel/list", "ScrollRectEx")
    self.m_goodsListRect = self:GetComp("RootPanel/equipmentPanel/list","RectTransform") ---@type UnityEngine.RectTransform
    local infoPanelRect = self:GetComp("RootPanel/equipmentPanel/info","RectTransform") ---@type UnityEngine.RectTransform
    local equipmentPanelRect = self:GetComp("RootPanel/equipmentPanel","RectTransform") ---@type UnityEngine.RectTransform
    self.m_hideInfoHeight = equipmentPanelRect.sizeDelta.y
    self.m_showInfoHeight = equipmentPanelRect.sizeDelta.y - infoPanelRect.sizeDelta.y
    self:SetListItemCountFunc(self.goodsList, function()
        --return Tools:GetTableSize(self.goodsCfg)
        return Tools:GetTableSize(self.m_needShowCfg)
    end)
    self:SetListItemNameFunc(self.goodsList, function(index)
        return "Item"
    end)
    self:SetListUpdateFunc(self.goodsList, handler(self, self.UpdateGoodsList))

    --self:InitGoodsList()
end

function PersonInteractUIView:InitGoodsList()
    if #self.m_needShowCfg>0 then
        self.m_emptyGO:SetActive(false)
        self.m_listGO:SetActive(true)
        self.goodsList:UpdateData(true)
    else
        self.m_emptyGO:SetActive(true)
        self.m_listGO:SetActive(false)
    end
end

--设置每个物品标签
function PersonInteractUIView:UpdateGoodsList(index, tran)
    index = index + 1
    local go = tran.gameObject
    local cfg = self.m_needShowCfg[index]
    local left = 0
    local equip = 0
    local normalBtn = self:GetComp(go, "bg/normal", "Button")
    local lockBtn = self:GetComp(go, "bg/lock", "Button")
    if DressUpDataManager:GetCurrentDressUpData(cfg.type) and DressUpDataManager:GetCurrentDressUpData(cfg.type)[cfg.id] then
        left = DressUpDataManager:GetCurrentDressUpData(cfg.type)[cfg.id].left or 0
        equip = DressUpDataManager:GetCurrentDressUpData(cfg.type)[cfg.id].equip or 0
    end
    local icon = self:GetComp(go, "bg/normal/icon", "Image")
    local lockicon = self:GetComp(go, "bg/lock/icon", "Image")
    local have = (equip + left ~= 0)
    self:SetText(go, "bg/normal/storage/num", left .. "/" .. equip + left)
    self:GetGo(go, "bg/lock"):SetActive(not have)
    self:GetGo(go, "bg/normal"):SetActive(have)
    self:GetGo(go, "bg/normal/storage"):SetActive(have)
    self:GetGo(go, "bg/normal/selected"):SetActive(self.currChoice == index)
    local alreadyEquipped = self:CheckAlreadyEquipped(cfg)
    self:GetGo(go, "bg/normal/equiped"):SetActive(alreadyEquipped)
    self:SetSprite(icon, "UI_Shop", cfg.icon)
    self:SetSprite(lockicon, "UI_Shop", cfg.icon)
    self:SetButtonClickHandler(normalBtn, function()
        local canUse = self:CheckCanUse(cfg)
        if canUse or alreadyEquipped then
            self:AddPersonDressUp(cfg)
            self.currChoice = index
            self:ShowInfo(cfg)
            self:InitGoodsList()
        end
        --self.goodsList:UpdateData(true)
        if left == 0 and not alreadyEquipped  then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_EQUIPMENT_EMPTY"))
        end
        if not canUse and left > 0 then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_EQUIPMENT_SEX"))
        end
    end)
    self:SetButtonClickHandler(lockBtn, function()
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_EQUIPMENT_LOCK"))
    end)
end

--显示详细信息页签
function PersonInteractUIView:ShowInfo(cfg)
    local infoGo = self:GetGo("RootPanel/equipmentPanel/info")
    if not cfg then
        infoGo:SetActive(false)
        local sizeDelta = self.m_goodsListRect.sizeDelta
        sizeDelta.y = self.m_hideInfoHeight
        self.m_goodsListRect.sizeDelta = sizeDelta
        return
    else
        local sizeDelta = self.m_goodsListRect.sizeDelta
        sizeDelta.y = self.m_showInfoHeight
        self.m_goodsListRect.sizeDelta = sizeDelta
    end
    local icon = self:GetComp(infoGo, "bg/icon", "Image")
    self:SetSprite(icon, "UI_Shop", cfg.icon)
    self:SetText(infoGo, "bg/desc", GameTextLoader:ReadText(cfg.desc))
    self:SetText(infoGo, "bg/name", GameTextLoader:ReadText(cfg.name))
    local personCfg = PersonInteractUI:GetPersonData()[self.m_personIndex]
    local confirmBtn = self:GetComp(infoGo, "bg/confirmBtn", "Button")
    local unloadBtn = self:GetComp(infoGo, "bg/unloadBtn", "Button")
    local oldID = DressUpDataManager:GetCurrentPersonAllDressUp(personCfg.id)[cfg.part]
    local canUse = self:CheckCanUse(cfg)
    confirmBtn.interactable = canUse
    confirmBtn.gameObject:SetActive(not self:CheckAlreadyEquipped(cfg))
    unloadBtn.gameObject:SetActive(self:CheckAlreadyEquipped(cfg))
    self:SetButtonClickHandler(confirmBtn, function()
        if type(oldID) ~= "number" and 0 == Tools:GetTableSize(oldID) then
            oldID = 0
        end
        EventManager:DispatchEvent("ChangeDressUpSuccess", personCfg.id, cfg.type, cfg.part, oldID, cfg.id)
        self:PlayanimatorAndBackToIdle()
        infoGo:SetActive(false)
    end)
    self:SetButtonClickHandler(unloadBtn, function()
        EventManager:DispatchEvent("ChangeDressUpSuccess", personCfg.id, cfg.type, cfg.part, oldID, 0)
        infoGo:SetActive(false)
        self:Refresh()
    end)
    infoGo:SetActive(true)
end

---检查是否显示某个物件.只显示解锁拥有的
function PersonInteractUIView:CheckHave(cfg)
    --local personCfg = PersonInteractUI:GetPersonData()[self.variable]
    --if not personCfg then
    --    return false
    --end
    local needShow = false
    local num = 0
    local curData = DressUpDataManager:GetCurrentDressUpData(cfg.type)
    if curData and curData[cfg.id] then
        num = curData[cfg.id].left + curData[cfg.id].equip
    end
    needShow = num > 0
    --needShow = num > 0 and (cfg.sex == personCfg.sex or cfg.sex == 3)
    return needShow
end

--检测一个东西能不能用
function PersonInteractUIView:CheckCanUse(cfg)
    local canUse = false
    local personCfg = PersonInteractUI:GetPersonData()[self.m_personIndex]
    if not personCfg then return canUse end
    local num = 0
    if DressUpDataManager:GetCurrentDressUpData(cfg.type) and DressUpDataManager:GetCurrentDressUpData(cfg.type)[cfg.id] then
        num = DressUpDataManager:GetCurrentDressUpData(cfg.type)[cfg.id].left or 0
    end
    canUse = num > 0 and (cfg.sex == personCfg.sex or cfg.sex == 3)
    return canUse
end

--检测一个东西是不是在身上
function PersonInteractUIView:CheckAlreadyEquipped(cfg)
    local alreadyEquipped = false
    local personCfg = PersonInteractUI:GetPersonData()[self.m_personIndex]
    if not personCfg then return alreadyEquipped end
    alreadyEquipped = DressUpDataManager:GetCurrentPersonAllDressUp(personCfg.id)[cfg.part] == cfg.id
    return alreadyEquipped
end

function PersonInteractUIView:SwitchVariable(isReduce)
    --减
    if isReduce then
        self.m_personIndex = self.m_personIndex - 1
        if  self.m_personIndex < 1 then
            self.m_personIndex = Tools:GetTableSize(PersonInteractUI:GetPersonData())
        end
    else
        --加
        self.m_personIndex = self.m_personIndex + 1
        if  self.m_personIndex > Tools:GetTableSize(PersonInteractUI:GetPersonData()) then
            self.m_personIndex = 1
        end
    end
    self:CurPersonIsBoss()
    self:RefreshPage()
    self:Refresh()
end

--刷新信息UI
function PersonInteractUIView:RefreshInfo()
    --self.labelList:UpdateData()
    self:ShowInfo()
    --self.goodsList:UpdateData(true)
    self:InitGoodsList()
end

--清空一个GameObject下的子物体,添加我们想让其添加的物体
function PersonInteractUIView:AddOnlyGo(parentTr, childPath, cb)
    --GameTimer:StopTimer(self.backIdle)
    GameUIManager:SetEnableTouch(false)
    for k,v in pairs(parentTr) do
        GameObject.Destroy(v.gameObject)
    end
    GameResMgr:AInstantiateObjectAsyncManual(childPath, self, function(this)
        GameTimer:CreateNewMilliSecTimer(2,function()
            this.transform.parent = parentTr
            this.transform.position = parentTr.position
            this.transform.rotation = parentTr.rotation

            if self.m_constructTriggerGO then
                self.m_constructTriggerGO:SetActive(false)
                self.m_constructTriggerGO:SetActive(true)
            end

            if cb then cb(this) end
            GameUIManager:SetEnableTouch(true)
        end,false,false)
    end)
end

--切换人物模型
function PersonInteractUIView:SwitchPersonGo()
    GameTimer:StopTimer(self.backIdle)
    local cfgPerson = PersonInteractUI:GetPersonData()[self.m_personIndex]
    if cfgPerson.id == 1 then
        self:SetText("name/txt", cfgPerson.name)
    else
        self:SetText("name/txt", GameTextLoader:ReadText(cfgPerson.name))
    end
    local point = self:GetGo(self.roomGo, "PersonPos")
    local path = "Assets/Res/Prefabs/character/".. cfgPerson.show_prefab ..".prefab"
    local personDressData = DressUpDataManager:GetCurrentPersonAllDressUp(cfgPerson.id)
    if personDressData then
        for k,v in pairs(personDressData) do
            local cfgEquipment = ConfigMgr.config_equipment[v]
            if cfgEquipment.part == 0 then
                path = cfgEquipment.path .. cfgEquipment.prefab .. ".prefab"
                self:AddOnlyGo(point.transform, path, function(this)
                    self.personGo = this
                end)
                return
            end
        end
    end
    self:AddOnlyGo(point.transform, path, function(this)
        self.personGo = this
        if personDressData then
            for k,v in pairs(personDressData) do
                local cfgEquipment = ConfigMgr.config_equipment[v]
                if cfgEquipment.part ~= 0 then
                    self:AddPersonDressUp(cfgEquipment)
                end
            end
            for k,v in pairs(cfgPerson.deco or {}) do
                local canDress = true
                local defCfgEquipment = ConfigMgr.config_equipment[v]
                for i,o in pairs(personDressData) do
                    if ConfigMgr.config_equipment[o].part == defCfgEquipment.part then
                        canDress = false
                        break
                    end
                end
                if canDress then
                    self:AddPersonDressUp(defCfgEquipment)
                end
            end
        end
    end)
end

function PersonInteractUIView:LoadBodyToPersonGO(parentGO,childPath,cb)
    GameUIManager:SetEnableTouch(false)
    GameResMgr:AInstantiateObjectAsyncManual(childPath, self, function(this)
        GameTimer:CreateNewMilliSecTimer(2,function()
            UnityHelper.ChangeSkinnedMeshAndBonesToBoss(parentGO,this)
            UnityHelper.DestroyGameObject(this)
            if cb then cb(this) end
            if self.m_constructTriggerGO then
                self.m_constructTriggerGO:SetActive(false)
                self.m_constructTriggerGO:SetActive(true)
            end
            GameUIManager:SetEnableTouch(true)
        end,false,false)
    end)
end

--给人物添加饰品
function PersonInteractUIView:AddPersonDressUp(cfgEquipment)
    local cfgPerson = PersonInteractUI:GetPersonData()[self.m_personIndex]
    --local personDressData = DressUpDataManager:GetCurrentPersonAllDressUp(cfgPerson.id)
    if not cfgEquipment.prefab then
        print("换装配置表没填prefab "..cfgEquipment.path)
        return
    end
    local path = cfgEquipment.path .. cfgEquipment.prefab .. ".prefab"
    local point = self:GetGo(self.roomGo, "PersonPos")
    if cfgEquipment.part == 0 then
        GameTimer:StopTimer(self.backIdle)
        self:AddOnlyGo(point.transform, path, function(this)
            self.personGo = this
        end)
    else
        local DressUp = function()
            if self.m_isBoss and cfgEquipment.part == 4 then --BOSS 身体单独处理
                --关闭Model
                local personGO = self.personGo
                local modelGO = self:GetGo(personGO,"Model")
                modelGO:SetActive(false)
                --加载身体
                self:LoadBodyToPersonGO(personGO, path, function(go)
                    --UnityHelper.AddChildToParent(personGO.transform, go.transform)
                end)
            else
                local pos
                if cfgEquipment.pos then
                    pos = self:GetGoOrNil(self.personGo, cfgEquipment.pos)
                end
                if pos then
                    self:AddOnlyGo(pos.transform, path, function(this)
                        UnityHelper.AddChildToParent(pos.transform, this.transform)
                    end)
                end
            end
        end
        if self.personGo.name ~= cfgPerson.show_prefab .. "(Clone)" then
            local personPath = "Assets/Res/Prefabs/character/".. cfgPerson.show_prefab ..".prefab"
            GameTimer:StopTimer(self.backIdle)
            self:AddOnlyGo(point.transform, personPath, function(this)
                self.personGo = this
                DressUp()
            end)
        else
            DressUp()
        end
    end
end

--初始化,生成场景预制体同时切相机
function PersonInteractUIView:OpenPersonInteractUINew(cfg, roomGo, openType)
    local OverlayCamera = self:GetComp(roomGo, "Overlay Camera", "Camera")
    self:SetCameraToMainCamera(OverlayCamera)
    self.roomGo  = roomGo
    self.m_personIndex = PersonInteractUI:GetPersonDataById(cfg.id)
    self.m_LastUIType = openType
    for part,_ in pairs(PersonInteractUI:GetEquipmentCfg()) do
        self:SetConfigs(part)
        break
    end
    self:CurPersonIsBoss()
    self:RefreshPage()
    self:Refresh()
end

----生成场景预制体同时切相机
--function PersonInteractUIView:OpenPersonInteractUI(cfg, openType)
--    local roomPath = "Assets/Res/UI/PersonDecorationUI.prefab"
--    GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(this)
--        self.roomGo  = this
--        self.m_personIndex = PersonInteractUI:GetPersonDataById(cfg.id)
--        self.m_LastUIType = openType
--        self:RefreshPage()
--        self:Refresh()
--    end)
--end

--设置相机的渲染将小场景的相机加在主相机上
function PersonInteractUIView:SetCameraToMainCamera(OverlayCamera)
    local mainCamera = GameUIManager:GetSceneCamera()
    UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
end

--滑行屏幕旋转宠物操作
function PersonInteractUIView:SlidePet()
    self.slideTime = GameTimer:CreateNewMilliSecTimer(10, function()
        if math.abs(self.rotateNum) > 150 then
            local speed = math.abs(self.rotateNum/(30))
            if self.rotateNum > 0 then
                self.rotateNum = self.rotateNum  - speed
                if not self.personGo then return end
                self.personGo.transform:Rotate(Vector3.up * speed * 1)
            else
                self.rotateNum = self.rotateNum  + speed
                if not self.personGo then return end
                self.personGo.transform:Rotate(Vector3.up * speed * -1)
            end
        end
    end, true, true)
end

--检测鼠标的位移量用于旋转的计算
function PersonInteractUIView:CalculateMouseDisplacement()
    local starFingerPos
    local endFingerPos
    local distance
    local cd = 50
    self.mouseTime = GameTimer:CreateNewMilliSecTimer(10, function()
        if cd < 0 and starFingerPos then
            starFingerPos = nil
        elseif cd >= 0 then
            cd = cd - 1
        end
        if Input.GetMouseButtonDown(0) then
            starFingerPos = Input.mousePosition
            cd = 50
        end
        if starFingerPos and Input.mousePosition then
            distance = starFingerPos.x - Input.mousePosition.x
        end
        if starFingerPos and math.abs(distance) > 100 then
            if distance * self.rotateNum >= 0 then
                self.rotateNum = self.rotateNum + distance
            else
                self.rotateNum = distance
            end
            starFingerPos = Input.mousePosition
            cd = 50
        end
        if Input.GetMouseButtonUp(0) then
            starFingerPos = nil
        end
    end, true, true)
end

--播放装备动画完成后回到Idle
function PersonInteractUIView:PlayanimatorAndBackToIdle()
    if self.personGo then
        -- local animator = self:GetComp(self.personGo, "", "Animator")
        -- local stateinfo = animator:GetCurrentAnimatorStateInfo()
        -- local Idlelenth = stateinfo.length
        -- animator:SetInteger("Action",34)
        -- self.backIdle =
        -- GameTimer:CreateNewMilliSecTimer(500, function()
        --     if self.personGo then
        --         local animator = self:GetComp(self.personGo, "", "Animator")
        --         local stateinfo = animator:GetCurrentAnimatorStateInfo()
        --         local lenght = stateinfo.length
        --         local normalizedTime = stateinfo.normalizedTime
        --         if Idlelenth and normalizedTime and lenght then
        --             if lenght ~= Idlelenth then
        --                 if normalizedTime >= 0.9 then
        --                     GameTimer:StopTimer(self.backIdle)
        --                     animator:SetInteger("Action",1)
        --                 end
        --             end
        --         end
        --     end
        -- end, true, true)

        local animator = self:GetComp(self.personGo, "", "Animator")
        animator:SetInteger("Action",34)
        --local clips = animator.runtimeAnimatorController.animationClips
        --local length = clips[35].length - 0.1
        local length = UnityHelper.GetAnimationLength(animator,"Victory") - 0.1
        self.backIdle = GameTimer:CreateNewMilliSecTimer(length * 1000, function()
            if not animator then
                animator = self:GetComp(self.personGo, "", "Animator")
            end
            if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PERSON_INTERACT_UI) and self.personGo and animator and not animator:IsNull() then
                animator:SetInteger("Action",1)
            end
        end, false, false)
    end
end

return PersonInteractUIView