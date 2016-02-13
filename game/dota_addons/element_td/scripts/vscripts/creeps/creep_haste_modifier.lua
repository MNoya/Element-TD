creep_haste_modifier = class({})

function creep_haste_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }

    return funcs
end

function creep_haste_modifier:GetModifierMoveSpeed_Max( params )
    return 600
end

function creep_haste_modifier:GetModifierMoveSpeed_Limit( params )
    return 600
end

function creep_haste_modifier:GetModifierMoveSpeedBonus_Constant( params )
    return 600
end

function creep_haste_modifier:GetTexture()
    return "dark_seer_surge"
end

function creep_haste_modifier:GetEffectName()
    return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function creep_haste_modifier:GetEffectAttachType()
    return PATTACH_ABSORIGIN
end