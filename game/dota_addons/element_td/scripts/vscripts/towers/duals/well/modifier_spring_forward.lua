modifier_spring_forward = class({})

function modifier_spring_forward:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_spring_forward:OnCreated()
	self.attack_speed_bonus = self:GetAbility():GetSpecialValueFor("attack_speed")
	self.level = self:GetAbility():GetLevel()
end

function modifier_spring_forward:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_bonus
end

function modifier_spring_forward:GetEffectName()
	return "particles/custom/well_tower_spring_forward.vpcf"
end

function modifier_spring_forward:GetEffectAttachType()
	return PATTACH_ABSORIGIN
end