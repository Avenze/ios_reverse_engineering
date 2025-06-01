local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local AnimationUtil = CS.Common.Utils.AnimationUtil


local CycleCastleCutScreenUIView = Class("CycleCastleCutScreenUIView", UIView)

function CycleCastleCutScreenUIView:ctor()
    self.super:ctor()
end

function CycleCastleCutScreenUIView:OnEnter()
    self.m_anim = self.m_uiObj:GetComponent("Animation")
    self.m_record = {}
end

function CycleCastleCutScreenUIView:OnExit()
    self.super:OnExit(self)
end

function CycleCastleCutScreenUIView:Play(cb, spend)
    if self.m_curSpeed == spend then
        if cb then cb() end
        return
    end

    if spend == 1 then
        self.m_curSpeed = spend
    else
        self.m_curSpeed = nil
    end
    if self.m_anim:IsPlaying("CutToScene_Anim") then
        self.m_record[spend] = {c = cb}
        return
    end

    local key = nil
    if spend == -1 then
        key = "KEY_FRAME_ANIM_END"
    end
    AnimationUtil.Play(self.m_anim, "CutToScene_Anim", function()
        if cb then cb() end
        if spend == -1 then
            self:DestroyModeUIObject()
        elseif self.m_record[-1] then
            self:Play(self.m_record[-1].c, -1)
            self.m_record[-1] = nil
        end
    end, spend, key)
end

return CycleCastleCutScreenUIView