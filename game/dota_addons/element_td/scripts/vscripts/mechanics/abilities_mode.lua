if not CHALLENGE_MODE then
	CHALLENGE_MODE = false

	AbilitiesMode = {
		ChallengeAbilityChoices = {
			[1] = "creep_ability_bulky",
			[2] = "creep_ability_heal",
			[3] = "creep_ability_vengeance",
			[4] = "creep_ability_undead",
			[5] = "creep_ability_regen",
			[6] = "creep_ability_fast",
			[7] = "creep_ability_mechanical",
			[8] = "creep_ability_time_lapse"
		},
		ChallengeElementalAbilityChoices = {
			[1] = "creep_ability_regen",
			[2] = "creep_ability_fast",
			[3] = "creep_ability_mechanical",
			[4] = "creep_ability_time_lapse"
		},
		AbilityToClassName = {
			["creep_ability_bulky"] = "CreepBulky",
			["creep_ability_heal"] = "CreepHeal",
			["creep_ability_heal_super"] = "CreepHeal",
			["creep_ability_vengeance"] = "CreepVengeance",
			["creep_ability_vengeance_super"] = "CreepVengeance",
			["creep_ability_undead"] = "CreepUndead",
			["creep_ability_undead_instant"] = "CreepUndead",
			["creep_ability_regen"] = "CreepRegen",
			["creep_ability_regen_super"] = "CreepRegen",
			["creep_ability_fast"] = "CreepFast",
			["creep_ability_fast_super"] = "CreepFast",
			["creep_ability_fast_perma"] = "CreepFast",
			["creep_ability_mechanical"] = "CreepMechanical",
			["creep_ability_mechanical_super"] = "CreepMechanical",
			["creep_ability_time_lapse"] = "CreepTemporal",
			["creep_ability_time_lapse_super"] = "CreepTemporal"

		},
		ChallengeModeAbilities = {
			[1] = {"creep_ability_mechanical", "creep_ability_mechanical"},
			[2] = {"creep_ability_heal", "creep_ability_heal"},
			[3] = {"creep_ability_fast", "creep_ability_fast"},
			[4] = {"creep_ability_undead", "creep_ability_undead"},
			[5] = {"creep_ability_regen", "creep_ability_regen"},
			[6] = {"creep_ability_bulky", "creep_ability_bulky"},
			[7] = {"creep_ability_vengeance", "creep_ability_vengeance"},
			[8] = {"creep_ability_time_lapse", "creep_ability_time_lapse"},
			[9] = {"creep_ability_heal", "creep_ability_bulky"},
			[10] = {"creep_ability_undead", "creep_ability_mechanical"},
			[11] = {"creep_ability_time_lapse", "creep_ability_vengeance"},
			[12] = {"creep_ability_heal", "creep_ability_fast"},
			[13] = {"creep_ability_undead", "creep_ability_regen"},
			[14] = {"creep_ability_mechanical", "creep_ability_bulky"},
			[15] = {"creep_ability_fast", "creep_ability_vengeance"},
			[16] = {"creep_ability_undead_instant", "creep_ability_undead_instant"},
			[17] = {"creep_ability_heal", "creep_ability_mechanical"},
			[18] = {"creep_ability_time_lapse", "creep_ability_regen"},
			[19] = {"creep_ability_vengeance", "creep_ability_bulky"},
			[20] = {"creep_ability_fast", "creep_ability_mechanical"},
			[21] = {"creep_ability_heal", "creep_ability_undead"},
			[22] = {"creep_ability_time_lapse", "creep_ability_bulky"},
			[23] = {"creep_ability_vengeance", "creep_ability_mechanical"},
			[24] = {"creep_ability_fast", "creep_ability_regen"},
			[25] = {"creep_ability_undead", "creep_ability_bulky"},
			[26] = {"creep_ability_time_lapse", "creep_ability_mechanical"},
			[27] = {"creep_ability_fast_perma", "creep_ability_fast_perma"},
			[28] = {"creep_ability_vengeance_super", "creep_ability_vengeance_super"},
			[29] = {"creep_ability_undead", "creep_ability_time_lapse"},
			[30] = {"creep_ability_heal", "creep_ability_regen"},
			[31] = {"creep_ability_fast", "creep_ability_bulky"},
			[32] = {"creep_ability_undead", "creep_ability_vengeance"},
			[33] = {"creep_ability_regen", "creep_ability_mechanical"},
			[34] = {"creep_ability_fast", "creep_ability_time_lapse"},
			[35] = {"creep_ability_heal_super", "creep_ability_heal_super"},
			[36] = {"creep_ability_regen", "creep_ability_vengeance"},
			[37] = {"creep_ability_fast", "creep_ability_undead"},
			[38] = {"creep_ability_heal", "creep_ability_time_lapse"},
			[39] = {"creep_ability_regen_super", "creep_ability_regen_super"},
			[40] = {"creep_ability_mechanical_super", "creep_ability_mechanical_super"},
			[41] = {"creep_ability_heal", "creep_ability_vengeance"},
			[42] = {"creep_ability_regen", "creep_ability_bulky"},
			[43] = {"creep_ability_fast_super", "creep_ability_fast_super"},
			[44] = {"creep_ability_time_lapse_super", "creep_ability_time_lapse_super"},
			[45] = {"creep_ability_undead_instant", "creep_ability_mechanical_super"},
			[46] = {"creep_ability_heal", "creep_ability_bulky"},
			[47] = {"creep_ability_heal", "creep_ability_bulky"},
			[48] = {"creep_ability_heal", "creep_ability_bulky"},
			[49] = {"creep_ability_heal", "creep_ability_bulky"},
			[50] = {"creep_ability_heal", "creep_ability_bulky"},
			[51] = {"creep_ability_heal", "creep_ability_bulky"},
			[52] = {"creep_ability_heal", "creep_ability_bulky"},
			[53] = {"creep_ability_heal", "creep_ability_bulky"},
			[54] = {"creep_ability_heal", "creep_ability_bulky"},
			[55] = {"creep_ability_heal", "creep_ability_bulky"}
	}
	}
end

-- hooray for extremely long function names!

function AbilitiesMode:GenerateChallengeAbilities()
	local copy_choices = (function()
		local tab = {}
		for k, v in ipairs(self.ChallengeAbilityChoices) do
			tab[k] = v
		end
		return tab
	end)

	for i = 1, WAVE_COUNT - 1 do
		self.ChallengeModeAbilities[i] = {}
		local choices = copy_choices()
		local armor = creepsKV[WAVE_CREEPS[i]].CreepAbility1 and (creepsKV[WAVE_CREEPS[i]].CreepAbility1)
		local ability1 = table.remove(choices, math.random(#choices))
		local ability2 = table.remove(choices, math.random(#choices))

		table.insert(self.ChallengeModeAbilities[i], ability1)
		table.insert(self.ChallengeModeAbilities[i], ability2)

		if armor then armor = armor:gsub("_armor", "") end
		if ability1 then ability1 = ability1:gsub("creep_ability_", "") end
		if ability2 then ability2 = ability2:gsub("creep_ability_", "") end

        print(string.format("%2d | %-16s | %6.0f | %9s | %10s | %10s |",i,WAVE_CREEPS[i],WAVE_HEALTH[i],armor,ability1,ability2))
	end
end	

function AbilitiesMode:GetChallengeAbilitiesForWave(wave)
	return self.ChallengeModeAbilities[wave]
end

function AbilitiesMode:GetClassNameFromAbility(ability_name)
	return self.AbilityToClassName[ability_name]
end

function AbilitiesMode:GetRandomElementalAbilityName()
	return self.ChallengeElementalAbilityChoices[math.random(#self.ChallengeElementalAbilityChoices)]
end