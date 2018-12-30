--manages towers
if not TOWER_CLASSES then
	TOWER_CLASSES = {}
	TOWER_MODIFIERS = {}
    HULL_RADIUS = 50
end

function RegisterTowerClass(class, name)
	if not class and name then
		Log:warn("Attemped to create nil class: " .. name)
	else
		class.OnCreated = class.OnCreated or (function(self) end)
		class.OnBuildingFinished = class.OnBuildingFinished or (function(self) end)
		
		TOWER_CLASSES[name] = class
		--Log:debug("Registered " .. name .. " tower class")
	end
end

function GetTowerPlayerID(tower)
	return tower:GetOwner():GetPlayerID()
end

function GetAbility(tower, name)
	return tower:FindAbilityByName(name)
end

function GetExplosionFX(tower)
    return GetUnitKeyValue(tower:GetUnitName(), "ExplosionEffect") or "particles/custom/towers/cannon/cannon_liquid_fire_explosion.vpcf"
end

function IsSupportTower(tower)
	return GetUnitKeyValue(tower.class, "TowerType") == "Support"
end

function IsTower(entity)
	return entity.class and string.find(entity.class, "tower") ~= nil
end

TOWER_TARGETING_HIGHEST_HP = 0 --Moss
TOWER_TARGETING_LOWEST_HP = 1 --Flame, Life, Disease, Gold
TOWER_TARGETING_CLOSEST = 2 --Default
TOWER_TARGETING_FARTHEST = 4 --Impulse, Obliteration
TOWER_TARGETING_OLDER = 8 --Filter creep wave IDs
function GetTowerTarget(tower, target_type, radius)
	if tower then
		local radius = radius or tower:GetAcquisitionRange()
		local find_type = FIND_CLOSEST
		if target_type == TOWER_TARGETING_FARTHEST then
			find_type = FIND_FARTHEST
		end
		local creeps = FindUnitsInRadius(tower:GetTeamNumber(), tower:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO, 0, find_type, false)

        -- Older can be used in addition with other types, it will filter out creeps from newer waves and recently leaked creeps
        local olderWave = 100
        if TargetFlag( target_type, TOWER_TARGETING_OLDER ) then
            for _,v in pairs(creeps) do
                if not v.recently_leaked and v.waveNumber and v.waveNumber < olderWave then
                    olderWave = v.waveNumber
                end
            end

            -- Execute the rest of the logic based on this limited set of creeps
            local newCreeps = creeps
            creeps = {}
            for _,v in pairs(newCreeps) do
                if not v.recently_leaked and (not v.waveNumber or v.waveNumber == olderWave) then
                    table.insert(creeps, v)
                end
            end

            -- If no creep, just use everything
            if #creeps == 0 then
                creeps = newCreeps
            end
        end

		if TargetFlag(target_type, TOWER_TARGETING_FARTHEST) or TargetFlag(target_type, TOWER_TARGETING_CLOSEST) then
			for _,v in pairs(creeps) do
				if v:GetTeam() == DOTA_TEAM_NEUTRALS then
					return v
				end
			end
		elseif TargetFlag(target_type, TOWER_TARGETING_LOWEST_HP) then
            local unit = nil
            for _,v in pairs(creeps) do
                if v:GetTeam() == DOTA_TEAM_NEUTRALS then
                    if unit == nil then
                        unit = v
                    elseif v:GetHealth() < unit:GetHealth() then
                        unit = v
                    end
                end
            end
            return unit

        elseif TargetFlag(target_type, TOWER_TARGETING_HIGHEST_HP) then
			local unit = nil
            for _,v in pairs(creeps) do
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

function TargetFlag( type, flag )
    return bit.band( type, flag ) == flag
end

function GetBuffTargetInRadius(caster, radius, modifierName, level)
	local towers = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local theChosenOne
    local bestPriority = 100
    
    for _,tower in pairs(towers) do
        if IsTower(tower) and tower:IsAlive() and not IsSupportTower(tower) and not tower:HasModifier("modifier_clone") and not tower.deleted then
            local priority = GetUnitKeyValue(tower:GetUnitName(), "BuffPriority")
            if priority <= bestPriority then
        
                local modifier = tower:FindModifierByName(modifierName)
                if not modifier or (modifier and level > modifier.level) then
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
    local level = caster:GetLevel()
    
    for _,tower in pairs(towers) do
        if IsTower(tower) and tower:IsAlive() and tower:GetHealthPercent() == 100 and not IsSupportTower(tower) and not tower.deleted and (level > 2 or tower:GetAttackTarget()) then
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

function InitializeKillCount(tower)
    tower:AddNewModifier(tower, nil, "modifier_kill_count", {})
end

function TransferKillCount(stacks, upgraded_tower)
    upgraded_tower:SetModifierStackCount("modifier_kill_count", upgraded_tower, stacks)
end

function IncrementKillCount(tower)
    if not tower or not IsValidEntity(tower) then return end

    local modifier = tower:FindModifierByName("modifier_kill_count")
    if modifier then
        tower:SetModifierStackCount("modifier_kill_count", tower, tower:GetModifierStackCount("modifier_kill_count", tower) + 1)
    end
end

function RemoveRandomBuff(tower)
    local origin = tower:GetAbsOrigin()
    local modifier_name
    if tower.class == "blacksmith_tower" then
        modifier_name = "modifier_fire_up"
    elseif tower.class == "well_tower" then
        modifier_name = "modifier_spring_forward"
    else
        return
    end

    local buffed = {}
    local towers = FindUnitsInRadius(tower:GetTeamNumber(), origin, nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _,tower in pairs(towers) do
        if tower:HasModifier(modifier_name) then
            table.insert(buffed, tower)
        end
    end

    if #buffed > 0 then
        local duration = 0
        local removeTarget
        -- Choose the target with the newest modifier (longest time remaining)
        for _,target in pairs(buffed) do
            local modifier = target:FindModifierByName(modifier_name)
            local currentDuration = modifier:GetRemainingTime()
            if modifier and currentDuration > duration then
                duration = currentDuration
                removeTarget = target
            end
        end
        if removeTarget then
            removeTarget:RemoveModifierByName(modifier_name)
        end
    end
end

function GetBuffData( tower )
    local buffData = {}
    local buffs = {"modifier_fire_up", "modifier_spring_forward", "modifier_conjure_prevent_cloning", "modifier_vengeance_debuff"}
    for _,modifierName in pairs(buffs) do
        local modifier = tower:FindModifierByName(modifierName)
        if modifier then
            buffData[modifierName] = {}
            buffData[modifierName].caster = modifier:GetCaster()
            buffData[modifierName].ability = modifier:GetAbility()
            buffData[modifierName].duration = modifier:GetDuration()
            
            if modifierName == "modifier_vengeance_debuff" then
                local stacks = modifier:GetStackCount()
                if stacks > 0 then
                    buffData[modifierName].ability = nil
                    buffData[modifierName].caster = nil
                    buffData[modifierName].stacks = stacks
                    buffData[modifierName].baseDamageReduction = modifier.baseDamageReduction
                    buffData[modifierName].damageReduction = modifier.baseDamageReduction * stacks
                end
            end
        end
    end
    return buffData
end

function ReapplyModifiers(tower, buffData)
    for modifierName,data in pairs(buffData) do
        if not caster then data.caster = tower end
        tower:AddNewModifier(data.caster, data.ability, modifierName, {duration = data.duration})

        if data.stacks then
            local modifier = tower:FindModifierByName(modifierName)
            if modifier and data.damageReduction then
                modifier.baseDamageReduction = data.baseDamageReduction
                modifier.damageReduction = data.damageReduction
                modifier:SetStackCount(data.stacks)
                
                for i=1,data.stacks do
                    tower:AddNewModifier(data.caster, data.ability, "modifier_vengeance_multiple", {duration = data.duration})
                end
            else
                print("Error, couldn't apply ", modifierName)
            end
        end
    end
end

function FindSellAbility( tower )
    for i=0,15 do
        local ability = tower:GetAbilityByIndex(i)
        if ability and string.match(ability:GetAbilityName(), "sell_tower") then
            return ability
        end
    end
end