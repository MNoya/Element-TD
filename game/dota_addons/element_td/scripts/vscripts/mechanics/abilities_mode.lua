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
		table.insert(self.ChallengeModeAbilities[i], table.remove(choices, math.random(#choices)))
		table.insert(self.ChallengeModeAbilities[i], table.remove(choices, math.random(#choices)))
		Log:info("Wave " .. i .. " abilities: ")
		PrintTable(self.ChallengeModeAbilities[i])
	end
end	

function AbilitiesMode:GetChallengeAbilitiesForWave(wave)
	return self.ChallengeModeAbilities[wave]
end

function AbilitiesMode:GetClassNameFromAbility(ability_name)
	return self.AbilityToClassName[ability_name]
end
