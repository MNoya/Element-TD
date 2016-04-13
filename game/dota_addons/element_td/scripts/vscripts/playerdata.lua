-- playerdata.lua
-- manages player data

if not PlayerData then
	PlayerData = {}
end

function CreateDataForPlayer(playerID, allowOverride)

    -- Don't create data twice unless allowed to override
    if not allowOverride then
        if PlayerData[playerID] or playerID == -1 then
            return 
        end
    end

	PlayerData[playerID] = {}
	local data = PlayerData[playerID]
	data["health"] = GameSettings:GetMapSetting("Lives")
	data["scoreObject"] = {}
	data["sector"] = -1
	data["lumber"] = 0
	data["pureEssenceTotal"] = 0 -- Keep track of the total amount given to the player
	data["pureEssence"] = 0
	data["elementalActive"] = false
	data["elementalUnit"] = nil
	data["elementalRandom"] = false
	data["elementalCount"] = 0
	data["LifeTowerKills"] = 0
	data["TotalLifeTowerKills"] = 0
	data["gold"] = 0
    data["gold_remainder"] = 0
	data["goldLost"] = 0
	data["towersSold"] = 0
	data["goldTowerEarned"] = 0
	data["leaks"] = 0
	data["elements"] = {
		water = 0, fire = 0, nature = 0,
		earth = 0, light = 0, dark = 0
	}
	data["elementOrder"] = {}
	data["towers"] = {}
	data["clones"] = {}
	data["difficulty"] = nil
	data["completedWaves"] = 0
	data["bossWaves"] = 0
	data["iceFrogKills"] = 0
	data["nextWave"] = 1
	data["activeWaves"] = 1
	data["waveObject"] = {} -- Current wave object
	data["waveObjects"] = {} -- All active wave objects
	data["remaining"] = 0 -- Creeps remaining to kill

	data["duration"] = 0 -- Seconds the player stayed alive for
	data["victory"] = 0  -- 0 if lost, 1 if won

	data["interestGold"] = 0
	data["interestData"] = {
		Locked = false,
		LockingWaves = {},
		NumLockingWaves = 0,
		TimeRemaining = 0
	}
    data["elementTrophies"] = {}
    
    print("Created Data for player ", playerID)
	
	return data
end

function GetPlayerDifficulty(playerID)
	return PlayerData[playerID].difficulty
end

function GetPlayerData(playerID)
	return PlayerData[playerID]
end

function GetPlayerName(playerID)
	return PlayerData[playerID].name or ""
end

function GetPlayerElementLevel( playerID, element )
	return GetPlayerData(playerID).elements[element]
end

function GetPlayerNetworth(playerID)
	local playerData = GetPlayerData(playerID)
	
    -- If a networth is set on EndGameForPlayer, that's the final value
    if playerData.networth then
		return playerData.networth
	end

    local playerNetworth = PlayerResource:GetGold(playerID) or 0
	for i,v in pairs( playerData.towers ) do
		local tower = EntIndexToHScript( i )
		if IsValidEntity(tower) and tower:GetHealth() == tower:GetMaxHealth() then
			for i=0,15 do
				local ability = tower:GetAbilityByIndex( i )
				if ability then
					local name = ability:GetAbilityName()
                    local cost = 0
                    if tower.class then
                        cost = GetUnitKeyValue( tower.class, "TotalCost" )
                    end
                    
					if ( name == "sell_tower_100" ) then
						playerNetworth = playerNetworth + cost
					elseif ( name == "sell_tower_98" ) then
						playerNetworth = playerNetworth + round( cost * 0.98 )
					elseif ( name == "sell_tower_95" ) then
						playerNetworth = playerNetworth + round( cost * 0.95 )
					elseif ( name == "sell_tower_90" ) then
						playerNetworth = playerNetworth + round( cost * 0.90 )
					end
				end
			end
		end
	end
	return playerNetworth
end

function IsPlayerUsingRandomMode( playerID )
	return GetPlayerData(playerID).elementalRandom or (GameSettings.elementsOrderName and string.match(GameSettings.elementsOrderName, "Random"))
end

-- Players can only enable random if their elementCount is 0, and before wave 5 finishes
function CanPlayerEnableRandom( playerID )
	local playerData = GetPlayerData(playerID)
	return playerData.elementalCount == 0 and playerData.completedWaves < 5
end

-- Players can only buy pure essence with lvl 1 on all elements or an element at level 3
function CanPlayerBuyPureEssence( playerID )
    local playerData = GetPlayerData(playerID)
    local elements = playerData.elements

    local hasLvl3 = false
    local hasLvl1 = true
    for i,v in pairs(elements) do
        if v == 3 then -- if level 3 of element
            hasLvl3 = true
        end
        if v == 0 then
            hasLvl1 = false
        end
    end

    return hasLvl3 or hasLvl1
end

function PlayElementalExplosion(element, tower)
    local particleName = ExplosionParticles[element]
    local explosion = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, tower)
    ParticleManager:SetParticleControl(explosion, 0, tower:GetAbsOrigin())

    if element=="earth" then
        ParticleManager:SetParticleControl(explosion, 1, Vector(150,150,150))
    elseif element=="light" then
        ParticleManager:SetParticleControlEnt(explosion, 1, tower, PATTACH_POINT_FOLLOW, "attach_hitloc", tower:GetAbsOrigin(), true)
    end
end

function ModifyElementValue(playerID, element, change)
	local playerData = GetPlayerData(playerID)

	if not playerData.elements[element] then 
		Log:error(element.. ' is not a valid element')
		return
	end

	-- Fire a particle on all towers
    for k,v in pairs(playerData.towers) do
        local tower = EntIndexToHScript(k)

        PlayElementalExplosion(element, tower)
    end

    if playerData.elementalCount == 0 then
        if playerData.summoner then
   		   StopHighlight(playerData.summoner, playerID)
   		   if playerData.lumber == 0 then
   			  PlayerResource:RemoveFromSelection(playerID, playerData.summoner )
   		   end
        end
   	end
   	
	playerData.elements[element] = playerData.elements[element] + change
	UpdateElementsHUD(playerID)
	UpdatePlayerSpells(playerID)
	UpdateSummonerSpells(playerID)
	ShowElementAcquiredMessage(playerID, element, playerData.elements[element])
	for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end

    -- Update orbs
    if playerData.elements[element] == 1 then
    	UpdateElementOrbs(playerID, element)
    	playerData.elementalCount = playerData.elementalCount + 1
    end

    -- Keep the order
    playerData.elementOrder[#playerData.elementOrder+1] = firstToUpper(element)

    -- First Dual (15 possible)
    if playerData.elementalCount == 2 then
    	playerData.firstDual = GetElementalOrderString(playerData.elements)

    -- First Triple (20 possible)
    elseif playerData.elementalCount == 3 then
		playerData.firstTriple = GetElementalOrderString(playerData.elements)
	end
	UpdateScoreboard(playerID)
end

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
                        
                        -- Refresh hero selection
                        if PlayerResource:IsUnitSelected(playerID, hero)  then
                            PlayerResource:NewSelection(playerID, hero)
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

    UpdatePlayerHealth(playerID);
end

-- health correction for gamemodes where max health > 50
local maxHealth = nil;
function UpdatePlayerHealth(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    if hero then
        maxHealth = maxHealth or GameSettings:GetMapSetting("Lives")
        hero:SetBaseMaxHealth(maxHealth)
        hero:SetMaxHealth(maxHealth)
        hero:SetHealth(playerData.health)
    end
end

function UpdateElementsHUD(playerID)
	local playerData = GetPlayerData(playerID)
	local data = {}
	data.playerID = playerID

	for k, v in pairs(playerData.elements) do
		data[k] = v
	end

	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_elements", data )
end

function UpdateSummonerSpells(playerID)
    local playerData = GetPlayerData(playerID)
    local lumber = playerData.lumber
    local summoner = playerData.summoner

    -- Exit out if no summoner
    if not summoner then
        return
    end

    UpdateRunes(playerID)

    for i=0,5 do
        local item = summoner:GetItemInSlot(i)
        if item then
            itemName = item:GetAbilityName()
            if itemName == "item_buy_pure_essence_disabled" and CanPlayerBuyPureEssence(playerID) then
                item:RemoveSelf()
                summoner:AddItem(CreateItem("item_buy_pure_essence", nil, nil))
            end
        end
    end

    if EXPRESS_MODE and not playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local level = playerData.elements[v["Element"]] + 1
                local ability = summoner:FindAbilityByName(k)
                if level == 1 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 2 and playerData.completedWaves >= 6 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 3 and playerData.completedWaves >= 15 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                else
                    ability:SetActivated(false)
                end
                ability:SetLevel(level)
            end
        end
    elseif playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(false)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    else
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(lumber >= v["LumberCost"] and playerData.elements[v["Element"]] < 3)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    end
end

function UpdateScoreboard(playerID, express_end)
	local playerData = GetPlayerData(playerID)
	if not playerData then
		return
	end
	local data = {}
	data.lives = playerData.health
	data.towers = tablelength(playerData.towers)
	data.lumber = playerData.lumber
	data.pureEssence = playerData.pureEssence
	data.difficulty = "NA"
	if playerData.difficulty then
		data.difficulty = playerData.difficulty.difficultyName
	end
	data.gold = PlayerResource:GetGold(playerID)
	data.networth = GetPlayerNetworth(playerID)
	data.lastHits = PlayerResource:GetLastHits(playerID)
	data.iceFrogKills = playerData.iceFrogKills
	if data.iceFrogKills == 0 and playerData.remaining then
		data.remaining = playerData.remaining
	end

    if data.remaining and data.remaining < 0 then data.remaining = 0 end

	if express_end then
		playerData.express_end = true
	end
	data.express_end = playerData.express_end

	data.randomed = playerData.elementalRandom --self-random
	data.elements = playerData.elements
	CustomGameEventManager:Send_ServerToAllClients("etd_update_scoreboard", {playerID=playerID, data = data})
end

function UpdateRandom(playerID)
    local playerData = GetPlayerData(playerID)
    if playerData.elementalRandom then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_player_random_enable", {} )
    end
end

function UpdateWaveInfo(playerID, wave)
    local player = PlayerResource:GetPlayer(playerID)
    local playerData = GetPlayerData(playerID)

    if player then
        local next_wave = wave+1
        if EXPRESS_MODE and wave==WAVE_COUNT then
        	CustomGameEventManager:Send_ServerToPlayer( player, "etd_next_wave_info", { nextWave="end"} )
        elseif next_wave >= WAVE_COUNT then
        	if not EXPRESS_MODE then
                local next_boss_wave = CURRENT_BOSS_WAVE and CURRENT_BOSS_WAVE + 1 or 1
            	CustomGameEventManager:Send_ServerToPlayer( player, "etd_next_wave_info", { nextWave=0, bossWave = next_boss_wave, nextAbility1="", nextAbility2="creep_ability_boss" } )
            elseif next_wave == WAVE_COUNT then
            	CustomGameEventManager:Send_ServerToPlayer( player, "etd_next_wave_info", { nextWave=next_wave, nextAbility1=creepsKV[WAVE_CREEPS[next_wave]].Ability1, nextAbility2=creepsKV[WAVE_CREEPS[next_wave]].Ability2 } )
            end
        else
    		CustomGameEventManager:Send_ServerToPlayer( player, "etd_next_wave_info", { nextWave=next_wave, nextAbility1=creepsKV[WAVE_CREEPS[next_wave]].Ability1, nextAbility2=creepsKV[WAVE_CREEPS[next_wave]].Ability2 } )
        end
    end
end

function Highlight(entity, playerID)
	if not entity.highlight then
		PlayerResource:NewSelection(playerID, entity)
		Timers:CreateTimer(0.1, function() PlayerResource:SetCameraTarget(playerID, nil) end)
		local particleName = "particles/custom/summoner/highlight_trail_05.vpcf"
		entity.highlight = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, entity)
		ParticleManager:SetParticleControl(entity.highlight, 15, Vector(255,255,255))

		Sounds:EmitSoundOnClient( playerID, "Tutorial.Notice.Speech" )

		-- Portal World Notification
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "world_notification", {entityIndex=entity:GetEntityIndex(), text="#etd_summoner_choose"} )
	end
end

function StopHighlight(entity, playerID)
	if entity and entity.highlight then
		ParticleManager:DestroyParticle(entity.highlight, true)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "world_remove_notification", {entityIndex=entity:GetEntityIndex()} )
	end
end

function GetElementalOrderString( elementList )
	local elementTable = {}

	for elementName,level in pairs(elementList) do
		if level > 0 then
			table.insert(elementTable, firstToUpper(elementName))
		end
	end
	table.sort(elementTable)
	return table.concat(elementTable, "+")
end

function PlayerIsAlive( playerID )
    local playerData = GetPlayerData(playerID)
    return playerData and playerData.health and playerData.health > 0
end

function ItemRandomUse(event)
    local caster = event.caster
    local item = event.ability
    local playerID = caster:GetPlayerOwnerID()

    GameSettings:EnableRandomForPlayer(playerID)
end