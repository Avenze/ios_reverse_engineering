local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local DeviceUtil = CS.Game.Plat.DeviceUtil
local Application = CS.UnityEngine.Application

local SoundEngine = GameTableDefine.SoundEngine
local SettingUI = GameTableDefine.SettingUI
local GiftUI = GameTableDefine.GiftUI
local CloudStorageUI = GameTableDefine.CloudStorageUI
local GameCenterUI = GameTableDefine.GameCenterUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local rapidjson = require("rapidjson")

--local QualityName = {
--    [1] = "Low",
--    [2] = "Medium",
--    [3] = "High"
--}

local SettingUIView = Class("SettingUIView", UIView)

function SettingUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function SettingUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
    self:CheckThirdAccouontBinding()
    self:SetUserIDShow()

    self.aniMusic = self:GetComp("RootPanel/MidPanel/musicOff/block", "Animation")
    self.aniSFX = self:GetComp("RootPanel/MidPanel/soundOff/block", "Animation")
    self:SetMusic()
    self:SetSound()

    self:SetButtonClickHandler(self:GetComp("RootPanel/BtnPanel/faq/btn", "Button"), function()
        GameTableDefine.FAQUI:GetView()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/musicOff","Button"), function()
        self:SetMusic(true)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/soundOff","Button"), function()
        self:SetSound(true)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/bg/bg1/group/button","Button"), function()
        GameSDKs:JumpQQGroup()
    end)

    if GameConfig:IsWarriorVersion() then
        local go = self:GetGo("RootPanel/BtnPanel/supportHelp")
        go:SetActive(true)
        self:SetButtonClickHandler(self:GetComp(go, "feedbackBtn","Button"), function()
            GameSDKs:Warrior_sendFeedbackMail()
        end)
    end

    -- self:GetGo("RootPanel/gameCenter"):SetActive(not GameConfig.IsIAP())
    -- if not GameConfig.IsIAP() then
    --     local btnGameVideo = self:GetComp("RootPanel/gameCenter/gameBtn", "Button")
    --     self:SetButtonClickHandler(btnGameVideo, function()
    --         GameCenterUI:Open()
    --     end)
    -- end

    --self:GetGo("RootPanel/bg"):SetActive(GameTableDefine.ConfigMgr.config_global.enable_iap ~= 1)

    local giftBtn = self:GetComp("RootPanel/BtnPanel/gift","Button")

    if ConfigMgr.config_global.enable_iap == 1 and GameDeviceManager:IsiOSDevice() then
        giftBtn.gameObject:SetActive(SettingUI:ShowGiftCode())
    else
        giftBtn.gameObject:SetActive(not GameDeviceManager:IsiOSDevice())
    end
    self:SetButtonClickHandler(giftBtn, function()
        GiftUI:GetView()
    end)

    local isSupport = false
    local list = GameDeviceManager:GetWechatSupportList()
    -- Tools:DumpTable(list, "GetWechatSupportList")
    for k,v in pairs(list or {}) do
        -- print(k, v, GameDeviceManager:GetAppBundleIdentifier(), v == GameDeviceManager:GetAppBundleIdentifier(), DeviceUtil.WechatExist())
        if v == GameDeviceManager:GetAppBundleIdentifier() then
            if GameTableDefine.ConfigMgr.config_global.enable_iap ~= 1 then
                isSupport = true and DeviceUtil.WechatExist()
            else
                isSupport = true
            end
            break
        end
    end
    
    self:GetGo("RootPanel/BtnPanel/cloud_storage"):SetActive(isSupport or GameConfig:IsDebugMode())
    self:SetButtonClickHandler(self:GetComp("RootPanel/BtnPanel/cloud_storage","Button"), function()
        if GameTableDefine.ConfigMgr.config_global.enable_iap == 1 then
            -- GameSDKs:Facebook_Login()
            CloudStorageUI:ShowPanel()
        else
            GameSDKs:Wechat_Login()
        end
    end)

    self:SetVersionInfo()

    local storageClearGo = self:GetGo("RootPanel/BtnPanel/storageClear")
    storageClearGo:SetActive(true)
    self:SetButtonClickHandler(self:GetComp(storageClearGo, "resetBtn","Button"), function()
        -- GameTableDefine.ConformUI:GetView()
        GameTableDefine.ConformUI:OpenFirstResetAccount()
    end)

    local cur = GameLanguage:GetCurrentLanguageID()
    local dropDown = self:GetComp("RootPanel/MidPanel/languageSwitch/Dropdown", "TMP_Dropdown")
    -- dropDown:ResetOptions()
    UnityHelper.ClearDropDownList(dropDown)
    for i,v in ipairs(ConfigMgr.config_language or {}) do
        -- dropDown:AddOptionDataToOptions()
        UnityHelper.AddOptionDataToDropDownList(dropDown)
        local langName = GameTextLoader:ReadText(v.txt)
        self:SetDropdownText(dropDown, i, langName)
        if cur == v.language then
            dropDown:SetValueWithoutNotify(i - 1)
        end
    end
    self:SetDropdownValueChangeHandler(dropDown, function(index)
        print("----SetDropdownValueChangeHandler", index, ConfigMgr.config_language[index + 1].language)
        GameLanguage:SetCurrentLanguageID(ConfigMgr.config_language[index + 1].language)
        GameTextLoader:LoadTextofLanguage(ConfigMgr.config_language[index + 1].language,function()
            -- print("Switch LoadTextofLanguage ", ConfigMgr.config_language[index + 1].language)
            self:SetUserIDShow()
            self:SetVersionInfo()
            self:UpdateDynamicLocalizeText()
        end) 
    end)

    local followGo = self:GetGo("RootPanel/BtnPanel/follow")
    local curRecord = LocalDataManager:GetCurrentRecord()
    local diamondIconGo = self:GetGoOrNil("RootPanel/BtnPanel/follow/reward")
    if diamondIconGo then
        if not curRecord.getFollowDiamond or curRecord.getFollowDiamond == 0 then
            diamondIconGo:SetActive(true)
        else
            diamondIconGo:SetActive(false)
        end
    end
    -- followGo:SetActive(GameConfig:IsWarriorVersion() and not UnityHelper.IsRuassionVersion())
    --2024-1-22运营要求调整facebook到商店
    followGo:SetActive(false)
    if GameConfig:IsWarriorVersion() and not UnityHelper.IsRuassionVersion() then
        local followBtn = self:GetComp("RootPanel/BtnPanel/follow", "Button")
        self:SetButtonClickHandler(followBtn, function()
            if not curRecord.getFollowDiamond or curRecord.getFollowDiamond == 0 then
                followBtn.interactable = false
                curRecord.getFollowDiamond = 1
                local position = followGo.transform.position
                diamondIconGo:SetActive(false)
                ResMgr:AddDiamond(100, ResMgr.EVENT_CLAIM_FOLLOW_FACEBOOK, function()
                end, true)
                EventManager:DispatchEvent("FLY_ICON", position, 3, 100, function()
                    followBtn.interactable = true
                    GameDeviceManager:OpenURL("https://www.facebook.com/IdleOfficeTycoon")
                end)
                LocalDataManager:WriteToFile()
            else
                GameDeviceManager:OpenURL("https://www.facebook.com/IdleOfficeTycoon")
            end
            
        end)
    end

    -- CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_uiObj:GetComponent("RectTransform"))
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self:GetComp("RootPanel", "RectTransform"))

    --隐私相关设置
    local privateBtnGo = self:GetGoOrNil("RootPanel/BtnPanel/privateBtn") 
    local privateBtn = self:GetComp("RootPanel/BtnPanel/privateBtn", "Button")
    if privateBtnGo then
        privateBtnGo:SetActive(GameConfig:IsWarriorVersion() and not UnityHelper.IsRuassionVersion())
        if privateBtn then
            privateBtn.interactable = DeviceUtil.IsPrivacySettingsButtonEnabled()
            self:SetButtonClickHandler(privateBtn, function()
                DeviceUtil.InvokeNativeMethod("ShowPrivacyUpdateOption")
            end)
        end
    end

    --俄区补单新增的内容2023-11-3
    self.m_RestorePurchaseBtnGo = self:GetGoOrNil("RootPanel/BtnPanel/restoreBtn")
    --- gxy 2024-3-11 18:47:02 将俄区补单的按钮功能改为通用的补单功能
    
    --if self.m_RestorePurchaseBtnGo then
    --    self.m_RestorePurchaseBtnGo:SetActive(UnityHelper.IsRuassionVersion())
    --    if UnityHelper.IsRuassionVersion() then
    --        local restorePurchaseBtn = self:GetComp("RootPanel/BtnPanel/restoreBtn", "Button")
    --        self:SetButtonClickHandler(restorePurchaseBtn, function()
    --            self:OpenCheckRussionPurchase()
    --        end)
    --    end
    --end
    if self.m_RestorePurchaseBtnGo then
        self.m_RestorePurchaseBtnGo:SetActive(true)

        local restorePurchaseBtn = self:GetComp("RootPanel/BtnPanel/restoreBtn", "Button")
        self:SetButtonClickHandler(restorePurchaseBtn, function()
            self:OpenCheckRussionPurchase()
        end)

    end
    self.m_RestorePurchasePanelGo = self:GetGoOrNil("restorePanel")
    if self.m_RestorePurchasePanelGo then
        self.m_RestorePurchasePanelGo:SetActive(false)
    end
    
    self:SetButtonClickHandler(self:GetComp("RootPanel/userid/copy_btn", "Button"), function()
        local userId = self:GetUserID()
        if not userId then
            userId = "未获取到userId"
        end
        printf("userId: " .. userId)
        CS.UnityEngine.GUIUtility.systemCopyBuffer = userId
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_BTN_COPY_TIP"));
    end)

    --self:InitQuality()
end

--function SettingUIView:InitQuality()
--    local data = LocalDataManager:GetCurrentRecord()
--    local curQuality = data.quality or (UnityHelper.GetCurrentQualityLevel() + 1)
--    local dropDown = self:GetComp("RootPanel/MidPanel/qualitySwitch/Dropdown", "TMP_Dropdown")
--    -- dropDown:ResetOptions()
--    UnityHelper.ClearDropDownList(dropDown)
--    for i = 1, 3 do
--        -- dropDown:AddOptionDataToOptions()
--        UnityHelper.AddOptionDataToDropDownList(dropDown)
--        self:SetDropdownText(dropDown, i, QualityName[i])
--        if curQuality == i then
--            dropDown:SetValueWithoutNotify(i - 1)
--        end
--    end
--    self:SetDropdownValueChangeHandler(dropDown, function(index)
--        print("----SetDropdownValueChangeHandler", index,  QualityName[index+1])
--        UnityHelper.SetQualityLevel(index)
--        data.quality = index + 1
--    end)
--end

function SettingUIView:GetUserID()
    local userId = GameSDKs.m_accountId
    if UnityHelper.IsRuassionVersion() or GameConfig:IsAMZPackageVersion() then
        userId = GameSDKs.LoginUUID
    end
    return userId
end

function SettingUIView:SetUserIDShow()
    local idRoot = self:GetGo("RootPanel/userid")
    local btn = self:GetComp(idRoot, "", "Button")
    local data = LocalDataManager:GetDataByKey("user_data")
    --local userId = GameSDKs:GetThirdAccountInfo()
    local userId = self:GetUserID()
    self:SetText("RootPanel/userid",GameTextLoader:ReadText("TXT_MISC_USERID") .. (userId or ""))

    self:SetButtonClickHandler(btn, function()
        GameDeviceManager:CopyToClipboard(userId)
    end)
end

function SettingUIView:SetVersionInfo()
    local versionInfo = GameTextLoader:ReadText("TXT_MISC_VERSION")
    local verNum = Application.version .. "." .. GameDeviceManager:GetServerVersionInfo():NewVerInt() .. "." .. GameDeviceManager:GetResVersion()
    if GameConfig:IsDebugMode() then
        verNum = verNum .. "_".. (GameDeviceManager:GetResDate() or "")
    end
    versionInfo = string.format(versionInfo, verNum)
    self:SetText("RootPanel/version", versionInfo)
end

function SettingUIView:SetMusic(change)
    local musicOn = SoundEngine:MusicOn()--如何获取当前背景音乐的状态
    if change then
        musicOn = musicOn == false
        SoundEngine:SetMusic(musicOn)
        SettingUI:SetSound(1, musicOn)
    else
        --self:GetGo("RootPanel/MidPanel/musicOff/musicOn"):SetActive(musicOn)
        -- local tran = self:GetTrans("RootPanel/MidPanel/musicOff/block")
        -- local localPos = tran.localPosition
        -- localPos.x = musicOn and 44 or -44;
        -- tran.localPosition = localPos;
    end

    local aniPlay = "sound_off"
    if musicOn then
        aniPlay = "sound_on"
    end

    AnimationUtil.Play(self.aniMusic, aniPlay, function()
        --self:GetGo("RootPanel/MidPanel/musicOff/musicOn"):SetActive(musicOn)
    end)
end

function SettingUIView:SetSound(change)
    local soundOn = SoundEngine:SFXOn()--如何获取当前背景音效的状态
    if change then
        soundOn = soundOn == false
        SoundEngine:SetSFX(soundOn)
        SettingUI:SetSound(2, soundOn)
    else
        --self:GetGo("RootPanel/MidPanel/soundOff/soundOn"):SetActive(soundOn)
        -- local tran = self:GetTrans("RootPanel/MidPanel/soundOff/block")
        -- local localPos = tran.localPosition
        -- localPos.x = soundOn and 44 or -44;
        -- tran.localPosition = localPos;
    end

    local aniPlay = "sound_off"
    if soundOn then
        aniPlay = "sound_on"
    end
    AnimationUtil.Play(self.aniSFX, aniPlay, function()
        --self:GetGo("RootPanel/MidPanel/soundOff/soundOn"):SetActive(soundOn)
    end)
end

function SettingUIView:OnExit()
    self.super:OnExit(self)
    if self.bindTimer then
        GameTimer:StopTimer(self.bindTimer)
        self.bindTimer = nil
    end
end

function SettingUIView:BindingThirdAccount(loginType)
    local data = LocalDataManager:GetDataByKey("user_data")
    -- if data.curr
end

--[[
    @desc: 检测第三方账号绑定情况并进行相关的设置
    author:{author}
    time:2023-07-11 11:32:02
    @return:
]]
function SettingUIView:CheckThirdAccouontBinding()
    local account_link_btnGo = self:GetGoOrNil("RootPanel/BtnPanel/account_link/btn")
    if not account_link_btnGo then
        return
    end
    local txtGo = self:GetGoOrNil(account_link_btnGo, "text")
    local appleGo = self:GetGoOrNil(account_link_btnGo, "apple")
    local googleGo = self:GetGoOrNil(account_link_btnGo, "google")
    local facebookGo = self:GetGoOrNil(account_link_btnGo, "facebook")
    local userData = LocalDataManager:GetDataByKey("user_data")
    
    if GameDeviceManager:IsEditor() then
        userData.cur_type = GameSDKs.LoginType.tourist
    end

    if not userData.cur_type then
        return
    end
    if txtGo then
        txtGo:SetActive(userData.cur_type == GameSDKs.LoginType.tourist)
    end
    if appleGo then
        appleGo:SetActive(userData.cur_type == GameSDKs.LoginType.apple and GameDeviceManager:IsiOSDevice())
    end
    if googleGo then
        googleGo:SetActive(userData.cur_type == GameSDKs.LoginType.google and GameDeviceManager:IsAndroidDevice())
    end
    if facebookGo then
        facebookGo:SetActive(userData.cur_type == GameSDKs.LoginType.facebook)
    end

    self:SetButtonClickHandler(self:GetComp("RootPanel/BtnPanel/account_link/btn", "Button"), function()
        if userData.cur_type == GameSDKs.LoginType.tourist then
            --打开绑定到对应的面板的按钮
            self:OpenBindingAccountPanel()
        else
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_LINKED"))
        end
    end)
end

function SettingUIView:RequestBinding()
    if not self.bindingType or self.bindingType == GameSDKs.LoginType.tourist then
        return
    end
    GameTableDefine.ChooseUI:CommonChoose("TXT_TIP_LINK_ALREADY", function()
        --调用SDK请求开始，需等待返回，
        -- DeviceUtil.InvokeNativeMethod("WarriorApiBind", self.bindingType)
        if GameConfig:IsWarriorVersion() then
            local loadingGo = self:GetGoOrNil("Loading")
            if loadingGo then
                loadingGo:SetActive(true)
            end
            if self.bindTimer then
                GameTimer:StopTimer(self.bindTimer)
                self.bindTimer = nil
            end
            self.bindTimer = GameTimer:CreateNewMilliSecTimer(500, function ()
                GameSDKs:Warrior_bindingAcc(self.bindingType)    
            end)
            
        end
    end, true, nil)
    
    --Test测试一下失败的逻辑流程
    -- GameTimer:CreateNewMilliSecTimer(500, function()
    --     self:WarriorBindingAccCallback(false)
    -- end, false, false)
end

function SettingUIView:OpenBindingAccountPanel()
    self:GetGoOrNil("accountPanel"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("accountPanel/BgCover", "Button"), function()
        self:GetGoOrNil("accountPanel"):SetActive(false)
    end)
    --facebook是都有的，google是安卓有的，apple是ios有的
    local isRuaVersion = UnityHelper.IsRuassionVersion()
    self:GetGoOrNil("accountPanel/bg/facebookBtn"):SetActive(not UnityHelper.IsRuassionVersion())
    self:SetButtonClickHandler(self:GetComp("accountPanel/bg/facebookBtn", "Button"), function()
        self.bindingType = GameSDKs.LoginType.facebook
        self:RequestBinding()
    end)
    if GameDeviceManager:IsiOSDevice() then
        self:GetGoOrNil("accountPanel/bg/googleBtn"):SetActive(false)
        self:GetGoOrNil("accountPanel/bg/appleBtn"):SetActive(true)
        self:SetButtonClickHandler(self:GetComp("accountPanel/bg/appleBtn", "Button"), function()
            self.bindingType = GameSDKs.LoginType.apple
            self:RequestBinding()
        end)
    elseif GameDeviceManager:IsAndroidDevice() then
        self:GetGoOrNil("accountPanel/bg/googleBtn"):SetActive(true)
        self:GetGoOrNil("accountPanel/bg/appleBtn"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp("accountPanel/bg/googleBtn", "Button"), function()
            self.bindingType = GameSDKs.LoginType.google
            self:RequestBinding()
        end)
    end
end

function SettingUIView:WarriorBindingAccCallback(isSuccess)
    
    if isSuccess then
        -- self:GetGoOrNil("accountPanel/Loading"):SetActive(false)
        self:GetGoOrNil("accountPanel"):SetActive(false)
        self:CheckThirdAccouontBinding()
    else
        -- CommonChoose(txt, cb, showCancel, canceCb)
        local resultStr = GameTextLoader:ReadText("TXT_TIP_LOGIN_FAIL")
        GameTableDefine.ChooseUI:CommonChoose(resultStr, function()
            self:RequestBinding()
        end, true, function()
            self:GetGoOrNil("accountPanel"):SetActive(false)
            self:CheckThirdAccouontBinding()
        end)
    end
    self:GetGoOrNil("Loading"):SetActive(false)
end

--[[
    @desc: 开启俄区补单查询
    author:{author}
    time:2023-11-03 12:02:32
    @return:
]]
function SettingUIView:OpenCheckRussionPurchase()
    self:ResetRussionPurchaseDisp()
    if self.m_RestorePurchasePanelGo then
        self.m_RestorePurchasePanelGo:SetActive(true)
        local dispText = GameTextLoader:ReadText("TXT_PURCHASE_Searching")
        self:SetText("restorePanel/background/midPanel/desc", dispText)
        --这里检测是不是已经拉到补单的信息了
        local haveData = nil
        local datas = GameTableDefine.MainUI:GetInitSupplementOrder()
        for _, v in pairs(datas or {}) do
            haveData = v
            break
        end
        
        if haveData and haveData.serialId and haveData.productId then
            local iapCfg = GameTableDefine.IAP:ProductIDToCfg(haveData.productId)
            -- if iapCfg and iapCfg.restore == 1 then
            if iapCfg then
                self:OnCheckRussionPurchaseCallback(true, haveData.serialId, haveData.productId, haveData.orderId)
            else
                local configGo = self:GetGoOrNil("restorePanel/background/botPanel")
                local waitIconGo = self:GetGoOrNil("restorePanel/background/midPanel/icon")
                self.m_RestorePurchasePanelGo:SetActive(true)
                waitIconGo:SetActive(false)
                self:SetText("restorePanel/background/midPanel/desc", GameTextLoader:ReadText("TXT_PURCHASE_Failed"))
                configGo:SetActive(true)
                self:SetButtonClickHandler(self:GetComp("restorePanel/background/botPanel/confirmBtn", "Button"), function()
                    self:CloseCheckRussionPurchase()
                end)
                return
            end
        else
            DeviceUtil.InvokeNativeMethod("queryOrder", "2")
        end
        
    end
end

function SettingUIView:CloseCheckRussionPurchase()
    if self.m_RestorePurchasePanelGo then
        self:ResetRussionPurchaseDisp()
        self.m_RestorePurchasePanelGo:SetActive(false)
    end  
end

--[[
    @desc:查询补单信息回调 
    author:{author}
    time:2023-11-03 14:05:11
    --@isSuccess: 
    @return:
]]
function SettingUIView:OnCheckRussionPurchaseCallback(isSuccess, serialId, productId, orderID)
    local configGo = self:GetGoOrNil("restorePanel/background/botPanel")
    local waitIconGo = self:GetGoOrNil("restorePanel/background/midPanel/icon")
    if isSuccess then
        --查询成功，直接开始调用补单接口
        DeviceUtil.InvokeNativeMethod("replenishOrder", serialId, productId, orderID, "2")
    else
        if waitIconGo then
            waitIconGo:SetActive(false)
        end
        if configGo then
            configGo:SetActive(true)
        end
        local dispText = GameTextLoader:ReadText("TXT_PURCHASE_NoResult")
        self:SetText("restorePanel/background/midPanel/desc", dispText)
        self:SetButtonClickHandler(self:GetComp("restorePanel/background/botPanel/confirmBtn", "Button"), function()
            self:CloseCheckRussionPurchase()
        end)
    end
end

function SettingUIView:ResetRussionPurchaseDisp()
    local configGo = self:GetGoOrNil("restorePanel/background/botPanel")
    local waitIconGo = self:GetGoOrNil("restorePanel/background/midPanel/icon")
    if configGo then
        configGo:SetActive(false)
    end
    if waitIconGo then
        waitIconGo:SetActive(true)
    end
end

--[[
    @desc: 补单成功与否的显示
    author:{author}
    time:2023-11-03 14:30:25
    --@isSuccess: 
    @return:
]]
function SettingUIView:OnRestorePurchaseCallback(isSuccess, productId, extra)
    local configGo = self:GetGoOrNil("restorePanel/background/botPanel")
    local waitIconGo = self:GetGoOrNil("restorePanel/background/midPanel/icon")
    local dispText = GameTextLoader:ReadText("TXT_PURCHASE_NoResult")
    
    local iapCfg = GameTableDefine.IAP:ProductIDToCfg(productId)
    -- if not iapCfg or iapCfg.restore == 0 then   -- 0表示不支持补单
    if not iapCfg then   -- 0表示不支持补单
        self.m_RestorePurchasePanelGo:SetActive(true)
        waitIconGo:SetActive(false)
        self:SetText("restorePanel/background/midPanel/desc", GameTextLoader:ReadText("TXT_PURCHASE_Failed"))
        configGo:SetActive(true)
        self:SetButtonClickHandler(self:GetComp("restorePanel/background/botPanel/confirmBtn", "Button"), function()
            self:CloseCheckRussionPurchase()
        end)
        return
    end
    
    if isSuccess then
        dispText = GameTextLoader:ReadText("TXT_PURCHASE_Restored")
        if iapCfg.restore == 1 then
            local shopId = GameTableDefine.IAP:ShopIdFromProductId(productId)
            GameTableDefine.ShopManager:Buy(shopId, false, nil, function ()
                GameTableDefine.PurchaseSuccessUI:SuccessBuy(shopId, nil)
            end)
        elseif iapCfg.restore == 0 then
            local extraData = rapidjson.decode(extra)
            local shopID = GameTableDefine.IAP:ShopIdFromProductId(productId)
            
            local rewardsData, isAccumulate = GameTableDefine.SupplementOrderUI:ParseRestoreZeroRealItems(shopID, extraData)
            if isAccumulate ~= 0 then
                if isAccumulate == 1 then
                    --补偿累充权限
                    GameTableDefine.AccumulatedChargeActivityDataManager:BuyProductCallbackByRestore(iapCfg.id, true)
                elseif isAccumulate == 2 then
                    --补偿通信证权限,现在就是一个通行证的方式，ID都是确定的
                    if shopID == GameTableDefine.SeasonPassManager.PREMIUM_SHOP_ID then
                        GameTableDefine.SeasonPassManager:SetIsBuyPremiumPass()
                        GameTableDefine.SeasonPassUI:OpenViewByDataUpdate(shopID)
                    elseif shopID == SeasonPassManager.LUXURY_SHOP_ID then
                        GameTableDefine.SeasonPassManager:SetIsBuyLuxuryPass()
                        GameTableDefine.SeasonPassUI:OpenViewByDataUpdate(shopID)
                    end
                elseif isAccumulate == 3 then
                    GameTableDefine.ClockOutDataManager:BuyClockOutIAPResult(shopID, true)
                end
            else
                GameTableDefine.ShopManager:BuyByGiftCode(rewardsData, function(realRewardDatas)
                    --realRewardDatas = {{icon1, num1}, {icon2, num2}}
                    --这里显示UI奖励内容
                    GameTableDefine.CycleInstanceRewardUI:ShowGiftCodeGetRewards(realRewardDatas, true)
                end, true)
            end      
        end
    end
    self:SetText("restorePanel/background/midPanel/desc", dispText)
    if waitIconGo then
        waitIconGo:SetActive(false)
    end
    if configGo then
        configGo:SetActive(true)
    end
    self:SetButtonClickHandler(self:GetComp("restorePanel/background/botPanel/confirmBtn", "Button"), function()
        self:CloseCheckRussionPurchase()
    end)
end

return SettingUIView