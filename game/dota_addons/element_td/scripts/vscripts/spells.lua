-- spells.lua
-- handles player spell upgrading

local towersKV = LoadKeyValues("scripts/kv/towers.kv")

function UpdatePlayerSpells(playerID)
	local playerData = GetPlayerData(playerID)
	local hero = ElementTD.vPlayerIDToHero[playerID]
	if hero then
		for i=0,15 do
			local ability = hero:GetAbilityByIndex(i)
			if ability then
				ability:SetActivated(MeetsAbilityElementRequirements(ability:GetAbilityName(), playerID))
			end
		end
	end
end

--called when a Sell Tower ability is cast
function SellTowerCast(keys)
	local tower = keys.caster

	BuildingHelper:RemoveBuilding(tower)

	if tower:GetHealth() == tower:GetMaxHealth() then -- only allow selling if the tower is fully built
		local hero = tower:GetOwner()
		local playerID = hero:GetPlayerID()
		local playerData = GetPlayerData(playerID)
		local sellPercentage = tonumber(keys.SellAmount)

		local refundAmount = round(GetUnitKeyValue(tower.class, "TotalCost") * sellPercentage)
		-- create a dummy unit to show the gold particles
		if sellPercentage > 0  then
			local dummy = CreateUnitByName("npc_dota_creep_badguys_ranged", tower:GetOrigin(), false, nil, nil, DOTA_TEAM_NOTEAM) 
			dummy:SetDeathXP(0)
			dummy:SetMaximumGoldBounty(refundAmount)
			dummy:SetMinimumGoldBounty(refundAmount)
			dummy:SetModel("") --make this creep invisible
			dummy:Kill(nil, hero)

			-- let's convert all this gold to reliable
			local gold = hero:GetGold()
			hero:SetGold(0, false)
			hero:SetGold(gold, true)
		end

		if tower.isClone then
			playerData.clones[tower.class][tower:entindex()] = nil
			CreateIllusionKilledParticles(tower)
		else
			-- we must delete a random clone of this type
			if playerData.clones[tower.class] and tower:HasModifier("modifier_conjure_prevent_cloning") then
				local entIDs, i = {}, 1
				for id,_ in pairs(playerData.clones[tower.class]) do
					entIDs[i] = id
					i = i + 1
				end
				if #entIDs > 0 then
					local ranIndex = math.random(#entIDs)
					local entindex = entIDs[ranIndex]
					local clone = EntIndexToHScript(entindex)
					if IsValidEntity(clone) then
						CreateIllusionKilledParticles(clone)
						playerData.towers[clone:entindex()] = nil -- remove this tower index from the player's tower list
						if clone.creatorClass then
							clone.creatorClass.clones[clone:entindex()] = nil
						end
						UTIL_Remove(clone) -- instantly remove the actual tower entity
					else
						Log:error("Invalid clone")
					end
				end
			end
		end

		for towerID,_ in pairs(playerData.towers) do
			UpdateUpgrades(EntIndexToHScript(towerID))
		end

		if tower.scriptObject["OnDestroyed"] then
			tower.scriptObject:OnDestroyed()
		end

		playerData.towers[tower:entindex()] = nil -- remove this tower index from the player's tower list
		UTIL_Remove(tower) -- instantly remove the actual tower entity
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
	local playerData = GetPlayerData(hero:GetPlayerID())
	
	if not MeetsItemElementRequirements(keys.ability, hero:GetPlayerID()) then
		ShowWarnMessage(hero:GetPlayerID(), "Incomplete Element Requirements!")
	elseif cost > hero:GetGold() then
		ShowWarnMessage(hero:GetPlayerID(), "Not Enough Gold!")
	elseif tower:GetHealth() == tower:GetMaxHealth() then
		hero:SpendGold(cost, DOTA_ModifyGold_PurchaseItem)
		GetPlayerData(hero:GetPlayerID()).towers[tower:entindex()] = nil --and remove it from the player's tower list

		local newTower = CreateUnitByName(newClass, tower:GetOrigin(), false, nil, nil, hero:GetTeam()) 

		-- set some basic values to this tower from its KeyValues
		newTower.class = newClass
		newTower.element = GetUnitKeyValue(newClass, "Element")
		newTower.damageType = GetUnitKeyValue(newClass, "DamageType")

		-- keep building visuals
		local angles = tower:GetAngles()
		newTower:SetAngles(angles.x, angles.y, angles.z)
		if tower.prop then
			newTower.prop = tower.prop
			local scale = GetUnitKeyValue(newClass, "PedestalModelScale") or newTower:GetModelScale()
			newTower.prop:SetModelScale(scale)
		end
		newTower.construction_size = tower.construction_size

		-- set this new tower's owner
		newTower:SetOwner(hero)
		newTower:SetControllableByPlayer(hero:GetPlayerID(), true)

		GetPlayerData(hero:GetPlayerID()).towers[newTower:entindex()] = newClass --add this tower to the player's tower list
		UpdateUpgrades(newTower) --update this tower's upgrades
		UpdatePlayerSpells(hero:GetPlayerID()) --update the player's spells

		local upgradeData = {}
		if tower.scriptObject and tower.scriptObject["GetUpgradeData"] then
			upgradeData = tower.scriptObject:GetUpgradeData()
		end

		-- create a script object for this tower
        local scriptClassName = GetUnitKeyValue(newClass, "ScriptClass")
        if not scriptClassName then scriptClassName = "BasicTower" end
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

    	ApplySupportModifier(newTower)
		

		if string.find(newTower.class, "arrow_tower") ~= nil or string.find(newTower.class, "cannon_tower") ~= nil or string.find(GameSettings.elementsOrderName, "Random") ~= nil then
			AddAbility(newTower, "sell_tower_100")
		else
			AddAbility(newTower, "sell_tower_75")
		end

		AddAbility(newTower, newTower.damageType .. "_passive")
		if GetUnitKeyValue(newClass, "AOE_Full") and GetUnitKeyValue(newClass, "AOE_Half") then
			AddAbility(newTower, "splash_damage_orb")
		end

		if tower.scriptObject["OnDestroyed"] then
			tower.scriptObject:OnDestroyed()
		end

		-- we must delete a random clone of this type
		if playerData.clones[tower.class] and tower:HasModifier("modifier_conjure_prevent_cloning") then
			local entIDs, i = {}, 1
			for id,_ in pairs(playerData.clones[tower.class]) do
				entIDs[i] = id
				i = i + 1
			end
			if #entIDs > 0 then
				local ranIndex = math.random(#entIDs)
				local entindex = entIDs[ranIndex]
				local clone = EntIndexToHScript(entindex)
				if IsValidEntity(clone) then
					CreateIllusionKilledParticles(clone)
					playerData.towers[clone:entindex()] = nil -- remove this tower index from the player's tower list
					AddTowerPosition(playerData.sector + 1, clone:GetOrigin()) -- re-add this position to the list of valid locations
					if clone.creatorClass then
						clone.creatorClass.clones[clone:entindex()] = nil
					end
					UTIL_Remove(clone) -- instantly remove the actual tower entity
				else
					Log:error("Invalid clone")
				end
			end
		end

		BuildTower(newTower, tower:GetModelScale()) --start the tower building animation
		UTIL_Remove(tower) --delete the old tower entity
	end
end

function PlaceTower(keys)
	local target = keys.target_points[1]
	local playerData = GetPlayerData(keys.caster:GetPlayerID())
	local sector = playerData.sector + 1 -- sector ID is always player ID + 1
	local pos = FindClosestTowerPosition(sector, target, 96)
	local hero = keys.caster
	local playerID = hero:GetPlayerID()

	if target.z == 384 and pos then -- this is the only height we allow towers to be built at
		local gold = hero:GetGold()

		if gold < GetUnitKeyValue(keys.tower, "Cost") then
			ShowWarnMessage(playerID, "Not Enough Gold!")
			return
		end

		hero:SpendGold(GetUnitKeyValue(keys.tower, "Cost"), DOTA_ModifyGold_PurchaseItem)
		RemoveTowerPosition(sector, pos)

		local tower = CreateUnitByName(keys.tower, pos, false, nil, nil, hero:GetTeam())
		tower.class = keys.tower
		tower.element = GetUnitKeyValue(tower.class, "Element")
		tower.damageType = GetUnitKeyValue(tower.class, "DamageType")

		tower:SetOwner(hero)
		tower:SetControllableByPlayer(hero:GetPlayerID(), true)
		UpdateUpgrades(tower)
		UpdatePlayerSpells(playerID)

		-- create a script object for this tower
        local scriptClassName = GetUnitKeyValue(keys.tower, "ScriptClass")
        if not scriptClassName then scriptClassName = "BasicTower" end
        if TOWER_CLASSES[scriptClassName] then
	        local scriptObject = TOWER_CLASSES[scriptClassName](tower, keys.tower)
	        tower.scriptClass = scriptClassName
	        tower.scriptObject = scriptObject
	        tower.scriptObject:OnCreated()
	    else
	    	Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. tower.class)
		end

		ApplySupportModifier(tower)

		if string.find(tower.class, "arrow_tower") ~= nil or string.find(tower.class, "cannon_tower") ~= nil or string.find(GameSettings.elementsOrderName, "Random") ~= nil then
			AddAbility(tower, "sell_tower_100")
		else
			AddAbility(tower, "sell_tower_75")
		end


		AddAbility(tower, tower.damageType .. "_passive")
		if GetUnitKeyValue(tower.class, "AOE_Full") and GetUnitKeyValue(tower.class, "AOE_Half") then
			AddAbility(tower, "splash_damage_orb")
		end

		GetPlayerData(hero:GetPlayerID()).towers[tower:entindex()] = keys.tower
		BuildTower(tower, 0.2)
	else
		ShowWarnMessage(playerID, "Invalid Tower Location!")
	end
end

function UpdateUpgrades(tower)
	local class = tower.class
	local playerID = tower:GetOwner():GetPlayerID()
	local data = GetPlayerData(playerID)
	local upgrades = towersKV[class].Upgrades
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
			local cost = tonumber(towersKV[upgrade].Cost)
			local suffix = ""

			--[[if cost > PlayerResource:GetGold(playerID) then
				suffix = "_disabled"
			end
			if towersKV[upgrade].Requirements then
				for element, level in pairs(towersKV[upgrade].Requirements) do
					if level > data.elements[element] then
						suffix = "_disabled"
					end
				end
			end]]--

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
	tower:AddNewModifier(nil, nil, "modifier_silence", {}) --towers are silenced until they finish building

	local buildTime = GetUnitKeyValue(tower.class, "BuildTime")
	if not buildTime then
		print(tower.class .. " does not have a build time!")
		buildTime = 1
	else
		buildTime = tonumber(buildTime)
	end

	local scale = tower:GetModelScale()
	local scaleIncrement = (scale - baseScale) / (buildTime * 20)

	tower:SetModelScale(baseScale)
	tower:SetHealth(1)
	tower:SetMaxHealth(buildTime * 20)
	tower:SetBaseMaxHealth(buildTime * 20)

	-- create a timer to build up the tower slowly
	Timers:CreateTimer("BuildTower"..tower:entindex(), {
		endTime = 0.05,
		callback = function()
			tower:SetHealth(tower:GetHealth() + 1)
	        tower:SetModelScale(tower:GetModelScale() + scaleIncrement)

			if tower:GetHealth() == tower:GetMaxHealth() then
	        	tower:RemoveModifierByName("modifier_disarmed")
	        	tower:RemoveModifierByName("modifier_silence")
	        	tower:AddNewModifier(nil, nil, "modifier_invulnerable", {})
	        	tower:NoHealthBar()

	        	if tower:GetBaseDamageMax() <= 0 then
	        		tower:SetMaxHealth(100)
	        		tower:SetBaseMaxHealth(100)
	        	else
					tower:SetMaxHealth(tower:GetBaseDamageMax())
					tower:SetBaseMaxHealth(tower:GetBaseDamageMax())
				end
	        	tower:SetHealth(tower:GetMaxHealth())
	        	return nil
	        end
	        return 0.05
		end
	})
end