modifier_conjure_prevent_cloning = class({})

function modifier_conjure_prevent_cloning:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_conjure_prevent_cloning:GetTexture()
    return "towers/trickery"
end

function modifier_conjure_prevent_cloning:GetEffectName()
    return "particles/custom/towers/trickery/buff_glow.vpcf"
end

function modifier_conjure_prevent_cloning:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_conjure_prevent_cloning:IsDebuff()
    return true
end

function modifier_conjure_prevent_cloning:IsPurgable()
    return false
end
