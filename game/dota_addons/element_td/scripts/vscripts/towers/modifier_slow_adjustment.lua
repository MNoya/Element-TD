if not modifier_slow_adjustment then
    modifier_slow_adjustment = class({})
end

function modifier_slow_adjustment:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE, }
end

function modifier_slow_adjustment:IsHidden()
    return true
end

if IsClient() then return end --This causes the UI to never update, but the actual ms value will be correct

SLOWING_MODIFIERS = {"modifier_tornado_slow", "modifier_explode_slow", "modifier_gaias_wrath_slow", "modifier_sludge_slow"}
SLOWING_VALUES = {[1]=0.1,[2]=0.3}

function modifier_slow_adjustment:GetModifierMoveSpeedOverride()
    local unit = self:GetParent()
    local movespeed = 300

    if unit:HasModifier("creep_haste_modifier") then
        return 522
    end
    
    local slows = {}
    for _,name in pairs(SLOWING_MODIFIERS) do
        local modifier = unit:FindModifierByName(name)
        if modifier then
            local ability = modifier:GetAbility()
            local level = ability and ability:GetLevel() or 1
            table.insert(slows, SLOWING_VALUES[level])
        end
    end

    if #slows > 1 then
        for _,value in pairs(slows) do
            movespeed = movespeed * (1-value)
        end
    end

    return movespeed
end