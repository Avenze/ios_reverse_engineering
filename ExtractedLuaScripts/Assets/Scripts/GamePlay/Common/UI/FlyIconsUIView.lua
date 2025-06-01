local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local GameUIManager = GameTableDefine.GameUIManager
local FeelUtil = CS.Common.Utils.FeelUtil
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local DotweenUtil = CS.Common.Utils.DotweenUtil
local GameObject = CS.UnityEngine.GameObject
local Input = CS.UnityEngine.Input
local Vector3 = CS.UnityEngine.Vector3

---@class FlyIconsUIView:UIBaseView
local FlyIconsUIView = Class("FlyIconsUIView", UIView)

local MainUI = GameTableDefine.MainUI
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CEODataManager = GameTableDefine.CEODataManager
local EventDispatcher = EventDispatcher
local CycleNightClubMainViewUI = GameTableDefine.CycleNightClubMainViewUI

--local setting = ConfigMgr.config_global.fly_icon_setting

local TYPE_TO_NAME = {--按照ResourceManager的顺序
    [2] = "Cash",
    [3] = "Diamond",
    --[4] = "Ticket",
    [5] = "Star",
    [6] = "Euro",
    [7] = "Token",
    [8] = "Support",
    ----100开始为不需要和按照ResourceManager对应的枚举
    [100] = "fragment_Token",
    [101] = "Strength",
    [102] = "fragment_Token_2",
    [103] = "fragment_task_",
    --副本资源    
    [104] = "instance_cash_1_",
    [105] = "instance_cash_2_",
    [106] = "instance_cash_3_",
    [107] = "instance_res_",
    --钻石基金
    [108] = "DiamondFund",
    --钻石月卡首次300钻
    [109] = "MonthCardUI_",
    --循环副本资源
    [26] = "instance_FlyIcon",
    [27] = "instance_FlyIcon",
    [30] = "instance_FlyIcon",
    [31] = "instance_FlyIcon",
    [203] = "instace_Tip",
    --副本礼包界面关闭
    [204] = "Instance_pack_",
    [205] = "Instance2_pack_",
    [206] = "Instance2_Milepost_",
    --[106] = "fragment_task_",
    --3号副本蓝图碎片
    [207] = "Instance3_Blueprint_ex1_",
    [208] = "Instance3_Blueprint_ex2_",
    [209] = "Instance3_Blueprint_ex3_",
    --4号副本蓝图碎片
    [210] = "Instance4_Blueprint_ex1_",
    [211] = "Instance4_Blueprint_ex2_",
    [212] = "Instance4_Blueprint_ex3_",
}

local CycleInstanceTypeToName = {
    --循环副本资源
    [3] = "item_diamond",
    [26] = "item_heroExp",
    [27] = "item_skillBook",
    [30] = "item_labaToken",
    [31] = "item_instance1_cash",
    [36] = "item_shard",
    [201] = "item_milePoint",
    [202] = "item_product",
    [301] = "item_labaToken_2",
    [302] = "item_piggypack_slot",
}

local HighLevelIcons = {
    [1] = "ceo_key",
    [2] = "ceo_chest",
    [3] = "ceo_keyFly",
    [4] = "clockoutFlyIcon",
}

function FlyIconsUIView:GetNodeFromPool(icon, prefab)
    --从对象池获取,如果没有则重新创建一个prefab,加入对象池
    if not self.m_simplePool then
        self.m_simplePool = {}
    end
    
    local item = nil
    for i,v in ipairs(self.m_simplePool[icon] or {}) do
        if not v.activeSelf then
            item = v--有时候这里会为空....可能是偶尔造成闪一下的原因
            break
        end
    end

    if item == nil then
        item = GameObject.Instantiate(prefab, prefab.transform.parent)
        if self.m_simplePool[icon] == nil then
            self.m_simplePool[icon] = {}
        end
        self.m_simplePool[icon][#self.m_simplePool[icon] + 1] = item
        --调整生成出来的物体的层级
        if prefab.transform.parent == self.m_uiObj.transform then
            item.transform:SetSiblingIndex(self:GetLowSibling())
        end
    end

    item:SetActive(true)
    return item
end

--获取底层层级
function FlyIconsUIView:GetLowSibling()
    return self.m_uiObj.transform.childCount - 1 - self.m_highLevelIconsCount
end

function FlyIconsUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_highLevelIconsCount = #HighLevelIcons
end

function FlyIconsUIView:OnEnter()
    self.m_simplePool = {}
    self.m_switchScene = self:GetComp("SwitchScene", "Image")
    self.m_switchSceneGo = self:GetGo("SwitchScene")

    for i = 1, self.m_highLevelIconsCount do
        local iconName = HighLevelIcons[i]
        self:GetTrans(iconName):SetAsLastSibling()
    end
end

function FlyIconsUIView:OnExit()
    self.super:OnExit(self)
    self.m_simplePool = nil
end

function FlyIconsUIView:setPurchaseCheck(isWaiting)
    local purchaseCheck = self:GetGo("Purchase_check")
    purchaseCheck:SetActive(isWaiting)
    if isWaiting then
        self:SetText(purchaseCheck, "content/HeadPanel/desc", GameTextLoader:ReadText("TXT_SHOP_CERTIFY"))

        local load = self:GetGo(purchaseCheck, "content/BottomPanel/loading")
        load:SetActive(true)
        local btn = self:GetGo(purchaseCheck, "content/BottomPanel/YesBtn")
        btn:SetActive(false)

        self:SetButtonClickHandler(self:GetComp(purchaseCheck, "bg", "Button"), function()
            purchaseCheck:SetActive(false)
        end)
    end
end

function FlyIconsUIView:FailService()
    local purchaseCheck = self:GetGo("Purchase_check")

    self:SetText(purchaseCheck, "content/HeadPanel/desc", GameTextLoader:ReadText("TXT_SHOP_CERTIFY_FAIL"))

    local load = self:GetGo(purchaseCheck, "content/BottomPanel/loading")
    load:SetActive(false)
    local btn = self:GetGo(purchaseCheck, "content/BottomPanel/YesBtn")
    btn:SetActive(true)

    self:SetButtonClickHandler(self:GetComp(btn, "", "Button"), function()
        purchaseCheck:SetActive(false)
    end)
end

function FlyIconsUIView:Show(pos, icon, num, cb)--然而现在只需要icon,cb了,但是之前用的比较多就先不想改了
    local name = TYPE_TO_NAME[icon]
    if not name then
        return
    end

    local flyFromPool = function(name, cb)
        local flyNode = self:GetNodeFromPool(name, self:GetGo(name.."Fly"))
        local ani = self:GetComp(flyNode, "", "Animation")
        SoundEngine:PlaySFX("Assets/Res/Audio/SFX_reward.ogg")
        AnimationUtil.Play(ani, name.."Fly_Anim", function()
            if cb then cb(nil) end
            MainUI:UpdateResourceUI()
            --MainUI:RefreshStarState()
            if icon == 5 then
                MainUI:PlayStarAnim()
                MainUI:RefreshStarState()
            else
                flyNode:SetActive(false)
            end
        end)
    end

    flyFromPool(name, cb)
end

--播放带有可选坐标的粒子动画
function FlyIconsUIView:ShowMoveAn(icon, cb)
    local name = TYPE_TO_NAME[icon]
    if not name then
        return
    end
    local flyFromPool = function(name, cb)
        local flyNode = self:GetGo(name)
        flyNode:SetActive(true)
        local feel = self:GetComp(flyNode, "", "MMFeedbacks")
        flyNode.transform.position = UnityHelper.GetTouchPosition(GameUIManager.m_uiCamera)

        if feel then
            feel.Events.OnComplete:AddListener(function()
                flyNode:SetActive(false)
            end)
            -- feel.onComplete:AddListener(function()
            --     flyNode:SetActive(false)
            --     if cb then cb(nil) end
            --     MainUI:UpdateResourceUI()
            --     MainUI:RefreshStarState()
            -- end)
            FeelUtil.PlayFeel(feel.gameObject)
        end       
        SoundEngine:PlaySFX("Assets/Res/Audio/SFX_reward.ogg")
    end

    flyFromPool(name, cb)
end

function FlyIconsUIView:SetSceneSwitchMask(percent, state)
    if self.m_switchScene and not self.m_switchScene:IsNull() then
        if state == 0 then -- 普通帧
            if not self.m_switchSceneGo.activeSelf and percent > 0 then
                self.m_switchSceneGo:SetActive(true)
            end
        elseif state == 1 then -- 最后一帧
            if self.m_switchSceneGo.activeSelf and percent < 0.4 then
                self.m_switchSceneGo:SetActive(false)
            end
        end
        if not self.m_switchSceneGo.activeSelf then
            return
        end
        local c = self.m_switchScene.color
        c.a = percent
        self.m_switchScene.color = c
    end
end

function FlyIconsUIView:SetNetWorkLoading(enable)
    local purchaseCheck = self:GetGo("NetworkLoading")
    purchaseCheck:SetActive(enable)
end

function FlyIconsUIView:SetInstanceResItem(res)
    local item = self:GetGo("instance_res_Fly/list/item")
    Tools:SetTempGo(item, #res, true, function(go, index)
        go = go.gameObject
        local resCfg = res[index].resCfg
        --local num = res[index].count
        self:SetSprite(self:GetComp(go, "bg/icon", "Image"), "UI_Common", resCfg.icon)
        --self:SetText(go, "num", Tools:SeparateNumberWithComma(math.floor(num)))
    end)
end

---@class CycleFlyIconResInfo
---@field itemType number
---@field str string
---@field icon string
local CycleFlyIconResInfo = {}

---@param res CycleFlyIconResInfo[]
function FlyIconsUIView:SetCycleInstanceNum(res, cb)
    if next(res) == nil then
        return
    end

    --一个循环副本对应一个根节点
    local nodePath = CycleInstanceDataManager:GetCurrentModel().config_instance_bind.fly_fullPath or "instance_FlyIcon"

    local cycleInstanceRoot = self:GetNodeFromPool(nodePath, self:GetGo(nodePath))
    local itemParentTrans = self:GetTrans(cycleInstanceRoot,"list")
    SoundEngine:PlaySFX("Assets/Res/Audio/SFX_reward.ogg")

    local playingCycleInstanceCount = 0

    for k,v in pairs(res) do
        local itemType = v.itemType
        local str = v.str
        local childName = CycleInstanceTypeToName[itemType]
        if childName then
            local childGOTemplate = self:GetGo(cycleInstanceRoot,"list/"..childName)
            local childGO = GameObject.Instantiate(childGOTemplate,itemParentTrans)
            local numText = self:GetComp(childGO,"num/num","TMPLocalization")
            numText.text = str
            if v.icon then
                local iconImage = self:GetComp(childGO,"bg/icon","Image")
                self:SetSprite(iconImage,"UI_Common",v.icon)
            end
            childGO.gameObject:SetActive(true)
            playingCycleInstanceCount = playingCycleInstanceCount + 1
            local fb = self:GetGo(childGO,"flyFB")
            FeelUtil.PlayFeelCallback(fb,function()
                GameObject.Destroy(childGO)
                playingCycleInstanceCount = playingCycleInstanceCount - 1
                if playingCycleInstanceCount == 0 then
                    cycleInstanceRoot:SetActive(false)
                end
                if cb then
                    cb()
                    cb = nil
                end
            end,true)
        end
    end
end

---显示任务完成提示,因为没有Animation所以特殊处理了
function FlyIconsUIView:ShowTaskTip()

    local taskRoot = self:GetNodeFromPool("instace_Tip", self:GetGo("instace_Tip"))
    SoundEngine:PlaySFX("Assets/Res/Audio/SFX_reward.ogg")
    --自动播FB,自动关闭
end

---副本房间界面家具升级的里程碑积分奖励
function FlyIconsUIView:ShowCycleMilepost(index,flyPath,str,cb)
    local goRoot = self:GetNodeFromPool(flyPath, self:GetGo(flyPath))
    SoundEngine:PlaySFX("Assets/Res/Audio/SFX_reward.ogg")
    local rewardGO = self:GetGo(goRoot,"reward"..index)
    rewardGO:SetActive(true)
    local numText = self:GetComp(rewardGO,"num/num","TMPLocalization")
    numText.text = str

    local ani = self:GetComp(rewardGO, "", "Animation")
    local find, name = AnimationUtil.GetFirstClipName(ani)
    AnimationUtil.Play(ani, name, function()
        if cb then cb() end
        goRoot:SetActive(false)
        rewardGO:SetActive(false)
    end)
end

---房间升级，播放存钱罐动画
function FlyIconsUIView:ShowPiggyBankAnim(diamondCount, cb)
    if diamondCount > 0 then
        self:SetText("PiggybankFly/num/num", diamondCount)
    end

    self:GetGo("PiggybankFly/num/num"):SetActive(diamondCount > 0)
    local piggyBankNode = self:GetGo("PiggybankFly")
    piggyBankNode:SetActive(true)
    local ani = self:GetComp(piggyBankNode, "", "Animation")
    AnimationUtil.Play(ani, "Piggybank_Fly", function()
        piggyBankNode:SetActive(false)
        MainUI:RefreshPiggyBankBtn(true)
        if cb then
            cb()
        end
    end)
end

function FlyIconsUIView:ShowCEOSpendDiamondAnim(spendDia, oldNum, addKeys, cb)
    EventDispatcher:RegEvent("CLOSE_KEY", function(go)
        EventDispatcher:UnRegEvent("CLOSE_KEY")
        local rootGo = self:GetGoOrNil("ceo_key")
        if rootGo then
            rootGo:SetActive(false)
        end
        if cb then
            cb(addKeys)
        end
    end)
    local curResumeNum = spendDia + oldNum
    local keyDiamond = ConfigMgr.config_global.diamond_key_ratio[1]
    local keyAdds = ConfigMgr.config_global.diamond_key_ratio[2]
    local sliderValue = curResumeNum / keyDiamond
    if sliderValue > 1 then
        sliderValue = 1
    end
    local ceoPopupGo = self:GetGoOrNil("ceo_key")
    if ceoPopupGo then
        local slider = self:GetComp(ceoPopupGo, "bg/slider", "Slider")
        slider.value = sliderValue
        self:SetText(ceoPopupGo, "bg/slider/prog/cost", curResumeNum)
        self:SetText(ceoPopupGo, "bg/slider/prog/need", keyDiamond)
        ceoPopupGo:SetActive(true)
        ceoPopupGo.transform:SetAsLastSibling()
    end
    
end

--[[
    @desc: 获得钥匙的动画播放，是2个，一个飞钥匙，一个宝箱进度的
    author:{author}
    time:2025-02-21 15:26:13
    --@keysType:
	--@addKeys:
	--@cb: 
    @return:
]]
function FlyIconsUIView:ShowCEOAddKeyAnim(keysType, addKeys, isNeedFly, cbkeyFly, cbBox)
    if not self.CEOKeysAniDatas then
        self.CEOKeysAniDatas = {}
    end
    local item = {keysType, addKeys, isNeedFly, cbkeyFly, cbBox}
    table.insert(self.CEOKeysAniDatas, item)
    if Tools:GetTableSize(self.CEOKeysAniDatas) > 0 then
        local data = table.remove(self.CEOKeysAniDatas, 1)
        if data[3] then
            self:_ShowCEOAddKeyAnim(data)
        else
            self:_ShowCEOAddKeyAnimNotFly(data)
        end
    end
end

function FlyIconsUIView:_ShowCEOAddKeyAnim(data)
    local isFlyOver = false
    local isChestOver = false
    local delData = false
    local keyCfg = ConfigMgr.config_ceo_key[data[1]]
    local chestCfg = ConfigMgr.config_ceo_chest[data[1]]
    EventDispatcher:RegEvent("CLOSE_KEYFLY", function(go)
        if data[4] then
            data[4]()
        end
        isFlyOver = true
        self:GetGo("ceo_keyFly"):SetActive(false)
        if  isChestOver and not delData then
            delData = true
            if Tools:GetTableSize(self.CEOKeysAniDatas) > 0 then
                local havedata = table.remove(self.CEOKeysAniDatas, 1)
                if havedata[3] then
                    self:_ShowCEOAddKeyAnim(havedata)
                else
                    self:_ShowCEOAddKeyAnimNotFly(havedata)
                end
            end
        end
        EventDispatcher:UnRegEvent("CLOSE_KEYFLY")
    end)

    EventDispatcher:RegEvent("CLOSE_CHEST", function(go)
        if data[5] then
            data[5]()
        end
        isChestOver = true
        self:GetGo("ceo_chest"):SetActive(false)
        if isFlyOver and not delData then
            delData = true
            if Tools:GetTableSize(self.CEOKeysAniDatas) > 0 then
                local havedata = table.remove(self.CEOKeysAniDatas, 1)
                if havedata[3] then
                    self:_ShowCEOAddKeyAnim(havedata)
                else
                    self:_ShowCEOAddKeyAnimNotFly(havedata)
                end
            end
        end
        EventDispatcher:UnRegEvent("CLOSE_CHEST")
    end)
    local ceoChestGo = self:GetGo("ceo_chest")
    local ceoKeyGo = self:GetGo("ceo_keyFly")
    ceoChestGo:SetActive(true)
    ceoKeyGo:SetActive(true)
    ceoChestGo.transform:SetAsLastSibling()
    ceoKeyGo.transform:SetAsLastSibling()
    self:SetSprite(self:GetComp("ceo_keyFly/bg/icon", "Image"), "UI_Shop", keyCfg.key_icon)
    self:SetText("ceo_keyFly/bg/num", tostring(data[2]))
    self:SetSprite(self:GetComp("ceo_chest/bg/icons/key", "Image"), "UI_Shop", keyCfg.key_icon)
    local slider = self:GetComp("ceo_chest/bg/slider", "Slider")
    local curKeys = GameTableDefine.CEODataManager:GetCurKeys(data[1])
    local needKeyCfg = 0
    if "normal" == data[1] or "premium" == data[1] then
        local tmpStrs = Tools:SplitString(chestCfg.chest_key_require, ":")
        needKeyCfg = tonumber(tmpStrs[2])
    end 
    local curChestNum = 0
    local sliderValue = 0
    if needKeyCfg > 0 then
        sliderValue = curKeys / needKeyCfg
        curChestNum = math.floor(sliderValue)
        if sliderValue > 1 then
            sliderValue = 1
        end
    end
    slider.value = sliderValue
    self:SetText("ceo_chest/bg/slider/prog/have", tostring(curKeys));
    self:SetText("ceo_chest/bg/slider/prog/need", tostring(needKeyCfg))
    self:SetSprite(self:GetComp("ceo_chest/bg/slider/prog/key", "Image"), "UI_Shop", keyCfg.key_icon)
    self:SetSprite(self:GetComp("ceo_chest/bg/slider/reward/icon", "Image"), "UI_Shop", chestCfg.chest_icon)
    self:SetText("ceo_chest/bg/slider/reward/count/num", "x"..tostring(curChestNum))
end

function FlyIconsUIView:_ShowCEOAddKeyAnimNotFly(data)
    local isChestOver = false
    local delData = false
    local keyCfg = ConfigMgr.config_ceo_key[data[1]]
    local chestCfg = ConfigMgr.config_ceo_chest[data[1]]
    EventDispatcher:RegEvent("CLOSE_CHEST", function(go)
        if data[5] then
            data[5]()
        end
        isChestOver = true
        self:GetGo("ceo_chest"):SetActive(false)
        if not delData then
            delData = true
            if Tools:GetTableSize(self.CEOKeysAniDatas) > 0 then
                local havedata = table.remove(self.CEOKeysAniDatas, 1)
                if havedata[3] then
                    self:_ShowCEOAddKeyAnim(havedata)
                else
                    self:_ShowCEOAddKeyAnimNotFly(havedata)
                end
            end
        end
        EventDispatcher:UnRegEvent("CLOSE_CHEST")
    end)
    local ceoChestGo = self:GetGo("ceo_chest")
    ceoChestGo:SetActive(true)
    ceoChestGo.transform:SetAsLastSibling()
    self:SetSprite(self:GetComp("ceo_chest/bg/icons/key", "Image"), "UI_Shop", keyCfg.key_icon)
    local slider = self:GetComp("ceo_chest/bg/slider", "Slider")
    local curKeys = GameTableDefine.CEODataManager:GetCurKeys(data[1])
    local needKeyCfg = 0
    if "normal" == data[1] or "premium" == data[1] then
        local tmpStrs = Tools:SplitString(chestCfg.chest_key_require, ":")
        needKeyCfg = tonumber(tmpStrs[2])
    end 
    local curChestNum = 0
    local sliderValue = 0
    if needKeyCfg > 0 then
        sliderValue = curKeys / needKeyCfg
        curChestNum = math.floor(sliderValue)
        if sliderValue > 1 then
            sliderValue = 1
        end
    end
    slider.value = sliderValue
    self:SetText("ceo_chest/bg/slider/prog/have", tostring(curKeys));
    self:SetText("ceo_chest/bg/slider/prog/need", tostring(needKeyCfg))
    self:SetSprite(self:GetComp("ceo_chest/bg/slider/prog/key", "Image"), "UI_Shop", keyCfg.key_icon)
    self:SetSprite(self:GetComp("ceo_chest/bg/slider/reward/icon", "Image"), "UI_Shop", chestCfg.chest_icon)
    self:SetText("ceo_chest/bg/slider/reward/count/num", "x"..tostring(curChestNum))
end
---拉霸机，播放副本存钱罐动画
function FlyIconsUIView:ShowNightClubPiggyBankAnim(cb, diamondCount)
    if diamondCount > 0 then
        self:SetText("cy4_piggypack_slot_Fly/num/num", diamondCount)
    end

    self:GetGo("cy4_piggypack_slot_Fly/num/num"):SetActive(diamondCount > 0)
    local piggyBankSlotNode = self:GetGo("cy4_piggypack_slot_Fly")
    piggyBankSlotNode:SetActive(true)
    local ani = self:GetComp(piggyBankSlotNode, "", "Animation")
    AnimationUtil.Play(ani, "cy4_piggypack_slot_Fly_Anim", function()
        piggyBankSlotNode:SetActive(false)
        if cb then
            cb()
        end
    end)
end


function FlyIconsUIView:ShowClockOutPopupUIAnim(cb)
    local curRootGo = self:GetGo("clockoutGuideIcon")
    for i = 0, curRootGo.transform.childCount - 1 do
        curRootGo.transform:GetChild(i).gameObject:SetActive(false)
    end
    local theme = GameTableDefine.ClockOutDataManager:GetActivityTheme()
    local curDispGo = self:GetGoOrNil(curRootGo, theme)
    if curDispGo then
        curDispGo:SetActive(true)
    end
    curRootGo:SetActive(true)

    if cb then
        cb()
    end
end

function FlyIconsUIView:ShowClockOutTicketsGetAnim(num, cb)
    local curRootGo = self:GetGo("clockoutFlyIcon")
    for i = 0, curRootGo.transform.childCount - 1 do
        curRootGo.transform:GetChild(i).gameObject:SetActive(false)
    end
    local theme = GameTableDefine.ClockOutDataManager:GetActivityTheme()
    local curDispGo = self:GetGoOrNil(curRootGo, theme)
    if curDispGo then
        curDispGo:SetActive(true)

        self:SetText(curDispGo, "gain/num", num)
    end
    curRootGo:SetActive(true)
    if cb then
        cb()
    end
end

return FlyIconsUIView
