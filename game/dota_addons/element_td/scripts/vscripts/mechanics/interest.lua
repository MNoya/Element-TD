INTEREST_INTERVAL = 15 -- every 15 seconds
INTEREST_RATE = 0.02 -- 2% interest rate
END_OFFSET = 1 -- how many waves from the end of the game to stop interest

if not InterestManager then
	InterestManager = class({})
	InterestManager.started = false
	InterestManager.timers = {}
	InterestManager.playerLockStates = {}
	InterestManager.gameStartedBefore = false
end

-- starts the interest timers initally for all players
-- this should only be called once, when the game starts
function InterestManager:StartInterest()
	InterestManager.started = true
	Log:debug("Starting interest for all player at ".. INTEREST_INTERVAL .. "s")

	for _, playerID in pairs(playerIDs) do
		if playerID then
			InterestManager:CreateTimerForPlayer(playerID)
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { 
		interval = INTEREST_INTERVAL, 
		rate = INTEREST_RATE, 
		enabled = true 
	})
end

-- handles single player interest restarting
function InterestManager:Restart(playerID)
	local playerData = GetPlayerData(playerID)
	if InterestManager.timers[playerID] then
		InterestManager:PauseInterestForPlayer(playerID, "#etd_interest_lock_end_title", "#etd_interest_lock_end")
	end

	local player = PlayerResource:GetPlayer(playerID)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "etd_restart_interest", {})
	end
	
	playerData.interestGold = 0
	InterestManager.started = false
	InterestManager.playerLockStates = {}
	InterestManager.timers = {}
end

function InterestManager:HandlePlayerReconnect(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	if InterestManager.started and player then
		
		CustomGameEventManager:Send_ServerToPlayer(player, "etd_display_interest", { 
			interval = INTEREST_INTERVAL, 
			rate = INTEREST_RATE, 
			enabled = true 
		})
		
		local lockState = InterestManager.playerLockStates[playerID]
		if lockState then
			CustomGameEventManager:Send_ServerToPlayer(player, "etd_pause_interest", lockState)
		else
			local timerName = InterestManager.timers[playerID]
			if timerName and Timers.timers[timerName] then
				local timeRemaining = Timers.timers[timerName].endTime - GameRules:GetGameTime()
				CustomGameEventManager:Send_ServerToPlayer(player, "etd_resume_interest", { timeRemaining = timeRemaining })
			end
		end

	end
end

function InterestManager:CreateTimerForPlayer(playerID, timeRemaining)
	if InterestManager.timers[playerID] then return end

	InterestManager.timers[playerID] = Timers:CreateTimer(timeRemaining or INTEREST_INTERVAL, function()
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and hero:IsAlive() then
			local playerData = GetPlayerData(playerID)
			if playerData.health ~= 0 then
				
				if playerData.completedWaves < WAVE_COUNT - END_OFFSET then
					InterestManager:GiveInterest(playerID)
				else
					Log:debug("Completely stopping interest for player " .. playerID)
					InterestManager:PauseInterestForPlayer(playerID, "#etd_interest_lock_end_title", "#etd_interest_lock_end")
					return nil
				end

			end
		end
		return INTEREST_INTERVAL
	end)
end

-- called every time a wave spawns for a player
-- checks to make sure the player's interest isn't locked when it shouldn't be
function InterestManager:CheckForIncorrectPausing(playerID)
	local playerData = GetPlayerData(playerID)
	local interestData = playerData.interestData

	if playerData.completedWaves < WAVE_COUNT - END_OFFSET and interestData.Locked then
		for waveNumber, _ in pairs(interestData.LockingWaves) do
			if not playerData.waveObjects[waveNumber] then
				interestData.LockingWaves[waveNumber] = nil
				interestData.NumLockingWaves = interestData.NumLockingWaves - 1

				if interestData.NumLockingWaves == 0 then
					InterestManager:ResumeInterestForPlayer(playerID)
					break
				end
			end
		end
	end
end

-- called whenever a player completes a wave
-- checks if the cleared wave is locking interest and resumes it if it is the last locking wave
function InterestManager:PlayerCompletedWave(playerID, waveNumber)
	local playerData = GetPlayerData(playerID)

	if playerData.completedWaves >= WAVE_COUNT - END_OFFSET then
		return
	end

	local interestData = playerData.interestData
	if interestData.Locked and interestData.LockingWaves[waveNumber] then
		interestData.LockingWaves[waveNumber] = nil
		interestData.NumLockingWaves = interestData.NumLockingWaves - 1

		if interestData.NumLockingWaves == 0 then
			InterestManager:ResumeInterestForPlayer(playerID)
		end
	end
end

-- force the player's interest to resume
function InterestManager:ResumeInterestForPlayer(playerID)
	local interestData = GetPlayerData(playerID).interestData
	interestData.Locked = false
	interestData.NumLockingWaves = 0
	interestData.LockingWaves = {}

	local player = PlayerResource:GetPlayer(playerID)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "etd_resume_interest", {
			timeRemaining = interestData.TimeRemaining
		})
	end
	InterestManager.playerLockStates[playerID] = nil
	InterestManager:CreateTimerForPlayer(playerID, interestData.TimeRemaining)
	interestData.TimeRemaining = 0
end

-- pauses interest for the given player
function InterestManager:PauseInterestForPlayer(playerID, title, msg)
	local player = PlayerResource:GetPlayer(playerID)
	local interestData = GetPlayerData(playerID).interestData
	local timerName = InterestManager.timers[playerID]

	if timerName and Timers.timers[timerName] then
			
		local timeRemaining = Timers.timers[timerName].endTime - GameRules:GetGameTime()
		interestData.TimeRemaining = timeRemaining
		
		Timers:RemoveTimer(timerName)
		InterestManager.timers[playerID] = nil
			
		-- store this pause in the case of player disconnect
		InterestManager.playerLockStates[playerID] = {
			title = title,
			msg = msg
		}

		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "etd_pause_interest", {title = title, msg = msg})
		end
	end
end

function InterestManager:PlayerLeakedWave(playerID, waveNumber)
	local playerData = GetPlayerData(playerID)
	local interestData = playerData.interestData

	-- leaking does not affect interest after the last wave spawns
	if playerData.completedWaves >= WAVE_COUNT - END_OFFSET then
		return
	end

	if not interestData.LockingWaves[waveNumber] and playerData.waveObjects[waveNumber] then
		interestData.LockingWaves[waveNumber] = true
		interestData.NumLockingWaves = interestData.NumLockingWaves + 1
		if not interestData.Locked then
			interestData.Locked = true
			InterestManager:PauseInterestForPlayer(playerID, "#etd_interest_lock_leak_title", "#etd_interest_lock_leak")
		end
	end
end

-- gives the specified player interest based on their current gold
function InterestManager:GiveInterest(playerID)
	local playerData = GetPlayerData(playerID)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	local gold = hero:GetGold()
	local interest = math.floor(gold * INTEREST_RATE)

	-- cooperative interest
	if COOP_MAP then
		gold = PlayerResource:GetTotalGold() / PlayerResource:GetPlayerCount()
		interest = math.floor(gold * INTEREST_RATE)
	end

	if interest > 0 then
		hero:ModifyGold(interest)
		PopupAlchemistGold(hero, interest)
		Sounds:EmitSoundOnClient(playerID, "Interest.Midas")
		playerData.interestGold = playerData.interestGold + interest
	end
	
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "etd_earned_interest", {goldEarned = interest})
	end
end

function InterestManager:IsStarted()
	return InterestManager.started
end