---@class StarMode
local StarMode = GameTableDefine.StarMode
local MainUI = GameTableDefine.MainUI
local FloorMode = GameTableDefine.FloorMode
local CityMode = GameTableDefine.CityMode
local PiggyBankUI = GameTableDefine.PiggyBankUI
local IntroduceUI = GameTableDefine.IntroduceUI
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local LocalDataManager = LocalDataManager

local STAR_DATA = "star_data"
local StarFieldName = "num" ---存档中知名度存款名

local localData = nil
function StarMode:Init()
    print("Star Init")
    localData = LocalDataManager:GetDataByKey(STAR_DATA)

    local currStar = self:GetStar()
    local starMayBe = self:GetNearStar()
    print("currStar" .. currStar .. "starMayBe" .. starMayBe)

    -- local makeWrong = nil
    -- print(makeWrong / 8)

    if currStar + 20 < starMayBe then
        --localData["num"] = starMayBe
        LocalDataManager:EncryptField(localData,StarFieldName,starMayBe)
        LocalDataManager:WriteToFile()
    end

end

function StarMode:GetStar()
    if not localData then
        localData = LocalDataManager:GetDataByKey(STAR_DATA)
        --localData["num"] = 0
    end

    return LocalDataManager:DecryptField(localData,StarFieldName)
    --return localData["num"] or 0
end

function StarMode:GetMax()--好像现在没有上限了吧,只是一个数字
    return 9999
end

function StarMode:GetNearStar()
    local starMayBe = 0

    local valueAdd = 0
    local rankData = LocalDataManager:GetDataByKey("bank")
    local max = rankData["max"] or nil
    if max ~= nil then
        local allReward = nil
        local cfg = ConfigMgr.config_wealthrank
        local last = #cfg
        valueAdd = last - max + 1
    end

    local companyAdd = 0
    local allCompany = LocalDataManager:GetDataByKey("company_invite_save")
    local allLv = allCompany["companyLv"] or {}
    for k,v in pairs(allLv) do
        companyAdd = companyAdd + v - 1
    end

    local roomAdd = 0
    local roomProgress = LocalDataManager:GetDataByKey("room_progress")
    for k,v in pairs(roomProgress or {}) do
        roomAdd = roomAdd + v - 1
    end

    starMayBe = valueAdd + companyAdd + roomAdd
    return starMayBe
end

function StarMode:StarRaise(starNum, refreshLater, cb, refershPiggyBank)
    local currStar = self:GetStar()
    local lastStar = currStar
    if not starNum then
        starNum = 1
    end
    
    currStar = currStar + starNum
    --需要新增3个adjust的新事件打点,分别在玩家的知名度达到18,40,50,84的时候上报
    local checkList = {1,5,10,18,25,30,35,40,50,70,84,100,120,164,200}
    for i=1,#checkList do
        if currStar >= checkList[i] and lastStar < checkList[i] then
            local name = "adjust_star_".. checkList[i]
            GameSDKs:TrackControl("af", "af,"..name, {af_buildingID = 0})
        end      
    end
    -- local newAFCondition = {18, 25, 35}
    -- for i=1,#newAFCondition do
    --     if currStar == newAFCondition[i] then
    --         if GameTableDefine.CityMode:CheckBuildingSatisfy(200) then
    --             local eventName = "scene_second_star_"..newAFCondition[i]
    --             GameSDKs:TrackControl("af", "af,"..eventName, {af_buildingID = 0})
    --         end
    --     end      
    -- end

    if currStar > self:GetMax() then
        currStar = self:GetMax()
    end
    --增加用户属性2024-8-20
    GameSDKs:SetUserAttrToWarrior({ob_reputaion_level = currStar})
    --localData["num"] = currStar
    LocalDataManager:EncryptField(localData,StarFieldName,currStar)

    LocalDataManager:WriteToFileInmmediately()
    MainUI:RefreshQuestHint()
    if not refreshLater then
        MainUI:RefreshStarState()
    end
    --添加一个商品的时效开启检测，现在这个是做在弹出礼包里面的，因为弹出礼包先做了，然后这个又是和弹出礼包强耦合的
    IntroduceUI:UpdateTimeLockCondition()
    FloorMode:GetScene():CheckRoomsStarEnough()
     --工厂新手引导
    FloorMode:GetScene():CheckIfNeededFactoryGuide()
    MainUI:SetPhoneNum()
    CityMode:InitDistricts(true)
    MainUI:RefreshDiamondFund()--增加时刷新一下基金的红点  
    MainUI:RefreshGrowPackageBtn()--增加时刷新成长基金按钮的状态
    MainUI:RefreshNewPlayerPackage(true) --增加刷新新手礼包按钮的检测
    if not refershPiggyBank then
        MainUI:RefreshPiggyBankBtn()--增加时刷新存钱罐
    end

    FloorMode:GetScene():RefreshRoulette()--增加时刷新场景中转盘的物体
    MainUI:GetView():GetGo("WheelBtn"):SetActive(ConfigMgr.config_global.wheel_switch == 1 and self:GetStar() >= ConfigMgr.config_global.wheel_condition and FloorMode:CheckWheelGo())

    -- 玩家在游戏过程中知名度升到了18，问卷图标需要主动显示出来
    if currStar >= 18 and lastStar < 18 then
        GameTableDefine.QuestionSurveyDataManager:Init(currStar)
        EventManager:DispatchEvent(GameEventDefine.OnBuyBuilding)
    end

    --2025-02-07 wy 升星，活动条件检查
    GameTableDefine.ActivityRemoteConfigManager:CheckActivityCondition()
    
    if cb then cb() end
    
    -- GameSDKs:Track("star_rating", {level = currStar})
    GameSDKs:TrackForeign("levelup", {level_new = tonumber(currStar) or 0})
end