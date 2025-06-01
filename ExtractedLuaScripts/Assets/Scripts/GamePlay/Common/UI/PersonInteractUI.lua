---@class PersonInteractUI
local PersonInteractUI = GameTableDefine.PersonInteractUI
local MainUI = GameTableDefine.MainUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local DressUpDataManager = GameTableDefine.DressUpDataManager
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local UIBaseView = require("Framework.UI.View")
local GameObject = CS.UnityEngine.GameObject

function PersonInteractUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSON_INTERACT_UI, self.m_view, require("GamePlay.Common.UI.PersonInteractUIView"), self, self.CloseView)
    return self.m_view
end

function PersonInteractUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSON_INTERACT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function PersonInteractUI:GetEquipmentCfg(rf)
    if not self.equipmentCfg or rf then
        self.equipmentCfg = {}
        for k,v in pairs(ConfigMgr.config_equipment) do
            if not self.equipmentCfg[v.part] then
                self.equipmentCfg[v.part] = {}
            end
            if v.default ~= 2 then
                table.insert(self.equipmentCfg[v.part], v)
            end
        end
    end
    return self.equipmentCfg
end

--员工的列表
function PersonInteractUI:GetPersonData(rf)
    if not self.employeeDataList or rf then
        self:AddEmployeeDataList(1)
        --     --特殊处理的老板与阿珍的数据
        --     for k,v in pairs(self:GetspecialData()) do
        --         table.insert(self.employeeDataList, v)
        --     end
        --     for k,v in pairs(ConfigMgr.config_employees or {}) do
        --         if not ShopManager:FirstBuy(v.shopId) then
        --             for i,o in pairs(self.employeeDataList) do
        --                 if o.person_type == v.person_type then

        --                 end
        --             end
        --             table.insert(self.employeeDataList, v)
        --         end
        --     end
    end

    return self.employeeDataList
end

--通过id往 employeeDataList 中加数据
function PersonInteractUI:AddEmployeeDataList(id)
    local data
    if not self.employeeDataList then
        self.employeeDataList = {}
    end
    local needAdd = true
    for k,v in pairs(self.employeeDataList) do
        if  v.id == id then
            needAdd = false
            break
        end
    end
    if needAdd then
        for k,v in pairs(self:GetspecialData()) do
            if  v.id == id then
                table.insert(self.employeeDataList, v)
                return
            end
        end
        local curr = ConfigMgr.config_employees[id]
        local index = 1
        if curr and curr.id == id then
            if Tools:GetTableSize(self.employeeDataList) == 0 then
                table.insert(self.employeeDataList, curr)
                return
            end
            for g,h in pairs(self.employeeDataList) do
                if h.person_type == curr.person_type and curr.id > h.id then
                    table.remove(self.employeeDataList, g)
                    table.insert(self.employeeDataList, curr)
                    return
                elseif h.person_type == curr.person_type and curr.id < h.id then
                    return
                elseif Tools:GetTableSize(self.employeeDataList) == index then
                    table.insert(self.employeeDataList, curr)
                    return
                end
                index = index + 1
            end
        end
    end
end

function PersonInteractUI:GetspecialData()
    if not self.specialData then
        local bossName = LocalDataManager:GetBossName()
        local bossSex = LocalDataManager:GetBossSex()
        local bossSkin = LocalDataManager:GetBossSkin()
        local bossIcon = "icon_boss_" .. Tools:SplitString(bossSkin, "_" )[2]
        --boss和阿珍的数据
        self.specialData = {
            {["id"] = 1, ["name"] = bossName, ["sex"] = bossSex, ["icon"] = bossIcon, ["show_prefab"] = bossSkin, ["desc"] = "TXT_EMPLOYEES_Boss_DESC"},
            {["id"] = 2, ["name"] = "TXT_EMPLOYEES_Azhen", ["sex"] = 2, ["icon"] = "icon_azhen", ["show_prefab"] = "Secretary_001", ["desc"] = "TXT_EMPLOYEES_Azhen_DESC"}
        }
    end
    return self.specialData
end

--通过id 去获取他在表中的位置和数据
function PersonInteractUI:GetPersonDataById(id)
    for k,v in pairs(self:GetPersonData()) do
        if v.id == id then
            return k, v
        end
    end
    return nil
end

--打开换装UI
function PersonInteractUI:OpenPersonInteractUI(cfg, roomGo, openType)
    -- self:GetView():Invoke("OpenPersonInteractUI", cfg, roomGo)
    --在Prefab加载后立刻删除不必要的Boss_001避免穿帮
    local point = UIBaseView:GetGo(roomGo, "PersonPos")
    if point then
        for k,v in pairs(point.transform) do
            GameObject.Destroy(v.gameObject)
        end
    end
    local view = self:GetView()
    view:Invoke("OpenPersonInteractUINew", cfg, roomGo, openType)
    MainUI:Hideing()
end