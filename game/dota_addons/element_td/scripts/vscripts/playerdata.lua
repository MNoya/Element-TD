-- playerdata.lua
-- manages player data

if not PlayerData then
	PlayerData = {}
end

function CreateDataForPlayer(playerID)
	PlayerData[playerID] = {}
	local data = PlayerData[playerID]
	data["health"] = 50
	data["sector"] = -1
	data["page"] = 1
	data["lumber"] = 0
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
	data["nextWave"] = 1
	data["activeWaves"] = {}
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