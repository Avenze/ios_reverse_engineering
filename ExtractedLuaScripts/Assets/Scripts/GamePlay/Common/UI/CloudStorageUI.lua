local CloudStorageUI = GameTableDefine.CloudStorageUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local timerId = nil

function CloudStorageUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CLOUD_STORAGE, self.m_view, require("GamePlay.Common.UI.CloudStorageUIView"), self, self.CloseView)
    return self.m_view
end

function CloudStorageUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CLOUD_STORAGE)
    self.m_view = nil
    collectgarbage("collect")
end


function CloudStorageUI:ShowPanel()
    local data = LocalDataManager:GetDataByKey("user_data")
    local timeInfo = GameTextLoader:ReadText("TXT_CLOUDSTORAGE_TIME")
    local time = math.ceil((data.save_time or 0) / 1000)
    local enbleUploadBtn = GameTimeManager:GetCurrentServerTime() - (time or 0) > ConfigMgr.config_global.upload_interval
    local enbleDownloadBtn = false
    if data.save_time then
        local time, _ = GameTimeManager:FormatTimeToDHM(time)
        timeInfo = time
        enbleDownloadBtn = true
    end
    local userID = GameSDKs:GetThirdAccountInfo()
    if userID ~= tostring(GameSDKs.m_accountId) then
        enbleDownloadBtn = false
    end
    self:GetView():Invoke("ShowPanel", timeInfo, enbleUploadBtn, enbleDownloadBtn)
end

function CloudStorageUI:Upload()
    local userID = GameSDKs:GetThirdAccountInfo()
    if userID ~= tostring(GameSDKs.m_accountId) then
        return
    end
    LocalDataManager:UpdateLoadLocalData(function(error)
        if error then
            return
        end
        self:ShowPanel()
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_CLOUDSTORAGE_UPLOAD_SUCCESS"))
        GameSDKs:UploadErrorInfo("warrior_response", {uid="touch_upload"})
    end)
end

function CloudStorageUI:Download()
    LocalDataManager:DownLoadLocalData(true)
end

-- 待定使用
function CloudStorageUI:AutoUpdateGameData()
    local data = LocalDataManager:GetDataByKey("user_data")
    local time = math.ceil((data.save_time or GameTimeManager:GetCurrentServerTimeInMilliSec()) / 1000)
    local enbleUploadBtn = GameTimeManager:GetCurrentServerTime() - (time or 0) > ConfigMgr.config_global.upload_interval
    if enbleUploadBtn then
        LocalDataManager:UpdateLoadLocalData()
    end
end

function CloudStorageUI:StartAutoUpdateGameDataTimer()
    if timerId then
        GameTimer:StopTimer(timerId)
        timerId = nil
    end

    timerId = GameTimer:CreateNewTimer(ConfigMgr.config_global.auto_cloudstorage, function()
        local userID = GameSDKs:GetThirdAccountInfo()
        if tostring(userID) ~= tostring(GameSDKs.m_accountId) then
            return
        end
        LocalDataManager:UpdateLoadLocalData()
    end,true)
end

