local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ResMgr = GameTableDefine.ResourceManger
local CityMapUI = GameTableDefine.CityMapUI--???是否不合适,而且是为了GetView()
local MainUI = GameTableDefine.MainUI
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local DotweenUtil = CS.Common.Utils.DotweenUtil
local FeelUtil = CS.Common.Utils.FeelUtil
local WorldListUI = GameTableDefine.WorldListUI
local CountryMode = GameTableDefine.CountryMode
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local GuideManager = GameTableDefine.GuideManager
local ConfigMgr = GameTableDefine.ConfigMgr
local TimerMgr = GameTimeManager
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local BankUI = GameTableDefine.BankUI
local ChooseUI = GameTableDefine.ChooseUI
local CEODataManager = GameTableDefine.CEODataManager

---@class CityMapUIView:UIBaseView
local CityMapUIView = Class("CityMapUIView", UIView)

function CityMapUIView:ctor()
    self.super:ctor()
    self.m_hintInfo = {
        ["City_map_star"] = {},
        ["City_map_unlock_btn"] = {},
        ["City_map_bubble"] = {},
        ["City_map_building_info"] = {},
        ["City_map_greate_info"] = {},
        ["City_map_factory_info"] = {},
        ["City_map_football_info"] = {},
    }
    self.m_hander = {}
    self.m_handerClose = {}
end

function CityMapUIView:CreateGoSync(id, cb)
    print("GetGoSync", id)
    local info = self.m_hintInfo[id] or {}
    local go = self:GetBuffGo(id, info)
    if id == "City_map_bubble" then
        local prefab = self:GetGo("MapRect/Viewport/Map/City_map_bubble/Prefab")
        go = GameObject.Instantiate(prefab, info[1].transform)
        go:SetActive(true)
        cb(go)
    elseif go then
        go:SetActive(true)
        cb(go, id)
    else
        go = GameObject.Instantiate(info[#info], info[1].transform)
        go:SetActive(true)
        table.insert(info, go)
        cb(go)
    end
end

function CityMapUIView:GetBuffGo(id, info)
    if id == "City_map_building_info" or id == "City_map_greate_info" or "City_map_factory_info" then
        return info[1]
    end
    for i,v in ipairs(info or {}) do
        if v and not v:IsNull() and not v.activeInHierarchy then
            return v
        end
    end
end

function CityMapUIView:OnEnter()
    for k,v in pairs(self.m_hintInfo) do
        local go = self:GetGo("MapRect/Viewport/Map/"..k)
        go:SetActive(false)
        table.insert(v, go)
    end

    self.m_hintInfo["City_map_bubble"][1]:SetActive(true)

    local vBtn = self:GetComp("MapRect/Viewport", "Button")
    self:SetButtonClickHandler(vBtn, function()
        self:PlayFeel()
        self:CloseCallBack()
    end, "")
    self.m_OnEnter = true
    self.m_mapGo = self:GetGo("MapRect/Viewport/Map")
    self.m_viewCenterPos = vBtn.transform.position

    EventManager:RegEvent("BANK_EARN", function(buildingId)
        CityMode:RefreshBuildingState(buildingId)
    end)

    print("CityMapUIView:OnEnter")
end

function CityMapUIView:CloseDetailInfo()
    for k,v in pairs(self.m_hander or {}) do
        v(k)
    end
end

function CityMapUIView:CloseCallBack()
    for k,v in pairs(self.m_handerClose or {}) do
        v(k)
    end
end

function CityMapUIView:OnPause()
    print("CityMapUIView:OnPause")
end

function CityMapUIView:OnResume()
    print("CityMapUIView:OnResume")
end

function CityMapUIView:OnExit()
    self.super:OnExit(self)
    self.m_hintInfo = nil
    self.m_lastData = nil
    self.m_unlockDistrictId = nil

    EventManager:UnregEvent("BANK_EARN")
    --print("CityMapUIView:OnExit")
end
--配置城市的具体情况(解锁或者解锁)
function CityMapUIView:SetDistrictData(data)
    for k,v in pairs(data or {}) do
        local trans = self:GetTrans(self.m_mapGo, v.name)
        if trans then
            local go = trans.gameObject
            self:SetDistrictHint(self:GetGo(go, "UIPositon"), v)
            if self.m_unlockDistrictId == v.id then
                local anim = go:GetComponent("Animation")
                AnimationUtil.Play(anim, "CityMap",function()
                    CityMode:InitBuildings()
                end)
                self.m_unlockDistrictId = nil
            else
                self:GetComp(go, "locked", "CanvasGroup").alpha = v.state ~= 1 and 1 or 0
                self:GetComp(go, "unlock", "CanvasGroup").alpha = v.state == 1 and 1 or 0
                -- self:GetGo(go, "locked/area"..GameConfig:GetLangageFileSuffix()):SetActive(true)
                -- self:GetGo(go, "unlock/area"..GameConfig:GetLangageFileSuffix()):SetActive(true)
            end
            v.go = go
        end
    end
    self.m_lastData = data
end
--判断城市是否已经解锁,解锁就跳槽,没有就配置解锁UI
function CityMapUIView:SetDistrictHint(hintGo, data)
    if data.state == 0 or data.state == 1 then
        hintGo:SetActive(false)
        return
    end
    hintGo:SetActive(true)
    if data.state == 2 then -- 等待解锁
        local curr = StarMode:GetStar()
        if curr < data.star_need then
            self:CreateGoSync("City_map_star", function(go)
                -- UnityHelper.AddChildToParent(hintGo.transform, go.transform)
                go.transform.position = hintGo.transform.position
                local curP = curr / data.star_need
                self:SetText(go, "reward/num", data.star_need)
                self:SetText(go, "curr", curr.."/"..data.star_need)
                self:GetComp(go, "progress", "Slider").value = curP
            end)
        else
            self:CreateGoSync("City_map_unlock_btn", function(go)
                -- UnityHelper.AddChildToParent(hintGo.transform, go.transform)
                go.transform.position = hintGo.transform.position
                self:SetButtonClickHandler(go:GetComponent("Button"), function()
                    -- CityMode:UnlockingDistrict(data.index)
                    -- self:MoveToCenter(go, function()
                    go:SetActive(false)
                    self.m_unlockDistrictId = data.id
                    CityMode:UnlockedDistrict(data.index)
                    -- end)
                    --触发相关的引导
                    if data.id == 1007 then        
						--WorldListUI:MovingBtnHint()                
                        MainUI:GetView():RefreshMovingHing()
                        GuideManager.currStep = 800
                        GuideManager:ConditionToStart()
                        GuideManager:ConditionToEnd()
                    end
                end)
            end)
        end
    elseif data.state >= GameTimeManager:GetCurrentServerTime() then
        -- 解锁倒计时
    else
        CityMode:UnlockedDistrict(data.index)
    end
    
end

function CityMapUIView:LookAt(target)
    local buildingGo = self:GetGoOrNil(target)
    if not buildingGo then return end
    -- local info = self.m_hintInfo[id] or {}
    -- local go = self:GetBuffGo(id, info)
    self:MoveToCenter(buildingGo)
end

function CityMapUIView:PlayFeel(newFeel)
    if FeelUtil then
        if self.lastFeel then--无论如何,有老的,一定要等到播放完老的
            FeelUtil.PlayFeel(self.lastFeel, "city_map_feel_complete")
            GameUIManager:SetEnableTouch(false)
            self.lastFeel = nil
            if newFeel then
                self.nextFeel = newFeel
            end
        elseif self.nextFeel then--老的播放完后,看看是否有前面排队等着的了
            FeelUtil.PlayFeel(self.nextFeel, "feel_complete")
            GameUIManager:SetEnableTouch(false)
            self.lastFeel = self.nextFeel
            self.nextFeel = nil
        elseif newFeel then--第一次打开,都是空的
            FeelUtil.PlayFeel(newFeel, "feel_complete")
            GameUIManager:SetEnableTouch(false)
            self.lastFeel = newFeel
        else
            GameUIManager:SetEnableTouch(true)
        end
    else--没有FeelUtil,就没法回调,只能直接调用了
        if newFeel then--传入打开,不传入关闭
            if self.lastFeel then
                local feel = self:GetComp(self.lastFeel, "", "MMFeedbacks")
                feel:PlayFeedbacks()
                self.lastFeel = nil
            end

            local feel = self:GetComp(newFeel, "", "MMFeedbacks")
            feel:PlayFeedbacks()
            self.lastFeel = newFeel
        else
            if self.lastFeel then
                local feel = self:GetComp(self.lastFeel, "", "MMFeedbacks")
                feel:PlayFeedbacks()
                self.lastFeel = nil
            end
        end
    end
end

function CityMapUIView:feelComplete()
    self.isPlayFeel = false
    GameUIManager:SetEnableTouch(true)
end

EventManager:RegEvent("city_map_feel_complete", function()
    CityMapUI:GetView():Invoke("PlayFeel")
end)

EventManager:RegEvent("feel_complete", function()
    CityMapUI:GetView():Invoke("feelComplete")
end)

function CityMapUIView:ShowBuildingHint(id, target, name, icon, state, cameraPos, buildingClass)
    local buildingGo = self:GetGo(target)
    local hintGo = self:GetGo(buildingGo, "UIPositon")

    local build = self:GetGoOrNil(buildingGo, "BuildFeedback")

    local isOffice = CityMode:IsTypeOffice(id)
    local isHouse = CityMode:IsTypeHouse(id)
    local isCarshop = CityMode:IsTypeCarShop(id)
    local isBuilding = CityMode:IsTypeGreatBuilding(id)
    local isFactory = CityMode:IsTypeFactory(id)
    local isFootballClub = CityMode:IsTypeFootballClub(id)

    if isOffice or isHouse or isCarshop or isFactory or isFootballClub then
        if state > 0 then
            hintGo:SetActive(true)

            ---@param go UnityEngine.GameObject
            local refreshBumble = function(go, firstTime)
                if firstTime then
                    local typeName = "office"--能够给个更好的方法
                    if isOffice then
                        typeName = "office"
                    elseif isHouse then
                        typeName = "house"
                    elseif isCarshop then
                        typeName = "carshop"
                    elseif isBuilding then
                        typeName = "building"
                    elseif isFactory then
                        typeName = "factory"   
                    elseif isFootballClub then
                        typeName = "football"                      
                    end                    
                    local feedback = self:GetGo(go, typeName .. "/ClickFeedback")
                    local isFirstCome = CityMode:IsNeedShowOpenTip(id)
                    --添加一个特效显示的控制2023-3-21 fengyu
                    if isOffice then
                        local ringGo = self:GetGoOrNil(go, typeName.."/ring")
                        if ringGo then
                            ringGo:SetActive(state ~= 1)
                        end
                        go.transform:SetAsLastSibling()
                        if id == 200 and state == 2 then
                            local currCountryCash = ResMgr:GetCash()
                            if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
                                currCountryCash = ResMgr:GetEUR()
                            end
                            local unlockCash = ConfigMgr.config_buildings[id].unlock_require or 0
                            --K117 2号场景不能买也显示Tip
                            if currCountryCash >= unlockCash or id == 200 then
                                local tip = self:GetGoOrNil(go,"office/tip")
                                if tip then
                                    tip:SetActive(true)
                                end
                            end
                        end
                    else
                        go.transform:SetAsFirstSibling()
                        local tipPath = nil
                        if isHouse then
                            tipPath = "house/tip"
                        elseif isCarshop then
                            tipPath = "carshop/tip"
                        end
                        if tipPath then
                            local tip = self:GetGoOrNil(go,tipPath)
                            if tip then
                                tip:SetActive(isFirstCome)
                            end
                        end
                    end
                    self:SetButtonClickHandler(go:GetComponent("Button"), function()
                        self:MoveToCenter(go, function()
                            if state == 1 and isOffice then
                                CityMode:EnterDefaultBuiding()
                            else
                                buildingClass:ShowUnlockBuildingDetails(buildingGo, hintGo)
                            end
                        end)
                        if state ~= 1 or not isOffice then
                            self:PlayFeel(feedback)
                        end
                    end)

                    local feed = feedback:GetComponent("MMFeedbacks")
                    feed:Initialization()

                    go.transform.position = hintGo.transform.position
                end

                self:GetGo(go, "office/own"):SetActive(state == 1)
                self:GetGo(go, "house/own"):SetActive(state == 1 or state ==2)                
                self:GetGo(go, "carshop/own"):SetActive(state == 1)
                self:GetGo(go, "factory/own"):SetActive(state == 1)
                self:GetGo(go, "football/own"):SetActive(state == 1)
                if isHouse then
                    local typeImapge = self:GetComp(go, "house/own", "Image")
                    if state == 1 then
                        local skin = LocalDataManager:GetBossSkin()
                        self:SetSprite(typeImapge, "UI_Common", "icon_head_" .. skin .. "_house", nil, true)
                    elseif state == 2 then
                        self:SetSprite(typeImapge, "UI_Common", "icon_citymap_house_own", nil, true)
                    end                    
                end
                -- if state == 1 and buildingClass.m_config.building_type == 2 then
                --     local typeImapge = self:GetComp(go, "house/own", "Image")
                --     local skin = LocalDataManager:GetBossSkin()
                --     local countryAdd = ""
                --     -- if GameConfig:IsIAP() then
                --     --     countryAdd = "_house"
                --     -- end
                --     self:SetSprite(typeImapge, "UI_Common", "icon_head_" .. skin .. countryAdd, nil, true)
                -- end

                self:GetGo(go, "house"):SetActive(isHouse)
                self:GetGo(go, "office"):SetActive(isOffice)
                self:GetGo(go, "carshop"):SetActive(isCarshop)
                self:GetGo(go, "building"):SetActive(isBuilding)
                self:GetGo(go, "factory"):SetActive(isFactory)
                self:GetGo(go, "football"):SetActive(isFootballClub and CityMode:CheckBuildingSatisfy(700))
                
                if isFactory then
                    local factoryData = LocalDataManager:GetCurrentRecord()["factory"]               
                    local value = false
                    if buildingClass.m_config.unlock_require <= ResMgr:GetCash() and buildingClass.m_config.starNeed <= StarMode:GetStar() then
                        if not factoryData or Tools:GetTableSize(factoryData) == 0 then
                            value = true
                        end
                    end
                    self:GetGo(go, "factory/tip"):SetActive(value)       
                end
                -- UnityHelper.AddChildToParent(hintGo.transform, go.transform)
                local cameraPosGo = self:GetGo(cameraPos)
                if state == 1 and isOffice and self.m_OnEnter then
                    self:MoveToCenter(cameraPosGo or go, nil, 0)
                    self.m_OnEnter = nil
                end
            end

            if buildingClass.bumble then
                refreshBumble(buildingClass.bumble)
                return
            end
            self:CreateGoSync("City_map_bubble", function(go)
                buildingClass.bumble = go
                go.name = buildingClass.m_config.mode_name
                refreshBumble(go, true)
            end)

            buildingClass.feedBuild = build
        elseif TimerMgr:GetCurrentServerTime() < state then
            -- 倒计时
        else
            hintGo:SetActive(false)
        end
    elseif isBuilding then
        if state>0 then
            local refreshBumble = function(go, firstTime)
                local model = self:GetGo(buildingGo, "model")

                if firstTime then
                    self:GetGo(go, "house"):SetActive(false)
                    self:GetGo(go, "office"):SetActive(false)
                    self:GetGo(go, "carshop"):SetActive(false)
                    self:GetGo(go, "building"):SetActive(true)
                    self:GetGo(go, "football"):SetActive(false)

                    self:GetGo(go, "building/cash"):SetActive(false)

                    go.transform.position = hintGo.transform.position
                    go.transform:SetAsFirstSibling()

                    local feedback = self:GetGo(go, "building/ClickFeedback")
                    local feed = feedback:GetComponent("MMFeedbacks")
                    --feed:PrePare()

                    local cameraPosGo = self:GetGo(cameraPos)
                    local tip = self:GetGoOrNil(go,"building/tip")
                    self:SetButtonClickHandler(go:GetComponent("Button"), function()
                        self:MoveToCenter(go, function()
                            --显示设施的详细详细,包括修建,修建中,升级,满级等
                            model:SetActive(true)
                            buildingClass:ShowGreateDetail(buildingGo, hintGo)
                            --K117 打开界面后不再显示Open
                            if tip then
                                tip:SetActive(CityMode:IsNeedShowOpenTip(false))
                            end
                        end)

                        self:PlayFeel(feedback)
                    end)

                    local choose = self:GetGoOrNil(buildingGo, "ChooseFeedback")
                    local upgrade = self:GetGoOrNil(buildingGo, "UpgradeFeedback")

                    buildingClass.feedChoose = choose
                    buildingClass.feedBuild = build
                    buildingClass.feedUpgrade = upgrade

                    if tip then
                        tip:SetActive(CityMode:IsNeedShowOpenTip(id))
                    end
                end

                local currLv,maxLv = GreateBuildingMana:GetLv(id)

                local func,funcName = GreateBuildingMana:GetFunction(id)

                local iconImage = self:GetComp(go, "building/icon", "Image")
                if currLv == 0 then
                    self:SetSprite(iconImage, "UI_Common", "icon_citymap_building")
                else
                    self:SetSprite(iconImage, "UI_Common", "icon_citymap_" .. funcName)
                end

                model:SetActive(currLv > 0)

                local cashEarn = GreateBuildingMana:GetCashEarn(id, true)
                if cashEarn > 0 then
                    self:GetGo(go, "building/cash"):SetActive(true)
                    self:SetText(go, "building/cash/next", "+" .. Tools:SeparateNumberWithComma(cashEarn))
                    local cashButton = self:GetComp(go, "building/cash/icon", "Button")
                    self:SetButtonClickHandler(cashButton, function()

                        local success = function()
                            local earn = GreateBuildingMana:GetCashEarn(id)
                            CityMode:RefreshBuildingState(id)
                            EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
                            self:GetGo(go, "building/cash"):SetActive(false)
                        end

                        local add = GreateBuildingMana:GetCashEarn(id, true)
                        ChooseUI:EarnCash(add, success)
                    end)
                end

                local upgrateAble = GreateBuildingMana:BuyBuilding(id, true)
                if currLv > 0 and upgrateAble then
                    self:GetGo(go, "building/lvUp"):SetActive(true)
                else
                    self:GetGo(go, "building/lvUp"):SetActive(false)
                end
            end

            if buildingClass.bumble then
                refreshBumble(buildingClass.bumble)
                return
            end
            self:CreateGoSync("City_map_bubble", function(go)
                buildingClass.bumble = go
                refreshBumble(go, true)

                local feel = go:GetComponent("MMFeedbacks")
                --feel:PrePare()
            end)
        else
            local model = self:GetGo(buildingGo, "model")
            model:SetActive(false)
        end
    end
end

function CityMapUIView:UpdateBuildingDetails(target, buildingClass)
    local buildingGo = self:GetGo(target)
    local hintGo = self:GetGo(buildingGo, "UIPositon")
    buildingClass:ShowUnlockBuildingDetails(buildingGo, hintGo)
end

function CityMapUIView:ShowGreateDetail(buildingGo, hintGo, class)
    local cfg = class.m_config--config_building对应的那一列

    local cb = function(go)
        -- if hintGo then
        --     go.transform.position = hintGo.transform.position
        -- end

        table.insert(self.m_hander, function(k)
            go:SetActive(false)
            self:StopTimer()
            self.m_hander[k] = nil
        end)

        local title = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.id.."_NAME")
        local descption = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.id.."_DESC")

        self:SetSprite(self:GetComp(go, "building_image", "Image"), "UI_Common", cfg.building_icon, nil, true)
        self:SetText(go, "building_name", title)
        self:SetText(go, "building_des", descption)

        local currLv,maxLv = GreateBuildingMana:GetLv(cfg.id)
        local buyAble,cashNeed,starNeed,valueNeed = GreateBuildingMana:BuyBuilding(cfg.id, true)
        local funcArray, funName = GreateBuildingMana:GetFunction(cfg.id)

        --K117 打开伟大建筑界面后，去掉Open Tip
        CityMode:MarkComeToBuilding(cfg.id)

        local iconImagre = self:GetComp(go, "icon_bg/category", "Image")
        self:SetSprite(iconImagre, "UI_Common", "icon_citymap_" .. funName, nil, true)

        local valueRoot = self:GetGo(go, "wealth_request")
        --valueRoot:SetActive(GameConfig:IsIAP())

        --if GameConfig:IsIAP() then
            if valueNeed and valueNeed ~= 0 then
                valueRoot:SetActive(true)
                self:SetText(valueRoot, "num", BankUI:ValueToShow(valueNeed))
            else
                valueRoot:SetActive(true)
            end
        --end
        
        --显示具体功能
        local infoRoot = self:GetGo(go, "greate_info")
        self:GetGo(infoRoot, "next"):SetActive(currLv ~= 0 and currLv ~= maxLv)

        local info = GameTextLoader:ReadText("TXT_BUFF_" .. string.upper(funName))
        info = info.format(info, funcArray[currLv ~= 0 and currLv or 1])
        self:SetText(infoRoot, "curr", info)

        if currLv == 0 then
            FeelUtil.PlayFeel(class.feedChoose)
            table.insert(self.m_handerClose, function(k)
                FeelUtil.StopFeel(class.feedChoose)
                self.m_handerClose[k] = nil
                local model = self:GetGo(buildingGo, "model")
                local currLv,maxLv = GreateBuildingMana:GetLv(cfg.id)
                model:SetActive(currLv > 0)
            end)
        end

        if currLv ~= maxLv then
            info = GameTextLoader:ReadText("TXT_BUFF_NEXT")
            info = info.format(info, funcArray[currLv + 1])
            self:SetText(infoRoot, "next", info)
        end


        --显示具体按钮1.购买 2.升级 3.冷却中 4.满级
        local unlockBtn = self:GetComp(go, "unlock", "Button")
        local wait = self:GetComp(go, "wait", "Button")
        local improve = self:GetComp(go, "improve", "Button")
        local max = self:GetComp(go, "max", "Button")

        local allButton = {unlockBtn, wait, improve, max}
        local chooseOne = function(index)
            for k,v in pairs(allButton) do
                v.gameObject:SetActive(k == index)
            end

            return allButton[index]
        end

        if currLv < maxLv then
            local currButton = nil
            if currLv == 0 then--购买按钮
                currButton = chooseOne(1)
            else--升级或冷却按钮
                --如果有冷却时间还要处理一下
                currButton = chooseOne(3)
            end

            if currButton then
                self:SetText(currButton.gameObject, "num", Tools:SeparateNumberWithComma(cashNeed))
                currButton.interactable = buyAble
                self:SetButtonClickHandler(currButton, function()
                    if currLv == 0 then
                        FeelUtil.PlayFeel(class.feedBuild)
                    else
                        FeelUtil.PlayFeel(class.feedUpgrade)
                    end

                    GreateBuildingMana:BuyBuilding(cfg.id)
                end)
            end
        else--满级按钮
            chooseOne(4)
        end
        --检测CEO奖励是否有效
        local canShowCEOReward = (CEODataManager:CheckCEOOpenCondition() and (Tools:GetTableSize(cfg.ceo_reward) > 0) and currLv < maxLv)
        local dispGo = self:GetGoOrNil(go, "keyReward")
        if dispGo then
            dispGo:SetActive(canShowCEOReward)
            if canShowCEOReward then
                local dataItem = cfg.ceo_reward[1]
                local shopCfg = ConfigMgr.config_shop[dataItem[1]]
                local num = dataItem[2] * shopCfg.amount
                self:SetSprite(self:GetComp(dispGo, "icon", "Image"), "UI_Shop", shopCfg.icon)
                self:SetText(dispGo, "num", "x"..tostring(num))
            end
        end
    end

    self:CloseDetailInfo()
    self:CreateGoSync("City_map_greate_info", cb)
end

function CityMapUIView:ShowBuildingDetails(class, logo, unlockCash, ownCash, starNeed, moneyEnhance, state, buildingGo, hintGo)
    local cb = function(go)
        table.insert(self.m_hander, function(k)
            go:SetActive(false)
            self:StopTimer()
            self.m_hander[k] = nil
        end)
        
        local buildingIcons = {"icon_citymap_company", "icon_citymap_house", "icon_citymap_carshop","","icon_citymap_factory", "icon_citymap_football"}
        local typeImage = self:GetComp(go, "icon_bg/category", "Image")
        local iconName = buildingIcons[class.m_config.building_type]
        local star = StarMode:GetStar()
        if state == 1 then
            iconName = iconName .. "_own"
        end
        if state == 2 and class.m_config.building_type == 2 then
            iconName = iconName .. "_own"
        end
        self:SetSprite(typeImage, "UI_Common", iconName, nil, true)
        -- if state == 1 and class.m_config.building_type == 2 then
        --     local skin = LocalDataManager:GetBossSkin()
        --     self:SetSprite(typeImage, "UI_Common", "icon_head_" .. skin, nil, true)
        -- end
            
        self:SetSprite(self:GetComp(go, "building_image", "Image"), "UI_Common", logo, nil, true)
        CityMapUI:SetDynamicLocalizeText("Building_ShowUnlockBuildingDetails", function()
            self:SetText(go, "building_name", GameTextLoader:ReadText("TXT_BUILDING_B"..class.m_id.."_NAME"))
            self:SetText(go, "building_des", GameTextLoader:ReadText("TXT_BUILDING_B"..class.m_id.."_DESC"))
        end)
       
        local id = class.m_id
        local isOffice = class.m_config.company_qualities ~= nil
        local numText = self:SetText(go, "btn/num", Tools:SeparateNumberWithComma(unlockCash or 0))
        self:SetSprite(self:GetComp("MapRect/Viewport/Map/City_map_building_info/btn/icon", "Image"), "UI_Main", ResMgr:GetResIcon(CountryMode:GetCurrCountryCurrency()))
        --local matAddress = unlockCash <= ownCash and "Assets/Res/Fonts/MSYH GreenOutline Material.mat" or "Assets/Res/Fonts/MSYH RedOutline Material.mat"
        -- local mat = GameResMgr:LoadMaterialSyncFree(matAddress, self)
        -- numText.fontMaterial = mat.Result

        local unlockBtn = self:GetComp(go, "btn", "Button")
        self:SetButtonClickHandler(unlockBtn, function()
            local currContryCash = ResMgr:GetCash()
            if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
                currContryCash = ResMgr:GetEUR()
            end
            if currContryCash < unlockCash then
                GameTableDefine.ShopInstantUI:EnterToCashBuy()
                return
            end
            CityMode:BuyBuilding(id)
            FeelUtil.PlayFeel(class.feedBuild)
        end)
        local moveinBtn = self:GetComp(go, "moveBtn", "Button")
        self:SetButtonClickHandler(moveinBtn, function()
            CityMode:ChanageCurrentBuilding(id)
            go:SetActive(false)
            self:StopTimer()
        end)

        local gotoBtn = self:GetComp(go, "gotoBtn", "Button")
        self:SetButtonClickHandler(gotoBtn, function()
            CityMode:EnterHouseOrCarShop(id)
        end)


        
        if isOffice then  
            local unlockAble = star >= starNeed
            unlockBtn.gameObject:SetActive(state ~= 1)
            unlockBtn.interactable = unlockAble

            local unlockId, unlockCountDown = CityMode:GetUnlockingBuidlingInfo()
            moveinBtn.gameObject:SetActive(id == unlockId)
            moveinBtn.interactable = unlockCountDown ~= nil and unlockCountDown < TimerMgr:GetCurrentServerTime()
            gotoBtn.gameObject:SetActive(false)
        elseif class.m_config.building_type == 3 then --是车店
            unlockBtn.gameObject:SetActive(false)
            moveinBtn.gameObject:SetActive(false)
            gotoBtn.gameObject:SetActive(true)
            gotoBtn.interactable = star >= starNeed
            self:SetButtonClickHandler(gotoBtn, function()
                --K119 打开汽车商店UI后，去掉Open Tip
                CityMode:MarkComeToBuilding(id)
                GameTableDefine.BuyCarShopUI:ShowCarShopUI(id)--买车直接打开界面
            end)
        elseif class.m_config.building_type == 5 then --是工厂
            local factoryDataKey = CountryMode.factory            
            local data = LocalDataManager:GetCurrentRecord()
            if not data[factoryDataKey] then
                GameSDKs:TrackForeign("factory_first_enter", {renown_new = tonumber(star) or 0, state = 2}) --初次接触工厂埋点
            end
            --是否有数据(是否买过)
            local factorydata = LocalDataManager:GetDataByKey(factoryDataKey)                        
            local bought = factorydata[class.m_config.mode_name]
            unlockBtn.gameObject:SetActive(not bought)
            gotoBtn.gameObject:SetActive(bought)
            local unlockAble = star >= starNeed
            unlockBtn.interactable = unlockAble
            self:SetButtonClickHandler(unlockBtn, function()
                local currContryCash = ResMgr:GetCash()
                if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
                    currContryCash = ResMgr:GetEUR()
                end
                if currContryCash < unlockCash then
                    GameTableDefine.ShopInstantUI:EnterToCashBuy()
                    return
                end
                CityMode:BuyFactoryBuilding(id)                                              
                unlockBtn.gameObject:SetActive(false)
                gotoBtn.gameObject:SetActive(true)
                GameSDKs:TrackForeign("factory_first_enter", {renown_new = tonumber(star) or 0, state = 1}) --购买工厂埋点
                --2023增加运营要求的af埋点，工厂购买
                if id == 40001 then
                    -- GameSDKs:Track("af_factory_buy", {buildingID = id})
                    GameSDKs:TrackControl("af", "af,af_factory_buy", {af_buildingID = id})
                end                
                FloorMode:GetScene():CheckIfNeededFactoryGuide(true)
                FeelUtil.PlayFeel(class.feedBuild)               
            end)
            self:SetButtonClickHandler(gotoBtn, function()
                CityMode:EnterHouseOrCarShop(id)
            end)
        elseif class.m_config.building_type == 6 then --是足球俱乐部
            local footballClubDataKey = CountryMode.football
            local footballClubData = LocalDataManager:GetDataByKey(footballClubDataKey)
            local bought = footballClubData[class.m_config.mode_name]
            unlockBtn.gameObject:SetActive(not bought)            
            gotoBtn.gameObject:SetActive(bought)
            local unlockAble = star >= starNeed
            unlockBtn.interactable = unlockAble
            self:SetButtonClickHandler(unlockBtn, function()
                local currContryCash = ResMgr:GetCash()
                if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
                    currContryCash = ResMgr:GetEUR()
                end
                if currContryCash < unlockCash then
                    GameTableDefine.ShopInstantUI:EnterToCashBuy()
                    return
                end
                FloorMode:GetScene():CloseFootballClubGuideEntrance()
                CityMode:BuyFootballClub(id)          
                CityMode:RefreshBuildingState(id)
                unlockBtn.gameObject:SetActive(false)
                gotoBtn.gameObject:SetActive(true)
                FeelUtil.PlayFeel(class.feedBuild)               
            end)

            self:SetButtonClickHandler(gotoBtn, function()
                CityMode:EnterHouseOrCarShop(id)
            end)
        else
            unlockBtn.gameObject:SetActive(false)
            moveinBtn.gameObject:SetActive(false)
            gotoBtn.gameObject:SetActive(true)
            gotoBtn.interactable = star >= starNeed
        end


        self:SetText(go, "building_info/reward/num", starNeed)
        moneyEnhance = tonumber(moneyEnhance)

        self:GetGo(go, "building_info/text1"):SetActive(moneyEnhance > 1)
        self:GetGo(go, "building_info/bonus"):SetActive(moneyEnhance > 1)
        if moneyEnhance > 1 then
            local rate = math.floor(moneyEnhance * 100)
            local num = moneyEnhance <= 1 and GameTextLoader:ReadText("TXT_MISC_STAR_NOLIMIT") or rate .. "%";
            local text = self:SetText(go, "building_info/bonus", num)
        end

        --self:GetGo(go, "building_info/bonus"):SetActive(isOffice)
        --text.gameObject:SetActive(isOffice)

        --self:GetGo(go, "building_info/text1"):SetActive(isOffice)

        self:GetGo(go, "unlocking"):SetActive(false)
        self:StopTimer()
        if state > 2 then
            local cfg = ConfigMgr.config_buildings[id]
            self.endPoint = state
            self:CreateTimer(1000, function()
                local t = self.endPoint - TimerMgr:GetCurrentServerTime()
                local timeTxt = TimerMgr:FormatTimeLength(t)
                if t > 0 then
                    self:SetText(go, "unlocking/prog/FillArea/time", timeTxt)
                    local progress = self:GetComp(go, "unlocking/prog/FillArea", "Slider")
                    progress.value = 1 - t / (cfg.unlock_time or t)
                else
                    self:StopTimer()
                    CityMode:UnlockBuidlingComplete() 
                end
            end, true, true)
        end
    end

    self:CloseDetailInfo()
    if class.m_config.building_type == 5 then
        self:CreateGoSync("City_map_factory_info",cb)  
    elseif class.m_config.building_type == 6 then
        self:CreateGoSync("City_map_football_info",cb)  
    else 
        self:CreateGoSync("City_map_building_info", cb)            
    end
    
end

function CityMapUIView:MoveToCenter(go, func, speed)
    if speed == 0 then
        local pos = self.m_viewCenterPos - go.transform.position
        self.m_mapGo.transform.position = self.m_mapGo.transform.position + pos
        return
    end

    local pos = self.m_viewCenterPos - go.transform.position
    -- DotweenUtil.DOTweenMove(self.m_mapGo, self.m_mapGo.transform.position + pos, 0.2, function()
    --     GameUIManager:SetEnableTouch(true)
    --     if func then func() end
    -- end)
    local cmd = "SET_CITY_MOVE_CENTER_END_" ..self.m_mapGo:GetInstanceID()
    EventManager:RegEvent(cmd, function(go)
        EventManager:UnregEvent(cmd)
        --GameUIManager:SetEnableTouch(true)
        if func then func() end
    end)
    DotweenUtil.DOTweenMove(self.m_mapGo, self.m_mapGo.transform.position + pos, 0.2, cmd)
end

return CityMapUIView