local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local CycleNightClubRankManager = GameTableDefine.CycleNightClubRankManager
local CycleNightClubRankUI = GameTableDefine.CycleNightClubRankUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local GameResMgr = require("GameUtils.GameResManager")
local GameUIManager = GameTableDefine.GameUIManager
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3

local CycleNightClubRankUIView = Class("CycleNightClubRankUIView", UIView)

function CycleNightClubRankUIView:ctor()
    self.super:ctor()
    self.m_init = false
    self.m_championData = {} -- 排行榜前三名data
    self.m_nightClubRankModel = nil -- 排行榜前三名模型展示
    self.rewardsDetails = nil
end

function CycleNightClubRankUIView:OnEnter()
    self.super:OnEnter()
    --if not CycleNightClubRankManager:GetQuestionIsOpen() then
    --    CycleNightClubRankUI:CloseView()
    --    return
    --end
    self.root_animation = self.m_uiObj:GetComponent("Animation")
    self.root_animation.playAutomatically = false

    self.canvas_group = self:GetComp("RootPanel", "CanvasGroup")
    self.canvas_group.alpha = 0
    
    self.rewardsDetails = self:GetGo("reward")
    self:InitPanelButton()
    -- 服务器出错 关闭UI
    EventManager:RegEvent(GameEventDefine.ServerError, function()
        GameSDKs:TrackForeign("rank_list", { name = CycleNightClubRankManager:GetInstanceId() .. "号副本排行榜", result = 1, ranking = CycleNightClubRankManager:GetUserRankNum(), score = CycleInstanceDataManager:GetCurrentModel():GetHistorySlotCoin() })
        GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_RANK_SERVER_ERROR"))
        self:DestroyModeUIObject()
    end)
    
    -- 数据刷新
    EventManager:RegEvent(GameEventDefine.RefreshNightClubRankData, function()
        if self.m_init then
            return
        end

        self.m_init = true
        GameSDKs:TrackForeign("rank_list", { name = CycleNightClubRankManager:GetInstanceId() .. "号副本排行榜", result = 0, ranking = CycleNightClubRankManager:GetUserRankNum(), score = CycleInstanceDataManager:GetCurrentModel():GetHistorySlotCoin() })
        self:RefreshPanelDisplay()
    end)

    print("进入排行榜界面, 获取服务器数据...")
    self:GetServerData()
    -- 刷新排行榜剩余时间
    self.rank_timer = GameTimer:CreateNewTimer(1, function()
        local remain_time = CycleNightClubRankManager:GetRemainTime() -- 活动剩余时间转换
        if remain_time >= 0 then
            self:SetText("RootPanel/title/time/txt", Tools:FormatTime(remain_time))
        else
            if self.rank_timer then
                GameTimer:StopTimer(self.rank_timer)
                self.rank_timer = nil
            end
        end
    end, true, true)
end

--- 进入排行榜界面, 获取服务器数据
function CycleNightClubRankUIView:GetServerData()
    self.loadingTag = true
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
    self.request_timer = GameTimer:CreateNewTimer(10, function()
        if self.loadingTag then
            print("10s 超时，关闭遮罩...")
            self.loadingTag = false
            GameSDKs:TrackForeign("rank_list", { name = CycleNightClubRankManager:GetInstanceId() .. "号副本排行榜", result = 1, ranking = CycleNightClubRankManager:GetUserRankNum(), score = CycleInstanceDataManager:GetCurrentModel():GetHistorySlotCoin() })
            GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)

            GameTableDefine.ChooseUI:CommonChoose(GameTextLoader:ReadText("TXT_TIP_RANK_NET_ERROR"), function()
                print("重试，拉取排行榜...")
                GameSDKs:TrackForeign("rank_list", { name = CycleNightClubRankManager:GetInstanceId() .. "号副本排行榜", result = 2, ranking = CycleNightClubRankManager:GetUserRankNum(), score = CycleInstanceDataManager:GetCurrentModel():GetHistorySlotCoin() })
                self:GetServerData()
            end, true, function()
                self:DestroyModeUIObject()
            end)
        end
    end)
    CycleNightClubRankManager:EnterCycleNightClubInstanceRankUI()
end

--[[
    @desc: 刷新当前显示面板的提示
    author:{author}
    time:2023-03-30 15:14:40
    @return:
]]
function CycleNightClubRankUIView:RefreshPanelDisplay()
    -- loading
    if not self.loadingTag then
        return
    end

    print("获取数据，关闭遮罩...")
    self.loadingTag = false
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)

    -- 玩家独立信息栏
    self:ShowPlayerInfo()

    -- 分组前三名，和其它名次数据
    self.m_championData = {}
    self.rankData = {}
    local rank_data = CycleNightClubRankManager:GetRankData()
    for rank_num, rank_info in pairs(rank_data) do
        if rank_num <= 3 then
            table.insert(self.m_championData, rank_info)
        else
            table.insert(self.rankData, rank_info)
        end
    end

    self:ShowTopInfo()
    -- 4 - 20名信息
    self:ShowOtherInfo()
end

--- 玩家独立信息栏
function CycleNightClubRankUIView:ShowPlayerInfo()
    local user_rank_info = CycleNightClubRankManager:GetUserRankInfo()
    self:SetText("RootPanel/player/item/rank/normal/num", user_rank_info.rank)
    self:GetGo("RootPanel/player/item/rank/normal/bg_self"):SetActive(true)
    self:GetGo("RootPanel/player/item/rank/normal/bg_other"):SetActive(false)
    self:SetText("RootPanel/player/item/info/name/txt", user_rank_info.username)
    self:SetText("RootPanel/player/item/point/num", math.floor(user_rank_info.score))

    -- bg
    local firstBg = self:GetGo("RootPanel/player/item/bg/bg_first")
    local secondBg = self:GetGo("RootPanel/player/item/bg/bg_second")
    local thirdBg = self:GetGo("RootPanel/player/item/bg/bg_third")
    local normalBg = self:GetGo("RootPanel/player/item/bg/bg_normal")
    firstBg:SetActive(user_rank_info.rank == 1)
    secondBg:SetActive(user_rank_info.rank == 2)
    thirdBg:SetActive(user_rank_info.rank == 3)
    normalBg:SetActive(user_rank_info.rank >= 4)

    local firstRankBg = self:GetGo("RootPanel/player/item/rank/first")
    local secondRankBg = self:GetGo("RootPanel/player/item/rank/second")
    local thirdRankBg = self:GetGo("RootPanel/player/item/rank/third")
    local normalRankBg = self:GetGo("RootPanel/player/item/rank/normal")
    firstRankBg:SetActive(user_rank_info.rank == 1)
    secondRankBg:SetActive(user_rank_info.rank == 2)
    thirdRankBg:SetActive(user_rank_info.rank == 3)
    normalRankBg:SetActive(user_rank_info.rank >= 4)

    local userSkin = ConfigMgr.config_global.boss_skin[user_rank_info.gender]
    local userIcon = "head_Boss_" .. Tools:SplitString(userSkin, "_" )[2]
    local icon = self:GetComp("RootPanel/player/item/info/head", "Image")
    self:SetSprite(icon, "UI_BG", userIcon, nil, true)

    local itemObj = self:GetGo("RootPanel/player/item/info/reward/item")
    self:ShowAwardItem(user_rank_info.rank, itemObj)
end

--- 分组前三名
function CycleNightClubRankUIView:ShowTopInfo()
    for rank, champion in pairs(self.m_championData) do
        if champion.is_robot then
            self:SetText("RootPanel/top/top" .. rank .. "/name", GameTextLoader:ReadText(champion.username))
        else
            self:SetText("RootPanel/top/top" .. rank .. "/name", champion.username)
        end

        self:SetText("RootPanel/top/top" .. rank .. "/flag/num", champion.rank)
        self:SetText("RootPanel/top/top" .. rank .. "/point/numShadow", math.floor(champion.score))
        self:SetText("RootPanel/top/top" .. rank .. "/point/numShadow/num", math.floor(champion.score))

        local championSkin = ConfigMgr.config_global.boss_skin[champion.gender]
        local championIcon = "head_Boss_" .. Tools:SplitString(championSkin, "_" )[2]
        local championIconRoot = self:GetComp("RootPanel/top/top" .. rank .. "/head", "Image")
        self:SetSprite(championIconRoot, "UI_BG", championIcon, nil, true)

        itemObj = self:GetGo("RootPanel/top/top" .. rank .. "/info/reward/item")
        self:ShowAwardItem(rank, itemObj)
    end

    -- 不显示模型了，美术做不出来，好像是
    --self:LoadNightClubRankModel()
end

--- 4 - 20名信息数据
function CycleNightClubRankUIView:ShowOtherInfo()
    local itemGo = self:GetGoOrNil("RootPanel/rank/Viewport/Content/item")
    self:GetComp(itemGo, "", "CanvasGroup").alpha = 0
    UnityHelper.SetMmFeedbacksInitializationMode(itemGo)

    local parentGo = self:GetGoOrNil("RootPanel/rank/Viewport/Content")
    for i = 1, #self.rankData do
        if i == 1 then
            self:RefreshRankItem(i - 1, itemGo.transform)
        else
            local tmpGo = UnityHelper.CopyGameByGo(itemGo, parentGo)
            self:RefreshRankItem(i - 1, tmpGo.transform)
        end
    end

    self.canvas_group.alpha = 1
    self.root_animation:Play()
    local count = 1
    self.item_timer = GameTimer:CreateNewMilliSecTimer(100, function()
        if count <= #self.rankData then
            local itemObj = parentGo.transform:GetChild(count - 1).gameObject
            local fb = self:GetComp(itemObj, "", "MMFeedbacks")
            fb:Initialization()
            fb:PlayFeedbacks()

            --self:GetComp(itemObj, "", "CanvasGroup").alpha = 1
            count = count + 1
        else
            if self.item_timer then
                GameTimer:StopTimer(self.item_timer)
            end
        end
    end, true, false)

    --self.rankList = self:GetComp("RootPanel/rank", "ScrollRectEx")
    --self:SetListItemCountFunc(self.rankList, function()
    --    return #self.rankData
    --end)
    --self:SetListUpdateFunc(self.rankList, handler(self, self.RefreshRankItem))
    --
    --self.show_timer = GameTimer:CreateNewMilliSecTimer(20, function()
    --    self.rankList:UpdateData()
    --
    --end)
end

--- 显示奖励物品列表
function CycleNightClubRankUIView:ShowAwardItem(rank, itemObj)
    local award_list = CycleNightClubRankManager:GetAwardList(rank)
    local shopItemList = {}
    Tools:SetTempGo(itemObj, #award_list, true, function(go, index)
        --self:GetGo(go, "on"):SetActive(index <= curWorker)
        shopItemList[index] = go
    end)

    for i = 1, #award_list do
        local shopConf = Tools:SplitString(award_list[i], ":", true)
        local shop_conf = ConfigMgr.config_shop[shopConf[1]]
        if shop_conf then
            local shop_num = shopConf[2] or 0
            if shop_conf.type == 9 then
                if shop_conf.country == 0 then
                    shop_num = tostring(math.floor(shop_num * 60)) .. "Min"
                end
            end
            
            self:SetText(shopItemList[i], "num", shop_num)
            self:SetSprite(self:GetComp(shopItemList[i], "icon", "Image"), "UI_Shop", shop_conf.icon, nil, true)
            
            -- 不同宝箱，不同背景
            local award_type = shop_conf.param3 and shop_conf.param3[1] or 1
            if award_type ~= 1 and award_type ~= 2 and award_type ~= 3 and award_type ~= 4 then
                award_type = 1
            end

            --其他玩家用RootPanel/player/item/info/reward/item/bgs/frame_1
            --玩家自己用frame2
            if rank == CycleNightClubRankManager:GetRankNum() then
                award_type = 2
            else
                award_type = 1
            end

            local typeGo1 = self:GetGoOrNil(shopItemList[i], "bgs/frame_1")
            local typeGo2 = self:GetGoOrNil(shopItemList[i], "bgs/frame_2")
            local typeGo3 = self:GetGoOrNil(shopItemList[i], "bgs/frame_3")
            local typeGo4 = self:GetGoOrNil(shopItemList[i], "bgs/frame_4")
            if typeGo1 then
                typeGo1:SetActive(award_type == 1)
            end

            if typeGo2 then
                typeGo2:SetActive(award_type == 2)
            end

            if typeGo3 then
                typeGo3:SetActive(award_type == 3)
            end

            if typeGo4 then
                typeGo4:SetActive(award_type == 4)
            end

            self:SetButtonClickHandler(self:GetComp(shopItemList[i], "", "Button"), function()
                self:OpenRewardInfo(shopItemList[i], shop_conf)
            end)
        end
    end
end

--- 显示奖励物品气泡
function CycleNightClubRankUIView:OpenRewardInfo(curGo, shop_conf)
    local infoGo = self:GetGoOrNil("reward")
    if infoGo.isActive then
        return
    end

    if infoGo then
        infoGo:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
        local canvas_group = self:GetComp(infoGo, "", "CanvasGroup")
        canvas_group.alpha = 0

        self:SetText("reward/rewardInfo/title/txt", GameTextLoader:ReadText(shop_conf.name))
        self:SetText("reward/rewardInfo_old/title/txt", GameTextLoader:ReadText(shop_conf.name))
        self:SetText("reward/rewardInfo_old/fix/txt", GameTextLoader:ReadText(shop_conf.desc))
        self.rewardItemData = shop_conf.param
        local item = self:GetGo("reward/rewardInfo/fix/item")
        local item_parent = item.transform.parent
        for i = 0, item_parent.childCount - 1 do
            local child = item_parent:GetChild(i)
            if string.gmatch(child.name, "item") then
                child.gameObject:SetActive(false)
            end
        end

        local rewardInfoGo = self:GetGoOrNil("reward/rewardInfo")
        if shop_conf.type == 35 then
            for i, shop_id in ipairs(shop_conf.param) do
                local reward_conf = ConfigMgr.config_shop[shop_id]
                local item_name = "item_" .. tostring(i)
                local item_trans = item_parent:Find(item_name)
                if not item_trans then
                    local new_item = GameObject.Instantiate(item, item_parent)
                    new_item.name = item_name
                    item_trans = new_item.transform
                end

                self:SetSprite(self:GetComp(item_trans.gameObject, "icon", "Image"), "UI_Shop", reward_conf.icon, nil, true)
                self:SetText(item_trans.gameObject, "num", reward_conf.amount)
                item_trans.gameObject:SetActive(true)
            end
        else
            rewardInfoGo = self:GetGoOrNil("reward/rewardInfo_old")
        end

        local clampRectTransform = self:GetTrans("reward")
        local arrowTrans = self:GetTrans(rewardInfoGo, "arrow")
        local locationPos = self:GetGo(curGo, "pivot")
        GameTimer:CreateNewMilliSecTimer(100, function()
            UnityHelper.ClampInfoUIPosition(rewardInfoGo.transform, arrowTrans, locationPos.transform.position, clampRectTransform)
            canvas_group.alpha = 1
            rewardInfoGo:SetActive(true)
        end, false, false)
        --rewardInfoGo.transform.position = locationPos.transform.position
        
        infoGo:SetActive(true)
    end
end

--- 排名列表详情
function CycleNightClubRankUIView:RefreshRankItem(index, tran)
    local go = tran.gameObject
    local data = self.rankData[index + 1]

    if data.is_robot then
        self:SetText(go, "info/name/txt", GameTextLoader:ReadText(data.username))
    else
        self:SetText(go, "info/name/txt", data.username)
    end
    
    self:SetText(go, "rank/num", data.rank)
    self:SetText(go, "point/num", math.floor(data.score))

    local user_rank_info = CycleNightClubRankManager:GetUserRankInfo()
    -- bg
    self:GetGo(go, "bg_other"):SetActive(data.rank ~= user_rank_info.rank)
    self:GetGo(go, "bg_self"):SetActive(data.rank == user_rank_info.rank)

    -- rank_bg
    self:GetGo(go, "rank/bg_other"):SetActive(data.rank ~= user_rank_info.rank)
    self:GetGo(go, "rank/bg_self"):SetActive(data.rank == user_rank_info.rank)

    local userSkin = ConfigMgr.config_global.boss_skin[data.gender]
    local userIcon = "head_Boss_" .. Tools:SplitString(userSkin, "_" )[2]
    local icon = self:GetComp(go, "info/head", "Image")
    self:SetSprite(icon, "UI_BG", userIcon, nil, true)

    local itemObj = self:GetGo(go, "info/reward/item")
    self:ShowAwardItem(data.rank, itemObj)
end

--- 加载前三名model prefab
function CycleNightClubRankUIView:LoadNightClubRankModel()
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/CycleInstance/NtClub/NtClubRankModel.prefab",self,function(go)
        self.m_nightClubRankModel = go
        self:RefreshModelPanel()
    end)
end

---加载前三名人物 prefab
function CycleNightClubRankUIView:RefreshModelPanel()
    for rank, champion in pairs(self.m_championData) do
        local parentPivot = self:GetTrans(self.m_nightClubRankModel, "pivot/Top" .. rank)
        local skinEquipConf = ConfigMgr.config_equipment[champion.skin]
        if skinEquipConf and skinEquipConf.part == 0 then -- 皮肤模型
            local skinPrefabPath = skinEquipConf.path .. skinEquipConf.prefab .. ".prefab"
            self:AddOnlyGo(parentPivot, skinPrefabPath, true, function(go)
                -- 切换状态机
                local anim = self:GetComp(go, "", "Animator")
                local anim_res_path = "Assets/Res/UI/CycleInstance/NtClub/Rank_pose_top" .. rank .. ".controller"
                GameResMgr:ALoadAsync(anim_res_path, this, function(res)
                    anim.runtimeAnimatorController = res.Result
                end)
            end)
        else -- 默认模型
            local userSkin = ConfigMgr.config_global.boss_skin[champion.gender]
            local prefabPath = "Assets/Res/Prefabs/character/" .. userSkin ..".prefab"
            self:AddOnlyGo(parentPivot, prefabPath, true, function (go)
                -- 帽子
                local hatEquipConf = ConfigMgr.config_equipment[champion.hat]
                if hatEquipConf and hatEquipConf.part == 1 then
                    local hatPos = self:GetTrans(go, "mixamorig:Hips/mixamorig:Spine/mixamorig:Spine1/mixamorig:Spine2/mixamorig:Neck/mixamorig:Head/mixamorig:HeadTop_End/hatPos")
                    local hatPrefabPath = hatEquipConf.path .. hatEquipConf.prefab .. ".prefab"
                    self:AddOnlyGo(hatPos, hatPrefabPath)
          
                end

                -- 背包
                local backpackEquipConf = ConfigMgr.config_equipment[champion.bag]
                if backpackEquipConf and backpackEquipConf.part == 2 then
                    local backpackPos = self:GetTrans(go, "mixamorig:Hips/mixamorig:Spine/mixamorig:Spine1/mixamorig:Spine2/backpackPos")
                    local backpackPrefabPath = backpackEquipConf.path .. backpackEquipConf.prefab .. ".prefab"
                    self:AddOnlyGo(backpackPos, backpackPrefabPath)
                end

                -- 切换状态机
                local anim = self:GetComp(go, "", "Animator")
                local anim_res_path = "Assets/Res/UI/CycleInstance/NtClub/Rank_pose_top" .. rank .. ".controller"
                GameResMgr:ALoadAsync(anim_res_path, this, function(res)
                    anim.runtimeAnimatorController = res.Result
                end)
            end)
        end
    end
end

--清空一个GameObject下的子物体,添加我们想让其添加的物体
function CycleNightClubRankUIView:AddOnlyGo(parentTr, childPath, scale, callback)
    --GameTimer:StopTimer(self.backIdle)
    GameUIManager:SetEnableTouch(false)
    for k,v in pairs(parentTr) do
        GameObject.Destroy(v.gameObject)
    end
    GameResMgr:AInstantiateObjectAsyncManual(childPath, self, function(this)
        GameTimer:CreateNewMilliSecTimer(2,function()
            this.transform.parent = parentTr
            this.transform.position = parentTr.position
            this.transform.rotation = parentTr.rotation

            if scale then -- 人物需要固定大小，帽子和背包不用
                this.transform.localScale = Vector3(3, 3, 3)
            else
                this.transform.localScale = Vector3(1, 1, 1)
            end

            GameUIManager:SetEnableTouch(true)
            if callback then
                callback(this)
            end
        end,false,false)
    end)
end

--[[
    @desc: 初始化当前各个面板的按钮点击回调
    author:{author}
    time:2023-03-30 15:14:54
    @return:
]]
function CycleNightClubRankUIView:InitPanelButton()
    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self.rewardsDetails:SetActive(false)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/title/closebtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    local state
    local claimPanel = self:GetGo("RootPanel/btnPanel")
    claimPanel:SetActive(false)
    if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
        state = InstanceDataManager:GetInstanceState()
        claimPanel:SetActive(state == InstanceDataManager.instanceState.awartable)
    elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        state = CycleInstanceDataManager:GetInstanceState()
        claimPanel:SetActive(state == CycleInstanceDataManager.instanceState.awartable)
    end

    local claimBtn = self:GetComp(claimPanel, "claimbtn", "Button")
    if CycleNightClubRankManager:HadClaimAward() then
        claimPanel:SetActive(true)
        claimBtn.interactable = false
    else
        self:SetButtonClickHandler(claimBtn, function()
            GameSDKs:TrackForeign("rank_reward", {})
            -- 不用之前 开蛋的流程，复用里程碑里含CEO奖励的流程
            --GameTableDefine.CycleNightClubRankRewardUI:GetView()

            GameTableDefine.CycleNightClubRewardUI:ShowAllNotClaimRewardsGet(true)
            
            claimBtn.interactable = false
        end)
    end
end

function CycleNightClubRankUIView:OnExit()
    --CycleNightClubRankManager:ExistCycleNightClubInstanceRankUI()

    EventManager:UnregEvent(GameEventDefine.ServerError)
    EventManager:UnregEvent(GameEventDefine.RefreshNightClubRankData)

    -- 排行榜新增事件
    if self.rank_timer then
        GameTimer:StopTimer(self.rank_timer)
        self.rank_timer = nil
    end

    if self.request_timer then
        GameTimer:StopTimer(self.request_timer)
        self.request_timer = nil
    end

    if self.show_timer then
        GameTimer:StopTimer(self.show_timer)
        self.show_timer = nil
    end

    if self.m_nightClubRankModel then
        GameObject.Destroy(self.m_nightClubRankModel)
        self.m_nightClubRankModel = nil
    end

    if self.item_timer then
        GameTimer:StopTimer(self.item_timer)
    end
    
    self.rankList = nil
    self.m_init = false
    self.super:OnExit(self)
end

return CycleNightClubRankUIView