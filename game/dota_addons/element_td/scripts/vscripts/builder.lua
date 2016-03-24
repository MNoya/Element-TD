-- A build ability is used (not yet confirmed)
function Build( event )
    local caster = event.caster
    local ability = event.ability
    local ability_name = ability:GetAbilityName()
    local building_name = ability:GetAbilityKeyValues()['UnitName']
    local gold_cost = ability:GetGoldCost(1)
    local hero = caster:IsRealHero() and caster or caster:GetOwner()
    local playerID = hero:GetPlayerID()
    local playerData = GetPlayerData(playerID)

    if caster:IsIdle() then
        caster:Stop()
    end

    -- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
    -- Always refund the gold here, as the building hasn't been placed yet
    PlayerResource:ModifyGold(playerID, gold_cost, true, 0)

    -- Check essence cost for periodic tower
    local essenceCost = GetUnitKeyValue(building_name, "EssenceCost") or 0
    if essenceCost > playerData.pureEssence and not playerData.freeTowers then
        ShowWarnMessage(playerID, "You need 1 Essence! Buy it at the Elemental Summoner")
        return
    end

    -- Makes a building dummy and starts panorama ghosting
    BuildingHelper:AddBuilding(event)

    -- Additional checks to confirm a valid building position can be performed here
    event:OnPreConstruction(function(vPos)

        -- Check for minimum height if defined
        if not BuildingHelper:MeetsHeightCondition(vPos) then
            SendErrorMessage(playerID, "#error_invalid_build_position")
            return false
        end

		-- If not enough resources to queue, stop
		if PlayerResource:GetGold(playerID) < gold_cost then
            SendErrorMessage(playerID, "#error_not_enough_gold")
            return false
        end

        if essenceCost > playerData.pureEssence and not playerData.freeTowers then
            ShowWarnMessage(playerID, "You need 1 Essence! Buy it at the Elemental Summoner")
            return false
        end

        local sector = playerData.sector + 1
        if not IsInsideSector(vPos, sector) then
            ShowWarnMessage(playerID, "#error_invalid_build_position")
            return false
        end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
        -- Spend resources
        if not playerData.freeTowers then
            hero:ModifyGold(-gold_cost)
            ModifyPureEssence(playerID, -essenceCost)
        end

        -- Play a sound
        Sounds:EmitSoundOnClient(playerID, "DOTA_Item.ObserverWard.Activate")
    end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
    event:OnConstructionFailed(function()
        local playerTable = BuildingHelper:GetPlayerTable(playerID)
        local name = playerTable.activeBuilding
        BuildingHelper:print("Failed placement of " .. name)
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
    end)

    -- Cancelled due to ClearQueue
    event:OnConstructionCancelled(function(work)
        local name = work.name
        BuildingHelper:print("Cancelled construction of " .. name)

        -- Refund resources for this cancelled work
        if work.refund then
            hero:ModifyGold(gold_cost)
            ModifyPureEssence(playerID, essenceCost, true)
        end
    end)

    -- A building unit was created
    event:OnConstructionStarted(function(unit)
        BuildingHelper:print("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        -- Play construction animation
        Rewards:CustomAnimation(playerID, caster)

        -- Units can't attack while building
        unit:AddNewModifier(unit, nil, "modifier_attack_disabled", {})
        unit:AddNewModifier(nil, nil, "modifier_stunned", {})

        -- Add kill tracker
        InitializeKillCount(unit)

        -- Remove invulnerability on npc_dota_building baseclass
        unit:RemoveModifierByName("modifier_invulnerable")

        -- Add building-creature properties
        AddAbility(unit, "ability_building")

        -- Add cancel building ability
        AddAbility(unit, "cancel_construction")

        -- set some basic values to this tower from its KeyValues
        unit.class = building_name
        unit.element = GetUnitKeyValue(building_name, "Element")
        unit.damageType = GetUnitKeyValue(building_name, "DamageType")
        UpdateUpgrades(unit)

        -- create a script object for this tower
        local scriptClassName = GetUnitKeyValue(building_name, "ScriptClass")
        if not scriptClassName then scriptClassName = "BasicTower" end
        if TOWER_CLASSES[scriptClassName] then
            local scriptObject = TOWER_CLASSES[scriptClassName](unit, building_name)
            unit.scriptClass = scriptClassName
            unit.scriptObject = scriptObject
        else
            Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. building_name)
        end

        local steamID32 = PlayerResource:GetSteamAccountID(playerID)
        local steamID64 = Rewards:ConvertID64(steamID32)
        local rewards = Rewards.file[steamID64]
        if rewards then
            local models = rewards["change_models"]
            if models and models[unit:GetUnitName()] then
                local data = models[unit:GetUnitName()]
                if data.model then
                    unit:SetModel(data.model)
                    unit:SetOriginalModel(data.model)
                    unit.override_model = data.model
                    unit:StartGesture(ACT_DOTA_SPAWN)

                    if data.scale then
                        unit.overrideMaxScale = data.scale
                        unit:SetModelScale(data.scale)
                    end

                    if data.offset then
                        local origin = unit:GetAbsOrigin()
                        origin.z = origin.z + data.offset
                        unit:SetAbsOrigin(origin)
                    end
                end
            end
        end

        -- Adjust health to the buildings TotalCost
        unit:SetMaxHealth(GetUnitKeyValue(building_name, "TotalCost"))
        unit:SetBaseMaxHealth(GetUnitKeyValue(building_name, "TotalCost"))

        -- Add the tower to the player data
        playerData.towers[unit:GetEntityIndex()] = building_name

        -- Instant placement
        if playerData.noCD then
            unit.overrideBuildTime = 0
        end

        -- Normalize Hull Radius
        unit:SetHullRadius(HULL_RADIUS)
        ToggleGridForTower(unit, true)
    end)

    -- A building finished construction
    event:OnConstructionCompleted(function(unit)
        BuildingHelper:print("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        
        -- Play construction complete sound
        -- Give the unit their original attack capability
        unit:RemoveModifierByName("modifier_attack_disabled")
        unit:RemoveModifierByName("modifier_stunned")
        
        -- Building abilities
        unit:AddNewModifier(unit, nil, "modifier_no_health_bar", {})

        -- Remove cancel building
        unit:RemoveAbility("cancel_construction")

        -- mark this tower as a support tower if necessary
        if IsSupportTower(unit) then
             unit:AddNewModifier(unit, nil, "modifier_support_tower", {})
        end

        -- sell ability
        if IsPlayerUsingRandomMode( playerID ) then
            AddAbility(unit, "sell_tower_100")
        elseif string.match(building_name, "arrow_tower") or string.match(building_name, "cannon_tower") then
            AddAbility(unit, "sell_tower_98")
        else
            AddAbility(unit, "sell_tower_90")
        end

        if string.match(building_name, "cannon_tower") then
            AddAbility(unit, "attack_ground")
        end

        unit.scriptObject:OnCreated()
        AddAbility(unit, unit.damageType .. "_passive")
        if GetUnitKeyValue(building_name, "AOE_Full") and GetUnitKeyValue(building_name, "AOE_Half") then
            AddAbility(unit, "splash_damage_orb")
        end

        UpdateScoreboard(playerID)

        if unit.override_model then
            unit:SetModel(unit.override_model)
            unit:SetOriginalModel(unit.override_model)
            unit:StartGesture(ACT_DOTA_IDLE)
        end
    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't fire multiple times unnecessarily.
    event:OnBelowHalfHealth(function(unit)
        BuildingHelper:print("" .. unit:GetUnitName() .. " is below half health.")
    end)

    event:OnAboveHalfHealth(function(unit)
        BuildingHelper:print("" ..unit:GetUnitName().. " is above half health.")

        unit:RemoveModifierByName("modifier_onfire")
        
    end)
end

-- item_build_periodic_tower_disabled
function PeriodicWarn( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()

    ShowWarnMessage(playerID, "You need at least level 1 on every element to build a Periodic Tower!")
end