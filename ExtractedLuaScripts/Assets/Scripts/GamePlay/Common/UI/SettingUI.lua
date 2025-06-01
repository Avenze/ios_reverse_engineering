local SettingUI = GameTableDefine.SettingUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local SoundEngine = GameTableDefine.SoundEngine

local json = require("rapidjson")
local AES = CS.Common.Utils.AES
local Application = CS.UnityEngine.Application
local UnityHelper = CS.Common.Utils.UnityHelper
local SET_SOUND = "setting_sound"
local NETWORK_APP_VER
local LOCAL_APP_VER

local VerNum = function(ver)
    if not ver then
        return
    end
    local findNum = string.gmatch(ver, '%d+')
    local osVer1 = findNum() or 0;
    local osVer2 = findNum() or 0;
    local osVer3 = findNum() or 0;
    local osVerValue = osVer1 * 10000 + osVer2 * 100 + osVer3
    return osVerValue
end

function SettingUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.SETTING_UI, self.m_view, require("GamePlay.Common.UI.SettingUIView"), self, self.CloseView)
    return self.m_view
end

function SettingUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.SETTING_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function SettingUI:Init()
    local setting = LocalDataManager:GetDataByKey(SET_SOUND)
    if setting.setSFX == nil then
        setting.setSFX = true
    end
    if setting.setBGM == nil then
        setting.setBGM = true
    end

    if not GameConfig:IsNeedSound() then
        setting.setSFX = false
        setting.setBGM = false
    end
    SoundEngine:SetSFX(setting.setSFX)
    SoundEngine:SetMusic(setting.setBGM)

    LocalDataManager:WriteToFile()
end

function SettingUI:SetSound(type, state)
    local setting = LocalDataManager:GetDataByKey(SET_SOUND)
    if type == 1 then
        setting.setBGM = setting.setBGM == false
    elseif type == 2 then
        setting.setSFX = setting.setSFX == false
    end

    LocalDataManager:WriteToFile()
end

function SettingUI:RequestNextWorkAppVersion()
    if NETWORK_APP_VER then
        return
    end
    LOCAL_APP_VER = VerNum(Application.version)
    local requestTable = {
       callback = function(response)
           if response.data then
            local data = json.decode(response.data)
            NETWORK_APP_VER = VerNum(data.reviewVersion)
            print("NETWORK APP VERISON:", NETWORK_APP_VER, LOCAL_APP_VER)
           end
       end
   }
   GameNetwork:HTTP_PublicSendRequest(GameNetwork.GET_GAME_VER_URL, requestTable, nil, "GET")
end

function SettingUI:HKRequestNextWorkAppVersion()
    if NETWORK_APP_VER then
         return
    end
    LOCAL_APP_VER = VerNum(Application.version)
    local requestTable = {
        url = "get_hk_ios_gift_v",
        callback = function(response)
            if response.data then
                NETWORK_APP_VER = VerNum(response.data)
                print("NETWORK APP VERISON:", NETWORK_APP_VER, LOCAL_APP_VER)
            end
        end
    }
    GameNetwork:HTTP_SendRequest(requestTable)
 end

function SettingUI:GetNextWorkAppVersion()
    return NETWORK_APP_VER
end

function SettingUI:ShowGiftCode()
    -- 添加HK版本的礼包码不显示
    if GameConfig:IsLeyoHKVersion() then
        return false
    end
    print("ShowGiftCode:", NETWORK_APP_VER, LOCAL_APP_VER)
    return (NETWORK_APP_VER or 0) >= (LOCAL_APP_VER or 0)
end

function SettingUI:ResetGameData()
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
        msg = {
            uuid = tostring(GameSDKs:GetThirdAccountInfo() or "")
        },
        callback = function(response)
            if GameConfig:IsWarriorVersion() or 
               (GameConfig:IsLeyoHKVersion() and tonumber(response.code) == 200) 
            then
                LocalDataManager:ClearUserSave()
                -- GameStateManager:RestartGame()
                -- CS.UnityEngine.Application.Quit()
                UnityHelper.ApplicationQuit()
            end
        end,
        isLoading = true,
		fullMsgTalbe = true,
   }
   if GameConfig:IsWarriorVersion() then
        if GameConfig:UseWarriorOldAPI() then
            GameNetwork:HTTP_PublicSendRequest(GameNetwork.RESET_GAME_DATA_URL, requestTable, nil, "GET", nil, GameNetwork.HEADR)
        else
            requestTable.url = GameSDKs.REST_DATA_URL
            GameSDKs:Warrior_request(requestTable)
            local rootRecord =  LocalDataManager:GetRootRecord()
            local key, v = next(rootRecord or {})
            GameSDKs:UploadErrorInfo("warrior_response", {uid="clear_data_success", rkey = key})
        end
   else
        requestTable.msg.wx_id = GameSDKs:GetThirdAccountInfo()
        requestTable.url = "hk_clear_data"
        GameNetwork:HTTP_SendRequest(requestTable)
   end
end

function SettingUI:WarriorBindingAccCallback(success, loginType, userID, serverData)

    --根据情况调用相关逻辑
    local loginFailed = success
    -- GameSDKs:TrackForeign("init", {init_id = 18, init_desc = "服务器返回存档请求"})
    local typeDesc = "facebook"
    if loginType == "3" then
        if GameDeviceManager:IsiOSDevice() then
            typeDesc = "apple"
        end
        if GameDeviceManager:IsAndroidDevice() then
            typeDesc = "google"
        end
    end
    local bindResult = 0
    if loginFailed then
        if userID and userID ~= "" and serverData and serverData == "" then
            bindResult = 1
        end
        if userID and userID ~= "" and serverData and serverData  ~= "" then
            bindResult = 2
        end
    end
    GameSDKs:TrackForeign("sign", {sign_type = typeDesc, sign_result = bindResult})
    --第一种登录失败
    if self.m_view and not loginFailed then
        self.m_view:Invoke("WarriorBindingAccCallback", false)
        return
    end
    
    --第二种情况服务器上没有存档，直接修改本地存档并保存
    if userID and userID ~= "" and serverData and serverData == "" then
        local userData = LocalDataManager:GetDataByKey("user_data")
        local oldCurAccount = userData["fb_id"]
        userData["cur_type"] = tostring(loginType)
        userData["fb_id"] = tostring(userID)
        userData["third_account"] = userData["third_account"] or {}
        local oldAccount = userData["third_account"][tostring(loginType)]
        userData["third_account"][tostring(loginType)] = tostring(userID)
        if GameSDKs.m_loginType == GameSDKs.LoginType.tourist then
            if not userData["third_account"][tostring(GameSDKs.m_loginType)] then
                userData["third_account"][tostring(GameSDKs.m_loginType)] = GameSDKs.m_accountId
            end
        end
        GameSDKs.m_accountId = userID   
        GameSDKs.m_loginType = loginType
        
        -- 2024-6-21 14:18:52 gxy 绑定第二个 reset本地存档
        if oldAccount and oldAccount ~= userID then
            LocalDataManager:ClearUserSave()
            local record = LocalDataManager:GetCurrentRecord()
            record.user_data = userData
        	LocalDataManager:WriteToFileInmmediately()

            UnityHelper.ApplicationQuit()    
        end

        --2024-6-24當前的綁定的賬號是一個新號，且客戶端是第一次綁定，把當前客戶端的檔變爲第三方賬號的檔並保存
        if not oldAccount then
            if oldCurAccount ~= tostring(userID) then
                LocalDataManager:ClearUserSave()
                local record = LocalDataManager:GetCurrentRecord()
                record.user_data = userData
                LocalDataManager:WriteToFileInmmediately()
                UnityHelper.ApplicationQuit() 
            else
                local record = LocalDataManager:GetCurrentRecord()
                record.user_data = userData
                LocalDataManager:WriteToFileInmmediately()
                UnityHelper.ApplicationQuit()
            end
            
        end

        --LocalDataManager:WriteToFileInmmediately()
        --LocalDataManager:UpdateLoadLocalData(
        --    function()
        --        if self.m_view then
        --            self.m_view:Invoke("WarriorBindingAccCallback", true)
        --        end
        --    end
        --)
        return   
    end

    if not serverData or serverData == "" then
        self.m_view:Invoke("WarriorBindingAccCallback", false)
        return
    end
    --2024-6-24现在根据运营绑定账号修改需求，如果返回的ID和本地游客登录的id一致的话，那就用本地的档
    if bindResult == 2 then
        local userData = LocalDataManager:GetDataByKey("user_data")
        userData["cur_type"] = tostring(loginType)
        if userData["fb_id"] == tostring(userID) then
            userData["fb_id"] = tostring(userID)
            userData["third_account"] = userData["third_account"] or {}
            userData["third_account"][tostring(loginType)] = tostring(userID)
            if GameSDKs.m_loginType == GameSDKs.LoginType.tourist then
                if not userData["third_account"][tostring(GameSDKs.m_loginType)] then
                    userData["third_account"][tostring(GameSDKs.m_loginType)] = GameSDKs.m_accountId
                end
            end
            GameSDKs.m_accountId = userID   
            GameSDKs.m_loginType = loginType
        elseif userData["fb_id"] ~= tostring(userID) then
            LocalDataManager:ReplaceLocalData(serverData)
            userData["fb_id"] = tostring(userID)
            userData["third_account"] = userData["third_account"] or {}
            userData["third_account"][tostring(loginType)] = tostring(userID)
            if GameSDKs.m_loginType == GameSDKs.LoginType.tourist then
                if not userData["third_account"][tostring(GameSDKs.m_loginType)] then
                    userData["third_account"][tostring(GameSDKs.m_loginType)] = GameSDKs.m_accountId
                end
            end
            GameSDKs.m_accountId = userID   
            GameSDKs.m_loginType = loginType
        end
        local record = LocalDataManager:GetCurrentRecord()
        record.user_data = userData
        LocalDataManager:WriteToFileInmmediately()
        UnityHelper.ApplicationQuit()
        return
    end
    --第三种情况服务器上有存档，弹出对话框设置存档后保存并退出游戏
    LocalDataManager:ReplaceLocalData(serverData)
    LocalDataManager:WriteToFileInmmediately()
    UnityHelper.ApplicationQuit()
    
    -- GameTableDefine.ChooseUI:CommonChoose("TXT_TIP_LINK_ALREADY", function()
    --     --TODO:需要设置新的存档后重启
    --     -- newData = string.gsub(newData,"%%2B","+")
    --     -- local newDataTable = rapidjson.decode(AES.Decrypt(newData)) -- 解码直接替换
    --     -- RecordData.record = newDataTable
    --     -- local useData = string.gsub(serverData, "%%2B","+")
    --     -- local newDataTable = json.decode(AES.Decrypt(useData))
    --     LocalDataManager:ReplaceLocalData(serverData)
    --     LocalDataManager:WriteToFileInmmediately()
    --     UnityHelper.ApplicationQuit()
    -- end, true, function()
    --     if self.m_view then
    --         self.m_view:Invoke("WarriorBindingAccCallback", true)
    --     end
    -- end)
end

--[[
    @desc:查询返回接口，供SDK返回时调用 
    author:{author}
    time:2023-11-03 14:07:35
    --@isSuccess: 
    @return:
]]
function SettingUI:OnCheckRussionPurchaseCallback(isSuccess, serialId, productId, orderId)
    if self.m_view then
        self.m_view:Invoke("OnCheckRussionPurchaseCallback", isSuccess, serialId, productId, orderId)
    end
end

function SettingUI:OnRestorePurchaseCallback(isSuccess, productId, extra)
    if self.m_view then
        self.m_view:Invoke("OnRestorePurchaseCallback", isSuccess, productId, extra)
    end
end