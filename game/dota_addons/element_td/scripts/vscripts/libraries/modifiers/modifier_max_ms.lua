modifier_max_ms = class({})

function modifier_max_ms:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_MOVESPEED_MAX,
    }

    return funcs
end

function modifier_max_ms:OnCreated(params)
    if params.ms then
        self:SetStackCount(params.ms)
    end
end

function modifier_max_ms:GetModifierMoveSpeed_Max(params)
    return self:GetStackCount()
end

function modifier_max_ms:GetModifierMoveSpeedOverride(params)
    return self:GetStackCount()
end

function modifier_max_ms:IsHidden()
    return true
end
