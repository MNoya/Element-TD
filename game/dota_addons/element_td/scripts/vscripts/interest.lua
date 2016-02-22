INTEREST_INTERVAL = 15 -- every 15 seconds
INTEREST_RATE = 0.02 -- 2% interest rate

if not InterestManager then
	InterestManager = class({})
	InterestManager.started = false
	InterestManager.timers = {}
end


function InterestManager:StartInterest()
	InterestManager.started = true

	Log:debug("Started interest timer: ".. INTEREST_INTERVAL .. "s")

	for _, playerID in pairs(playerIDs) do
		if playerID then
			InterestManager:CreateTimerForPlayer(playerID)
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { interval=INTEREST_INTERVAL, rate=INTEREST_RATE, enabled=true } )
end

function InterestManager:CreateTimerForPlayer(playerID, timeRemaining)
	InterestManager.timers[playerID] = Timers:CreateTimer(timeRemaining or INTEREST_INTERVAL, function()
		local hero = ElementTD.vPlayerIDToHero[playerID]
		if hero and hero:IsAlive() then
			local playerData = GetPlayerData(playerID)
			if playerData.health ~= 0 and ((playerData.completedWaves < WAVE_COUNT - 1 and not EXPRESS_MODE) or (playerData.completedWaves < WAVE_COUNT and EXPRESS_MODE)) then
				InterestManager:GiveInterest(playerID)
			end
		end
		return INTEREST_INTERVAL
	end)
end

function InterestManager:PlayerCompletedWave(playerID, waveNumber)
	local interestData = GetPlayerData(playerID).interestData
	if interestData.Locked and interestData.LockingWaves[waveNumber] then
		interestData.LockingWaves[waveNumber] = nil
		interestData.NumLockingWaves = interestData.NumLockingWaves - 1

		if interestData.NumLockingWaves == 0 then
			InterestManager:ResumeInterestForPlayer(playerID)
		end
	end
end

function InterestManager:ResumeInterestForPlayer(playerID)
	--print("Resuming interest timer for " .. playerID)
	local interestData = GetPlayerData(playerID).interestData
	interestData.Locked = false
	interestData.NumLockingWaves = 0
	interestData.LockingWaves = {}

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_resume_interest", {
		timeRemaining = interestData.TimeRemaining
	})
	InterestManager:CreateTimerForPlayer(playerID, interestData.TimeRemaining)
	
	interestData.TimeRemaining = 0
end

function InterestManager:PauseInterestForPlayer(playerID, waveNumber)
	local interestData = GetPlayerData(playerID).interestData
	--print("player " .. playerID .. " has leaked wave " .. waveNumber)

	if not interestData.LockingWaves[waveNumber] then
		interestData.LockingWaves[waveNumber] = true
		interestData.NumLockingWaves = interestData.NumLockingWaves + 1
		--print("player " .. playerID .. " now has " .. interestData.NumLockingWaves .. " locking waves")
		if not interestData.Locked then
			local timerName = InterestManager.timers[playerID]
			interestData.Locked = true
			interestData.TimeRemaining = Timers.timers[timerName].endTime - GameRules:GetGameTime()
			
			--print("stopping timer\n")
			Timers:RemoveTimer(timerName)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_pause_interest", {})
		end
	end
end

function InterestManager:GiveInterest(playerID)
	local playerData = GetPlayerData(playerID)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	local gold = hero:GetGold()
	local interest = math.floor(gold * INTEREST_RATE)
	
	if interest > 0 then
		hero:ModifyGold(interest)
		PopupAlchemistGold(hero, interest)
		Sounds:EmitSoundOnClient(playerID, "Interest.Midas")

		playerData.interestGold = playerData.interestGold + interest
	end
	
	if player then
		CustomGameEventManager:Send_ServerToPlayer( player, "etd_earned_interest", { goldEarned=interest } )
	end
end

function InterestManager:IsStarted()
	return InterestManager.started
end