--manages towers
if not TOWER_CLASSES then
	TOWER_CLASSES = {}
	TOWER_MODIFIERS = {}
end

function RegisterTowerClass(class, name)
	if TOWER_CLASSES[name] then return end
	if not class and name then
		Log:warn("Attemped to create nil class: " .. name)
	else
		if not class.OnCreated then
			class.OnCreated = (function(self) end)
		end
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