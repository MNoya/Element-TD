GameSettingsKV = LoadKeyValues("scripts/kv/gamesettings.kv")

-- gamesettings.lua
-- manages custom games settings such as difficulty, gamemodes, creep order, and game length
if not GameSettings then
	GameSettings = {}
	GameSettings.__index = GameSettings
	GameSettings.gamemode = ""
	GameSettings.endless = "Normal"
	GameSettings.order = "Normal"
	GameSettings.length = ""
	GameSettings.elements = ""

	DIFFICULTY_OBJECTS = {}
end

DifficultyObject = createClass({
		constructor = function(self, difficultyName)
			self.difficultyName = difficultyName
			self.data = GameSettingsKV.Difficulty[self.difficultyName]
		end
	},
{}, nil)

function DifficultyObject:GetBountyForWave(wave)
	local bounty = math.floor(math.pow(self.data.BaseBounty, wave + 4))
	if EXPRESS_MODE then
		bounty = math.floor(math.pow(self.data.BaseBountyExpress, wave + 8))
	elseif wave == WAVE_COUNT then -- boss wave
		bounty = 0
	end
	if GameSettings:GetEndless() == "Endless" and bounty ~= 0 then -- Flat 20% bonus for rush mode
		bounty = round(bounty * (1.20))
	end
	return bounty
end

function DifficultyObject:GetBountyBonusMultiplier()
    return EXPRESS_MODE and self.data.BaseBountyExpress or self.data.BaseBounty
end

function DifficultyObject:GetWaveBreakTime(wave)
	local times = self.data.WaveTimers
	if EXPRESS_MODE then
		times = self.data.WaveTimersExpress
	end
	for k, v in pairs(times) do
		local startNum = split(k, "-")[1]
		local endNum = split(k, "-")[2]
		if wave >= tonumber(startNum) and wave <= tonumber(endNum) then
			return v
		end
	end
	Log:warn("Invalid wave number: " .. wave)
	return 0
end

function DifficultyObject:GetHealthMultiplier()
	return tonumber(self.data.Health)
end

function DifficultyObject:GetArmorValue()
	return tonumber(self.data.Armor)
end

for df,_ in pairs(GameSettingsKV.Difficulty) do
	DIFFICULTY_OBJECTS[df] = DifficultyObject(df)
end

function GameSettings:SetDifficulty(playerID, difficulty)
	local playerData = GetPlayerData(playerID)
	playerData.difficulty = DIFFICULTY_OBJECTS[difficulty]
	Log:info("Set " .. GetPlayerName(playerID) .. "'s difficulty to " .. difficulty)
	UpdateScoreboard(playerID)
end

function GameSettings:SetGamemode(gamemode)
	self.gamemode = gamemode
end

function GameSettings:GetGamemode()
	return GameSettings.gamemode
end

function GameSettings:GetGameLength()
	return GameSettings.length
end

function GameSettings:GetEndless()
	return GameSettings.endless
end

function GameSettings:SetGameLength(length)
	GameSettings.length = GameSettingsKV["GameLength"][length]
	if not GameSettings.length then
		Log:warn("Attempted to set unknown game length: " .. length .. ". Defaulting to Normal")
		GameSettings:SetGameLength("Normal")
		return
	end
	for _,plyID in pairs(playerIDs) do
		local playerData = GetPlayerData(plyID)
		local hero = ElementTD.vPlayerIDToHero[plyID]

		hero:ModifyGold(GameSettings.length.Gold)
		ModifyLumber(plyID, GameSettings.length.Lumber)
		playerData.nextWave = GameSettings.length.Wave

		if length == "Developer" then
			for e,_ in pairs(playerData.elements) do
				ModifyElementValue(plyID, e, 1)
			end
			DEV_MODE = true
		end

		if length == "Express" then
			EXPRESS_MODE = true
    	end
	end
	Log:info("Set game length to " .. length)
end

function GameSettings:SetEndless(endless)
	self.endless = endless
end

function GameSettings:SetCreepOrder(order)
	if order ~= "Normal" and order ~= "Chaos" then
		Log:warn("Attempted to set invalid creep order: " .. order .. ". Defaulting to Normal")
		GameSettings:SetCreepOrder("Normal")
	else
		GameSettings.order = order
		loadWaveData(order == "Chaos")
	end
end

-- Called after a player chooses the individual -random option (random element chain shouldn't be shared)
function GameSettings:EnableRandomForPlayer(playerID)
    local playerData = GetPlayerData(playerID)

    if IsPlayerUsingRandomMode(playerID) then
    	SendErrorMessage(playerID, "#etd_random_already_enabled")

    elseif CanPlayerEnableRandom(playerID) then
        playerData.elementalRandom = true
        Log:info("Enabled Random for player "..playerID)
        SendEssenceMessage(playerID, "#etd_random_toggle_enable")
        BuyElement(playerID, getRandomElement(0))

        if EXPRESS_MODE then
            BuyElement(playerID, getRandomElement(0))
        end

        UpdatePlayerSpells(playerID)
        UpdateScoreboard(playerID)
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_player_random_enable", {} )
    else
    	if playerData.completedWaves >= 5 then
    		SendErrorMessage(playerID, "#etd_random_5wave_error")
    	else
        	SendErrorMessage(playerID, "#etd_random_chosen_error")
        end
    end
end

usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0, ["pure"] = 0 }
elements = {"water", "fire", "earth", "nature", "dark", "light", "pure"}
function getRandomElement(wave)
	local element = elements[math.random(#elements)]

	if element == "pure" then
		if usedElements[element] < 2 then
			local hasLvl3 = false
			local hasLvl1 = true
			for i,v in pairs(usedElements) do
				if v == 3 then -- if level 3 of element
					hasLvl3 = true
				end
				if v == 0 then
					hasLvl1 = false
				end
			end
			if hasLvl3 or hasLvl1 then
				usedElements[element] = usedElements[element] + 1
				return element
			else
				return getRandomElement(wave)
			end
		end
	end

	if EXPRESS_MODE and ((wave < 9 and usedElements[element] == 1) or (wave < 18 and usedElements[element] == 2) or usedElements[element] == 3 ) then
		return getRandomElement(wave)
	elseif not EXPRESS_MODE and ((wave < 15 and usedElements[element] == 1) or (wave < 30 and usedElements[element] == 2) or usedElements[element] == 3) then
		return getRandomElement(wave)
	else
		usedElements[element] = usedElements[element] + 1
		return element
	end
end

function GameSettings:SetElementOrder(order)
	local randomseed = string.gsub(GetSystemTime(), ":", "") .. string.gsub(GetSystemDate(), "/", "")
	math.randomseed(tonumber(randomseed))
	math.random() math.random() math.random()

	GameSettings.elementsOrderName = order
	GameSettings.elements = GameSettingsKV["ElementModes"][order]

	--same random, all players get the same element order
	if order == "SameRandom" then
		local elementsOrder = getRandomElementOrder()

		for _, plyID in pairs(playerIDs) do    
			print("Order for " .. GetPlayerName(plyID))
			PrintTable(elementsOrder)
            GetPlayerData(plyID).elementsOrder = elementsOrder
            if elementsOrder[0] then
            	for _,v in pairs(elementsOrder[0]) do
            		BuyElement(plyID, v)
            	end
        	end
        end
    end
end

function GameSettings:GetElementOrder()
    return GameSettings.elements 
end

function getRandomElementOrder()
	usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0, ["pure"] = 0}
	local elementsOrder = {}
	local startingElements = {}
	local lumber = GameSettings.length.Lumber

	if EXPRESS_MODE then
		elementsOrder[0] = startingElements
		for i = 0, lumber - 1 do
			startingElements[i] = getRandomElement(0)
		end
		for i = 3, 27, 3 do
			local element = getRandomElement(i)
			--print("[" .. i .. "] " .. element)
			elementsOrder[i] = element
		end
	else
		elementsOrder[0] = startingElements
		for i = 0, lumber - 1 do
			startingElements[i] = getRandomElement(0)
		end
		for i = 5, 50, 5 do
			local element = getRandomElement(i)
			--print("[" .. i .. "] " .. element)
			elementsOrder[i] = element
		end
	end
	return elementsOrder
end

function GetRandomElementForWave(playerID, wave)
    local playerData = GetPlayerData(playerID)
    usedElements = {["water"] = playerData.elements["water"], ["fire"] = playerData.elements["fire"], ["earth"] = playerData.elements["earth"], ["nature"] = playerData.elements["nature"], ["dark"] = playerData.elements["dark"], ["light"] = playerData.elements["light"], ["pure"] = playerData.pureEssenceTotal}

    local element = getRandomElement(wave)

    return element
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------
