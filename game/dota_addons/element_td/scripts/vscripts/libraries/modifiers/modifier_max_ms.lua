modifier_max_ms = class({})

function modifier_max_ms:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_MOVESPEED_MAX,
    }

    return funcs
end

function modifier_max_ms:GetModifierMoveSpeed_Max(params)
    return 6000
end

function modifier_max_ms:GetModifierMoveSpeedOverride(params)
    return 6000
end
