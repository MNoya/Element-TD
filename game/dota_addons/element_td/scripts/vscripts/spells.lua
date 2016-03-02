-- spells.lua
-- handles player spell upgrading

function UpdateBuildAbility(playerID, ability)
	local abilityName = ability:GetAbilityName()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local element = string.match(abilityName, "build_(%l+)_tower")
	if element then
		local level = GetPlayerElementLevel(playerID, element)
		if ability:GetLevel() ~= level then
			-- Downgrade 1 -> 0
			if level == 0 then
				local disabledAbilityName = abilityName.."_disabled"
				local newAbility = AddAbility(hero, disabledAbilityName, 0)
				hero:SwapAbilities(disabledAbilityName, abilityName, true, false)
				hero:RemoveAbility(abilityName)
			else
				ability:SetLevel(level)
			end
		end
	end
end

function UpdatePlayerSpells(playerID)
	local playerData = GetPlayerData(playerID)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero then
		for i=0,15 do
			local ability = hero:GetAbilityByIndex(i)
			if ability then
				local abilityName = ability:GetAbilityName()
				if string.match(abilityName, "_disabled") then
					local enabledAbilityName = string.gsub(abilityName, "_disabled", "")
					if MeetsAbilityElementRequirements(enabledAbilityName, playerID) then
						local newAbility = AddAbility(hero, enabledAbilityName, 1)
						hero:SwapAbilities(enabledAbilityName, abilityName, true, false)
						hero:RemoveAbility(abilityName)

						UpdateBuildAbility(playerID, newAbility)
						
						if IsCurrentlySelected(hero)  then
							NewSelection(hero)
						end
					end
				else
					UpdateBuildAbility(playerID, ability)
				end
			end
		end

		for i=0,5 do
			local item = hero:GetItemInSlot(i)
			if item then
				local itemName = item:GetAbilityName()
				if itemName == "item_build_periodic_tower_disabled" and MeetsItemElementRequirements(item, playerID) then
					item:RemoveSelf()
					hero:AddItem(CreateItem("item_build_periodic_tower", hero, hero))
				end
			end
		end

		-- In Random mode, essence purchasing is disabled
		if IsPlayerUsingRandomMode( playerID ) then
			local buy_essence = GetItemByName(playerData.summoner, "item_buy_pure_essence")
			if buy_essence then
				buy_essence:RemoveSelf()
			end

			-- Remove random-cast item
			local item_random = GetItemByName(playerData.summoner, "item_random")
			if item_random then
				item_random:RemoveSelf()
			end
			return
		end

		if not CanPlayerEnableRandom(playerID) then
			-- Remove random-cast item
			local item_random = GetItemByName(playerData.summoner, "item_random")
			if item_random then
				item_random:RemoveSelf()
			end
		end
	end
end

--called when a Sell Tower ability is cast
function SellTowerCast(keys)
	local tower = keys.caster

	if tower:GetHealth() == tower:GetMaxHealth() then -- only allow selling if the tower is fully built
		local hero = tower:GetOwner()
		local playerID = hero:GetPlayerID()
		local playerData = GetPlayerData(playerID)
		local goldCost = GetUnitKeyValue(tower.class, "TotalCost")
		local sellPercentage = tonumber(keys.SellAmount)

		local refundAmount = round(goldCost * sellPercentage)
		if sellPercentage > 0  then
			Sounds:EmitSoundOnClient(playerID, "Gold.CoinsBig")	
			PopupAlchemistGold(tower, refundAmount)

		    local coins = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, tower)
		    ParticleManager:SetParticleControl(coins, 1, tower:GetAbsOrigin())

			-- Add gold
			hero:ModifyGold(refundAmount)

			-- If a tower costs a Pure Essence (Pure, Periodic), then that essence is refunded upon selling the tower.
			local essenceCost = GetUnitKeyValue(tower.class, "EssenceCost") or 0
			if essenceCost > 0 then
				ModifyPureEssence(playerID, essenceCost, true)
				PopupEssence(tower, essenceCost)
			end

			-- Add lost gold and towers sold
			local goldLost = goldCost - refundAmount
			playerData.goldLost = playerData.goldLost + goldLost
			playerData.towersSold = playerData.towersSold + 1
		end

		if tower.isClone then
			RemoveClone(tower)
		else
			-- we must delete a random clone of this type
			if playerData.clones[tower.class] and tower:HasModifier("modifier_conjure_prevent_cloning") then
				RemoveRandomClone(playerData, tower.class)
			end
		end

		if tower.damageType and tower.damageType ~= "composite" then
			PlayElementalExplosion(tower.damageType, tower)
		end

		-- Remove random Blacksmith/Well buff when sold
		if tower.class == "blacksmith_tower" or tower.class == "well_tower" then
			RemoveRandomBuff(tower)
		end

		--[[for towerID,_ in pairs(playerData.towers) do
			UpdateUpgrades(EntIndexToHScript(towerID))
		end]]

		tower.sold = true
		if tower.scriptObject["OnDestroyed"] then
			tower.scriptObject:OnDestroyed()
		end

		-- Kills and hide the tower, so that its running timers can still execute until it gets removed by the engine
		tower:AddEffects(EF_NODRAW)
		DrawTowerGrid(tower)
		tower:ForceKill(true)
		playerData.towers[tower:entindex()] = nil -- remove this tower index from the player's tower list

		UpdateScoreboard(hero:GetPlayerID())
		Log:debug(playerData.name .. " has sold a tower")
		UpdatePlayerSpells(hero:GetPlayerID())
	end
end

function MeetsAbilityElementRequirements(name, playerID)
	local req = GetAbilityKeyValue(name, "Requirements")

	if req then
		local playerData = GetPlayerData(playerID)
		for e, l in pairs(req) do
			if tonumber(l) > playerData.elements[e] then
				return false
			end
		end
	end
	return true
end

function MeetsItemElementRequirements(upgrade_item, playerID)
	local name = upgrade_item:GetAbilityName()
	local req = GetItemKeyValue(name, "Requirements")

	if req then
		local playerData = GetPlayerData(playerID)
		for e, l in pairs(req) do
			if tonumber(l) > playerData.elements[e] then
				return false
			end
		end
	end
	return true
end

function UpgradeTower(keys)
	local tower = keys.caster
	local hero = tower:GetOwner()
	local newClass = keys.tower -- the class of the tower to upgrade to
	local cost = GetUnitKeyValue(newClass, "Cost") -- Old GetCostForTower(newClass)
	local playerID = hero:GetPlayerID()
	local playerData = GetPlayerData(playerID)
	local essenceCost = GetUnitKeyValue(newClass, "EssenceCost") or 0
	local playerEssence = GetPlayerData(playerID).pureEssence
	
	if not MeetsItemElementRequirements(keys.ability, playerID) and not playerData.freeTowers then
		ShowWarnMessage(playerID, "Incomplete Element Requirements!")
	elseif essenceCost > playerEssence and not playerData.freeTowers then
		ShowWarnMessage(playerID, "You need 1 Essence! Buy it at the Elemental Summoner")
	elseif cost > hero:GetGold() and not playerData.freeTowers then
		ShowWarnMessage(playerID, "Not Enough Gold!")
	elseif tower:GetHealth() == tower:GetMaxHealth() then
		if not playerData.freeTowers then
			hero:ModifyGold(-cost)
			ModifyPureEssence(playerID, -essenceCost)
		end
		
		GetPlayerData(playerID).towers[tower:entindex()] = nil --and remove it from the player's tower list

		local scriptClassName = GetUnitKeyValue(newClass, "ScriptClass") or "BasicTower"
		local stacks = tower:GetModifierStackCount("modifier_kill_count", tower)

		-- Replace the tower by a new one
		local newTower = BuildingHelper:UpgradeBuilding(tower, newClass)

		-- Kill count is transfered if the tower is upgraded to one of the same type (single/dual/triple)
		InitializeKillCount(newTower)
		if scriptClassName == tower.scriptClass then
			TransferKillCount(stacks, newTower)
		end

		-- set some basic values to this tower from its KeyValues
		newTower.class = newClass
		newTower.element = GetUnitKeyValue(newClass, "Element")
		newTower.damageType = GetUnitKeyValue(newClass, "DamageType")

		-- New pedestal if one wasn't created already
		if not newTower.prop then
			local basicName = newTower.damageType.."_tower"
			local pedestalName = GetUnitKeyValue(basicName, "PedestalModel")
			local prop = BuildingHelper:CreatePedestalForBuilding(newTower, basicName, GetGroundPosition(newTower:GetAbsOrigin(), nil), pedestalName)
		end

		GetPlayerData(playerID).towers[newTower:entindex()] = newClass --add this tower to the player's tower list
		UpdateUpgrades(newTower) --update this tower's upgrades
		UpdatePlayerSpells(playerID) --update the player's spells

		local upgradeData = {}
		if tower.scriptObject and tower.scriptObject["GetUpgradeData"] then
			upgradeData = tower.scriptObject:GetUpgradeData()
		end

		-- Add upgrade cancelling ability
		newTower.upgradedFrom = tower:GetUnitName()
		newTower.upgradedFromClass = tower.class
		AddAbility(newTower, "cancel_construction")

		-- Add sell ability
		if IsPlayerUsingRandomMode(playerID) then
			AddAbility(newTower, "sell_tower_100")
		elseif string.find(newTower.class, "arrow_tower") ~= nil or string.find(newTower.class, "cannon_tower") ~= nil then
			AddAbility(newTower, "sell_tower_98")
		else
			AddAbility(newTower, "sell_tower_90")
		end

		-- create a script object for this tower
        if TOWER_CLASSES[scriptClassName] then
	        local scriptObject = TOWER_CLASSES[scriptClassName](newTower, newClass)
	        newTower.scriptClass = scriptClassName
	        newTower.scriptObject = scriptObject
	        newTower.scriptObject:OnCreated()
	        if newTower.scriptObject["ApplyUpgradeData"] then
	        	newTower.scriptObject:ApplyUpgradeData(upgradeData)
	        end
        else
	    	Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. newTower.class)
    	end

    	if IsSupportTower(newTower) then
        	newTower:AddNewModifier(newTower, nil, "modifier_support_tower", {})
        end

		AddAbility(newTower, newTower.damageType .. "_passive")
		if GetUnitKeyValue(newClass, "AOE_Full") and GetUnitKeyValue(newClass, "AOE_Half") then
			AddAbility(newTower, "splash_damage_orb")
		end

		if tower.scriptObject["OnDestroyed"] then
			tower.scriptObject:OnDestroyed()
		end

		-- When you sell/upgrade a tower that has been cloned in the last 60 seconds, you lose a random clone of that tower type (this is to prevent abuse with 100% sell).
		-- we must delete a random clone of this type
		if playerData.clones[tower.class] and tower:HasModifier("modifier_conjure_prevent_cloning") then
			RemoveRandomClone(playerData, tower.class)
		end

		tower.deleted = true --mark the old tower for deletion

		-- Start the tower building animation
		if tower.scriptClass == scriptClassName then
			BuildTower(newTower, tower:GetModelScale())
		else
			BuildTower(newTower)
		end

		if GetUnitKeyValue(newClass, "DisableTurning") then
        	newTower:AddNewModifier(newTower, nil, "modifier_disable_turning", {})
        end

        AddAbility(newTower, "ability_building")

        -- keep well & blacksmith buffs
	    local fire_up = tower:FindModifierByName("modifier_fire_up")
	    if fire_up then
	        newTower:AddNewModifier(fire_up:GetCaster(), fire_up:GetAbility(), "modifier_fire_up", {duration = fire_up:GetDuration()})
	    end

	    local spring_forward = tower:FindModifierByName("modifier_spring_forward")
	    if spring_forward then
	        newTower:AddNewModifier(spring_forward:GetCaster(), spring_forward:GetAbility(), "modifier_spring_forward", {duration = spring_forward:GetDuration()})
	    end

		Timers:CreateTimer(function()
			RemoveUnitFromSelection( tower )
			AddUnitToSelection(newTower)
			Timers:CreateTimer(0.03, function()
				UpdateSelectedEntities()
			end)
		end)
	end
end

function RemoveRandomClone( playerData, name )
	local clones = {}
	local i = 0
	for entindex,_ in pairs(playerData.clones[name]) do
		local clone = EntIndexToHScript(entindex)
		if IsValidEntity(clone) and clone:GetClassname() == "npc_dota_creature" and clone:IsAlive() then
			i = i + 1
			clones[i] = clone
		else
			playerData.clones[name][entindex] = nil
		end
	end

	if #clones > 0 then
		local ranIndex = RandomInt(1,i)
		local clone = clones[ranIndex]
		RemoveClone(clone)
	end
end

function UpdateUpgrades(tower)
	local class = tower.class
	local playerID = tower:GetPlayerOwnerID()
	local data = GetPlayerData(playerID)
	local upgrades = NPC_UNITS_CUSTOM[class].Upgrades

	-- delete all items first
	for i = 0, 5, 1 do
		local item = tower:GetItemInSlot(i)
		if item then
			UTIL_Remove(item)
		end
	end

	-- now add them again
	if upgrades.Count then
		local count = tonumber(upgrades.Count)
		for i = 1, count, 1 do
			local upgrade = upgrades[tostring(i)]
			local cost = tonumber(NPC_UNITS_CUSTOM[upgrade].Cost)
			local suffix = ""

			--[[if cost > PlayerResource:GetGold(playerID) then
				suffix = "_disabled"
			end]]
			-- Put a _disabled item if the requirement isn't met yet
			if NPC_UNITS_CUSTOM[upgrade].Requirements then
				for element, level in pairs(NPC_UNITS_CUSTOM[upgrade].Requirements) do
					if level > data.elements[element] then
						suffix = "_disabled"
					end
				end
			end

			local item = CreateItem("item_upgrade_to_" .. upgrade .. suffix, nil, nil)
			tower:AddItem(item)
		end
	end
end

-- starts the tower building animation
function BuildTower(tower, baseScale)
	tower:RemoveModifierByName("modifier_invulnerable")
	tower:RemoveModifierByName("modifier_tower_truesight_aura")
	tower:AddNewModifier(nil, nil, "modifier_disarmed", {}) --towers are disarmed until they finish building
	tower:AddNewModifier(nil, nil, "modifier_stunned", {}) --towers are stunned until they finish building

	local buildTime = GetUnitKeyValue(tower.class, "BuildTime")
	if not buildTime then
		print(tower.class .. " does not have a build time!")
		buildTime = 1
	else
		buildTime = tonumber(buildTime)
	end

	local scale = tower:GetModelScale()
	baseScale = baseScale or (scale / 2) -- Start at the old size (if its the same model) or at half the end size
	local scaleIncrement = (scale - baseScale) / (buildTime * 20)

	tower:SetModelScale(baseScale)
	tower:SetMaxHealth(buildTime * 20)
	tower:SetBaseMaxHealth(buildTime * 20)
	tower:SetHealth(1)

	-- create a timer to build up the tower slowly
	Timers:CreateTimer(0.05, function()
		if not IsValidEntity(tower) or not tower:IsAlive() then return end
		tower:SetHealth(tower:GetHealth() + 1)
        tower:SetModelScale(tower:GetModelScale() + scaleIncrement)

		if tower:GetHealth() == tower:GetMaxHealth() then
			tower:RemoveModifierByName("modifier_disarmed")
        	tower:RemoveModifierByName("modifier_stunned")
        	tower:AddNewModifier(nil, nil, "modifier_invulnerable", {})

			tower:SetMaxHealth(GetUnitKeyValue(tower.class, "TotalCost"))
			tower:SetBaseMaxHealth(GetUnitKeyValue(tower.class, "TotalCost"))

        	tower:SetHealth(tower:GetMaxHealth())

        	-- Remove building cancel ability
        	tower:RemoveAbility("cancel_construction")

        	tower.scriptObject:OnBuildingFinished()
        	return
        end
        return 0.05
	end)
end

function ToggleGrid( event )
	local item = event.ability
	local playerID = event.caster:GetPlayerOwnerID()
	local playerData = GetPlayerData(playerID)
	local sector = playerData.sector + 1
	item.enabled = not item.enabled

	if item.enabled then
		if item.particles then
			for k,v in pairs(item.particles) do
				ParticleManager:DestroyParticle(v, true)
			end
		end

		item.particles = {}
		for y,v in pairs(BuildingHelper.Grid) do
	        for x,_ in pairs(v) do
				local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), nil)
	            if pos.z > 380 and pos.z < 400 and IsInsideSector(pos, sector) then
	            	if BuildingHelper:CellHasGridType(x,y,'BUILDABLE') then
	            		local particle = DrawGrid(x,y,Vector(255,255,255), playerID)
	                	table.insert(item.particles, particle)
	                end
	            end
	        end
	   	end
	else
		for k,v in pairs(item.particles) do
			ParticleManager:DestroyParticle(v, true)
		end
	end
end

function DrawGrid(x, y, color, playerID)
	local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
    BuildingHelper:SnapToGrid(1, pos)
    pos = GetGroundPosition(pos, nil)
        
    local particle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/square_overlay.vpcf", PATTACH_CUSTOMORIGIN, nil, PlayerResource:GetPlayer(playerID))
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(32,0,0))
    ParticleManager:SetParticleControl(particle, 2, color)
    ParticleManager:SetParticleControl(particle, 3, Vector(90,0,0))

	return particle
end

function DrawTowerGrid(tower)
	local playerID = tower:GetPlayerOwnerID()
	local playerData = GetPlayerData(playerID)
	if not playerData.toggle_grid_item or not playerData.toggle_grid_item.enabled then
		return
	end

	local location = tower:GetAbsOrigin()
	local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local boundX1 = originX + 1
    local boundX2 = originX - 1
    local boundY1 = originY + 1
    local boundY2 = originY - 1

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    upperBoundX = upperBoundX-1
    upperBoundY = upperBoundY-1

    for y = lowerBoundY, upperBoundY do
        for x = lowerBoundX, upperBoundX do
			local particle = DrawGrid(x, y, Vector(255,255,255), playerID)
			table.insert(playerData.toggle_grid_item.particles, particle)
        end
    end
end

function CancelConstruction(event)
	local ability = event.ability
	local tower = event.caster
	local hero = tower:GetOwner()
	local playerID = hero:GetPlayerID()
	local playerData = GetPlayerData(playerID)
	local goldCost = GetUnitKeyValue(tower:GetUnitName(), "Cost")
	local essenceCost = GetUnitKeyValue(tower.class, "EssenceCost") or 0

	if tower.upgradedFrom then
		local newClass = tower.upgradedFrom
		local scriptClassName = GetUnitKeyValue(newClass, "ScriptClass") or "BasicTower"
		local stacks = tower:GetModifierStackCount("modifier_kill_count", tower)

		-- Replace the tower by a new one
		local newTower = BuildingHelper:UpgradeBuilding(tower, newClass)

		-- Kill count is transfered if the tower is upgraded to one of the same type (single/dual/triple)
		InitializeKillCount(newTower)
		if scriptClassName == tower.scriptClass then
			TransferKillCount(stacks, newTower)
		end

		-- set some basic values to this tower from its KeyValues
		newTower.class = newClass
		newTower.element = GetUnitKeyValue(newClass, "Element")
		newTower.damageType = GetUnitKeyValue(newClass, "DamageType")

		-- New pedestal if one wasn't created already
		if not newTower.prop then
			local basicName = newTower.damageType.."_tower"
			local pedestalName = GetUnitKeyValue(basicName, "PedestalModel")
			local prop = BuildingHelper:CreatePedestalForBuilding(newTower, basicName, GetGroundPosition(newTower:GetAbsOrigin(), nil), pedestalName)
		end

		playerData.towers[newTower:entindex()] = newClass --add this tower to the player's tower list
		UpdateUpgrades(newTower) --update this tower's upgrades
		UpdatePlayerSpells(playerID) --update the player's spells

		local upgradeData = {}
		if tower.scriptObject and tower.scriptObject["GetUpgradeData"] then
			upgradeData = tower.scriptObject:GetUpgradeData()
		end

		-- Add sell ability
		if IsPlayerUsingRandomMode(playerID) then
			AddAbility(newTower, "sell_tower_100")
		elseif string.find(newTower.class, "arrow_tower") ~= nil or string.find(newTower.class, "cannon_tower") ~= nil then
			AddAbility(newTower, "sell_tower_98")
		else
			AddAbility(newTower, "sell_tower_90")
		end

		-- create a script object for this tower
        if TOWER_CLASSES[scriptClassName] then
	        local scriptObject = TOWER_CLASSES[scriptClassName](newTower, newClass)
	        newTower.scriptClass = scriptClassName
	        newTower.scriptObject = scriptObject
	        newTower.scriptObject:OnCreated()
	        if newTower.scriptObject["ApplyUpgradeData"] then
	        	newTower.scriptObject:ApplyUpgradeData(upgradeData)
	        end
        else
	    	Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. newTower.class)
    	end

    	if IsSupportTower(newTower) then
        	newTower:AddNewModifier(newTower, nil, "modifier_support_tower", {})
        end

		AddAbility(newTower, newTower.damageType .. "_passive")
		if GetUnitKeyValue(newClass, "AOE_Full") and GetUnitKeyValue(newClass, "AOE_Half") then
			AddAbility(newTower, "splash_damage_orb")
		end

		tower.deleted = true --mark the old tower for deletion

		if GetUnitKeyValue(newClass, "DisableTurning") then
        	newTower:AddNewModifier(newTower, nil, "modifier_disable_turning", {})
        end

        AddAbility(newTower, "ability_building")
        newTower:AddNewModifier(newTower, nil, "modifier_no_health_bar", {})

        -- keep well & blacksmith buffs
	    local fire_up = tower:FindModifierByName("modifier_fire_up")
	    if fire_up then
	        newTower:AddNewModifier(fire_up:GetCaster(), fire_up:GetAbility(), "modifier_fire_up", {duration = fire_up:GetDuration()})
	    end

	    local spring_forward = tower:FindModifierByName("modifier_spring_forward")
	    if spring_forward then
	        newTower:AddNewModifier(spring_forward:GetCaster(), spring_forward:GetAbility(), "modifier_spring_forward", {duration = spring_forward:GetDuration()})
	    end

		Timers:CreateTimer(function()
			RemoveUnitFromSelection( tower )
			AddUnitToSelection(newTower)
			Timers:CreateTimer(0.03, function()
				UpdateSelectedEntities()
			end)
		end)
	else
		Sounds:EmitSoundOnClient(playerID, "Gold.CoinsBig")	
		PopupAlchemistGold(tower, goldCost)
		local coins = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, tower)
		ParticleManager:SetParticleControl(coins, 1, tower:GetAbsOrigin())

		if essenceCost > 0 then
			PopupEssence(tower, essenceCost)
		end

		if tower.damageType and tower.damageType ~= "composite" then
			PlayElementalExplosion(tower.damageType, tower)
		end

		tower:AddEffects(EF_NODRAW)
		DrawTowerGrid(tower)
		tower:ForceKill(true)
	end

	-- Gold
	hero:ModifyGold(goldCost)

	-- Essence
	if essenceCost > 0 then
		ModifyPureEssence(playerID, essenceCost, true)
	end

	-- Removal
	playerData.towers[tower:entindex()] = nil -- remove this tower index from the player's tower list
end