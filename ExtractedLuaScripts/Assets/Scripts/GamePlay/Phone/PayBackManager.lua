local LightManager = GameTableDefine.LightManager
local GameClockManager = GameTableDefine.GameClockManager
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local PayBackManager = GameTableDefine.PayBackManager

local UnityHelper = CS.Common.Utils.UnityHelper;

local PAY_BACK = "pay_back"
function PayBackManager:PayBack(money)
end

function PayBackManager:isAllPayBack()
end