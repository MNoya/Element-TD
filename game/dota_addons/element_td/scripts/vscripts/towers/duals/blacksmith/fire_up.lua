blacksmith_tower_fire_up = class({})
LinkLuaModifier("modifier_fire_up", "towers/duals/blacksmith/modifier_fire_up", LUA_MODIFIER_MOTION_NONE)

function blacksmith_tower_fire_up:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	--Sounds:EmitSoundOnClient(caster:GetPlayerOwnerID(), "Hero_OgreMagi.Bloodlust.Target")

	local particleName = "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    if target:HasModifier("modifier_fire_up") then
    	target:RemoveModifierByName("modifier_fire_up")
    end

	target:AddNewModifier(caster, self, "modifier_fire_up", {
		duration = self:GetSpecialValueFor("duration")
	})
end

function blacksmith_tower_fire_up:CastFilterResultTarget(target)
	local result = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, self:GetCaster():GetTeamNumber())
	
	if result ~= UF_SUCCESS then
		return result
	end
	
	--[[if target:HasModifier("modifier_support_tower") then
		return UF_FAIL_CUSTOM
	end]]
	
	if IsServer() then
		local modifier = target:FindModifierByName("modifier_fire_up")
		if modifier and modifier.level > self:GetLevel() then
			return UF_FAIL_CUSTOM
		end
	end

	return UF_SUCCESS
end

function blacksmith_tower_fire_up:GetCustomCastErrorTarget(target)
	--[[if target:HasModifier("modifier_support_tower") then
		return "#etd_error_support_tower"
	end]]

	if IsServer() then
		local modifier = target:FindModifierByName("modifier_fire_up")
		if modifier and modifier.level > self:GetLevel() then
			return "#etd_error_higher_level_buff"
		end
	end

	return ""
end
