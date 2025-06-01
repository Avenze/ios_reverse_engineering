--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-28 17:51:59
]]

---@class DressUpDataManager
local DressUpDataManager = GameTableDefine.DressUpDataManager
local CfgMgr = GameTableDefine.ConfigMgr
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")
local UnityHelper = CS.Common.Utils.UnityHelper
local PersonInteractUI = GameTableDefine.PersonInteractUI
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
--[[
    @desc: 初始化存档数据中和装备相关的数据内容
    author:{author}
    time:2022-11-28 17:53:54
    @return:
]]
function DressUpDataManager:Init()
    local isNeedSave = false
    self.dressUpData = LocalDataManager:GetDataByKey("dressup_data")
    --已经获取到的所有装扮物品的数量dataItem:{itemID = xx:num = xxx}
    if not self.dressUpData.allDressUpDatas then
        self.dressUpData.allDressUpDatas = {}
        -- TODO:测试数据
        isNeedSave = true
    else
        -- --TODO:测试数据，添加7和8到数据中
        -- if self.dressUpData.allDressUpDatas then
        --     self.dressUpData.allDressUpDatas = {{itemID = 7, num = 1}, {itemID = 8, num = 1}}
        -- end
    end
    --已经穿戴的相关数据dataItem:{workerID:{id1, id2, id3, id4}}
    if not self.dressUpData.dressingDatas then
        self.dressUpData.dressingDatas = {}
        isNeedSave = true
    end
    --是否存在刚刚获取到了装备但是没有去查看()
    if self.dressUpData.newDressNotViewed == nil then
        self.dressUpData.newDressNotViewed = false
    end
    --全部已拥有的装备数据 data = { ID:{left:0, equip:0}} ID:外观物品的ID，left剩余未装备的数量，equip：已经装备的数量
    self.haveEquipDatas = {}
    --全部已拥有的饰品数据 data = { ID:{left:0, equip:0}} ID:外观物品的ID，left剩余未装备的数量，equip：已经装备的数量
    self.haveJewelryDatas = {}
    --全部已拥有的时装（戏服）数据
    self.haveFashionDatas = {}
    self:RefreshCurDressUpData()
    if isNeedSave then
        LocalDataManager:WriteToFile()
    end
end

function DressUpDataManager:RefreshCurDressUpData()
    for k, v in pairs(self.dressUpData.allDressUpDatas) do
        local itemConfig = CfgMgr.config_equipment[v.itemID]
        if not itemConfig then
            print("DressUpDataManager::RefreshCurDressUpData:没有找到配置表中有对应的数据:"..v.itemID)
        else
            if itemConfig.type == 2 then
                self.haveEquipDatas[v.itemID] = {left = v.num, equip = 0}
            elseif itemConfig.type == 1 then
                self.haveJewelryDatas[v.itemID] = {left = v.num, equip = 0}
            elseif itemConfig.type == 3 then
                self.haveFashionDatas[v.itemID] = {left = v.num, equip = 0}
            end
        end
    end

    for k, v in pairs(self.dressUpData.dressingDatas) do
        for _, dressID in pairs(v) do
            if self.haveEquipDatas[dressID] and self.haveEquipDatas[dressID].left > 0 then
                self.haveEquipDatas[dressID].left  = self.haveEquipDatas[dressID].left - 1
                self.haveEquipDatas[dressID].equip  = self.haveEquipDatas[dressID].equip + 1
            elseif self.haveJewelryDatas[dressID] and self.haveJewelryDatas[dressID].left > 0 then
                self.haveJewelryDatas[dressID].left  = self.haveJewelryDatas[dressID].left - 1
                self.haveJewelryDatas[dressID].equip  = self.haveJewelryDatas[dressID].equip + 1
            elseif self.haveFashionDatas[dressID] and self.haveFashionDatas[dressID].left > 0 then
                self.haveFashionDatas[dressID].left  = self.haveFashionDatas[dressID].left - 1
                self.haveFashionDatas[dressID].equip  = self.haveFashionDatas[dressID].equip + 1
            end
        end
    end
end

--[[
    @desc: 获取当前装扮物品数据1-饰品，2-装备，3-时候(戏服)4-所有
    author:{author}
    time:2022-11-29 15:32:28
    --@type:1-装饰物，2-装备，3-时装（戏服）4-所有
    @return:{itemiD:{left = 0, equip = 0}, itemID:{left = 0, equip = 0}}
    left-剩余可装备物品数量 equip-已装备（使用）物品数量
]]
function DressUpDataManager:GetCurrentDressUpData(type)
    if type == 1 then
        return self.haveJewelryDatas
    elseif type == 2 then
        return self.haveEquipDatas
    elseif type == 3 then
        return self.haveFashionDatas
    elseif type == 4 then
        local result = {}
        for k, v in pairs(self.haveEquipDatas) do
            result[k] = v
        end
        for k, v in pairs(self.haveJewelryDatas) do
            result[k] = v
        end
        return result
    end

    return {}
end

--[[
    @desc: 获取当前角色装备数据
    author:{author}
    time:2022-11-29 15:45:48
    --@personID: 角色对应的ID，有些角色需要约定id，比如阿珍和老板
    @return:
]]
function DressUpDataManager:GetCurrentPersonDressUpData(personID)
    return self.dressUpData.dressingDatas[tostring(personID)]
end

--[[
    @desc: 获取指定角色指定部位能装饰的ID的数据，如果没有可用饰品返回{}
    author:{author}
    time:2022-11-29 15:48:11
    --@personID:角色ID，有些角色需要约定ID，比如阿珍，老板等等
	--@type: 1-饰品，2-装备
    --@part: 装备部位,根据策划约定来进行
    @return:{id1, id2, id3}
]]
function DressUpDataManager:GetCanDressPartItems(personID, type, part)
    local result = {}
    if type == 1 then
        for k, v in pairs(self.haveJewelryDatas) do
            local itemconfig = CfgMgr.config_equipment[k]
            if itemconfig and itemconfig.part == part and v.left > 0 then
                table.insert(result, k)
            end
        end
    elseif type == 2 then
        for k, v in pairs(self.haveEquipDatas) do
            local itemconfig = CfgMgr.config_equipment[k]
            if itemconfig and itemconfig.part == part and v.left > 0 then
                table.insert(result, k)
            end
        end
    elseif type == 3 then
        for k, v in pairs(self.haveFashionDatas) do
            local itemConfig = CfgMgr.config_equipment[k]
            if v.left > 0 then
                table.insert(result, k)
            end
        end
    end

    return result;
end

--[[
    @desc: 获取当前角色已经装备的ID相关内容
    author:{author}
    time:2022-11-29 16:35:23
    --@personID:
    @return:{partID:itemID, partID:itemID}
]]
function DressUpDataManager:GetCurrentPersonAllDressUp(personID)
    local result = {}
    if self.dressUpData.dressingDatas[tostring(personID)] then
        for _, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
            local itemConfig = CfgMgr.config_equipment[v]
            if itemConfig then
                result[itemConfig.part] = v
            end
        end
    end
    return result
end

--[[
    @desc: 更换装备或者装饰的接口
    author:{author}
    time:2022-11-29 16:50:48
    --@personID:指定要更换装扮的角色的id
	--@type:装扮类型1-饰品，2-装备
	--@part:部位，根据策划约定
	--@oldID:当前部位的装扮物ID，没有的话就填0，就是新加的装扮
	--@newID: 需要更换的装扮的ID，如果是脱装备的话，这个就填0
    @return:换装成功，如果是UI层调用的话，需要刷新下对应的一些显示数据
]]
function DressUpDataManager:ChangeDressUp(personID, type, part, oldID, newID)
    local result = true
    --local isNeedSave = false
    --step1.判断是否是脱装备
    if newID == 0 then
        if oldID == 0 then
            return false
        end
        if type == 1 then
            if self.haveJewelryDatas[oldID] then
                self.haveJewelryDatas[oldID].left  = self.haveJewelryDatas[oldID].left + 1
                self.haveJewelryDatas[oldID].equip  = self.haveJewelryDatas[oldID].equip - 1
            end
        elseif type == 2 then
            if self.haveEquipDatas[oldID] then
                self.haveEquipDatas[oldID].left  = self.haveEquipDatas[oldID].left + 1
                self.haveEquipDatas[oldID].equip  = self.haveEquipDatas[oldID].equip - 1
            end
        elseif type == 3 then
            if self.haveFashionDatas[oldID] then
                self.haveFashionDatas[oldID].left  = self.haveFashionDatas[oldID].left + 1
                self.haveFashionDatas[oldID].equip  = self.haveFashionDatas[oldID].equip - 1
            end
        end
        if self.dressUpData.dressingDatas[tostring(personID)] then
            for k, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
                if v == oldID then
                    table.remove(self.dressUpData.dressingDatas[tostring(personID)], k)
                    LocalDataManager:WriteToFile()
                    EventManager:DispatchEvent("ChangeDressUpSuccess_"..personID, personID, type, oldID, newID)
                    return result
                end
            end
        end
    elseif newID ~= 0 then
        if self.dressUpData.dressingDatas[tostring(personID)] then
            for k, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
                if newID == v then
                    return false
                end
            end
        end
        if type == 1 then
            if self.haveJewelryDatas[newID] and self.haveJewelryDatas[newID].left > 0 then
                self.haveJewelryDatas[newID].left  = self.haveJewelryDatas[newID].left - 1
                self.haveJewelryDatas[newID].equip  = self.haveJewelryDatas[newID].equip + 1
                if oldID > 0 then
                    if self.haveJewelryDatas[oldID] then
                        self.haveJewelryDatas[oldID].left  = self.haveJewelryDatas[oldID].left + 1
                        self.haveJewelryDatas[oldID].equip  = self.haveJewelryDatas[oldID].equip - 1
                    else
                        self.haveJewelryDatas[oldID] = {left = 1, equip = 0}
                    end
                end
                --这里判断穿挂件必须脱掉时装
                self:DrawOffPersonCurFashion(personID)
            else
                return false
            end
        elseif type == 2 then
            if self.haveEquipDatas[newID] and self.haveEquipDatas[newID].left > 0 then
                self.haveEquipDatas[newID].left  = self.haveEquipDatas[newID].left - 1
                self.haveEquipDatas[newID].equip  = self.haveEquipDatas[newID].equip + 1
                if oldID > 0 then
                    if self.haveEquipDatas[oldID] then
                        self.haveEquipDatas[oldID].left  = self.haveEquipDatas[oldID].left + 1
                        self.haveEquipDatas[oldID].equip  = self.haveEquipDatas[oldID].equip - 1
                    else
                        self.haveEquipDatas[oldID] = {left = 1, equip = 0}
                    end
                end
                --这里判断穿Body必须脱掉时装
                self:DrawOffPersonCurFashion(personID)
            else
                return false
            end
        elseif type == 3 then
            if self.haveFashionDatas[newID] and self.haveFashionDatas[newID].left > 0 then
                self.haveFashionDatas[newID].left  = self.haveFashionDatas[newID].left - 1
                self.haveFashionDatas[newID].equip  = self.haveFashionDatas[newID].equip + 1
                if oldID > 0 then
                    if self.haveFashionDatas[oldID] then
                        self.haveFashionDatas[oldID].left  = self.haveFashionDatas[oldID].left + 1
                        self.haveFashionDatas[oldID].equip  = self.haveFashionDatas[oldID].equip - 1
                    else
                        self.haveFashionDatas[oldID] = {left = 1, equip = 0}
                    end
                end
                --穿时装先自动脱下身上所有的挂件
                self:DrawOffPersonAllJewerly(personID)
                self:DrawOffPersonBody(personID)
            else
                return false
            end
        end

        if self.dressUpData.dressingDatas[tostring(personID)] then
            table.insert(self.dressUpData.dressingDatas[tostring(personID)], newID)
            if oldID ~= 0 then
                for k, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
                    if v == oldID then
                        table.remove(self.dressUpData.dressingDatas[tostring(personID)], k)
                    end
                end
            end
        else
            self.dressUpData.dressingDatas[tostring(personID)] = {}
            table.insert(self.dressUpData.dressingDatas[tostring(personID)], newID)
        end
        EventManager:DispatchEvent("ChangeDressUpSuccess_".. personID, personID, type, oldID, newID)
        LocalDataManager:WriteToFile()
    end

    return result
end

---获取所有装扮
function DressUpDataManager:GetAllDressUpItem(count)
    count = count or 1
    for k,v in pairs(CfgMgr.config_equipment) do
        self:GetNewDressUpItem(k,count)
    end
end

--[[
    @desc: 获取新的装扮物品了
    author:{author}
    time:2022-11-29 17:51:11
    --@itemID:
	--@num:
    @return:
]]
function DressUpDataManager:GetNewDressUpItem(id, count)
    local itemConfig = CfgMgr.config_equipment[id]
    if itemConfig then
        local isHave = false
        --已经获取到的所有装扮物品的数量dataItem:{itemID = xx:num = xxx}
        for k, v in pairs(self.dressUpData.allDressUpDatas) do
            if v.itemID == id then
                v.num  = v.num + count
                isHave = true
                break
            end
        end
        if not isHave then
            table.insert(self.dressUpData.allDressUpDatas, {itemID = id, num = count})
        end
        LocalDataManager:WriteToFile()
        if itemConfig.type == 1 then
            if self.haveJewelryDatas[id] then
                self.haveJewelryDatas[id].left  = self.haveJewelryDatas[id].left + count
            else
                self.haveJewelryDatas[id] = {left = count, equip = 0}
            end
        elseif itemConfig.type == 2 then
            if self.haveEquipDatas[id] then
                self.haveEquipDatas[id].left  = self.haveEquipDatas[id].left + count
            else
                self.haveEquipDatas[id] = {left = count, equip = 0}
            end
        elseif itemConfig.type == 3 then
            if self.haveFashionDatas[id] then
                self.haveFashionDatas[id].left  = self.haveFashionDatas[id].left + count
            else
                self.haveFashionDatas[id] = {left = count, equip = 0}
            end
        end
        self.dressUpData.newDressNotViewed = true
        EventManager:DispatchEvent("NewDressupItemGet", id, count)
    end
end

--[[
    @desc: 检查是否存在有没被查看的新装备
    author:{author}
    time:2022-12-15 12:02:55
    @return: 有新的返回true, 没有返回 false
]]
function DressUpDataManager:CheckNewDressNotViewed()
    if not self.dressUpData then
        return false
    end
    return self.dressUpData.newDressNotViewed or false
end
--[[
    @desc: 将有没查看过的标签设置为false
    author:{author}
    time:2022-12-15 12:10:27
    @return:
]]
function DressUpDataManager:SetNewDressNotViewed(Viewed)
    if Viewed == nil or self.dressUpData.newDressNotViewed  == nil then
        return
    end
    self.dressUpData.newDressNotViewed = Viewed
end

--[[
    @desc: 脱去当前角色身上所有的挂件装饰接口
    author:{author}
    time:2022-12-06 14:24:03
    --@personID:
    @return:成功true，失败false
]]
function DressUpDataManager:DrawOffPersonAllJewerly(personID)
    if not self.dressUpData.dressingDatas[tostring(personID)] then
        return false
    end
    local drawOffIDs = {}
    local othersIDs = {}
    for k, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
        local itemConfig = CfgMgr.config_equipment[v]
        if itemConfig then
            if itemConfig.type == 1 then
                table.insert(drawOffIDs, itemConfig.id)
                if self.haveJewelryDatas[v] then
                    self.haveJewelryDatas[v].left  = self.haveJewelryDatas[v].left + 1
                    self.haveJewelryDatas[v].equip  = self.haveJewelryDatas[v].equip - 1
                else
                    self.haveJewelryDatas[v] = {left = 1, equip = 0}
                end
            else
                table.insert(othersIDs, itemConfig.id)
            end
        end
    end

    if Tools:GetTableSize(drawOffIDs) > 0 then
        self.dressUpData.dressingDatas[tostring(personID)] = othersIDs
        EventManager:DispatchEvent("DrawOffPersonAllJewerly_"..personID, drawOffIDs)
    end

    return true
end

---脱去当前角色身上所有的挂件装饰接口
function DressUpDataManager:DrawOffPersonBody(personID)
    local dressUpDatas = self.dressUpData.dressingDatas[tostring(personID)]
    if not dressUpDatas then
        return false
    end
    local drawOffID = nil
    local len = #dressUpDatas
    if len>0 then
        for i = len, 1,-1 do
            local dressUpID = dressUpDatas[i]
            local itemConfig = CfgMgr.config_equipment[dressUpID]
            if itemConfig then
                if itemConfig.type == 2 then
                    drawOffID = itemConfig.id
                    if self.haveEquipDatas[dressUpID] then
                        self.haveEquipDatas[dressUpID].left  = self.haveEquipDatas[dressUpID].left + 1
                        self.haveEquipDatas[dressUpID].equip  = self.haveEquipDatas[dressUpID].equip - 1
                    else
                        self.haveEquipDatas[dressUpID] = {left = 1, equip = 0}
                    end
                    table.remove(dressUpDatas,i)
                    break
                end
            end
        end
    end

    if drawOffID then
        EventManager:DispatchEvent("DrawOffPersonBody"..personID, drawOffID)
    end

    return true
end

--[[
    @desc:脱掉当前身上的时装
    author:{author}
    time:2022-12-08 11:24:30
    --@personID:
    @return:
]]
function DressUpDataManager:DrawOffPersonCurFashion(personID)
    if not self.dressUpData.dressingDatas[tostring(personID)] then
        return false
    end
    local drawFashoinIDs = 0
    for k, v in pairs(self.dressUpData.dressingDatas[tostring(personID)]) do
        local itemConfig = CfgMgr.config_equipment[v]
        if itemConfig then
            if itemConfig.type == 3 then
                drawFashoinIDs = v
                if self.haveFashionDatas[v] then
                    self.haveFashionDatas[v].left  = self.haveFashionDatas[v].left + 1
                    self.haveFashionDatas[v].equip  = self.haveFashionDatas[v].equip - 1
                else
                    self.haveFashionDatas[v] = {left = 1, equip = 0}
                end

                table.remove(self.dressUpData.dressingDatas[tostring(personID)], k)
                break
            end
        end
    end

    if drawFashoinIDs > 0 then
        EventManager:DispatchEvent("DrawOffPersonCurrFashion_"..personID, drawFashoinIDs)
    end

    return true
end

--[[
    @desc: 检测当前的角色是否需要替换存档数据，用于离线经理升级等逻辑处理，新的经理升级现在就直接把老的数据删除
    author:{author}
    time:2022-12-08 15:28:33
    --@personID:
    @return:
]]
function DressUpDataManager:CheckAddPersonRefreshDressUpData(personID)
    if not self.dressUpData or not self.dressUpData.dressingDatas then
        return
    end
    if self.dressUpData.dressingDatas and Tools:GetTableSize(self.dressUpData.dressingDatas) > 0 and self.dressUpData.dressingDatas[tostring(personID)] then
        return
    end
    local employConfig = CfgMgr.config_employees[personID]
    if not employConfig then
        return
    end
    local removeData = nil
    for id, v in pairs(self.dressUpData.dressingDatas) do
        local havePersonItem = CfgMgr.config_employees[tonumber(id)]
        if havePersonItem then
            if havePersonItem.person_type == employConfig.person_type then
                removeData = Tools:CopyTable(self.dressUpData.dressingDatas[id])
                self.dressUpData.dressingDatas[id] = nil
                LocalDataManager:WriteToFile()
                break
            end
        end
    end
    if removeData then
        for _, v in pairs(removeData) do
            local itemCfg = CfgMgr.config_equipment[v]
            if itemCfg then
                if itemCfg.type == 3 then
                    if self.haveFashionDatas[v] then
                        self.haveFashionDatas[v].left  = self.haveFashionDatas[v].left + 1
                        self.haveFashionDatas[v].equip  = self.haveFashionDatas[v].equip - 1
                    else
                        self.haveFashionDatas[v] = {left = 1, equip = 0}
                    end
                elseif itemCfg.type == 1 then
                    if self.haveJewelryDatas[v] then
                        self.haveJewelryDatas[v].left  = self.haveJewelryDatas[v].left + 1
                        self.haveJewelryDatas[v].equip  = self.haveJewelryDatas[v].equip - 1
                    else
                        self.haveJewelryDatas[v] = {left = 1, equip = 0}
                    end
                elseif itemCfg.type == 2 then
                    if self.haveEquipDatas[v] then
                        self.haveEquipDatas[v].left  = self.haveEquipDatas[v].left + 1
                        self.haveEquipDatas[v].equip  = self.haveEquipDatas[v].equip - 1
                    else
                        self.haveEquipDatas[v] = {left = 1, equip = 0}
                    end
                end
            end
        end
    end
end

--[[
    @desc: 用于timeline播放的时候替换其蒙皮的相关功能
    author:{author}
    time:2022-12-09 10:19:34
    --@timelineGo:
    @return:
]]
function DressUpDataManager:ChangeTimelineActorDressUp(timelineGo)
    if not timelineGo then
        return
    end
    print("ChangeTimelineActorDressUp:"..timelineGo.name)
    ---检测timeline和阿珍老板有关联的进行换装替换
    --step1.找到阿珍和老板有装扮的数据
    local azhenFashionID = 0
    local bossFashionID = 0
    local azhenJewerlyIDs = {}
    local bossJewerlyIDs = {}
    local bossBodyID = 0
    if not self.dressUpData or not self.dressUpData.dressingDatas then
        return
    end
    --获取老板数据
    if self.dressUpData.dressingDatas["1"] then
        for _, v in pairs(self.dressUpData.dressingDatas["1"]) do
            local itemConfig = CfgMgr.config_equipment[v]
            if itemConfig then
                if itemConfig.type == 1 then
                    table.insert(bossJewerlyIDs, v)
                elseif itemConfig.type == 3 then
                    bossFashionID = v
                    break
                elseif itemConfig.type == 2 then
                    bossBodyID = v
                end
            end
        end
    end
    --获取阿珍数据
    if self.dressUpData.dressingDatas["2"] then
        for _, v in pairs(self.dressUpData.dressingDatas["2"]) do
            local itemConfig = CfgMgr.config_equipment[v]
            if itemConfig then
                if itemConfig.type == 1 then
                    table.insert(azhenJewerlyIDs, v)
                elseif itemConfig.type == 3 then
                    azhenFashionID = v
                    break
                end
            end
        end
    end
    local peopleGo = UnityHelper.FindTheChildByGo(timelineGo, "People")
    if not peopleGo then
        return
    end
    local bossParentGo = UnityHelper.FindTheChildByGo(peopleGo, "Boss")
    local curBossGo = nil
    if bossParentGo then
        curBossGo = UnityHelper.FindTheChildByGo(bossParentGo, LocalDataManager:GetBossSkin())
    end
    local azhenParentGo = UnityHelper.FindTheChildByGo(peopleGo, "Azhen")
    local curAzhenGo = nil
    if azhenParentGo then
        curAzhenGo = UnityHelper.FindTheChildByGo(azhenParentGo, "Secretary_001")
    end
    --开始给老板换装了
    if curBossGo then
        if bossFashionID > 0 then
            bossJewerlyIDs = {}
            local itemCfg = CfgMgr.config_equipment[bossFashionID]
            if itemCfg then
                local prefab = itemCfg.path..itemCfg.prefab..".prefab"
                local loadGoCb = function(go)
                    if curBossGo then

                        local fashionGo = UnityHelper.ChangeSkinnedMeshAndBones(curBossGo,go)
                        if not fashionGo then
                            UnityHelper.DestroyGameObject(go)
                        end
                        fashionGo:SetActive(true)

                        local modelGO = UnityHelper.FindTheChildByGo(curBossGo, "Model")
                        if modelGO then
                            modelGO:SetActive(false)
                        end
                    end
                end
                GameResMgr:AInstantiateObjectAsyncManual(prefab, self, loadGoCb)
            end
        else
            if Tools:GetTableSize(bossJewerlyIDs) > 0 then
                if self.initBossJewelryTimeHander then
                    GameTimer:StopTimer(self.initBossJewelryTimeHander)
                    self.initBossJewelryTimeHander = nil
                end
                local index = 1
                self.initBossJewelryTimeHander = GameTimer:CreateNewTimer(1, function()
                    if index > Tools:GetTableSize(bossJewerlyIDs) then
                        GameTimer:StopTimer(self.initBossJewelryTimeHander)
                        self.initBossJewelryTimeHander = nil
                    end
                    local dressConfig = CfgMgr.config_equipment[bossJewerlyIDs[index]]
                    if dressConfig then
                        local prefab = dressConfig.path..dressConfig.prefab..".prefab"
                        local loadGoCb = function(go)
                            local boneTran = UnityHelper.FindTheChild(curBossGo, "mixamorig:Hips/"..dressConfig.pos)
                            if boneTran then
                                UnityHelper.AddChildToParent(boneTran, go.transform)
                            else
                                UnityHelper.DestroyGameObject(go)
                            end
                        end
                        GameResMgr:AInstantiateObjectAsyncManual(prefab, self, loadGoCb)
                    end
                    index  = index + 1
                end, true, true)
            end
            if bossBodyID>0 then
                local itemCfg = CfgMgr.config_equipment[bossBodyID]
                if itemCfg then
                    local prefab = itemCfg.path..itemCfg.prefab..".prefab"
                    local loadGoCb = function(go)
                        if curBossGo then
                            UnityHelper.ChangeSkinnedMeshAndBonesToBoss(curBossGo,go)
                            local modelGO = UnityHelper.FindTheChildByGo(curBossGo, "Model")
                            if modelGO then
                                modelGO:SetActive(false)
                            end
                        end
                    end
                    GameResMgr:AInstantiateObjectAsyncManual(prefab, self, loadGoCb)
                end
            end
        end
    end

    --开始给阿珍换装
    if curAzhenGo then
        if azhenFashionID > 0 then
            azhenJewerlyIDs = {}
            local itemCfg = CfgMgr.config_equipment[azhenFashionID]
            if itemCfg then
                local prefab = itemCfg.path..itemCfg.prefab..".prefab"
                local loadGoCb = function(go)
                    if curAzhenGo then
                        local fashionGo = UnityHelper.ChangeSkinnedMeshAndBones(curAzhenGo, go)
                        if not fashionGo then
                            UnityHelper.DestroyGameObject(go)
                        end
                        fashionGo:SetActive(true)
                        local modelGO = UnityHelper.FindTheChildByGo(curAzhenGo, "Model")
                        if modelGO then
                            modelGO:SetActive(false)
                        end
                    end
                end
                GameResMgr:AInstantiateObjectAsyncManual(prefab, self, loadGoCb)
            end
        elseif Tools:GetTableSize(azhenJewerlyIDs) > 0 then
            if self.initAZhenTimeHandler then
                GameTimer:StopTimer(self.initAZhenTimeHandler)
                self.initAZhenTimeHandler = nil
            end
            local index = 1
            self.initAZhenTimeHandler = GameTimer:CreateNewTimer(1, function()
                if index > Tools:GetTableSize(azhenJewerlyIDs) then
                    GameTimer:StopTimer(self.initAZhenTimeHandler)
                    self.initAZhenTimeHandler = nil
                end
                local dressConfig = CfgMgr.config_equipment[azhenJewerlyIDs[index]]
                if dressConfig then
                    local prefab = dressConfig.path..dressConfig.prefab..".prefab"
                    local loadGoCb = function(go)
                        local boneTran = UnityHelper.FindTheChild(curAzhenGo, "mixamorig:Hips/"..dressConfig.pos)
                        if boneTran then
                            UnityHelper.AddChildToParent(boneTran, go.transform)
                        else
                            UnityHelper.DestroyGameObject(go)
                        end
                    end
                    GameResMgr:AInstantiateObjectAsyncManual(prefab, self, loadGoCb)
                end
                index  = index + 1
            end,true, true)
        end
    end
end

function DressUpDataManager:TestChangeDressup(personID, type, oldID, newID)
    EventManager:DispatchEvent("ChangeDressUpSuccess_"..personID, personID, type, oldID, newID)
end

--[[
    @desc: 获取当前装扮带来的现金加成收益
    author:{author}
    time:2022-12-20 17:11:27
    @return:
]]
function DressUpDataManager:CashImprove()
    return 0
end

function DressUpDataManager:GetOfflineAdd()
    return 0
end

function DressUpDataManager:GetMoodImprove()
    return 0
end

--加载身体(Boss专用)
function DressUpDataManager:LoadBodyToPersonGO(parentGO,childPath,cb)
    GameResMgr:AInstantiateObjectAsyncManual(childPath, self, function(this)
        UnityHelper.ChangeSkinnedMeshAndBonesToBoss(parentGO,this)
        UnityHelper.DestroyGameObject(this)
        if cb then cb(this) end
    end)
end

--清空一个GameObject下的子物体,添加我们想让其添加的物体
function DressUpDataManager:AddOnlyGo(parentTr, childPath, cb)
    if parentTr then
        for k,v in pairs(parentTr) do
            GameObject.Destroy(v.gameObject)
        end
    end
    GameResMgr:AInstantiateObjectAsyncManual(childPath, self, function(this)
        GameTimer:CreateNewMilliSecTimer(2,function()
            UnityHelper.AddChildToParent(parentTr,this.transform)
            if cb then cb(this) end
        end,false,false)
    end)
end


--给人物添加饰品,或替换BOSS身体
function DressUpDataManager:AddPersonDressUp(personGO,cfgEquipment,cb,isBoss)
    if not cfgEquipment.prefab then
        print("换装配置表没填prefab "..cfgEquipment.path)
        if cb then cb() end
        return
    end
    if cfgEquipment.part == 0 then
        --套装不做处理
    else
        local path = cfgEquipment.path .. cfgEquipment.prefab .. ".prefab"
        if isBoss and cfgEquipment.part == 4 then --BOSS 身体单独处理
            --关闭Model
            local modelGO = UnityHelper.FindTheChild(personGO,"Model").gameObject
            modelGO:SetActive(false)
            --加载身体
            self:LoadBodyToPersonGO(personGO, path, function(go)
                if cb then cb() end
            end)
        else
            local posTrans
            if cfgEquipment.pos then
                posTrans = UnityHelper.FindTheChild(personGO, cfgEquipment.pos)
            end
            if posTrans then
                self:AddOnlyGo(posTrans, path, function(this)
                    UnityHelper.AddChildToParent(posTrans, this.transform)
                    if cb then cb() end
                end)
            else
                if cb then cb() end
            end
        end
    end
end

---获取一个角色，包含它的换装
function DressUpDataManager:LoadPersonGO(personID,cb)
    local personIndex,cfgPerson = PersonInteractUI:GetPersonDataById(personID)
    if not cfgPerson then
        if cb then
            cb(nil)
        end
        return
    end

    local personDressData = DressUpDataManager:GetCurrentPersonAllDressUp(cfgPerson.id)
    if personDressData then
        for k,v in pairs(personDressData) do
            local cfgEquipment = CfgMgr.config_equipment[v]
            if cfgEquipment.part == 0 then
                --加载对应套装然后返回
                local dressPath = cfgEquipment.path .. cfgEquipment.prefab .. ".prefab"
                GameResMgr:AInstantiateObjectAsyncManual(dressPath, self, function(this)
                    GameTimer:CreateNewMilliSecTimer(2,function()
                        if cb then cb(this) end
                    end,false,false)
                end)
                return
            end
        end
    end
    local path = "Assets/Res/Prefabs/character/".. cfgPerson.show_prefab ..".prefab"
    local isBoss = personID == 1
    --加载角色基础模型
    GameResMgr:AInstantiateObjectAsyncManual(path, self, function(this)
        GameTimer:CreateNewMilliSecTimer(2,function()
            local resultGO = this
            if personDressData then
                local loadingCount = 1 --初始设为1，防止同一帧加载完成导致多次回调
                local loadDressUpOverFunc = function()
                    loadingCount = loadingCount-1
                    if loadingCount == 0 then
                        if cb then
                            cb(resultGO)
                        end
                    end
                end
                --加载装扮
                for k,v in pairs(personDressData) do
                    local cfgEquipment = CfgMgr.config_equipment[v]
                    if cfgEquipment.part ~= 0 then
                        loadingCount = loadingCount+1
                        self:AddPersonDressUp(resultGO,cfgEquipment,loadDressUpOverFunc,isBoss)
                    end
                end
                --加载饰品
                for k,v in pairs(cfgPerson.deco or {}) do
                    local canDress = true --不是默认装备才加载
                    local defCfgEquipment = CfgMgr.config_equipment[v]
                    for i,o in pairs(personDressData) do
                        if CfgMgr.config_equipment[o].part == defCfgEquipment.part then
                            canDress = false
                            break
                        end
                    end
                    if canDress then
                        loadingCount = loadingCount+1
                        self:AddPersonDressUp(resultGO,defCfgEquipment,loadDressUpOverFunc,isBoss)
                    end
                end
                loadDressUpOverFunc()
            end
        end,false,false)
    end)
end