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
			["creep_ability_vengeance"] = "CreepVengeance",
			["creep_ability_undead"] = "CreepUndead",
			["creep_ability_regen"] = "CreepRegen",
			["creep_ability_fast"] = "CreepFast",
			["creep_ability_mechanical"] = "CreepMechanical",
			["creep_ability_time_lapse"] = "CreepTemporal"

		},
		ChallengeModeAbilities = {}
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