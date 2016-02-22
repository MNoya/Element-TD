INTEREST_INTERVAL = 15 -- every 15 seconds
INTEREST_RATE = 0.02 -- 2% interest rate

if not InterestManager then
	InterestManager = class({})
	InterestManager.started = false
end

function InterestManager:StartInterestTimer()
	InterestManager.started = true

	Log:debug("Started interest timer "..INTEREST_INTERVAL)

	Timers:CreateTimer(INTEREST_INTERVAL, function()
		for _,plyID in pairs(playerIDs) do
			if plyID then
				local hero = ElementTD.vPlayerIDToHero[plyID]
				if hero and hero:IsAlive() then
					local playerData = GetPlayerData(plyID)
					if playerData.health ~= 0 and ((playerData.completedWaves < WAVE_COUNT - 1 and not EXPRESS_MODE) or (playerData.completedWaves < WAVE_COUNT and EXPRESS_MODE)) then
						InterestManager:GiveInterest(plyID)
					end
				end
			end
		end
		return INTEREST_INTERVAL
	end)

	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { interval=INTEREST_INTERVAL, rate=INTEREST_RATE, enabled=true } )
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