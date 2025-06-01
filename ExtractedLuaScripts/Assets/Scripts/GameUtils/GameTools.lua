GameTools = {	
	m_orgServerTime = 0,
	m_TimingValue = 0,
	m_stageRect = {},
	m_mark = {},
	---时间消耗统计
	m_timePoint = {},
}

GameEventDefine = 
{
	PersonalDev_EnergyCover = "PERSONALDEV_ENERGY_RECOVER", --个人发展的心跳恢复精力
	PersonalDev_AffairCanUse = "PERSONAL_AFFAIR_CAN_USE", --个人发展事务处理可以处理了
	PersonalDev_AffairRecover = "PERSONALDEV_AFFAIR_RECOVER",  --个人发展心跳恢复事务数
	ReCalculatePowerUsed = "RE_CALCULATE_POWER_USED", --当前电量，当前电量=总电量-消耗电量
	ReCalculateTotalPower = "RE_CALCULATE_TOTAL_POWER", --计算总电量
	OnRoomBuildingViewOpen = "OnRoomBuildingViewOpen",--RoomBuildingView打开时触发
	OnRoomBuildingViewClose = "OnRoomBuildingViewClose",--RoomBuildingView关闭时触发
	---替换BOSS Car 的模型
	ChangeBossCar = "ChangeBossCar",

	OnBuyBuilding = "OnBuyBuilding", -- 解锁场景

	RefreshCastleRankNum = "OnRefreshCastleRankNum", -- 刷新古堡排行榜排名
	RefreshCastleRankData = "OnRefreshCastleRankData", -- 刷新古堡排行榜数据

	RefreshNightClubRankNum = "OnRefreshNightClubRankNum", -- 刷新夜店排行榜排名
	RefreshNightClubRankData = "OnRefreshNightClubRankData", -- 刷新夜店排行榜数据
	
	ServerError = "OnServerError", -- 服务器出错，可能 会关闭UI

	---循环副本产品模型修改
	OnCycleProductionModelChange = "OnCycleProductionModelChange",
	---循环副本产品上架
	OnCycleProductionUnlock = "OnCycleProductionUnlock",
	---循环副本产品升级
	OnCycleProductionUpgrade = "OnCycleProductionUpgrade",
	---副本地标动画事件
	LandMarkAnimEnd = "LandMarkAnimEnd",
	---赛季通行证状态更新
	SeasonPassStateChange = "SeasonPassStateChange",
    ---赛季通行证升级
    SeasonPassLevelUp = "SeasonPassLevelUp",

	---修改对应房间的CEOActor
	ChangeCEOActor = "ChangeCEOActor",
	---通知对应房间的CEO下班(与公司一通下班)
	CEOOffWorkWithCompany = "CEOOffWorkWithCompany",
	---通知全大楼的的CEO下班(与大楼一起下班)
	CEOOffWorkWithBuilding = "CEOOffWorkWithBuilding",
	---通知对应房间的CEO上班
	CEOGoToWork = "CEOGoToWork",
	---升级对应房间的CEODesk
	UpgradeCEODesk = "UpgradeCEODesk",

	--升级CEO有对应的房间时发送消息
	RoomCEOUpgrade = "RoomCEOUpgrade",

	--有CEO宝箱可以开启时的消息通知
	UpdateCEOBoxTips = "UpdateCEOBoxTips",

	--CEO宝箱开启界面关闭的消息通知
	CEOBoxPurchaseUIViewClose = "CEOBoxPurchaseUIViewClose", 

	--房间设置UI关闭消息通知
	RoomBuildingUIViewClose = "RoomBuildingUIViewClose", 

	--活跃任务UI关闭消息通知
	ActivityUIViewClose = "ActivityUIViewClose",

	--购买下班打卡的商品消息通知
	-- ACCUMULATED_CHARGE_BUY_MSG
	ClockOut_Charge_Buy_Msg = "ClockOut_Charge_Buy_Msg",
}

local Debug = CS.UnityEngine.Debug;
 
local androidTable = {}
-- if GameDeviceManager:IsAndroidDevice() then
-- 	function print(...)
-- 		table.insert(androidTable,...)	 
-- 	end
-- end

function AndroidPrintIO()
	if GameDeviceManager:IsAndroidDevice() then
		local log = table.concat(androidTable)
		local size = string.len(log)
		local maxSize = 1000
		if size >maxSize then
			for i=0,size,maxSize do	
				print(string.sub(log,i+1,i+maxSize))
			end
		else
			print(log)
		end		
		androidTable = {}
	end	
end

local rendererName = {

}

function GameTools:GetRendererName(renderer)
	for k, v in pairs(rendererName) do
		if v == renderer then
			return k
		end
	end
end

function GameTools:LoadSwf(inst, fileName)
	if inst then
		local stageRect = LuaTools:CopyTable(GameDeviceManager:GetStageRect())

		if fileName == "background_.ges" then
			stageRect = GameDeviceManager:GetFullScreenRect()
		end
		inst:Load(fileName, stageRect.x, stageRect.y, stageRect.w, stageRect.h)		
		GameTools:RecordSwfInst(fileName, inst)
	end
end

function GameTools:RecordSwfInst(swfFileName, inst)
	rendererName[swfFileName] = inst
end

function GameTools:DestroySwfInst(inst)
	for k, v in pairs(rendererName) do
		if v == inst then
			rendererName[k] = nil
		end
	end
end
 
---------------------- Screen Operation ----------------------
function GameTools:GetScaleRateX()
	if glib.IsScreen16x9() then 
		return 1136.0/glib.SCREEN_WIDTH
	end
	if self:IsResolution4x3() then return self.GAME_SCREEN_WIDTH_4x3 / glib.SCREEN_WIDTH end
	--zzy added for android adapt
	if glib.GetPlatform() == "Android" then
		return self:ApproximateScaleWidth()
	else
		return self.GAME_SCREEN_WIDTH / glib.SCREEN_WIDTH
	end
end

function GameTools:GetScaleRateY()
	if glib.IsScreen16x9() then
		return 640.0/glib.SCREEN_HEIGHT
	end
	if self:IsResolution4x3() then return self.GAME_SCREEN_WIDTH_4x3 / glib.SCREEN_WIDTH end
	--zzy added for android adapt
	if glib.GetPlatform() == "Android" then
		return self:ApproximateScaleHeight()
	else
		return self.GAME_SCREEN_HEIGHT / glib.SCREEN_HEIGHT
	end
end

function GameTools:ApproximateScaleWidth_portrait()
	if glib.IsScreen16x9() then
		return 750.0/glib.SCREEN_WIDTH
	elseif glib.IsScreen4x3() then
		return 768.0/glib.SCREEN_WIDTH
	else
		return self.GAME_SCREEN_WIDTH / glib.SCREEN_WIDTH
	end
end

function GameTools:ApproximateScaleHeight_portrait()
	if glib.IsScreen16x9() then
		return 1335.0/glib.SCREEN_HEIGHT
	elseif glib.IsScreen4x3() then
		return 1024.0/glib.SCREEN_HEIGHT
	else
		return self.GAME_SCREEN_HEIGHT / glib.SCREEN_HEIGHT
	end
end

function GameTools:ApproximateScaleWidth()
	if glib.IsScreen16x9() then
		return 1136.0/glib.SCREEN_WIDTH
	elseif glib.IsScreen4x3() then
		return 1024.0/glib.SCREEN_WIDTH
	else
		return self.GAME_SCREEN_WIDTH / glib.SCREEN_WIDTH
	end
end

function GameTools:ApproximateScaleHeight()
	if glib.IsScreen16x9() then
		return 640.0/glib.SCREEN_HEIGHT
	elseif glib.IsScreen4x3() then
		return 768.0/glib.SCREEN_HEIGHT
	else
		return self.GAME_SCREEN_HEIGHT / glib.SCREEN_HEIGHT
	end
end

function GameTools:IsResolution16x9()
	return (glib.SCREEN_WIDTH == 1136 and glib.SCREEN_HEIGHT == 640)
end

function GameTools:IsResolution4x3()
	if glib.GetPlatform() == "Android" then
		return (glib.SCREEN_HEIGHT * 4 == glib.SCREEN_WIDTH * 3 and glib.SCREEN_WIDTH == 1024)
	else
		return (glib.SCREEN_HEIGHT * 4 == glib.SCREEN_WIDTH * 3)
	end
end

function GameTools:GetScreenWith()
	return glib.SCREEN_WIDTH
end
function GameTools:GetScreenHeight()
	return glib.SCREEN_HEIGHT
end
  

--shorten the number such as 10000 to 10k
function GameTools:FormatNumber(num)
	local result 
	num = tonumber(num)
	if num >= 1000000 * 100 then
		result = string.format("%3d"..GameConfig._M, num / 1000000)
	elseif num >= 1000000 * 10 and num < 1000000 * 100 then
		result = string.format("%.1f"..GameConfig._M, num / 1000000)
	elseif num >= 1000000 and num < 1000000 * 10 then
		result = string.format("%.1f"..GameConfig._M, num / 1000000)
	elseif num >= 1000 * 100 and num < 1000 * 1000 then
		result = string.format("%3d"..GameConfig._K, num / 1000)
	elseif num >= 1000 * 10 and num < 1000 * 100 then
		result = string.format("%.1f"..GameConfig._K, num / 1000)
	else
		result = string.format("%d", num)
	end

	return result
end

function GameTools:FormatGameSaveWithName(t, name)
	local out = name .. ' = '
	out = GameTools:FormatTable(t, out)
	return out
end

function GameTools:GetDistanceOfTwoCity(startx, starty, stopx, stopy)
    local start_x, start_y = GameTools:ConvertGridToMapPos(startx, starty)
    local stop_x, stop_y   = GameTools:ConvertGridToMapPos(stopx, stopy)

 	return LuaExtension:Math_GetTwoPointDisTance(start_x, start_y, stop_x, stop_y)
end

-------------------------------- table operation -------------------------------------
function GameTools:PrintTab(n)
	for i = 1, n do
		print('\t')
	end
end

function GameTools:PrintTableValue(v, depth)
	if type(v) == 'string' then
		print(string.format('%q', v))
	elseif type(v) == 'number' then
		print(v)
	elseif type(v) == 'boolean' then
		print((v and 'true') or 'false')
	elseif type(v) == 'table' then
		GameTools:PrintTable(v, depth)
	else
		print('Wrong value type for data table!', type(v))
	end
end

function GameTools:PrintTable(t, depth)
	if GameConfig.enableDbgOutput then
		local depth = depth or 1
		print('{\n')
		for k, v in pairs(t) do
		 	GameTools:PrintTab(depth)
		 	print('[')
		 	GameTools:PrintTableValue(k, depth + 1)
		 	print('] = ')
		 	GameTools:PrintTableValue(v, depth + 1)
		 	print(',\n')
		end
		GameTools:PrintTab(depth-1)
		print('}')
	end
end

function GameTools:FormatTableValue(v, out)
	if type(v) == 'string' then
		out = out .. string.format('%q', v)
	elseif type(v) == 'number' then
		out = out .. v
	elseif type(v) == 'boolean' then
		out = out .. ((v and 'true') or 'false')
	elseif type(v) == 'table' then
		out = GameTools:FormatTable(v, out)
	else
		error('Wrong value type for data table!')
	end
	return out	
end

function GameTools:FormatTable(t, out)
	out = out .. '{\n'
	for k, v in pairs(t) do
		out = out .. '[' 
		out = GameTools:FormatTableValue(k, out) 
		out = out .. '] = ' 
		out = GameTools:FormatTableValue(v, out)
		out = out .. ',\n'
	end
	out = out .. ' }\n'
	return out
end

function GameTools:OutputTable(t, name)
	if GameConfig.enableDbgOutput then
		print(name..' = ')
		GameTools:PrintTable(t)
		AndroidPrintIO()	
	end
end

-------------------------------- table operation -------------------------------------
function GameTools:InitDeviceOPTSetting()
	if self:IsLowLevelDevice() or self:Is4sSeriesDevice() or GameDeviceManager:IsAndroidDevice() then
		--print("now use poor effect!")
	end

	--fps limit
	if self:IsHighFPSDevice() then
	end

	if GameDeviceManager:IsAndroidDevice() then
	end
end

--http://zh.wikipedia.org/wiki/IOS%E8%AE%BE%E5%A4%87%E5%88%97%E8%A1%A8
function GameTools:Is4sSeriesDevice()
	local device_name = glib.Gelib_SysDeviceVersion()
--	print("Now we check phone: "..device_name)
	if device_name == "iPhone4,1" --iphone4s
		or device_name == "iPod5,1"
		or device_name == "ipad2,1"
		or device_name == "ipad2,2"
		or device_name == "ipad2,3"
		or device_name == "ipad2,4"
		or device_name == "ipad2,5"
		or device_name == "ipad2,6"
		or device_name == "ipad2,7"
		or device_name == "iPad2,1"
		or device_name == "iPad2,2"
		or device_name == "iPad2,3"
		or device_name == "iPad2,4"
		or device_name == "iPad2,5"
		or device_name == "iPad2,6"
		or device_name == "iPad2,7"
		then
		return true
	end
	return false
end

function GameTools:IsHighFPSDevice()
	local device_name = glib.Gelib_SysDeviceVersion()
	--print("device_name:",device_name)
	if glib.GetPlatform() == "Android" then
		return true
	else
		return false
	end
end

function GameTools:IsLowLevelDevice()
	local is_low_level = false
	local device_name = glib.Gelib_SysDeviceVersion()
--	print("Now we check phone: "..device_name)
	if device_name == "iPhone1,2" --iphone3g
		or device_name == "iPhone2,1" --iphone3gs
		or device_name == "iPhone3,1" --iphone4
		or device_name == "iPhone3,2"
		or device_name == "iPhone3,3" --iphone4
		or device_name == "iPod1,1" --ipod1
		or device_name == "iPod2,1" --ipod2
		or device_name == "iPod3,1" --ipod3
		or device_name == "iPod4,1" --ipod4
		or device_name == "iPad1,1" --iPad1
		or device_name == "iPod2,1" --ipod2
		or device_name == "iPad1,1"
		or device_name == "ipad1,1"
		then
		is_low_level = true
		--print("Now we get level device "..device_name)
	end
	return is_low_level
end

function GameTools:GetSwfTopmostMenu(render)
	local found = false
	local menuName = ""
	local rendererName = ""
	if render and render.GSF_GetTopMostEntity then
		menuName = render:GSF_GetTopMostEntity()
		rendererName = self:GetRendererName(render)
		if menuName ~= "" then
			found = true
		end
	end

	return found, menuName, rendererName
end

function GameTools:PrintMemoryUsage(extraInfo)
	local extraInfo = extraInfo or ""
	local memKB = collectgarbage("count")
	local memMB = math.ceil(memKB / 100) / 10
	--print(extraInfo .. " MemUse = " .. memMB .. " MB")
end

function GameTools:MarkNeedImplement()
	if not GameConfig:IsDebugMode() or not GameConfig:IsEnableDebugTrace() then return end
	-- if true then return end

	local traceback = self:SplitEx(debug.traceback("", 2), "\n")
	local traceinfo = self:TrimEx(traceback[2]);

	if self.m_mark[traceinfo] then return end;
	self.m_mark[traceinfo] = true;

	local traceinfoTab = self:SplitEx(traceinfo, ":");
	local file = traceinfoTab[1];
	local line = traceinfoTab[2];
	local method = string.gmatch(traceinfo, "\'(.*)\'")();
	method = string.gsub(method, file..".", "");
	local info = string.format("LUA file %s:%s: %s this method needs to be implemented!", file, line, method);
	-- Debug.LogWarning(info);
	--print(info);
end

function GameTools:CostTime(method, name, ...)
	if type(method) ~= "function" or type(name) ~= "string" then return end
	local start = GameTimeManager:GetDeviceTimeInMilliSec()
	-- print(string.format("%s start time : %.4f", name, start));
	method(...);
	local now = GameTimeManager:GetDeviceTimeInMilliSec()
	-- print(string.format("%s end time   : %.4f", name, now));
	--print(string.format("%s cost time  : %.4f", name, now - start));
end

---添加计时的开始时间
function GameTools:AddTimePoint(name)
	self.m_timePoint[name] = os.clock()
end

---计算耗时
function GameTools:CalcTimePointCost(name)

	local start = self.m_timePoint[name]
	if start then
		local now = os.clock()
		print(string.format("代码耗时---- %s 耗时: %.4f", name, now - start))
	else
		print(string.format("代码耗时---- %s 无法计算耗时,缺少开始时间的记录", name))
	end
end