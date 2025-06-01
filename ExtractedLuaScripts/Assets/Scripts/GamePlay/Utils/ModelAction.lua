local ModelAction = {}

local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper

local SOLDIER_ACTION = {
    SOLDIER_ACTION_IDLE = 0,
    SOLDIER_ACTION_MARCH = 1,
    SOLDIER_ACTION_MARCH_SPEEDUP = 2,
    SOLDIER_ACTION_ATTACK = 3,
    SOLDIER_ACTION_DIE = 10,
    SOLDIER_ACTION_MOVEIN = 11,
    SOLDIER_ACTION_CALC = 12,
    SOLDIER_ACTION_CURE = 13,
    SOLDIER_ACTION_HURT = 14,
    SOLDIER_ACTION_DYING = 15
}

local GUARDIAN_ACTION = {
    GUARDIAN_ACTION_IDLE = 0,
    GUARDIAN_ACTION_JUMPIN = 1,
    GUARDIAN_ACTION_JUMPOUT = 2,
    GUARDIAN_ACTION_SHOW = 3,
    GUARDIAN_ACTION_CAST_SKILL = 4
}

local SOLDIER_EFFECT = {
    SOLDIER_EFFECT_NORMAL = 0,
    SOLDIER_EFFECT_CLICKED = 1,
    SOLDIER_EFFECT_HURT = 2
}

local BUILDING_EFFECT = {
    BUILDING_EFFECT_NORMAL = 0,
    BUILDING_EFFECT_CLICKED = 1,
    BUILDING_EFFECT_HURT = 2
}

local HERO_ACTION = {
    IDLE = 0,
    MARCH = 1,
    CAST_SKILL = 3,
    JUMP_IN = 7,
    JUMP_OUT = 8
}

local CITY_ARMY_LINE_ACTION = {
    IDLE = 0,
    MOVE_FROM_BARRACK = 1,
    MOVE_FROM_HOSPITAL = 2
}

function ModelAction:SoldierIdle(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_IDLE)
    else
        print("SoldierIdle: no animator found ", go, go and go.name)
    end
end

function ModelAction:SoldierDie(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_DIE)
    end
end

function ModelAction:SoldierMarch(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_MARCH)
    end
end

function ModelAction:SoldierMarchSpeedup(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_MARCH_SPEEDUP)
    end
end

function ModelAction:SoldierAttack(go, postHandler, hitHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ATTACKING_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ATTACKING_HIT",
        function()
            if go and not go:IsNull() and hitHandler then
                hitHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_ATTACK)
    end
end

function ModelAction:SoldierMoveIn(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_MOVEIN)
    end
end

function ModelAction:SoldierCalculate(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_CALC)
    end
end

function ModelAction:SoldierHurt(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_HURT)
    end
end

function ModelAction:SoldierDying(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_DYING)
    end
end

function ModelAction:TowerHurt(go, postHandler)
    local animator = go:GetComponent("Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ACTION_END",
        function()
            if go and not go:IsNull() then
                if postHandler then
                    postHandler()
                end
            end
        end
    )
    animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_HURT)
end

function ModelAction:TowerIdle(go)
    local animator = go:GetComponent("Animator")
    animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_IDLE)
end

function ModelAction:TowerDying(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_DYING)
    end
end

function ModelAction:TowerAttack(go, postHandler, hitHandler)
    local animator = go:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ATTACKING_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ATTACKING_HIT",
        function()
            if go and not go:IsNull() and hitHandler then
                hitHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_ATTACK)
    end
end

function ModelAction:TowerCalculate(go, postHandler)
    local animator = go:GetComponent("Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ACTION_END",
        function()
            if go and not go:IsNull() then
                if postHandler then
                    postHandler()
                end
            end
        end
    )
    animator:SetInteger("Action", SOLDIER_ACTION.SOLDIER_ACTION_CALC)
end

function ModelAction:InCityArmyLineIdle(go)
    local animator = go:GetComponent("Animator")
    if animator then
        animator:SetInteger("Action", CITY_ARMY_LINE_ACTION.IDLE)
    end
end

function ModelAction:InCityArmyLineMoveFromBarrack(go, postHandler)
    local animator = go:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", CITY_ARMY_LINE_ACTION.MOVE_FROM_BARRACK)
    end
end

function ModelAction:InCityArmyLineMoveFromHospital(go, postHandler)
    local animator = go:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", CITY_ARMY_LINE_ACTION.MOVE_FROM_HOSPITAL)
    end
end

function ModelAction:GuardianJumpIn(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    animator.cullingMode = 0
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if animator then
                animator.cullingMode = 1
            end
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", GUARDIAN_ACTION.GUARDIAN_ACTION_JUMPIN)
    end
end

function ModelAction:GuardianJumpOut(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    animator.cullingMode = 0
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_JUMPOUT_END",
        function()
            if animator then
                animator.cullingMode = 1
            end
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", GUARDIAN_ACTION.GUARDIAN_ACTION_JUMPOUT)
    end
end

function ModelAction:GuardianShow(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    animator.cullingMode = 0
    AnimationUtil.AddKeyFrameEventOnObj(UnityHelper.FindTheChild(go, "Body").gameObject, "ACTION_END", function()
        if animator then
            animator.cullingMode = 1
        end
        if go and not go:IsNull() and postHandler then
            postHandler()
        end
    end)
    if animator then
        animator:SetInteger("Action", GUARDIAN_ACTION.GUARDIAN_ACTION_SHOW)
    end
end

function ModelAction:GuardianCastSkill(go, postHandler, nextEventHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "NEXT_EVENT",
        function()
            if go and not go:IsNull() and nextEventHandler then
                nextEventHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", GUARDIAN_ACTION.GUARDIAN_ACTION_CAST_SKILL)
    end
end

function ModelAction:GuardianIdle(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    if animator then
        animator:SetInteger("Action", GUARDIAN_ACTION.GUARDIAN_ACTION_IDLE)
    end
end

function ModelAction:HeroIdle(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    if animator then
        animator:SetInteger("Action", HERO_ACTION.IDLE)
    end
end

function ModelAction:HeroMarch(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    if animator then
        animator:SetInteger("Action", HERO_ACTION.MARCH)
    end
end

function ModelAction:HeroCastSkill(go, postHandler, nextEventHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "NEXT_EVENT",
        function()
            if go and not go:IsNull() and nextEventHandler then
                nextEventHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", HERO_ACTION.CAST_SKILL)
    end
end

function ModelAction:HeroJumpin(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", HERO_ACTION.JUMP_IN)
    end
end

function ModelAction:HeroJumpout(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "ACTION_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Action", HERO_ACTION.JUMP_OUT)
    end
end

function ModelAction:MonsterEffectClicked(go, postHandler)
    local obj = UnityHelper.GetFirstChild(go).gameObject
    local animator = obj:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        obj,
        "EFFECT_END",
        function()
            if obj and not obj:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Effect", SOLDIER_EFFECT.SOLDIER_EFFECT_CLICKED)
    end
end

function ModelAction:MonsterEffectHurt(go, postHandler)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(
        UnityHelper.FindTheChild(go, "Body").gameObject,
        "EFFECT_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Effect", SOLDIER_EFFECT.SOLDIER_EFFECT_HURT)
    end
end

function ModelAction:MonsterEffectNormal(go)
    local animator = UnityHelper.GetTheChildComponent(go, "Body", "Animator")
    if animator then
        animator:SetInteger("Effect", SOLDIER_EFFECT.SOLDIER_EFFECT_NORMAL)
    end
end

function ModelAction:BuildingEffectClicked(go, postHandler)
    if not go or go:IsNull() then
        return
    end
    local animator = go:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "EFFECT_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator and not animator:IsNull() then
        animator:SetInteger("Effect", BUILDING_EFFECT.BUILDING_EFFECT_CLICKED)
    end
end

function ModelAction:BuildingEffectHurt(go, postHandler)
    local animator = go:GetComponent("Animator")

    AnimationUtil.AddKeyFrameEventOnObj(
        go,
        "EFFECT_END",
        function()
            if go and not go:IsNull() and postHandler then
                postHandler()
            end
        end
    )

    if animator then
        animator:SetInteger("Effect", BUILDING_EFFECT.BUILDING_EFFECT_HURT)
    end
end

function ModelAction:BuildingEffectNormal(go)
    local animator = go:GetComponent("Animator")
    if animator then
        animator:SetInteger("Effect", BUILDING_EFFECT.BUILDING_EFFECT_NORMAL)
    end
end

return ModelAction
