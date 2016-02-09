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
-- Water #01A2FF
-- Fire #C40000
-- Nature #00C400
-- Earth #D4880F
-- Light #E5DE23
-- Dark #8733C8

function DamageEntity(entity, attacker, damage)
	if not entity or not entity:IsAlive() then return end
	
	if entity:HasModifier("modifier_invulnerable") then return end

	local original = damage

	-- Modify damage based on elements
	damage = ApplyElementalDamageModifier(damage, GetDamageType(attacker), GetArmorType(entity))
	local element = damage

	-- Increment damage based on debuffs
	damage = ApplyDamageAmplification(damage, entity)
	local amplified = damage

	if GameRules.WhosYourDaddy then
		damage = entity:GetMaxHealth()*2
	end

	damage = math.ceil(damage) --round up to the nearest integer
	if damage < 0 then damage = 0 end --pls no negative damage
	
	if GameRules.DebugDamage then
		local sourceName = attacker.class
		local targetName = entity.class
		print("[DAMAGE] " .. sourceName .. " deals " .. damage .. " to " .. targetName .. " [" .. entity:entindex() .. "]")
		if (original ~= damage) then
			print("[DAMAGE]  Original: "..original.." | Element: "..element.." | Amplified: "..amplified)
		end
	end
	
	if entity:GetHealth() - damage <= 0 then
		local playerID = attacker:GetPlayerOwnerID()
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		local goldBounty = entity:GetGoldBounty()

		if attacker.scriptClass == "GoldTower" and entity:IsAlive() and entity:GetGoldBounty() > 0 then
			goldBounty = attacker.scriptObject:ModifyGold(goldBounty)
			
			local playerData = GetPlayerData(playerID)
			playerData.goldTowerEarned = playerData.goldTowerEarned + goldBounty

			local origin = entity:GetAbsOrigin()
			origin.z = origin.z+128
			local particle = ParticleManager:CreateParticle("particles/custom/towers/gold/midas.vpcf", PATTACH_ABSORIGIN, entity)
    		ParticleManager:SetParticleControl(particle, 0, origin)
    		ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_attack1", attacker:GetAbsOrigin(), true)
		end

		if entity.SunburnData and entity.SunburnData.StackCount > 0 then
			local team = DOTA_TEAM_BADGUYS
			if attacker:GetTeam() == DOTA_TEAM_GOODGUYS then team = DOTA_TEAM_BADGUYS end
			if attacker:GetTeam() == DOTA_TEAM_BADGUYS then team = DOTA_TEAM_GOODGUYS end
			CreateSunburnRemnant(entity, team)
		end
		
		hero:ModifyGold(goldBounty)
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
	return round(newDamage)
end

-- Handles blacksmith damage increasing for abilities
function ApplyAbilityDamageFromModifiers(damage, attacker)
	local newDamage = damage
	local fire_up = attacker:FindModifierByName("modifier_fire_up")
	if fire_up then
		newDamage = newDamage + (damage * fire_up.damage_bonus * 0.01)
	end
	return round(newDamage)
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

function GetElementColor(element)
	return Vector(ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
end