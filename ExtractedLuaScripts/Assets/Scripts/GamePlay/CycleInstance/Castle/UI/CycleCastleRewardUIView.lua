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

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleCastleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

---@class CycleCastleRewardUIView:UIBaseView
local CycleCastleRewardUIView = Class("CycleCastleRewardUIView", UIView)

function CycleCastleRewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.isShopUIRequire = false
end

function CycleCastleRewardUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        -- print("Close the CycleCastleRewardUIView")
        self:DestroyModeUIObject()

        if not self.isShopUIRequire then
            local state = CycleInstanceDataManager:GetInstanceState()
            if state == CycleInstanceDataManager.instanceState.isActive then
                if GameTableDefine.CycleCastleMilepostUI.m_view then
                    GameTableDefine.CycleCastleMilepostUI:Refresh(self.cacheIndex)
                end
            end
        end
    end)
    self.m_list = self:GetComp("RootPanel/milestonePanel/reward/list", "ScrollRectEx")
end

function CycleCastleRewardUIView:OnPause()
end

function CycleCastleRewardUIView:OnResume()
end

function CycleCastleRewardUIView:OnExit()
end

function CycleCastleRewardUIView:ShowGetReward(rewards,isShopUIRequires, scrollIndex)
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
                self:SetSprite(self:GetComp(go,"icon", "Image"), "UI_Common", "icon_cy2_skill_"..k)
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
    @desc:展示获取的所有未领取的奖励 
    author:{author}
    time:2024-07-02 15:00:54
    --@allRewards: 
    @return:
]]
function CycleCastleRewardUIView:ShowAllNotClaimRewardsGet(allRewards)
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

return CycleCastleRewardUIView
