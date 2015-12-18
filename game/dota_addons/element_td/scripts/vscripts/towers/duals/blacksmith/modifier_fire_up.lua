modifier_fire_up = class({})

function modifier_fire_up:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	}
end

function modifier_fire_up:OnCreated()
	self.damage_bonus = self:GetAbility():GetSpecialValueFor("damage")
	self.level = self:GetAbility():GetLevel()
end

function modifier_fire_up:GetModifierDamageOutgoing_Percentage()
	return self.attack_speed_bonus
end

function modifier_fire_up:GetTexture()
    return "towers/blacksmith_tower_fire_up"
end

function modifier_fire_up:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_fire_up:GetEffectAttachType()
	return PATTACH_ABSORIGIN
end