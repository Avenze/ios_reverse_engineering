---@class CityMode
local CityMode = GameTableDefine.CityMode
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI
local CityMapUI = GameTableDefine.CityMapUI
local BossChooseUI = GameTableDefine.BossChooseUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local BenameUI = GameTableDefine.BenameUI
local StarMode = GameTableDefine.StarMode
local ChatEventManager = GameTableDefine.ChatEventManager
local TalkUI = GameTableDefine.TalkUI
local SoundEngine = GameTableDefine.SoundEngine
local CountryMode = GameTableDefine.CountryMode
local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local LocalDataManager = LocalDataManager
local StoryLineManager = GameTableDefine.StoryLineManager
local HouseMode = GameTableDefine.HouseMode

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local Class = require("Framework.Lua.Class")
local EventManager = require("Framework.Event.Manager")
local Building = require("GamePlay.Buildings.Buildings")

local buildingsClass = {}

local CITY_FIRST_COME = "city_first_come"

local BUILDING_STATE_NORMAL     = 0
local BUILDING_STATE_UNLOCKING  = 1
local BUILDING_STATE_COMPLETE   = 2

function CityMode:Init()
    -- Execute:Async(
    --     {
    --         function()
    --             GameUIManager:SetFloatUILockScale(true, 18)
    --         end
    --     }
    -- )
    if LocalDataManager:IsNewPlayerRecord() then
        self:ShowOpeningScene()
        return true
    end

    self.localCityData = LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    self:InitDistricts()
    self:InitBuildings()
    FlyIconsUI:SetScenceSwitchEffect(-1)
end

function CityMode:Update(dt)
end

function CityMode:OnExit()
    for k, v in pairs(buildingsClass or {}) do
        v:Destroy()
    end
    buildingsClass = {}
    self.localCityData = nil
end


function CityMode:ShowOpeningScene()
    EventManager:RegEvent("CMD_OPENING_SCENE_CHOOSE_ACTOR", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 1, keyframe = "CMD_OPENING_SCENE_CHOOSE_ACTOR"})
        -- GameSDKs:Track("start_timeline", {state = "success"})
        self:PauseOpeningScene()
        BossChooseUI:ShowChooseBossSkinPanel()
    end)
    -- EventManager:RegEvent("CMD_OPENING_SCENE_DIALOG", function(go, args)
    --     self.m_dialogId = tonumber(args[1])
    --     self:PauseOpeningScene()
    --     self:CheckOpeningSceneDialog(0)
    -- end)

    EventManager:RegEvent("START_TALK", function(go, args)
        GameSDKs:TrackForeign("opening_timeline", {type = 1, keyframe = "START_TALK", extend_param = tostring(args[1])})
        local vp = Tools:FindObjectInAllScenes(typeof(CS.UnityEngine.Video.VideoPlayer))
        printf("VP Clip:", vp.clip)
        TalkUI:OpenTalk("cutscene" .. tonumber(args[1]), {bossName = LocalDataManager:GetBossName()}, function()
            GameUIManager:SetEnableTouch(false)
            CityMode:ResumeOpeningScene()
        end, function()
            CityMode:PauseOpeningScene()
            GameUIManager:SetEnableTouch(true)
        end)
    end)

    EventManager:RegEvent("CMD_OPENING_SCENE_NAME", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 1, keyframe = "CMD_OPENING_SCENE_NAME"})
        self:PauseOpeningScene()
        -- GameSDKs:TrackForeign("init", {init_id = 9, init_desc = "弹出命名界面"})
        BenameUI:GetView()
    end)

    EventManager:RegEvent("CMD_OPENING_SCENE_END", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 1, keyframe = "CMD_OPENING_SCENE_END"})
        LocalDataManager:ClearNewPlayerRecord(ConfigMgr.config_global.boss_skin[self.m_currSkin or 1])
        -- FlyIconsUI:SetScenceSwitchEffect(1, function()
        --     MainUI:GetView()
        --     self:Init()
        -- end)
        -- GameSDKs:Track("end_timeline", {state = "success"})
        GameSDKs:TrackForeign("init", {init_id = 10, init_desc = "命名完成"})

        GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(1, function()
            self:EnterDefaultBuiding()
        end)
        --GuideManager:SetTimeLineDialogCompleteHander(nil)
    end)

    EventManager:RegEvent("EVENT_OPENIING1", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 1, keyframe = "EVENT_OPENIING1"})
    end)
    self.m_skins = {}
    for i,v in ipairs(ConfigMgr.config_global.boss_skin or {}) do
        self.m_skins[v] = GameObject.Find("OpeningTimeline/Boss/"..v).gameObject
        self.m_skins[v]:SetActive(i == 1)
    end
    -- GuideManager:SetTimeLineDialogCompleteHander(function(v)
    --     self:CheckOpeningSceneDialog(v)
    -- end)
end

-- function CityMode:CheckOpeningSceneDialog(v)
--     if not self.m_dialogId then
--         return
--     end
--     self.m_dialogId =  self.m_dialogId + v
--     if ConfigMgr.config_guide[self.m_dialogId] then
--         GuideUI:Show(ConfigMgr.config_guide[self.m_dialogId])
--     else
--         GuideUI:CloseView()
--         CityMode:ResumeOpeningScene()
--     end
-- end

function CityMode:ChangeBossSkin(last, curr)
    self.m_currSkin = curr
    self.m_skins[ConfigMgr.config_global.boss_skin[last]]:SetActive(false)
    self.m_skins[ConfigMgr.config_global.boss_skin[curr]]:SetActive(true)
end

function CityMode:BenameFinish(name)
    LocalDataManager:SaveBossName(name)

    local currBuilding = self:GetCurrentBuilding()
    if currBuilding and currBuilding > 100 then
        return
    end
    
    CityMode:ResumeOpeningScene()
end

function CityMode:PauseOpeningScene()
    -- if not self.m_playableDirector then
    --     self.m_playableDirector = GameObject.Find("OpeningTimeline").gameObject:GetComponent("PlayableDirector")
    -- end
    -- UnityHelper.PauseTimeLine(self.m_playableDirector)
    -- self.m_playableDirector:Pause()
end
function CityMode:ResumeOpeningScene()
    local playableDirector = GameObject.Find("OpeningTimeline").gameObject:GetComponent("PlayableDirector")
    UnityHelper.PlayTimeLine(playableDirector)
    playableDirector:Play()
end

function CityMode:InitDistricts(isRefreshData)
    self.m_districtData = {}
    local districtData = self:GetDistrictLocalData()
    local districtCfg = self:GetCurrDistrictCfg()
    local currStar = StarMode:GetStar()
    local leaveBtnHintNum = 0
    -- for i,v in pairs(districtCfg or {}) do
    --     if not districtData.currId and v.star_need == 0 
    --         or (districtData.currId == v.id and districtData.currId == districtData.unlockingId and districtData.currId ~= districtCfg[#districtCfg].id) 
    --     then
    --         districtData.currId = v.id
    --         districtData.unlockingId = districtCfg[i + 1].id 
    --     end
    --     if not self.m_districtData[v.id] then
    --         self.m_districtData[v.id] = {}
    --     end
    --     self.m_districtData[v.id].name = v.go_name
    --     self.m_districtData[v.id].star_need = v.star_need
    --     self.m_districtData[v.id].id = v.id
    --     self.m_districtData[v.id].index = i
    --     if v.id <= districtData.currId then
    --         self.m_districtData[v.id].state = 1 --  1 解锁
    --     elseif v.id == districtData.unlockingId then
    --         self.m_districtData[v.id].state = districtData.unlockingTime or 2 -- 等待解锁
    --         if v.star_need <= currStar then
    --             leaveBtnHintNum = leaveBtnHintNum + 1
    --         end
    --     else
    --         self.m_districtData[v.id].state = 0 -- 0 未解锁
    --         if v.star_need <= currStar then
    --             leaveBtnHintNum = leaveBtnHintNum + 1
    --         end
    --     end
    -- end
    for i,v in pairs(districtCfg or {}) do
        if not districtData.currId then
            if v.star_need == 0 then --默认解锁 
                districtData.currId = v.id
                districtData.unlockingId = districtCfg[i + 1].id
            else --默认不解锁
                districtData.currId = nil
                districtData.unlockingId = v.id
            end
        elseif districtData.currId == v.id and districtData.currId == districtData.unlockingId and districtData.currId ~= self:GetCurrMaxId() then
            districtData.currId = v.id
            districtData.unlockingId = districtCfg[i + 1].id        
        end
        if not self.m_districtData[v.id] then
            self.m_districtData[v.id] = {}
        end
        self.m_districtData[v.id].name = v.go_name
        self.m_districtData[v.id].star_need = v.star_need
        self.m_districtData[v.id].id = v.id
        self.m_districtData[v.id].index = i
        
        if districtData.currId and v.id <= districtData.currId then
            self.m_districtData[v.id].state = 1 --  1 解锁
        elseif districtData.unlockingId and v.id == districtData.unlockingId then
            self.m_districtData[v.id].state = districtData.unlockingTime or 2 -- 等待解锁
            if v.star_need <= currStar then
                leaveBtnHintNum = leaveBtnHintNum + 1
            end
        else
            self.m_districtData[v.id].state = 0 -- 0 未解锁
            if v.star_need <= currStar then
                leaveBtnHintNum = leaveBtnHintNum + 1
            end
        end        
    end
    if not isRefreshData then
        CityMapUI:SetDistrictData(self.m_districtData)
    else
        MainUI:SetCityHintNum(leaveBtnHintNum)
    end
end
--获取当前国家的地区数据
function CityMode:GetCurrDistrictCfg()
    local currCountry = CountryMode:GetCurrCountry()
    local currDistrictCfg = {}
    for i,v in ipairs(ConfigMgr.config_district or {}) do
        if v.country == currCountry then
            currDistrictCfg[i] = v 
        end
    end
    return currDistrictCfg    
end
--获取当前国家的最大的那个id
function CityMode:GetCurrMaxId()
    local districtCfg = self:GetCurrDistrictCfg() 
    local maxId = 0
    local maxNum = 0
    for k,v in pairs(districtCfg) do
        if v.id > maxId then
            maxId = v.id
            maxNum = k
        end
    end
    return maxId , maxNum
end
--获取当前国家的最小的那个id
function CityMode:GetCurrMinId()
    local districtCfg = self:GetCurrDistrictCfg() 
    local minId = 0
    for k,v in pairs(districtCfg) do
        if v.id < minId or minId == 0 then
            minId = v.id
        end
    end
    return minId
end
--获取当前国家的建筑数数据
function CityMode:GetCurrbuildingCfg()
    local currCountry = CountryMode:GetCurrCountry()
    local currBuildingCfg = {}
    for i,v in pairs(ConfigMgr.config_buildings or {}) do 
        if v.country == currCountry then
            currBuildingCfg[i] = v 
        end
    end
    return currBuildingCfg
end 
function CityMode:UnlockingDistrict(id)
    local districtData = self:GetDistrictLocalData()
    local districtCfg = self:GetCurrDistrictCfg()[id]
    if districtCfg then
        districtData.unlockingTime = GameTimeManager:GetCurrentServerTime() - 1 -- 占时不需要倒计时
    end
    self:InitDistricts()
end

function CityMode:UnlockedDistrict(id)
    local districtData = self:GetDistrictLocalData()
    local districtCfg = self:GetCurrDistrictCfg()
    local cfg = self:GetCurrDistrictCfg()[id]
    if cfg then
        districtData.currId = cfg.id
        local maxId, maxNum = self:GetCurrMaxId()
        districtData.unlockingId = districtCfg[math.min(id + 1, maxNum)].id 
        districtData.unlockingTime = nil
    end
    self:InitDistricts()
    --self:InitBuildings()
end

---获取当前Area(District) ID
function CityMode:GetCurrentDistrict()
    local districtData = self:GetDistrictLocalData()
    if districtData then
        return districtData.currId
    end
end

function CityMode:IsDistrictUnlock(id)
    for k,v in pairs(self.m_districtData or {}) do
        if v.id == id and v.state == 1 then
            return true
        end
    end
    return false
end

--初始化城市中具体建筑(在地图中的显示)
function CityMode:InitBuildings()
    local currBuidlingId = self:GetCurrentBuilding()
    for i,v in pairs(self:GetCurrbuildingCfg() or {}) do
        self:CreateBuildingClass(i)
    end
end
--为 建筑类 变量 buildingsClass 赋值
function CityMode:CreateBuildingClass(id)
    local name = "Building_" .. id

    local currBuildingClass = self:GetBuildingClass(id)
    if not currBuildingClass then
        currBuildingClass = Class(name, Building)
        buildingsClass[id] = currBuildingClass
    end

    self.localCityData[id] = self.localCityData[id] or {}
    currBuildingClass:Init(id, ConfigMgr.config_buildings[id], self.localCityData[id])
end

function CityMode:ClickeOperationButton(id, functionName)
    if buildingsClass[id] then
        buildingsClass[id]:ClickeOperationButtonByName(functionName)
    end
end
--获取到当前状态下默认的办公楼
function CityMode:GetCurrentBuilding()
    self.localCityData = LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    --return localData.currBuidlingId         
    if self.localCityData.currBuidlingId then
        return self.localCityData.currBuidlingId
    end

    for i, v in pairs(self:GetCurrbuildingCfg() or {}) do
        if v.unlock_require == 0 then
            self.localCityData.currBuidlingId = i
            LocalDataManager:WriteToFile()
            break
        else
            
        end
    end

    return self.localCityData.currBuidlingId
end
--检测玩家建筑是否满足要求建筑
function CityMode:CheckBuildingSatisfy(BuildingId)
    for k,v in pairs(ConfigMgr.config_country) do
        local string = "city_record_data" .. CountryMode.SAVE_KEY[v.id]
        -- if v.id == 1 or nil then
        --     string = "city_record_data"            
        -- else
        --     string = "city_record_data" .. k
        -- end
        local CityData = LocalDataManager:GetDataByKey(string)
        if CityData.currBuidlingId and CityData.currBuidlingId >= BuildingId then
            return true    
        end
    end
    return false
end

function CityMode:ChanageCurrentBuilding(buildingId)
    if not self.localCityData.unlockingBuildingId or self.localCityData.unlockingBuildingId ~= buildingId then
        return 
    end

    self.localCityData.buildingState = BUILDING_STATE_NORMAL
    self.localCityData.unlockingBuildingId = nil
    self.localCityData.unlockingCountDown = nil
    self.localCityData.currBuidlingId = buildingId
    self:EnterDefaultBuiding()

    MainUI:RefreshNewPlayerPackage(true)
    --if buildingId == 200 then
    --    GameTableDefine.QuestionSurveyDataManager:Init()
    --end
    LocalDataManager:WriteToFile()
end

--跳转到其他的城市的建筑上去
function CityMode:GotoOtherCityBuilding(CityId)  
    
    local cb = function()
        GameStateManager:EnterBuildingFloor({id = CityId, config = ConfigMgr.config_buildings[CityId]})
        
        local roomId = CityId
        local cfgBuilding = ConfigMgr.config_buildings[roomId]
		local bgmPlay = SoundEngine[cfgBuilding.bgm]
        SoundEngine:PlayBackgroundMusic(bgmPlay, true)
    end
    -- MainUI:InitCameraScale("OutdoorScale", cb)
    GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(1, cb)

    MainUI:PlayUIAnimation(true) -- 解决创建完角色会闪MainUI
   
    MainUI:RefreshNewPlayerPackage(true) --刷新玩家礼包
end

function CityMode:EnterHouseOrCarShop(id)
    self:EnterDefaultBuiding(nil, id)
end

function CityMode:IsTypeHouse(id)
    if not id then
        return
    end
    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 2
end

function CityMode:IsTypeCarShop(id)
    if not id then
        return
    end
    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 3
end

function CityMode:IsTypeGreatBuilding(id)
    if not id then
        return
    end
    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 4
end

function CityMode:IsTypeOffice(id)
    if not id then
        return
    end

    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 1
end

function CityMode:IsTypeFactory(id)
    if not id then
        return
    end

    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 5
end

function CityMode:IsTypeFootballClub(id)
    if not id then
        return
    end

    local cfg = ConfigMgr.config_buildings[id]
    return cfg and cfg.building_type == 6
end

function CityMode:BuyBuilding(buildingId)
    if self.localCityData.currBuidlingId == buildingId then
        return
    end

    local cfg = ConfigMgr.config_buildings[buildingId]
    local cb = function(isEnough)
        if isEnough then
            if cfg.unlock_time then
                if cfg.company_qualities then
                    self.localCityData.buildingState = cfg.unlock_time > 0 and BUILDING_STATE_UNLOCKING or BUILDING_STATE_COMPLETE
                    self.localCityData.unlockingBuildingId = buildingId
                    self.localCityData.unlockingCountDown = cfg.unlock_time > 0 and (GameTimeManager:GetCurrentServerTime() + cfg.unlock_time) or 0
                    -- self:RefreshBuildingState(buildingId)
                    -- self:GetScene():ShowUnlockBuildingEffect()
                    --MainUI:InitCameraScale("OutdoorScale")
                    --local buildingsClass = self:GetBuildingClass(self.localCityData.unlockingBuildingId)
                    --buildingsClass:UpdateBuildingDetails()
                    CityMode:ChanageCurrentBuilding(buildingId)
                    --2025-2-7 2号场景解锁初始化CEO系统
                    if buildingId == 200 then
                        GameTableDefine.CEODataManager:Init()
                    end
                end
            else
                if cfg.company_qualities then
                    self.localCityData.currBuidlingId = buildingId
                    CityMode:EnterDefaultBuiding()
                else
                    if not self.localCityData.currHouses then
                        self.localCityData.currHouses = {}
                    end
                    table.insert(self.localCityData.currHouses, buildingId)
                    self:RefreshBuildingState(buildingId)
                end
            end
            GameSDKs:TrackForeign("scene_unlock", {scene_id = buildingId, operation_type = 2})
            --添加告知个人发展模块会自动切换个人发展的头衔设置
            -- GameTableDefine.PersonalDevModel:UnLockBuiding(buildingId)
            --2024-5-29 gxy 增加运营要求的af埋点，二号场景解锁
            if buildingId == 200 then
                GameSDKs:TrackControl("af", "af,af_scene_second", {af_buildingID = buildingId})
            end
            --2023增加运营要求的af埋点，三号场景解锁
            if buildingId == 300 then
                -- GameSDKs:Track("af_scene_third", {buildingID = buildingId})
                GameSDKs:TrackControl("af", "af,af_scene_third", {af_buildingID = buildingId})
            end

            --2024-09-02 wy 场景解锁，增加问卷开关判断
            GameTableDefine.QuestionSurveyDataManager:Init()
            EventManager:DispatchEvent(GameEventDefine.OnBuyBuilding)
            
            -- GameSDKs:Track("get_scene", {scene_id = buildingId, scene_name = GameTextLoader:ReadText("TXT_BUILDING_B"..buildingId.."_NAME"), operation_type = 2, current_money = ResMgr:GetCash()})
             --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
             local type = CountryMode:GetCurrCountry()
             local amount = cfg.unlock_require
             local change = 1
             local position = "["..buildingId.."]号办公楼解锁"
             GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})

             --2024-9-13fy添加，解锁房间时的af埋点
             if buildingId == 200 then 
                local newAFCondition = {18, 25, 35}
                local currStar = StarMode:GetStar()
                for i=1,#newAFCondition do
                    if currStar == newAFCondition[i] then
                        if GameTableDefine.CityMode:CheckBuildingSatisfy(200) then
                            local eventName = "scene_second_star_"..newAFCondition[i]
                            GameSDKs:TrackControl("af", "af,"..eventName, {af_buildingID = 0})
                        end
                    end      
                end
             end
        else
            --hint
        end
    end
    ResMgr:SpendLocalMoney(cfg.unlock_require, ResMgr.EVENT_BUY_BUILIDNG, cb)
end

---购买工厂
function CityMode:BuyFactoryBuilding(buildingId)
    local data = LocalDataManager:GetDataByKey(CountryMode.factory)
    local cfg = ConfigMgr.config_buildings[buildingId]
    --存档中存在这个数据表示购买过这个工厂了
    if not data[cfg.mode_name] then        
        ResMgr:SpendLocalMoney(cfg.unlock_require, nil,function(isEnough)
            if isEnough  then
                 --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
                local type = CountryMode:GetCurrCountry()
                local amount = cfg.unlock_require
                local change = 1
                local position = "["..buildingId.."]号伟大建筑购买"
                GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
                data[cfg.mode_name] = {}
                LocalDataManager:WriteToFile()
            end            
        end)        
    else
        return
    end
end

--购买足球俱乐部
function CityMode:BuyFootballClub(buildingId)
    local data = LocalDataManager:GetDataByKey(CountryMode.football)
    local cfg = ConfigMgr.config_buildings[buildingId]
    --存档中存在这个数据表示购买过这个工厂了
    if not data[cfg.mode_name] then        
        ResMgr:SpendLocalMoney(cfg.unlock_require, nil,function(isEnough)
            if isEnough then
                data[cfg.mode_name] = {}
                LocalDataManager:WriteToFile()

                  --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
                  local type = CountryMode:GetCurrCountry()
                  local amount = cfg.unlock_require
                  local change = 1
                  local position = "["..buildingId.."]号伟大建筑购买"
                  GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
            end            
        end)        
    else
        return
    end
end

function CityMode:UnlockBuidlingComplete() 
    if not self.localCityData.unlockingBuildingId then
        return
    end
    self.localCityData.buildingState = BUILDING_STATE_COMPLETE
    self.localCityData.unlockingCountDown = 0
    -- self:RefreshBuildingState(self.localCityData.unlockingBuildingId)
    local buildingsClass = self:GetBuildingClass(self.localCityData.unlockingBuildingId)
    buildingsClass:UpdateBuildingDetails()
end

function CityMode:UnlockBuildingNow(config, diamondNeed, cb)
    ResMgr:SpendDiamond(diamondNeed, nil, function(isEnough)
        if isEnough then
            self:UnlockBuidlingComplete()
            -- GameSDKs:Track("cost_diamond", {cost = diamondNeed, left = ResMgr:GetDiamond(), cost_way = "加速办公楼解锁"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "加速办公楼解锁", behaviour = 2, num_new = tonumber(diamondNeed)})
        end
        cb(isEnough)
    end)
end

function CityMode:EnterDefaultBuiding(defaultRoom, specialBuildId)
    local id = self:GetCurrentBuilding()

    local cb = function()
        -- if not id then
        --     GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(-1)
        --     return
        -- end
        GameStateManager:EnterBuildingFloor({id = id, config = ConfigMgr.config_buildings[id], defaultRoomCategory = defaultRoom, specialBuildId = specialBuildId})
        
        local roomId = specialBuildId ~= nil and specialBuildId or id
            
        local cfgBuilding = ConfigMgr.config_buildings[roomId]
		local bgmPlay = SoundEngine[cfgBuilding.bgm]
        SoundEngine:PlayBackgroundMusic(bgmPlay, true)
    end
    -- MainUI:InitCameraScale("OutdoorScale", cb)
    GameTableDefine.FlyIconsUI:SetScenceSwitchEffect(1, cb)

    MainUI:PlayUIAnimation(true) -- 解决创建完角色会闪MainUI
    ChatEventManager:ConditionToStart(5, id)
    OfflineRewardUI:LoopCheckRewardValue(function()
        OfflineRewardUI:GetView()
    end, false)
end

function CityMode:PlayDefaultSound()
    local id = self:GetCurrentBuilding()
    local cfgBuilding = ConfigMgr.config_buildings[id]
    local bgmPlay = SoundEngine[cfgBuilding.bgm]
    SoundEngine:PlayBackgroundMusic(bgmPlay, true)
end

function CityMode:LookAtBuilding(buildingId, cameraFocus, isBack, cb)
    if buildingsClass[buildingId] then
        buildingsClass[buildingId]:SetBuildingOnCenter(cameraFocus, isBack, cb)
    end
end
--在 建筑类buildingsClass 合集中  通过buildingId获取到具体的 建筑(building) 
function CityMode:GetBuildingClass(buildingId)
    if not buildingsClass or Tools:GetTableSize(buildingsClass) == 0 then
        return
    end
    return buildingsClass[buildingId]
end

function CityMode:RefreshGreateDetail(buildingId)
    local buildingsClass = self:GetBuildingClass(buildingId)
    buildingsClass:ShowGreateDetail()
end

function CityMode:RefreshBuildingState(buildingId)
    local buildingsClass = self:GetBuildingClass(buildingId)
    if buildingsClass == nil then
        return
    end
    buildingsClass:GetBuildingGoUIView()
end

function CityMode:GetUnlockingBuidlingInfo()
    local data = self.localCityData or LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    return data.unlockingBuildingId, data.unlockingCountDown
end

function CityMode:GetDistrictLocalData()
    local data = self.localCityData or LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    if not data.district then
        data.district = {}
    end
    return data.district
end

--已经废弃
function CityMode:GetHousesLocalData()
    -- local data = self.localCityData or LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    -- return data.currHouses
end

function CityMode:GetTotalHouse()
    local totalNum = 0
    for k,v in pairs(ConfigMgr.config_buildings or {}) do
        if k > 10000 then
            totalNum = totalNum + 1
        end
    end

    return totalNum
end

---是否拥有某建筑,兼容老玩家存档,只有汽车商店要故事线来解锁
function CityMode:IsHaveBuilding(buildingID)
    local buildingConfig = ConfigMgr.config_buildings[buildingID]
    if CityMode:IsTypeOffice(buildingID) then
        --办公楼
        local curr = CountryMode:GetMaxDevelopCountryBuildingID() or 100
        return curr>=buildingID and true or false
    elseif CityMode:IsTypeGreatBuilding(buildingID) then
        --伟大工程 是否拥有伟大工程的判断改为依照自由城的存档判断
        local data = LocalDataManager:GetDataByKey("greate_building")
        if data and data[tostring(buildingID)] and data[tostring(buildingID)].lv>0 then
            return true
        else
            return false
        end
    elseif CityMode:IsTypeCarShop(buildingID) then
        --汽车商店
        if not StoryLineManager:IsCompleteStage(buildingConfig.unlock_stage) then
            return false
        else
            local unlock = buildingConfig.starNeed <= StarMode:GetStar() and true or false
            return unlock
        end
    elseif CityMode:IsTypeFactory(buildingID) then
        --工厂
        local data = LocalDataManager:GetCurrentRecord()
        if data["factory"] and data["factory"][buildingConfig.mode_name] then
            return true
        else
            return false
        end
    elseif CityMode:IsTypeFootballClub(buildingID) then
        --足球俱乐部
        local data = LocalDataManager:GetCurrentRecord()
        local key = buildingConfig.mode_name
        local buildName = "football" .. CountryMode.SAVE_KEY[buildingConfig.country]
        if data[buildName] and data[buildName][key] then
            return true
        else
            return false
        end
    elseif CityMode:IsTypeHouse(buildingID) then
        --豪宅
        if HouseMode:GetLocalData(buildingID) then
            return true
        else
            return false
        end
    else
        return false
    end
end

---是否解锁了某建筑(包括已拥有),前置条可能是故事线或知名度达标
function CityMode:IsUnlockOrHaveBuilding(buildingID)
    local buildingConfig = ConfigMgr.config_buildings[buildingID]

    if buildingConfig.unlock_stage and buildingConfig.unlock_stage ~= 0 then
        if StoryLineManager:IsCompleteStage(buildingConfig.unlock_stage) then
            return true
        end
    else
        return self:IsHaveBuilding(buildingID)
    end

end

---获取 是否第一次到达的存档，升级老玩家存档
function CityMode:GetFirstComeData()
    local data = self.localCityData or LocalDataManager:GetDataByKey(CountryMode.city_record_data)
    local firstComeData = data[CITY_FIRST_COME]
    if not firstComeData then
        --升级老玩家存档
        firstComeData = {}
        data[CITY_FIRST_COME] = firstComeData
        --伟大建筑
        local gbData = LocalDataManager:GetDataByKey(CountryMode.greate_building)
        for k,v in pairs(gbData) do
            firstComeData[k] = true
        end
        --豪宅
        local hData = LocalDataManager:GetDataByKey("houses")
        if hData.d then
            for _,v in pairs(hData.d) do
                if v.id then
                    firstComeData[tostring(v.id)] = true
                end
            end
        end
    end

    return firstComeData
end

---是否应该显示Open提示
function CityMode:IsNeedShowOpenTip(buildingID)
    local buildingConfig = ConfigMgr.config_buildings[buildingID]
    if buildingConfig then
        if buildingConfig.unlock_stage and buildingConfig.unlock_stage ~= 0 then
            return self:IsFirstComeToBuilding(buildingID)
        end
    end
    return false
end

---获取是否去过这个建筑
function CityMode:IsFirstComeToBuilding(buildingID)
    if not buildingID then
        return false
    end

    local kID = tostring(buildingID)
    local cityFirstComeData = self:GetFirstComeData()
    if cityFirstComeData[kID] then
        return false
    end

    return true
end

---标记为去过这个建筑
function CityMode:MarkComeToBuilding(buildingID)
    if not buildingID or not self:IsFirstComeToBuilding(buildingID)then
        return
    end

    local kID = tostring(buildingID)
    local cityFirstComeData = self:GetFirstComeData()
    cityFirstComeData[kID] = true
    LocalDataManager:WriteToFile()
end

---是否有解锁了却没去过的汽车商店，豪宅，伟大建筑
function CityMode:AnyBuildingNeedCome()
    local curArea = self:GetCurrentDistrict() or 0
    local currCountry = CountryMode:GetCurrCountry()
    for k,v in pairs(ConfigMgr.config_buildings) do
        --区域，国家
        if v.unlock_stage and v.unlock_stage ~= 0 and (v.district or 0) <= curArea and v.country == currCountry then
            if v.building_type == 4 or v.building_type == 3 or v.building_type == 2 then
                if StoryLineManager:IsCompleteStage(v.unlock_stage) and self:IsFirstComeToBuilding(k) then
                    return true
                end
            end
        end
    end
    return false
end