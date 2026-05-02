local modes = {
    {modifier = "modifier_tower_targeting_closest", texture = "sniper_take_aim"},
    {modifier = "modifier_tower_targeting_farthest", texture = "enchantress_impetus"},
    {modifier = "modifier_tower_targeting_lowest_hp", texture = "bloodseeker_thirst"},
    {modifier = "modifier_tower_targeting_highest_hp", texture = "life_stealer_feast"},
    {modifier = "modifier_tower_targeting_older", texture = "faceless_void/jewelofaeons/faceless_void_time_walk_1"},
    {modifier = "modifier_tower_targeting_newer", texture = "faceless_void_time_dilation"}
}

local function RegisterTargetingModifier(modifierName)
    LinkLuaModifier(modifierName, "towers/tower_targeting", LUA_MODIFIER_MOTION_NONE)

    _G[modifierName] = class({})
    local modifier = _G[modifierName]

    function modifier:IsHidden()
        return true
    end

    function modifier:IsPurgable()
        return false
    end

    function modifier:RemoveOnDeath()
        return false
    end
end

for _, mode in ipairs(modes) do
    RegisterTargetingModifier(mode.modifier)
end

tower_targeting = class({})

function tower_targeting:OnSpellStart()
    if IsServer() then
        CycleTowerTargeting(self:GetCaster())
    end
end

function tower_targeting:GetAbilityTextureName()
    local caster = self:GetCaster()
    if not caster then
        return modes[1].texture
    end

    for _, mode in ipairs(modes) do
        if caster:HasModifier(mode.modifier) then
            return mode.texture
        end
    end

    return modes[1].texture
end
