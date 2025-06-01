local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local DeviceUtil = CS.Game.Plat.DeviceUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Slider = CS.UnityEngine.UI.Slider
local ConfigMgr = GameTableDefine.ConfigMgr
local Application = CS.UnityEngine.Application


---@class LaunchView:UIBaseView
local LaunchView = Class("TestView", UIView)

function LaunchView:ctor()
    self.super:ctor()
    self.m_versionText = nil ---@type UnityEngine.UI.Text
    self.m_userIDText = nil ---@type UnityEngine.UI.Text
    self.m_realProgressValue = 70
    self.m_fakeProgressValue = 70
    -- self:PreloadSpriteAltas("UI_Effect");
end

function LaunchView:OnEnter()
    print("LaunchView:OnEnter")
    EventManager:DispatchEvent("FS_CMD_UI_MANAGER_BG_CLOSE")
    self.m_progressBar = UnityHelper.GetTheChildComponent(self.m_uiObj, "SplashBar", typeof(Slider))
    self.m_logs = UnityHelper.GetTheChildComponent(self.m_uiObj, "Logs", "TextMeshProUGUI")
    self.m_progressBar.maxValue = 100
    -- print("Slider->", self.m_progressBar);
    self.m_hintInfo = UnityHelper.GetTheChildComponent(self.m_uiObj, "TxtHint", "TextMeshProUGUI")
    self.m_progInfo = UnityHelper.GetTheChildComponent(self.m_uiObj, "TxtProgress", "TextMeshProUGUI")
    -- print("Info->", self.m_contentInfo);
    if GameConfig:IsLeyoHKVersion() then
        self:GetGo("Frame/top/Logo_tc"):SetActive(true)
    elseif GameConfig:IsWarriorVersion() then
        self:GetGo("Frame/top/Logo_en"):SetActive(true)
    else
        self:GetGo("Frame/top/Logo_cn"):SetActive(true)
    end

    if GameConfig:IsWarriorVersion() or GameConfig:IsLeyoHKVersion() then
        self:GetGo("warning"):SetActive(false)
        self:GetGo("RemindBtn"):SetActive(false)
    else
        self:GetGo("warning"):SetActive(true)
        self:GetGo("RemindBtn"):SetActive(true)
    end
    
    local  RemindBtn = self:GetComp("RemindBtn","Button")
    if RemindBtn and not RemindBtn:IsNull() then
        local launcherPop = CS.Game.GameLauncher.Instance.updater:GetGo("TipPanel")
        self:GetGo("TipPanel"):SetActive(launcherPop.activeSelf)
        self:SetButtonClickHandler(RemindBtn, function()
            self:GetGo("TipPanel"):SetActive(true)
            launcherPop:SetActive(true)
        end)
        self:SetButtonClickHandler(self:GetComp("TipPanel/bg/closeBtn","Button"), function()
            self:GetGo("TipPanel"):SetActive(false)
            launcherPop:SetActive(false)
        end)
    end

    self.m_userIDText = self:GetComp(self.m_uiObj, "gameInfo/userid/num", "RTLTextMeshPro")
    self.m_versionText = self:GetComp(self.m_uiObj, "gameInfo/version/num", "RTLTextMeshPro")
    self:UpdateVersionInfo()
    self:UpdateUserID()
    EventManager:DispatchEvent("FS_CMD_UI_UPDATE_CLOSE")

    self.m_realProgressValue = 70
    self.m_fakeProgressValue = 69
    self:CreateTimer(1,handler(self,self.OnUpdate),true,true)
end

function LaunchView:OnUpdate()
    if self.m_fakeProgressValue == self.m_realProgressValue then
        return
    end
    local delta = self.m_realProgressValue - self.m_fakeProgressValue
    local speed = 1
    if self.m_realProgressValue > 99 then
        speed = 10
    elseif delta>10 then
        speed = 2
    end
    if delta > 0 then
        self.m_fakeProgressValue = self.m_fakeProgressValue + math.min(speed,delta)
    else
        self.m_fakeProgressValue = self.m_realProgressValue
    end
    if self.m_progressBar then
        self.m_progressBar.value = self.m_fakeProgressValue
    end
end

function LaunchView:OnPause()
    print("LaunchView:OnPause")
end

function LaunchView:OnResume()
    print("LaunchView:OnResume")
end

function LaunchView:OnExit()
    print("LaunchView:OnExit")
    self.super:OnExit(self)
    EventManager:DispatchEvent("FS_CMD_UI_UPDATE_CLOSE")
end

function LaunchView:ShowLoadingScreen()
    local progressBg = self:GetGo("ProgressBg")
    local splashBar = self:GetGo("SplashBar")
    progressBg:SetActive(true)
    splashBar:SetActive(true)
    --self:SetLoadingProgress(0)
end

function LaunchView:SetLoadingProgress(progress, msg)
    self.m_realProgressValue = progress
    self:SetLoadingMsg(msg)
end

function LaunchView:SetLoadingMsg(msg)
    if self.m_logs and msg and msg ~= "" then
        self.m_logs.text = GameTextLoader:ReadText(msg)
        self.m_logs.gameObject:SetActive(true)
        return
    end
    --self.m_logs:Set(false)
end

function LaunchView:UpdateVersionInfo()
    local verNum = Application.version .. "." .. GameDeviceManager:GetServerVersionInfo():NewVerInt() .. "." .. GameDeviceManager:GetResVersion()
    if GameConfig:IsDebugMode() then
        local resDate = GameDeviceManager:GetResDate()
        if resDate and string.len(resDate)>0 then
            verNum = verNum .. "_".. (GameDeviceManager:GetResDate() or "")
        end
    end
    self:SetVersionInfo(verNum)
end

function LaunchView:SetVersionInfo(info)
    if self.m_versionText then
        self.m_versionText.text = info or ""
    end
end

function LaunchView:UpdateUserID()
    local userId = GameSDKs:GetThirdAccountInfo()
    if UnityHelper.IsRuassionVersion() or GameConfig:IsAMZPackageVersion() then
        userId = GameSDKs.LoginUUID
    end
    self:SetUserID(userId)
end

function LaunchView:SetUserID(userID)
    if not userID or string.len(userID)==0 then
        self:GetGo(self.m_uiObj,"gameInfo/userid"):SetActive(false)
        return
    end
    --printf("LaunchView:SetUserID(userID)"..userID)
    CS.UnityEngine.PlayerPrefs.SetString("userid",userID)
    CS.UnityEngine.PlayerPrefs.Save()
    if self.m_userIDText then
        self.m_userIDText.text = userID or ""
    end
end

function LaunchView:SetLoginPhaseInfo(isVisible, text)
    print("LaunchView:SetLoginPhaseInfo", isVisible, text)
    -- self.m_hintInfo.enabled = isVisible;
    if self.m_hintInfo then
        self.m_hintInfo.text = text
    end
end

function LaunchView:SetEnteringGameText(desc, tips)
    print("LaunchView:SetEnteringGameText", desc, tips)
    self.m_hintInfo.text = tips
    self.m_progInfo.text = desc
end

function LaunchView:WarriorLoginBtn()
    local go = self:GetGo("loginPanel")
    local progressBg = self:GetGo("ProgressBg")
    local splashBar = self:GetGo("SplashBar")
    go:SetActive(true)
    progressBg:SetActive(false)
    splashBar:SetActive(false)

    local isiOS = GameDeviceManager:IsiOSDevice()
    local appleGo = self:GetComp("loginPanel/appleBtn", "Button")
    appleGo.gameObject:SetActive(isiOS)
    local googleGo = self:GetGoOrNil("loginPanel/googleBtn")
    if googleGo then
        googleGo:SetActive(not isiOS)
    end
    if isiOS then
        self:SetButtonClickHandler(appleGo, function()
            GameSDKs:Warrior_login(GameSDKs.LoginType.apple)
            GameSDKs:TrackForeign("login", {login_type = GameSDKs.LoginType.apple, login_result = 11 })
            go:SetActive(false)
        end)
    end
    self:SetButtonClickHandler(self:GetComp("loginPanel/facebookBtn", "Button"), function()
        GameSDKs:Warrior_login(GameSDKs.LoginType.facebook)
        GameSDKs:TrackForeign("login", {login_type = GameSDKs.LoginType.facebook, login_result = 11 })
        go:SetActive(false)
    end)
    self:SetButtonClickHandler(self:GetComp("loginPanel/visitorBtn", "Button"), function()
        GameSDKs:Warrior_login(GameSDKs.LoginType.tourist)
	    GameSDKs:TrackForeign("login", {login_type = GameSDKs.LoginType.tourist, login_result = 11 })
        go:SetActive(false)
    end)
    if not isiOS then
        self:SetButtonClickHandler(self:GetComp("loginPanel/googleBtn", "Button"), function()
            GameSDKs:Warrior_login(GameSDKs.LoginType.google)
            GameSDKs:TrackForeign("login", {login_type = GameSDKs.LoginType.google, login_result = 11 })
            go:SetActive(false)
        end)
    end
    -- GameSDKs:TrackForeign("init", {init_id = 16, init_desc = "登陆界面加载完成并显示（游客以及新玩家）"})
end

function LaunchView:ShowWaitingEffect()
    local waittingGo = self:GetGoOrNil("LoginPanel")
    if waittingGo then
        waittingGo:SetActive(true)
    end
end

function LaunchView:HideWaitingEffect()
    local waittingGo = self:GetGoOrNil("LoginPanel")
    if waittingGo then
        waittingGo:SetActive(false)
    end
end

return LaunchView;
