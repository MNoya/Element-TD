--manages towers
if not TOWER_CLASSES then
	TOWER_CLASSES = {}
	TOWER_MODIFIERS = {}
    HULL_RADIUS = 50
end

function RegisterTowerClass(class, name)
	if not class and name then
		Log:warn("Attempted to create nil class: " .. name)
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
TOWER_TARGETING_OLDER = 8 --Filter creep spawn IDs
TOWER_TARGETING_NEWER = 16 --Filter creep spawn IDs, preferring the newest spawn

TOWER_TARGETING_ABILITY_NAME = "tower_targeting"
TOWER_TARGETING_MODES = {
    TOWER_TARGETING_CLOSEST,
    TOWER_TARGETING_FARTHEST,
    TOWER_TARGETING_LOWEST_HP,
    TOWER_TARGETING_HIGHEST_HP,
    TOWER_TARGETING_OLDER,
    TOWER_TARGETING_NEWER
}
TOWER_TARGETING_STATE_MODIFIERS = {
    [TOWER_TARGETING_CLOSEST] = "modifier_tower_targeting_closest",
    [TOWER_TARGETING_FARTHEST] = "modifier_tower_targeting_farthest",
    [TOWER_TARGETING_LOWEST_HP] = "modifier_tower_targeting_lowest_hp",
    [TOWER_TARGETING_HIGHEST_HP] = "modifier_tower_targeting_highest_hp",
    [TOWER_TARGETING_OLDER] = "modifier_tower_targeting_older",
    [TOWER_TARGETING_NEWER] = "modifier_tower_targeting_newer"
}

function ToIntFlag(value)
    return value and 1 or 0
end

function EnabledFlag(value)
    return value == true or tonumber(value) == 1
end

function GetTowerTargetingModifierName(target_type)
    return TOWER_TARGETING_STATE_MODIFIERS[tonumber(target_type)] or TOWER_TARGETING_STATE_MODIFIERS[TOWER_TARGETING_CLOSEST]
end

function MoveTowerBuildingAbilityToEnd(tower)
    if not tower or not IsValidEntity(tower) or not tower:HasAbility("ability_building") then
        return
    end

    tower:RemoveAbility("ability_building")
    AddAbility(tower, "ability_building")
end

function UpdateTowerTargetingStateModifier(tower, target_type)
    if not tower or not IsValidEntity(tower) then
        return
    end

    for _, mode in ipairs(TOWER_TARGETING_MODES) do
        local modifierName = GetTowerTargetingModifierName(mode)
        if tower:HasModifier(modifierName) then
            tower:RemoveModifierByName(modifierName)
        end
    end

    tower:AddNewModifier(tower, nil, GetTowerTargetingModifierName(target_type), {})
end

function IsWaveFilteredTargetType(target_type, filterType)
    local numericType = tonumber(target_type)
    if not numericType then
        return false
    end

    return numericType == filterType or TargetFlag(numericType, filterType)
end

function GetBaseTowerTargetType(target_type)
    local normalized = tonumber(target_type) or TOWER_TARGETING_CLOSEST

    if normalized == TOWER_TARGETING_OLDER or normalized == TOWER_TARGETING_NEWER then
        return TOWER_TARGETING_CLOSEST
    elseif TargetFlag(normalized, TOWER_TARGETING_FARTHEST) then
        return TOWER_TARGETING_FARTHEST
    elseif TargetFlag(normalized, TOWER_TARGETING_CLOSEST) then
        return TOWER_TARGETING_CLOSEST
    elseif normalized == TOWER_TARGETING_LOWEST_HP or TargetFlag(normalized, TOWER_TARGETING_LOWEST_HP) then
        return TOWER_TARGETING_LOWEST_HP
    end

    return TOWER_TARGETING_HIGHEST_HP
end

function FilterCreepsBySpawnID(creeps, preferNewest)
    local filtered = {}
    local targetSpawnID = nil

    for _, creep in pairs(creeps) do
        if not creep.recently_leaked then
            local spawnID = creep.spawn_id or creep:GetEntityIndex()
            if not targetSpawnID then
                targetSpawnID = spawnID
            elseif preferNewest and spawnID > targetSpawnID then
                targetSpawnID = spawnID
            elseif not preferNewest and spawnID < targetSpawnID then
                targetSpawnID = spawnID
            end
        end
    end

    if not targetSpawnID then
        return creeps
    end

    for _, creep in pairs(creeps) do
        if not creep.recently_leaked and (creep.spawn_id or creep:GetEntityIndex()) == targetSpawnID then
            table.insert(filtered, creep)
        end
    end

    if #filtered == 0 then
        return creeps
    end

    return filtered
end

function GetTowerTarget(tower, target_type, radius)
	if tower then
		local searchRadius = radius or tower:GetAttackRange()
        local baseTargetType = GetBaseTowerTargetType(target_type)
		local findType = baseTargetType == TOWER_TARGETING_FARTHEST and FIND_FARTHEST or FIND_CLOSEST
		local creeps = FindUnitsInRadius(tower:GetTeamNumber(), tower:GetAbsOrigin(), nil, searchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO, 0, findType, false)

        if IsWaveFilteredTargetType(target_type, TOWER_TARGETING_OLDER) then
            creeps = FilterCreepsBySpawnID(creeps, false)
        elseif IsWaveFilteredTargetType(target_type, TOWER_TARGETING_NEWER) then
            creeps = FilterCreepsBySpawnID(creeps, true)
        end

		if baseTargetType == TOWER_TARGETING_FARTHEST or baseTargetType == TOWER_TARGETING_CLOSEST then
			for _,v in pairs(creeps) do
				if v:GetTeam() == DOTA_TEAM_NEUTRALS then
					return v
				end
			end
		elseif baseTargetType == TOWER_TARGETING_LOWEST_HP then
            local unit = nil
            for _,v in pairs(creeps) do
                if v:GetTeam() == DOTA_TEAM_NEUTRALS then
                    if unit == nil or v:GetHealth() < unit:GetHealth() then
                        unit = v
                    end
                end
            end
            return unit
        else
			local unit = nil
            for _,v in pairs(creeps) do
                if v:GetTeam() == DOTA_TEAM_NEUTRALS then
                    if unit == nil or v:GetHealth() > unit:GetHealth() then
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
    local numericType = tonumber(type)
    if numericType == nil or flag == nil or flag == 0 then
        return false
    end
    return bit.band( numericType, flag ) == flag
end

function ApplyTowerTargeting(tower, params)
    if not tower or not IsValidEntity(tower) then
        return
    end

    local targetType = tonumber(params.target_type) or tower.target_type or tower.default_target_type or TOWER_TARGETING_CLOSEST
    local keepTarget = params.keep_target
    if keepTarget == nil then
        keepTarget = tower.keep_target or tower.default_keep_target
    end

    local changeOnLeak = params.change_on_leak
    if changeOnLeak == nil then
        changeOnLeak = tower.change_on_leak or tower.default_change_on_leak
    end

    tower.target_type = targetType
    tower.keep_target = EnabledFlag(keepTarget)
    tower.change_on_leak = EnabledFlag(changeOnLeak)
    UpdateTowerTargetingStateModifier(tower, targetType)
    CustomNetTables:SetTableValue("tower_targeting", tostring(tower:GetEntityIndex()), {text = GetTowerTargetingLabel(targetType)})

    if tower:HasModifier("modifier_attacking_ground") then
        return
    end

    if tower:HasModifier("modifier_attack_targeting") then
        tower:RemoveModifierByName("modifier_attack_targeting")
    end

    tower:AddNewModifier(tower, nil, "modifier_attack_targeting", {
        target_type = targetType,
        keep_target = ToIntFlag(tower.keep_target),
        change_on_leak = ToIntFlag(tower.change_on_leak)
    })
end

function ShouldAddTowerTargetingAbility(tower)
    if not tower or not IsValidEntity(tower) then
        return false
    end

    return true
end

function AddTowerTargetingAbility(tower)
    if not ShouldAddTowerTargetingAbility(tower) then
        return nil
    end

    if tower.default_target_type == nil then
        tower.default_target_type = tower.target_type or TOWER_TARGETING_CLOSEST
        tower.default_keep_target = tower.keep_target == true
        tower.default_change_on_leak = tower.change_on_leak == true
    end

    local ability = tower:FindAbilityByName(TOWER_TARGETING_ABILITY_NAME)
    if not ability then
        ability = AddAbility(tower, TOWER_TARGETING_ABILITY_NAME)
    end
    MoveTowerBuildingAbilityToEnd(tower)

    if not tower:HasModifier("modifier_attack_targeting") and not tower:HasModifier("modifier_attacking_ground") then
        ApplyTowerTargeting(tower, {
            target_type = tower.default_target_type,
            keep_target = tower.default_keep_target,
            change_on_leak = tower.default_change_on_leak
        })
    else
        local targetType = tower.target_type or tower.default_target_type or TOWER_TARGETING_CLOSEST
        UpdateTowerTargetingStateModifier(tower, targetType)
        CustomNetTables:SetTableValue("tower_targeting", tostring(tower:GetEntityIndex()), {text = GetTowerTargetingLabel(targetType)})
    end

    return ability
end

function GetNextTowerTargetingType(target_type)
    local current = tonumber(target_type) or TOWER_TARGETING_CLOSEST

    for index, mode in ipairs(TOWER_TARGETING_MODES) do
        if mode == current then
            local nextIndex = index + 1
            if nextIndex > #TOWER_TARGETING_MODES then
                nextIndex = 1
            end
            return TOWER_TARGETING_MODES[nextIndex]
        end
    end

    return TOWER_TARGETING_MODES[1]
end

function GetTowerTargetingLabel(target_type)
    local current = tonumber(target_type)

    if current == TOWER_TARGETING_FARTHEST then
        return "#etd_targeting_mode_farthest"
    elseif current == TOWER_TARGETING_LOWEST_HP then
        return "#etd_targeting_mode_lowest_hp"
    elseif current == TOWER_TARGETING_HIGHEST_HP then
        return "#etd_targeting_mode_highest_hp"
    elseif current == TOWER_TARGETING_OLDER then
        return "#etd_targeting_mode_older"
    elseif current == TOWER_TARGETING_NEWER then
        return "#etd_targeting_mode_newer"
    end

    return "#etd_targeting_mode_closest"
end

function CycleTowerTargeting(tower)
    if not tower or not IsValidEntity(tower) or not tower:IsAlive() then
        return
    end

    local currentTargetType = tower.target_type or tower.default_target_type or TOWER_TARGETING_CLOSEST
    local nextTargetType = GetNextTowerTargetingType(currentTargetType)
    ApplyTowerTargeting(tower, {target_type = nextTargetType})

    local playerID = tower:GetPlayerOwnerID()
    if playerID ~= nil and playerID ~= -1 then
        ShowTowerTargetingMessage(playerID, GetTowerTargetingLabel(nextTargetType))
    end
end

function CycleTowerTargetingAbility(keys)
    CycleTowerTargeting(keys.caster)
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
    for i=0,tower:GetAbilityCount()-1 do
        local ability = tower:GetAbilityByIndex(i)
        if ability and string.match(ability:GetAbilityName(), "sell_tower") then
            return ability
        end
    end
end

function EnsureAbilityHotkey(tower, abilityName)
    local ability = tower:FindAbilityByName(abilityName)
    if not ability then
        return false
    end

    -- Move all hidden abilities (except index 0) to the end
    -- We bubble hidden abilities toward the end by swapping with the next ability
    local totalAbilities = tower:GetAbilityCount()
    for i = 1, totalAbilities - 1 do
        local currentAbility = tower:GetAbilityByIndex(i)
        if currentAbility and not currentAbility:IsHidden() then
            -- Find the earliest hidden ability before this visible one and swap them
            for j = 1, i - 1 do
                local earlier = tower:GetAbilityByIndex(j)
                if earlier and earlier:IsHidden() then
                    tower:SwapAbilities(currentAbility:GetAbilityName(), earlier:GetAbilityName(), true, false)
                    break
                end
            end
        end
    end

    return ability:GetAbilityIndex() <= 5
end
