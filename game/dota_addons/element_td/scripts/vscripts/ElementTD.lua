-- Element Tower Defense
-- programmed by Vlad Marica (Quintinity)

players = {}
NPC_UNITS_CUSTOM = LoadKeyValues("scripts/npc/npc_units_custom.txt")
NPC_ABILITIES_CUSTOM = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
NPC_ITEMS_CUSTOM = LoadKeyValues("scripts/npc/npc_items_custom.txt")
ADDON_ENGLISH = LoadKeyValues("resource/addon_english.txt")

TEAM_TO_SECTOR = {}
TEAM_TO_SECTOR[2] = 0
TEAM_TO_SECTOR[3] = 1
TEAM_TO_SECTOR[6] = 2
TEAM_TO_SECTOR[7] = 3
TEAM_TO_SECTOR[8] = 4
TEAM_TO_SECTOR[9] = 5
TEAM_TO_SECTOR[10] = 6
TEAM_TO_SECTOR[11] = 7
 
GAME_IS_PAUSED = false
SKIP_VOTING = false -- assigns default game settings if true
DEV_MODE = false
EXPRESS_MODE = false

function ElementTD:InitGameMode()

    EntityUtils:Load()
    GenerateAllTowerGrids() -- create tower grids
    GenerateAllConstants() -- generate all constant tables

    self.availableSpawnIndex = 1 -- the index of the next available sector
    self.playersCount = 0
    self.gameStarted = false
    self.playerSpawnIndexes = {}

    self.gameStartTriggers = 1

    self.direPlayers = 0
    self.radiantPlayers = 0
    self.playerIDMap = {} --maps userIDs to playerID
    self.vPlayerIDToHero = {} -- Maps playerID to hero
    self.dummyCreated = false -- has the global caster dummy been initialized

    GameRules:SetHeroRespawnEnabled(false)
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetPostGameTime(30)
    GameRules:SetPreGameTime(0)
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetGoldPerTick(0)

    -- Setup Teams
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 1 )

    ListenToGameEvent('player_connect_full', Dynamic_Wrap(ElementTD, 'PlayerConnectedFull'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(ElementTD, 'EntityKilled'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(ElementTD, 'OnPlayerChat'), self)
    ListenToGameEvent('entity_hurt', Dynamic_Wrap(ElementTD, 'EntityHurt'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(ElementTD, 'OnUnitSpawned'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(ElementTD, 'OnGameStateChange'), self)

    ------------------------------------------------------
    local base_game_mode = GameRules:GetGameModeEntity()
    base_game_mode:SetRecommendedItemsDisabled(true) -- no recommended items panel
    base_game_mode:SetFogOfWarDisabled(true) -- no fog
    base_game_mode:SetCameraDistanceOverride(1500) -- move the camera higher up
    base_game_mode:SetCustomGameForceHero( "npc_dota_hero_wisp" ) -- Skip hero pick screen
    ------------------------------------------------------

    -- Allow cosmetic swapping
    SendToServerConsole( "dota_combine_models 0" )

    -- Don't end the game if everyone is unassigned
    SendToServerConsole("dota_surrender_on_disconnect 0")

    print("Loaded Element Tower Defense!")
end

function ElementTD:OnGameStateChange(keys)
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
        self.gameStartTriggers = self.gameStartTriggers + 1
        if self.gameStartTriggers < 2 then return end

        GameRules:SendCustomMessage("Welcome to <font color='#70EA72'>Element Tower Defense</font>!", 0, 0)
        
        self.gameStarted = true
        self:MoveHeroesToSpawns()
        self:StartGame()
    end
end

function ElementTD:PlayerConnectedFull(keys)
    local player = PlayerInstanceFromIndex(keys.index + 1)
    table.insert(players, player)
end

function ElementTD:OnPlayerChat(keys)
    PrintTable(keys)
    OnPlayerChatEvent(keys.text, self.playerIDMap[keys.userid])
end

-- move all heroes to their proper spawn locations
function ElementTD:MoveHeroesToSpawns()
    Timers:CreateTimer("MovePlayersToSpawn", {
        endTime = 1,
        callback = function()
            for k, ply in pairs(players) do
                local playerData = GetPlayerData(ply:GetPlayerID())
                if self.playerSpawnIndexes[ply:GetPlayerID()] then
                    local hero = ply:GetAssignedHero()

                    hero:SetAbsOrigin(SpawnLocations[self.playerSpawnIndexes[ply:GetPlayerID()]]) 

                    -- we must create the Elemental Summoner for this player
                    local sector = playerData.sector + 1
                    local summoner = CreateUnitByName("elemental_summoner", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber()) 
                    summoner:SetOwner(ply:GetAssignedHero())
                    summoner:SetControllableByPlayer(ply:GetPlayerID(), true)
                    summoner:SetAngles(0, 270, 0)

                    GetPlayerData(ply:GetPlayerID())["summoner"] = summoner
                    ModifyLumber(ply:GetPlayerID(), 0)  -- updates summoner spells
                    UpdatePlayerSpells(ply:GetPlayerID())
                end
            end
        end
    })
end

-- let's start the actual game
-- call this after the players have been move to their proper spawn locations
function ElementTD:StartGame()
        print("ElementTD Started!")
        Timers:CreateTimer("StartGameDelay", {
        endTime = 3,

        callback = function()
            Log:info("The game has started!")
            FireGameEvent("etd_game_started", {})
            
            if not SKIP_VOTING then
                FireGameEvent("etd_toggle_vote_dialog", {visible = true}) -- show that vote ui
                StartVoteTimer()
            else
                -- voting should never be skipped in real games
                if DEV_MODE then
                    GameSettings:SetGameLength("Developer")
                else
                    GameSettings:SetGameLength("Normal")
                end
                Log:info("Skipping voting")
                GameSettings:SetDifficulty("Normal")
                GameSettings:SetCreepOrder("Normal")
                for _, ply in pairs(players) do
                    StartBreakTime(ply:GetPlayerID()) -- begin the break time for wave 1 :D
                end
            end
        end
        })
end

function ElementTD:EndGameForPlayer( playerID )
    local playerData = GetPlayerData(playerID)
    Log:info("Player "..playerID.." has been defeated on wave "..playerData.nextWave..".")
    GameRules:SendCustomMessage(playerData.name.." has been defeated on wave "..playerData.nextWave..".", 0, 0)

    -- Clean up
    UpdatePlayerSpells(playerID)

    if playerData.elementalUnit ~= nil and not playerData.elementalUnit:IsNull() and playerData.elementalUnit:IsAlive() then
        print("Elemental Removed")
        playerData.elementalUnit:ForceKill(false)
    end
    for i,v in pairs(playerData.towers) do
        UTIL_RemoveImmediate(EntIndexToHScript(i))
    end
    for j,k in pairs(playerData.clones) do
        UTIL_RemoveImmediate(EntIndexToHScript(j))
    end
    for l,m in pairs(playerData.waveObject.creeps) do
        EntIndexToHScript(l):ForceKill(false)
    end
    ElementTD:CheckGameEnd()
end

-- Check if all players are dead or have completed all the waves so we can end the game
function ElementTD:CheckGameEnd()
    local endGame = true
    for k, ply in pairs(players) do
        local playerData = GetPlayerData(ply:GetPlayerID())
        if playerData.health ~= 0 or playerData.completedWaves < WAVE_COUNT then
            endGame = false
        end
    end
    if endGame then
        Log:info("Game end condition reached.")
        GameRules:SendCustomMessage("Thank you for playing <font color='#70EA72'>Element Tower Defense</font>!", 0, 0)

        GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
        GameRules:SetSafeToLeave( true )
    end
end

function ElementTD:OnUnitSpawned(keys)
    local unit = EntIndexToHScript(keys.entindex)
    EntityUtils:Fix(unit)

    if unit:IsRealHero() then
        local playerID = unit:GetPlayerOwnerID()
        local player = PlayerResource:GetPlayer(playerID)
        CreateDataForPlayer(playerID)

        if playerID >= 0 then
            if not self.dummyCreated then
                GlobalCasterDummy:Init()
                self.dummyCreated = true
            end
            local playerData = GetPlayerData(playerID)
            playerData.name = PlayerResource:GetPlayerName(playerID)
            self:InitializeHero(player:GetPlayerID(), unit)
            self.playerSpawnIndexes[player:GetPlayerID()] = playerData.sector + 1
            self.availableSpawnIndex = self.availableSpawnIndex + 1
        end
    end
end

-- initializes a player's hero
function ElementTD:InitializeHero(playerID, hero)
    print("OnInitHero PID:"..playerID)
    hero:AddNewModifier(nil, nil, "modifier_disarmed", {})
    GlobalCasterDummy:ApplyModifierToTarget(hero, "player_movespeed_applier", "modifier_base_movespeed")
    hero:SetAbilityPoints(0)
    hero:SetMaxHealth(50)
    hero:SetHealth(50)
    hero:SetBaseDamageMin(0)
    hero:SetBaseDamageMax(0)
    hero:SetBaseHealthRegen(-0.03) -- we need to counteract base regen that 1 strength give you. volvo pls.
    hero:SetGold(0, false)
    hero:SetGold(70, true)
    hero:SetModelScale(0.75)
    hero:AddNewModifier(nil, nil, "modifier_silence", {}) -- silence this player until break time is started

    self.vPlayerIDToHero[playerID] = hero -- Store hero for player in here GetAssignedHero can be flakey

    local playerData = GetPlayerData(playerID)
    local spells = SpellPages[playerData.page]
    playerData.spells = {}

    playerData.sector = TEAM_TO_SECTOR[hero:GetTeamNumber()]

    for k, name in pairs(spells) do
        hero:AddAbility(name)
        hero:FindAbilityByName(name):SetLevel(1)
    end
    CreatePhantomUnitManager(hero:GetPlayerID())
    UpdatePlayerSpells(playerID)
end

function ElementTD:EntityKilled(keys)
    local index = keys.entindex_killed
    local entity = EntIndexToHScript(index)
    local playerData = GetPlayerData(entity.playerID)

    if entity.scriptObject and entity.scriptObject.OnDeath then
        entity.scriptObject:OnDeath()
    end

    if entity.isElemental then
        -- an elemental was killed :O
        Timers:RemoveTimer("MoveElemental"..index)
        Log:info(playerData.name .. " has killed a " .. entity.element .. " elemental")
        playerData.elementalActive = false
        playerData.elementalUnit = nil
        ModifyElementValue(entity.playerID, entity.element, 1)
    else
        local playerID = entity.playerID
        if entity.waveObject then 
            entity.waveObject:OnCreepKilled(index)
        end
        CREEP_SCRIPT_OBJECTS[index] = nil
        --for towerID,_ in pairs(GetPlayerData(pID).towers) do
            --UpdateUpgrades(EntIndexToHScript(towerID))
        --end
        UpdatePlayerSpells(playerID)
        Timers:RemoveTimer("MoveUnit"..index)
    end
end

function ElementTD:EntityHurt(keys)
    local entity = EntIndexToHScript(keys.entindex_killed)
    local attacker = nil
    if keys.entindex_attacker then
        attacker = EntIndexToHScript(keys.entindex_attacker)
    end


    if entity and attacker then
        if attacker.dummyParent then
            local tower = attacker.dummyParent

            if tower.scriptClass == "ElectricityTower" then -- handle electricity tower chain lightning damage
                tower.scriptObject:OnLightningHitEntity(entity)
            end
        end
    end

end

--called every 0.1 seconds
function ElementTD:Think()
    -- DEPRECIATED
end

-- helper function
function GetUnitKeyValue(unitName, key)
    if NPC_UNITS_CUSTOM[unitName] then
        if not NPC_UNITS_CUSTOM[unitName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. unitName)
        end
        return NPC_UNITS_CUSTOM[unitName][key]
    else
        --Log:warn("Unknown unit type: " .. tostring(unitName) .. " [Key: " .. key .. "]")
        return nil
    end
end

-- helper function
function GetAbilityKeyValue(abilityName, key)
    if NPC_ABILITIES_CUSTOM[abilityName] then
        if not NPC_ABILITIES_CUSTOM[abilityName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. abilityName)
        end
        return NPC_ABILITIES_CUSTOM[abilityName][key]
    else
        --Log:warn("Unknown ability: " .. tostring(abilityName) .. " [Key: " .. key .. "]")
        return nil
    end
end

function GetEnglishTranslation(key)
    return ADDON_ENGLISH.Tokens[key]
end

-- helper function
function GetItemKeyValue(itemName, key)
    if NPC_ITEMS_CUSTOM[itemName] then
        if not NPC_ITEMS_CUSTOM[itemName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. itemName)
        end
        return NPC_ITEMS_CUSTOM[itemName][key]
    else
        Log:warn("Unknown item: " .. tostring(itemName) .. " [Key: " .. key .. "]")
        return nil
    end
end

--helper function
function GetAbilitySpecialValue(abilityName, specialValue)
    if NPC_ABILITIES_CUSTOM[abilityName] then
        local kv = NPC_ABILITIES_CUSTOM[abilityName]
        if kv.AbilitySpecial then
            for k, v in pairs(kv.AbilitySpecial) do
                if v[specialValue] then
                    local result = nil
                    if string.find(v[specialValue], " ") then -- is this value an array?
                        result = split(v[specialValue], " ")
                        for k2, v2 in pairs(result) do
                            result[k2] = tonumber(v2)
                        end
                    else
                        result = tonumber(v[specialValue])
                    end
                    return result
                end
            end
        end
        return nil
    else
        Log:warn("Unknown ability: " .. tostring(abilityName) .. " [SpecialValue: " .. specialValue .. "]")
        return nil
    end
end