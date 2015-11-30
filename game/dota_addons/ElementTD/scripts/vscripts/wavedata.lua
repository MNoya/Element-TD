-- wavedata.lua
-- manages the spawning of creep waves

WAVE_CREEPS = {};  -- array that stores the order that creeps spawn in. see /scripts/kv/waves.kv
WAVE_HEALTH = {};  -- array that stores creep health values per wave.  see /scripts/kv/waves.kv
--WAVE_ENTITIES_PLAYER = {};  -- array of entities based on playerIDs: e.g. WAVE_ENTITIES_PLAYER[playerID] is the array for that player's creeps
--WAVE_ENTITIES = {}; -- array of playerIDs based on entindexes: e.g. WAVE_ENTITIES[entindex] is the player this creep is assigned to
CREEP_SCRIPT_OBJECTS = {};
CREEPS_PER_WAVE = 30; -- the number of creeps to spawn in each wave
WAVE_1_STARTED = false;
CURRENT_WAVE = 1;

local kv = LoadKeyValues("scripts/kv/waves.kv");
local creepsKV = LoadKeyValues("scripts/kv/creeps.kv");
WAVE_COUNT = kv["WaveCount"];

-- loads the creep and health data for each wave. Randomizes the creep order if 'chaos' is set to true
function loadWaveData(chaos) 
    WAVE_CREEPS = {};
    WAVE_HEALTH = {};
    for k, v in pairs(kv) do
    	if tonumber(k) then
    		WAVE_CREEPS[tonumber(k)] = v.Creep;
    		WAVE_HEALTH[tonumber(k)] = v.Health;
    	end
    end
    if chaos then 
        local first5Waves = {};
        for i = 1, 5, 1 do
            first5Waves[i] =  WAVE_CREEPS[i];
            WAVE_CREEPS[i] = nil;
        end
        WAVE_CREEPS = shuffle(WAVE_CREEPS); 
        for i = 5, 1, -1 do
            table.insert(WAVE_CREEPS, 1, first5Waves[i]);
        end 
    end
end

-- starts the break timer for the specified player.
-- the next wave spawns once the break time is over
function StartBreakTime(playerID, breakTime)
    if not PlayerResource:GetPlayer(playerID):GetAssignedHero():IsAlive() then return end
    
    PlayerResource:GetPlayer(playerID):GetAssignedHero():RemoveModifierByName("modifier_silence");

    Log:debug("Starting break time for " .. GetPlayerName(playerID));

    -- let's figure out how long the break is
    local wave = GetPlayerData(playerID).nextWave;
    local msgTime = 5; -- how long to show the message for
    if (wave - 1) % 5 == 0 then
        breakTime = 30;
    end

    FireGameEvent("etd_update_wave_timer", {playerID = playerID, time = breakTime});

    if msgTime >= breakTime then
        msgTime = breakTime - 0.5;
    end
    ShowMessage(playerID, "Wave "..wave.." in "..breakTime.." seconds", msgTime);

    -- create the actual timer
    CreateTimer("SpawnWaveDelay"..playerID, DURATION, {
        duration = breakTime,
        playerID = playerID, 

        callback = function(t)
            local data = GetPlayerData(t.playerID);
            Log:info("Spawning wave " .. wave .. " for ["..t.playerID.."] ".. data.name);
            ShowMessage(playerID, "Wave " .. GetPlayerData(playerID).nextWave, 3);
            SpawnWaveForPlayer(t.playerID, wave); -- spawn dat wave
            WAVE_1_STARTED = true;
        end
    });
end

function SpawnEntity(entityClass, playerID, position)
    local entity = CreateUnitByName(entityClass, position, true, nil, nil, DOTA_TEAM_NOTEAM);
    if entity then
        entity:AddNewModifier(nil, nil, "modifier_phased", {});
        GlobalCasterDummy:ApplyModifierToTarget(entity, "creep_damage_block_applier", "modifier_damage_block");
        entity:SetDeathXP(0);
        entity.class = entityClass;
        entity.playerID = playerID;
        ApplyArmorModifier(entity, GetPlayerDifficulty(playerID):GetArmorValue() * 100);

        -- create a script object for this entity
        -- see /vscripts/creeps/basic.lua
        local scriptClassName = GetUnitKeyValue(entityClass, "ScriptClass");
        if not scriptClassName or scriptClassName == "" then scriptClassName = "CreepBasic"; end
        local scriptObject = CREEP_CLASSES[scriptClassName](entity, entityClass);
        CREEP_SCRIPT_OBJECTS[entity:entindex()] = scriptObject;
        entity.scriptClass = scriptClassName;
        entity.scriptObject = scriptObject;

        -- tint this creep if keyvalue ModelColor is set
        local modelColor = GetUnitKeyValue(entityClass, "ModelColor");
        if modelColor then
            modelColor = split(modelColor, " ");
            entity:SetRenderColor(tonumber(modelColor[1]), tonumber(modelColor[2]), tonumber(modelColor[3]));
        end

        if GetUnitKeyValue(entityClass, "ParticleEffect") then
            local particle = ParticleManager:CreateParticle(GetUnitKeyValue(entityClass, "ParticleEffect"), 2, entity); 
            ParticleManager:SetParticleControlEnt(particle, 0, entity, 5, "attach_origin", entity:GetOrigin(), true);
        end
        return entity;
    else
        Log:error("Attemped to create unknown creep type: " .. entityClass);
        return nil;
    end
end

-- spawn the wave for the specified player
function SpawnWaveForPlayer(playerID, wave)
    local waveObj = Wave(playerID, wave);
    local sector = playerID + 1;
    local startPos = EntityStartLocations[sector];
    local playerData = GetPlayerData(playerID);
    playerData.waveObject = waveObj;

    FireGameEvent("etd_update_wave_info", {playerID = playerID, nextWave = wave + 1, nextWaveCreep = WAVE_CREEPS[wave + 1]});

    if not InterestManager:IsStarted() then
        InterestManager:StartInterestTimer();
    end

    waveObj:SetOnCompletedCallback(function() 
        print("Player has completed a wave");
        playerData.completedWaves = playerData.completedWaves + 1;
        playerData.nextWave = playerData.nextWave + 1;

        if playerData.completedWaves >= WAVE_COUNT then
            Log:info("Player ["..playerData.playerID.."] has completed the game.");
            ElementTD:CheckGameEnd();
            return
        end

        if playerData.nextWave > CURRENT_WAVE then
            for _, ply in pairs(players) do
                StartBreakTime(ply:GetPlayerID(), GetPlayerDifficulty(playerID):GetWaveBreakTime(playerData.nextWave));
            end
            CURRENT_WAVE = playerData.nextWave;
        end

        if playerData.completedWaves % 5 == 0 then
            ModifyLumber(playerID, 1); -- give 1 lumber every 5 waves
            if GameSettings.elementsOrderName == "AllPick" then
                Log:info("Giving 1 lumber to " .. playerData.name);
            elseif playerData.elementsOrder[playerData.completedWaves] then
                SummonElemental({caster = playerData.summoner, Elemental = playerData.elementsOrder[playerData.completedWaves] .. "_elemental"});
            end
        end
    end);
    waveObj:SpawnWave();
    
    ----------------------------------------
    -- create thinker to sync fast creeps --
    if GetUnitKeyValue(WAVE_CREEPS[wave], "ScriptClass") == "CreepFast" then
        local player = PlayerResource:GetPlayer(playerID);
        local hero = player:GetAssignedHero();

        player:SetContextThink("HasteWaveThinker" .. wave, function()
            local creeps = GetCreepsInArea(hero:GetOrigin(), 10000);
            for _, creep in pairs(creeps) do
                if creep:GetUnitName() == WAVE_CREEPS[wave] and creep.playerID == playerID then
                    creep:CastAbilityImmediately(creep:FindAbilityByName("creep_ability_fast"), playerID);
                end
            end
            return 4 + math.random(3, 10);
        end, math.random(3, 10));
        
    end
    ----------------------------
end

function CreateMoveTimerForCreep(creep, sector)
    local destination = EntityEndLocations[sector];
    creep:SetContextThink("MoveUnit" .. creep:entindex(), function()
        ExecuteOrderFromTable({
            UnitIndex = creep:entindex(),
            OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            Position = destination
        });
        if (creep:GetOrigin() - destination):Length2D() <= 150 then
            local playerID = creep.playerID;
            local playerData = PlayerData[playerID];

            local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero();
            
            if hero:GetHealth() == 1 then
                playerData.health = 0;
                hero:ForceKill(false);
                ElementTD:EndGameForPlayer(hero:GetPlayerID()); -- End the game for the dead player
            elseif hero:IsAlive() then
                playerData.health = playerData.health - 1;
                hero:SetHealth(hero:GetHealth() - 1);
            end

            FindClearSpaceForUnit(creep, EntityStartLocations[playerID + 1], true) -- remove interp frames on client
            --creep:SetAbsOrigin(EntityStartLocations[playerID + 1]);
            creep:SetForwardVector(Vector(0, -1, 0));
        end
        return 1;
    end, 0);
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

            local count = 0;
            for k, v in pairs(WAVE_ENTITIES_PLAYER[timer.playerID]) do
                count = count + 1;
            end
            if count == 0 then
                local playerData = GetPlayerData(timer.playerID);
                PlayerResource:GetPlayer(playerID):SetContextThink("HasteWaveThinker" .. playerData.wave, nil, 0);
                Log:info("Wave " .. playerData.wave .. " has ended for " .. playerData.name);
                if playerData.wave >= WAVE_COUNT then
                    print("The game has ended for " .. playerData.name);
                else
                	if playerData.wave % 5 == 0 then
                		
                		ModifyLumber(timer.playerID, 1); -- give 1 lumber every 5 waves
                        if GameSettings.elementsOrderName == "AllPick" then
                			Log:info("Giving 1 lumber to " .. playerData.name);
                		elseif playerData.elementsOrder[playerData.wave] then
                			SummonElemental({caster = playerData.summoner, Elemental = playerData.elementsOrder[playerData.wave] .. "_elemental"});
                        end

                	end
                    playerData.wave = playerData.wave + 1;
                    StartBreakTime(playerID);
                end
                DeleteTimer(timer.name);
            end

        end
    });
end
]]--