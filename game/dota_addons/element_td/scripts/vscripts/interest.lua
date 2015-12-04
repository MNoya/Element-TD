INTEREST_INTERVAL = 15; -- every 15 seconds
INTEREST_RATE = 0.02; -- 2% interest rate

InterestManager = {};
InterestManager.started = false;

function InterestManager:StartInterestTimer()
	Log:debug("Started interest timer");
	InterestManager.started = true;

	Timers:CreateTimer("InterestThinker", {
		endTime = INTEREST_INTERVAL,
		callback = function()
			local goldEarnedData = {};
			for _,ply in pairs(players) do
				if ply then
					local hero = ply:GetAssignedHero();
					if hero and GetPlayerData(ply:GetPlayerID()).health ~= 0 then
						local interest = math.ceil(hero:GetGold() * INTEREST_RATE);
						local gold = hero:GetGold() + interest;
						hero:SetGold(0, false);
						hero:SetGold(gold, true);
						PopupGoldGain(hero, interest);
						goldEarnedData["player" .. ply:GetPlayerID()] = interest;
						CustomGameEventManager:Send_ServerToPlayer( ply, "etd_earned_interest", { goldEarned=interest } )
					end
				end
			end

			FireGameEvent("etd_interest_earned", goldEarnedData);
			FireGameEvent("etd_start_interest_timer", {duration = INTEREST_INTERVAL});
			return INTEREST_INTERVAL;
		end
	});
	CustomGameEventManager:Send_ServerToAllClients("etd_display_interest", { interval=INTEREST_INTERVAL, rate=INTEREST_RATE, enabled=true } )
	FireGameEvent("etd_start_interest_timer", {duration = INTEREST_INTERVAL});

end

function InterestManager:IsStarted()
	return InterestManager.started;
end