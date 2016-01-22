INTEREST_INTERVAL = 15 -- every 15 seconds
INTEREST_RATE = 0.02 -- 2% interest rate

if not InterestManager then
	InterestManager = {}
	InterestManager.started = false
end


function InterestManager:StartInterestTimer()
	Log:debug("Started interest timer")
	InterestManager.started = true

	Timers:CreateTimer("InterestThinker", {
		endTime = INTEREST_INTERVAL,
		callback = function()
			local goldEarnedData = {}
			for _,plyID in pairs(playerIDs) do
				if plyID then
					local ply = PlayerResource:GetPlayer(plyID)
					local hero = ElementTD.vPlayerIDToHero[plyID]
					if hero and hero:IsAlive() and GetPlayerData(plyID).health ~= 0 then
						local interest = math.ceil(hero:GetGold() * INTEREST_RATE)
						local gold = hero:GetGold() + interest
						hero:SetGold(0, false)
						hero:SetGold(gold, true)
						PopupAlchemistGold(hero, interest)
						Sounds:EmitSoundOnClient(plyID, "DOTA_Item.Hand_Of_Midas")
						goldEarnedData["player" .. plyID] = interest
						if ply then
							CustomGameEventManager:Send_ServerToPlayer( ply, "etd_earned_interest", { goldEarned=interest } )
						end
					end
				end
			end
			return INTEREST_INTERVAL
		end
	})
	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { interval=INTEREST_INTERVAL, rate=INTEREST_RATE, enabled=true } )
end

function InterestManager:IsStarted()
	return InterestManager.started
end