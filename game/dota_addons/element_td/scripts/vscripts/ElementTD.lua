if not players then
    players = {}
    playerIDs = {}

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

    VERSION = "1.1"

    START_TIME = GetSystemDate() .. " " .. GetSystemTime()
    END_TIME = nil

    START_GAME_TIME = 0
end

function ElementTD:InitGameMode()
    GenerateAllConstants() -- generate all constant tables

    self.availableSpawnIndex = 1 -- the index of the next available sector
    self.playersCount = 0
    self.gameStarted = false
    self.playerSpawnIndexes = {}

    self.gameStartTriggers = 1

    self.direPlayers = 0
    self.radiantPlayers = 0
    self.vUserIds = {}
    self.vPlayerUserIds = {}
    self.playerIDMap = {} --maps userIDs to playerID
    self.vPlayerIDToHero = {} -- Maps playerID to hero

    GameRules:SetHeroRespawnEnabled(false)
    GameRules:SetSameHeroSelectionEnabled(true)
    GameRules:SetPostGameTime(100)
    GameRules:SetPreGameTime(0)
    GameRules:SetHeroSelectionTime(0)
    GameRules:SetGoldPerTick(0)
    GameRules:GetGameModeEntity():SetGoldSoundDisabled(true)
    GameRules:GetGameModeEntity():SetAnnouncerDisabled(true)
    GameRules:GetGameModeEntity():SetHUDVisible(DOTA_HUD_VISIBILITY_TOP_SCOREBOARD, false)

    -- Setup Teams
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 1 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 1 )

    -- Event Hooks
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(ElementTD, 'OnConnectFull'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(ElementTD, 'OnEntityKilled'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(ElementTD, 'OnPlayerChat'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(ElementTD, 'OnUnitSpawned'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(ElementTD, 'OnGameStateChange'), self)

    -- Register Listener
    CustomGameEventManager:RegisterListener( "update_selected_entities", Dynamic_Wrap(ElementTD, 'OnPlayerSelectedEntities'))
    GameRules.SELECTED_UNITS = {}

    -- Filters
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( ElementTD, "FilterExecuteOrder" ), self )
    GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( ElementTD, "DamageFilter" ), self )
    GameRules:GetGameModeEntity():SetTrackingProjectileFilter( Dynamic_Wrap( ElementTD, "FilterProjectile" ), self )

    -- Lua Modifiers
    LinkLuaModifier("modifier_attack_targeting", "towers/modifier_attack_targeting", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_kill_count", "towers/modifier_kill_count", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_slow_adjustment", "towers/modifier_slow_adjustment", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("creep_haste_modifier", "creeps/creep_haste_modifier", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_vengeance_debuff", "creeps/modifier_vengeance_debuff", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_vengeance_multiple", "creeps/modifier_vengeance_debuff", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_stunned", "libraries/modifiers/modifier_stunned", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_invisible_etd", "libraries/modifiers/modifier_invisible_etd", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_no_health_bar", "libraries/modifiers/modifier_no_health_bar", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_transparency", "libraries/modifiers/modifier_transparency.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_disabled", "libraries/modifiers/modifier_disabled", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_attack_disabled", "libraries/modifiers/modifier_attack_disabled", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_support_tower", "libraries/modifiers/modifier_support_tower", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_bonus_life", "libraries/modifiers/modifier_bonus_life", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_health_bar_markers", "libraries/modifiers/modifier_health_bar_markers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_not_on_minimap_for_enemies", "libraries/modifiers/modifier_not_on_minimap_for_enemies", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_max_ms", "libraries/modifiers/modifier_max_ms", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_attack_immune", "libraries/modifiers/modifier_attack_immune", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_client_convars", "libraries/modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
    
    -- Register UI Listener   
    CustomGameEventManager:RegisterListener( "next_wave", Dynamic_Wrap(ElementTD, "OnNextWave")) -- wave info
    CustomGameEventManager:RegisterListener( "etd_player_voted", Dynamic_Wrap(ElementTD, "OnPlayerVoted")) -- voting ui

    ------------------------------------------------------
    local base_game_mode = GameRules:GetGameModeEntity()
    base_game_mode:SetRecommendedItemsDisabled(true) -- no recommended items panel
    base_game_mode:SetFogOfWarDisabled(true) -- no fog
    base_game_mode:SetBuybackEnabled( false )
    base_game_mode:SetCustomGameForceHero( "npc_dota_hero_wisp" ) -- Skip hero pick screen
    ------------------------------------------------------

    -- Allow cosmetic particle rendering
    SendToServerConsole("dota_combine_models 1")

    -- Don't end the game if everyone is unassigned
    SendToServerConsole("dota_surrender_on_disconnect 0")

    -- Increase time to load and start even if not all players loaded
    SendToServerConsole("dota_wait_for_players_to_load_timeout 240")

    -- Less expensive pathing?
    LimitPathingSearchDepth(0.5)

    -- Version Label
    CustomNetTables:SetTableValue("gameinfo", "version", {value=VERSION})

    print("Loaded Element Tower Defense!")
end

-- called when 'script_reload' is run
-- TODO: make with work with the :OnCreated function
function ElementTD:OnScriptReload()
    -- Reload files
    NPC_UNITS_CUSTOM = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    NPC_ABILITIES_CUSTOM = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
    NPC_ITEMS_CUSTOM = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    ADDON_ENGLISH = LoadKeyValues("resource/addon_english.txt")
    
    for _, playerID in pairs(playerIDs) do

        -- loop over the player's towers
        for towerID, _ in pairs(GetPlayerData(playerID).towers) do
            local tower = EntIndexToHScript(towerID)
            if IsValidEntity(tower) and tower.scriptObject then
                local scriptObject = getmetatable(tower.scriptObject).__index

                -- replace the old functions in the script objects with the new ones
                for name, value in pairs(TOWER_CLASSES[tower.scriptClass]) do
                    if type(value) == "function" then
                        scriptObject[name] = value
                    end
                end
            end
        end

    end
end

function ElementTD:OnGameStateChange(keys)
    local state = GameRules:State_Get()
    if state == DOTA_GAMERULES_STATE_HERO_SELECTION then
        self.gameStartTriggers = self.gameStartTriggers + 1
        if self.gameStartTriggers < 2 then return end

        GameRules:SendCustomMessage("#etd_welcome_message", 0, 0)
        
        self.gameStarted = true

        self:StartGame()
    elseif state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then

        -- Load donation rewards
        Rewards:Load()
    end
end

-- let's start the actual game
-- call this after the players have been move to their proper spawn locations
function ElementTD:StartGame()
    print("ElementTD Started!")

    Timers:CreateTimer(1, function()
        Log:info("The game has started!")

        if not SKIP_VOTING then
            CustomGameEventManager:Send_ServerToAllClients( "etd_toggle_vote_dialog", {visible = true} )
            StartVoteTimer()
            EmitAnnouncerSound("announcer_announcer_battle_prepare_01")

            if GameRules:IsCheatMode() then
                ElementTD:CheatsEnabled()
            end
        else
            -- voting should never be skipped in real games
            START_GAME_TIME = GameRules:GetGameTime()
            if DEV_MODE then
                GameSettings:SetGameLength("Developer")
            else
                GameSettings:SetGameLength("Normal")
            end
            Log:info("Skipping voting")
            GameSettings:SetDifficulty("Normal")
            GameSettings:SetCreepOrder("Normal")
            for _, ply in pairs(playerIDs) do
                StartBreakTime(ply) -- begin the break time for wave 1 :D
            end
        end
    end)
end

function ElementTD:OnNextWave( keys )
    local playerID = keys.PlayerID
    local data = GetPlayerData(playerID)
    if GameSettings:GetGamemode() == "Competitive" and (PlayerResource:GetPlayerCount() > 1 or data.nextWave > 1) then
        return
    end

    if (data.waveObject and data.waveObject.creepsRemaining == 0) or data.nextWave == 1 or GameSettings:GetEndless() == "Endless" then
        Timers:RemoveTimer("SpawnWaveDelay"..playerID)
        Log:info("Spawning wave " .. data.nextWave .. " for ["..playerID.."] ".. data.name)
        ShowWaveSpawnMessage(playerID, data.nextWave)

        UpdateWaveInfo(playerID, data.nextWave) -- update wave info
        SpawnWaveForPlayer(playerID, data.nextWave) -- spawn dat wave
    end
end

function ElementTD:EndGameForPlayer( playerID )
    -- Remove the hero top left ui element
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    hero:RemoveAbility("hero_ui")

    local playerData = GetPlayerData(playerID)
    local ply = PlayerResource:GetPlayer(playerID)

    if playerData.completedWaves + 1 >= WAVE_COUNT and not EXPRESS_MODE then
        Log:info("Player "..playerID.." has been defeated on the boss Wave "..playerData.bossWaves..".")
        playerData.victory = 1
        GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerData.name.."</font> has completed the game with "..playerData.iceFrogKills.." Icefrog kills!", 0, 0)
    else
        Log:info("Player "..playerID.." has been defeated on Wave "..playerData.nextWave..".")
        GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerData.name.."</font> has been defeated on Wave "..playerData.nextWave.."!", 0, 0)
    end

    -- Clean up
    UpdatePlayerSpells(playerID)
    RemoveElementalOrbs(playerID)
    ClosePortalForSector(playerID, playerData.sector+1, true)

    playerData.networth = GetPlayerNetworth( playerID )
    playerData.duration = GameRules:GetGameTime() - START_GAME_TIME
    playerData.tow = tablelength(playerData.towers)

    if playerData.elementalUnit ~= nil and IsValidEntity(playerData.elementalUnit) and playerData.elementalUnit:IsAlive() then
        playerData.elementalUnit:ForceKill(false)
    end
    for i,v in pairs(playerData.towers) do
        EntIndexToHScript(i):ForceKill(false)
    end
    if (playerData.waveObject and playerData.waveObject.creeps) then
        for l,m in pairs(playerData.waveObject.creeps) do
            EntIndexToHScript(l):ForceKill(false)
        end
    end
    for _,object in pairs(playerData.waveObjects) do
        for index,_ in pairs(object.creeps) do
            local creep = EntIndexToHScript(index)
            if IsValidEntity(creep) then
                creep:ForceKill(false)
            end
        end
    end
    UTIL_Remove(playerData.summoner.icon)

    for i=0,15 do
        local ability = playerData.summoner:GetAbilityByIndex(i)
        if ability then
            ability:SetHidden(true)
        end
    end

    for i=0,5 do
        local item = playerData.summoner:GetItemInSlot(i)
        if item then
            item:RemoveSelf()
        end
    end
    
    playerData.remaining = nil
    UpdateScoreboard(playerID, EXPRESS_MODE)

    --EmitAnnouncerSound(defeatAnnouncer[playerData.sector])    
    EmitGlobalSound("ETD.PlayerLost")

    -- Stop player interest
    if ply then
        CustomGameEventManager:Send_ServerToPlayer( ply, "etd_display_interest", { interval=INTEREST_INTERVAL, rate=INTEREST_RATE, enabled=false } )
    end

    ElementTD:CheckGameEnd()
end

-- Check if all players are dead or have completed all the waves so we can end the game
function ElementTD:CheckGameEnd()
    print("Check Game End, PlayerID count: "..#playerIDs)

    for k, ply in pairs(playerIDs) do
        local playerData = GetPlayerData(ply)
        print('Player '..ply..' is at '..playerData.health..' health and has completed '..playerData.completedWaves..' waves')

        -- If theres a player still alive
        if playerData.health ~= 0 then

            -- In Express mode, the game could end with a player still alive
            if EXPRESS_MODE then
                if playerData.completedWaves < WAVE_COUNT then
                    print("Express - Players are still alive and havent finished the game")
                    return
                end
            else
                print("Players are still alive")
                return
            end
        end
    end

    print("Game End Condition met. Determining a winner...")
    local teamWinner = DOTA_TEAM_NEUTRALS
    if #playerIDs == 1 then
        for k, ply in pairs(playerIDs) do
            local hero = self.vPlayerIDToHero[ply]
            local playerData = GetPlayerData(ply)
            
            -- Lost
            local bExpressDefeat = EXPRESS_MODE and playerData.health == 0 --Must stay alive until the end
            local bClassicDefeat = not EXPRESS_MODE and (playerData.completedWaves < WAVE_COUNT-1) --Must complete up to 1 wave before the boss
            if bExpressDefeat or bClassicDefeat then
                print("Single Player Defeat")
            
            -- Win
            else
                teamWinner = hero:GetTeamNumber()
                print("Single Player Victory!")
            end
        end
    else
        print("Multiple players checking for winner")
        -- Wave > Difficulty > Score
        local winnerId = -1
        local compareWave = 0
        local compareScore = 0
        local compareDifficulty = "Normal"
        for k, ply in pairs(playerIDs) do
            local playerData = GetPlayerData(ply)
            if playerData.completedWaves > compareWave then
                winnerId = ply
                compareWave = playerData.completedWaves
                compareScore = playerData.scoreObject.totalScore
                compareDifficulty = playerData.difficulty.difficultyName
            elseif playerData.completedWaves == compareWave then
                if playerData.difficulty.difficultyName == compareDifficulty then
                    if playerData.scoreObject.totalScore >  compareScore then
                        winnerId = ply
                        compareWave = playerData.completedWaves
                        compareScore = playerData.scoreObject.totalScore
                        compareDifficulty = playerData.difficulty.difficultyName
                    end
                else
                    local diff = playerData.difficulty.difficultyName
                    if diff == "Insane" or (diff == "VeryHard" and (compareDifficulty == "Hard" or compareDifficulty == "Normal")) or (diff == "Hard" and compareDifficulty == "Normal") then
                        winnerId = ply
                        compareWave = playerData.completedWaves
                        compareScore = playerData.scoreObject.totalScore
                        compareDifficulty = playerData.difficulty.difficultyName
                    end
                end
            end
        end
        if winnerId ~= -1 then
            teamWinner = self.vPlayerIDToHero[winnerId]:GetTeamNumber()
        end
    end

    END_TIME = GetSystemDate() .. " " .. GetSystemTime()
    Log:info("Ending game in 5 seconds.")
    if teamWinner == DOTA_TEAM_NEUTRALS then
        GameRules:SendCustomMessage("#etd_end_message_defeat", 0, 0)
    end    
    GameRules:SendCustomMessage("#etd_end_message", 0, 0)
    Timers:CreateTimer(5, function()

        -- Try to revert client convars
        for _, playerID in pairs(playerIDs) do
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                hero:RemoveModifierByName("modifier_client_convars")
            end
        end

        GameRules:SetGameWinner( teamWinner )
        GameRules:SetSafeToLeave( true )
    end)
end

function ElementTD:OnUnitSpawned(keys)
    local unit = EntIndexToHScript(keys.entindex)

    if unit:IsRealHero() then
        local hero = unit
        local playerID = hero:GetPlayerID()

        -- Should we change to an alternate builder?
        if Rewards:PlayerHasCosmeticModel(playerID) and hero:GetUnitName() == "npc_dota_hero_wisp" then
            Timers:CreateTimer(0.03, function()
                Rewards:HandleHeroReplacement(hero)
            end)
        else 
            ElementTD:OnHeroInGame(hero)
        end
    else
        local unitName = unit:GetUnitName()
        if unitName and unitName ~= "" and not NPC_UNITS_CUSTOM[unitName] then
            Log:warn("A non-custom unit was spawned! "..unitName)
            unit:RemoveSelf()
        end
    end
end

function ElementTD:OnHeroInGame(hero)
    local playerID = hero:GetPlayerID()
    if playerID == -1 then return end
    CreateDataForPlayer(playerID)

    local playerData = GetPlayerData(playerID)
    playerData.name = PlayerResource:GetPlayerName(playerID)
    if playerData.name == "" then -- This normally happens in dev tools
        playerData.name = 'Developer'
    end
    self:InitializeHero(playerID, hero)
    self.playerSpawnIndexes[playerID] = playerData.sector + 1
    self.availableSpawnIndex = self.availableSpawnIndex + 1

    -- we must create the Elemental Summoner for this player
    local sector = playerData.sector + 1
    local summoner = CreateUnitByName("elemental_summoner", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber()) 
    summoner:SetOwner(hero)
    summoner:SetControllableByPlayer(playerID, true)
    summoner:SetAngles(0, 270, 0)
    summoner:AddItem(CreateItem("item_buy_pure_essence_disabled", nil, nil))
    summoner.icon = CreateUnitByName("elemental_summoner_icon", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber())
    playerData.summoner = summoner

    hero:ModifyGold(0)
    ModifyLumber(playerID, 0)  -- updates summoner spells
    ModifyPureEssence(playerID, 0, true)
    UpdateElementsHUD(playerID)
    UpdatePlayerSpells(playerID)

    Sandbox:CheckPlayer(playerID)  
end

-- initializes a player's hero
function ElementTD:InitializeHero(playerID, hero)
    print("OnInitHero PID:"..playerID)
    hero:AddNewModifier(nil, nil, "modifier_disarmed", {})
    hero:AddNewModifier(nil, nil, "modifier_attack_immune", {})
    hero:AddNewModifier(hero, nil, "modifier_client_convars", {})
    hero:AddNewModifier(hero, nil, "modifier_max_ms", {})

    hero:SetAbilityPoints(0)
    hero:SetMaxHealth(50)
    hero:SetBaseMaxHealth(50)
    hero:SetHealth(50)
    hero:SetBaseDamageMin(0)
    hero:SetBaseDamageMax(0)
    hero:SetGold(0, false)
    hero:SetGold(0, true)
    hero:SetModelScale(0.75)

    -- Team location based colors
    local teamID = PlayerResource:GetTeam(playerID)
    PlayerResource:SetCustomPlayerColor(playerID, m_TeamColors[teamID][1], m_TeamColors[teamID][2], m_TeamColors[teamID][3])

    self.vPlayerIDToHero[playerID] = hero -- Store hero for player in here GetAssignedHero can be flakey

    local playerData = GetPlayerData(playerID)

    playerData.sector = TEAM_TO_SECTOR[hero:GetTeamNumber()]

    SCORING_OBJECTS[playerID] = ScoringObject(playerID)
    playerData.scoreObject = SCORING_OBJECTS[playerID]

    -- Give building items
    hero:AddItem(CreateItem("item_build_arrow_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_cannon_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_periodic_tower_disabled", hero, hero))
   
    playerData.toggle_grid_item = hero:AddItem(CreateItem("item_toggle_grid", hero, hero))
    playerData.toggle_grid_item.particles = setmetatable({}, {
        __index = (function(tab, index)
            tab[index] = {}
            return tab[index]
        end)
    })
    
    Timers:CreateTimer(0.1, function() hero:SwapItems(3, 5) end)

    -- Additional Heroes UI
    heroUI = hero:FindAbilityByName("hero_ui")
    if heroUI then
        heroUI:SetLevel(1)
    end

    UpdatePlayerSpells(playerID)
    UpdateScoreboard(playerID)
end

function ElementTD:OnEntityKilled(keys)
    local index = keys.entindex_killed
    local entity = EntIndexToHScript(index)
    local killer = EntIndexToHScript(keys.entindex_attacker)
    local playerData = GetPlayerData(entity.playerID)

    if playerData and playerData.health == 0 then
        return
    end

    if IsCustomBuilding(entity) then
        -- Remove dead units from selection group
        RemoveUnitFromSelection(entity)
    end

    if entity.scriptObject and entity.scriptObject.OnDeath then
        entity.scriptObject:OnDeath(killer)
    end

    if entity:GetUnitName() == "icefrog" then
        -- Count non-undead frogs
        if playerData and entity.real_icefrog then
            
            -- Bulky counts as 2 kills
            if entity:HasAbility("creep_ability_bulky") then
                playerData.iceFrogKills = playerData.iceFrogKills + 2
            else
                playerData.iceFrogKills = playerData.iceFrogKills + 1
            end
            entity:EmitSound("Frog.Kill")
        end
    end

    if entity.isElemental then
        -- an elemental was killed :O
        Timers:RemoveTimer("MoveElemental"..index)
        Log:info(playerData.name .. " has killed a " .. entity.element .. " elemental level ".. entity.level)
        playerData.elementalActive = false
        playerData.elementalUnit = nil
        ModifyElementValue(entity.playerID, entity.element, 1)
        AddElementalTrophy(entity.playerID, entity.element)

        Sounds:PlayElementalDeathSound(entity.playerID, entity)
    else
        local playerID = entity.playerID
        if entity.waveObject then 
            entity.waveObject:OnCreepKilled(index)
        end
        CREEP_SCRIPT_OBJECTS[index] = nil

        UpdateScoreboard(playerID)
        Timers:RemoveTimer("MoveUnit"..index)
    end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function ElementTD:OnConnectFull(keys)
    
    local entIndex = keys.index+1
    -- The Player entity of the joining user
    local ply = EntIndexToHScript(entIndex)    
    
    table.insert(players, ply)
    Timers:CreateTimer(0.03, function() -- To prevent it from being -1 when the player is created
        local playerID = ply:GetPlayerID()
        if playerID and playerID ~= -1 then
            if not tableContains(playerIDs, playerID) then
                table.insert(playerIDs, playerID)
            else
                ElementTD:OnReconnect(playerID)
            end

            -- Update the user ID table with this user
            self.vUserIds[keys.userid] = ply
            self.vPlayerUserIds[playerID] = keys.userid
        else
            print("Got an invalid playerID: ", playerID)
        end
    end)
end

-- Called every time the player connects after being added to the valid playerIDs
function ElementTD:OnReconnect(playerID)
    local player = PlayerResource:GetPlayer(playerID)

    Sandbox:CheckPlayer(playerID)

    if PlayerData[playerID] and PlayerData[playerID].elements then
        ModifyLumber(playerID, 0) -- updates summoner spells
        ModifyPureEssence(playerID, 0, true)
        UpdateElementsHUD(playerID)
        UpdateRandom(playerID)
    end

    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION then
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if not hero then
            local hero = CreateHeroForPlayer("npc_dota_hero_wisp", player)

            if PLAYERS_NOT_VOTED[playerID] and START_GAME_TIME == 0 then
                CustomGameEventManager:Send_ServerToPlayer( player, "etd_toggle_vote_dialog", {visible = true} )
            end
        end
    end
end

function ElementTD:OnPlayerSelectedEntities( event )
    local playerID = event.PlayerID
    GameRules.SELECTED_UNITS[playerID] = event.selected_entities
end

function ElementTD:FilterExecuteOrder( filterTable )
    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]
    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]
    local x = tonumber(filterTable["position_x"])
    local y = tonumber(filterTable["position_y"])
    local z = tonumber(filterTable["position_z"])
    local point = Vector(x,y,z)
    local queue = filterTable["queue"] == 1

    -- Skip Prevents order loops
    if not units["0"] then
        return true
    end

     -- Track the current order
    for n,unit_index in pairs(units) do
        local unit = EntIndexToHScript(unit_index)
        if unit and IsValidEntity(unit) then
            unit.orderTable = filterTable
        end
    end

    local unit = EntIndexToHScript(units["0"])
    if unit and unit.skip then
        unit.skip = false
        return true
    end

    if unit and IsTower(unit) and (order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET or order_type == DOTA_UNIT_ORDER_ATTACK_MOVE) then
        return false
    end

    if unit and unit:IsRealHero() and unit.cosmetic_override then
        Rewards:HandleAnimationOrder(unit, order_type)
    end

    ------------------------------------------------
    --           Ability Multi Order              --
    ------------------------------------------------
    if abilityIndex and abilityIndex > 0 then
        local ability = EntIndexToHScript(abilityIndex)
        if not ability then return end
        local abilityName = ability:GetAbilityName()

        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        if not entityList then return true end

        if string.match(abilityName, "sell_tower_") then
            
            for _,entityIndex in pairs(entityList) do
                local caster = EntIndexToHScript(entityIndex)
                -- Make sure the original caster unit doesn't cast twice
                if caster and caster ~= unit and caster:HasAbility(abilityName) then
                    local abil = caster:FindAbilityByName(abilityName)
                    if abil and abil:IsFullyCastable() then --CHECK GOLD

                        -- Only NO_TARGET
                        caster.skip = true
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
                    end
                end
            end

        elseif string.match(abilityName, "item_upgrade_to_") then
            if not unit:IsStunned() then
                unit.upgrading = true
            end
            for _,entityIndex in pairs(entityList) do
                local caster = EntIndexToHScript(entityIndex)
                -- Make sure the original caster unit doesn't cast twice
                if caster and caster ~= unit and caster:HasItemInInventory(abilityName) then
                    local item = GetItemByName(caster, abilityName)
                    if item and item:IsFullyCastable() and not caster:IsStunned() and not caster.upgrading then

                        -- Only NO_TARGET
                        caster.skip = true
                        caster.upgrading = true
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = item:GetEntityIndex(), Queue = queue})
                    end
                end
            end
        elseif ability:GetAbilityKeyValues()["AbilityMultiOrder"] then
            for _,entityIndex in pairs(entityList) do
                local caster = EntIndexToHScript(entityIndex)

                -- Make sure the original caster unit doesn't cast twice
                if caster and caster ~= unit and caster:HasAbility(abilityName) then
                    local abil = caster:FindAbilityByName(abilityName)
                    if abil and abil:IsFullyCastable() then

                        caster.skip = true
                        if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
                            if (caster:GetAbsOrigin() - point):Length2D() <= ability:GetCastRange() then
                                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, Position = point, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
                            end
                        else
                            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
                        end
                    end
                end
            end

            -- stop the main target target point if its out of range
            if order_type == DOTA_UNIT_ORDER_CAST_POSITION and (unit:GetAbsOrigin() - point):Length2D() > ability:GetCastRange() then
                unit:Interrupt()
                SendErrorMessage(issuer, "dota_hud_error_target_out_of_range")
            end

        -- Stop cast on out of range target
        elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET and targetIndex then
            local target = EntIndexToHScript(targetIndex)
            if unit:GetRangeToUnit(target) > ability:GetCastRange(unit:GetAbsOrigin(), target) then
                unit:Interrupt()
                SendErrorMessage(issuer, "dota_hud_error_target_out_of_range")
                return false
            end
        end
    end

    -- Glyph
    if order_type == DOTA_UNIT_ORDER_GLYPH then
        if PlayerResource:IsValidPlayerID(issuer) then
            CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(issuer), "glyph_override", {} )
        end
        return false
    end

    return true
end

function ElementTD:DamageFilter( filterTable )
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end

    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local damagetype = filterTable["damagetype_const"]

    -- All our damage is done through elements custom DamageEntity, physical damage is not allowed
    if damagetype == DAMAGE_TYPE_PHYSICAL then
        return false
    end

    return true
end

function ElementTD:FilterProjectile( filterTable )
    local attacker_index = filterTable["entindex_source_const"]
    local victim_index = filterTable["entindex_target_const"]

    if not victim_index or not attacker_index then
        return true
    end

    local attacker = EntIndexToHScript( attacker_index )
    local is_attack = tobool(filterTable["is_attack"])

    if is_attack and attacker:HasGroundAttack() then
        local victim = EntIndexToHScript( victim_index )
        local move_speed = filterTable["move_speed"]
        AttackGroundPos(attacker, victim:GetAbsOrigin(), move_speed)
        return false
    end

    return true
end

PLAYER_CODES = {
    ["random"] = function(...) GameSettings:EnableRandomForPlayer(...) end,  -- Enable random for player
}

DEV_CODES = {
    ["dev"] = function(playerID) CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "sandbox_mode_visible", {}) end,
    ["sets"] = function(...) MakeSets() end,
    ["tooltips"] = function(...) Tooltips:Validate() end
}

-- A player has typed something into the chat
function ElementTD:OnPlayerChat(keys)
    local text = keys.text
    local userID = keys.userid
    local playerID = self.vUserIds[userID] and self.vUserIds[userID]:GetPlayerID()
    if not playerID then return end

    if StringStartsWith(text, "-") then
        local input = split(string.sub(text, 2, string.len(text)))
        local command = input[1]
        if PLAYER_CODES[command] then
            PLAYER_CODES[command](playerID, input[2])
        elseif DEV_CODES[command] and Sandbox:IsDeveloper(playerID) then
            DEV_CODES[command](playerID)
        end
    end
end

function ElementTD:CheatsEnabled()    
    for _, playerID in pairs(playerIDs) do
        local playerData = GetPlayerData(playerID)
        if playerData then
            playerData.cheated = true
        end
    end
    
    GameRules:SendCustomMessage("#etd_cheats_enabled", 0, 0)
end