

local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local CompanyMode = GameTableDefine.CompanyMode
local ExchangeUI = GameTableDefine.ExchangeUI
local GuideManager = GameTableDefine.GuideManager
local CountryMode = GameTableDefine.CountryMode
local EventManager = require("Framework.Event.Manager")

function RoomBuildingUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ROOM_BUILDING_UI, self.m_view, require("GamePlay.Floors.UI.RoomBuildingUIView"), self, self.CloseView)
    return self.m_view
end

function RoomBuildingUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ROOM_BUILDING_UI)
    self.m_view = nil
    collectgarbage("collect")

    --引导加一个接口,调用立刻关闭...
    GuideManager:unenforceEnd()
end

function RoomBuildingUI:ShowRoomPanelInfo(roomId)
    local roomConfig = ConfigMgr.config_rooms[roomId]
    local localData = FloorMode:GetCurrRoomLocalData().furnitures or {}
    local shield = {[10038] = true, [10050] = true, [11038] = true, [11050] = true}
    local data = {}
    for i, v in ipairs(roomConfig.furniture or {}) do
        if shield[v.id] ~= true then -- 屏蔽经理和秘书,收益经理,离线经理
            local nextLevel = localData[i].level + 1
            local isMax = (nextLevel  > #ConfigMgr.config_furnitures_levels[v.id])
            nextLevel = math.min(#ConfigMgr.config_furnitures_levels[v.id], nextLevel)
            local nextFurnitureCfg = ConfigMgr.config_furnitures_levels[v.id][nextLevel] or {}
            local curFurnitureCfg = ConfigMgr.config_furnitures_levels[v.id][localData[i].level] or {}
            local name = FloorMode:GetFurnitureName(v.id, nextLevel)
            local desc = FloorMode:GetFurnitureDesc(v.id, nextLevel)

            local currShowLv = localData[i].level > 0 and localData[i].level or 1
            local icon = (v.id % 100 + 10000) .."_"..nextLevel
            local icon_curr = (v.id % 100 + 10000) .. "_" .. currShowLv
            --local currRent = curFurnitureCfg.quality.rent or 0
            --local nextRent = nextFurnitureCfg.quality.rent or 0
            --local bonous = currRent .." + " .. (nextRent - currRent)
            local bonousIcon = {}
            local bonous = {}
            local nextBonous = {}
            local qualitys = nil


            local currQuality = {rent_addition = curFurnitureCfg.rent_addition, support = curFurnitureCfg.support, office = curFurnitureCfg.office,
                                clean = curFurnitureCfg.clean, comfort = curFurnitureCfg.comfort, health = curFurnitureCfg.health,
                                network = curFurnitureCfg.network, addexp = curFurnitureCfg.addexp, time = curFurnitureCfg.time,
                                pleasure = curFurnitureCfg.pleasure, benefit = curFurnitureCfg.benefit, offlimit = curFurnitureCfg.offlimit}
            local nextQuality = {rent_addition = nextFurnitureCfg.rent_addition, support = nextFurnitureCfg.support, office = nextFurnitureCfg.office,
                                clean = nextFurnitureCfg.clean, comfort = nextFurnitureCfg.comfort, health = nextFurnitureCfg.health,
                                network = nextFurnitureCfg.network, addexp = nextFurnitureCfg.addexp, time = nextFurnitureCfg.time,
                                pleasure = nextFurnitureCfg.pleasure, benefit = nextFurnitureCfg.benefit, offlimit = nextFurnitureCfg.offlimit}

            if next(curFurnitureCfg) == nil then
                qualitys = nextQuality
            else
                qualitys = currQuality
            end

            for q_i,q_v in pairs(qualitys) do
                repeat
                    -- if roomConfig.category[2] ~= 1 and q_i == "rent_addition" then--不可入驻的房间
                    --     if q_v >= 0 then--不显示员工薪资之外的租金加成
                    --         break
                    --     end
                    -- end
                    if roomConfig.category[2] ~= 1 and q_i == "rent_addition" then--不可入驻的房间不显示
                        break
                    end
                    local nextQ = nextQuality[q_i] or 0
                    if q_i == "rent_addition" or q_i == "benefit" then
                        bonousIcon[#bonousIcon + 1] = "icon_".. q_i .. "_" .. CountryMode:GetCurrCountry()    
                    else
                        bonousIcon[#bonousIcon + 1] = "icon_".. q_i
                    end
                    bonous[#bonous + 1] = q_v
                    --nextBonous[#nextBonous + 1] = nextQ > 0 and (nextQ - q_v) or 0
                    nextBonous[#nextBonous + 1] = isMax and 0 or nextQ - q_v
                until true
            end

            local water = nextFurnitureCfg.water_consume or 0

            local lastPower = curFurnitureCfg.power_consume or 0
            local nextPower = nextFurnitureCfg.power_consume or 0
            local power = nextPower - lastPower
            --转换现金类型--
            local cost = nextFurnitureCfg.cost[1]
            local fame = nextFurnitureCfg.fame
            if cost.type == 2 then
                cost.type = CountryMode:GetCurrCountryCurrency()
                --cost.num = ExchangeUI:CurrencyExchange(1, ExchangeUI:SwitchCurrencyId(cost.type), cost.num)
            end
            table.insert(data, {hint = localData[i].level, nextLevel = nextLevel, id = v.id, 
                name = name, desc = desc, nextIcon = icon, currIcon = icon_curr, cost = cost,
                bonous = bonous, nextBonous = nextBonous, bonousIcon = bonousIcon, 
                water = water, power = power, fame = fame,
                lastPower = lastPower, nextPower = nextPower,
                isMaxLv = isMax, 
                progressValue = curFurnitureCfg.progressValue or 0}
            )
        end
    end

    local furnatureProgress = FloorMode:GetCurrRoomProgress()

    --CompanyMode:Init()--????每次打开设施界面都会重新初始化一次???不对吧

    local companyId = CompanyMode:CompIdByRoomIndex(roomConfig.room_index)
    local isOffice = FloorMode:IsTypeOffice(roomConfig.category)
    -- local roomName = GameTextLoader:ReadText("TXT_ROOM_R" .. roomConfig.room_index_number .. "_NAME")
    local roomName = GameTextLoader:ReadText(roomConfig.room_name)

    if companyId then
        local facilityData = {}
        local furnitureRequire = ConfigMgr.config_company[companyId] or {}
        local checkUnlock = function(furnitureId, level)
            local defReslut = (furnitureId % 100) == 1 and true or false --因为之前只有10001 需要,后面新增了11001和之后的也需要,所以这样写
            for i,v in pairs(localData) do
                if v.id  == furnitureId then
                    if (furnitureId % 100) == 1 then--办公室不同处理
                        if v.level == 0 then
                            --未解锁的不管
                        elseif v.level < level then
                            return false--一张不满足就变红
                        end
                    elseif v.level >= level then
                        return true--一张满足就变绿
                    end
                end
            end

            return defReslut
        end

        for k,v in pairs(furnitureRequire.facility_requirement) do
            local lvData = ConfigMgr.config_furnitures_levels[v]
            table.insert(facilityData, {hint = lvData.level, icon = (lvData.furniture_id % 100 + 10000) .."_" .. lvData.level, satisfy = checkUnlock(lvData.furniture_id, lvData.level)})
        end
        self:GetView():Invoke("SetBuildingNeedData", facilityData)
    end

    local isPowerRoom = roomConfig.category[2] == 5

    self:GetView():Invoke("SetHeadPanel", isOffice, roomName,  furnatureProgress)
    self:GetView():Invoke("SetTitlePanel", companyId)
    self:GetView():Invoke("SetListData", data)
    self:GetView():Invoke("SetPower", isPowerRoom)
    self:GetView():Invoke("SetProgress", roomId)

    --如果是是2号房间,并且工位没有全部解锁,则进行支线引导
    local currRoomIndex = FloorMode.m_curRoomIndex
    if currRoomIndex == "Office_2" then--之后再稍微优化一下
        local currValue = FloorMode:GetRoomFurnitureNum(10001, 1, currRoomIndex)
        local canActive = GuideManager:compareStepWith(20, 30, true)--非强制引导结束
        if currValue < 4 and canActive then
            GameSDKs:Track("guide", {guide_id = 20, guide_name = GameTextLoader:ReadText("TXT_GUIDE_"..20)})
            GameSDKs:TrackForeign("guide", {guide_id = 20, guide_desc = GameTextLoader:ReadText("TXT_GUIDE_"..20)})

            GuideManager:ConditionToEnd()
            GuideManager:GetNextStep(100, true, true, 107)
        else
            GuideManager:ConditionToEnd()
        end
    elseif currRoomIndex == "Office_4" or currRoomIndex == "Office_1" then
        GuideManager:ConditionToStart()
    end
end

function RoomBuildingUI:ChooseOne(furnitureId, buildingLevel)
    self:GetView():Invoke("ChooseOne", furnitureId, buildingLevel)
end

function RoomBuildingUI:CurrChoose()
    return self:GetView().m_currSelectItemIndex
end

function RoomBuildingUI:secondToHour(workTime)
    if not workTime then
        return ''
    end
    local h = math.floor(workTime / 60)
    local min = workTime - h * 60
    if min < 10 then
        min = '0' .. min
    end
    return h..':'..min
end