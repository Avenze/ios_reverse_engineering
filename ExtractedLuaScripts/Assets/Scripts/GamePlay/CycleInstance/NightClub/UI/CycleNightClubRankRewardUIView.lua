--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 10:39:57
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FeelUtil = CS.Common.Utils.FeelUtil
local InstanceDataManager = GameTableDefine.InstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local UI = GameTableDefine.CycleNightClubRankRewardUI
local CycleNightClubRankRewardUIView = Class("CycleNightClubRankRewardUIView", UIView)


function CycleNightClubRankRewardUIView:ctor()
    self.super:ctor()
    self.m_uiModel = UI:GetUIModel()

    self.m_level = nil -- 当前操作的彩蛋等级
    self.m_index = nil -- 当前等级操作的彩蛋索引
    self.m_eggsGO = nil -- 彩蛋节点
    self.m_playable = nil -- 每个彩蛋上的timeline的playable组件
    self.m_openingBtn = nil -- 点击按钮
    self.m_tipGO = nil -- 点击提示节点
    self.m_rewardGO = nil -- 弹出奖励节点
    self.m_rewardFeel = nil
    self.m_frame1 = nil -- 事件1节点
    self.m_RewardDataList = {{}, {}}
end

function CycleNightClubRankRewardUIView:OnEnter()
    --print("================11111111111111")
    --埋点:查看副本详情
    local buildingID = CityMode:GetCurrentBuilding()
    GameSDKs:TrackForeign("rank_activity", {name = "LimitInstance", operation = "1", score_new = tonumber(InstanceDataManager:GetCurInstanceKSLevel()) or 0, scene_id = buildingID})

    self:InitView()
    self:ShowAchievements()
end

function CycleNightClubRankRewardUIView:getTableCount(t)
    local num = 0
    for i, v in pairs(t) do
        if v then
            num = num + 1
        end
    end
    
    return num
end

function CycleNightClubRankRewardUIView:InitView()
    --local count = #self.m_uiModel.rewardTypeConfig
    self.m_eggsGO = {}
    self.m_playable = {}
    --for i=1,count do
    --    self.m_eggsGO[i] = self:GetGo("background/MediumPanel/chestPivot/chest/"..tostring(i))
    --    self.m_playable[i] = self:GetComp(self.m_eggsGO[i],"","PlayableDirector")
    --end

    local max_egg_type = 0
    for egg_type, egg_num in pairs(self.m_uiModel.eggs) do
        self.m_eggsGO[egg_type] = self:GetGo("background/MediumPanel/chestPivot/chest/"..tostring(egg_type))
        self.m_playable[egg_type] = self:GetComp(self.m_eggsGO[egg_type],"","PlayableDirector")
        if egg_type > max_egg_type then
            max_egg_type = egg_type
        end
    end

    local chestTrans = self:GetTrans("background/MediumPanel/chestPivot/chest")
    for i = 1, chestTrans.childCount do
        self:GetGo("background/MediumPanel/chestPivot/chest/"..tostring(i)):SetActive(false)
    end
    
    self.m_level = max_egg_type
    self.m_index = self.m_uiModel.eggs[self.m_level]
    self.m_openingBtn = self:GetComp("background/MediumPanel/opening","Button")
    self.m_tipGO = self:GetGo("background/BottomPanel/tipText")
    self.m_rewardGO = self:GetGo("background/MediumPanel/reward")
    self.m_rewardFeel = self:GetComp(self.m_rewardGO,"openFB","MMFeedbacks")
    self.m_openingBtn.interactable = false

    local reallyRewards = self.m_uiModel.reallyRewards
    if not reallyRewards or self:getTableCount(reallyRewards) <= 0 then
        GameTableDefine.InstanceRewardUI:CloseView()
        return
    end
    --for i = 1, Tools:GetTableSize(reallyRewards) do
    --    if reallyRewards[i] then
    --        table.insert(self.m_RewardDataList, i + 1, reallyRewards[i])
    --    end
    --end

    for egg_type, egg_conf in pairs(reallyRewards) do
        table.insert(self.m_RewardDataList, egg_conf)
    end

    -- 点击开蛋事件:
    EventManager:RegEvent("EVENT_OPEN_EGG", function(go)
        self.m_playable[self.m_level]:Pause()
        self.m_frame1 = self.m_playable[self.m_level].time
        self.m_tipGO:SetActive(true)
        self.m_openingBtn.interactable = true

        self:SetButtonClickHandler(self.m_openingBtn,function()
            local curEgg = self:OpenAEgg(true)
            if curEgg~= nil then -- 显示下一个同级奖励
                if self.m_index >= 1 then
                    self.m_openingBtn.interactable = false
                    self.m_tipGO:SetActive(false)
                    self.m_playable[self.m_level]:Resume()
                    self.m_rewardGO:SetActive(true) -- 第一次动画自动播放
                    --设置奖励信息
                    self:SetRewardInfo()

                else -- 显示下一级奖励
                    self:OpenAEgg()
                    self:ShowAchievements()
                end
            else  -- 显示全部奖励
                self.m_rewardGO:SetActive(false)
                self:OpenAllRewardList()
            end

        end)
    end)
    -- 继续开蛋事件
    EventManager:RegEvent("EVENT_CONTINUE_OPEN_EGG", function(go)
        self.m_playable[self.m_level]:Pause()
        self.m_tipGO:SetActive(true)
        self.m_openingBtn.interactable = true

        self:SetButtonClickHandler(self.m_openingBtn, function()
            local curEgg = self:OpenAEgg(true)
            if curEgg~= nil then
                if self.m_index >= 1 then -- 显示下一个同级奖励
                    self.m_openingBtn.interactable = false
                    self.m_tipGO:SetActive(false)
                    self.m_playable[self.m_level]:Play()
                    self.m_playable[self.m_level].time = self.m_frame1
    
                    --设置奖励信息
                    self:SetRewardInfo()
                else -- 显示下一级奖励
                    self:OpenAEgg()
                    self:ShowAchievements()
                end
            else -- 显示全部奖励
                self.m_rewardGO:SetActive(false)
                self:OpenAllRewardList()
            end

        end)
    end)

    self:SetButtonClickHandler(self:GetComp("background/MediumPanel/bg","Button"), function()
    end)

    self:ShowAchievements()
end

function CycleNightClubRankRewardUIView:SetRewardInfo()
    self.m_rewardFeel:PlayFeedbacks()

    local rewardID = self.m_uiModel.reallyRewards[self.m_level].rewardList[self.m_index][1]
    local rewardData = self.m_uiModel.shopConfig[rewardID]
    self:SetText(self.m_rewardGO,"icon/num","+"..rewardData.amount)
    self:SetSprite(self:GetComp(self.m_rewardGO,"icon","Image"),"UI_Shop",rewardData.icon)

    self:OpenAEgg()
    self:SetText(self.m_eggsGO[self.m_level],"num", "x"..self.m_index)
end

function CycleNightClubRankRewardUIView:ShowAchievements()
    self.m_openingBtn.interactable = false
    self.m_tipGO:SetActive(false)

    self.m_playable[self.m_level].time = 0
    local curEgg = self:OpenAEgg(true)
    if curEgg == nil then   -- 没有新的蛋了, 展示所有得到的奖励
    else -- 还有没开完的蛋, 继续开蛋
        --for i=1,#self.m_eggsGO do
        --    self.m_eggsGO[i]:SetActive(i == self.m_level)
        --end

        for egg_type, obj in pairs(self.m_eggsGO) do
            self.m_eggsGO[egg_type]:SetActive(egg_type == self.m_level)
        end
        
        local go = self.m_eggsGO[self.m_level]
        self:SetText(go,"num", "x"..self.m_index)
    end
    self.m_rewardGO:SetActive(false)

end



--[[
    @desc: 所有蛋的开完显示所有奖励列表，并于一定时间后开启点关闭
    author:{author}
    time:2023-04-28 10:58:33
    @return:
]]
function CycleNightClubRankRewardUIView:OpenAllRewardList()
    
    self:SetButtonClickHandler(self.m_openingBtn, function()
        self:DestroyModeUIObject()
    end)


    self:SetText("background/HeadPanel/bg/title", GameTextLoader:ReadText("TXT_INSTANCE_TOTAL_REWARD"))
    local allRewardData = {}
    -- ["rewardList"] = {{1001,1002},{1001}},
    for _, v in pairs(self.m_RewardDataList) do
        if Tools:GetTableSize(v) > 0 then
            for _, v1 in ipairs(v.rewardList) do
                for _, v3 in ipairs(v1) do
                    local shopCfg = ConfigMgr.config_shop[v3]
                    if shopCfg then
                        if not allRewardData[v3] then
                            allRewardData[v3] = shopCfg.amount
                        else
                            allRewardData[v3]  = allRewardData[v3] + shopCfg.amount
                        end
                    end
                end 
            end
        end
    end
    if Tools:GetTableSize(allRewardData) <= 0 then
        UI:CloseView()
        return
    end
    local itemGoList = {}
    local goCounter = 1
    local itemGO = self:GetGoOrNil("background/MediumPanel/list/item")
    local parentGO = self:GetGoOrNil("background/MediumPanel/list")
    --TODO：这里需要去重，用显示类型判断
    --{shopID = amount, displayType = 0, icon = ""}
    local newAllRewardData = {}
    local haveTypes = {}
    local haveTypeIndex = {}
    local needConvertDiamondItems = {}
    local diamondIndex = 0
    local converNum = 0
    for shopID, v in pairs(allRewardData) do 
        local shopCfg = ConfigMgr.config_shop[shopID]
        if shopCfg then
            if shopCfg.category_type > 0 then
                local isHaveType = false
                local haveIndex = 0
                for index, haveType in ipairs(haveTypes) do
                    if haveType == shopCfg.category_type then
                        isHaveType = true
                        haveIndex = index
                        break
                    end
                end
                if not isHaveType then
                    local tmpData = {}
                    tmpData.amount = v
                    tmpData.icon = shopCfg.category_icon
                    table.insert(newAllRewardData, tmpData)
                    table.insert(haveTypes, shopCfg.category_type)
                    table.insert(haveTypeIndex, Tools:GetTableSize(newAllRewardData))
                    if shopCfg.category_type == 3 then
                        diamondIndex = Tools:GetTableSize(newAllRewardData)
                    end
                else
                    if haveIndex > 0 and haveTypeIndex[haveIndex] and newAllRewardData[haveTypeIndex[haveIndex]] then
                        newAllRewardData[haveTypeIndex[haveIndex]].amount = newAllRewardData[haveTypeIndex[haveIndex]].amount + v
                    end
                end
            else
                if InstanceDataManager:IsConvertShopItem(shopID) then
                    converNum  = converNum + InstanceDataManager:GetSameShopItemConverToDiamond(shopID)
                else
                    local tmpData = {}
                    tmpData.amount = v
                    tmpData.icon = shopCfg.icon
                    table.insert(newAllRewardData, tmpData)
                end
                
            end
        end
    end
    --对于转换给钻石的物品作为显示
    if converNum > 0 then
        if diamondIndex > 0 then
            newAllRewardData[diamondIndex].amount = newAllRewardData[diamondIndex].amount + converNum
        else
            local tmpData = {}
            tmpData.amount = converNum
            tmpData.icon = "icon_shop_diamond_1"
            table.insert(newAllRewardData, tmpData)
        end
    end
    for k, v in ipairs(newAllRewardData) do
        if goCounter == 1 then
            self:SetSprite(self:GetComp(itemGO, "icon", "Image"), "UI_Shop", v.icon)
            self:SetText(itemGO, "bg/num", "+"..tostring(Tools:SeparateNumberWithComma(v.amount)))
        else
            local tempGo = UnityHelper.CopyGameByGo(itemGO, parentGO)
            self:SetSprite(self:GetComp(tempGo, "icon", "Image"), "UI_Shop", v.icon)
            self:SetText(tempGo, "bg/num", "+"..tostring(Tools:SeparateNumberWithComma(v.amount)))
        end
        goCounter  = goCounter + 1
    end
    parentGO:SetActive(true)

end



--[[
    @desc: 开蛋
    author:{author}
    time:2023-10-17 14:44:49
    --@isPre: 是否预先获取将要开的蛋的信息
    @return:
]]
function CycleNightClubRankRewardUIView:OpenAEgg(isPre)
    local eggs = self.m_uiModel.eggs
    local eggType = nil
    if self.m_index >= 1 then
        if not isPre then
            self.m_index = self.m_index - 1
        end
        eggType = self.m_level
    else
        local nextEgg
        local nextIndex
        for i = 1, self:getTableCount(eggs) do
            if eggs[self.m_level - i] then
                nextIndex = i
                nextEgg = eggs[self.m_level - i]
                break
            end
        end

        if nextEgg then
            if not isPre then
                self.m_level = self.m_level - nextIndex
                self.m_index = eggs[self.m_level]
            end
            eggType = self.m_level
        end
    end
    return eggType 
end

function CycleNightClubRankRewardUIView:OnExit()
    if self.tiemr then
        GameTimer:_RenewTimer(self.tiemr)
    end

	self.super:OnExit(self)
end

return CycleNightClubRankRewardUIView