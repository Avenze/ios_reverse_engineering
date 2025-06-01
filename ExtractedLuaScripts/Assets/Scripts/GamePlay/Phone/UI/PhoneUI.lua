local PhoneUI = GameTableDefine.PhoneUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local MY_APP = "my_app"
function PhoneUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PHONE_UI, self.m_view, require("GamePlay.Phone.UI.PhoneUIView"), self, self.CloseView)
    return self.m_view
end

function PhoneUI:Refresh()
    --1聊天 2银行 3货币兑换(海外才有)
    local save = LocalDataManager:GetDataByKey(MY_APP)
    --if GameConfig:IsIAP() then
        save.downApp = {1,2,3}
    -- else
    --     save.downApp = {1}
    -- end

    self:GetView():Invoke("Refresh", save.downApp)
end

function PhoneUI:DonwApp(appId, show)
    local save = LocalDataManager:GetDataByKey(MY_APP)
    if not save.downApp then
        save.downApp = {1}
    end
    
    for k,v in pairs(save.downApp) do
        if v == appId then--不重复下载
            return
        end
    end

    table.insert(save.downApp, appId)
    if show then
        self:GetView():Invoke("Refresh", save.downApp, appId)
    end
end

function PhoneUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PHONE_UI)
    self.m_view = nil
    collectgarbage("collect")
end