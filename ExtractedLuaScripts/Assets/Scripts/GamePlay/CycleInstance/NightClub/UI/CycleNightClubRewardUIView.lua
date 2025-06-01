--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-01 12:18:42
]]
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
local ResMgr = GameTableDefine.ResourceManager
local GuideManager = GameTableDefine.GuideManager
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleNightClubModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

---@class CycleNightClubRewardUIView:UIBaseView
local CycleNightClubRewardUIView = Class("CycleNightClubRewardUIView", UIView)

function CycleNightClubRewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.isShopUIRequire = false
end

function CycleNightClubRewardUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        -- print("Close the CycleNightClubRewardUIView")
        self:DestroyModeUIObject()

        if not self.isShopUIRequire then
            local state = CycleInstanceDataManager:GetInstanceState()
            if state == CycleInstanceDataManager.instanceState.isActive then
                if GameTableDefine.CycleNightClubMilepostUI.m_view then
                    GameTableDefine.CycleNightClubMilepostUI:Refresh(self.cacheIndex)
                end
            end
        end

        --是否开启过引导
        if not CycleNightClubModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.DrawMilestone) then
            GuideManager.currStep = CycleInstanceDefine.GuideDefine.NightClub.DrawMilestone
            GuideManager:ConditionToStart()
            CycleNightClubModel:SetGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.DrawMilestone)
        end
    end)
    self.m_list = self:GetComp("RootPanel/milestonePanel/reward/list", "ScrollRectEx")
    UnityHelper.SetSpriteNull(self:GetTrans("background/MediumPanel/list/item/icon"))
end

function CycleNightClubRewardUIView:OnPause()
end

function CycleNightClubRewardUIView:OnResume()
end

function CycleNightClubRewardUIView:OnExit()
end

function CycleNightClubRewardUIView:ShowGetReward(rewards,isShopUIRequires, scrollIndex)
    self.isShopUIRequire = isShopUIRequires
    self.cacheIndex = scrollIndex
    if not rewards or not next(rewards) then
        self:DestroyModeUIObject()
        return
    end
    -- rewards.level = level
    -- rewards.shop_id = v.shop_id
    -- rewards.count = v.count
    local shopCfg = ConfigMgr.config_shop[rewards.shop_id]
    if shopCfg.type == 4 and GameTableDefine.ShopManager:IsNoAD() then
        rewards.shop_id = 1333
        rewards.count = shopCfg.amount * rewards.count * (tonumber(shopCfg.param[1]) or 0)
        shopCfg = ConfigMgr.config_shop[1333]
    end
    if not shopCfg then
        self:DestroyModeUIObject()
        return
    end
    local totalCount = rewards.count
    local iconUse = shopCfg.icon
    --TODO:需要根据商店配置奖励的类型进行数量转换,比如绿钞，钻石等等
    if shopCfg.type == 9 then
        --当前场景的小时数量的现金
        local resType = GameTableDefine.ResourceManger:GetShopCashType(shopCfg.country)
        local cashType = 2
        local tmpTotalCount = shopCfg.amount * rewards.count * 3600 / 30
        totalCount = math.ceil(GameTableDefine.FloorMode:GetTotalRent() * tmpTotalCount)
        if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
            totalCount = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * tmpTotalCount
            iconUse = shopCfg.icon.."_euro"
            cashType = 6
        end   
    end
    if shopCfg.type == 27 then
        --商店购买技能书
        local skillInfos = rewards.param
        local prefabParentTrans = self:GetTrans("background/MediumPanel/list")
        local prefabGO = self:GetGo("background/MediumPanel/list/item")
        for k,v in pairs(skillInfos) do
            if v>0 then
                local go = GameObject.Instantiate(prefabGO,prefabParentTrans)
                local skillConf = CycleInstanceDataManager:GetCurrentModel().config_cy_instance_skill[k][0].skill_icon
                self:SetSprite(self:GetComp(go,"icon", "Image"), "UI_Common", skillConf)

                self:SetText(go,"bg/num", "+".. tostring(v))
            end
        end
        prefabGO:SetActive(false)
    else
        self:SetSprite(self:GetComp("background/MediumPanel/list/item/icon", "Image"), "UI_Shop", iconUse)
        local numStr = shopCfg.type == 26 and BigNumber:FormatBigNumber(totalCount) or tostring(Tools:SeparateNumberWithComma(totalCount))
        self:SetText("background/MediumPanel/list/item/bg/num", "+".. numStr)
    end
end


--[[
    @desc: 单独的CEO卡牌获取最后的ui显示
    author:{author}
    time:2025-03-03 16:36:56
    --@rewards:{1, {coeid, isDiamond, num}, 2, {ceoid, isDiamond, num}}
	--@isShopUIRequires:
	--@scrollIndex:
    @return:
]]
function CycleNightClubRewardUIView:ShowCEOCardsGet(rewards,isShopUIRequires, scrollIndex)
    self.isShopUIRequire = isShopUIRequires
    self.cacheIndex = scrollIndex
    if not rewards or not next(rewards) then
        self:DestroyModeUIObject()
        return
    end
    -- rewards.level = level
    -- rewards.shop_id = v.shop_id
    -- rewards.count = v.count
    local shopCfg = ConfigMgr.config_shop[rewards.shop_id]
    if not shopCfg then
        self:DestroyModeUIObject()
        return
    end
    local dispItemNum = 0
    local dispceoIds = {}
    if rewards.diamonds then
        dispItemNum  = dispItemNum + 1
    end
    for ceoid, value in pairs(rewards.ceoids) do
        local item = {}
        local ceoCfg = ConfigMgr.config_ceo[ceoid]
        if ceoCfg then
            item.icon = ceoCfg.ceo_card
            item.num = value
            table.insert(dispceoIds, item)
            dispItemNum  = dispItemNum + 1
        end
    end
    local itemGo = self:GetGoOrNil("background/MediumPanel/list/item")
    if itemGo then
        local curChildCount = itemGo.transform.parent.childCount
        for i = 1, curChildCount do
            local item_child = itemGo.transform.parent:GetChild(i - 1).gameObject
            if item_child.name ~= "openFB" then
                item_child:SetActive(false)
            end
        end
        for i = 1, dispItemNum do
            local dispGo
            if i < curChildCount then
                dispGo = itemGo.transform.parent:GetChild(i-1).gameObject
            else
                dispGo = GameObject.Instantiate(itemGo, itemGo.transform.parent)
            end
            local icon = ""
            local num = 0
            if dispceoIds[i] then
                num = dispceoIds[i].num
                icon = dispceoIds[i].icon
            else
                num = rewards.diamonds
                icon = "icon_cy2_diamond"
            end
            if dispGo then
                dispGo:SetActive(true)
                self:SetSprite(self:GetComp(dispGo, "icon", "Image"), "UI_Common", icon)
                local numStr = shopCfg.type == 26 and BigNumber:FormatBigNumber(num) or tostring(Tools:SeparateNumberWithComma(num))
                self:SetText(dispGo, "bg/num", "+".. numStr)
            end
        end
    end
    -- self:SetSprite(self:GetComp("background/MediumPanel/list/item/icon", "Image"), "UI_Shop", iconUse)
    -- local numStr = shopCfg.type == 26 and BigNumber:FormatBigNumber(totalCount) or tostring(Tools:SeparateNumberWithComma(totalCount))
    -- self:SetText("background/MediumPanel/list/item/bg/num", "+".. numStr)
end

--[[
    @desc:展示获取的所有未领取的奖励 
    author:{author}
    time:2024-07-02 15:00:54
    --@allRewards: 
    @return:
]]
function CycleNightClubRewardUIView:ShowAllNotClaimRewardsGet(allRewards)
    --{{level = 1, shop_id = 1, count = 1}}
    --step.1需要整合同样商品的id的数量
    local tmpShopItemRewards = {}
    local tmpSameTypeRes = {}
    for k, v in pairs(allRewards) do
        local shopCfg = ConfigMgr.config_shop[v.shop_id]
        if shopCfg then
            if shopCfg.type == 9 then
                local resType = GameTableDefine.ResourceManger:GetShopCashType(shopCfg.country)
                local cashType = 2
                local tmpTotalCount = shopCfg.amount * v.count * 3600 / 30
                local currentCoutry = GameTableDefine.CountryMode:GetCurrCountry()
                local realAddCash = 0
                local iconUse = shopCfg.icon
                realAddCash = math.ceil(GameTableDefine.FloorMode:GetTotalRent() * tmpTotalCount)
                if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                    realAddCash = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * tmpTotalCount
                    iconUse = shopCfg.icon.."_euro"
                    cashType = 6
                    currentCoutry = 2
                end
            --    --小时现金，需要区分绿钞和欧元1-绿钞，2-欧元
            --    local currentCoutry = GameTableDefine.CountryMode:GetCurrCountry()
            --    local realAddCash = 0
            --    local iconUse = shopCfg.icon
            --    if shopCfg.country ~= 0 then
            --        if shopCfg.country == 1 then
            --            realAddCash = (shopCfg.amount * v.count * 3600 / 30 ) * GameTableDefine.FloorMode:GetTotalRent()
            --        elseif shopCfg.country == 2 then
            --            realAddCash = (shopCfg.amount * v.count * 3600 / 30 ) * GameTableDefine.FloorMode:GetTotalRent(nil, 2)
            --            iconUse = iconUse.."_euro"
            --        end
            --        currentCoutry = shopCfg.country
            --    else
            --        if currentCoutry == 1 then
            --            realAddCash = (shopCfg.amount * v.count * 3600 / 30 ) * GameTableDefine.FloorMode:GetTotalRent()
            --        elseif currentCoutry == 2 then
            --            realAddCash = (shopCfg.amount * v.count * 3600 / 30 ) * GameTableDefine.FloorMode:GetTotalRent(nil, 2)
            --            iconUse = iconUse.."_euro"
            --        end
            --    end
                if not tmpSameTypeRes[currentCoutry] then
                    tmpSameTypeRes[currentCoutry] = {}
                    tmpSameTypeRes[currentCoutry].totalCount = realAddCash
                    tmpSameTypeRes[currentCoutry].icon = iconUse
                else
                    tmpSameTypeRes[currentCoutry].totalCount = tmpSameTypeRes[currentCoutry].totalCount + realAddCash
                end
            else
                --要判断一下免广告购买了的话，广告卷要换成钻石
                if shopCfg.type == 4 and GameTableDefine.ShopManager:IsNoAD() then
                    local amount = shopCfg.amount * v.count * (tonumber(shopCfg.param[1]) or 0)
                    if not tmpShopItemRewards[1333] then
                        tmpShopItemRewards[1333] = {}
                        tmpShopItemRewards[1333].count = amount
                        local insDiaShopCfg = ConfigMgr.config_shop[1333]
                        tmpShopItemRewards[1333].icon = insDiaShopCfg.icon
                    else
                        tmpShopItemRewards[1333].count  = tmpShopItemRewards[1333].count + amount
                    end
                else
                    if not tmpShopItemRewards[v.shop_id] then
                        tmpShopItemRewards[v.shop_id] = {}
                        tmpShopItemRewards[v.shop_id].count = v.count
                        tmpShopItemRewards[v.shop_id].icon = shopCfg.icon
                    else
                        tmpShopItemRewards[v.shop_id].count  = tmpShopItemRewards[v.shop_id].count + v.count
                    end
                end
            end
        end
        
    end
    local displayResData = {}
    for k, v in pairs(tmpSameTypeRes) do
        local cur = {}
        local tmpCash = math.ceil(v.totalCount)
        cur.TotalAmount = tmpCash
        cur.icon = v.icon
        table.insert(displayResData, cur)
    end
    for k, v in pairs(tmpShopItemRewards) do
        local cur = {}
        cur.TotalAmount = v.count
        cur.icon = v.icon
        table.insert(displayResData, cur)
    end
    --进行显示了
    local goCounter = 1
    local itemGo = self:GetGoOrNil("background/MediumPanel/list/item")
    local parentGo = self:GetGoOrNil("background/MediumPanel/list")
    for k, v in pairs(displayResData) do
        if goCounter == 1 then
            self:SetSprite(self:GetComp(itemGo, "icon", "Image"), "UI_Shop", v.icon)
            self:SetText(itemGo, "bg/num", "+".. tostring(Tools:SeparateNumberWithComma(v.TotalAmount)))
        else
            local tmpGo = UnityHelper.CopyGameByGo(itemGo, parentGo)
            self:SetSprite(self:GetComp(tmpGo, "icon", "Image"), "UI_Shop", v.icon)
            self:SetText(tmpGo, "bg/num", "+".. tostring(Tools:SeparateNumberWithComma(v.TotalAmount)))
        end
        goCounter  = goCounter + 1
    end
end

function CycleNightClubRewardUIView:ShowAllNotClaimRewardsGetHaveCeoReward(allRewards, extendDiamond, ceoCards, normalKeys, premiumKeys)
    --step.1需要整合同样商品的id的数量
    local tmpShopItemRewards = {}
    local tmpSameTypeRes = {}
    for k, v in pairs(allRewards) do
        local shopCfg = ConfigMgr.config_shop[v.shop_id]
        if shopCfg then
            if shopCfg.type == 9 then
                local resType = GameTableDefine.ResourceManger:GetShopCashType(shopCfg.country)
                local cashType = 2
                local tmpTotalCount = shopCfg.amount * v.count * 3600 / 30
                local currentCoutry = GameTableDefine.CountryMode:GetCurrCountry()
                local realAddCash = 0
                local iconUse = shopCfg.icon
                realAddCash = math.ceil(GameTableDefine.FloorMode:GetTotalRent() * tmpTotalCount)
                if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                    realAddCash = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * tmpTotalCount
                    iconUse = shopCfg.icon.."_euro"
                    cashType = 6
                    currentCoutry = 2
                end
                if not tmpSameTypeRes[currentCoutry] then
                    tmpSameTypeRes[currentCoutry] = {}
                    tmpSameTypeRes[currentCoutry].totalCount = realAddCash
                    tmpSameTypeRes[currentCoutry].icon = iconUse
                else
                    tmpSameTypeRes[currentCoutry].totalCount = tmpSameTypeRes[currentCoutry].totalCount + realAddCash
                end
            else
                --要判断一下免广告购买了的话，广告卷要换成钻石
                if shopCfg.type == 4 and GameTableDefine.ShopManager:IsNoAD() then
                    local amount = shopCfg.amount * v.count * (tonumber(shopCfg.param[1]) or 0)
                    if not tmpShopItemRewards[1333] then
                        tmpShopItemRewards[1333] = {}
                        tmpShopItemRewards[1333].count = amount
                        local insDiaShopCfg = ConfigMgr.config_shop[1333]
                        tmpShopItemRewards[1333].icon = insDiaShopCfg.icon
                    else
                        tmpShopItemRewards[1333].count  = tmpShopItemRewards[1333].count + amount
                    end
                else
                    if not tmpShopItemRewards[v.shop_id] then
                        tmpShopItemRewards[v.shop_id] = {}
                        tmpShopItemRewards[v.shop_id].count = v.count
                        tmpShopItemRewards[v.shop_id].icon = shopCfg.icon
                    else
                        tmpShopItemRewards[v.shop_id].count  = tmpShopItemRewards[v.shop_id].count + v.count
                    end
                end
            end
        end

    end
    local displayResData = {}
    for k, v in pairs(tmpSameTypeRes) do
        local cur = {}
        local tmpCash = math.ceil(v.totalCount)
        cur.TotalAmount = tmpCash
        cur.icon = v.icon
        table.insert(displayResData, cur)
    end
    for k, v in pairs(tmpShopItemRewards) do
        local cur = {}
        cur.TotalAmount = v.count
        if k == 1333 then
            cur.TotalAmount  = cur.TotalAmount + extendDiamond
        end
        cur.icon = v.icon
        table.insert(displayResData, cur)
    end
    if not tmpShopItemRewards[1333] and extendDiamond > 0 then
        local diamondShopCfg = ConfigMgr.config_shop[1333]
        if diamondShopCfg then
            local cur = {}
            cur.TotalAmount = extendDiamond
            cur.icon = diamondShopCfg.icon
            table.insert(displayResData, cur)
        end
    end
    if normalKeys > 0 then
        local keyCfg = ConfigMgr.config_ceo_key["normal"]
        if keyCfg then
            local cur = {}
            cur.TotalAmount = normalKeys
            cur.icon = keyCfg.key_icon
            table.insert(displayResData, cur)
        end
    end
    if premiumKeys > 0 then
        local keyCfg = ConfigMgr.config_ceo_key["premium"]
        if keyCfg then
            local cur = {}
            cur.TotalAmount = premiumKeys
            cur.icon = keyCfg.key_icon
            table.insert(displayResData, cur)
        end
    end
    if Tools:GetTableSize(ceoCards) > 0 then
        for ceoid, num in pairs(ceoCards) do
            local ceoCfg = ConfigMgr.config_ceo[ceoid]
            if ceoCfg then
                local cur = {}
                cur.TotalAmount = num
                cur.icon = ceoCfg.ceo_card
                cur.altas = "UI_Common"
                table.insert(displayResData, cur)
            end
        end
    end
    --进行显示了
    local goCounter = 1
    local itemGo = self:GetGoOrNil("background/MediumPanel/list/item")
    local parentGo = self:GetGoOrNil("background/MediumPanel/list")
    for k, v in pairs(displayResData) do
        local atlas = v.altas or "UI_Shop"
        if goCounter == 1 then
            self:SetSprite(self:GetComp(itemGo, "icon", "Image"), atlas, v.icon)
            self:SetText(itemGo, "bg/num", "+".. tostring(Tools:SeparateNumberWithComma(v.TotalAmount)))
        else
            local tmpGo = UnityHelper.CopyGameByGo(itemGo, parentGo)
            self:SetSprite(self:GetComp(tmpGo, "icon", "Image"), atlas, v.icon)
            self:SetText(tmpGo, "bg/num", "+".. tostring(Tools:SeparateNumberWithComma(v.TotalAmount)))
        end
        goCounter  = goCounter + 1
    end
end

return CycleNightClubRewardUIView
