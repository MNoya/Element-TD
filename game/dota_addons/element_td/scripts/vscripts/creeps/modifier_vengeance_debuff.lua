-- Stack display, keeps track of how much damage should be reduced
modifier_vengeance_debuff = class({})

function modifier_vengeance_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_BONUS, }
end

function modifier_vengeance_debuff:GetTexture()
    return "creeps/vengeance"
end

function modifier_vengeance_debuff:IsDebuff()
    return true
end

function modifier_vengeance_debuff:GetModifierHealthBonus()
    return self:GetStackCount() * 10
end

-- Individual modifier applied every time a creep is killed
modifier_vengeance_multiple = class({})

function modifier_vengeance_multiple:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_BONUS, }
end

function modifier_vengeance_multiple:GetTexture()
    return "creeps/vengeance"
end

function modifier_vengeance_multiple:IsHidden()
    return true
end

function modifier_vengeance_multiple:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_vengeance_multiple:GetEffectName()
    return "particles/custom/creeps/vengeance/debuff.vpcf"
end

function modifier_vengeance_multiple:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_vengeance_multiple:OnDestroy( params )
    if IsServer() then
        local tower = self:GetParent()

        if tower:HasModifier("modifier_vengeance_debuff") then
            local stackCount = tower:GetModifierStackCount("modifier_vengeance_debuff", tower) - 1
            local modifier = tower:FindModifierByName("modifier_vengeance_debuff")
            if stackCount <= 0 then
                modifier:Destroy()
                stackCount = 0
            else
                modifier:DecrementStackCount()
            end
            modifier.damageReduction = modifier.baseDamageReduction * stackCount
        end
    end
end