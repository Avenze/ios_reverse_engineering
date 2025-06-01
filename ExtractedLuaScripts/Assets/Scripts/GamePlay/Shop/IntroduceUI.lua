---@class IntroduceUI
local IntroduceUI = GameTableDefine.IntroduceUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI
local EventManager = require("Framework.Event.Manager")
local UIPopManager = GameTableDefine.UIPopupManager

local INTRODUCE = "pop"
local shopId2Discound = nil

function IntroduceUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INTRODUCE_UI, self.m_view, require("GamePlay.Shop.IntroduceUIView"), self, self.CloseView)
    return self.m_view
end

function IntroduceUI:OpenView(cmd, shopId, cb, openType)
    local view = self:GetView()
    if cmd then
        view:Invoke(cmd,shopId, cb, openType)
    end
end

function IntroduceUI:IntroduceEachDay()--每天显示
    GameTableDefine.UIPopupManager:EnqueuePopView(self, function()
        local data = LocalDataManager:GetDataByKey(INTRODUCE)
        local now = TimerMgr:GetCurrentServerTime()
        if data["last"] == nil then
            data["last"] = now
            LocalDataManager:WriteToFile()
        end

        local today = os.date("%d", now)
        local last = os.date("%d", data["last"])

        if today ~= last then
            data["last"] = now
            LocalDataManager:WriteToFile()
            self:Introduce(nil, 1)
        else
            return
        end
    end, "IntroduceUI")

end

function IntroduceUI:IntroduceByIds(allId, cb, openType)--获取ID获取
    if not GameConfig:IsIAP() then
        return
    end
    
    local data = LocalDataManager:GetDataByKey(INTRODUCE)

    local canBuy
    local goalShopId
    for k,v in pairs(allId) do
        canBuy = ShopManager:EnableBuy(v)
        if canBuy and data[v .. ""] == nil then
            data[v..""] = true
            goalShopId = v
            LocalDataManager:WriteToFile()
            break
        end
    end

    if goalShopId then
        self:Open(goalShopId, cb, openType)
    else
        if cb then cb() end
    end
end

function IntroduceUI:IntroduceByShopId(shopId, cb, openType)
    if shopId then
        self:Open(shopId, cb, openType)
    end
end

function IntroduceUI:StarImprove()
    local allId = {1045, 1044, 1042, 1040, 1038, 1037, 1190, 1192, 1194}    
    self:IntroduceByIds(allId, nil, 2)
    MainUI:RefreshGrowPackageBtn()
    MainUI:RefreshNewPlayerPackage(true)
end

function IntroduceUI:SceneNeed(cb)
    local allId = {1041, 1046, 1094, 1191, 1193}
    self:IntroduceByIds(allId, nil, 2)
    MainUI:RefreshGrowPackageBtn()
    MainUI:RefreshNewPlayerPackage(true)
end

function IntroduceUI:ValueImprove(cb)
    local allId = {1043}
    self:IntroduceByIds(allId, cb, 2)
    MainUI:RefreshGrowPackageBtn()
    MainUI:RefreshNewPlayerPackage(true)
end

function IntroduceUI:Introduce(cb, openType)
    if not GameConfig.IsIAP() then
        return
    end

    local cfg = ConfigMgr.config_popup
    if not cfg then
        return
    end

    local allId = {}
    for k,v in pairs(cfg) do
        table.insert(allId, v)
    end

    table.sort(allId, function(a,b)
        return a.id < b.id
    end)

    local canBuy,goalShopId
    for k,v in pairs(allId) do
        canBuy = ShopManager:EnableBuy(v.shopId)
        if canBuy then
            if v.shopId == 1068 then
                if ShopManager:EnableBuy(1009) then
                    goalShopId = v.shopId
                    break
                end
            elseif v.shopId == 1037 then
                if ShopManager:EnableBuy(1189) then
                    goalShopId = v.shopId
                    break
                end
            elseif v.shopId == 1189 then
                if ShopManager:EnableBuy(1037) then
                    goalShopId = v.shopId
                    break;
                end
            elseif v.shopId == 1016 then
                GameTableDefine.MonthCardUI:OpenView()
                return
            else
                goalShopId = v.shopId
                break
            end            
        end
    end

    if goalShopId then
        self:Open(goalShopId, cb, openType)
    end
end

function IntroduceUI:Open(shopId, cb, openType)
    self:UnlockShopEffectTime(shopId)
    --self:GetView():Invoke("Introduce", shopId, cb, openType)
    self:OpenView("Introduce", shopId, cb, openType)

end

function IntroduceUI:CheckCanOpen()
    --return true -- todo 这里的条件待定
    return self:IsNewDay()
end

function IntroduceUI:IsNewDay()
    local data = LocalDataManager:GetDataByKey(INTRODUCE)
    local now = TimerMgr:GetCurrentServerTime()
    if data["last"] == nil then
        data["last"] = now
        LocalDataManager:WriteToFile()
    end

    local today = os.date("%d", now)
    local last = os.date("%d", data["last"])

    return today ~= last
end

--[[
    @desc:根据条件解锁对应的时效商品的时间 
    author:{author}
    time:2023-06-14 14:10:11
    @return:
]]
function IntroduceUI:UpdateTimeLockCondition()
    if not GameConfig.IsIAP() then
        return
    end

    local cfg = ConfigMgr.config_popup
    if not cfg then
        return
    end

    local allId = {}
    for k,v in pairs(cfg) do
        table.insert(allId, v)
    end

    table.sort(allId, function(a,b)
        return a.id < b.id
    end)

    local canBuy,goalShopId
    for k,v in pairs(allId) do
        canBuy = ShopManager:EnableBuy(v.shopId)
        if canBuy then
            self:UnlockShopEffectTime(v.shopId)
        end
    end
end

function IntroduceUI:GetDiscountByShopId(shopId)
    if shopId2Discound == nil then
        shopId2Discound = {}
        for k,v in pairs(ConfigMgr.config_popup) do
            shopId2Discound[v.shopId] = v.offvalue
        end
    end

    return shopId2Discound[shopId] or 0
end

function IntroduceUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INTRODUCE_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

--[[
    @desc: 返回商品对应的剩余有效购买时间
    author:{author}
    time:2023-06-09 15:19:24
    --@shopID: 
    @return:isTimeShop, leftTime  (是否是实效商品，剩余时间是多少-1就是还没解锁)
]]
function IntroduceUI:CheckShopIDEffectTime(shopID)
    local isTimeShop = false
    local leftTime = -1
    local packageTimeSave = LocalDataManager:GetDataByKey("GiftPackTimeData")
    if not packageTimeSave then
        return false, 0
    end
    local popupCfg = nil
    for i, v in pairs(ConfigMgr.config_popup) do
        if shopID == v.shopId then
            if v.timelimit == 1 then
                popupCfg = v
                break
            end
        end
    end
    if not popupCfg then
        return false, 0
    end
    if packageTimeSave[tostring(shopID)] then
        leftTime = popupCfg.duration - (GameTimeManager:GetCurServerOrLocalTime() - packageTimeSave[tostring(shopID)])
        if leftTime <= 0 then
            leftTime = 0
        end
        return true, math.floor(leftTime)
    else
        return true, -1
    end
end

--[[
    @desc: 解锁一个有时效性的商品的时效时间，如果是时效性商品的话
    author:{author}
    time:2023-06-09 15:29:17
    --@shopID: 
    @return:
]]
function IntroduceUI:UnlockShopEffectTime(shopID)
    local packageTimeSave = LocalDataManager:GetDataByKey("GiftPackTimeData")
    if not packageTimeSave then
        return
    end
    if packageTimeSave[tostring(shopID)] then
        return
    end
    local popupCfg = nil
    for i, v in pairs(ConfigMgr.config_popup) do
        if shopID == v.shopId then
            if v.timelimit == 1 then
                popupCfg = v
                break
            end
        end
    end
    if not popupCfg then
        return
    end
    local openTime = nil
    local timeGroup = popupCfg.timegroup
    if not packageTimeSave[tostring(shopID)] then
        openTime = GameTimeManager:GetCurServerOrLocalTime()
        packageTimeSave[tostring(shopID)] = openTime
        LocalDataManager:WriteToFile()
    end
    if timeGroup > 0 then
        --检测时间组相同的商品也同时开启计时了
        if openTime and openTime > 0 then
            local needSave = false
            for i, v in pairs(ConfigMgr.config_popup) do
                if timeGroup == v.timegroup and v.shopId ~= shopID then
                    needSave = true
                    if not packageTimeSave[tostring(v.shopId)] and openTime then
                        packageTimeSave[tostring(v.shopId)] = openTime
                    end
                end
            end
            if needSave then
                LocalDataManager:WriteToFile()
            end
        end
    end
    
end

function IntroduceUI:CanOpenNewPlayerPackage()
    local canBuy1037 = ShopManager:EnableBuy(1037)
    local canBuy1189 = ShopManager:EnableBuy(1189)
    return canBuy1037 and canBuy1189
end

--指定打开新手的弹窗礼包
function IntroduceUI:OpenNewPlayerPackage()
    if not self:CanOpenNewPlayerPackage() then
        return
    end
    self:Open(1037, nil, 2)
end

function IntroduceUI:OpenCurrentGrowPackage()
    local allGrowPackage = {1038,1039,1040,1041,1042,1043,1044,1045,1046,1094,1190,1191,1192,1193,1194}
    if Tools:GetTableSize(allGrowPackage) <= 0 then
        return
    end
    local useShopID = nil
    for index = Tools:GetTableSize(allGrowPackage), 1, -1 do
        useShopID = allGrowPackage[index]
        local canBuy = ShopManager:EnableBuy(useShopID)
        if canBuy then
            break
        end
    end
    if not useShopID then
        return
    end
    self:Open(useShopID, nil, 2)
end