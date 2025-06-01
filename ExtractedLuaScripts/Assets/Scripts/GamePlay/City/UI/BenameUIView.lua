local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local PetInteractUI = GameTableDefine.PetInteractUI
local GameUIManager = GameTableDefine.GameUIManager
local BenameUI = GameTableDefine.BenameUI
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local PetMode = GameTableDefine.PetMode
local FootballClubModel = GameTableDefine.FootballClubModel
local BenameUIView = Class("BenameUIView", UIView)

function BenameUIView:ctor()
    self.super:ctor()
    self.m_isBuildingName = nil
end

function BenameUIView:OnEnter()
    print("BenameUIView:OnEnter")
    GameUIManager:SetEnableTouch(true)  -- gxy 2024-4-26 16:05:41  重命名时强制开启可点击 
    ---2024-10-29 fy根据玩家取名和公司取名要求添加随机名字的功能，对下面的功能进行相应的修改
    --step1.检测当前是玩家命名还是公司命名
    local isBossName = false
    local isBuildingName = false

    local userName = LocalDataManager:GetBossName()
    if not userName then
        isBossName = true
    end
    if not isBossName then
        local buildingName = LocalDataManager:GetBuildingName()
        if not buildingName then
            isBuildingName = true
        end
    end

    self:GetGo("RootPanel/MidPanel/input_character"):SetActive(isBossName or isBuildingName)
    self:GetGo("RootPanel/MidPanel/input"):SetActive(not isBossName and not isBuildingName)
    local txtComp = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    if isBossName or isBuildingName then
        txtComp = self:GetComp("RootPanel/MidPanel/input_character/input", "TMP_InputField")
    end
    self:SetText("RootPanel/MidPanel/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_NAME_INPUT"))
    self:SetText("RootPanel/MidPanel/input_character/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_NAME_INPUT"))
    if isBossName then
        txtComp.text = self:GetRandomBossName(true)
    end
    if isBuildingName then
        txtComp.text = self:GetRandomCompanyName(true)
    end
    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
        if self:CheckNameLawless(txtComp.text) then
            return
        end
        BenameUI:SaveName(txtComp.text, self.m_isBuildingName)
        self:DestroyModeUIObject()
    end)

    self:SetTMPInputEndEditHandler(txtComp, function(content)
        -- if Tools:Utf8len(content) > 6 then
        --     txtComp:SetTextWithoutNotify(Tools:Utf8sub(content, 1, 6))
        -- end
        if isBossName then
            GameSDKs:TrackForeign("init", {init_id = 21, init_desc = "角色手动命名"})
        end
        if isBuildingName then
            GameSDKs:TrackForeign("init", {init_id = 23, init_desc = "公司手动命名"})
        end
        local len = string.len(content)
        if string.len(content) > 18 then
            local result = string.sub(content, 1, 18)
            txtComp:SetTextWithoutNotify(result)
        end
    end)

    local rerollNameBtn = self:GetComp("RootPanel/MidPanel/input_character/rerollBtn", "Button")
    self:SetButtonClickHandler(rerollNameBtn, function()
        if isBossName then
            txtComp.text = self:GetRandomBossName()
            GameSDKs:TrackForeign("init", {init_id = 22, init_desc = "角色随机命名"})
        end
        if isBuildingName then
            txtComp.text = self:GetRandomCompanyName()
            GameSDKs:TrackForeign("init", {init_id = 24, init_desc = "公司随机命名"})
        end
    end)
end

function BenameUIView:ReName()
    local txtComp = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    local isBuildingName = false
    if self.m_isBuildingName then
        txtComp = self:GetComp("RootPanel/MidPanel/input_character/input", "TMP_InputField")
        self:SetText("RootPanel/MidPanel/input_character/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_COMPANY_INPUT"))
        isBuildingName = true
    end
    self:GetGo("RootPanel/MidPanel/input_character"):SetActive(isBuildingName)
    self:GetGo("RootPanel/MidPanel/input"):SetActive(not isBuildingName)

    local rerollNameBtn = self:GetComp("RootPanel/MidPanel/input_character/rerollBtn", "Button")
    self:SetButtonClickHandler(rerollNameBtn, function()
        if isBuildingName then
            txtComp.text = self:GetRandomCompanyName()
        end
    end)

    local renameCost = ConfigMgr.config_global.rename_cost
    self:SetText("RootPanel/SelectPanel/RenameBtn/cost/num", renameCost)
    local renameBtn = self:GetComp("RootPanel/SelectPanel/RenameBtn", "Button")
    --renameBtn.gameObject:SetActive(true)
    renameBtn.interactable = ResourceManger:CheckDiamond(renameCost)

    local closeBtn = self:GetComp("BgCover", "Button")
    self:SetButtonClickHandler(closeBtn, function()
        self:DestroyModeUIObject()
    end)

    self:SetButtonClickHandler(renameBtn, function()
        if self:CheckNameLawless(txtComp.text) then
            return
        end

        renameBtn.interactable = false
        ResourceManger:SpendDiamond(renameCost, nil, function()
            BenameUI:SaveName(txtComp.text, self.m_isBuildingName)
            self:DestroyModeUIObject()
        end)
    end)
end

function BenameUIView:OnPause()
    print("BenameUIView:OnPause")
end

function BenameUIView:OnResume()
    print("BenameUIView:OnResume")
end

function BenameUIView:OnExit()
    self.super:OnExit(self)
    --print("BenameUIView:OnExit")
end

function BenameUIView:SetBuildingName()
    self.m_isBuildingName = true
    local isFirst = LocalDataManager:GetCurrentRecord()["building_name"] ~= nil
    if LocalDataManager:IsNewPlayerRecord() then
        isFirst = false
    end
    if not isFirst then
        GameSDKs:TrackForeign("init", {init_id = 19, init_desc = "进入公司命名"})
    end
    self:GetGo("RootPanel/SelectPanel/ConfirmBtn"):SetActive(not isFirst)
    self:GetGo("RootPanel/SelectPanel/RenameBtn"):SetActive(isFirst)
          
    self:SetText("RootPanel/MidPanel/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_COMPANY_INPUT"))
end

------------------宠物名字------------------
function BenameUIView:RePetName(petId, cb)
    self:GetGo("RootPanel/SelectPanel/CancelBtn"):SetActive(true)
    local txtComp = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    local CancelBtn = self:GetComp("RootPanel/SelectPanel/CancelBtn", "Button")
    local petData = PetMode:GetPetLocalData(petId)
    local cfg  = PetMode:GetPetCfgByPetId(petId) 
    txtComp.text = petData.name or GameTextLoader:ReadText(cfg.name)
    CancelBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(CancelBtn, function()
        self:DestroyModeUIObject()
    end)
    self:SetText("RootPanel/MidPanel/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_PET_INPUT"))
    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
        if self:CheckNameLawless(txtComp.text) then
            return
        end
        PetInteractUI:RePetName(petId ,txtComp.text)
        self:DestroyModeUIObject()    
        if cb then
            cb()
        end
    end)
end

------------------俱乐部重命名------------------
function BenameUIView:ReClubName(cb)
    local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
    FCData.renameCount = FCData.renameCount and FCData.renameCount + 1 or 1

    local playerTeamData = FootballClubModel:GetPlayerTeamData()
    if not playerTeamData  then
        return
    end 
    self:GetGo("RootPanel/SelectPanel/CancelBtn"):SetActive(true)
    local txtComp = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    local CancelBtn = self:GetComp("RootPanel/SelectPanel/CancelBtn", "Button")
    --txtComp.text = playerTeamData.name or ""
    CancelBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(CancelBtn, function()
        self:DestroyModeUIObject()
    end)
    self:SetText("RootPanel/MidPanel/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_CLUB_INPUT"))
    
    local diamondEnough = ResourceManger:CheckDiamond(ConfigMgr.config_global.fc_rename_cost)

    local function Rename(costDiamond)
        if self:CheckNameLawless(txtComp.text) then
            return
        end

        if diamondEnough and costDiamond then
            ResourceManger:SpendDiamond(ConfigMgr.config_global.fc_rename_cost, nil, function()
                playerTeamData.name = txtComp.text
                LocalDataManager:WriteToFile()
            end)
        else
            playerTeamData.name = txtComp.text
            LocalDataManager:WriteToFile()
        end
        self:DestroyModeUIObject()
        if cb then
            cb()    
        end 
    end
    self:GetGo("RootPanel/SelectPanel/ConfirmBtn"):SetActive(not FCData.renameCount or FCData.renameCount <= 1)
    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
        Rename()
    end)
    self:GetGo("RootPanel/SelectPanel/RenameBtn"):SetActive(FCData.renameCount and FCData.renameCount > 1)
    local RenameBtn = self:GetComp("RootPanel/SelectPanel/RenameBtn", "Button")
    self:SetText("RootPanel/SelectPanel/RenameBtn/cost/num",ConfigMgr.config_global.fc_rename_cost)
    RenameBtn.interactable = diamondEnough
    self:SetButtonClickHandler(RenameBtn, function()
        Rename(true)
    end)

end

--[[
    @desc: 修改boss的名字
    author:{author}
    time:2023-08-23 17:26:32
    --@cb: 
    @return:
]]
function BenameUIView:ReBossName(cb)
    self:GetGo("RootPanel/SelectPanel/CancelBtn"):SetActive(true)
    local txtComp = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    local CancelBtn = self:GetComp("RootPanel/SelectPanel/CancelBtn", "Button")
    --txtComp.text = playerTeamData.name or ""
    CancelBtn.gameObject:SetActive(true)
    self:SetButtonClickHandler(CancelBtn, function()
        self:DestroyModeUIObject()
    end)
    self:SetText("RootPanel/MidPanel/input/Text Area/Placeholder", GameTextLoader:ReadText("TXT_MISC_NAME_INPUT"))
    
    local diamondEnough = ResourceManger:CheckDiamond(ConfigMgr.config_global.fc_rename_cost)

    local function Rename(costDiamond)
        if self:CheckNameLawless(txtComp.text) then
            return
        end

        if diamondEnough and costDiamond then
            ResourceManger:SpendDiamond(ConfigMgr.config_global.fc_rename_cost, nil, function()
                LocalDataManager:SaveBossName(txtComp.text)
                LocalDataManager:WriteToFile()
            end)
        end
        self:DestroyModeUIObject()
        if cb then
            cb()    
        end 
    end
    self:GetGo("RootPanel/SelectPanel/ConfirmBtn"):SetActive(false)
    -- self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
    --     Rename()
    -- end)
    self:GetGo("RootPanel/SelectPanel/RenameBtn"):SetActive(true)
    local RenameBtn = self:GetComp("RootPanel/SelectPanel/RenameBtn", "Button")
    self:SetText("RootPanel/SelectPanel/RenameBtn/cost/num",ConfigMgr.config_global.fc_rename_cost)
    RenameBtn.interactable = diamondEnough
    self:SetButtonClickHandler(RenameBtn, function()
        Rename(true)
    end)
end

function BenameUIView:CheckNameLawless(name)
    local isLawless = name == "" or name == nil
    if not isLawless then
        isLawless = true
        for word in string.gmatch(name, ".") do
            if word ~= "" and word ~= " " then
                isLawless = false
                break
            end
        end
    end
    if isLawless then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_LACK_INPUT"))
    end
    return isLawless
end

--[[
    @desc: 获取随机的Boss名字
    author:{author}
    time:2024-10-29 15:36:52
    @return:
]]
function BenameUIView:GetRandomBossName(isFirst)
    local result = "随机Boss名字"
    local isMan = self:CheckSelectIsManOrWoman()
    local getIndex = isMan and 1 or 51
    local nameIndex = ConfigMgr.config_global.player_character_namePool_index
    ---这里修改成根据选择的男女角色来确认名字内容
    if not isFirst then
        local nameIndexRangStr = Tools:SplitString(tostring(ConfigMgr.config_global.player_character_namePool_range), ',', true)
        local cfgMin = tonumber(nameIndexRangStr[1]) or 1
        local cfgMax = tonumber(nameIndexRangStr[2]) or 1
        if cfgMax <= cfgMin or cfgMin <= 0 then
            getIndex = cfgMax
        else
            local cfgLengthHalf = math.ceil((cfgMax - cfgMin - 1)/2) 
            
            local minIndex = cfgMin
            local maxIndex = cfgLengthHalf
            if not isMan then
                minIndex = cfgLengthHalf + 1
                maxIndex = cfgMax
            end
            getIndex = math.random(minIndex, maxIndex)
            -- if nameIndexRangStr[1] and nameIndexRangStr[2] and tonumber(nameIndexRangStr[1]) and tonumber(nameIndexRangStr[2]) then
            --     getIndex = math.random(tonumber(nameIndexRangStr[1]), tonumber(nameIndexRangStr[2]))
            -- end
        end
        
    end
    
    result = GameTextLoader:ReadText(nameIndex.."_"..tostring(getIndex))
    
    return result
end

--[[
    @desc:获取随机的公司名字
    author:{author}
    time:2024-10-29 15:37:30
    @return:
]]
function BenameUIView:GetRandomCompanyName(isFirst)
    local result = "随机公司名字"
    local getIndex = 1
    local nameIndex = ConfigMgr.config_global.office_building_namePool_index
    if not isFirst then
        local nameIndexRangStr = Tools:SplitString(tostring(ConfigMgr.config_global.office_building_namePool_range), ',', true)
        if nameIndexRangStr[1] and nameIndexRangStr[2] and tonumber(nameIndexRangStr[1]) and tonumber(nameIndexRangStr[2]) then
            getIndex = math.random(tonumber(nameIndexRangStr[1]), tonumber(nameIndexRangStr[2]))
        end
    end
    
    result = GameTextLoader:ReadText(nameIndex.."_"..tostring(getIndex))

    return result
end

function BenameUIView:CheckSelectIsManOrWoman()
    return BenameUI:GetCurBossSkinID() == 1
end

return BenameUIView