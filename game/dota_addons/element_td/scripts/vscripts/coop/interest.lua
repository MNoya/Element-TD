-- interest manager for element_td_coop

INTEREST_INTERVAL = 15 -- every 15 seconds
INTEREST_RATE = 0.02 -- 2% interest rate
END_OFFSET = 1 -- how many waves from the end of the game to stop interest

if not InterestManagerCoop then
	InterestManagerCoop = class({})
	InterestManagerCoop.started = false
	InterestManagerCoop.timer = nil
	InterestManagerCoop.locked = false
	InterestManagerCoop.gameStartedBefore = false

	InterestManager = InterestManagerCoop
	print("Loaded InterestManagerCoop")
end

-- starts the interest timers initally for all players
-- this should only be called once, when the game starts
function InterestManagerCoop:StartInterest()
	InterestManagerCoop.started = true
	Log:debug("Starting interest for all players at ".. INTEREST_INTERVAL .. "s")

	InterestManagerCoop:CreateTimer()
	CustomNetTables:SetTableValue("gameinfo", "interest_stopped", {value=false})

	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { 
		interval = INTEREST_INTERVAL, 
		rate = INTEREST_RATE, 
		enabled = true 
	})
end

-- handles co-op interest restarting
function InterestManagerCoop:Restart()
	InterestManagerCoop:PauseInterest(true)

	ForAllPlayerIDs(function(playerID)
		GetPlayerData(playerID).interestGold = 0
		local player = PlayerResource:GetPlayer(playerID)
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "etd_restart_interest", {})
		end
	end)
	
	InterestManagerCoop.started = false
	InterestManagerCoop.timer = nil
	InterestManagerCoop.locked = false
	InterestManagerCoop.gameStartedBefore = false
end

function InterestManagerCoop:HandlePlayerReconnect(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	if InterestManagerCoop.started and player then
		
		CustomGameEventManager:Send_ServerToPlayer(player, "etd_display_interest", { 
			interval = INTEREST_INTERVAL, 
			rate = INTEREST_RATE, 
			enabled = true 
		})
		
		if interest.locked then
			CustomGameEventManager:Send_ServerToPlayer(player, "etd_pause_interest", {})
		else
			local timerName = InterestManagerCoop.timer
			if timerName and Timers.timers[timerName] then
				local timeRemaining = Timers.timers[timerName].endTime - GameRules:GetGameTime()
				CustomGameEventManager:Send_ServerToPlayer(player, "etd_resume_interest", { timeRemaining = timeRemaining })
			end
		end

	end
end

function InterestManagerCoop:CreateTimer(timeRemaining)
	if InterestManagerCoop.timer then return end

	InterestManagerCoop.timer = Timers:CreateTimer(timeRemaining or INTEREST_INTERVAL, function()
		if COOP_WAVE < WAVE_COUNT - END_OFFSET then
			InterestManagerCoop:GiveInterest()
		else
			Log:debug("Completely stopping interest")
			CustomNetTables:SetTableValue("gameinfo", "interest_stopped", {value=true})
			InterestManagerCoop:PauseInterest(true)
			return nil
		end
		return INTEREST_INTERVAL
	end)
end

function InterestManagerCoop:CheckForIncorrectPausing()
	-- I don't know if we will actually need this in co-op mode
end

function InterestManagerCoop:CompletedWave(waveNumber)
	if InterestManagerCoop.locked then
		InterestManagerCoop:ResumeInterest()
	end
end

-- force the player's interest to resume
function InterestManagerCoop:ResumeInterest()
	InterestManagerCoop.locked = false
	
	CustomGameEventManager:Send_ServerToAllClients("etd_resume_interest", {
		timeRemaining = InterestManagerCoop.TimeRemaining
	})

	InterestManagerCoop:CreateTimer(InterestManagerCoop.TimeRemaining)
	InterestManagerCoop.TimeRemaining = 0
end

function InterestManagerCoop:PauseInterest(bResetBar)
	local timerName = InterestManagerCoop.timer

	if InterestManagerCoop.timer then

		if Timers.timers[timerName] then
			-- store time remaining for when we resume
			InterestManagerCoop.TimeRemaining = Timers.timers[timerName].endTime - GameRules:GetGameTime()
		else
			Log:warn("[INTEREST] Attempted interest pause but timer was missing.")
		end
		
		Timers:RemoveTimer(timerName)
		InterestManagerCoop.timer = nil
			
		-- store this pause in the case of player disconnect
		InterestManagerCoop.locked = true

		CustomGameEventManager:Send_ServerToAllClients("etd_pause_interest", {bResetBar = bResetBar})
	end
end

function InterestManagerCoop:LeakedWave(waveNumber)
	-- leaking does not affect interest after the last wave spawns
	if waveNumber >= WAVE_COUNT - END_OFFSET then
		return
	end

	if not InterestManagerCoop.locked then
		InterestManagerCoop.locked = true
		InterestManagerCoop:PauseInterest(false)
	end
end

-- gives all players interest based on total team gold
function InterestManagerCoop:GiveInterest()
	local gold = PlayerResource:GetTotalGold() / PlayerResource:GetPlayerCount()
	local interest = math.floor(gold * INTEREST_RATE)

	if interest > 0 then
		ForAllPlayerIDs(function(playerID)
			local playerData = GetPlayerData(playerID)
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)

			hero:ModifyGold(interest)
			PopupAlchemistGold(hero, interest)
			Sounds:EmitSoundOnClient(playerID, "Interest.Midas")
			playerData.interestGold = playerData.interestGold + interest
		end)
	end
	
	CustomGameEventManager:Send_ServerToAllClients("etd_earned_interest", {goldEarned = interest})
end

function InterestManagerCoop:IsStarted()
	return InterestManagerCoop.started
end