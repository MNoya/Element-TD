-- wavedata.lua
-- manages the spawning of creep waves

if not WAVE_CREEPS then
    WAVE_CREEPS = {}  -- array that stores the order that creeps spawn in. see /scripts/kv/waves.kv
    WAVE_HEALTH = {}  -- array that stores creep health values per wave.  see /scripts/kv/waves.kv
    --WAVE_ENTITIES_PLAYER = {}  -- array of entities based on playerIDs: e.g. WAVE_ENTITIES_PLAYER[playerID] is the array for that player's creeps
    --WAVE_ENTITIES = {} -- array of playerIDs based on entindexes: e.g. WAVE_ENTITIES[entindex] is the player this creep is assigned to
    CREEP_SCRIPT_OBJECTS = {}
    CREEPS_PER_WAVE = 30 -- the number of creeps to spawn in each wave
    WAVE_1_STARTED = false
    CURRENT_WAVE = 1
end

local kv = LoadKeyValues("scripts/kv/waves.kv")
creepsKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
WAVE_COUNT = kv["WaveCount"]

-- loads the creep and health data for each wave. Randomizes the creep order if 'chaos' is set to true
function loadWaveData(chaos)
    if EXPRESS_MODE then
        WAVE_COUNT = kv["WaveCountExpress"]
    end
    WAVE_CREEPS = {}
    WAVE_HEALTH = {}
    for k, v in pairs(kv) do
        if tonumber(k) and tonumber(k) <= WAVE_COUNT then
        	WAVE_CREEPS[tonumber(k)] = v.Creep
        	WAVE_HEALTH[tonumber(k)] = v.Health
        end
    end
    if chaos then
        local lastWaves = {}
        if not EXPRESS_MODE then
            for i = 55, 56, 1 do
                lastWaves[i] =  WAVE_CREEPS[i]
                WAVE_CREEPS[i] = nil
            end
        end
        WAVE_CREEPS = shuffle(WAVE_CREEPS)
        if not EXPRESS_MODE then
            for i = 55, 56, 1 do
                table.insert(WAVE_CREEPS, lastWaves[i])
            end
        end
    end
    PrintTable(WAVE_CREEPS)
end

-- starts the break timer for the specified player.
-- the next wave spawns once the break time is over
function StartBreakTime(playerID, breakTime)
    if not PlayerResource:GetPlayer(playerID):GetAssignedHero():IsAlive() then return end
    
    PlayerResource:GetPlayer(playerID):GetAssignedHero():RemoveModifierByName("modifier_silence")

    Log:debug("Starting break time for " .. GetPlayerName(playerID))

    -- let's figure out how long the break is
    local wave = GetPlayerData(playerID).nextWave
    local msgTime = 5 -- how long to show the message for
    if (wave - 1) % 5 == 0 and not EXPRESS_MODE then
        breakTime = 30
    end

    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_wave_timer", { time = breakTime } )

    if msgTime >= breakTime then
        msgTime = breakTime - 0.5
    end
    ShowMessage(playerID, "Wave "..wave.." in "..breakTime.." seconds", msgTime)

    -- create the actual timer
    Timers:CreateTimer("SpawnWaveDelay"..playerID, {
        endTime = breakTime,

        callback = function()
            local data = GetPlayerData(playerID)
            Log:info("Spawning wave " .. wave .. " for ["..playerID.."] ".. data.name)
            ShowMessage(playerID, "Wave " .. GetPlayerData(playerID).nextWave, 3)
            SpawnWaveForPlayer(playerID, wave) -- spawn dat wave
            WAVE_1_STARTED = true
        end
    })
end

function SpawnEntity(entityClass, playerID, position)
    local entity = CreateUnitByName(entityClass, position, true, nil, nil, DOTA_TEAM_NOTEAM)
    if entity then
        entity:AddNewModifier(nil, nil, "modifier_phased", {})
        GlobalCasterDummy:ApplyModifierToTarget(entity, "creep_damage_block_applier", "modifier_damage_block")
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

    playerData.waveObject = waveObj

    if (wave < WAVE_COUNT) then
        CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_next_wave_info", { nextWave=wave + 1, nextAbility1=creepsKV[WAVE_CREEPS[wave+1]].Ability1, nextAbility2=creepsKV[WAVE_CREEPS[wave+1]].Ability2 } )
    else
        CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_next_wave_info", { nextWave=0, nextAbility1="", nextAbility2="" } )
    end

    if not InterestManager:IsStarted() then
        InterestManager:StartInterestTimer()
    end

    waveObj:SetOnCompletedCallback(function()
        if playerData.health == 0 then
            return
        end
        print("Player has completed a wave")
        playerData.completedWaves = playerData.completedWaves + 1
        playerData.nextWave = playerData.nextWave + 1

        playerData.scoreObject:UpdateScore( SCORING_WAVE_CLEAR )

        if playerData.completedWaves >= WAVE_COUNT then
            playerData.scoreObject:UpdateScore( SCORING_GAME_CLEAR )
            Log:info("Player ["..playerID.."] has completed the game.")
            ElementTD:CheckGameEnd()
            return
        end

        if playerData.nextWave > CURRENT_WAVE then
            for _, ply in pairs(players) do
                StartBreakTime(ply:GetPlayerID(), GetPlayerDifficulty(playerID):GetWaveBreakTime(playerData.nextWave))
            end
            CURRENT_WAVE = playerData.nextWave
        end

        -- lumber
        if (playerData.completedWaves % 5 == 0 and playerData.completedWaves < 55 and not EXPRESS_MODE) or (playerData.completedWaves % 3 == 0 and playerData.completedWaves < 30 and EXPRESS_MODE) then
            ModifyLumber(playerID, 1) -- give 1 lumber every 5 waves or every 3 if express mode ignoring the last wave 55 and 30.
            if GameSettings.elementsOrderName == "AllPick" then
                Log:info("Giving 1 lumber to " .. playerData.name)
            elseif playerData.elementsOrder[playerData.completedWaves] then
                SummonElemental({caster = playerData.summoner, Elemental = playerData.elementsOrder[playerData.completedWaves] .. "_elemental"})
            end
        end

        -- pure essence
        if ((playerData.completedWaves == 46 or playerData.completedWaves == 51) and not EXPRESS_MODE) or ((playerData.completedWaves == 25 or playerData.completedWaves == 28) and EXPRESS_MODE) then
            ModifyPureEssence(playerID, 1) -- give 1 pure essence after wave 46 and 51 or 25 and 28 on express mode
            Log:info("Giving 1 pure essence to " .. playerData.name)
        end
    end)
    waveObj:SpawnWave()
    
    ----------------------------------------
    -- create thinker to sync fast creeps --
    if GetUnitKeyValue(WAVE_CREEPS[wave], "ScriptClass") == "CreepFast" then
        local player = PlayerResource:GetPlayer(playerID)
        local hero = player:GetAssignedHero()

        player:SetContextThink("HasteWaveThinker" .. wave, function()
            local creeps = playerData.waveObject.creeps
            for _, creep in pairs(creeps) do
                local unit = EntIndexToHScript(creep)
                if unit:GetUnitName() == WAVE_CREEPS[wave] and unit.playerID == playerID then
                    unit:CastAbilityImmediately(unit:FindAbilityByName("creep_ability_fast"), playerID)
                end
            end
            return 3
        end, 3)
    end
    ----------------------------
end

function CreateMoveTimerForCreep(creep, sector)
    local destination = EntityEndLocations[sector]
--    Timers:CreateTimer("MoveUnit"..creep:entindex(), {
--        callback = function()
--            ExecuteOrderFromTable({
--                UnitIndex = creep:entindex(),
--                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
--                Position = destination
--            })
--            if (creep:GetOrigin() - destination):Length2D() <= 150 then
--                local playerID = creep.playerID
--                local playerData = PlayerData[playerID]
--
--                local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
--
--                if hero:GetHealth() == 1 then
--                    playerData.health = 0
--                    hero:ForceKill(false)
--                    ElementTD:EndGameForPlayer(hero:GetPlayerID()) -- End the game for the dead player
--                elseif hero:IsAlive() then
--                    playerData.health = playerData.health - 1
--                    hero:SetHealth(hero:GetHealth() - 1)
--                end
--
--                FindClearSpaceForUnit(creep, EntityStartLocations[playerData.sector + 1], true) -- remove interp frames on client
--                --creep:SetAbsOrigin(EntityStartLocations[playerID + 1])
--                creep:SetForwardVector(Vector(0, -1, 0))
--            end
--            return 1
--        end
--    })

    creep:SetContextThink("MoveUnit" .. creep:entindex(), function()
        ExecuteOrderFromTable({
            UnitIndex = creep:entindex(),
            OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            Position = destination
        })
        if (creep:GetOrigin() - destination):Length2D() <= 150 then
            local playerID = creep.playerID
            local playerData = GetPlayerData(playerID)

            local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
            
            if hero:GetHealth() == 1 then
                playerData.health = 0
                hero:ForceKill(false)
                playerData.scoreObject:UpdateScore( SCORING_WAVE_LOST )
                ElementTD:EndGameForPlayer(hero:GetPlayerID()) -- End the game for the dead player
            elseif hero:IsAlive() then
                playerData.health = playerData.health - 1
                playerData.waveObject.leaks = playerData.waveObject.leaks + 1
                hero:SetHealth(hero:GetHealth() - 1)
            end

            FindClearSpaceForUnit(creep, EntityStartLocations[playerData.sector + 1], true) -- remove interp frames on client
            --creep:SetAbsOrigin(EntityStartLocations[playerID + 1])
            creep:SetForwardVector(Vector(0, -1, 0))
        end
        return 1
    end, 0)
end

-- waits for the wave to finish for the specified player
-- starts break time once the wave is over

--UNUSED
--[[
function WaitForWaveToFinish(playerID)
    CreateTimer("WaitForWaveToFinish"..playerID, INTERVAL, {
        loops = -1,
        interval = 1,
        playerID = playerID, 

        callback = function(timer)

            local count = 0
            for k, v in pairs(WAVE_ENTITIES_PLAYER[timer.playerID]) do
                count = count + 1
            end
            if count == 0 then
                local playerData = GetPlayerData(timer.playerID)
                PlayerResource:GetPlayer(playerID):SetContextThink("HasteWaveThinker" .. playerData.wave, nil, 0)
                Log:info("Wave " .. playerData.wave .. " has ended for " .. playerData.name)
                if playerData.wave >= WAVE_COUNT then
                    print("The game has ended for " .. playerData.name)
                else
                	if playerData.wave % 5 == 0 then
                		
                		ModifyLumber(timer.playerID, 1) -- give 1 lumber every 5 waves
                        if GameSettings.elementsOrderName == "AllPick" then
                			Log:info("Giving 1 lumber to " .. playerData.name)
                		elseif playerData.elementsOrder[playerData.wave] then
                			SummonElemental({caster = playerData.summoner, Elemental = playerData.elementsOrder[playerData.wave] .. "_elemental"})
                        end

                	end
                    playerData.wave = playerData.wave + 1
                    StartBreakTime(playerID)
                end
                DeleteTimer(timer.name)
            end

        end
    })
end
]]--