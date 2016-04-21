-- holds important functions and variables for our cooperative mode

COOP_WAVE = 1 -- the current wave 
CREEPS_PER_WAVE_COOP = 120 -- number of creeps in each wave
CURRENT_WAVE_OBJECT = nil -- maybe should hold the WaveCoop 'object' of the wave that is currently active (can we ever have > 1 waves at once?)

COOP_HEALTH = 0
COOP_LIFE_TOWER_KILLS = 0
COOP_LIFE_TOWER_KILLS_TOTAL = 0

-- entry point
function CoopStart()
    COOP_HEALTH = GameSettings:GetMapSetting("Lives");
    local initialBreakTime = GameSettings.length.PregameTime
    StartBreakTimeCoop(initialBreakTime)
end

function SpawnWaveCoop()
    Log:info("Spawning co-op wave " .. COOP_WAVE)

    CURRENT_WAVE_OBJECT = WaveCoop(COOP_WAVE)
    
    -- First wave marks the start of the game
    if START_GAME_TIME == 0 then
        START_GAME_TIME = GameRules:GetGameTime()
    end

    for _, playerID in pairs(playerIDs) do
        local playerData = GetPlayerData(playerID)
        CustomGameEventManager:Send_ServerToAllClients("SetTopBarWaveValue", {playerId = playerID, wave = COOP_WAVE})
        
        -- not sure about these
        playerData.waveObject = CURRENT_WAVE_OBJECT 
        playerData.waveObjects[COOP_WAVE] = CURRENT_WAVE_OBJECT
    end

    if not InterestManager:IsStarted() then
        InterestManager:StartInterest()
    end
    -- InterestManager:CheckForIncorrectPausing() -- not needed?

    CURRENT_WAVE_OBJECT:SetOnCompletedCallback(function()   
        print("[COOP] Completed wave "..COOP_WAVE)

        if COOP_WAVE < WAVE_COUNT then
            COOP_WAVE = COOP_WAVE + 1
        end

        EmitGlobalSound("ui.npe_objective_complete")
        InterestManager:CompletedWave(COOP_WAVE)

        -- Boss Wave completed starts the new one with no breaktime
        if CURRENT_BOSS_WAVE > 0 then
            print("[COOP] Completed boss wave "..CURRENT_BOSS_WAVE)
            CURRENT_BOSS_WAVE = CURRENT_BOSS_WAVE + 1

            ForAllPlayerIDs(function(playerID)
                ShowBossWaveMessage(playerID, CURRENT_BOSS_WAVE)
                UpdateWaveInfo(playerID, COOP_WAVE)
            end)

            SpawnWaveCoop() 
            return
        end
 
        -- Start the breaktime for the next wave
        StartBreakTimeCoop(GameSettings:GetGlobalDifficulty():GetWaveBreakTime(COOP_WAVE))
    end)

    CURRENT_WAVE_OBJECT:SpawnWave()
end


function CreateMoveTimerForCreepCoop(creep, sector)
    local destination = EntityEndLocations[sector]

    Timers:CreateTimer(0.1, function()
        if IsValidEntity(creep) and creep:IsAlive() then
            creep:MoveToPosition(destination)

            if (creep:GetAbsOrigin() - destination):Length2D() <= 100 then
                
                if GameSettings:GetEndless() ~= "Endless" then
                    InterestManager:LeakedWave(creep.waveObject.waveNumber)
                end

                -- Boss Wave leaks = 3 lives
                local lives = 1
                if CURRENT_BOSS_WAVE > 0 then
                    lives = 3
                end

                -- Bulky creeps count as 2
                if creep:HasAbility("creep_ability_bulky") then
                    lives = lives * 2
                end

                COOP_HEALTH = COOP_HEALTH - 1
                for _, playerID in pairs(playerIDs) do
                    ReduceLivesForPlayer(playerID, lives)
                end

                creep.recently_leaked = true
                Timers:CreateTimer(10, function()
                    if IsValidEntity(creep) then creep.recently_leaked = nil end
                end)

                creep.times_leaked = creep.times_leaked and creep.times_leaked + 1 or 1
                FindClearSpaceForUnit(creep, EntityStartLocations[sector], true)

                creep:SetForwardVector(Vector(0, -1, 0))
            end
            return 0.1
        else
            return
        end
    end)
end

function StartBreakTimeCoop(breakTime)
    ElementTD:PrecacheWave(COOP_WAVE)

    local msgTime = 5 -- how long to show the message for
    if COOP_WAVE > 1 and (COOP_WAVE - 1) % 5 == 0 then
        breakTime = 30
    end
    -- First boss breaktime 60 seconds
    if COOP_WAVE == WAVE_COUNT and CURRENT_BOSS_WAVE == 0 then
        breakTime = 60
    end
    if msgTime >= breakTime then
        msgTime = breakTime - 0.5
    end

    -- show countdown timer for all players
    Log:debug("Starting co-op break time for wave " .. COOP_WAVE)
    local bShowButton = PlayerResource:GetPlayerCount() == 1 and COOP_WAVE == 1
    CustomGameEventManager:Send_ServerToAllClients("etd_update_wave_timer", {time = breakTime, button = bShowButton})

    -- show sector portals
    for i = 1, 6 do
        ShowPortalForSector(i, COOP_WAVE)
    end

    -- set up each individual player
    for _, playerID in pairs(playerIDs) do
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        local playerData = GetPlayerData(playerID)

        ShowWaveBreakTimeMessage(playerID, COOP_WAVE, breakTime, msgTime)

        if PlayerIsAlive(playerID) then

            -- Grant Lumber and Essence to all players the moment the next wave is set
            if WaveGrantsLumber(COOP_WAVE - 1) then
                ModifyLumber(playerID, 1)
                if IsPlayerUsingRandomMode( playerID ) then
                    Notifications:ClearBottom(playerID)
                    local element = GetRandomElementForPlayerWave(playerID, COOP_WAVE - 1)

                    Log:info("Randoming element for player "..playerID..": "..element)

                    if element == "pure" then
                        SendEssenceMessage(playerID, "#etd_random_essence")
                        ModifyLumber(playerID, -1)
                        ModifyPureEssence(playerID, 1)
                        playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1

                        -- Track pure essence purchasing as part of the element order
                        playerData.elementOrder[#playerData.elementOrder + 1] = "Pure"
                        
                        -- Gold bonus for Pure Essence randoming (removed in 1.5)
                        -- GivePureEssenceGoldBonus(playerID)
                    else
                        SendEssenceMessage(playerID, "#etd_random_elemental")
                        SummonElemental({caster = playerData.summoner, Elemental = element .. "_elemental"})
                    end
                else
                    Log:info("Giving 1 lumber to " .. playerData.name)
                end
            end

            if WaveGrantsEssence(COOP_WAVE - 1) then
                ModifyPureEssence(playerID, 1) 
                Log:info("Giving 1 pure essence to " .. playerData.name)
                playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
            end
        end
    end

    -- create the timer to wait for wave spawn
    Timers:CreateTimer("SpawnWaveDelay_Coop", {
        endTime = breakTime,
        callback = function()
        
            if COOP_WAVE == WAVE_COUNT then
                CURRENT_BOSS_WAVE = 1
                Log:info("Spawning the first co-op boss wave")
                
                for _, playerID in pairs(playerIDs) do
                    local playerData = GetPlayerData(playerID)
                    playerData.iceFrogKills = 0
                    playerData.bossWaves = CURRENT_BOSS_WAVE
                    ShowBossWaveMessage(playerID, CURRENT_BOSS_WAVE)
                    UpdateWaveInfo(playerID, COOP_WAVE)
                end
            else
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
