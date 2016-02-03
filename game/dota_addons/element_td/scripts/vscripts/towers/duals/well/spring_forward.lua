-- Well tower's Spring Forward ability

well_tower_spring_forward = class({})
LinkLuaModifier("modifier_spring_forward", "towers/duals/well/modifier_spring_forward", LUA_MODIFIER_MOTION_NONE)

function well_tower_spring_forward:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	--Sounds:EmitSoundOnClient(caster:GetPlayerOwnerID(), "DOTA_Item.ClarityPotion.Activate")

	local particle1 = ParticleManager:CreateParticle("particles/items3_fx/mango_active.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particle1, 0, caster:GetAbsOrigin())

    local particle2 = ParticleManager:CreateParticle("particles/items3_fx/mango_active.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle2, 0, target:GetAbsOrigin())

    if target:HasModifier("modifier_spring_forward") then
    	target:RemoveModifierByName("modifier_spring_forward")
    end

	target:AddNewModifier(caster, self, "modifier_spring_forward", {
		duration = self:GetSpecialValueFor("duration")
	})
end

function well_tower_spring_forward:CastFilterResultTarget(target)
	local result = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, self:GetCaster():GetTeamNumber())
	
	if result ~= UF_SUCCESS then
		return result
	end
	
	if target:HasModifier("modifier_support_tower") then
		return UF_FAIL_CUSTOM
	end
	
	if IsServer() then
		local modifier = target:FindModifierByName("modifier_spring_forward")
		if modifier and modifier.level > self:GetLevel() then
			return UF_FAIL_CUSTOM
		end
	end

	return UF_SUCCESS;
end

function well_tower_spring_forward:GetCustomCastErrorTarget(target)
	if target:HasModifier("modifier_support_tower") then
		return "#etd_error_support_tower"
	end

	if IsServer() then
		local modifier = target:FindModifierByName("modifier_spring_forward")
		if modifier and modifier.level > self:GetLevel() then
			return "#etd_error_higher_level_buff"
		end
	end

	return ""
end
