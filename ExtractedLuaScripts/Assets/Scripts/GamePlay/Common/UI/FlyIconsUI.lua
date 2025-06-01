---@class FlyIconsUI
local FlyIconsUI = GameTableDefine.FlyIconsUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CutScreenUI = GameTableDefine.CutScreenUI
local EventManager = require("Framework.Event.Manager")

function FlyIconsUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FLY_ICONS_UI, self.m_view, require("GamePlay.Common.UI.FlyIconsUIView"), self, self.CloseView)
    return self.m_view
end

function FlyIconsUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FLY_ICONS_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function FlyIconsUI:Init()
    EventManager:RegEvent("FLY_ICON", function(pos, icon, num, cb)--Cash:2,Diamond:3,Ticket:3
        FlyIconsUI:GetView():Invoke("Show", pos, icon, num, cb)
    end);
end


function FlyIconsUI:SetScenceSwitchEffect(state, cb)
    --self.m_scenceSwitchEffect = state --1 透明向不透明渐变， 2 不透明向透明渐变
    --self:SetSceneSwitchMask(1, 0)
    CutScreenUI:Play(state, cb)
end

function FlyIconsUI:SetSceneSwitchMask(percent, state)
    -- if self.m_scenceSwitchEffect then
    --     if self.m_scenceSwitchEffect == 1 then
    --         percent = 1 - percent
    --     end
    --     FlyIconsUI:GetView():Invoke("SetSceneSwitchMask", percent, state)
    -- end
end

function FlyIconsUI:WaitingService(isWaiting)
    self:GetView():Invoke("setPurchaseCheck", isWaiting)
end

function FlyIconsUI:FailService()
    self:GetView():Invoke("FailService")
end

function FlyIconsUI:SetNetWorkLoading(enable)
    self:GetView():Invoke("SetNetWorkLoading", enable)
end

function FlyIconsUI:ShowMoveAn(go, icon, cb)
    FlyIconsUI:GetView():Invoke("ShowMoveAn",go , icon, cb)
end

function FlyIconsUI:SetInstanceResItem(res)
    FlyIconsUI:GetView():Invoke("SetInstanceResItem", res)
end

---设置循环副本资源数量
---@param res CycleFlyIconResInfo[]
function FlyIconsUI:SetCycleInstanceNum(res, cb)
    FlyIconsUI:GetView():Invoke("SetCycleInstanceNum", res, cb)
end

---播放副本任务提示
function FlyIconsUI:ShowTaskTip()
    FlyIconsUI:GetView():Invoke("ShowTaskTip")
end

---副本房间界面家具升级的里程碑积分奖励
function FlyIconsUI:ShowCycleMilepost(index,flyPath,str,cb)
    FlyIconsUI:GetView():Invoke("ShowCycleMilepost",index,flyPath,str,cb)
end

---房间升级，播放存钱罐动画
function FlyIconsUI:ShowPiggyBankAnim(diamondCount, cb)
    FlyIconsUI:GetView():Invoke("ShowPiggyBankAnim", diamondCount, cb)
end

--[[
    @desc: CEO系统开启后花费钻石时的飞图标功能
    author:{author}
    time:2025-02-21 12:17:57
    --@spendDia:
	--@oldNum:
	--@cb: 
    @return:
]]
function FlyIconsUI:ShowCEOSpendDiamondAnim(spendDia, oldNum, addkey, cb)
    FlyIconsUI:GetView():Invoke("ShowCEOSpendDiamondAnim", spendDia, oldNum, addkey, cb)
end

function FlyIconsUI:ShowCEOAddKeyAnim(keysType, addKeys, isNeedFly, cbKey, cbChest)
    FlyIconsUI:GetView():Invoke("ShowCEOAddKeyAnim", keysType, addKeys, isNeedFly, cbKey, cbChest)
end

---拉霸机，播放副本存钱罐动画
function FlyIconsUI:ShowNightClubPiggyBankAnim(cb, diamondCount)
    FlyIconsUI:GetView():Invoke("ShowNightClubPiggyBankAnim", cb, diamondCount)
end

function FlyIconsUI:ShowClockOutPopupUIAnim(cb)
    self:GetView():Invoke("ShowClockOutPopupUIAnim", cb)
end

function FlyIconsUI:ShowClockOutTicketsGetAnim(num, cb)
    self:GetView():Invoke("ShowClockOutTicketsGetAnim", num, cb)
end