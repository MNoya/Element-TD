modifier_clone = class({})

function modifier_clone:GetStatusEffectName()
    return "particles/status_fx/status_effect_slark_shadow_dance.vpcf"
end

function modifier_clone:GetEffectName()
    return "particles/custom/towers/trickery/buff.vpcf"
end

function modifier_clone:GetTexture()
    return "towers/trickery"
end

function modifier_clone:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_clone:OnDestroy( params )
    if IsServer() then
        RemoveClone(self:GetParent())
    end
end