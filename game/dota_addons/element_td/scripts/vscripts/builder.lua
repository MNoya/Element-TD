------------------------------------------
--             Build Scripts
------------------------------------------

-- A build ability is used (not yet confirmed)
function Build( event )
    local caster = event.caster
    local ability = event.ability
    local ability_name = ability:GetAbilityName()
    local AbilityKV = BuildingHelper.AbilityKV
    local UnitKV = BuildingHelper.UnitKV

    if caster:IsIdle() then
        caster:Interrupt()
    end

    -- Handle the name for item-ability build
    local building_name
    if ability:IsItem() then
        building_name = GetItemKeyValue(ability_name, "UnitName")
    else
        building_name = GetAbilityKeyValue(ability_name, "UnitName")
    end

    local construction_size = BuildingHelper:GetConstructionSize(building_name)
    local construction_radius = construction_size * 64 - 32

    -- Checks if there is enough custom resources to start the building, else stop.
    local unit_table = UnitKV[building_name]
    local gold_cost = ability:GetGoldCost(1)

    local hero = caster:GetPlayerOwner():GetAssignedHero()
    local playerID = hero:GetPlayerID()
    local player = PlayerResource:GetPlayer(playerID)    
    local teamNumber = hero:GetTeamNumber()

    -- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
    -- Always refund the gold here, as the building hasn't been placed yet
    hero:ModifyGold(gold_cost, true, 0)

    -- Makes a building dummy and starts panorama ghosting
    BuildingHelper:AddBuilding(event)

    -- Additional checks to confirm a valid building position can be performed here
    event:OnPreConstruction(function(vPos)

        -- TD height
        if vPos.z < 380 then
            SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
            return false
        end

		-- If not enough resources to queue, stop
		if PlayerResource:GetGold(playerID) < gold_cost then
            return false
        end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
        
        -- Spend resources
        hero:ModifyGold(-gold_cost, true, 0)

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
            hero:ModifyGold(gold_cost, true, 0)
        end
    end)

    -- A building unit was created
    event:OnConstructionStarted(function(unit)
        BuildingHelper:print("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        -- Play construction sound

        -- If it's an item-ability and has charges, remove a charge or remove the item if no charges left
        if ability.GetCurrentCharges and not ability:IsPermanent() then
            local charges = ability:GetCurrentCharges()
            charges = charges-1
            if charges == 0 then
                ability:RemoveSelf()
            else
                ability:SetCurrentCharges(charges)
            end
        end

        -- Units can't attack while building
        unit:AddNewModifier(unit, nil, "modifier_attack_disabled", {})

        -- Remove invulnerability on npc_dota_building baseclass
        unit:RemoveModifierByName("modifier_invulnerable")

        -- Cast angles and various building-creature properties
        if GetUnitKeyValue(building_name, "DisableTurning") then
            unit:AddNewModifier(unit, nil, "modifier_disable_turning", {})
        end
    end)

    -- A building finished construction
    event:OnConstructionCompleted(function(unit)
        BuildingHelper:print("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        
        -- Play construction complete sound
        -- Give the unit their original attack capability
        unit:RemoveModifierByName("modifier_attack_disabled")
        
        -- Building abilities
        unit:AddNewModifier(unit, nil, "modifier_no_health_bar", {})
        
        local playerData = GetPlayerData(playerID)
        local gold = hero:GetGold()
        local tower = unit
        tower.class = building_name
        tower.element = GetUnitKeyValue(building_name, "Element")
        tower.damageType = GetUnitKeyValue(building_name, "DamageType")

        UpdateUpgrades(tower)
        UpdatePlayerSpells(playerID)

        -- create a script object for this tower
        local scriptClassName = GetUnitKeyValue(building_name, "ScriptClass")
        if not scriptClassName then scriptClassName = "BasicTower" end
        if TOWER_CLASSES[scriptClassName] then
            local scriptObject = TOWER_CLASSES[scriptClassName](tower, building_name)
            tower.scriptClass = scriptClassName
            tower.scriptObject = scriptObject
            tower.scriptObject:OnCreated()
        else
            Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. building_name)
        end

        -- mark this tower as a support tower if necessary
        if IsSupportTower(tower) then
            tower:AddNewModifier(tower, nil, "modifier_support_tower", {})
        end

        -- sell ability
        if IsPlayerUsingRandomMode( playerID ) then
            AddAbility(tower, "sell_tower_100")
        elseif string.match(building_name, "arrow_tower") or string.match(building_name, "cannon_tower") then
            AddAbility(tower, "sell_tower_95")
        else
            AddAbility(tower, "sell_tower_75")
        end

        AddAbility(tower, tower.damageType .. "_passive")
        if GetUnitKeyValue(building_name, "AOE_Full") and GetUnitKeyValue(building_name, "AOE_Half") then
            AddAbility(tower, "splash_damage_orb")
        end

        -- Add the tower to the player data
        local playerData = GetPlayerData(playerID)
        playerData.towers[unit:GetEntityIndex()] = building_name
        UpdateScoreboard(playerID)
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

-- Called when the move_to_point ability starts
function StartBuilding( keys )
    BuildingHelper:StartBuilding(keys)
end

-- Called when the Cancel ability-item is used
function CancelBuilding( keys )
    BuildingHelper:CancelBuilding(keys)
end