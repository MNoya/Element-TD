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
	GameSettings.difficulty = nil -- for co-op mode

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
	local bounty = math.floor(math.pow(self.data.BaseBounty, wave + 5))
	if EXPRESS_MODE then
		bounty = math.floor(math.pow(self.data.BaseBountyExpress, wave + 10))
	elseif wave == WAVE_COUNT then -- boss wave
		bounty = 0
	end
	if GameSettings:GetEndless() == "Endless" and bounty ~= 0 then -- Flat 25% bonus for rush mode
		bounty = round(bounty * (1.25))
	end
	return bounty
end

function DifficultyObject:GetBountyBonusMultiplier()
    return EXPRESS_MODE and self.data.BaseBountyExpress or self.data.BaseBounty
end

function DifficultyObject:GetBaseWorth()
    return EXPRESS_MODE and self.data.NetworthBonusExpress or self.data.NetworthBonus
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

function GameSettings:SetGlobalDifficulty(difficulty)
	GameSettings.difficulty = DifficultyObject(difficulty)
end

function GameSettings:GetGlobalDifficulty()
	return GameSettings.difficulty
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

		SetCustomGold(plyID, GameSettings.length.Gold)
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

            ElementTD:ExpressPrecache()
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

    elseif not VOTING_FINISHED then 
        SendErrorMessage(playerID, "#etd_random_wait_for_vote")        

    elseif CanPlayerEnableRandom(playerID) then
        playerData.elementalRandom = true
        Log:info("Enabled Random for player "..playerID)

        local color = playerColors[playerData.sector]
        GameRules:SendCustomMessage("<font color='"..color.."'>"..playerData.name.."</font> has chosen to random elements!", 0, 0)

        SendEssenceMessage(playerID, "#etd_random_toggle_enable")

        -- Generate a random order for this player
        playerData.elementsOrder = getRandomElementOrder()

        local first_random_element = GetRandomElementForPlayerWave(playerID, 0)
        BuyElement(playerID, first_random_element)

        if EXPRESS_MODE then
            local first_random_express = GetRandomElementForPlayerWave(playerID, 0, EXPRESS_MODE)
            BuyElement(playerID, first_random_express)
        end

        UpdatePlayerSpells(playerID)
        UpdateScoreboard(playerID)
        UpdateRandom(playerID)
    else
    	if playerData.completedWaves >= 5 then
    		SendErrorMessage(playerID, "#etd_random_5wave_error")
    	else
        	SendErrorMessage(playerID, "#etd_random_chosen_error")
        end
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
            GetPlayerData(plyID).elementsOrder = elementsOrder
            if elementsOrder[0] then
            	for _,v in pairs(elementsOrder[0]) do
            		BuyElement(plyID, v)
            	end
        	end
        end
    --all random, players get different element order
    elseif order == "AllRandom" then
        for _, plyID in pairs(playerIDs) do
            local elementsOrder = getRandomElementOrder()
            local playerData = GetPlayerData(plyID)
            playerData.elementsOrder = elementsOrder
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

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------
