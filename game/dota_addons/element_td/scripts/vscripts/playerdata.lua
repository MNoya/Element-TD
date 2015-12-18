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
	data["pureEssence"] = 0
	data["elementalActive"] = false
	data["elementalUnit"] = nil
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
	local health = playerData.health
	local towers = tablelength(playerData.towers)
	local lumber = playerData.lumber
	local pureEssence = playerData.pureEssence
	local difficulty = "NA"
	if playerData.difficulty then
		difficulty = playerData.difficulty.difficultyName
	end
	CustomGameEventManager:Send_ServerToAllClients( "etd_update_scoreboard", {playerID=playerID, data = {lives=health, lumber=lumber, towers=towers, pureEssence=pureEssence,difficulty=difficulty}} )
end