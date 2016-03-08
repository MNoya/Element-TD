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
	if damage <= 0 then return end --pls no negative damage

	-- Modify damage based on elements
	damage = ApplyElementalDamageModifier(damage, GetDamageType(attacker), GetArmorType(entity))
	local element = damage

	-- Increment damage based on debuffs
	damage = ApplyDamageAmplification(damage, entity, attacker)
	local amplified = damage

	damage = math.ceil(damage) --round up to the nearest integer
		
	if GameRules.DebugDamage then
		local sourceName = attacker.class
		local targetName = entity.class
		print("[DAMAGE] " .. sourceName .. " deals " .. damage .. " to " .. targetName .. " [" .. entity:entindex() .. "]")
		if (original ~= damage) then
			print("[DAMAGE]  Original: "..original.." | Element: "..element.." | Amplified: "..amplified)
		end
	end
	
	local playerID = attacker:GetPlayerOwnerID()
	local playerData = GetPlayerData(playerID)
	if playerData.godMode then
		damage = entity:GetMaxHealth()*2
	elseif playerData.zenMode then
		damage = 0
	end

	if entity:GetHealth() - damage <= 0 then
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		local goldBounty = entity:GetGoldBounty()

		-- Gold Tower
		if attacker.scriptClass == "GoldTower" and entity:IsAlive() and entity:GetGoldBounty() > 0 then
			goldBounty = attacker.scriptObject:ModifyGold(goldBounty)
			local extra_gold = goldBounty - entity:GetGoldBounty()
			
			playerData.goldTowerEarned = playerData.goldTowerEarned + extra_gold

			local origin = entity:GetAbsOrigin()
			origin.z = origin.z+128
			local particle = ParticleManager:CreateParticle("particles/custom/towers/gold/midas.vpcf", PATTACH_ABSORIGIN, entity)
    		ParticleManager:SetParticleControl(particle, 0, origin)
    		ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_attack1", attacker:GetAbsOrigin(), true)
    		if extra_gold > 0 then
    			PopupGoldGain(attacker, extra_gold)
    		end
		end

		-- Flame Tower
		if entity.SunburnData and entity.SunburnData.StackCount > 0 then
			CreateSunburnRemnant(entity)
		end
		
		hero:ModifyGold(goldBounty)

		if not entity.isUndead then
			IncrementKillCount(attacker)
			if entity:GetUnitName() ~= "icefrog" then
				EmitSoundOnLocationForAllies(entity:GetOrigin(), "Gold.Coins", hero)
			end
		end

		entity:Kill(nil, attacker)
	else
		entity:SetHealth(entity:GetHealth() - damage)
	end

	return damage
end

function DamageEntitiesInArea(origin, radius, attacker, damage)
	local entities = GetCreepsInArea(origin, radius)
	for _,e in pairs(entities) do
		DamageEntity(e, attacker, damage)
	end
end
--------------------------------------------------------------
--------------------------------------------------------------

function ApplyDamageAmplification(damage, creep, tower)
	local newDamage = damage
	local amp = 0

	-- Erosion
	local erosionModifier = creep:FindModifierByName("modifier_acid_attack_damage_amp")
	if erosionModifier then
		amp = amp + erosionModifier.damageAmp
	end

	-- Enchantment
	local ffModifier = creep:FindModifierByName("modifier_faerie_fire")
	if ffModifier then
		local creeps = GetCreepsInArea(creep:GetAbsOrigin(), ffModifier.findRadius)
		if #creeps <= 3 then
			amp = amp + ffModifier.maxAmp
		else
			amp = amp + ffModifier.baseAmp
		end
	end

	-- Vengeance
	local vModifier = tower:FindModifierByName("modifier_vengeance_debuff")
	if vModifier then
		amp = amp + vModifier.damageReduction
	end

	newDamage = newDamage * (1+ amp*0.01)

	if GameRules.DebugDamage and amp ~= 0 then
		print("[DAMAGE] Amplified damage done to "..creep:GetUnitName().." damage of "..damage.." to "..newDamage.." due to an amplification of "..amp)
	end

	return round(newDamage)
end

-- Handles blacksmith damage increasing for abilities
function ApplyAbilityDamageFromModifiers(damage, attacker)
	local newDamage = damage
	local fire_up = attacker:FindModifierByName("modifier_fire_up")
	if fire_up then
		newDamage = newDamage + (damage * fire_up.damage_bonus * 0.01)
		if GameRules.DebugDamage then
			print("[DAMAGE] Increased "..attacker.class.." damage of "..damage.." to "..newDamage.." due to Fire Up modifier.")
		end
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
