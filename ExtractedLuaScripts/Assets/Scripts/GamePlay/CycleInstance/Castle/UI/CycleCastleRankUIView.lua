local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local CycleCastleRankManager = GameTableDefine.CycleCastleRankManager
local CycleCastleRankUI = GameTableDefine.CycleCastleRankUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local GameResMgr = require("GameUtils.GameResManager")
local GameUIManager = GameTableDefine.GameUIManager
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3

local CycleCastleRankUIView = Class("CycleCastleRankUIView", UIView)

function CycleCastleRankUIView:ctor()
    self.super:ctor()
    self.m_init = false
    self.m_championData = {} -- 排行榜前三名data
    self.m_castleRankModel = nil -- 排行榜前三名模型展示
    self.rewardsDetails = nil
end

function CycleCastleRankUIView:OnEnter()
    self.super:OnEnter()
    --if not CycleCastleRankManager:GetQuestionIsOpen() then
    --    CycleCastleRankUI:CloseView()
    --    return
    --end

    self.rewardsDetails = self:GetGo("reward")
    self:InitPanelButton()
    -- 服务器出错 关闭UI
    EventManager:RegEvent(GameEventDefine.ServerError, function()
        GameSDKs:TrackForeign("rank_list", { name = CycleCastleRankManager:GetInstanceId() .. "号副本排行榜", result = 1 })
        GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_RANK_SERVER_ERROR"))
        self:DestroyModeUIObject()
    end)
    
    -- 数据刷新
    EventManager:RegEvent(GameEventDefine.RefreshCastleRankData, function(data)
        if self.m_init then
            return
        end

        self.m_init = true
        GameSDKs:TrackForeign("rank_list", { name = CycleCastleRankManager:GetInstanceId() .. "号副本排行榜", result = 0 })
        self:RefreshPanelDisplay(data)
    end)

    print("进入排行榜界面, 获取服务器数据...")
    self:GetServerData()
    -- 刷新排行榜剩余时间
    self.rank_timer = GameTimer:CreateNewTimer(1, function()
        local remain_time = CycleCastleRankManager:GetRemainTime() -- 活动剩余时间转换
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
function CycleCastleRankUIView:GetServerData()
    self.loadingTag = true
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
    self.request_timer = GameTimer:CreateNewTimer(10, function()
        if self.loadingTag then
            print("10s 超时，关闭遮罩...")
            self.loadingTag = false
            GameSDKs:TrackForeign("rank_list", { name = CycleCastleRankManager:GetInstanceId() .. "号副本排行榜", result = 1 })
            GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)

            GameTableDefine.ChooseUI:CommonChoose(GameTextLoader:ReadText("TXT_TIP_RANK_NET_ERROR"), function()
                print("重试，拉取排行榜...")
                GameSDKs:TrackForeign("rank_list", { name = CycleCastleRankManager:GetInstanceId() .. "号副本排行榜", result = 2 })
                self:GetServerData()
            end, true, function()
                self:DestroyModeUIObject()
            end)
        end
    end)
    CycleCastleRankManager:EnterCycleCastleInstanceRankUI()
end

--[[
    @desc: 刷新当前显示面板的提示
    author:{author}
    time:2023-03-30 15:14:40
    @return:
]]
function CycleCastleRankUIView:RefreshPanelDisplay(data)
    -- loading
    if not self.loadingTag then
        return
    end

    print("获取数据，关闭遮罩...")
    self.loadingTag = false
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)

    -- 玩家独立信息栏
    local user_rank_info = CycleCastleRankManager:GetUserRankInfo()
    self:SetText("RootPanel/player/item/rank/num", user_rank_info.rank)
    self:SetText("RootPanel/player/item/info/name/txt", user_rank_info.username)
    self:SetText("RootPanel/player/item/point/num", math.floor(user_rank_info.score))

    local userSkin = ConfigMgr.config_global.boss_skin[user_rank_info.gender]
    local userIcon = "icon_boss_" .. Tools:SplitString(userSkin, "_" )[2]
    local icon = self:GetComp("RootPanel/player/item/info/head", "Image")
    self:SetSprite(icon, "UI_BG", userIcon, nil, true)

    local itemObj = self:GetGo("RootPanel/player/item/info/reward/item")
    self:ShowAwardItem(user_rank_info.rank, itemObj)

    -- 分组前三名，和其它名次数据
    self.m_championData = {}
    local members = {}
    for rank_num, rank_info in pairs(data) do
        if rank_num <= 3 then
            table.insert(self.m_championData, rank_info)
        else
            table.insert(members, rank_info)
        end
    end

    -- 前三名基本信息展示
    for rank, champion in pairs(self.m_championData) do
        if champion.is_robot then
            self:SetText("RootPanel/rank/top/top" .. rank .. "/info/name", GameTextLoader:ReadText(champion.username))
        else
            self:SetText("RootPanel/rank/top/top" .. rank .. "/info/name", champion.username)
        end

        self:SetText("RootPanel/rank/top/top" .. rank .. "/flag", champion.rank)
        self:SetText("RootPanel/rank/top/top" .. rank .. "/info/point/num", math.floor(champion.score))

        itemObj = self:GetGo("RootPanel/rank/top/top" .. rank .. "/reward/item")
        self:ShowAwardItem(rank, itemObj)
    end

    self.rankData = members
    self.rankList = self:GetComp("RootPanel/rank", "ScrollRectEx")
    self:SetListItemCountFunc(self.rankList, function()
        return #self.rankData
    end)
    self:SetListUpdateFunc(self.rankList, handler(self, self.RefreshRankItem))
    self.rankList:UpdateData()

    self:LoadCastleRankModel()
end

function CycleCastleRankUIView:ShowAwardItem(rank, itemObj)
    --奖励物品
    local award_list = CycleCastleRankManager:GetAwardList(rank)
    local shopItemList = {}
    Tools:SetTempGo(itemObj, #award_list, true, function(go, index)
        --self:GetGo(go, "on"):SetActive(index <= curWorker)
        shopItemList[index] = go
    end)

    for i = 1, #award_list do
        local shopConf = Tools:SplitString(award_list[i], ":", true)
        local shop_conf = ConfigMgr.config_shop[shopConf[1]]
        if shop_conf then
            self:SetText(shopItemList[i], "num", shopConf[2] or 0)
            self:SetSprite(self:GetComp(shopItemList[i], "icon", "Image"), "UI_Shop", shop_conf.icon, nil, true)

            self:SetButtonClickHandler(self:GetComp(shopItemList[i], "", "Button"), function()
                self:OpenRewardInfo(shopItemList[i], shop_conf.name, shop_conf.desc)
            end)
        end
    end
end

function CycleCastleRankUIView:OpenRewardInfo(curGo, name, desc)
    local infoGo = self:GetGoOrNil("reward")
    if infoGo.isActive then
        return
    end

    if infoGo then
        self:SetText("reward/rewardInfo/title/txt", GameTextLoader:ReadText(name))
        self:SetText("reward/rewardInfo/fix/txt", GameTextLoader:ReadText(desc))
        local rewardInfoGo = self:GetGoOrNil("reward/rewardInfo")

        local clampRectTransform = self:GetTrans("reward")
        local arrowTrans = self:GetTrans(rewardInfoGo, "arrow")
        UnityHelper.ClampInfoUIPosition(rewardInfoGo.transform, arrowTrans, curGo.transform.position, clampRectTransform)
        --rewardInfoGo.transform.position = locationPos.transform.position
        
        infoGo:SetActive(true)
    end
end

function CycleCastleRankUIView:RefreshRankItem(index, tran)
    local go = tran.gameObject
    local data = self.rankData[index + 1]

    if data.is_robot then
        self:SetText(go, "info/name/txt", GameTextLoader:ReadText(data.username))
    else
        self:SetText(go, "info/name/txt", data.username)
    end
    
    self:SetText(go, "rank/num", data.rank)
    self:SetText(go, "point/num", math.floor(data.score))

    local userSkin = ConfigMgr.config_global.boss_skin[data.gender]
    local userIcon = "icon_boss_" .. Tools:SplitString(userSkin, "_" )[2]
    local icon = self:GetComp(go, "info/head", "Image")
    self:SetSprite(icon, "UI_BG", userIcon, nil, true)

    local itemObj = self:GetGo(go, "info/reward/item")
    self:ShowAwardItem(data.rank, itemObj)
end

--- 加载前三名model prefab
function CycleCastleRankUIView:LoadCastleRankModel()
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/CycleInstance/Castle/CastleRankModel.prefab",self,function(go)
        self.m_castleRankModel = go
        self:RefreshModelPanel()
    end)
end

---加载前三名人物 prefab
function CycleCastleRankUIView:RefreshModelPanel()
    for rank, champion in pairs(self.m_championData) do
        local parentPivot = self:GetTrans(self.m_castleRankModel, "pivot/Top" .. rank)
        local skinEquipConf = ConfigMgr.config_equipment[champion.skin]
        if skinEquipConf and skinEquipConf.part == 0 then -- 皮肤模型
            local skinPrefabPath = skinEquipConf.path .. skinEquipConf.prefab .. ".prefab"
            self:AddOnlyGo(parentPivot, skinPrefabPath, true, function(go)
                -- 切换状态机
                local anim = self:GetComp(go, "", "Animator")
                local anim_res_path = "Assets/Res/UI/CycleInstance/Castle/Rank_pose_top" .. rank .. ".controller"
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
                local anim_res_path = "Assets/Res/UI/CycleInstance/Castle/Rank_pose_top" .. rank .. ".controller"
                GameResMgr:ALoadAsync(anim_res_path, this, function(res)
                    anim.runtimeAnimatorController = res.Result
                end)
            end)
        end
    end
end

--清空一个GameObject下的子物体,添加我们想让其添加的物体
function CycleCastleRankUIView:AddOnlyGo(parentTr, childPath, scale, callback)
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
function CycleCastleRankUIView:InitPanelButton()
    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self.rewardsDetails:SetActive(false)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/closebtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    local state
    local claimBtn = self:GetGo("RootPanel/claimbtn")
    claimBtn:SetActive(false)
    if InstanceDataManager:GetInstanceIsActive() or InstanceDataManager:GetInstanceRewardIsActive() then
        state = InstanceDataManager:GetInstanceState()
        claimBtn:SetActive(state == InstanceDataManager.instanceState.awartable)
    elseif CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        state = CycleInstanceDataManager:GetInstanceState()
        claimBtn:SetActive(state == CycleInstanceDataManager.instanceState.awartable)
    end

    local claimBtnComp = self:GetComp(claimBtn, "", "Button")
    if CycleCastleRankManager:HadClaimAward() then
        claimBtnComp.interactable = false
    end

    self:SetButtonClickHandler(claimBtnComp, function()
        GameSDKs:TrackForeign("rank_reward", {})
        -- todo 奖励领取
        GameTableDefine.CycleCastleRankRewardUI:GetView()
        claimBtnComp.interactable = false
    end)
end

function CycleCastleRankUIView:OnExit()
    CycleCastleRankManager:ExistCycleCastleInstanceRankUI()

    EventManager:UnregEvent(GameEventDefine.ServerError)
    EventManager:UnregEvent(GameEventDefine.RefreshCastleRankData)

    -- 排行榜新增事件
    if self.rank_timer then
        GameTimer:StopTimer(self.rank_timer)
        self.rank_timer = nil
    end

    if self.request_timer then
        GameTimer:StopTimer(self.request_timer)
        self.request_timer = nil
    end

    if self.m_castleRankModel then
        GameObject.Destroy(self.m_castleRankModel)
        self.m_castleRankModel = nil
    end

    self.m_init = false
    self.super:OnExit(self)
end

return CycleCastleRankUIView