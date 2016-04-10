modifier_max_ms_coop = class({})

function modifier_max_ms_coop:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_MOVESPEED_MAX,
    }

    return funcs
end

function modifier_max_ms_coop:GetModifierMoveSpeed_Max(params)
    return 1000
end

function modifier_max_ms_coop:GetModifierMoveSpeedOverride(params)
    return 1000
end

function modifier_max_ms_coop:IsHidden()
    return true
end
