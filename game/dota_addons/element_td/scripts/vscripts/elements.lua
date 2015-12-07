-- elements.lua
-- manages damage modifier mostly

CreepsClass = "npc_dota_creep_neutral" -- all creeps have this baseclass

DamageModifiers = {
	composite = {
		--100% to all
	},
	fire = {
		nature = 2.0,
		water = 0.5,
		composite = 0.9
	},
	water = {
		fire = 2.0,
		dark = 0.5,
		composite = 0.9
	},
	nature = {
		earth = 2.0,
		fire = 0.5,
		composite = 0.9
	},
	earth = {
		light = 2.0,
		nature = 0.5,
		composite = 0.9
	},
	light = {
		dark = 2.0,
		earth = 0.5,
		composite = 0.9
	},
	dark = {
		water = 2.0,
		light = 0.5,
		composite = 0.9
	}
}

ElementColors = {
	composite = {255, 255, 255}, water = {1, 162, 255},	fire = {196, 0, 0}, nature = {0, 196, 0},
	earth = {212, 136, 15}, light = {229, 222, 35}, dark = {132, 51, 200}
}

function DamageEntity(entity, attacker, damage)
	if not entity or not entity:IsAlive() then return end
	
	if entity:HasModifier("modifier_invulnerable") then return end
	--damage = ApplyDifficultyArmor(damage, attacker)
	damage = ApplyElementalDamageModifier(damage, GetDamageType(attacker), GetArmorType(entity))
	damage = ApplyDamageAmplification(damage, entity)

	damage = math.ceil(damage) --round up to the nearest integer
	if damage < 0 then damage = 0 end --pls no negative damage
	
	--print("Dealing " .. damage .. " damage to " .. entity.class .. " [" .. entity:entindex() .. "]")
	
	if entity:GetHealth() - damage <= 0 then

		if attacker.scriptClass == "GoldTower" and entity:IsAlive() and entity:GetGoldBounty() > 0 then
			local goldBounty = entity:GetGoldBounty()
			goldBounty = attacker.scriptObject:ModifyGold(goldBounty)
			entity:SetMaximumGoldBounty(goldBounty)
			entity:SetMinimumGoldBounty(goldBounty)

			local particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN, entity)
    		ParticleManager:SetParticleControl(particle, 0, entity:GetAbsOrigin())
    		ParticleManager:SetParticleControl(particle, 1, attacker.scriptObject:GetAttackOrigin())
		end

		if entity.SunburnData and entity.SunburnData.StackCount > 0 then
			local team = DOTA_TEAM_BADGUYS
			if attacker:GetTeam() == DOTA_TEAM_GOODGUYS then team = DOTA_TEAM_BADGUYS end
			if attacker:GetTeam() == DOTA_TEAM_BADGUYS then team = DOTA_TEAM_GOODGUYS end
			CreateSunburnRemnant(entity, team)
		end
		
		entity:Kill(nil, attacker)
	else
		entity:SetHealth(entity:GetHealth() - damage)
	end
end

function DamageEntitiesInArea(origin, radius, attacker, damage)
	local entities = GetCreepsInArea(origin, radius)
	for _,e in pairs(entities) do
		DamageEntity(e, attacker, damage)
	end
end
--------------------------------------------------------------
--------------------------------------------------------------

-- ampAmount is a number between 0 and 100 (%)
function AddDamageAmpModifierToCreep(creep, modifierName, ampAmount)
	if not creep.DamageAmpTable then
		creep.DamageAmpTable = {
			[modifierName] = ampAmount
		}
	else
		if not creep.DamageAmpTable[modifierName] then
			creep.DamageAmpTable[modifierName] = ampAmount
		elseif ampAmount > creep.DamageAmpTable[modifierName] then
			creep.DamageAmpTable[modifierName] = ampAmount
		end
	end
end

function RemoveDamageAmpModifierFromCreep(creep, modifierName)
	if creep.DamageAmpTable and creep.DamageAmpTable[modifierName] then
		creep.DamageAmpTable[modifierName] = nil
	end
end

function ApplyDamageAmplification(damage, creep)
	local newDamage = damage
	if creep.DamageAmpTable then
		for name, value in pairs(creep.DamageAmpTable) do
			newDamage = newDamage + (damage * (value / 100))
		end
	end
	return math.floor(newDamage + 0.5)
end

--modifies damages from modifier registered in TOWER_MODIFIERS
function ApplyAttackDamageFromModifiers(damage, attacker)
	local baseDamage = damage
	for mod, data in pairs(TOWER_MODIFIERS) do
		if attacker:HasModifier(mod) then
			if data.bonus_damage then
				damage = damage + data.bonus_damage
			end
			if data.bonus_damage_percent then
				damage = damage + ((data.bonus_damage_percent / 100) * baseDamage)
			end
		end
	end
	return math.floor(damage + 0.5)
end

--modifies damages from modifier registered in TOWER_MODIFIERS
function ApplyAbilityDamageFromModifiers(damage, attacker)
	local baseDamage = damage
	for mod, data in pairs(TOWER_MODIFIERS) do
		if attacker:HasModifier(mod) then
			if data.bonus_ability_damage then
				damage = damage + data.bonus_ability_damage
			end
			if data.bonus_ability_damage_percent then
				damage = damage + ((data.bonus_ability_damage_percent / 100) * baseDamage)
			end
		end
	end
	return math.floor(damage + 0.5)
end

-- applies the armor modifier based on the current difficulty
function ApplyDifficultyArmor(damage, attacker)
	return damage * (1 - GetPlayerDifficulty(attacker:GetOwner():GetPlayerID()):GetArmorValue())
end

-- applies the element damage modifier
function ApplyElementalDamageModifier(damage, inflictingElement, targetElement)
	if DamageModifiers[inflictingElement][targetElement] then
		return damage * DamageModifiers[inflictingElement][targetElement]
	else
		return damage
	end
end

-- returns a unit's elemental armor type
function GetArmorType(entity)
	for element, data in pairs(DamageModifiers) do
		if entity:HasAbility(element .. "_armor") then
			return element
		end
	end
	Log:warn("Could not find armor type for entity " .. entity:entindex())
	return "composite"
end

function GetDamageType(tower)
	local element = GetUnitKeyValue(tower.class, "DamageType")
	if element then
		return element
	else
		Log:warn("Unable to find damage type for " .. tower.class)
		return "composite"
	end
end