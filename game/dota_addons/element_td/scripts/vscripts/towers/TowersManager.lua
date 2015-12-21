--manages towers
if not TOWER_CLASSES then
	TOWER_CLASSES = {}
	TOWER_MODIFIERS = {}
end

function RegisterTowerClass(class, name)
	if not class and name then
		Log:warn("Attemped to create nil class: " .. name)
	else
		class.OnCreated = class.OnCreated or (function(self) end)
		class.OnBuildingFinished = class.OnBuildingFinished or (function(self) end)
		
		TOWER_CLASSES[name] = class
		Log:debug("Registered " .. name .. " tower class")
	end
end

function RegisterModifier(modifier, data)
	--[[
	[modifier] is the modifier name as defined in keyvalues
	[data] is a table of modifier values. Example:
	{
		bonus_damage = 100, --grants 100 bonus damage on auto-attacks
		bonus_damage_percent = 30, --grants 30% bonus damage on auto-attacks
		bonus_ability_damage = 100, --grants 100 bonus damage on abilities
		bonus_ability_damage_percent = 30 --grants 30% bonus damage on abilities
	}
	]]--
	TOWER_MODIFIERS[modifier] = data
end

function GetTowerPlayerID(tower)
	return tower:GetOwner():GetPlayerID()
end

function HasAnyModifier(entity, modifier)
	if not entity then return false end
	if type(modifier) == "string" then
		return entity:HasModifier(modifier)
	elseif type(modifier) == "table" then
		for _,v in pairs(modifier) do
			if entity:HasModifier(v) then
				return true
			end
		end
		return false
	else
		return false
	end
end

function GetAbility(tower, name)
	return tower:FindAbilityByName(name)
end

function IsSupportTower(tower)
	return GetUnitKeyValue(tower.class, "TowerType") == "Support"
end

function IsTower(entity)
	return entity.element and string.find(entity.class, "tower") ~= nil
end

TOWER_TARGETING_HIGHEST_HP = 0
TOWER_TARGETING_LOWEST_HP = 1
TOWER_TARGETING_CLOSEST = 2
TOWER_TARGETING_FARTHEST = 3
function GetTowerTarget(tower, type)
	if tower then
		local radius = tower:GetAttackRange()
		local find_type = FIND_CLOSEST
		if type == TOWER_TARGETING_FARTHEST then
			find_type = FIND_FARTHEST
		end

		local creeps = FindUnitsInRadius(0, center, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, find_type, false)
		if type == TOWER_TARGETING_FARTHEST or type == TOWER_TARGETING_CLOSEST then
			for k, v in pairs(creeps) do
				if v:GetTeam() == DOTA_TEAM_NEUTRAL then
					return k
				end
			end
		elseif type == TOWER_TARGETING_LOWEST_HP or type == TOWER_TARGETING_HIGHEST_HP then
			local unit = nil
			for k, v in pairs(creeps) do
				if v:GetTeam() == DOTA_TEAM_NEUTRAL then
					if unit == nil then
						unit = v
					elseif type == TOWER_TARGETING_LOWEST_HP and v:GetHealth() < unit:GetHealth() then
						unit = v
					elseif type == TOWER_TARGETING_HIGHEST_HP and v:GetHealth() > unit:GetHealth() then
						unit = v
					end
				end
			end
			return unit
		end
		return nil
	end
end