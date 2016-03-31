-- holds important functions and variables for our cooperative mode

COOP_WAVE = 1 -- the current wave 
CREEPS_PER_WAVE_COOP = 20 -- number of creeps in each wave
CURRENT_WAVE = nil -- maybe should hold the WaveCoop 'object' of the wave that is currently active (can we ever have > 1 waves at once?)

function SpawnWaveCoop()
	-- spawn wave COOP_WAVE
	Log:debug("SpawnWaveCoop() 4Head")
end

function StartBreakTimeCoop(breakTime)
	ElementTD:PrecacheWave(COOP_WAVE)

	local msgTime = 5 -- how long to show the message for
    if (COOP_WAVE - 1) % 5 == 0 and not EXPRESS_MODE then
        breakTime = 30
    end
    -- First boss breaktime 60 seconds
    if not EXPRESS_MODE and COOP_WAVE == WAVE_COUNT and CURRENT_BOSS_WAVE == 0 then
        breakTime = 60
    end
    if msgTime >= breakTime then
        msgTime = breakTime - 0.5
    end

    -- show countdown timer for all players
    Log:debug("Starting co-op break time for wave " .. COOP_WAVE)
   	-- local bShowButton = PlayerResource:GetPlayerCount() == 1 and COOP_WAVE == 1
    CustomGameEventManager:Send_ServerToAllClients("etd_update_wave_timer", {time = breakTime, button = false})
	
	-- TODO: update portals, give players lumber/esscense, random elementals
	-- set up each individual player
	for _, playerID in pairs(playerIDs) do
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		
		ShowWaveBreakTimeMessage(playerID, COOP_WAVE, breakTime, msgTime)
		if hero then 
        	hero:RemoveModifierByName("modifier_silence")
    	end
	end

	-- create the timer to wait for wave spawn
    Timers:CreateTimer("SpawnWaveDelayCoop", {
        endTime = breakTime,
        callback = function()

            if COOP_WAVE == WAVE_COUNT and not EXPRESS_MODE then
                CURRENT_BOSS_WAVE = 1
                
                -- TODO: make this work with co-op mode
                --[[
                if PlayerIsAlive(playerID) then
                    Log:info("Spawning the first boss wave for ["..playerID.."]")            
                    playerData.iceFrogKills = 0
                    playerData.bossWaves = CURRENT_BOSS_WAVE
                end
                ShowBossWaveMessage(playerID, CURRENT_BOSS_WAVE)
                UpdateWaveInfo(playerID, wave)
                ]]--
            else
            	Log:info("Spawning co-op wave " .. COOP_WAVE)
            	for _, playerID in pairs(playerIDs) do
					ShowWaveSpawnMessage(playerID, COOP_WAVE) -- show wave spawn message
					UpdateWaveInfo(playerID, COOP_WAVE) -- update wave info
				end
            end

            if COOP_WAVE == 1 then
                EmitAnnouncerSound("announcer_announcer_battle_begin_01")
            end

            -- spawn dat wave
            SpawnWaveCoop() 
        end
    })
end