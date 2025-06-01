local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local V2 = CS.UnityEngine.Vector2

local CountryMode = GameTableDefine.CountryMode
local ActivityUI = GameTableDefine.ActivityUI
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local PiggyBankUI = GameTableDefine.PiggyBankUI
local CompanysUI = GameTableDefine.CompanysUI
local CompanyMode = GameTableDefine.CompanyMode
local ResMgr = GameTableDefine.ResourceManger
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local ChooseUI = GameTableDefine.ChooseUI
local ConfigMgr = GameTableDefine.ConfigMgr
local MaterialUtil = CS.Common.Utils.MaterialUtil
local StarMode = GameTableDefine.StarMode
local GuideManager = GameTableDefine.GuideManager
local IntroduceUI = GameTableDefine.IntroduceUI
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local PowerManager = GameTableDefine.PowerManager
local CEODataManager = GameTableDefine.CEODataManager
local EventDispatcher = EventDispatcher
local CityMode = GameTableDefine.CityMode
local RenewUI = GameTableDefine.RenewUI

---@class RoomBuildingUIView:UIBaseView
local RoomBuildingUIView = Class("RoomBuildingUIView", UIView)

local ROOM_PROGRESS = "room_progress"

function RoomBuildingUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_currSelectItemIndex = 1
end

function RoomBuildingUIView:StopAllTimer(special)
    if special then
        GameTimer:StopTimer(self.__timers[special])
        self.__timers[special] = nil
        return
    end

    GameTimer:StopTimer(self.__timers[self])
    self.__timers[self] = nil
end

function RoomBuildingUIView:OnEnter()
    EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", false)
    
    self.m_currSelectItemIndex = 1
    print("RoomBuildingUIView:OnEnter")
    self:GetGo("RootPanel/RoomInfo"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
        local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
        -- self.__timers = self.__timers or {}

        
        -- GameTimer:StopTimer(self.__timers[self])
        -- self.__timers[self] = 
        if self.onEnterTimer then
            GameTimer:StopTimer(self.onEnterTimer)
            self.onEnterTimer = nil
        end
        self.onEnterTimer = GameTimer:CreateNewTimer(0.02, function()
            FloorMode:SetFurnitureOnCenter(data, true)
            FloorMode:GetScene():SelectFurniture(nil)
            self:MakeIntroduce()
            self:DestroyModeUIObject()
        end)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/RoomInfo/power/title/quitBtn", "Button"), function()
        local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
        local data = {m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position}
        -- self.__timers = self.__timers or {}

        -- GameTimer:StopTimer(self.__timers[self])
        -- self.__timers[self] = 
        if self.quitBtnTimer then
            GameTimer:StopTimer(self.quitBtnTimer)
            self.quitBtnTimer = nil
        end
        self.quitBtnTimer = GameTimer:CreateNewTimer(0.02, function()
            FloorMode:SetFurnitureOnCenter(data, true)
            FloorMode:GetScene():SelectFurniture(nil)
            self:MakeIntroduce()
            self:DestroyModeUIObject()
        end)
    end)

    local buyButton = self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn", "Button")

    self.buyCount = 0
    self.needPop = false
    self.buyActionReturnDiamond = PiggyBankUI:CalculateEarnings()
    self:SetButtonClickHandler(buyButton, function()
        local dataPanel = self.m_data[self.m_currSelectItemIndex] or {}
        if dataPanel then
            local showStarNeedPanel = dataPanel.fame ~= nil and dataPanel.fame > StarMode:GetStar()
            local isEnoughPanel = ResMgr:CheckEnough(dataPanel.cost.type, dataPanel.cost.num)
            buyButton.interactable = not showStarNeedPanel 
            --2 绿钞 6 欧元，3钻石
            if not isEnoughPanel then
                if dataPanel.cost.type == 2 or dataPanel.cost.type == 6 then
                    GameTableDefine.ShopInstantUI:EnterToCashBuy()
                    return
                elseif dataPanel.cost.type == 3 then
                    GameTableDefine.ShopInstantUI:EnterToDiamondBuy()
                    return
                end   
            end
        end

        buyButton.interactable = false
        local data = self.m_data[self.m_currSelectItemIndex] or {}
        if not self.isPowerRoom and data.power ~= nil and data.power + self.currPower < 0 then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_ELECTRIC"))
            return
        end
        
        FloorMode:BuyFurniture(self.m_currSelectItemIndex, data.id, nil, function()
            if dataPanel.cost.type == 3 then
                GameSDKs:TrackControlCheckData("af", "af,equip_upgrade_diamond_1", {})
            end
            --存钱罐累加值 加一号类型
            local needPop = PiggyBankUI:AddValue(1)
            if needPop and not self.needPop then
                self.needPop = true
            end
            
            EventManager:DispatchEvent("UPGRADE_FACILITIES")
            self.buyCount = self.buyCount + 1
            --调用通行证任务接口，更新任务进度2024-12-23
            GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(5, 1)
            --添加检测活动数据是否满足添加条件，满足的话需要处理一些满足的逻辑
            local data = self.m_data[self.m_currSelectItemIndex] or {}
            local addLevel = data.nextLevel - 1
            if data.isMaxLv then
                addLevel = data.nextLevel
            end

            --2025-4-1下班打卡门票活动添加门票 fy
            local checkClockOutTickets = function(curLevel, isMax)
                -- if isMax then
                --     return 0
                -- end
                if curLevel == 1 then
                    return 1
                elseif curLevel == 2 then
                    return 1
                elseif curLevel == 3 then
                    return 2
                elseif curLevel == 4 then
                    return 2
                elseif curLevel == 5 then
                    return 3
                elseif curLevel == 6 then
                    return 3
                elseif curLevel == 7 then
                    return 5
                elseif curLevel == 8 then
                    return 5
                elseif curLevel == 9 then
                    return 5
                end
                return 0
            end
            GameTableDefine.ClockOutDataManager:AddClockOutTickets(checkClockOutTickets(addLevel, data.isMaxLv), 4)
            if ActivityRankDataManager:PlayerCheckGetRankValue(addLevel) then
                -- TODO：处理特效相关的内容
                EventManager:DispatchEvent("FLY_ICON", nil, 7, nil, function()
                    print("播放排行获取值特效完成")
                end)
            end

            --当玩家购买（升级）具有解锁进度系数配置的房间设施时，需要播放房间进度增长动效动画
            if data.progressValue and data.progressValue > 0 then
                local ani = self:GetComp(self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/prog"), "", "Animation")
                AnimationUtil.Play(ani, "RoomBuild_prog", function()
                    print("当玩家购买（升级）具有解锁进度系数配置的房间设施时，需要播放房间进度增长动效动画")
                end)
            end
        end)
        local data = self.m_data[self.m_currSelectItemIndex] or {}
        local closeBuyButton = data.power + self.currPower < 0 or data.isMaxLv
        if self.isPowerRoom then
            if not data.isMaxLv then
                closeBuyButton = false
            end
        end
        buyButton.gameObject:SetActive(not closeBuyButton)

        local ani = self:GetComp("RootPanel/RoomTitle/HeadPanel/bg/prog/reward", "Animation")
        AnimationUtil.Play(ani, "BoughtEffect_Anim")
        if self.twiceCheckTimer then
            GameTimer:StopTimer(self.twiceCheckTimer)
            self.twiceCheckTimer = nil
        end
        self.twiceCheckTimer = GameTimer:CreateNewTimer(0.1, function() --防止误点2次
            local data = self.m_data[self.m_currSelectItemIndex] or {}
            local showStarNeed = data.fame ~= nil and data.fame > StarMode:GetStar()
            local isEnough = ResMgr:CheckEnough(data.cost.type, data.cost.num)
            buyButton.interactable = not showStarNeed            
            local closeBuyButton = data.power + self.currPower < 0 or data.isMaxLv
            buyButton.gameObject:SetActive(not closeBuyButton)
            --self:AutoNextFurnitureSelect()
        end)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/ebtn", "Button"), function()
        local energyRoomId = nil
        local energyRoomIndex = nil

        local floorConfig = FloorMode:GetCurrFloorConfig() or {}
        for k,roomId in ipairs(floorConfig.room_list or {}) do
            local roomConfig = ConfigMgr.config_rooms[roomId]
            if roomConfig.category[2] == 5 then
                energyRoomId = roomConfig.id
                energyRoomIndex = roomConfig.room_index
                break
            end
        end

        local changeCamera = function()
            self.m_currSelectItemIndex = 1
            self.m_lastFocusItemIndex = nil
            self.m_list:ScrollTo(0)
            self.m_list:UpdateData()

            -- self.__timers = self.__timers or {}
            -- self:StopAllTimer()
            -- self.__timers[self] =
            if self.changeCamTimer then
                GameTimer:StopTimer(self.changeCamTimer)
                self.changeCamTimer = nil
            end
            self.changeCamTimer = GameTimer:CreateNewTimer(0.02, function() --延迟执行，等待CameraFocus位置自动修正完毕
                local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
                FloorMode:SetFurnitureOnCenter({m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position})
            end)
        end

        local roomGo = FloorMode:GetScene():GetRoomRootGoData(energyRoomId)
        local  floorCount = FloorMode:GetCurrFloorConfig().floor_count
        if roomGo.floorNumberIndex ~= FloorMode:GetCurrentFloorIndex() and floorCount ~= 1 then
            FloorMode:SetCurrentFloorIndex(roomGo.floorNumberIndex, nil, function()
                FloorMode:SetCurrRoomInfo(energyRoomIndex, energyRoomId)
                RoomBuildingUI:ShowRoomPanelInfo(energyRoomId)
                changeCamera()
            end)
        else
            FloorMode:SetCurrRoomInfo(energyRoomIndex, energyRoomId)
            RoomBuildingUI:ShowRoomPanelInfo(energyRoomId)
            changeCamera()
        end
    end)

   local text = GameTextLoader:ReadText("TXT_MISC_CANCEL_COST")
    text = string.format(text, ConfigMgr.config_global.cancel_diamond)
    local fireCompany = function (check)
        local cancelSpend = self.m_isMaxCompanyLevel and 0 or ConfigMgr.config_global.cancel_diamond
        if check then
            return ResMgr:CheckDiamond(cancelSpend)
        end
        local cb = function ()
            CompanyMode:FireCompany(FloorMode.m_curRoomIndex, FloorMode.m_curRoomId, 2)
            -- GameSDKs:Track("cost_diamond", {cost = cancelSpend, left = ResMgr:GetDiamond(), cost_way = "解雇公司"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "解雇公司", behaviour = 2, num_new = tonumber(cancelSpend)})
            RoomBuildingUI:ShowRoomPanelInfo(FloorMode.m_curRoomId)
            FloorMode:GetScene():InitRoomGo(FloorMode.m_curRoomId)
        end
        if cancelSpend > 0 then
            ResMgr:SpendDiamond(cancelSpend, nil, cb)
        else
            cb()
        end
    end

    local firButton = self:GetComp("RootPanel/CancelPanel/bg/btn", "Button")
    self:SetText("RootPanel/CancelPanel/bg/btn/bg/num", ConfigMgr.config_global.cancel_diamond)
    firButton.interactable = fireCompany(true)
    self:SetButtonClickHandler(firButton, function()
        fireCompany()
        self:GetGo("RootPanel/CancelPanel"):SetActive(false)
        self:GetGo("RootPanel/BgCover"):SetActive(false)
    end)

    local firFreeButton = self:GetComp("RootPanel/CancelPanel/bg/freebtn", "Button")
    self:SetButtonClickHandler(firFreeButton, function()
        fireCompany()
        self:GetGo("RootPanel/CancelPanel"):SetActive(false)
        self:GetGo("RootPanel/BgCover"):SetActive(false)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/contracBtn", "Button"), function()
        local endPoint = CompanyMode:CompanyExist(FloorMode.m_curRoomIndex).time
        local t = endPoint - GameTimeManager:GetCurrentServerTime()

        if t>0 then
            firButton.gameObject:SetActive(not self.m_isMaxCompanyLevel)
            firFreeButton.gameObject:SetActive(self.m_isMaxCompanyLevel)
            self:GetGo("RootPanel/CancelPanel"):SetActive(true)
            self:GetGo("RootPanel/BgCover"):SetActive(true)
            self:SetButtonClickHandler(self:GetComp("RootPanel/BgCover", "Button"), function()
                self:GetGo("RootPanel/CancelPanel"):SetActive(false)
                self:GetGo("RootPanel/BgCover"):SetActive(false)
            end)


            local show = GameTextLoader:ReadText("TXT_TIME_SHOW")
            local h = math.floor(t/3600)
            local m = math.floor((t - h * 3600) / 60)
            show = string.format(show, h, m)
            self:SetText("RootPanel/CancelPanel/bg/rest_time/resttime", show)
        else
            local roomSaveData = FloorMode:GetRoomLocalData(FloorMode.m_curRoomIndex)
            local leaveCompany = roomSaveData.leaveCompany
            RenewUI:Refresh(leaveCompany, FloorMode.m_curRoomIndex, FloorMode.m_curRoomId)
        end
    end)

    local employeeButton = self:GetComp("RootPanel/BtnPanel/employeeBtn", "Button")
    self:SetButtonClickHandler(employeeButton, function()
        self:GetGo("RootPanel/CompanyPanel"):SetActive(true)
        -- self:GetGo("RootPanel/BgCover"):SetActive(true)
        -- self:SetButtonClickHandler(self:GetComp("RootPanel/BgCover", "Button"), function()
        --     self:GetGo("RootPanel/BgCover"):SetActive(false)
        --     self:GetGo("RootPanel/CompanyPanel"):SetActive(false)
        -- end)
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/CompanyPanel/BgCover", "Button"), function()
        self:GetGo("RootPanel/CompanyPanel"):SetActive(false)
    end)

    self:GetGo("RootPanel/RoomInfo/RoomPanel"):SetActive(true)
    self:GetGo("RootPanel/CompanyPanel"):SetActive(false)
    --self:SetSprite(self:GetComp("RootPanel/RoomPanel/FurnitureInfo/main/info/bonous/quality1/icon", "Image"), "UI_Common", "", nil, true)
    self:SetSprite(self:GetComp("RootPanel/RoomTitle/HeadPanel/bg/income/item/icon", "Image"), "UI_Main", "icon_cash_00" .. CountryMode:GetCurrCountry(), nil, true)
    self:InitEmployeeList()
    self:InitList()

    EventManager:DispatchEvent(GameEventDefine.OnRoomBuildingViewOpen)

   --CEO
    self.m_ceoNode = self:GetGo("RootPanel/BtnPanel/ceoBtn")
    self.m_ceoBtn = self:GetComp(self.m_ceoNode,"","Button")
    self:SetButtonClickHandler(self.m_ceoBtn,function()
        GameSDKs:TrackForeign("ceo_manage", {source = "办公室界面"})
       GameTableDefine.CEODeskUI:Show(FloorMode.m_curRoomIndex, CountryMode:GetCurrCountry())
    end)

    self.m_changeCEOActorHandler = handler(self,self.OnCEOActorChanged)
    EventDispatcher:RegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
    EventDispatcher:RegEvent(GameEventDefine.UpgradeCEODesk,self.m_changeCEOActorHandler)
    EventDispatcher:RegEvent(GameEventDefine.RoomCEOUpgrade,self.m_changeCEOActorHandler)
end

function RoomBuildingUIView:OnCEOActorChanged(roomIndex)
    if FloorMode.m_curRoomIndex == roomIndex then
        self:RefreshCEOInfo()
    end
end

function RoomBuildingUIView:OnPause()
    print("RoomBuildingUIView:OnPause")
end

function RoomBuildingUIView:OnResume()
    print("RoomBuildingUIView:OnResume")
end

function RoomBuildingUIView:MakeIntroduce()
    if self.raiseStar then
        IntroduceUI:StarImprove()
    end
end

function RoomBuildingUIView:OnExit()
    self.super:OnExit(self)
    self.m_data = nil
    self.m_lastFocusItemIndex = nil--引导会调用OnlyExitMainUI,导致这个index不会清空,导致镜头不动,导致锁定不解除
    self.raiseStar = nil
    self:StopAllTimer("roomExp")
    self:StopAllTimer("roomPower")
    self:StopAllTimer("roomCompanyTime")
    if self.setListDataTimeHandler then
        GameTimer:StopTimer(self.setListDataTimeHandler)
        self.setListDataTimeHandler = nil
    end
    if self.effProTimer then
        GameTimer:StopTimer(self.effProTimer)
        self.effProTimer = nil
    end

    if self.selecProTimer then
        GameTimer:StopTimer(self.selecProTimer)
        self.selecProTimer = nil
    end

    if self.onEnterTimer then
        GameTimer:StopTimer(self.onEnterTimer)
        self.onEnterTimer = nil
    end

    if self.quitBtnTimer then
        GameTimer:StopTimer(self.quitBtnTimer)
        self.quitBtnTimer = nil
    end

    if self.twiceCheckTimer then
        GameTimer:StopTimer(self.twiceCheckTimer)
        self.twiceCheckTimer = nil
    end
    if self.changeCamTimer then
        GameTimer:StopTimer(self.changeCamTimer)
        self.changeCamTimer = nil
    end

    -- k124 改为20星之后，才开启存钱罐，没开启时，不飞钻石动效
    if PiggyBankUI:GetPiggyBankEnable() and self.buyCount > 0 then
        local buyActionReturnDiamondCur = PiggyBankUI:CalculateEarnings()
        local addReturnDiamond = buyActionReturnDiamondCur.num - self.buyActionReturnDiamond.num
        GameTableDefine.FlyIconsUI:ShowPiggyBankAnim(addReturnDiamond, function()
            -- 关闭界面后, 飞钻石动效结束, 才弹出存钱罐界面
            if self.needPop then
                PiggyBankUI:OpenView()
                self.needPop = false
            end
        end)
    end

    EventManager:DispatchEvent(GameEventDefine.OnRoomBuildingViewClose)
    EventDispatcher:TriggerEvent(GameEventDefine.RoomBuildingUIViewClose)
    EventDispatcher:UnRegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
    EventDispatcher:UnRegEvent(GameEventDefine.UpgradeCEODesk,self.m_changeCEOActorHandler)
    EventDispatcher:UnRegEvent(GameEventDefine.RoomCEOUpgrade,self.m_changeCEOActorHandler)
    self.m_changeCEOActorHandler = nil
    print("RoomBuildingUIView:OnExit")
end

function RoomBuildingUIView:InitList()
    self.m_list = self:GetComp("RootPanel/RoomInfo/RoomPanel/BuidlingList", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateListItem))

    self.company_list = self:GetComp("RootPanel/CompanyPanel/needBuilding/BuildingNeed", "ScrollRectEx")
    self:SetListItemCountFunc(self.company_list, function()
        return #self.building_require
    end)
    self:SetListUpdateFunc(self.company_list, handler(self, self.UpdateFacilityRequire))
end

function RoomBuildingUIView:ChooseOne(buildingId, buildingLevel)--提前直接选中相应的设施
    if not self.m_data then
        return
    end

    local index = 1
    for k,v in ipairs(self.m_data) do
        if v.id == buildingId and  (buildingLevel == nil or v.hint < buildingLevel) then
            index = k
            break
        end
    end
    self.m_lastFocusItemIndex = nil
    self.m_currSelectItemIndex = index
    self.m_list:UpdateData()
end

function RoomBuildingUIView:UpdateFacilityRequire(index, tran)
    index = index + 1
    local go = tran.gameObject
    local itemData = self.building_require[index]
    if itemData then
        local selectGo = self:GetGo(go, "selected")
        local iconImage = self:GetComp(selectGo, "icon", "Image")
        self:SetSprite(iconImage, "UI_Common", itemData.icon, nil, true)

        local blockImageName = itemData.satisfy and "icon_Employee_green" or "icon_Employee_red"
        local addImageName = itemData.satisfy and "icon_EmployeeLabel_green" or "icon_EmployeeLabel_red"
        local blockImage = self:GetComp(go, "selected", "Image")
        local addImage = self:GetComp(go, "selected/level", "Image")
        -- self:SetSprite(blockImage, "UI_Common", blockImageName)
        -- self:SetSprite(addImage, "UI_Common", addImageName)
        -- 不满足#E65F56（0.9，0.37，0.34）、满足#67BF94（0.4，0.75，0.58）
        local outlineImage = self:GetComp(go, "selected/outline", "Image")
        local levelImage = self:GetComp(go, "selected/level", "Image")
        local r = itemData.satisfy and 0.4 or 0.9
        local g = itemData.satisfy and 0.75 or 0.37
        local b = itemData.satisfy and 0.58 or 0.34
        outlineImage.color = CS.UnityEngine.Color(r, g ,b)
        levelImage.color = CS.UnityEngine.Color(r, g, b)

        self:SetText(selectGo, "level/num", itemData.hint)
        self:GetGo(go, "selected/tip/good"):SetActive(itemData.satisfy)
        self:GetGo(go, "selected/tip/bad"):SetActive(not itemData.satisfy)
    end
end

function RoomBuildingUIView:UpdateListItem(index, tran)
   index = index + 1
    local go = tran.gameObject
    local itemData = self.m_data[index]
    if itemData then
        go.name = index--itemData.id

        local selectGo = self:GetGo(go, "Btn/selected")
        local unlockGo = self:GetGo(go, "Btn/unlocked")
        local lockedGo = self:GetGo(go, "Btn/locked")
        selectGo:SetActive(false)
        unlockGo:SetActive(false)
        lockedGo:SetActive(false)

        local iconImage = self:GetComp(selectGo, "icon", "Image")
        if iconImage.image == nil then
            self:SetSprite(iconImage, "UI_Common", itemData.currIcon, nil, true)
            iconImage = self:GetComp(unlockGo, "icon", "Image")
            self:SetSprite(iconImage, "UI_Common", itemData.currIcon, nil, true)
            iconImage = self:GetComp(lockedGo, "icon", "Image")
            self:SetSprite(iconImage, "UI_Common", itemData.currIcon, nil, true)
        end

        local currStateGo = nil
        if self.m_currSelectItemIndex == index then
            currStateGo = selectGo
        else
            currStateGo = itemData.hint > 0 and unlockGo or lockedGo
        end
        currStateGo:SetActive(true)
        self:SetText(currStateGo, "level/num", itemData.hint)

        self:GetGo(selectGo, "locked"):SetActive(itemData.hint == 0)

        if self.m_currSelectItemIndex == index then
            self:SetSelectItemInfo()
            local lockTarget = FloorMode:GetScene():SelectFurniture(index)
            if self.m_lastFocusItemIndex == self.m_currSelectItemIndex then
                return
            end
            self.m_lastFocusItemIndex = self.m_currSelectItemIndex
            if not lockTarget then
                return
            end

            -- self.__timers = self.__timers or {}
            -- self:StopAllTimer()
            -- self.__timers[self] = 
            if self.selecProTimer then
                GameTimer:StopTimer(self.selecProTimer)
                self.selecProTimer = nil
            end
            self.selecProTimer  = GameTimer:CreateNewTimer(0.02, function() --延迟执行，等待CameraFocus位置自动修正完毕
                local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
                FloorMode:SetFurnitureOnCenter({m_cameraSize=cameraFocus.m_cameraSize, m_cameraMoveSpeed = cameraFocus.m_cameraMoveSpeed, position=cameraFocus.transform.position})
            end)
        end

        --self:SetSprite(self:GetComp(currStateGo, "level/icon", "Image"), "UI_Common", itemData.itemIcon, nil, true)
        self:SetButtonClickHandler(self:GetComp(go, "Btn", "Button"), function()
            if self.m_currSelectItemIndex == index then
                return
            end
            self.m_currSelectItemIndex = index
            self.m_list:UpdateData()
        end)
    end
end

function RoomBuildingUIView:SetPower(isPowerRoom)
    self.mfeel = self:GetComp("RootPanel/RoomInfo/power/PowerLoad/pointer/fb", "MMFeedbacks")
    self:GetGo("RootPanel/RoomInfo/power"):SetActive(isPowerRoom)
    self.isPowerRoom = isPowerRoom
    if isPowerRoom then
        local bg = self:GetGo("RootPanel/bg")
        local currSize = bg.transform.sizeDelta
        local powerSize = self:GetTrans("RootPanel/RoomInfo/power").sizeDelta
        local panelSize = self:GetTrans("RootPanel/RoomTitle/HeadPanel").sizeDelta
        -- bg.transform.sizeDelta = V2(currSize.x, panelSize.y + powerSize.y)

        local power = PowerManager:GetCurrentPower()
        local totalPower = PowerManager:GetTotalPower()
        local warmPower = FloorMode:isWarmPower(power, totalPower)
        local rate = power / totalPower
        local consumRate = 1 - rate
        self:GetGo("RootPanel/RoomInfo/power/PowerLoad/level/1"):SetActive(consumRate <= 0.2)
        self:GetGo("RootPanel/RoomInfo/power/PowerLoad/level/2"):SetActive(consumRate > 0.2 and consumRate <= 0.4)
        self:GetGo("RootPanel/RoomInfo/power/PowerLoad/level/3"):SetActive(consumRate > 0.4 and consumRate <= 0.6)
        self:GetGo("RootPanel/RoomInfo/power/PowerLoad/level/4"):SetActive(consumRate > 0.6 and consumRate <= 0.8)
        self:GetGo("RootPanel/RoomInfo/power/PowerLoad/level/5"):SetActive(consumRate > 0.8)
        local leftPowerTxt = tostring(power)
        if consumRate <= 0.2 then
            leftPowerTxt = Tools:ChangeTextColor(leftPowerTxt, "0DFF18")
        elseif consumRate > 0.2 and consumRate <= 0.4 then
            leftPowerTxt = Tools:ChangeTextColor(leftPowerTxt, "C1FF4C")
        elseif consumRate > 0.4 and consumRate <= 0.6 then
            leftPowerTxt = Tools:ChangeTextColor(leftPowerTxt, "FFFB65")
        elseif consumRate > 0.6 and consumRate <= 0.8 then
            leftPowerTxt = Tools:ChangeTextColor(leftPowerTxt, "FFB12C")
        elseif consumRate > 0.8 then
            leftPowerTxt = Tools:ChangeTextColor(leftPowerTxt, "FF3D00")
        end
        self:SetText("RootPanel/RoomInfo/power/remain/num", leftPowerTxt)
        local percentStr = tostring(math.floor(consumRate*100)).."%"
        self:SetText("RootPanel/RoomInfo/power/rate/num", percentStr)
        local rotate = 180 * consumRate * (-1)
        -- if consumRate > 0.5 then
        --     rotate = 450 - rotate
        -- else
        --     rotate = 90 - rotate
        -- end
        
        self:GetGo("RootPanel/RoomInfo/power/warning"):SetActive(consumRate > 0.8)
        --让rotate从90 一直转到
        local fill = self:GetTrans("RootPanel/RoomInfo/power/PowerLoad/pointer")
        -- local startAngle = fill.transform.localEulerAngles.z
        -- local endAngle = rotate
        if self.mfeel then
            local currFeel = self.mfeel.Feedbacks[0]
            local startAngle = self.saveEndAngle and self.saveEndAngle or 0
            local endAngle = rotate
            currFeel.RemapCurveZero = startAngle
            currFeel.RemapCurveOne = endAngle
            self.mfeel:PlayFeedbacks()
            self.saveEndAngle = endAngle
        end
        -- UnityHelper.SetLocalRotation(fill, 0, 0, rotate)

        self.__timers = self.__timers or {}
        self:StopAllTimer("roomPower")

        -- self.__timers["roomPower"] = GameTimer:CreateNewTimer(0.02, function()
        --     self.currRotate = self.currRotate - 8
        --     UnityHelper.SetLocalRotation(fill, 0, 0, self.currRotate)
        --     if rotate - self.currRotate >= 0 then
        --         UnityHelper.SetLocalRotation(fill, 0, 0, rotate)
        --         self:StopAllTimer("roomPower")
        --         local ani = self:GetComp(fill.gameObject, "pointer", "Animation")
        --         if rate <= 0 then
        --             AnimationUtil.Play(ani, "Pointer_Anim")
        --         else
        --             AnimationUtil.GotoAndStop(ani, "Pointer_Anim")
        --         end
        --     end
        -- end, true, true)

        self:SetText("RootPanel/RoomInfo/power/PowerLoad/num", power, warmPower and "FF3100" or "000000")
    end
end

function RoomBuildingUIView:SetCampanyStateEmployeePanelDispay(isOffice)
    self:GetGo("RootPanel/CompanyPanel/needBuilding/BuildingNeed"):SetActive(isOffice)
    self:GetGo("RootPanel/CompanyPanel/needBuilding/empty"):SetActive(not isOffice)

end

function RoomBuildingUIView:SetHeadPanel(isOffice, name,  profress)
    self.currPower = PowerManager:GetCurrentPower()

    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/title/name", name)
    --self:SetText("RootPanel/RoomTitle/HeadPanel/prog/name", math.floor(profress*100 + 0.5) .."%")
    --self:GetGo("RootPanel/RoomTitle/BtnPanel/toCompany"):SetActive(isOffice)
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/income"):SetActive(isOffice)
    self:GetGo("RootPanel/RoomInfo/CompanyState"):SetActive(isOffice)
    self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/message/contracBtn"):SetActive(isOffice)
    self:GetGo("RootPanel/BtnPanel/employeeBtn"):SetActive(isOffice)
    self:SetCampanyStateEmployeePanelDispay(isOffice)
    self:GetGo("RootPanel/BtnPanel"):SetActive(isOffice)
    if isOffice then
        local bg = self:GetGo("RootPanel/bg")
        local currSize = bg.transform.sizeDelta
        local stateSize = self:GetTrans("RootPanel/RoomInfo/CompanyState").sizeDelta
        local panelSize = self:GetTrans("RootPanel/RoomTitle/HeadPanel").sizeDelta
        -- bg.transform.sizeDelta = V2(currSize.x, panelSize.y + stateSize.y)

        local companyRent = FloorMode:GetCompanyRent(FloorMode.m_curRoomIndex)
        local baseRent = FloorMode:GetRent(FloorMode.m_curRoomIndex)
        local improve = FloorMode:GetSceneEnhance()

        local text = GameTextLoader:ReadText("TXT_HELP_RENT")
        text = string.format(text, math.floor(companyRent * improve), math.floor(baseRent * improve))
        self:SetText("HelpInfo/frame/desc", text)

        local totalRent = (companyRent + baseRent) * improve
        local roomTotalRent = FloorMode:GetSingleOfficeRent(FloorMode.m_curRoomIndex)
        text = GameTextLoader:ReadText("TXT_MISC_ROOM_INCOME_RATE")
        text = string.format(text, math.floor(roomTotalRent))
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/income/item/base", text)

        local companyId = CompanyMode:CompIdByRoomIndex(FloorMode.m_curRoomIndex)
        local satisfy = CompanyMode:IsRoomSatisfy(FloorMode.m_curRoomIndex)
        local haveCompany = companyId and true or false
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/income/item/icon/debuff"):SetActive(haveCompany and not satisfy)
        self:GetGo("HelpInfo/frame/warning"):SetActive(not satisfy)
        self:GetGo("RootPanel/BtnPanel/employeeBtn/tip"):SetActive(not satisfy and companyId ~= nil)
        
        local txtRent = GameTextLoader:ReadText("TXT_MISC_COMPANY_BASERENT")
        txtRent = string.format(txtRent, math.floor(companyRent))
        --新版UI替换注释掉bg1下的逻辑
        -- self:SetText("RootPanel/RoomInfo/CompanyState/bg1/rent", txtRent)
        self:RefreshCEOInfo()
    end
end

function RoomBuildingUIView:RefreshCEOInfo()
    local roomSaveData = FloorMode:GetRoomLocalData(FloorMode.m_curRoomIndex)
    self.m_ceoNode:SetActive(roomSaveData.ceoFurnitureInfo and true or false)
    local ceoBtnGO = self.m_ceoNode
    local ceoNoneGO = self:GetGo(ceoBtnGO,"none")
    local ceoPeopleGO = self:GetGo(ceoBtnGO,"people")
    local ceoID = CEODataManager:GetCEOByRoomIndex(FloorMode.m_curRoomIndex)
    local haveCEO = ceoID and true or false
    ceoNoneGO:SetActive(not haveCEO)
    ceoPeopleGO:SetActive(haveCEO)
    if haveCEO then
        local normalBG = self:GetGo(ceoPeopleGO,"bg/normal")
        local premiumBG = self:GetGo(ceoPeopleGO,"bg/premium")
        local ceoConfig = CEODataManager:GetCEOConfig(ceoID)
        normalBG:SetActive(ceoConfig.ceo_quality == CEODataManager.CEORankType.Normal)
        premiumBG:SetActive(ceoConfig.ceo_quality == CEODataManager.CEORankType.Premium)

        local ceoIcon = self:GetComp(ceoPeopleGO,"icon","Image")
        self:SetSprite(ceoIcon,"UI_Shop",ceoConfig.ceo_head,nil,false,true)

        local buffIcon = self:GetComp(ceoPeopleGO,"resIcon","Image")
        self:SetSprite(buffIcon,"UI_Common",CEODataManager.CEOBuffIcon[ceoConfig.ceo_effect_type])
        --Buff值
        local ceoLevel = CEODataManager:GetCEOLevel(ceoID)
        local curCEOLevelConfig = CEODataManager:GetCEOLevelConfig(ceoID,ceoLevel)
        local buffStr = "x"..(curCEOLevelConfig.ceo_effect*100).."%"
        local furLevel = roomSaveData.ceoFurnitureInfo.level
        local curDeskConfig = ConfigMgr.config_ceo_furniture_level[furLevel]
        if curDeskConfig then
            local furLevelEnough = curDeskConfig.table_ceo_limit>=ceoLevel
            local buffValue = curCEOLevelConfig.ceo_effect - 1
            local numColor = furLevelEnough and "FFFFFF" or "FF2017"
            if furLevelEnough then
                buffStr = "x"..(100+buffValue*100).."%"
            else
                buffStr = "x"..(100+buffValue*50).."%"
            end
            self:SetText(ceoPeopleGO,"num",buffStr,numColor)
            self:SetText(ceoPeopleGO,"level/num",ceoLevel)

            local stateGO = self:GetGo(ceoPeopleGO,"state")
            stateGO:SetActive(not furLevelEnough)
        end
    end

    local currScene = CityMode:GetCurrentBuilding()
    if currScene>=200 then
        if not CEODataManager:GetGuideTriggered() then
            ResMgr:AddDiamond(20, nil, function() 
                CEODataManager:SetGuideTriggered()
                GuideManager.currStep = 2102
                GuideManager:ConditionToStart()
                --给10把钥匙和20钻石
                CEODataManager:AddCEOKey("normal",10,true)
            end)
            
        end
    end
    --刷新房间收入显示
    local roomTotalRent = FloorMode:GetSingleOfficeRent(FloorMode.m_curRoomIndex)
    local text = GameTextLoader:ReadText("TXT_MISC_ROOM_INCOME_RATE")
    text = string.format(text, math.floor(roomTotalRent))
    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/income/item/base", text)
end

function RoomBuildingUIView:SetTitlePanel(companyId)
    local isEmpty = companyId == nil
    self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/message"):SetActive(not isEmpty)
    self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/invite"):SetActive(isEmpty)
    self:GetGo("RootPanel/CompanyPanel/EmployeeList/Viewport"):SetActive(not isEmpty)
    self:GetGo("RootPanel/CompanyPanel/EmployeeList/empty"):SetActive(isEmpty)
    self:SetCampanyStateEmployeePanelDispay(not isEmpty)
    if not isEmpty then--有公司
        local companyData = ConfigMgr.config_company[companyId]
        local lv = CompanyMode:GetCompanyLevel(companyId)

        local message = self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/message")

        --更新基本显示界面
        self:SetText(message, "name", GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_NAME"))
        self:SetSprite(self:GetComp(message, "logo", "Image"), "UI_Common", companyData.company_logo..GameConfig:GetLangageFileSuffix(), nil, true)
        self:SetSprite(self:GetComp(message, "quality", "Image"), "UI_Common", "icon_Grade"..companyData.company_quality, nil, true)
        self:SetText(message, "desc", GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_DESC"))
		self.company_list:UpdateData()

        self:SetText(message, "rent", GameTextLoader:ReadText("TXT_CONTRACT_RENT_REQUIRE").."+".. FloorMode:GetCompanyRent(FloorMode.m_curRoomIndex) * FloorMode:GetSceneEnhance())
        self.mProgress = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/progress", "Slider")
        self.lastLevel = CompanyMode:GetCompanyLevel(companyId)
        self.maxLevel = ConfigMgr.config_company[companyId].levelMax
        self.mExpTxt = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/progress/time", "TMPLocalization")
        self.mExpImage = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/progress/image", "Image")
        self:RefreshCompanyLevel(self.lastLevel - 1, self.maxLevel)
        
        self.__timers = self.__timers or {}
        self:StopAllTimer("roomExp")
        self.__timers["roomExp"] = GameTimer:CreateNewTimer(1, function() --延迟执行，等待CameraFocus位置自动修正完毕
            local companyId = CompanyMode:CompIdByRoomIndex(FloorMode.m_curRoomIndex)
            if not companyId then
                self:SetTitlePanel(companyId)
                self:StopAllTimer("roomExp")
                return
            end

            local expProgress = CompanyMode:CompanyExpProgress(FloorMode.m_curRoomIndex)
            self.mProgress.value = expProgress
            self:SetText("RootPanel/RoomInfo/CompanyState/bg2/message/progress/pro", string.format("%.2f",expProgress*100).."%")

            self:RefreshExpAdd()
            self:RefreshEmployeeState()
        end, true, true, true)

        local nameText = self:GetComp(message, "name", "TMPLocalization")
        local image = self:GetComp(message, "quality", "Image")
        local help = self:GetComp(message, "HelpBtn", "Image")
        local toSet = {nameText, image, help}
        self:ArrangeWidget(toSet, true, 2)
        
    else--没公司
        local inviteBtn = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/invite/inviteBtn", "Button")
        local workspaceNum = FloorMode:GetFurnitureNum(10001, 1, FloorMode.m_curRoomIndex)
        local cfg = ConfigMgr.config_rooms[FloorMode.m_curRoomId] or {}
        local deskNeed = cfg.deskNeed
        inviteBtn.interactable = workspaceNum >= deskNeed
        self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/invite/inviteBtn/text"):SetActive(workspaceNum >= deskNeed)
        
        local needString = GameTextLoader:ReadText("TXT_CONTRACT_WORKSPACE_REQUIRE")
        needString = string.format(needString, deskNeed)
        self:SetText("RootPanel/RoomInfo/CompanyState/bg2/invite/inviteBtn/disable", needString)
        self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/invite/inviteBtn/disable"):SetActive(workspaceNum < deskNeed)
        self:SetButtonClickHandler(inviteBtn, function()
            CompanysUI:MakeEnableCompanys()
            CompanysUI:OpenView()
        end)
        if workspaceNum == deskNeed and deskNeed ~= 0 then
            --FloorMode:RefreshFloorSceneById(FloorMode:GetRoomIdByRoomIndex(roomIndex))
            FloorMode:GetScene():InitRoomGo(FloorMode.m_curRoomId)
        end
    end
end

function RoomBuildingUIView:InitEmployeeList()
    self.employeeList = self:GetComp("RootPanel/CompanyPanel/EmployeeList", "ScrollRectEx")
    self:SetListItemCountFunc(self.employeeList, function()
        return #self.m_employees
    end)
    self:SetListUpdateFunc(self.employeeList, handler(self, self.UpdateEmployee))
end

function RoomBuildingUIView:UpdateEmployee(index, tran)
    index = index + 1
    local go = tran.gameObject
    
    local employeeData = self.m_employees[index]--change,mood,name

    self:SetText(go, "name", employeeData.name or "")

    local moodSection = ConfigMgr.config_global.mood_section
    local currState = employeeData.moodState and "icon_mood_" .. employeeData.moodState or "icon_mood_1"
    self:SetSprite(self:GetComp(go, "state", "Image"), "UI_Float", currState, nil, true)

    self:RefreshStateChange(self:GetGo(go, "icon"), employeeData.change)
end

function RoomBuildingUIView:RefreshStateChange(root, change)
    local stateUp = self:GetGo(root, "stateUp")
    local stateDown = self:GetGo(root, "stateDown")
    stateUp:SetActive(change > 0)
    stateDown:SetActive(change < 0)

    if change == 0 then
        return
    end

    local currRoot = change > 0 and stateUp or stateDown
    change = change > 0 and change or change * -1
    for i = 1, 5 do
        self:GetGo(currRoot, tostring(i)):SetActive(i <= change)
    end
end

function RoomBuildingUIView:RefreshEmployeeState()
    self.m_employees = CompanyMode:GetEmployeeData(FloorMode.m_curRoomIndex)
    self.employeeList:UpdateData()
end

function RoomBuildingUIView:RefreshExpAdd()
    local addAble,type = CompanyMode:CheckCompanyExpState(FloorMode.m_curRoomIndex)
    local text,spriteName,materialName
    local image1 = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/progress/FillArea/Fill", "Image")
    local image2 = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/progress/FillArea/Fill/pitch", "Image")
    if addAble then
        local expAdd,addProgress = CompanyMode:RoomExpAdd(FloorMode.m_curRoomIndex)

        text = GameTextLoader:ReadText("TXT_MISC_COMPANY_EXP")
        text = string.format(text, expAdd)
        if addProgress <= 0.69 then--增长红
            -- text = Tools:ChangeTextColor(text, "F94653")
            spriteName = "Icon_CompanyExperience_003"
            materialName = "ExpIncreaseGlowMatRed"
            -- 2）慢 红：#CD1F34   #E22A40
            if image1 then
                image1.color = UnityHelper.GetColor("#CD1F34")
            end
        
            if image2 then
                image2.color = UnityHelper.GetColor("#E22A40")
            end
        elseif addProgress < 1 then--增长黄
            -- text = Tools:ChangeTextColor(text, "F2B923")
            spriteName = "Icon_CompanyExperience_002"
            materialName = "ExpIncreaseGlowMatYellow"
            -- 3）中 黄：#F4B818  #FED32C
            if image1 then
                image1.color = UnityHelper.GetColor("#F4B818")
            end
        
            if image2 then
                image2.color = UnityHelper.GetColor("#FED32C")
            end
        else--增长绿
            -- text = Tools:ChangeTextColor(text, "99FF8C")
            spriteName = "Icon_CompanyExperience_001"
            materialName = "ExpIncreaseGlowMatGreen"
            -- 4）快 绿： #4BB284  #65C898
            if image1 then
                image1.color = UnityHelper.GetColor("#4BB284")
            end
        
            if image2 then
                image2.color = UnityHelper.GetColor("#65C898")
            end
        end
    else
        
        if type == 1 then--下班
            text = GameTextLoader:ReadText("TXT_MISC_COMPANY_OFFDUTY")
            -- text = Tools:ChangeTextColor(text, "FFFDEE")
            spriteName = "Icon_CompanyExperience_004"
            materialName = "ExpIncreaseGlowMatPause"
        elseif type == 2 then--待维修
            text = GameTextLoader:ReadText("TXT_MISC_COMPANY_POWEROFF")
            -- text = Tools:ChangeTextColor(text, "FFFDEE")
            spriteName = "Icon_CompanyExperience_004"
            materialName = "ExpIncreaseGlowMatPause"
        elseif type == 3 then--满级
            text = GameTextLoader:ReadText("TXT_MISC_COMPANY_MAXLVL")
            -- text = Tools:ChangeTextColor(text, "FFFDEE")
            spriteName = "icon_max"
            materialName = "ExpIncreaseGlowMatMax"
        end
        -- 1）停滞状态  灰： #8F9DBB  #AAB4CB
        if image1 then
            image1.color = UnityHelper.GetColor("#8F9DBB")
        end
        if image2 then
            image2.color = UnityHelper.GetColor("#AAB4CB")
        end
    end

    if not self.lastSprite or self.lastSprite ~= spriteName then
        self:SetSprite(self.mExpImage, "UI_Common", spriteName, nil, true)
        local mat = GameResMgr:LoadMaterialSyncFree("Assets/Res/Shaders/".. materialName ..".mat")
        self.mExpImage.material = mat.Result
        self.lastSprite = spriteName
    end
    self.mExpTxt.text = text
    
end

function RoomBuildingUIView:RefreshCompanyLevel(companyLevel, maxLevel)
    local levelHolder = self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/message/levelHolder")
    local childCount = levelHolder.transform.childCount
    local level
    for i = 1, childCount do
        self:GetGo(levelHolder,"star"..i):SetActive(i < maxLevel)
        level = self:GetGo(levelHolder, "star" .. i .. "/on")
        level:SetActive(i <= companyLevel)
    end
    local img = self:GetComp("RootPanel/RoomInfo/CompanyState/bg2/message/contracBtn", "Image")
    self.m_isMaxCompanyLevel = (companyLevel + 1) >= maxLevel
    self:SetSprite(img, "UI_Common", self.m_isMaxCompanyLevel and "btn_014" or "btn_013", nil, true)
    local txtRoot = self:GetGo("RootPanel/RoomInfo/CompanyState/bg2/message/contracBtn/text")
    -- self:SetText(txtRoot, "", GameTextLoader:ReadText("TXT_BTN_CONTRACT"), self.m_isMaxCompanyLevel and "000000" or "FFFFFF")
    self:SetText(txtRoot, "", GameTextLoader:ReadText("TXT_BTN_CONTRACT"))
end

function RoomBuildingUIView:SecondToHour(workTime)
    if not workTime then
        return ''
    end
    local h = math.floor(workTime / 60)
    local min = workTime - h * 60
    if min < 10 then
        min = '0' .. min
    end
    return h..':'..min
end

function RoomBuildingUIView:SetSelectItemInfo()
    local data = self.m_data[self.m_currSelectItemIndex] or {}
    local num = Tools:SeparateNumberWithComma(data.cost.num)
    local startFame = self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn/fame")    
    self:SetText(startFame, "reward/num", data.fame or 0)
    local showStarNeed = data.fame ~= nil and data.fame > StarMode:GetStar()
    startFame:SetActive(showStarNeed)
    local isEnough = ResMgr:CheckEnough(data.cost.type, data.cost.num)
    local numText = self:SetText("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn/num", num)
    local matAddress = isEnough and "Assets/Res/Fonts/MSYH GreenOutline Material.mat" or "Assets/Res/Fonts/MSYH RedOutline Material.mat"
    -- local mat = GameResMgr:LoadMaterialSyncFree(matAddress, self)
    -- numText.fontMaterial = mat.Result

    self:SetText("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn/num", num)
    self:SetSprite(self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/frame/icon", "Image"), "UI_Common", data.nextIcon, nil, true)
    self:SetText("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/name", data.name)
    self:SetText("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/level/bg/num", data.nextLevel)
    self:SetText("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/desc", data.desc)
    
    self:SetSprite(self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn/icon", "Image"), "UI_Main", ResMgr:GetResIcon(data.cost.type))
    

    local buyButton = self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/btn", "Button")

    self:GetGo(buyButton.gameObject, "text"):SetActive(not showStarNeed)
    self:GetGo(buyButton.gameObject, "icon"):SetActive(not showStarNeed)
    self:GetGo(buyButton.gameObject, "num"):SetActive(not showStarNeed)
    if self.m_lastFocusItemIndex ~= self.m_currSelectItemIndex then
        -- buyButton.interactable = isEnough and not showStarNeed
        buyButton.interactable = not showStarNeed
        local closeBuyButton = data.power + self.currPower < 0 or data.isMaxLv
        if not self.isPowerRoom then
            buyButton.gameObject:SetActive(not closeBuyButton)
        else
            if not data.isMaxLv then
                buyButton.gameObject:SetActive(true)
            else
                buyButton.gameObject:SetActive(false)
            end
        end
    end
    if not self.isPowerRoom then
        self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/ebtn"):SetActive(data.power + self.currPower < 0)
    else
        self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/ebtn"):SetActive(false)
    end
    if data.power + self.currPower < 0 then
        EventManager:DispatchEvent("elec_lack")
    end

    self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/maxlvl"):SetActive(data.isMaxLv)

    local toSet = {}
    for i = 1, 3 do
        local go = self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/bonous/quality" .. i)
        go:SetActive(data.bonous[i] ~= nil)
        if data.bonous[i] then
            local showText = data.bonous[i]
            -- if data.nextBonous[i] > 0 then
            --     showText = showText .. Tools:ChangeTextColor("+" .. data.nextBonous[i], "1CCAFF")
            -- end
            if data.nextBonous[i] > 0 then
                showText = showText .. Tools:ChangeTextColor("+"..data.nextBonous[i], "0AA859")
            elseif data.nextBonous[i] < 0 then
                showText = showText .. Tools:ChangeTextColor(data.nextBonous[i], "0AA859")
            end

            self:SetText(go,"num", showText)
            self:SetSprite(self:GetComp(go,"icon", "Image"), "UI_Common", data.bonousIcon[i], nil, true)
            table.insert(toSet, self:GetComp(go, "icon", "Image"))
            table.insert(toSet, self:GetComp(go, "num", "TMPLocalization"))
        end
    end

    self:ArrangeWidget(toSet, true, 1)

    --local waterGo  = self:GetGo("RootPanel/RoomPanel/FurnitureInfo/res_requirement/water")
    local powerGo = self:GetGo("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/bonous/electric")
    --waterGo:SetActive(data.water ~= 0)
    powerGo:SetActive(data.lastPower ~= 0 or data.nextPower ~= 0)
    if data.power + self.currPower <= 0 then
        powerGo:SetActive(false)
    end
    if data.isMaxLv then
        powerGo:SetActive(false)
    end
    --self:SetText(waterGo, "num", data.water)

    local last = data.lastPower
    local next = data.nextPower

    local left = last
    if last == 0 then--解锁的时候直接显示自身
        left = next
    end
    left = left > 0 and "+"..left or left*-1
    -- left = Tools:ChangeTextColor(left, "FF6200")

    local right = data.power
    if last == 0 or data.power == 0 then
        right = ""
    elseif data.power > 0 then
        right = Tools:ChangeTextColor("+"..data.power, "FF6C00")
    elseif data.power < 0 then
        right = Tools:ChangeTextColor("+"..data.power*-1, "FF6C00")
    end

    self:SetText(powerGo, "num", left..right)

    local nameText = self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/name", "TMPLocalization")
    local levelText = self:GetComp("RootPanel/RoomInfo/RoomPanel/FurnitureInfo/main/info/level", "TMPLocalization")
    local toSet = {nameText, levelText}
    self:ArrangeWidget(toSet, true, 1)

    GuideManager:ConditionToEnd()
end

function RoomBuildingUIView:SetListData(data)
    self.m_data = data
    if self.setListDataTimeHandler then
        GameTimer:StopTimer(self.setListDataTimeHandler)
        self.setListDataTimeHandler = nil
    end
    self.setListDataTimeHandler = GameTimer:CreateNewMilliSecTimer(100, function() --延迟执行，等待CameraFocus位置自动修正完毕
        self.m_list:UpdateData()
    end)
end

function RoomBuildingUIView:SetBuildingNeedData(data)
    self.building_require = data
end

function RoomBuildingUIView:SetProgress(roomId)--设置房间进度
    if not self.m_data then--界面已经关闭
        return
    end
    local currCfg = ConfigMgr.config_rooms[roomId]
    local save = LocalDataManager:GetDataByKey(CountryMode.room_progress)
    if not save[currCfg.room_index] then
        save[currCfg.room_index] = 1
    end
    if not currCfg.roomProgress then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/prog"):SetActive(false)
        return
    end

    local currData = currCfg.roomProgress[save[currCfg.room_index]]
    if not currData then--已经满级
        currData = currCfg.roomProgress[#currCfg.roomProgress]
        local bar = self:GetComp("RootPanel/RoomTitle/HeadPanel/bg/prog/progress", "Slider")
        bar.value = 1
        -- self:SetText("RootPanel/RoomTitle/HeadPanel/bg/prog/reward/num", "100%")
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/prog/curr", "100%")
        return
    end

    local currValue = 0
    for k,v in pairs(self.m_data) do
        currValue = currValue + v.progressValue
    end

    local bar = self:GetComp("RootPanel/RoomTitle/HeadPanel/bg/prog/progress", "Slider")
    local curr = (currValue - currData[2]) / (currData[1] - currData[2])
    bar.value = curr

    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/prog/curr", math.floor(curr*100) .. "%")
    if not self.lastRoom then
        self.lastRoom = currCfg.room_index
    end
    if not self.lastProgress or self.lastRoom ~= currCfg.room_index then
        self.lastProgress = 0
    end
    if currValue - currData[2] >= currData[1] - currData[2] and self.lastProgress ~= save[currCfg.room_index] then
        
        -- GameSDKs:Track("room_complete", {room_id = roomId, complete_level = save[currCfg.room_index]})

        --可以直接领取奖励
        self.lastProgress = save[currCfg.room_index]
        save[currCfg.room_index] = save[currCfg.room_index] + 1
        self:SetProgress(roomId)
        local pos = self:GetTrans("RootPanel/RoomTitle/HeadPanel/bg/prog/reward")
        GameSDKs:TrackForeign("build_upgrade", {build_id = currCfg.id, build_level_new = tonumber(save[currCfg.room_index]), operation_type = 3, scene_id = GameTableDefine.CityMode:GetCurrentBuilding()})
        if currCfg.id == 1009 then
            GameSDKs:TrackControlCheckData("af", "af,build_upgrade_1009_1", {})
        end
        StarMode:StarRaise(currData[3], true, nil, true)
        EventManager:DispatchEvent("FLY_ICON", pos.position, 5, currData[3], function()
            self.raiseStar = true
            --关闭界面后,进行推荐
        end)
        --显示房间效果

        local currRoomId = FloorMode.m_curRoomId
        local data = FloorMode:GetScene():GetRoomRootGoData(currRoomId)
        local root = data.go
        local eff = UnityHelper.FindTheChild(root, "officebuff")
        if eff then
            eff.gameObject:SetActive(true)
            if self.effProTimer then
                GameTimer:StopTimer(self.effProTimer)
                self.effProTimer = nil
            end
            -- self.__timers = self.__timers or {}
            -- self:StopAllTimer("room_rise")
            -- self.__timers["room_rise"] = 
            self.effProTimer = GameTimer:CreateNewTimer(3.5, function() --延迟执行，等待CameraFocus位置自动修正完毕
                eff.gameObject:SetActive(false)
                self.__timers["room_rise"] = nil
            end)
        end

        return
    end
end

--[[
    @desc: 自动切换到下一个家具的显示
    author:{author}
    time:2024-11-13 10:47:57
    @return:
]]
function RoomBuildingUIView:AutoNextFurnitureSelect()
    if self.m_currSelectItemIndex then
        local curData = self.m_data[self.m_currSelectItemIndex]
        local curUseIndex = self.m_currSelectItemIndex
        if not curData then
            return
        end
        local curNextLevel = curData.nextLevel;
        function CompareGetConditionIndex(compareType)
        --     --compareType:1比当前等级小的，2-和当前等级一样的，3-比当前等级打切最接近当前等级
            for k, data in ipairs(self.m_data) do
                if not data.isMax and k ~= self.m_currSelectItemIndex then
                    if compareType == 1 and curNextLevel > data.nextLevel then
                        curNextLevel = data.nextLevel
                        curUseIndex = k
                    elseif compareType == 2 and curNextLevel == data.nextLevel then
                        curUseIndex = k
                        break;
                    elseif compareType == 3 and curNextLevel < data.nextLevel then
                        curNextLevel = data.nextLevel
                        curUseIndex = k
                    end
                end
            end
        end
        CompareGetConditionIndex(1)
        if self.m_currSelectItemIndex == curUseIndex then
            CompareGetConditionIndex(2)
            if self.m_currSelectItemIndex == curUseIndex then
                CompareGetConditionIndex(3)
            end
        end
        if self.m_currSelectItemIndex == curUseIndex then
            return
        end
        self.m_currSelectItemIndex  = curUseIndex
        if self.m_currSelectItemIndex > #self.m_data then
            self.m_currSelectItemIndex = 1
        end
        local scrollIndex = math.floor((self.m_currSelectItemIndex - 1)/5)
        self.m_list:ScrollTo(self.m_currSelectItemIndex - 1, 3)
    else
        self.m_currSelectItemIndex = 1
    end
    self.m_list:UpdateData()
end

return RoomBuildingUIView