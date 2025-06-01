---@class CheatUI
local CheatUI = GameTableDefine.CheatUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local EventManager = require("Framework.Event.Manager")
local UnityHelper = CS.Common.Utils.UnityHelper
local rapidjson = require("rapidjson")

local cheatingCommandForm = 
{
    ["addcash"] =                       {type = 1, Info = "加绿钞", num = 1000},
    ["addeuro"] =                       {type = 2, Info = "加欧元", num = 1000},
    ["addstar"] =                       {type = 3, Info = "加星星", num = 1},
    ["adddiamond"] =                    {type = 4, Info = "加钻石", num = 1000},
    ["addlicense"] =                    {type = 5, Info = "加许可证" , num = 1},
    ["clearbuy"] =                      {type = 6, Info = "清理商城购买"},
    ["unlockallfurniture"] =            {type = 7, Info = "房间中建筑全解锁,退出后生效"},
    ["openrankingactivity"] =           {type = 8, Info = "模拟开启一个排行活动", num = 5, num_2 = 10},
    ["openfragmentactivity"] =          {type = 9, Info = "模拟开启一个碎片(火鸡币)活动性", num = 5, num_2 = 10},
    ["addfragment"] =                   {type = 10, Info = "增加活动碎片", num = 1},
    ["resetgame"] =                     {type = 11, Info = "重置游戏"},
    ["changeingametime"] =              {type = 12, Info = "改变游戏内时间", num = 1},
    ["addexp"] =                        {type = 13, Info = "增加本区域公司经验", num = 1},
    ["copyexcption"] =                  {type = 14, Info = "将异常拷贝到本设备剪切板"},
    ["requestarchive"] =                {type = 15, Info = "向服务器请求存档", num = "192.168.110.249", num_2 = "8000"},
    ["employeebehavior"] =              {type = 16, Info = "控制员工行为", num = 1},
    ["chatevent"] =                     {type = 17, Info = "对话事件触发", num = 1},
    ["addpetfeed"] =                    {type = 18, Info = "加宠物零食", num = 1001, num_2 = 10},
    ["addopenranking"] =                {type = 19, Info = "加冲榜积分", num = 1},
    ["buygoods"] =                      {type = 20, Info = "购买商品", num = 1001, num_2 = 1},
    ["openAccChargeAC"] =               {type = 21, Info = "开启一个5分钟的累充活动", num = 5},
    ["openlimitpack"] =                 {type = 22, Info = "开一个限时礼包活动", num = 5},
    ["openInstanceAC"] =                {type = 23, Info = "开启一个x分钟的副本活动", num = 5, num_2 = 1},
    ["inchangestate"] =                 {type = 24, Info = "副本告诉玩家修改状态", num = 5},
    ["addInstanceCoin"] =               {type = 25, Info = "增加副本货币数量", num = 10000},
    ["addFCSP"] =                       {type = 26, Info = "增加足球俱乐部体力", num = 5},
    ["addFCMatchCharge"] =              {type = 27, Info = "增加足球俱乐部比赛机会", num = 1},
    ["openDayGif"] =                    {type = 28, Info = "打开每日礼包"},
    ["changeInstanceTime"] =            {type = 29, Info = "改变副本时间"},
    ["RefreshInstanceAutoTime"] =       {type = 30, Info = "刷新副本自动弹出进入面板的时间"},
    ["OpenPersonalInfo"] =              {type = 31, Info = "测试进入个人发展的UI界面"},
    ["GetAllDressUpItem"] =             {type = 32, Info = "获取所有角色换装",num = 1},
    ["GMDefineABTestGroup"] =            {type = 35, Info = "制定ABTest分组",num = 1},
    ["GMModifyCountryCode"] =           {type = 36, Info = "PayerMax修改地区码", str = "US"},
    ["ChangeArchive"] =                 {type = 38, Info = "本地更换存档"},
    ["AddInstanceTaskScore"] =          {type = 39, Info = "增加副本任务积分",num = 10},
    ["AddPiggyBankValue"] =             {type = 40, Info = "增加存钱罐积分",num = 50},
    ["PlayTimeLine"] =                  {type = 41, Info = "播放指定timeline",str = "Story_1_2"},
    ["OpenCycleInstanceAC"] =           {type = 42, Info = "开启一个x分钟的循环副本活动",num = 5, num_2 = 4, num_3 = 0},
    ["addTicket"] =                     {type = 43, Info = "增加广告卷", num = 5},
    ["addWheelTicket"] =                {type = 44, Info = "增加转盘卷", num = 5},
    ["addCycleInstanceCoin"] =          {type = 45, Info = "增加循环副本货币 (用科学计数法表示)", num = 5000},
    ["GiftCodeSend"]        =           {type = 46, Info = "本地测试礼包发放的功能(默认发放15钻石)", num = 5000, num_2 = 3},
    ["ApplyRecommendedQualityLevel"] =  {type = 47, Info = "应用推荐渲染等级设置(按内存区分)"},
    ["clearSurvey"] =                   {type = 48, Info = "删除问卷数据"},
    ["addCycleInstanceScore"] =         {type = 49, Info = "增加循环副本里程碑积分", num = 5000},
    ["InitFirstPurchase"] =             {type = 51, Info = "开启重置首冲双倍活动(默认5分钟)", num = 5},
    ["OpenStatisticUI"] =               {type = 52, Info = "打开个人名片系统UI"},
    -- bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName
    ["OpenOtherStatisticUI"] =          {type = 53, Info = "打开个人名片系统UI", bossSkin = "Boss_002", playerName = "test", start = 100, contry_id = 1, curMoneyEff = 567, sceneID = 800, sceneName = "猪镇"},
    ["ChangeCycleInstanceBPResCount"] = {type = 54, Info = "修改循环副本蓝图材料数量", num = 64,num_2 = 1},
    ["OpenRankUI"] =                    {type = 55, Info = "打开排行榜UI"},
    ["OpenPassUI"] =                    {type = 56, Info = "打开通行证界面(时间默认5分钟,类型默认为1)",num=5,str_2 = "tuibiji",str_3 = "normal"},
    ["ResetSeasonPassTask"] =           {type = 57, Info = "重置通行证任务模块数据"},
    ["GMModifyTaskTime"] =              {type = 58, Info = "修改通行证任务的重置时间(想到剩余多少秒最少60秒)", num = 1, num_2 = 60},
    ["AddSeasonGameTicket"] =           {type = 59, Info = "添加通行证小游戏门票", num = 5},
    ["ChangeLocalTime"] =                {type = 60, Info = "修改游戏中获取到的当前时间(min)", num = 5},
    ["ParseResotreShopIDItems"] =        {type = 61, Info = "解析补单数据相关接口测试", num = 5000, data = {}},
    ["GMRestoreCallback"] =             {type = 62, Info = "GM直接补单的接口调用", str = "cy3_pack_2", data = {}},
    ["ResetPopView"] =                   {type = 63, Info = "弹窗状态重置"},
    ["GMDefineABGroup"] =            {type = 64, Info = "切换AB分组",num = 1},
    ["OpenCEOBox"] =             {type = 65, Info = "开启CEO盒子", str = "normal", num_2 = 1},
    ["AddCEOKey"] =             {type = 66, Info = "添加CEO开启盒子的钥匙", str = "normal", num_2 = 1},
    ["AddCEOSpecificCard"] =             {type = 67, Info = "添加CEO指定CEOID卡牌", num = 1, num_2 = 1},
    ["GMUpdateCEOLvl"] =             {type = 68, Info = "给指定CEO一个指定的等级", num = 1, num_2 = 1},
    ["GMResetFreeBoxCD"] =             {type = 69, Info = "重置CEO免费宝箱的CD和次数"},
    ["GMGetActivityGift"] =             {type = 70, Info = "获取活跃任务的奖励", str = "day", num_2 = 1},
    ["SendSaveDataToEditor"] =             {type = 71, Info = "将存档传输到局域网内的编辑器中"},
    ["GetSaveDataFromEditor"] =             {type = 75, Info = "从局域网内的编辑器接收存档"},
    ["GMOpenClockOutActivity"] =             {type = 72, Info = "GM开启一个下班打卡活动", num = 1},
    ["AddClockOutTickets"] =             {type = 73, Info = "添加下班打卡活动的门票数量", num = 5},
    ["nil"] =                           {type = 999, Info = "输入错误"},
}

function CheatUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CHEAT_UI, self.m_view, require("GamePlay.Common.UI.CheatUIView"), self, self.CloseView)
    return self.m_view
end

function CheatUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CHEAT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--写入信息列表
function CheatUI:WriteToInfoList(info)
    if not self.infoList then
        self.infoList = {"请输入指令"}
    end
    while (Tools:GetTableSize(self.infoList) > 9) do
        table.remove(self.infoList, Tools:GetTableSize(self.infoList))
    end
    table.insert(self.infoList, 1, info)
    return self.infoList
end

--获取信息列表
function CheatUI:GetInfoList()
    if not self.infoList then
        self.infoList = {"请输入指令"}
    end
    return self.infoList
end

--处理输入的信息
function CheatUI:ProcessingOutputInformation(inputInfo)
    local info = Tools:SplitString(tostring(inputInfo), ',', true)
    local curr = {}    
    for k,v in pairs(cheatingCommandForm) do
        if string.lower(k) == string.lower(info[1]) then
            for i,o in pairs(v) do
                curr[i] = o
            end            
            if info[2] and type(info[2]) == "number" and curr.num then
                curr.num = tonumber(info[2] or v.num)
            elseif info[2] and type(info[2]) == "string" and curr.str then
                curr.str = info[2]
            end
            if info[3] and type(info[3]) == "number" and curr.num_2 then
                curr.num_2 = tonumber(info[3] or v.num_2)
            elseif info[3] and type(info[3]) == "string" and curr.str_2 then
                curr.str_2 = info[3]
            end
            if info[4] and type(info[4]) == "number" and curr.num_3 then
                curr.num_3 = tonumber(info[4] or v.num_3)
            elseif info[4] and type(info[4]) == "string" and curr.str_3 then
                curr.str_3 = info[4]
            end
            return curr
        end
    end
    return cheatingCommandForm["nil"]
end

--通过传来的信息执行相应的方法
function CheatUI:Implement(cfg)   
    local info = cfg.Info
    local time = GameTimeManager:FormatTimeToHMS(GameTimeManager:GetCurrentServerTime(true))
    if cfg.type == 999 then
        info =  "<color=#FF0000>" .. cfg.Info .. ",时间:".. time .. "</color>"
        self:WriteToInfoList(info)
        return
    elseif cfg.type == 1 then
        EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
        if cfg.num > 0 then
            GameTableDefine.ResourceManger:AddCash(cfg.num, nil, nil, true, true)
        else
            GameTableDefine.ResourceManger:SpendCash(math.abs(cfg.num), nil, nil)
        end
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 2 then
        EventManager:DispatchEvent("FLY_ICON", nil, 6, nil)
        GameTableDefine.ResourceManger:AddEUR(cfg.num, nil, nil, true, true)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 3 then
        GameTableDefine.StarMode:StarRaise(cfg.num)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 4 then
        EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
        if tonumber(cfg.num) > 0 then
            GameTableDefine.ResourceManger:AddDiamond(cfg.num, nil, nil, true)
        else
            GameTableDefine.ResourceManger:SpendDiamond(math.abs(cfg.num), nil, nil)
        end
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 5 then
        GameTableDefine.ResourceManger:AddLicense(cfg.num, nil, function()
            GameTableDefine.MainUI:RefreshLicenseState()
        end, true)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 6 then
        GameTableDefine.ShopManager:CleanShopData()
        GameTableDefine.PetMode:CleanEntiey()
    elseif cfg.type == 7 then
        GameTableDefine.FloorMode:BeNB()
        EventManager:DispatchEvent("UI_NOTE", "退出游戏后生效")
    elseif cfg.type == 8 then
        GameTableDefine.ActivityRankDataManager:GMAddPlayerRankScore()
    elseif cfg.type == 9 then
        --2025-3-14注释，现在已经不开启该活动了
        -- GameTableDefine.TimeLimitedActivitiesManager:EnableFragmentActivity(cfg.num, cfg.num_2)
        info = cfg.Info .. ",活动时间:" .. cfg.num .. ",领奖时间时间:" .. cfg.num_2
    elseif cfg.type == 10 then
        GameTableDefine.FragmentActivityUI:AddFragment(nil, cfg.num)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 11 then
        LocalDataManager:ClearUserSave()
        GameStateManager:RestartGame()
    elseif cfg.type == 12 then
        GameTableDefine.GameClockManager.offsetTime = GameTableDefine.GameClockManager.offsetTime + cfg.num * 60
        info = cfg.Info .. ",加" .. cfg.num .. "小时"
    elseif cfg.type == 13 then
        local data = GameTableDefine.CompanyMode:GetData()
        local companyConfig = ConfigMgr.config_company
        local needSave = false
        local expAdd = 10000 * cfg.num
        for k,v in pairs(data or {}) do
            local currConfig = companyConfig[v.company_id]
            if not v.currExp then
                v.currExp = 0
            end
            if not v.level then
                v.level = ConfigMgr.config_company[v.company_id].levelBegin
            end
            v.currExp = math.floor(v.currExp + expAdd)
        end
        info = cfg.Info .. ",每个公司加" .. expAdd
    elseif cfg.type == 14 then
        local excp = ExceptionHandler:GetException()
        local rapidjson = require("rapidjson")
        local strExcp = rapidjson.encode(excp, {pretty = true, sort_keys = true})
        GameDeviceManager:CopyToClipboard(strExcp)
        EventManager:DispatchEvent("UI_NOTE", "程序异常已经拷贝到本设备剪贴板中。")
    elseif cfg.type == 15 then
        -- local str = "http://192.168.110.249:8000/share/wuyeSave/PlayerSaves.txt"
        local str = "http://"..cfg.num..(cfg.num_2 and (":" .. cfg.num_2) or "").."/share/wuyeSave/PlayerSaves.txt"
        -- local ipStr = self:GetComp("Cheat/CheatButton/ReadData/input", "TMP_InputField").text
        -- local clipStatus1 = self:GetComp("Cheat/CheatButton/ReadData/Image/Status1", "Text")
        -- local clipStatus2 = self:GetComp("Cheat/CheatButton/ReadData/Image/Status2", "Text")
        -- if not ipStr or string.len(ipStr) ~= 0 then
        --     str = "http://"..ipStr.."/share/wuyeSave/PlayerSaves.txt"
        -- end
        local clipBoardStr1 = "请求地址为:"..str
        local clipBoardStr2 = "开始请求存档"
        local info1 = clipBoardStr1.."  "..clipBoardStr2
        -- self:WriteToInfoList(info1)
        -- clipStatus1.text = clipBoardStr1
        -- clipStatus2.text = clipBoardStr2
        -- 存档请求
        local requestTable = {
            callback = function(response)
                print(response)
                if response ~= nil then
                    local data = nil
                    if type(response) == "string" then
                        if string.len(response) > 0 then
                            local dataStr = response
                            xpcall(function()
                                local rapidjson = require("rapidjson")
                                dataStr = CS.Common.Utils.AES.Decrypt(dataStr)
                                data = {record = rapidjson.decode(dataStr)}
                            end,function(error)
                                local rapidjson = require("rapidjson")
                                data = rapidjson.decode(dataStr)
                            end)
                        else
                            printError("读取存档失败,存档为空")
                            return
                        end
                    elseif type(response) == "table" then
                        if response.table_name == "RecordData" then
                            data = response
                        else
                            printError("读取存档失败")
                            return
                        end
                    else
                        printError("读取存档失败")
                        return
                    end
                    if data then
                        --这里是整体替换玩家存档，包含玩家的userid也使用
                        -- LocalDataManager:ReplaceRecordData(data)
                        --这里使用的是玩家的数据存档，userid还是使用当前本机的
                        LocalDataManager:ReplaceLocalDataByGM(data)
                        clipBoardStr1 = "替换存档成功，重新启动客户端生效"
                        print(clipBoardStr1)
                        info = cfg.Info..clipBoardStr1
                        info =  "<color=#D9D919>" .. info .. ",时间:".. time .. "</color>"
                        self:WriteToInfoList(info)
                        -- CS.UnityEngine.Application.Quit()
                        UnityHelper.ApplicationQuit()
                        return
                    else
                        clipBoardStr1 = "获取的存档为空或者异常"
                    end
                    -- clipStatus1.text = clipBoardStr1
                    -- clipStatus2.text = clipBoardStr2
                    info = cfg.Info..clipBoardStr1
                else
                    info = cfg.Info.."请求无响应:"..str
                end
            end
        }
        GameNetwork:HTTP_PublicSendRequest(str, requestTable, nil, "GET")
    elseif cfg.type == 16 then
        local ActorManager = require "CodeRefactoring.Actor.ActorManager"
        local tab = {
            {"厕", ActorManager.FLAG_EMPLOYEE_ON_TOILET},
            {"休", ActorManager.FLAG_EMPLOYEE_ON_REST},
            {"会", ActorManager.FLAG_EMPLOYEE_ON_MEETING},
            {"娱", ActorManager.FLAG_EMPLOYEE_ON_ENTERTAINMENT},
            {"健", ActorManager.FLAG_EMPLOYEE_ON_GYM},
        }
        ActorManager:DebugAddFlag(tab[cfg.num][2])
        info = cfg.Info .. ",事件:" .. tab[cfg.num][1]
    elseif cfg.type == 17 then
        for k,v in pairs(ConfigMgr.config_chat_condition) do
            if cfg.num == k then
                GameTableDefine.ChatEventManager:ActiveChatEvent(k, true, true)
                info = cfg.Info .. ",对话事件:" .. cfg.num
                break
            end
        end
    elseif cfg.type == 18 then
        GameTableDefine.PetListUI:PetFeed(cfg.num, cfg.num_2)
        info = cfg.Info .. ",零食类型:" .. cfg.num .. ",零食数量:" .. cfg.num_2
    elseif cfg.type == 19 then
        GameTableDefine.ActivityRankDataManager:PlayerCheckGetRankValue(cfg.num)
        info = cfg.Info .. ",升级等级:" .. cfg.num
    elseif cfg.type == 20 then
        local afterBuy = function(cfgShop)--购买后的计数增加,暂时只能这样拆出来
            local save = ShopManager:GetLocalData()
            save["times"] = save["times"] or {}
            local times = save["times"]
            times[""..cfgShop.id] = (times[""..cfgShop.id] or 0) + 1
            LocalDataManager:WriteToFile()
        end
        local cfgShop = ConfigMgr.config_shop[cfg.num]
        local value = ShopManager:GetValue(cfgShop)
        if  type(value) == "number" then
            value = value * cfg.num_2
        end
        local cb = ShopManager:GetCB(cfgShop)
        cb(value , cfgShop, afterBuy(cfgShop))
        GameTableDefine.PurchaseSuccessUI:SuccessBuy(cfgShop.id)
        info = cfg.Info .. ",购买商品:" .. cfg.num .. "," .. cfg.num_2 .. "个"
    elseif cfg.type == 21 then
        GameTableDefine.AccumulatedChargeActivityDataManager:GMOpenAccumulatedChargeAC(cfg.num or 5)
    elseif cfg.type == 22 then
        GameTableDefine.TimeLimitedActivitiesManager:EnableLimitPackActivity(cfg.num)
        info = cfg.Info .. ",活动时间:" .. cfg.num .. "分钟"
    elseif cfg.type == 23 then
        --2025-3-14  注释，老得副本开启已经不用了，用新的带Cyc的副本开启了
        -- GameTableDefine.InstanceDataManager:GMOpenInstanceActivity(cfg.num, cfg.num_2)
        -- --副本活动数据模块的初始化相关内容
        -- GameTableDefine.InstanceDataManager:Init(
        --         function()
        --             GameTableDefine.InstanceDataManager:ClearSaveData()
        --             GameTableDefine.InstanceTaskManager:InitTaskData(cfg.num_2)
        --             --初始化资金
        --             GameTableDefine.InstanceDataManager:AddCurInstanceCoin(GameTableDefine.InstanceDataManager.config_global.startCash )
        --             self:CloseView()
        --         end
        -- )
        -- GameTableDefine.MainUI:RefreshInstanceentrance()
        info = cfg.Info..",活动持续时间:"..cfg.num.."分钟"

    elseif cfg.type == 24 then
        info = cfg.Info.."在副本中告诉玩家检测状态"
    elseif cfg.type == 25 then
        GameTableDefine.InstanceDataManager:AddCurInstanceCoin(cfg.num)
        info = cfg.Info.."增加副本货币 ["..cfg.num.."]"
    elseif cfg.type == 26 then
        GameTableDefine.FootballClubModel:ChangeSP(nil, cfg.num)
    elseif cfg.type == 27 then
        GameTableDefine.FootballClubModel:ChangeLeagueMatchChance(cfg.num)
    elseif cfg.type == 28 then
        GameTableDefine.IntroduceUI:Introduce(nil, 1)
        info = cfg.Info
    elseif cfg.type == 29 then
        GameTableDefine.InstanceDataManager:ChangeCurrentTime(cfg.num or 1)
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():ChangeCurrentTime(cfg.num or 1)
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():ChangeCurrentTime(cfg.num or 1)
        info = cfg.Info..(cfg.num or 1).."H"

    elseif cfg.type == 30 then
        GameTableDefine.InstanceDataManager:RefreshAutoDisplayEntryTime()
        info = cfg.Info.."Refresh the Instance Auto display entry UI"
    elseif cfg.type == 31 then
        GameTableDefine.PersonalInfoUI:OpenPersonalInfoUI()
        info = cfg.Info.."Open PersonalDev Info UI"
        self:CloseView()
    elseif cfg.type == 32 then
        GameTableDefine.DressUpDataManager:GetAllDressUpItem(cfg.num)
        info = cfg.Info.."Get All DressUp Items"
        self:CloseView()
    elseif cfg.type == 35 then
        if cfg.num == 1 or cfg.num == 2 then
            GameTableDefine.ConfigMgr:GMDefineABTestGroup(cfg.num)
            info = cfg.Info.."Define the ABTest Group:"..tostring(cfg.num)
            self:CloseView()
        end
    elseif cfg.type == 36 then
        if cfg.str then
            GameTableDefine.IAP:GMModifyCountryCode(cfg.str)
            info = cfg.Info.."Modify Country Code to "..cfg.str
            self:CloseView()
        end
    elseif cfg.type == 38 then
        LocalDataManager:ReplaceLocalDataByConfig(cfg.num)
        info = cfg.Info.."本地更换存档成功, 请重新启动客户端生效"
    elseif cfg.type == 39 then
        GameTableDefine.InstanceDataManager:AddScore(cfg.num)
        GameTableDefine.InstanceMainViewUI:Refresh()
        info = cfg.Info.."添加副本任务积分 "..cfg.num
    elseif cfg.type == 40 then
        GameTableDefine.PiggyBankUI:GMAddPiggyBankValue(cfg.num)
        info = cfg.Info.."增加存钱罐积分 "..cfg.num
    elseif cfg.type == 41 then
        GameTableDefine.FloorMode:GetScene():InitGuideTimeLine(cfg.str)
        info = cfg.Info.."播放TimeLine: "..cfg.str
        self:CloseView()
    elseif cfg.type == 42 then
        GameTableDefine.CycleInstanceDataManager:GMOpenInstanceActivity(cfg.num, cfg.num_2, cfg.num_3)
        --GameTableDefine.MainUI:RefreshInstanceentrance() -- 放到 GMOpenInstanceActivity 里了
        info = cfg.Info..",活动持续时间:"..cfg.num.."分钟"
    elseif cfg.type == 43 then
        GameTableDefine.ResourceManger:AddTicket(cfg.num, nil, nil)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 44 then
        GameTableDefine.ResourceManger:AddWheelTicket(cfg.num, nil, nil)
        info = cfg.Info .. ",加" .. cfg.num .. "个"
    elseif cfg.type == 45 then
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():AddCurInstanceCoin(cfg.num)
        info = cfg.Info.."循环增加副本货币 ["..cfg.num.."]"
    elseif cfg.type == 46 then
        local data = {cfg.num, cfg.num_2}
        GameTableDefine.GiftUI:SendGift(data)
        info = cfg.Info
    elseif cfg.type == 47 then
        GameDeviceManager:ApplyRecommendedQualitylevel()
        info = cfg.Info
    elseif cfg.type == 48 then
        GameTableDefine.QuestionSurveyDataManager:ClearSurvey()
        info = cfg.Info.."清除问卷存档, 请重新启动客户端生效"
    elseif cfg.type == 49 then
        local cur = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetCurInstanceScore()
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():SetCurInstanceScore(cur + cfg.num)
        info = cfg.Info.."循环增加副本积分 ["..cfg.num.."]"
    elseif cfg.type == 51 then
        local firstPurchaseData = GameTableDefine.FirstPurchaseUI:GetSaveData()
        local now =  GameTimeManager:GetCurrentServerTime()
        local endTime = now + cfg.num * 60
        local startTime = now
        firstPurchaseData.enterDay = nil
        ShopManager:CheckResetDoubleDiamond({activityType=3,resetId=GameTimeManager:GetCurrentServerTime(),endTime = endTime, startTime = startTime})

        self:CloseView()
    elseif cfg.type == 52 then
        GameTableDefine.StatisticUI:OpenSelfStatistic()
        self:CloseView()
    elseif cfg.type == 53 then
        -- bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName
        GameTableDefine.StatisticUI:OpenOtherPlayerStatistic(cfg.bossSkin, cfg.playerName, cfg.start, cfg.contry_id, cfg.curMoneyEff, cfg.sceneID, cfg.sceneName)
        self:CloseView()
    elseif cfg.type == 55 then
        -- bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName
        local rankManagerClass = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetRankManager()
        if rankManagerClass then
            rankManagerClass:GMOpenRankSystem()
        end
    elseif cfg.type == 54 then
        local currModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
        if currModel and currModel.config_cy_blueprint_res then
            local bluePrintManager = currModel:GetBluePrintManager() ---@type CycleToyBluePrintManager
            local resID = nil
            local resCount = nil
            if cfg.num_2 > 1 then
                resID = cfg.num
                resCount = cfg.num_2
            else
                resID = bluePrintManager:GetBaseResID()
                resCount = cfg.num
            end
            if resID then
                bluePrintManager:ChangeUpgradeResCount(resID,resCount)
                info = cfg.Info..",材料数量"..cfg.num
            else
                info = info.."添加蓝图材料失败,不存在副本或此副本没有蓝图功能"
            end
        else
            info = info.."添加蓝图材料失败,不存在副本或此副本没有蓝图功能"
        end
    elseif cfg.type == 56 then
        GameTableDefine.SeasonPassManager:GMOpenActivity(cfg.str_2, cfg.str_3, cfg.num)
        --GameTableDefine.SeasonPassUI:OpenView()
        self:CloseView()
    elseif cfg.type == 57 then
        GameTableDefine.SeasonPassTaskManager:Reset(true)
    elseif cfg.type == 58 then
        -- ["GMModifyTaskTime"] =              {type = 58, Info = "修改通行证任务的重置时间(想到剩余多少秒最少60秒)", num_1 = 1, num_2 = 60},
        GameTableDefine.SeasonPassTaskManager:GMModifyTaskTime(tonumber(cfg.num), tonumber(cfg.num_2))
    elseif cfg.type == 59 then
        local gameManager = GameTableDefine.SeasonPassManager:GetCurGameManager()
        if gameManager and gameManager.AddTicket then
            gameManager:AddTicket(cfg.num)
        end
    elseif cfg.type == 60 then
        GameTimeManager:GMChangeTime(cfg.num)
    elseif cfg.type == 61 then
        local rewardsData, isAccumulate = GameTableDefine.SupplementOrderUI:ParseRestoreZeroRealItems(cfg.num, cfg.data)
    elseif cfg.type == 62 then
        local extraData = rapidjson.encode(cfg.data or {})
        GameTableDefine.SupplementOrderUI:OnRestorePurchaseCallback(true, cfg.str, extraData)
    elseif cfg.type == 63 then
        
        GameTableDefine.UIPopupManager:ResetPopView()
    elseif cfg.type == 64 then
        if cfg.num == 1 or cfg.num == 2 then
            GameTableDefine.ConfigMgr:ReloadConfig(cfg.num)
            info = cfg.Info..": "..tostring(cfg.num)
        end
    elseif cfg.type == 65 then
        GameTableDefine.CEODataManager:OpenCEOBox(cfg.str, tonumber(cfg.num_2), true, nil, 1)
        self:CloseView()
    elseif cfg.type == 66 then
        GameTableDefine.CEODataManager:AddCEOKey(cfg.str, tonumber(cfg.num_2))
        self:CloseView()
    elseif cfg.type == 67 then
        if cfg.num_2 and tonumber(cfg.num_2) > 0 then
            for i = 1, tonumber(cfg.num_2) do
                GameTableDefine.CEODataManager:AddCEOSpecificCard(cfg.num)
            end
        else
            GameTableDefine.CEODataManager:AddCEOSpecificCard(cfg.num)
        end
        self:CloseView()
    elseif cfg.type == 68 then
        GameTableDefine.CEODataManager:GMModifyCEOLevel(cfg.num, cfg.num_2)
        self:CloseView()
    elseif cfg.type == 69 then
        GameTableDefine.CEODataManager:GMRefreshFreeTimes()
        self:CloseView()
    elseif cfg.type == 70 then
        -- ["GMGetActivityGift"] =             {type = 70, Info = "获取活跃任务的奖励", str = "day", num_2 = 1},
        GameTableDefine.ActivityUI:GetActivityGife(cfg.str, tonumber(cfg.num_2))
        self:CloseView()
    elseif cfg.type == 71 then
        UnityHelper.SendSaveDataToEditor()
    elseif cfg.type == 75 then
        UnityHelper.ReceiveSaveDataFromEditor(function(str)
            local data
            if str and string.len(str) > 0 then
                local rj = require("rapidjson")
                xpcall(function()
                    str = CS.Common.Utils.AES.Decrypt(str)
                    data = {record = rj.decode(str)}
                end,function(error)
                    data = rj.decode(str)
                end)
            else
                printError("读取存档失败,存档为空")
            end
            local clipBoardStr1
            if data then
                --这里是整体替换玩家存档，包含玩家的userid也使用
                -- LocalDataManager:ReplaceRecordData(data)
                --这里使用的是玩家的数据存档，userid还是使用当前本机的
                LocalDataManager:ReplaceLocalDataByGM(data)
                clipBoardStr1 = "替换存档成功，重新启动客户端生效"
                print(clipBoardStr1)
                info = cfg.Info..clipBoardStr1
                info =  "<color=#D9D919>" .. info .. ",时间:".. time .. "</color>"
                self:WriteToInfoList(info)
                -- CS.UnityEngine.Application.Quit()
                UnityHelper.ApplicationQuit()
                return
            else
                clipBoardStr1 = "获取的存档为空或者异常"
            end
            info = cfg.info..clipBoardStr1
        end)
    elseif cfg.type == 72 then
        GameTableDefine.ClockOutDataManager:GMOpenClockOutActivity(cfg.num)
        self:CloseView()
    elseif cfg.type == 73 then
        GameTableDefine.ClockOutDataManager:AddClockOutTickets(cfg.num, 1)
        self:CloseView()
    end

    info =  "<color=#D9D919>" .. info .. ",时间:".. time .. "</color>"
    self:WriteToInfoList(info)
end

function CheatUI:GetCheatingCommand(command)
    return cheatingCommandForm[command]
end

function CheatUI:GetMatchContent(str)
    str = string.lower(str)
    local pattern = "%a*"
    if str == " " then
        --pattern = "*"
    else
        for char in string.gmatch(str, ".[\128-\191]*") do
            pattern = pattern..char..'%a*'
        end
    end
    local result = {}
    for k,v in pairs(cheatingCommandForm) do
        local command = string.lower(k)
        local found = string.find(command,pattern) or string.find(tostring(v.type),pattern) or string.find(v.Info,pattern)
        if found then
            result[#result+1] = k
        end
    end
    table.sort(result,function(a,b)
        return cheatingCommandForm[a].type < cheatingCommandForm[b].type
    end)
    return result
end
