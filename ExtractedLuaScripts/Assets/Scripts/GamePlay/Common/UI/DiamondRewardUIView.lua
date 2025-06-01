local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Color = CS.UnityEngine.Color

local MainUI = GameTableDefine.MainUI
local GameUIManager = GameTableDefine.GameUIManager
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local TimerMgr = GameTimeManager
local ConfigMgr = GameTableDefine.ConfigMgr

local DiamondRewardUIView = Class("DiamondRewardUIView", UIView)

local HEAD  = 1 -- head
local MEDIUM_VEDIO = 2 -- medium_vedio
local MEDIUM_DIAMOND = 3 -- medium_diamond
local TAIL = 4 --tail

function DiamondRewardUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function DiamondRewardUIView:OnEnter()
    print("DiamondRewardUIView:OnEnter")

    local btn = self:GetComp("background/BottomPanel/RewardBtn", "Button")
    local rewardAble,rewards = DiamondRewardUI:ClamADRewards(true)

    self:SetButtonClickHandler(btn, function()
        btn.interactable = false
        if rewardAble then
            DiamondRewardUI:ClamADRewards()
            for k,v in ipairs(rewards) do
                EventManager:DispatchEvent("FLY_ICON", self:GetTrans("background/BottomPanel/RewardBtn").position,
                v[1], v[2])
            end
        end
    end)

    self:SetButtonClickHandler(self:GetComp("background/QuitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    local curr = TimerMgr:GetCurrentServerTime()
    local toYear = tonumber(os.date("%Y",curr))
    local toMonth = tonumber(os.date("%m",curr)) 
    local today = tonumber(os.date("%d",curr))
    local toHour = tonumber(os.date("%H",curr))
    self.endPoint = os.time({year = toYear, month = toMonth, day = today, hour = 5, min = 0, sec = 0})
    if toHour > 5 then
        self.endPoint = self.endPoint + 24 * 60 * 60
    end

    self:CreateTimer(1000, function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        local timeTxt = TimerMgr:FormatTimeLength(t)
        if t > 0 then
            self:SetText("background/BottomPanel/refresh_time", timeTxt)
        else
            DiamondRewardUI:ShowRewardPanel()
        end
    end, true, true)
    --开启一个计时器
end

function DiamondRewardUIView:OnPause()
    print("DiamondRewardUIView:OnPause")
end

function DiamondRewardUIView:OnResume()
    print("DiamondRewardUIView:OnResume")
end

function DiamondRewardUIView:OnExit()
    self.super:OnExit(self)
    print("DiamondRewardUIView:OnExit")
end

function DiamondRewardUIView:SetRewardStatus(data)
    -- type 1 头  4 尾 2 不带奖励 3 带奖励
    -- diamond 奖励数量
    -- status 1 已经完成待领取 2 已经领取 3未完成

    --现在是{adTimes = 3, diamond = 5, status = 1,2,3}
    --status 1已完成带岭区 2已领取 3未完成
    local btn = self:GetComp("background/BottomPanel/RewardBtn", "Button")
    local rewardAble = DiamondRewardUI:ClamADRewards(true)
    btn.interactable = rewardAble

    local progress = self:GetGo("background/MediumPanel/Frame/progress")
    local slider = self:GetComp(progress, "", "Slider")
    
    local adTotalNeed = data[#data].adTimes
    local progressWidth = progress.transform.rect.width
    local adRate = progressWidth / adTotalNeed

    local toAdTime = LocalDataManager:GetDataByKey("ad_data").todayAdTime
    slider.value = toAdTime / adTotalNeed

    local rewardHolder = self:GetGo("background/MediumPanel/Frame/progress/rewardHolder")
    local prefab = self:GetGo("background/MediumPanel/Frame/progress/rewardHolder/item")
    local buttonName = {"wait", "checked", "unchecked"}
    for i, v in ipairs(data or {}) do
        local currRoot = UnityHelper.FindTheChild(rewardHolder, "item"..i)--self:GetGo(rewardHolder, "item"..i)
        if not currRoot then
            currRoot = GameObject.Instantiate(prefab, rewardHolder.transform)
            currRoot.name = "item"..i
        else
            currRoot = currRoot.gameObject
        end

        self:GetGo(currRoot, "top"):SetActive(i % 2 ~= 0)
        self:GetGo(currRoot, "bottom"):SetActive(i % 2 == 0)
        
        local currPath = i % 2 ~= 0 and "top/" or "bottom/"

        self:GetGo(currRoot, currPath .. "wait"):SetActive(v.status == 1)
        self:GetGo(currRoot, currPath .. "checked"):SetActive(v.status == 2)
        self:GetGo(currRoot, currPath .. "unchecked"):SetActive(v.status == 3)

        self:SetText(currRoot, currPath .. buttonName[v.status].."/text", v.reward[2])
        self:SetText(currRoot, currPath .. buttonName[v.status].."/seq", v.adTimes)
        self:GetGo(currRoot, currPath .. buttonName[v.status].."/D"):SetActive(v.reward[1] == 3)
        self:GetGo(currRoot, currPath .. buttonName[v.status].."/C"):SetActive(v.reward[1] == 2)
        local rootPos = currRoot.transform.anchoredPosition
        rootPos.x = adRate * v.adTimes
        currRoot.transform.anchoredPosition = rootPos
    end
    prefab:SetActive(false)
end


return DiamondRewardUIView