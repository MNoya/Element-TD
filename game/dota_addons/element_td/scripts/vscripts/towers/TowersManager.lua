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

function GetTowerPlayerID(tower)
	return tower:GetOwner():GetPlayerID()
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

TOWER_TARGETING_HIGHEST_HP = 0 --Moss
TOWER_TARGETING_LOWEST_HP = 1 --Flame, Life, Disease, Gold
TOWER_TARGETING_CLOSEST = 2 --Default
TOWER_TARGETING_FARTHEST = 3 --Impulse, Obliteration
function GetTowerTarget(tower, target_type, radius)
	if tower then
		local radius = radius or tower:GetAttackRange()
		local find_type = FIND_CLOSEST
		if target_type == TOWER_TARGETING_FARTHEST then
			find_type = FIND_FARTHEST
		end
		local creeps = FindUnitsInRadius(tower:GetTeamNumber(), tower:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO, 0, find_type, false)
		if target_type == TOWER_TARGETING_FARTHEST or target_type == TOWER_TARGETING_CLOSEST then
			for k, v in pairs(creeps) do
				if v:GetTeam() == DOTA_TEAM_NEUTRALS then
					return v
				end
			end
		elseif target_type == TOWER_TARGETING_LOWEST_HP then
            local unit = nil
            for k, v in pairs(creeps) do
                if v:GetTeam() == DOTA_TEAM_NEUTRALS then
                    if unit == nil then
                        unit = v
                    elseif v:GetHealth() < unit:GetHealth() then
                        unit = v
                    end
                end
            end
            return unit

        elseif target_type == TOWER_TARGETING_HIGHEST_HP then
			local unit = nil
            for k, v in pairs(creeps) do
                if v:GetTeam() == DOTA_TEAM_NEUTRALS then
                    if unit == nil then
                        unit = v
                    elseif v:GetHealth() > unit:GetHealth() then
                        unit = v
                    end
                end
            end
            return unit
		end
	end
	return nil
end

function GetBuffTargetInRadius(caster, radius, modifierName, level)
	local towers = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local theChosenOne
    local bestPriority = 100
    
    for _,tower in pairs(towers) do
        if IsTower(tower) and tower:IsAlive() and not IsSupportTower(tower) and not tower.deleted then
            local priority = GetUnitKeyValue(tower:GetUnitName(), "BuffPriority")
            if priority <= bestPriority then
        
                local modifier = tower:FindModifierByName(modifierName)
                if not modifier or (level and level > modifier.level) then 
                    bestPriority = priority
                    theChosenOne = tower
                end
            end
        end
    end

    return theChosenOne
end

function GetCloneTargetInRadius(caster, radius)
	local towers = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local theChosenOne
    local bestPriority = 100
    
    for _,tower in pairs(towers) do
        if IsTower(tower) and tower:IsAlive() and not IsSupportTower(tower) and not tower.deleted then
            local priority = GetUnitKeyValue(tower:GetUnitName(), "BuffPriority")
            if priority <= bestPriority then
        
                if not tower:HasModifier("modifier_clone") and not tower:HasModifier("modifier_conjure_prevent_cloning") then
                    bestPriority = priority
                    theChosenOne = tower
                end
            end
        end
    end

    return theChosenOne
end