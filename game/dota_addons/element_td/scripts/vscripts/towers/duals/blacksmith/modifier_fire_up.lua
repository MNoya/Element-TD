modifier_fire_up = class({})

function modifier_fire_up:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
	}
end

function modifier_fire_up:OnCreated()
    if self:GetAbility() then
       self.damage_bonus = self:GetAbility():GetSpecialValueFor("damage")
       self.level = self:GetAbility():GetLevel()
    else
        self.damage_bonus = 15
        self.level = 1
    end
end

function modifier_fire_up:GetModifierBaseDamageOutgoing_Percentage()
	return self.damage_bonus
end

function modifier_fire_up:GetTexture()
    return "towers/blacksmith"
end

function modifier_fire_up:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_fire_up:GetEffectAttachType()
	return PATTACH_ABSORIGIN
end