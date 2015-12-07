------------------------------------------
--             Build Scripts
------------------------------------------

-- A build ability is used (not yet confirmed)
function Build( event )
	local caster = event.caster
	local ability = event.ability
	local ability_name = ability:GetAbilityName()
	local AbilityKV = BuildingHelper.AbilityKVs
	local UnitKV = BuildingHelper.UnitKVs

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
	hero:ModifyGold(gold_cost, false, 0)

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
    	hero:ModifyGold(-gold_cost, false, 0)

    	-- Play a sound
    	EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", player)

    	-- Move allied units away from the building place
		local units = FindUnitsInRadius(teamNumber, vPos, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		
		for _,unit in pairs(units) do
			if unit ~= caster and unit:GetTeamNumber() == teamNumber and not IsCustomBuilding(unit) then
				BuildingHelper:print("Moving unit "..unit:GetUnitName().." outside of the building area")
				local front_position = unit:GetAbsOrigin() + unit:GetForwardVector() * hull
				ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = front_position, Queue = false})
				unit:AddNewModifier(caster, nil, "modifier_phased", {duration=1})
			end
		end

        -- Create pedestal
        local building_model = GetUnitKeyValue(building_name, "Model")
        if building_model == "models/tower_white_top.vmdl" then
            local prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/tower_white_pedestal.vmdl"})
            prop:SetModelScale(GetUnitKeyValue(building_name, "ModelScale"))
            prop:SetAbsOrigin(vPos)
        end

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
			hero:ModifyGold(-gold_cost, false, 0)
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
	    unit.original_attack = unit:GetAttackCapability()
		unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

    	-- Remove invulnerability on npc_dota_building baseclass
    	unit:RemoveModifierByName("modifier_invulnerable")

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

		ApplySupportModifier(tower)

		if string.match(building_name, "arrow_tower") or string.match(building_name, "cannon_tower") or (GameSettings.elementsOrderName and string.match(GameSettings.elementsOrderName, "Random")) then
			AddAbility(tower, "sell_tower_100")
		else
			AddAbility(tower, "sell_tower_75")
		end

		AddAbility(tower, tower.damageType .. "_passive")
		if GetUnitKeyValue(building_name, "AOE_Full") and GetUnitKeyValue(building_name, "AOE_Half") then
			AddAbility(tower, "splash_damage_orb")
		end

		-- Cast angles and various building-creature properties
    	--AddAbility(tower, "ability_building")

	end)

	-- A building finished construction
	event:OnConstructionCompleted(function(unit)
		BuildingHelper:print("Completed construction of " .. building_name .. " " .. unit:GetEntityIndex())
		
		-- Play construction complete sound

		-- Give the unit their original attack capability
		unit:SetAttackCapability(unit.original_attack)

		-- Let the building cast abilities
		unit:RemoveModifierByName("modifier_construction")

		-- Building ability
		unit:AddNewModifier(unit, nil, "modifier_no_health_bar", {})

	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't fire multiple times unnecessarily.
	event:OnBelowHalfHealth(function(unit)
		BuildingHelper:print("" .. unit:GetUnitName() .. " is below half health.")
				
		local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(unit, unit, "modifier_onfire", {})
    	item = nil

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