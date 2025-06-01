
require("ConfigData.ConfigPit")
require("ConfigData.ConfigFuncVariable")
local GameMainCity = GameTableDefine.GameMainCity
local SoundEngine = GameTableDefine.SoundEngine 
local Guide = GameTableDefine.Guide
local GameTopPopupMenu = GameTableDefine.GameTopPopupMenu
local GameLeague = GameTableDefine.GameLeague
local Item = GameTableDefine.Item
local User = GameTableDefine.User

GameBuildingPos = {
	m_localPosID = nil,
	m_posUID = nil,
	m_groupUID = nil,
	m_buildingObj = nil,
	m_selectedConfigID = nil,
	m_buildingtobeBuilt = nil,
	m_isOpPanelShowing = false
}

function GameBuildingPos:New(localPosID, posUID, groupUID)
	local o = {
	}
	setmetatable(o, self)
	self.__index = self
	o:Init(localPosID, posUID, groupUID)
	return o
end

function GameBuildingPos:Init(localPosID, posUID, groupUID)
	self.m_localPosID = localPosID
	self.m_posUID = posUID
	self.m_groupUID = groupUID
end

function GameBuildingPos:Remove()
	if self.m_buildingObj then
		self.m_buildingObj:RemoveObj()
		self.m_buildingObj = nil
	end
end

function GameBuildingPos:OBJ_GetPosID()
	return self.m_localPosID
end

function GameBuildingPos:OBJ_GetPosUID()
	return self.m_posUID
end

function GameBuildingPos:OBJ_HasBuilding()
	return self.m_buildingObj ~= nil
end

function GameBuildingPos:SetBuilding(buildingObj)
	self.m_buildingObj = buildingObj
end

function GameBuildingPos:OBJ_IsRealBuilding()
	return self.m_buildingObj and self.m_buildingObj:OBJ_GetBuildingUID() ~= -1
end

function GameBuildingPos:SetFakeBuilding(buildingObj)
	self.m_buildingtobeBuilt = buildingObj
end

function GameBuildingPos:GetFakeBuildingObj()
	return self.m_buildingtobeBuilt
end

function GameBuildingPos:OBJ_GetBuildingObj()
	return self.m_buildingObj
end

function GameBuildingPos:OBJ_SetEventBoxObj(obj)
    self.m_eventBox = obj
end

function GameBuildingPos:OBJ_GetEventBoxObj()
    return self.m_eventBox
end

function GameBuildingPos:OBJ_GetPosData()
end

function GameBuildingPos:OBJ_GetPosConfigData()
	return config_pits[tonumber(self.m_posUID)]
end

function GameBuildingPos:OBJ_IsPosofProduction()
	local configData = self:OBJ_GetPosConfigData()
	if configData then
		return #(configData.buildings) > 1
	else
		return false
	end
end

function GameBuildingPos:GetBuildableList()
	local configData = self:OBJ_GetPosConfigData() or {}
	return configData.buildings
end

function GameBuildingPos:ShowEmptyNormalBuildingOpPanel()
	local buildingLevel = 0
	local localPosID = self:OBJ_GetPosID()
	local buildingConfigID = self:GetBuildableList()[1]
	self.m_selectedConfigID = buildingConfigID

	print("buildingConfigID: ", buildingConfigID)
	local buildingName = GameBuildings:GetBuildingLocalizedNameByConfigID(buildingConfigID)
	local buildingObj = GameMainCity:CreateBuildingObj(buildingConfigID, localPosID)
	local buildButtonName = "CONSTRUCT_BUILDING"

	if buildingObj:IsBuildingLocked() then
		buildButtonName = "BUILD_DISABLE"
	end

	_buttonArray =  {"BUILDING_DETAIL", buildButtonName}

	local buttonNumber, buttonNameString = GameBuildings:GenerateOperationButtonsString(_buttonArray)
	local buttonStatusString = GameBuildings:GenerateOperationButtonStatus(nil, localPosID, buttonNameString)
	GameMainCity:ShowOperationPanel(localPosID, buildingLevel, buildingName, buttonNumber, buttonNameString, buttonValueString, buttonStatusString, false)
	Guide:OnEvent("GUIDE_EVENT_SHOW_EMPTY_NORMAL_BUILDING_PANEL")
end

function GameBuildingPos:ShowEmptyResourceBuildingOpPanel()
	local buildingLevel = 0
	local buildingName = ""
	local localPosID = self:OBJ_GetPosID()

	self.m_selectedConfigID = nil

	local isTentEnabled = not BuildingsTent:IsReachedCurrentBuildingLimit() 
	local isMineEnabled = GameBuildings:IsBuildingAvailable("mine")
	local isQuarryEnabled = GameBuildings:IsBuildingAvailable("quarry")
	local tentButtonName = isTentEnabled and "BUILDING_TENT" or "TENT_DISABLE"
	local mineButtonName = isMineEnabled and "BUILDING_MINE" or "MINE_DISABLE"
	local QuarryButtonName = isQuarryEnabled and "BUILDING_QUARRY" or "QUARRY_DISABLE"
	_buttonArray =  {"BUILDING_LOGGINGCAMP", "BUILDING_FARM", tentButtonName, mineButtonName, QuarryButtonName}

	local buttonNumber, buttonNameString = GameBuildings:GenerateOperationButtonsString(_buttonArray)
	local buttonStatusString = GameBuildings:GenerateOperationButtonStatus(nil, localPosID, buttonNameString)
	GameMainCity:ShowOperationPanel(localPosID, buildingLevel, buildingName, buttonNumber, buttonNameString, buttonValueString, buttonStatusString, false)
	Guide:OnEvent("GUIDE_EVENT_SHOW_EMPTY_POS_OP_PANEL")
end

function GameBuildingPos:OBJ_ShowOPPanel()
	self.m_isOpPanelShowing = true
	if self:OBJ_IsPosofProduction() then
		self:ShowEmptyResourceBuildingOpPanel()
	else
		self:ShowEmptyNormalBuildingOpPanel()
	end
end

function GameBuildingPos:ClickeOperationButtonByName(functionName)
	if self:OBJ_HasBuilding() and self:OBJ_IsRealBuilding() then
		local buildingObj = self:OBJ_GetBuildingObj()
		buildingObj:OBJ_EnterFunctionByName(functionName)
	else
		local clickedButtonName = functionName
		local tempObj = nil
		if clickedButtonName == "BUILDING_DETAIL" then
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowBuildingDetail()
		elseif clickedButtonName == "BUILD_DISABLE" then
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowLockBuildingInfo()
		elseif clickedButtonName == "CONSTRUCT_BUILDING" then
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_TENT" or clickedButtonName == "TENT_DISABLE" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_TENT_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("tent")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_FARM" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_FARM_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("farm")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_MINE" or clickedButtonName == "MINE_DISABLE" then
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("mine")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_QUARRY" or clickedButtonName == "QUARRY_DISABLE" then
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("quarry")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_LOGGINGCAMP" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_LOGGINGCAMP_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("loggingCamp")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		end
		print("create fake building: ", self.m_selectedConfigID)
		self:SetFakeBuilding(tempObj)

		GameMainCity:HideAllOpPanel()
		GameMainCity:HideAllArrows()
	end
end

function GameBuildingPos:ClickeOperationButton(functionIndex)
	if self:OBJ_HasBuilding() and self:OBJ_IsRealBuilding() then
		local buildingObj = self:OBJ_GetBuildingObj()
		buildingObj:OBJ_EnterFunction(tonumber(functionIndex))
	else
		local clickedButtonName = _buttonArray[tonumber(functionIndex)]
		local tempObj = nil
		if clickedButtonName == "BUILDING_DETAIL" then
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowBuildingDetail()
		elseif clickedButtonName == "CONSTRUCT_BUILDING" or clickedButtonName == "BUILD_DISABLE" then
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_TENT" or clickedButtonName == "TENT_DISABLE" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_TENT_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("tent")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_FARM" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_FARM_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("farm")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_MINE" or clickedButtonName == "MINE_DISABLE" then
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("mine")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_QUARRY" or clickedButtonName == "QUARRY_DISABLE" then
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("quarry")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		elseif clickedButtonName == "BUILDING_LOGGINGCAMP" then
			Guide:OnEvent("GUIDE_EVENT_SHOW_LOGGINGCAMP_BUILDING_MENU")
			self.m_selectedConfigID = GameMainCity:GetBuildingConfigIDByName("loggingCamp")
			tempObj = GameMainCity:CreateBuildingObj(self.m_selectedConfigID, self:OBJ_GetPosID())
			tempObj:ShowUpgradePanel()
		end

		self:SetFakeBuilding(tempObj)

		GameMainCity:HideAllOpPanel()
		GameMainCity:HideAllArrows()
	end
end

function GameBuildingPos:ConstructBuilding(useRssItem)
	local posUID = self:OBJ_GetPosUID()
	local currentBuilding = GameMainCity:GetCurrentBuildingObj()
	local currentBuildingRecord = GameBuildings:GetCurrentBuildingRecords()

	local rssItems = nil
	local rssTypes = {}
    if useRssItem then
    	rssItems = {}
    	for k, v in pairs(currentBuildingRecord.rssItemstobeUsed or {}) do
    		table.insert(rssItems, {item_id = v.itemID, amount = v.itemNumber})
    		local rssType = Item:GetResourceItemValue(v.itemID)
    		rssTypes[rssType] = (rssTypes[rssType] or 0) + (v.itemNumber * v.resAmount)
    	end
    end

	local callback = function(response)  
		GameBuildings:FX_CloseUpgradePanel()
		self:SetFakeBuilding(nil)
 
		if tonumber(self.m_selectedConfigID) == GameMainCity:GetBuildingConfigIDByName("guardian") then
			self:Remove()
		end
		-- GameMainCity:RefreshCity(response) --wenhao bug #1445
		GameMainCity:RefreshCityByBuildings(response.buildings, response.pits)
		GameMainCity:FX_RefreshBuildings()
		local buildingObj = GameMainCity:GetBuildingObjectByPos(posUID)
		SoundEngine:playEffect(SoundConst.SFX_BUILD, false)
		if not GameLeague:HasJoinUnion() and buildingObj:OBJ_NeedtoShowSpeedupPop() then
			buildingObj:OBJ_AutoPopSpeedup()
		end
		if useRssItem then
			GameTopPopupMenu:ShowResourceBurst(rssTypes, nil, true)
		end
		Guide:OnEvent(Guide.EVENT_BUILDING_CONSTRUCTING, {self:OBJ_GetPosID()})
		if GameConfig:IsGuideEnabled() then
			if tonumber(self.m_selectedConfigID) == GameMainCity:GetBuildingConfigIDByName("factory") or
			tonumber(self.m_selectedConfigID) == GameMainCity:GetBuildingConfigIDByName("academy") or 
			tonumber(self.m_selectedConfigID) == GameMainCity:GetBuildingConfigIDByName("herohall") or
			tonumber(self.m_selectedConfigID) == GameMainCity:GetBuildingConfigIDByName("guardian") then
				GameTableDefine.GameGuideMenu:LockInput()
			end
		end
    end

	local buildingConfigID = self.m_selectedConfigID or self:GetBuildableList()[1]
	print("m_selectedConfigID: ", buildingConfigID, posUID)
    local requestTable = {
        url = "user.buildingHandler.build",
        msg = {
        	c_building_id = buildingConfigID,
            pit = tonumber(posUID),
            items = rssItems
        },
        callback = callback,
    }

    local userLevel = User:GetUserLevel()
    local requiredLevel = tonumber(config_func_variable["cityhall_unlock_more_point"])

    if userLevel < requiredLevel then
    	local hint = GameTextLoader:ReadText("LC_WORD_OPEN_UP_MORE_LAND_UNLOCK")
    	local value = requiredLevel
    	hint = LuaTools:FormatString(hint, value)
    	
    	if GameMainCity:IsFarm(self.m_selectedConfigID) and GameMainCity:GetFarmNumber() >= 4 then
    		GameTopPopupMenu:ShowTipsWithoutTitle(hint)
    	elseif GameMainCity:IsSawmill(self.m_selectedConfigID) and GameMainCity:GetSawmillNumber() >= 4 then
    		GameTopPopupMenu:ShowTipsWithoutTitle(hint)
    	else
    		GameNetwork:Socket_SendRequest(requestTable)
    	end
    else
    	GameNetwork:Socket_SendRequest(requestTable)
    end
end

function GameBuildingPos:OBJ_IsOpPanelShowing()
	return self.m_isOpPanelShowing
end

function GameBuildingPos:OBJ_HideOpPanel()
	self.m_isOpPanelShowing = false
	local localPosID = self:OBJ_GetPosID()
	GameMainCity:HideOperationPanel(localPosID)
end

function GameBuildingPos:MarkPos()
	local localPosID = self:OBJ_GetPosID()
	GameMainCity:ShowArrowAnimation(localPosID, true)
end

function GameBuildingPos:IsLocked()
	local groupUID = self.m_groupUID
	return GameMainCity:IsResourceBuildingPosGroupLocked(groupUID)
end

function GameBuildingPos:IsEmpty()
	return not self:OBJ_HasBuilding()
end

function GameBuildingPos:CanBuildThisBuilding(buildingConfigID)
	local buildableList = self:GetBuildableList() or {}

	for k, v in pairs(buildableList) do
		if tostring(v) == tostring(buildingConfigID) then
			return true
		end
	end

	return false
end

function GameBuildingPos:OnFscommand(cmd, param)

end

