local ChooseUI = GameTableDefine.ChooseUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger

function ChooseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CHOOSE_UI, self.m_view, require("GamePlay.Common.UI.ChooseUIView"), self, self.CloseView)
    return self.m_view
end

function ChooseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CHOOSE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ChooseUI:BindFunction(cb, title, spend)
    self:GetView():Invoke("BindFunction", cb, title, spend)
end

function ChooseUI:ShowCloudConfirm(txt, cb)
    local title = GameTextLoader:ReadText(txt)
    self:GetView():Invoke("ShowCloudConfirm", title, cb)
end

function ChooseUI:Choose(txt, cb)
    local title = GameTextLoader:ReadText(txt)
    self:GetView():Invoke("CommonChoose", title, cb, true, nil)
end

function ChooseUI:ChooseMore(txt, price, cb)
    local title = GameTextLoader:ReadText(txt)
    title = string.format(title, price)
    self:GetView():Invoke("Choose", title, cb)
end

function ChooseUI:CommonChoose(txt, cb, showCancel, canceCb, extendType, extendNum)---文本, 确定回调, 显示取消按钮, 取消回调, 额外显示的资源和数量，可以为nil
    local title = GameTextLoader:IsTextID(txt) and GameTextLoader:ReadText(txt) or txt
    --title = string.format(title, price)
    self:GetView():Invoke("CommonChoose", title, cb, showCancel, canceCb, nil, extendType, extendNum)
end

function ChooseUI:EarnCash(addValue, successCb, txt)
    if ResMgr:CashCurrMax(addValue) then
        self:CommonChoose("TXT_TIP_CASH_LIMIT_REWARD", successCb, true)
        --if successCb then successCb() end
    elseif txt then        
        self:ChooseMore(txt, math.floor(addValue), successCb)
    elseif successCb then         
        successCb()      
    end
end