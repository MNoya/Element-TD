modifier_conjure_prevent_cloning = class({})

function modifier_conjure_prevent_cloning:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_conjure_prevent_cloning:GetTexture()
    return "modifier_illusion"
end

function modifier_conjure_prevent_cloning:IsDebuff()
    return true
end

function modifier_conjure_prevent_cloning:IsPurgable()
    return false
end
