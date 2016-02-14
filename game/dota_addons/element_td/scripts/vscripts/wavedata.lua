-- wavedata.lua
-- manages the spawning of creep waves

if not WAVE_CREEPS then
    WAVE_CREEPS = {}  -- array that stores the order that creeps spawn in. see /scripts/kv/waves.kv
    WAVE_HEALTH = {}  -- array that stores creep health values per wave.  see /scripts/kv/waves.kv
    CREEP_SCRIPT_OBJECTS = {}
    CREEPS_PER_WAVE = 30 -- the number of creeps to spawn in each wave
    WAVE_1_STARTED = false
    CURRENT_WAVE = 1
end

wavesKV = LoadKeyValues("scripts/kv/waves.kv")
creepsKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
WAVE_COUNT = wavesKV["WaveCount"]

-- loads the creep and health data for each wave. Randomizes the creep order if 'chaos' is set to true
function loadWaveData(chaos)
    local settings = GameSettingsKV.GameLength["Normal"]
    if EXPRESS_MODE then
        WAVE_COUNT = wavesKV["WaveCountExpress"]
        settings = GameSettingsKV.GameLength["Express"]
    end

    local baseHP = tonumber(settings["BaseHP"])
    local multiplier = tonumber(settings["Multiplier"])

    for i=1,WAVE_COUNT do
        if EXPRESS_MODE then
           WAVE_CREEPS[i] = wavesKV[tostring(i)].CreepExpress
        else
    	   WAVE_CREEPS[i] = wavesKV[tostring(i)].Creep
        end

        -- Health formula: Last Wave HP * Multiplier
        if i==1 then
            WAVE_HEALTH[i] = baseHP
        else
            WAVE_HEALTH[i] = WAVE_HEALTH[i-1] * multiplier
        end
    end
    if chaos then
        local lastWaves = {}
        local k = WAVE_COUNT
        if not EXPRESS_MODE then
            for i = k, k + 1, 1 do
                lastWaves[i] =  WAVE_CREEPS[i]
                WAVE_CREEPS[i] = nil
            end
        elseif EXPRESS_MODE then
            lastWaves[k] = WAVE_CREEPS[k]
            WAVE_CREEPS[k] = nil
        end
        WAVE_CREEPS = shuffle(WAVE_CREEPS)
        if not EXPRESS_MODE then
            for i = k, k + 1, 1 do
                table.insert(WAVE_CREEPS, lastWaves[i])
            end
        elseif EXPRESS_MODE then
            table.insert(WAVE_CREEPS, lastWaves[k])
        end
    end

    -- Print and round the values
    for k,v in pairs(WAVE_CREEPS) do
        WAVE_HEALTH[k] = round(WAVE_HEALTH[k])
        print(string.format("%2d | %-20s %5.0f",k,v,WAVE_HEALTH[k]))
    end
end

-- starts the break timer for the specified player.
-- the next wave spawns once the break time is over
function StartBreakTime(playerID, breakTime)
    local ply = PlayerResource:GetPlayer(playerID)
    local hero = ElementTD.vPlayerIDToHero[playerID]
    local playerData = GetPlayerData(playerID)
    
    hero:RemoveModifierByName("modifier_silence")

    -- let's figure out how long the break is
    local wave = GetPlayerData(playerID).nextWave
    if GameSettings:GetGamemode() == "Competitive" and GameSettings:GetEndless() == "Normal" then
        wave = CURRENT_WAVE
    end
    local msgTime = 5 -- how long to show the message for
    if (wave - 1) % 5 == 0 and not EXPRESS_MODE then
        breakTime = 30
    end

    if msgTime >= breakTime then
        msgTime = breakTime - 0.5
    end

    Log:debug("Starting break time for " .. GetPlayerName(playerID).. " for wave "..wave)
    if ply then
        CustomGameEventManager:Send_ServerToPlayer( ply, "etd_update_wave_timer", { time = breakTime, button = (GameSettings:GetGamemode() ~= "Competitive") } )
    end

    ShowWaveBreakTimeMessage(playerID, wave, breakTime, msgTime)

    -- Update portal
    if hero:IsAlive() then
        local sector = playerData.sector + 1
        ShowPortalForSector(sector, wave, breakTime, playerID)
    end

    -- Grant Lumber and Essence to all players the moment the next wave is set
    if WaveGrantsLumber(wave-1) then
        ModifyLumber(playerID, 1)
        if GameSettings.elementsOrderName == "AllPick" and not playerData.elementalRandom then
            Log:info("Giving 1 lumber to " .. playerData.name)
        elseif playerData.elementalRandom or playerData.elementsOrder[playerData.completedWaves] then
            local element = nil
            if playerData.elementalRandom then
                element = GetRandomElementForWave(playerID, playerData.completedWaves)
            elseif playerData.elementsOrder[playerData.completedWaves] then
                element = playerData.elementsOrder[playerData.completedWaves]
            else
                print("Something horrible went wrong.")
            end

            if element == "pure" then
                SendEssenceMessage(playerID, "#etd_random_essence")
                ModifyPureEssence(playerID, 1)
                playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1

                -- Gold bonus for Pure Essence randoming
                GivePureEssenceGoldBonus(playerID)
            else
                SendEssenceMessage(playerID, "#etd_random_elemental")
                SummonElemental({caster = playerData.summoner, Elemental = element .. "_elemental"})
            end
        end
    end

    if WaveGrantsEssence(wave-1) then
        ModifyPureEssence(playerID, 1) 
        Log:info("Giving 1 pure essence to " .. playerData.name)
        playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
    end

    -- create the actual timer
    Timers:CreateTimer("SpawnWaveDelay"..playerID, {
        endTime = breakTime,

        callback = function()
            local data = GetPlayerData(playerID)

            if wave == WAVE_COUNT and not EXPRESS_MODE then
                Log:info("Spawning the first boss wave for ["..playerID.."] ".. playerData.name)
                playerData.bossWaves = playerData.bossWaves + 1
                ShowBossWaveMessage(playerID, playerData.bossWaves)
            else
                Log:info("Spawning wave " .. wave .. " for ["..playerID.."] ".. data.name)
                ShowWaveSpawnMessage(playerID, wave)
            end

            if wave == 1 then
                EmitAnnouncerSound("announcer_announcer_battle_begin_01")
            end

            -- update wave info
            UpdateWaveInfo(playerID, wave)

            -- spawn dat wave
            if hero:IsAlive() then
                SpawnWaveForPlayer(playerID, wave) 
            end
            WAVE_1_STARTED = true
        end
    })
end

function SpawnEntity(entityClass, playerID, position)
    local entity = CreateUnitByName(entityClass, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if entity then
        entity:AddNewModifier(nil, nil, "modifier_phased", {})
        entity:AddNewModifier(entity, nil, "modifier_damage_block", {})

        entity:SetDeathXP(0)
        entity.class = entityClass
        entity.playerID = playerID
        --Repurpose for game difficulty
        --ApplyArmorModifier(entity, GetPlayerDifficulty(playerID):GetArmorValue() * 100)

        -- create a script object for this entity
        -- see /vscripts/creeps/basic.lua
        local scriptClassName = GetUnitKeyValue(entityClass, "ScriptClass")
        if not scriptClassName or scriptClassName == "" then scriptClassName = "CreepBasic" end
        local scriptObject = CREEP_CLASSES[scriptClassName](entity, entityClass)
        CREEP_SCRIPT_OBJECTS[entity:entindex()] = scriptObject
        entity.scriptClass = scriptClassName
        entity.scriptObject = scriptObject

        -- tint this creep if keyvalue ModelColor is set
        local modelColor = GetUnitKeyValue(entityClass, "ModelColor")
        if modelColor then
            modelColor = split(modelColor, " ")
            entity:SetRenderColor(tonumber(modelColor[1]), tonumber(modelColor[2]), tonumber(modelColor[3]))
        end

        if GetUnitKeyValue(entityClass, "ParticleEffect") then
            local particle = ParticleManager:CreateParticle(GetUnitKeyValue(entityClass, "ParticleEffect"), 2, entity) 
            ParticleManager:SetParticleControlEnt(particle, 0, entity, 5, "attach_origin", entity:GetOrigin(), true)
        end

        -- Adjust slows multiplicatively
        entity:AddNewModifier(entity, nil, "modifier_slow_adjustment", {})

        -- Add to scoreboard count
        local playerData = GetPlayerData(playerID)
        playerData.remaining = playerData.remaining + 1
        UpdateScoreboard(playerID)

        return entity
    else
        Log:error("Attemped to create unknown creep type: " .. entityClass)
        return nil
    end
end

-- spawn the wave for the specified player
function SpawnWaveForPlayer(playerID, wave)
    local waveObj = Wave(playerID, wave)
    local playerData = GetPlayerData(playerID)
    local sector = playerData.sector + 1
    local startPos = EntityStartLocations[sector]
    local ply = PlayerResource:GetPlayer(playerID)

    playerData.waveObject = waveObj
    playerData.waveObjects[wave] = waveObj

    CustomGameEventManager:Send_ServerToAllClients("SetTopBarWaveValue", {playerId=playerID, wave=wave} )

    if not InterestManager:IsStarted() then
        InterestManager:StartInterestTimer()
    end

    waveObj:SetOnCompletedCallback(function()
        if playerData.health == 0 then
            return
        end

        playerData.completedWaves = playerData.completedWaves + 1
        print("Player [" .. playerID .. "] has completed wave "..playerData.completedWaves)
        if GameSettings:GetEndless() == "Normal" then
            playerData.nextWave = playerData.nextWave + 1
        end
        if ply then
            EmitSoundOnClient("ui.npe_objective_complete", ply)
        end

        -- Boss Wave completed starts the new one with no breaktime (unless its Endless)
        if playerData.completedWaves >= WAVE_COUNT and not EXPRESS_MODE and GameSettings:GetEndless() == "Normal" then
            print("Player [" .. playerID .. "] has completed a boss wave")
            playerData.bossWaves = playerData.bossWaves + 1
            Log:info("Spawning boss wave " .. playerData.bossWaves .. " for ["..playerID.."] ".. playerData.name)
            ShowBossWaveMessage(playerID, playerData.bossWaves)

            -- update wave info
            UpdateWaveInfo(playerID, wave)

            -- Boss wave score
            playerData.scoreObject:UpdateScore( SCORING_BOSS_WAVE_CLEAR, wave)

            SpawnWaveForPlayer(playerID, WAVE_COUNT) -- spawn the next boss wave
            return
        end

        -- For Endless
        if playerData.completedWaves >= WAVE_COUNT and not EXPRESS_MODE and GameSettings:GetEndless() == "Endless" then
            return
        end

        -- Cleared/completed game
        local finishedExpress = EXPRESS_MODE and playerData.completedWaves == WAVE_COUNT
        local clearedNormal = not EXPRESS_MODE and playerData.completedWaves == WAVE_COUNT - 1
        if finishedExpress or clearedNormal then
            playerData.scoreObject:UpdateScore( SCORING_GAME_CLEAR )

            if finishedExpress then
                Log:info("Player ["..playerID.."] has completed the game.")
                GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerData.name .. "</font> has completed the game!", 0, 0)
                playerData.duration = GameRules:GetGameTime() - START_GAME_TIME
                playerData.victory = 1
                ElementTD:CheckGameEnd()
                return
            end
        else
            playerData.scoreObject:UpdateScore( SCORING_WAVE_CLEAR, wave )
        end

        -- First player to finish the wave sets the next wave
        if playerData.completedWaves == CURRENT_WAVE then
            print("Player: " .. playerData.name .. " [" .. playerID .. "] is the first to complete wave " .. CURRENT_WAVE)

            if PlayerResource:GetPlayerCount() > 1 then
                local color = playerColors[sector-1]
                GameRules:SendCustomMessage("<font color='"..color.."'>"..playerData.name.."</font> is the first to complete Wave " .. CURRENT_WAVE, 0, 0)
            end

            -- Next wave
            CURRENT_WAVE = playerData.nextWave
            if GameSettings:GetGamemode() == "Competitive" and GameSettings:GetEndless() ~= "Endless" then
                CompetitiveNextRound(CURRENT_WAVE)
            end
        end

        if GameSettings:GetGamemode() ~= "Competitive" and GameSettings:GetEndless() ~= "Endless" then
            StartBreakTime(playerID, GetPlayerDifficulty(playerID):GetWaveBreakTime(playerData.nextWave))
        end

        playerData.waveObjects[waveObj.waveNumber] = nil
    end)
    waveObj:SpawnWave()
end

-- give 1 lumber every 5 waves or every 3 if express mode ignoring the last wave 55 and 30.
function WaveGrantsLumber( wave )
    if wave == 0 then return end
    if EXPRESS_MODE then
        return wave % 3 == 0 and wave < 30
    else
        return wave % 5 == 0 and wave < 55
    end
end

-- pure essence at waves 45/50 and 24/7 (express)
function WaveGrantsEssence( wave )
    if wave == 0 then return end
    if EXPRESS_MODE then
        return wave == 24 or wave == 27
    else
        return wave == 45 or wave == 50
    end
end

function ShowPortalForSector(sector, wave, time, playerID)
    local element = string.gsub(creepsKV[WAVE_CREEPS[wave]].Ability1, "_armor", "")
    local portal = SectorPortals[sector]
    local origin = portal:GetAbsOrigin()
    origin.z = origin.z - 200
    origin.y = origin.y - 70

    ClosePortalForSector(playerID, sector, true)

    local particleName = "particles/custom/portals/spiral.vpcf"
    portal.particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(portal.particle, 0, origin)
    ParticleManager:SetParticleControl(portal.particle, 15, GetElementColor(element))
    
    -- Portal World Notification
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "world_notification", {entityIndex=portal:GetEntityIndex(), text="#etd_wave_"..element} )
end

function ClosePortalForSector(playerID, sector, removeInstantly)
    removeInstantly = removeInstantly or false
    local portal = SectorPortals[sector]
    if portal.particle then
        ParticleManager:DestroyParticle(portal.particle, removeInstantly)
    end
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "world_remove_notification", {entityIndex=portal:GetEntityIndex()} )
end

function CreateMoveTimerForCreep(creep, sector)
    local destination = EntityEndLocations[sector]
    Timers:CreateTimer(0.1, function()
        if IsValidEntity(creep) then
            creep:MoveToPosition(destination)
            if (creep:GetOrigin() - destination):Length2D() <= 100 then
                local playerID = creep.playerID
                local playerData = GetPlayerData(playerID)
                
                ReduceLivesForPlayer(playerID)

                FindClearSpaceForUnit(creep, EntityStartLocations[playerData.sector + 1], true)
                creep:SetForwardVector(Vector(0, -1, 0))
            end
            return 0.1
        else
            return
        end
    end)
end

-- If the game mode is competitive spawn the next wave for all players after breaktime
function CompetitiveNextRound(wave)
    for _,v in pairs(playerIDs) do
        StartBreakTime(v, GetPlayerDifficulty(v):GetWaveBreakTime(wave))
    end
end

function ReduceLivesForPlayer( playerID )
    local playerData = GetPlayerData(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local ply = PlayerResource:GetPlayer(playerID)

    local lives = 1

    -- Boss Wave leaks = 3 lives
    if playerData.completedWaves + 1 >= WAVE_COUNT and not EXPRESS_MODE then
        lives = 3
    end

    -- Cheats can melt steel beams
    if GameRules.WhosYourDaddy then
        lives = 0
        return
    end

    if hero:GetHealth() <= lives and hero:GetHealth() > 0 then
        playerData.health = 0
        hero:ForceKill(false)
        if playerData.completedWaves + 1 >= WAVE_COUNT and not EXPRESS_MODE then
            playerData.scoreObject:UpdateScore( SCORING_GAME_FINISHED )
        else
            playerData.scoreObject:UpdateScore( SCORING_WAVE_LOST )
        end
        ElementTD:EndGameForPlayer(playerID) -- End the game for the dead player
    elseif hero:IsAlive() then
        playerData.health = playerData.health - lives
        playerData.waveObject.leaks = playerData.waveObject.leaks + lives
        if playerData.health < 50 then --When over 50 health, HP loss is covered by losing modifier_bonus_life
            hero:SetHealth(playerData.health)
        end
    end

    Sounds:EmitSoundOnClient(playerID, "ETD.Leak")
    hero:CalculateStatBonus()
    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
    UpdateScoreboard(playerID)
end