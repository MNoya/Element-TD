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
	data["page"] = 1
	data["lumber"] = 0
	data["pureEssenceTotal"] = 0 -- Keep track of the total amount given to the player
	data["pureEssence"] = 0
	data["elementalActive"] = false
	data["elementalUnit"] = nil
	data["elementalRandom"] = false
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
	data["waveObject"] = {}
	
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

    -- If a new element was added, update orbs
    if playerData.elements[element] == 0 then
    	UpdateElementOrbs(playerID, element)
    end

	playerData.elements[element] = playerData.elements[element] + change
	UpdateElementsHUD(playerID)
	UpdatePlayerSpells(playerID)
	UpdateSummonerSpells(playerID)
	for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
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

	if not hero.orbits then
		hero.orbits = {}
		hero.orb_count = 0
	end
	hero.orb_count = hero.orb_count + 1

	-- Create new orb
	local particleName = orb_path.."orb_"..new_element..".vpcf"
	hero.orbits[hero.orb_count] = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, hero)

	-- Update
	if not hero.orbitTimer then
		hero.orbitTimer = Timers:CreateTimer(function()
			if hero:IsAlive() then
				for k,particle in pairs(hero.orbits) do
					local angle = 360 / hero.orb_count
					local origin = hero:GetAbsOrigin()
					local rotate_pos = origin + Vector(1,0,0) * 80
					local pos = RotatePosition(origin, QAngle(0, angle*k, 0), rotate_pos)
					pos.z = pos.z + 90
					ParticleManager:SetParticleControl(particle, 0, pos)
				end
				return 0.03
			else
				RemoveElementalOrbs(hero)
			end
		end)
	end
end

function RemoveElementalOrbs(hero)
	for k,v in pairs(hero.orbits) do
		ParticleManager:DestroyParticle(v, false)
	end
end
