--[[
    用于小游戏中开启奖励选择的UI功能内容
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-12-25 14:38:55
]]

local SeasonPassUIView = require("GamePlay.Common.UI.SeasonPassUIView")

local GameObject = CS.UnityEngine.GameObject

local UIPickUpItem = CS.Component.Widget.UIPickUpItem

local IsFirstEnter = true

function SeasonPassUIView:ctorGameChoose()
    self.isFirstEnter = true
end

--加载界面时调用
function SeasonPassUIView:OnEnterGameChooseView()
    self.gameChooseRootGo = self:GetGo("chooseWindow")
    self.gc_PickUpItemGo = self:GetGo(self.gameChooseRootGo, "module")
    self.gc_BtnClose = self:GetComp(self.gameChooseRootGo, "BgCover", "Button")
    self:SetButtonClickHandler(self.gc_BtnClose, function()
        self:OnExitGameChooseView()
    end)
    if self.gc_PickUpItemGo then
        self.gc_pickItemScript = self.gc_PickUpItemGo:GetComponent("UIPickUpItem")
    end
    self.m_DownListItemGos = {}
    self.m_DownListItemGos[1] = {}
    self.m_DownListItemGos[2] = {}
    
    self.m_DownListGo = self:GetGo(self.gameChooseRootGo, "bg/list/chooseList")
    for i = 0,self.m_DownListGo.transform.childCount - 1 do
        if i <= 4 then
            table.insert(self.m_DownListItemGos[1], self.m_DownListGo.transform:GetChild(i).gameObject)
        else
            table.insert(self.m_DownListItemGos[2], self.m_DownListGo.transform:GetChild(i).gameObject)
        end
    end
    self.m_UpListItemGos = {}
    self.m_UpListItemGos[1] = {}
    self.m_UpListItemGos[2] = {}
    self.m_UpListGo = self:GetGo(self.gameChooseRootGo, "bg/list/setList")
    
    for i = 0, self.m_UpListGo.transform.childCount - 1 do
        if i <= 4 then
            table.insert(self.m_UpListItemGos[1], self.m_UpListGo.transform:GetChild(i).gameObject)
        else
            table.insert(self.m_UpListItemGos[2], self.m_UpListGo.transform:GetChild(i).gameObject)
        end
    end
    self.btnResetBtn = self:GetComp(self.gameChooseRootGo, "bg/resetBtn", "Button")
    self.btnConfirm = self:GetComp(self.gameChooseRootGo, "bg/yesBtn", "Button")
    
    -- {
    --     "awardID": 13,
    --     "double": false,
    --     "removed": false
    -- },
end

function SeasonPassUIView:OnShowGameChooseView()
    GameTableDefine.CoinPusherManager:OpenChooseView()
    
    --进行数据初始化的相关内容
    local endDragCallback = function(index, gameobject)
        print("OnShowGameChooseView endDragCallback:index is:"..tostring(index).."destionGame name is:"..gameobject.name)
    end
    self:RefreshDownListData()
    self:RefreshUpListData()
    self:RefreshDownListItems()
    self:RefreshUpListItems()
    self:SetButtonClickHandler(self.btnResetBtn, function()
        self:RefreshDownListData()
        self:RefreshUpListData()
        self:RefreshDownListItems()
        self:RefreshUpListItems()
        self:PlayChooseGuidAnimation(1)
    end)
    self:SetButtonClickHandler(self.btnConfirm, function()
        if not self:CheckCanConfirm() then
            return
        end
        self.btnConfirm.interactable = false
        local trackRewardStr = ""
        for row, v in pairs(self.m_UpListData) do
            local double = 2
            if row == 2 then
                double = 1
            end
            for col, col_v in pairs(v) do
                if col_v.row and col_v.col and self.m_DownListData[col_v.row] and self.m_DownListData[col_v.row][col_v.col] then
                    trackRewardStr = trackRewardStr..","..tostring(self.m_DownListData[col_v.row][col_v.col].curRewardID)
                    GameTableDefine.CoinPusherManager:SetChoosableAward(row, col, self.m_DownListData[col_v.row][col_v.col].curRewardID, double)
                end
            end
        end
        self:OnExitGameChooseView()
        self:InitMap()
        GameTableDefine.CoinPusherManager:AddChooseAwardTimes(1)
        --2024-12-31fy添加用于埋点，设置选择小游戏奖励成功
        GameSDKs:TrackForeign("pass_game_choose", {time = GameTableDefine.CoinPusherManager:GetChooseAwardTimes(), results = trackRewardStr})
    end)
    self.gameChooseRootGo:SetActive(true)
    self.gameChooseGuideAniState = 0
    if IsFirstEnter then
        --播放引导的动画
        self:PlayChooseGuidAnimation(1)
        IsFirstEnter = false
    else
        self:PlayChooseGuidAnimation(2)
    end
    if self.guideAniTimer then
        GameTimer:StopTimer(self.guideAniTimer)
        self.guideAniTimer = nil
    end
    --设置回调函数了
    
    self.upPointDownUpItem =  self:GetComp(self.gameChooseRootGo, "checkPressPanel", "UIPointDownUpItem")
    if self.upPointDownUpItem then
        self.upPointDownUpItem:SetPointUpGetTouchesCB(function(touches) 
            if touches > 0 then
                self:PlayChooseGuidAnimation(2)
            end
            if touches > 0 and self.guideAniTimer then
                GameTimer:StopTimer(self.guideAniTimer)
                self.guideAniTimer = nil
            end
            if touches == 0 and not self.guideAniTimer then
                self.guideAniTimer = GameTimer:CreateNewTimer(4, function()
                    self:PlayChooseGuidAnimation(1)
                 end, false, false)
            end
        end)
    end
end

function SeasonPassUIView:RefreshConfirmBtn()
    self.btnConfirm.interactable = self:CheckCanConfirm()
end

function SeasonPassUIView:RefreshDownListData()
    self.m_DownListData = {}
    self.m_DownListData[1] = {}
    self.m_DownListData[2] = {}
    --step1库存数据的加载
    for _, v in pairs(GameTableDefine.ConfigMgr.config_pass_game_tuibiji[3]) do
        local itemData = {}
        itemData.curStorage = tonumber(v.storage)
        itemData.curMaxStorage = tonumber(v.storage)
        itemData.curShareNum = tonumber(v.item_num)
        itemData.curRow = tonumber(v.row_num[1])
        itemData.curCol = tonumber(v.column_num[1])
        itemData.curRewardID = tonumber(v.id)
        itemData.isTimeReward = false --奖励需要换成时间显示的内容
        local shopCfg = GameTableDefine.ConfigMgr.config_shop[tonumber(v.shop_id)]
        itemData.curIcon = shopCfg.icon
        if shopCfg and shopCfg.type == 9 then
            itemData.curShareNum = math.floor((v.item_num * shopCfg.amount * 3600)/60)
            itemData.isTimeReward =  true
            if GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                itemData.curIcon = shopCfg.icon.."_euro"
            end
        end
        
        if self.m_DownListData[itemData.curRow] then
            self.m_DownListData[itemData.curRow][itemData.curCol] = itemData
        end
    end
end

function SeasonPassUIView:RefreshUpListData()
    self.m_UpListData = {}
    self.m_UpListData[1] = {}
    self.m_UpListData[2] = {}
    for i =1, 5 do
        self.m_UpListData[1][i] = {}
        self.m_UpListData[2][i] = {}
    end
end

function SeasonPassUIView:RefreshUpListItems()
    for row, v in pairs(self.m_UpListData) do
        for col, data in pairs(v) do
            if self.m_UpListItemGos[row] and self.m_UpListItemGos[row][col] then
                local itemGo = self.m_UpListItemGos[row][col]
                local choosedGo = self:GetGo(itemGo, "choosed")
                local isHaveData = Tools:GetTableSize(data) > 0
                choosedGo:SetActive(isHaveData)
                if isHaveData and self.m_DownListData[data.row] and self.m_DownListData[data.row][data.col] then
                    local downData = self.m_DownListData[data.row][data.col]
                    self:SetSprite(self:GetComp(choosedGo, "icon", "Image"), "UI_Shop", downData.curIcon)
                    local showNum = downData.curShareNum
                    if row == 1 then
                        showNum = showNum * 2   
                    end
                    if downData.isTimeReward then
                        showNum = tostring(showNum).."Min"
                    end 
                    self:SetText(choosedGo, "num", showNum)
                    self:SetButtonClickHandler(self:GetComp(choosedGo, "delBtn", "Button"), function()
                        self.m_DownListData[data.row][data.col].curStorage  = self.m_DownListData[data.row][data.col].curStorage + 1
                        if self.m_DownListData[data.row][data.col].curStorage > self.m_DownListData[data.row][data.col].curMaxStorage then
                            self.m_DownListData[data.row][data.col].curStorage = self.m_DownListData[data.row][data.col].curMaxStorage
                        end
                        self.m_UpListData[row][col] = {}
                        choosedGo:SetActive(false)
                        self:RefreshDownListItems()
                        self:RefreshUpListItems()
                    end)
                end
            end
        end
    end
    self:RefreshConfirmBtn()
end

function SeasonPassUIView:RefreshDownListItems()
    
    -- self.m_DownListData = {12122121}
    for row, v in pairs(self.m_DownListItemGos) do
        for col, itemGo in pairs(v) do
            local data = self.m_DownListData[row][col]
            -- local index = (row - 1) * 5 + col
            local pressDown = self:GetComp(itemGo, "canChoose", "UIPickUpItem")
            local notChooseGo = self:GetGo(itemGo, "choosed")
            local storgeNumGo = self:GetGo(itemGo, "numList")
            local showGos = self:GetGo(itemGo, "canChooseShow")
            local showNum = data.curShareNum
            if data.isTimeReward then
                showNum = tostring(data.curShareNum).."Min"
            end
            self:SetSprite(self:GetComp(pressDown.gameObject, "icon", "Image"), "UI_Shop", data.curIcon)
            self:SetText(pressDown.gameObject, "num", tostring(showNum))
            self:SetSprite(self:GetComp(notChooseGo, "icon", "Image"), "UI_Shop", data.curIcon)
            self:SetText(notChooseGo, "num", tostring(showNum))
            self:SetSprite(self:GetComp(showGos, "icon", "Image"), "UI_Shop", data.curIcon)
            self:SetText(showGos, "num", tostring(showNum))
            self:SetText(storgeNumGo, "remain", tostring(data.curStorage))
            self:SetText(storgeNumGo, "max", tostring(data.curMaxStorage))
            notChooseGo:SetActive(data.curStorage <= 0)
            if pressDown then
                pressDown:ClearDropZones()
                if not self.m_DownListData[row] or not self.m_DownListData[row][col] or self.m_DownListData[row][col].curStorage <= 0 then
                    pressDown.gameObject:SetActive(false)
                    showGos:SetActive(false)
                else
                    pressDown:SetMoveParent(self.gameChooseRootGo.transform)
                    pressDown.gameObject:SetActive(true)
                    showGos:SetActive(true)
                    for upRow, upV in pairs(self.m_UpListItemGos) do
                        for upCol, zoneGo in pairs(upV) do
                            local key = (upRow - 1)*5 + upCol
                            pressDown:AddDropZone(key, zoneGo)
                        end
                    end
                    pressDown:SetOnEndDragCallback(function(index, go)
                        -- print("OnShowGameChooseView endDragCallback:index is:"..tostring(index).."destionGame name is:"..go.name)
                        local cbUpRow = math.floor(index / 5) + 1
                        local cbUpCol = index % 5
                        if cbUpCol == 0 then
                            cbUpRow  = cbUpRow - 1
                            cbUpCol = 5
                        end
                        if self.m_UpListData[cbUpRow] and self.m_UpListData[cbUpRow][cbUpCol] and self.m_UpListData[cbUpRow][cbUpCol].row and self.m_UpListData[cbUpRow][cbUpCol].col then
                            return
                        end
                        if not self.m_UpListData[cbUpRow] then
                            self.m_UpListData[cbUpRow] = {}
                        end
                        if not self.m_UpListData[cbUpRow][cbUpCol] then
                            self.m_UpListData[cbUpRow][cbUpCol] = {}
                        end
                        self.m_UpListData[cbUpRow][cbUpCol].row = row
                        self.m_UpListData[cbUpRow][cbUpCol].col = col
                        self.m_DownListData[row][col].curStorage  = self.m_DownListData[row][col].curStorage - 1
                        self:RefreshDownListItems()
                        self:RefreshUpListItems()
                    end)
                end
            end
        end
    end
    -- for i = 1, Tools:GetTableSize(self.m_DownListItemGos) do
    --     local itemGo = self.m_DownListItemGos[i]
    --     local pressDown = self:GetComp(itemGo, "canChoose", "UIPickUpItem")
        
    --     if pressDown then
    --         pressDown:ClearDropZones()
    --         if not self.m_DownListData[i] then
    --             pressDown.gameObject:SetActive(false)
    --         else
    --             pressDown:SetMoveParent(self.gameChooseRootGo.transform)
    --             pressDown.gameObject:SetActive(true)
    --             for key, zoneGo in pairs(self.m_UpListItemGos) do
    --                 pressDown:AddDropZone(key, zoneGo)
    --             end
    --             pressDown:SetOnEndDragCallback(function(index, go)
    --                 -- print("OnShowGameChooseView endDragCallback:index is:"..tostring(index).."destionGame name is:"..go.name)
    --                 if self.m_UpListData[index] then
    --                     local openGo = self:GetGo(go, "choosed")
    --                     openGo:SetActive(true)
    --                     print("源数据内容是:"..tostring(self.m_DownListData[i]))

    --                 end
    --             end)
    --         end
    --     end
    -- end
end

function SeasonPassUIView:CheckCanConfirm()
    for row, v in pairs(self.m_UpListData) do
        for col, data in pairs(v) do
            if not data.row or not data.col then
                return false
            end
        end
    end
    return true
end

function SeasonPassUIView:OnExitGameChooseView()
    if self.gc_PickUpItemGo then
        self.gc_PickUpItemGo:SetActive(false)
    end
    self.gameChooseRootGo:SetActive(false)
    if self.guideAniTimer then
        GameTimer:StopTimer(self.guideAniTimer)
        self.guideAniTimer = nil
    end
    self.gameChooseGuideAniState = 0
end

--[[
    @desc: 1-播放引导动画，2-停止引导动画播放
    author:{author}
    time:2024-12-31 14:17:31
    --@state: 
    @return:
]]
function SeasonPassUIView:PlayChooseGuidAnimation(state)
    if not self.chooseGuideAnimator then
        self.chooseGuideAnimator = self:GetComp(self.gameChooseRootGo, "bg", "Animator")
    end
    if self:CheckCanConfirm() then
        self.chooseGuideAnimator:Play("UI_tuibiji_chooseWindow_guide_close")
        self.gameChooseGuideAniState = 2
        return
    end
    if state == 1 and self.gameChooseGuideAniState ~= state then
        self.chooseGuideAnimator:Play("UI_tuibiji_chooseWindow_guide")
        self.gameChooseGuideAniState = state
    elseif state == 2 and self.gameChooseGuideAniState ~= state then
        self.chooseGuideAnimator:Play("UI_tuibiji_chooseWindow_guide_close")
        self.gameChooseGuideAniState = state
    end
end
