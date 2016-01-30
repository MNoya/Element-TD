-- playerdata.lua
-- manages player data

if not PlayerData then
	PlayerData = {}
end

function CreateDataForPlayer(playerID)
	PlayerData[playerID] = {}
	local data = PlayerData[playerID]
	data["health"] = 50
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
	data["elements"] = {
		water = 0, fire = 0, nature = 0,
		earth = 0, light = 0, dark = 0
	}
	data["towers"] = {}
	data["clones"] = {}
	data["difficulty"] = nil
	data["completedWaves"] = 0
	data["bossWaves"] = 0
	data["nextWave"] = 1
	data["activeWaves"] = 1
	data["waveObject"] = {} -- Current wave object
	data["waveObjects"] = {} -- All active wave objects
	
	return data
end

function GetPlayerDifficulty(playerID)
	return PlayerData[playerID].difficulty
end

function GetPlayerData(playerID)
	return PlayerData[playerID]
end

function GetPlayerName(playerID)
	return PlayerData[playerID].name
end

function GetPlayerElementLevel( playerID, element )
	return GetPlayerData(playerID).elements[element]
end

function IsPlayerUsingRandomMode( playerID )
	return GetPlayerData(playerID).elementalRandom or (GameSettings.elementsOrderName and string.match(GameSettings.elementsOrderName, "Random"))
end

function CanPlayerEnableRandom( playerID )
	local elementData = GetPlayerData(playerID).elements
	local count = 0
	for elem,level in pairs(elementData) do
		if level > 0 then
			return false
		end
	end
	return true
end

function ModifyElementValue(playerID, element, change)
	local playerData = GetPlayerData(playerID)

	if not playerData.elements[element] then 
		Log:error(element.. ' is not a valid element')
		return
	end

	-- Fire a particle on all towers
    local particleName = ExplosionParticles[element]
    for k,v in pairs(playerData.towers) do
        local tower = EntIndexToHScript(k)
        local explosion = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, tower)
        ParticleManager:SetParticleControl(explosion, 0, tower:GetAbsOrigin())

        if element=="earth" then
            ParticleManager:SetParticleControl(explosion, 1, Vector(150,150,150))
        elseif element=="light" then
            ParticleManager:SetParticleControlEnt(explosion, 1, tower, PATTACH_POINT_FOLLOW, "attach_hitloc", tower:GetAbsOrigin(), true)
        end
    end

   	playerData.elementalCount = playerData.elementalCount + change
	playerData.elements[element] = playerData.elements[element] + change
	UpdateElementsHUD(playerID)
	UpdatePlayerSpells(playerID)
	UpdateSummonerSpells(playerID)
	for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end

    -- Update orbs
    if playerData.elements[element] == 1 then
    	UpdateElementOrbs(playerID, element)
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

function UpdateScoreboard(playerID)
	local playerData = GetPlayerData(playerID)
	if not playerData then
		return
	end
	local health = playerData.health
	local towers = tablelength(playerData.towers)
	local lumber = playerData.lumber
	local pureEssence = playerData.pureEssence
	local difficulty = "NA"
	if playerData.difficulty then
		difficulty = playerData.difficulty.difficultyName
	end
	local gold = PlayerResource:GetGold(playerID)
	local lastHits = PlayerResource:GetLastHits(playerID)
	CustomGameEventManager:Send_ServerToAllClients( "etd_update_scoreboard", {playerID=playerID, data = {lives=health, lumber=lumber, towers=towers, pureEssence=pureEssence, difficulty=difficulty, gold=gold, lastHits=lastHits}} )
end

function UpdateElementOrbs(playerID, new_element)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local orb_path = "particles/custom/orbs/"

	if not hero.orbit_entities then
		hero.orbit_entities = {}
		hero.orb_count = 0
	end

	-- Clear orbs
	if hero.orb_count > 0 then
		for i=1,hero.orb_count do
			UTIL_Remove(hero.orbit_entities[i])
		end
	end

	-- Build list
	local elements = {}
	local playerData = GetPlayerData(playerID)
	for k,v in pairs(playerData.elements) do
		if v > 0 then
			table.insert(elements, k)
		end
	end

	hero.orb_count = hero.orb_count + 1

	-- Recreate orbs
	for k=1,#elements do
		local ent = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/props_gameplay/red_box.vmdl"})
		local angle = 360 / hero.orb_count
		local origin = hero:GetAbsOrigin()
		local rotate_pos = origin + Vector(1,0,0) * 80
		local pos = RotatePosition(origin, QAngle(0, angle*k, 0), rotate_pos)
		pos.z = pos.z + 90
		ent:SetAbsOrigin(pos)
		ent:SetParent(hero, "attach_hitloc")
		ent:AddEffects(EF_NODRAW)
		hero.orbit_entities[k] = ent

		-- Create particle attached to the entity
		local particleName = orb_path.."orb_"..elements[k]..".vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, ent)
		ParticleManager:SetParticleControlEnt(particle, 3, ent, PATTACH_POINT_FOLLOW, "attach_hitloc", ent:GetAbsOrigin(), true)
	end
end

function RemoveElementalOrbs(hero)
	for k,v in pairs(hero.orbits) do
		ParticleManager:DestroyParticle(v, false)
	end
end
