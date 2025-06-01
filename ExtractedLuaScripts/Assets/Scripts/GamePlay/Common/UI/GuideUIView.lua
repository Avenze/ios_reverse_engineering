local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local TweenUtil = CS.Common.Utils.DotweenUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local EventTriggerListener = CS.Common.Utils.EventTriggerListener
local V3 = CS.UnityEngine.Vector3
local V2 = CS.UnityEngine.Vector2
local TimerMgr = GameTimeManager
local CityMapUI = GameTableDefine.CityMapUI
local GuideManager = GameTableDefine.GuideManager
local FloorMode = GameTableDefine.FloorMode
local CompanysUI = GameTableDefine.CompanysUI
local CityMode = GameTableDefine.CityMode
local GameUIManager = GameTableDefine.GameUIManager;

---@class GuideUIView:UIBaseView
local GuideUIView = Class("GuideUIView", UIView)

function GuideUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function GuideUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("skip","Button"), function()
        GuideManager:JumpToNext()
        --GuideManager.inGuide = false
        self:DestroyModeUIObject()
    end)
end

function GuideUIView:OnExit()
    self.super:OnExit(self)
end

function GuideUIView:ResetView()
    self:GetGo("log"):SetActive(false)
    self:GetGo("log2"):SetActive(false)
    self:GetGo("highLightReal"):SetActive(false)
    self:GetGo("highlightScale"):SetActive(false)
    self:GetGo("highLightReal2"):SetActive(false)
    self:GetGo("highlightScale2"):SetActive(false)
    self:GetGo("buttonReal"):SetActive(false)
    self:GetGo("buttonReal2"):SetActive(false)
    self:GetGo("block"):SetActive(false)
    self:GetGo("Note"):SetActive(false)
end

function GuideUIView:UpdateTargetWidget(d)
    --Set self:GetComp("", "Button",)
    print("当前引导的id:" .. d.id)
    --对话框
    self:ResetView()
    self:GetGo("skip"):SetActive(d.skipAble)
    if d.type == "Log" or d.type == "Log2" then
        local content = GameTextLoader:ReadText("TXT_GUIDE_"..d.id)
        if d.id == 1053 then -- 需要老板名字
            content = string.format(content, LocalDataManager:GetBossName() or "")
        end
        local logRootGO = nil
        if d.type == "Log" then
            logRootGO = self:GetGo("log")
        elseif d.type == "Log2" then
            logRootGO = self:GetGo("log2")
        end
        logRootGO:SetActive(true)
        self:SetText(logRootGO,"bg/txt", content)
        self:GetGo(logRootGO,"BgCover"):SetActive(true)

        local npcGO = self:GetGo(logRootGO,"npc")
        local imageName = nil
        local showName = nil
        if d.npcImage == "player" then
            imageName = LocalDataManager:GetBossSkin()
            showName = LocalDataManager:GetBossName()
        elseif d.npcImage == "empty" then
            imageName = "empty"
            showName = ""
        else
            imageName = d.npcImage
            showName = GameTextLoader:ReadText("TXT_NPC_"..d.npcImage)
        end
        self:GetGo(npcGO, imageName):SetActive(true)
        local spriteName = "icon_" .. imageName .. "_" .. d.npcPortrait
        self:SetSprite(self:GetComp(npcGO,imageName, "Image"), "UI_BG", spriteName)
        local vfx = nil
        if d.npcVfx then
            vfx = self:GetGo(npcGO,imageName .. "/vfx/" .. d.npcVfx)
            vfx:SetActive(true)
        end
        
        self:GetGo(logRootGO,"bg/title"):SetActive(d.type == "Log" and d.npcImage ~= "empty")

        self:SetText(logRootGO,"bg/title/name", showName)
        local npc = npcGO.transform
        local npcPos = npc.anchoredPosition
        --print(string.format("npcPos = %.2f,%.2f",npcPos.x,npcPos.y))
        npcPos.x = d.npcPlaceX and d.npcPlaceX or 0
        npcPos.y = d.npcPlace and d.npcPlace or 0
        npc.anchoredPosition = npcPos
        
        --这里控制了对话框的默认位置为 (0,90)
        local talk = self:GetTrans(logRootGO,"bg")
        local talkPos = talk.anchoredPosition
        talkPos.x = d.talkPlaceX and d.talkPlaceX or 0
        talkPos.y = d.talkPlace and d.talkPlace or 90
        talk.anchoredPosition = talkPos

        GameUIManager:SetEnableTouch(true, "点击对话")
        

        self:SetButtonClickHandler(self:GetComp(logRootGO,"", "Button"), function()
            -- if GuideManager.m_dialogCompleteHander then
            --     self:GetGo("log/npc/" .. imageName):SetActive(false)
            --     GuideManager.m_dialogCompleteHander(1)
            -- else
                self:GetGo(npcGO, imageName):SetActive(false)
                if vfx then
                    vfx:SetActive(false)
                end
                GuideManager:ConditionToEnd(true)
            --end
        end)
        --设置高亮
        if d.view then--ui高亮
            self:GetGo(logRootGO,"BgCover"):SetActive(false)
            local view = GameTableDefine[d.view]:GetView()
            local btn = view:GetGo(d.widget)

            local goalTran = btn.transform
            local goalScale = goalTran.localScale
            local goalSize = V2(goalTran.rect.width * goalScale.x + 80, goalTran.rect.height * goalScale.y + 80)

            local xOffset = (0.5 - goalTran.pivot.x) * goalTran.rect.width * goalScale.x
            local yOffset = (0.5 - goalTran.pivot.y) * goalTran.rect.height * goalScale.y

            local goalPos = V3(goalTran.position.x, goalTran.position.y,  0)

            if d.widgetType == 0 then--highLightReal节点高亮
                self:GetGo("highLightReal"):SetActive(true)
                
                local high = self:GetGo("highLightReal/highLight")
                local highLight = self:GetGo("highLightReal/highLight/image")
            
                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)

                highLight.transform.sizeDelta = goalSize
            elseif d.widgetType == 1 then--highlightScale变形高亮
                self:GetGo("highlightScale"):SetActive(true)

                local high = self:GetGo("highlightScale/image")
                local line = self:GetGo("highlightScale/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)

                TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            elseif d.widgetType == 2 then--highlightScale变形高亮,外扩20像素
                goalSize = V2(goalTran.rect.width * goalScale.x + 20, goalTran.rect.height * goalScale.y + 20)
                self:GetGo("highlightScale"):SetActive(true)

                local high = self:GetGo("highlightScale/image")
                local line = self:GetGo("highlightScale/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )

                TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            elseif d.widgetType == 3 then--highLightReal2节点高亮
                self:GetGo("highLightReal2"):SetActive(true)

                local high = self:GetGo("highLightReal2/highLight")
                local highLight = self:GetGo("highLightReal2/highLight/image")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)

                highLight.transform.sizeDelta = goalSize
            elseif d.widgetType == 4 then--highlightScale2变形高亮
                self:GetGo("highlightScale2"):SetActive(true)

                local high = self:GetGo("highlightScale2/image")
                local line = self:GetGo("highlightScale2/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)

                TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            elseif d.widgetType == 5 then--highlightScale2变形高亮,外扩20像素
                goalSize = V2(goalTran.rect.width * goalScale.x + 20, goalTran.rect.height * goalScale.y + 20)
                self:GetGo("highlightScale2"):SetActive(true)

                local high = self:GetGo("highlightScale2/image")
                local line = self:GetGo("highlightScale2/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )

                TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            elseif d.widgetType == 6 then--highlightScale2不变形高亮
                self:GetGo("highlightScale2"):SetActive(true)

                local high = self:GetGo("highlightScale2/image")
                local line = self:GetGo("highlightScale2/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x + xOffset, currAnchor.y + yOffset)

                high.transform.sizeDelta = goalSize
                line.transform.sizeDelta = goalSize
                --TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                --TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            elseif d.widgetType == 7 then--highlightScale2不变形变形高亮,外扩20像素
                goalSize = V2(goalTran.rect.width * goalScale.x + 20, goalTran.rect.height * goalScale.y + 20)
                self:GetGo("highlightScale2"):SetActive(true)

                local high = self:GetGo("highlightScale2/image")
                local line = self:GetGo("highlightScale2/line")

                high.transform.position = goalPos
                local currAnchor = high.transform.anchoredPosition
                high.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )
                line.transform.position = goalPos
                currAnchor = line.transform.anchoredPosition
                line.transform.anchoredPosition = V2(currAnchor.x , currAnchor.y )

                high.transform.sizeDelta = goalSize
                line.transform.sizeDelta = goalSize
                --TweenUtil.DOTweenGuideChange(high.transform, goalSize)
                --TweenUtil.DOTweenGuideChange(line.transform, goalSize)
            end
        elseif d.widget then--场景高亮
            local currScene = nil
            if GameStateManager:IsInCity() then
                currScene = CityMode:GetScene()
            else
                currScene = FloorMode:GetScene()
            end
            local go = GameObject.Find(d.widget)
            if not go then
                return
            end
            
            self:GetGo("highLightReal"):SetActive(true)
            self:GetGo(logRootGO,"BgCover"):SetActive(false)

            go = go.gameObject
            local goalPos = currScene:Position3dTo2d(go.transform.position)
            --TODO:场景中的Log高亮
            local high = self:GetGo("highLightReal/highLight")
            local highLight = self:GetGo("highLightReal/highLight/image")
            high.transform.position = V3(goalPos.x, goalPos.y, 0)
            --大小如何确定
            highLight.transform.sizeDelta = V2(30,30)--临时用这个,目前只有直接解锁可以用
            
            if d.widgetType == 1 then
                currScene:LocatePosition(go.transform.position, true)
            end
        end
    --阻挡界面
    elseif d.type == "Block"  then
        self:GetGo("block"):SetActive(true)
        --self:GetGo("BgCover"):SetActive(false)
        local myBtn = self:GetGo("button")

        --存在有CityMapUI时--将镜头移动到建筑位置 
        if GameStateManager:IsInCity() and GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.CITY_MAP) or GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.EUROPE_MAP_UI) then
            if d.widget then
                CityMapUI:LookAt(d.widget)
            end           
        end

        --副本中--将镜头移动到建筑位置 
        if GameTableDefine.CycleInstanceDataManager:GetInstanceIsActive() then
            if d.widget then
                local go = GameObject.Find(d.widget)
                if go then
                    local mainUiViewExist = GameUIManager:GetUIIndex(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI)
                    if mainUiViewExist and mainUiViewExist > 0 then
                        local scene = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetScene()
                        if scene then
                            scene:LocatePosition(go.transform.position, true)
                        end
                    end
                end
            end
        end
        
        --需要长时间去检查下一步时
        if d.widgetType == 10 then
            local updata 
            updata= GameTimer:CreateNewMilliSecTimer(
                10000,
                function()
                    if GuideManager:ConditionToEnd() then
                        --GuideManager:EndStep()
                        GameTimer:StopTimer(updata)                         
                    end          
                end,
                true,
                true
            )  
        end
        if d.widgetType == 20 then
            if self.blockTimer then
                return
            end
            local waitTime = (d.widgetSize and d.widgetSize[1] or 1) * 1000
            self.blockTimer = GameTimer:CreateNewMilliSecTimer(
                    waitTime,
                function()
                    printf(d.id.. "  "..waitTime.."毫秒后")
                    GuideManager.autoEnd = true
                    GameTimer:StopTimer(self.blockTimer )
                    self.blockTimer = nil
                    GuideManager:ConditionToEnd()
                end,
                true,
                false
            )
        end
        if d.widgetType == 30 then  -- 专门给循环副本拉霸机加的, 用于判断拉霸机是否已停止转动
            if self.blockTimer then
                return
            end
            self.blockTimer = GameTimer:CreateNewMilliSecTimer(
                50,
                function()
                    local instanceID = GameTableDefine.CycleInstanceDataManager:GetCurrentModel().instance_id
                    local slotMachineUI
                    if instanceID == 4 then
                        slotMachineUI = GameTableDefine.SlotMachineUI
                    elseif instanceID == 5 then
                        slotMachineUI = GameTableDefine.CycleCastleSlotMachineUI
                    elseif instanceID == 6 then
                        slotMachineUI = GameTableDefine.CycleToySlotMachineUI
                    elseif instanceID == 7 then
                        slotMachineUI = GameTableDefine.CycleNightClubSlotMachineUI
                    end
                    if slotMachineUI.m_view:IsNotRunning() then
                        GuideManager.autoEnd = true
                        GameTimer:StopTimer(self.blockTimer)
                        self.blockTimer = nil
                        GuideManager:ConditionToEnd()
                    end
                end,
                true,
                false
            )
        end
        --UI按钮
    elseif d.type == "UI" then        
        --设置遮罩
        self:GetGo("buttonReal"):SetActive(true)
        self:GetGo("buttonReal/button"):SetActive(true)
        self:GetGo("buttonReal/buttonImage"):SetActive(true)
        self:GetGo("buttonReal/point"):SetActive(true)

        local viewUI = GameTableDefine[d.view]
        if not viewUI then
            printError("引导 找不到代码 "..d.view..".txt")
        end
        local view = viewUI:GetView()
        --自动关闭当前的UI进入下一步
        if d.widgetType == 20 then
            viewUI:CloseView()
            GuideManager:ConditionToEnd(true)
            return
        end
        
        local btn = view:GetComp(d.widget, "Button")

        local tran = btn.gameObject.transform
        local goalScale = tran.localScale
        local goalWidth = d.widgetSize and d.widgetSize[1] or (tran.rect.width * goalScale.x)
        local goalHeight = d.widgetSize and d.widgetSize[2] or (tran.rect.width * goalScale.x)

        local xOffSet = (0.5 - tran.pivot.x) * tran.rect.width * goalScale.x
        local yoffSet = (0.5 - tran.pivot.y) * tran.rect.height * goalScale.y

        local goalp = V3(tran.position.x, tran.position.y, 0)

        local myBtn = self:GetComp("buttonReal/button", "Button")
        local myImage = self:GetTrans("buttonReal/buttonImage")
        local myPoint = self:GetTrans("buttonReal/point")

        if not btn then--如果没有找到按钮....那问题很大,肯定是配置出问题,本来就不应该发生的
            GuideManager:JumpToNext()--临时措施,直接跳过当前步骤
        end

        --是否翻转Point节点
        local scale = myPoint.localScale
        if d.widgetFlipX then
            scale.x = -1
        else
            scale.x = 1
        end
        myPoint.localScale = scale

        local clickAble = btn.interactable

        myBtn.gameObject.transform.position = goalp
        myImage.transform.position = goalp
        myPoint.transform.position = goalp

        local currAnchor = myBtn.gameObject.transform.anchoredPosition
        myBtn.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)
        currAnchor = myImage.gameObject.transform.anchoredPosition
        myImage.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)
        currAnchor = myPoint.gameObject.transform.anchoredPosition
        myPoint.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)
                                       
        TweenUtil.DOTweenGuideChange(myImage.transform, V2(goalWidth, goalHeight))
        TweenUtil.DOTweenGuideChange(myBtn.transform, V2(goalWidth, goalHeight))

        self:SetButtonClickHandler(myBtn, function()
            self:GetGo("buttonReal/button"):SetActive(false)
            self:GetGo("buttonReal/point"):SetActive(false)
            self:GetGo("buttonReal/buttonImage"):SetActive(false)
            if btn.interactable then
                btn.onClick:Invoke()
            end
            if d.widgetType == 6 then --自动关闭UI
                GameTableDefine[d.view]:CloseView()
            end
            if d.widgetType == 3 then
                CompanysUI:SpecialOpenView(1)--修改为特定的公司
            elseif d.widgetType == 5 then
                CompanysUI:SpecialOpenView(2)--修改为特定的公司
            elseif d.widgetType == 10 then --将工厂引导小人消除
                --进入时检查关闭主场景人物
                FloorMode:GetScene():CheckIfNeededFactoryGuide(true)
            elseif d.widgetType == 11 then --将足球俱乐部引导小人消除
                --进入时检查关闭主场景人物
                FloorMode:GetScene():CloseFootballClubGuideEntrance()
            end
            
            GuideManager:ConditionToEnd(true)
        end)
        --UI2按钮,有click,hold两种状态
    elseif d.type == "UI2" then
        --设置遮罩
        local buttonRealGO = self:GetGo("buttonReal2")
        buttonRealGO:SetActive(true)
        self:GetGo(buttonRealGO,"button"):SetActive(true)
        self:GetGo(buttonRealGO,"buttonImage"):SetActive(true)

        local view = GameTableDefine[d.view]:GetView()
        --自动关闭当前的UI进入下一步
        if d.widgetType == 20 then
            GameTableDefine[d.view]:CloseView()
            GuideManager:ConditionToEnd(true)
            return
        end

        --容错检测
        if not view or not d or not d.widget or not d.widgetType then
            return
        end
        local btn = view:GetComp(d.widget, d.widgetType<100 and "Button" or"ButtonEx")
        if not btn then--如果没有找到按钮....那问题很大,肯定是配置出问题,本来就不应该发生的
            GuideManager:JumpToNext()--临时措施,直接跳过当前步骤
            printError("引导找不到Button id="..d.id..",widget="..d.widget)
            return
        end
        local tran = btn.gameObject.transform
        local goalScale = tran.localScale
        local goalWidth = d.widgetSize and d.widgetSize[1] or (tran.rect.width * goalScale.x)
        local goalHeight = d.widgetSize and d.widgetSize[2] or (tran.rect.width * goalScale.x)

        local xOffSet = (0.5 - tran.pivot.x) * tran.rect.width * goalScale.x
        local yoffSet = (0.5 - tran.pivot.y) * tran.rect.height * goalScale.y

        local goalp = V3(tran.position.x, tran.position.y, 0)

        local myBtn = self:GetComp(buttonRealGO,"button", "Button")
        local myImage = self:GetTrans(buttonRealGO,"buttonImage")
        local pointClickGO = self:GetGo("point_click")
        local pointHoldGO = self:GetGo("point_hold")
        local myPoint
        if d.widgetType < 100 then
            myPoint = pointClickGO.transform
            pointClickGO:SetActive(true)
            pointHoldGO:SetActive(false)
        else
            myPoint = pointHoldGO.transform
            pointClickGO:SetActive(false)
            pointHoldGO:SetActive(true)
        end

        if not btn then--如果没有找到按钮....那问题很大,肯定是配置出问题,本来就不应该发生的
            GuideManager:JumpToNext()--临时措施,直接跳过当前步骤
            return
        end

        --是否翻转Point节点
        local scale = myPoint.localScale
        if d.widgetFlipX then
            scale.x = -1
        else
            scale.x = 1
        end
        myPoint.localScale = scale

        local clickAble = btn.interactable

        myBtn.gameObject.transform.position = goalp
        myImage.transform.position = goalp
        myPoint.transform.position = goalp

        local currAnchor = myBtn.gameObject.transform.anchoredPosition
        myBtn.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)
        currAnchor = myImage.gameObject.transform.anchoredPosition
        myImage.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)
        currAnchor = myPoint.gameObject.transform.anchoredPosition
        myPoint.gameObject.transform.anchoredPosition = V2(currAnchor.x + xOffSet, currAnchor.y + yoffSet)

        TweenUtil.DOTweenGuideChange(myImage.transform, V2(goalWidth, goalHeight))
        TweenUtil.DOTweenGuideChange(myBtn.transform, V2(goalWidth, goalHeight))

        --小于100是点击
        if d.widgetType < 100 then
            self:SetButtonClickHandler(myBtn, function()
                self:GetGo(buttonRealGO,"button"):SetActive(false)
                myPoint.gameObject:SetActive(false)
                self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                if btn.interactable then
                    btn.onClick:Invoke()
                end
                if d.widgetType == 6 then --自动关闭UI
                    GameTableDefine[d.view]:CloseView()
                end

                GuideManager:ConditionToEnd(true)
            end)
            self:SetButtonHoldHandler(myBtn, function()
            end)
        else
            --响应长按时隐藏引导界面1s.
            local lastHoldTime = 0
            local isHide = false
            local hideTimer = GameTimer:CreateNewMilliSecTimer(50,function()
                local curMilliSecTime = TimerMgr:GetCurrentServerTimeInMilliSec()
                if curMilliSecTime - lastHoldTime > 300 then
                    --从新显示
                    --self:GetGo(buttonRealGO,"button"):SetActive(true)
                    if isHide and not myBtn.IsHolding then
                        myPoint.gameObject:SetActive(true)
                        self:GetGo(buttonRealGO,"buttonImage"):SetActive(true)
                        isHide = false
                    end
                end
            end,true)
            --大于100是长按
            self:SetButtonClickHandler(myBtn, function()
                myPoint.gameObject:SetActive(false)
                self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                isHide = true
                lastHoldTime = TimerMgr:GetCurrentServerTimeInMilliSec()
                if btn.interactable then
                    --btn.onHold:Invoke()
                    btn.onHold(btn.name)
                end

                if GuideManager:ConditionToEnd(true) then
                    GameTimer:StopTimer(hideTimer)
                end
            end)
            self:SetButtonHoldHandler(myBtn, function()
                myPoint.gameObject:SetActive(false)
                self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                isHide = true
                lastHoldTime = TimerMgr:GetCurrentServerTimeInMilliSec()
                if btn.interactable then
                    --btn.onHold:Invoke()
                    btn.onHold(btn.name)
                end

                if GuideManager:ConditionToEnd(true) then
                    GameTimer:StopTimer(hideTimer)
                end
            end, nil,0.4, 0.13)
        end
    --场景节点
    elseif d.type == "Scene" or d.type == "Scene2" then
        local currScene = FloorMode:GetScene()        
        local go = nil
        if d.view then
            go = GuideManager:GetSpecialGo(d.view)
        else
            go = GameObject.Find(d.widget)
        end

        if go then
            go = go.gameObject
        else
            --外一出现特殊情况,没有出现...
            print("<color#FF0000>!!!!!!!!!!!!新手引导寻找节点失败!!!!!!!!!!!!!!!!!!</color>")
            GuideManager:JumpToNext()--临时措施,直接跳过当前步骤
            self:DestroyModeUIObject()
            return
        end

        local buttonRealGO
        if d.type == "Scene" then
            buttonRealGO = self:GetGo("buttonReal")
        elseif d.type == "Scene2" then
            buttonRealGO = self:GetGo("buttonReal2")
        end

        local MovePositionCb = function()
            GameUIManager:SetEnableTouch(true)
            local goalPos 
            if not currScene then
                if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_INSTANCE then
                    goalPos = GameTableDefine.InstanceModel:Position3dTo2d(go.transform.position)
                end
                if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
                    goalPos = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():Position3dTo2d(go.transform.position)
                end
            else
                goalPos = currScene:Position3dTo2d(go.transform.position)
            end    
                    
            local myBtn = self:GetComp(buttonRealGO,"button", "Button")
            local myImage = self:GetTrans(buttonRealGO,"buttonImage")
            local myPoint
            if d.type == "Scene" then
                myPoint = self:GetTrans(buttonRealGO,"point")
            elseif d.type == "Scene2" then
                myPoint = self:GetTrans(buttonRealGO,"point_click")
            end

            if not myBtn then--为什么这里界面都没了
                return
            end

            --是否翻转Point节点
            local scale = myPoint.localScale
            if d.widgetFlipX then
                scale.x = -1
            else
                scale.x = 1
            end
            myPoint.localScale = scale

            if d.widgetOffset then
                myBtn.gameObject.transform.anchoredPosition = V2(d.widgetOffset[1], d.widgetOffset[2])
                myImage.transform.anchoredPosition = V2(d.widgetOffset[1], d.widgetOffset[2])
                myPoint.transform.anchoredPosition = V2(d.widgetOffset[1], d.widgetOffset[2])--myBtn.gameObject.transform.position
            else
                myBtn.gameObject.transform.position = V3(goalPos.x, goalPos.y, 0)
                myImage.transform.position = V3(goalPos.x, goalPos.y, 0)
                myPoint.transform.position = myBtn.gameObject.transform.position
            end

            if d.widgetSize then
                --myBtn.gameObject.transform.sizeDelta = V2(d.widgetSize[1], d.widgetSize[2])
                TweenUtil.DOTweenGuideChange(myImage.transform, V2(d.widgetSize[1], d.widgetSize[2]))
                TweenUtil.DOTweenGuideChange(myBtn.transform, V2(d.widgetSize[1], d.widgetSize[2]))
                --myImage.transform.sizeDelta = V2(d.widgetSize[1], d.widgetSize[2])
            else
                --myBtn.gameObject.transform.sizeDelta = V2(100,100)
                TweenUtil.DOTweenGuideChange(myImage.transform, V2(130,130))
                TweenUtil.DOTweenGuideChange(myBtn.transform, V2(130,130))
                --myImage.transform.sizeDelta = V2(100,100)
            end

            buttonRealGO:SetActive(true)
            self:GetGo(buttonRealGO,"button"):SetActive(true)
            myPoint.gameObject:SetActive(true)
            self:GetGo(buttonRealGO,"buttonImage"):SetActive(true)

            if d.widgetType == 1 then--1.一般场景中的碰撞体
                local event = EventTriggerListener.Get(go)

                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    myPoint.gameObject:SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    event:OnPointerClick()
                    GuideManager:ConditionToEnd(true)
                end)
            elseif d.widgetType == 2 then--2.一般场景中的按钮
                local btn = UnityHelper.GetObjComponent(go, "Button")

                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    myPoint.gameObject:SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    btn.onClick:Invoke()
                    GuideManager:ConditionToEnd(true)
                end)
            elseif d.widgetType == 3 then--3.招聘(第一次)
                local event = EventTriggerListener.Get(go)

                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    myPoint.gameObject:SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    event:OnPointerClick()
                    CompanysUI:SpecialOpenView(1)--修改为特定的公司
                    GuideManager:ConditionToEnd(true)
                end)
            elseif d.widgetType == 4 then--断电等特殊图标
                local go,click = GuideManager:GetSpecialGo(d.view)
                local event = EventTriggerListener.Get(go)
                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    myPoint.gameObject:SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    if click then click() end
                    GuideManager:ConditionToEnd(true)
                end)
            elseif d.widgetType == 5 then
                local event = EventTriggerListener.Get(go)

                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    myPoint.gameObject:SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    event:OnPointerClick()
                    CompanysUI:SpecialOpenView(2)--修改为特定的公司
                    GuideManager:ConditionToEnd(true)
                end)
            elseif d.widgetType == 6 then
                myPoint.gameObject:SetActive(false)
                self:SetButtonClickHandler(myBtn, function()
                    self:GetGo(buttonRealGO,"button"):SetActive(false)
                    self:GetGo(buttonRealGO,"buttonImage"):SetActive(false)
                    GuideManager:ConditionToEnd(true)
                end)
            end
        end


        if not currScene then
            if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_INSTANCE then
                GameUIManager:SetEnableTouch(false, "引导")--移动期间禁止点击跳过,以防止关闭界面,导致后面移动过程中或者节点失败
                GameTableDefine.InstanceModel:LocatePosition(go.transform.position , true, MovePositionCb)
                return
            end
            if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
                GameUIManager:SetEnableTouch(false, "引导")--移动期间禁止点击跳过,以防止关闭界面,导致后面移动过程中或者节点失败
                GameTableDefine.CycleInstanceDataManager:GetCurrentModel():LocatePosition(go.transform.position , true, MovePositionCb)
                return
            end
            print("<color#FF0000>!!!!!!!!!!!!获取当前场景失败!!!!!!!!!!!!!!!!!!</color>")
            GuideManager:JumpToNext()--临时措施,直接跳过当前步骤
            self:DestroyModeUIObject()
            return
        end

        local showMove = true
        if d.id == 32 then
            showMove = false
        end
        
        GameUIManager:SetEnableTouch(false, "引导")--移动期间禁止点击跳过,以防止关闭界面,导致后面移动过程中或者节点失败
        currScene:LocatePosition(go.transform.position, showMove, MovePositionCb)
    elseif d.type == "HighLight" then
        self:GetGo("highLightReal"):SetActive(true)
        --self:GetGo("log/BgCover"):SetActive(false)
        local view = GameTableDefine[d.view]:GetView()
        local btn = view:GetGo(d.widget)
        local high = self:GetGo("highLightReal/highLight")
        local highLight = self:GetGo("highLightReal/highLight/image")
    
        local goalScale = btn.gameObject.transform.localScale

        local rect = btn.transform.rect
        highLight.transform.sizeDelta = V2(rect.width * goalScale.x , rect.height * goalScale.y)--btn.transform.sizeDelta

        high.transform.position = btn.transform.position
        
        high.transform.anchoredPosition = V2(
            high.transform.anchoredPosition.x + (0.5 - btn.transform.pivot.x)*rect.width,
            high.transform.anchoredPosition.y + (0.5 - btn.transform.pivot.y)*rect.height
        )
    elseif d.type == "Note" then
        local emptyInput = self:GetComp("", "EmptyRaycast")
        emptyInput.raycastTarget = false
        self:GetGo("Note"):SetActive(true)
        self:GetGo("Note/button"):SetActive(true)
        self:GetGo("Note/buttonImage"):SetActive(true)

        local view = GameTableDefine[d.view]:GetView()
        local btn = view:GetComp(d.widget, "Button")
        local myImage = self:GetTrans("Note/buttonImage")
        local myBtn = self:GetTrans("Note/button")
        local goalScale = btn.gameObject.transform.localScale

        myBtn.transform.position = btn.gameObject.transform.position
        myImage.transform.position = btn.gameObject.transform.position
        local goalWidth = btn.gameObject.transform.sizeDelta.x * goalScale.x
        TweenUtil.DOTweenGuideChange(myImage.transform, V2(goalWidth, goalWidth))
        TweenUtil.DOTweenGuideChange(myBtn.transform, V2(goalWidth, goalWidth))
    else
        GuideManager:ConditionToEnd(true)
    end
end

function GuideUIView:Refresh(data)
    self.mData = data
    self:UpdateTargetWidget(self.mData)--更新表现
end

function GuideUIView:CurrGuideEnd()
    self:DestroyModeUIObject()
end

return GuideUIView