if not players then
    players = {}

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

    -- Event Hooks
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(ElementTD, 'OnConnectFull'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(ElementTD, 'EntityKilled'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(ElementTD, 'OnPlayerChat'), self)
    ListenToGameEvent('entity_hurt', Dynamic_Wrap(ElementTD, 'EntityHurt'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(ElementTD, 'OnUnitSpawned'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(ElementTD, 'OnGameStateChange'), self)

    -- Register Listener
    CustomGameEventManager:RegisterListener( "update_selected_entities", Dynamic_Wrap(ElementTD, 'OnPlayerSelectedEntities'))
    GameRules.SELECTED_UNITS = {}

    -- Filters
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( ElementTD, "FilterExecuteOrder" ), self )
    GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( ElementTD, "DamageFilter" ), self )

    -- Lua Modifiers
    LinkLuaModifier("modifier_stunned", "libraries/modifiers/modifier_stunned", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_invisible_etd", "libraries/modifiers/modifier_invisible", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_no_health_bar", "libraries/modifiers/modifier_no_health_bar", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_transparency", "libraries/modifiers/modifier_transparency.lua", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_disabled", "libraries/modifiers/modifier_disabled", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_attack_disabled", "libraries/modifiers/modifier_attack_disabled", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_damage_block", "libraries/modifiers/modifier_damage_block", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_support_tower", "libraries/modifiers/modifier_support_tower", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_bonus_life", "libraries/modifiers/modifier_bonus_life", LUA_MODIFIER_MOTION_NONE)    
    LinkLuaModifier("modifier_disable_turning", "libraries/modifiers/modifier_disable_turning", LUA_MODIFIER_MOTION_NONE)    
    
    -- Register UI Listener   
    CustomGameEventManager:RegisterListener( "next_wave", Dynamic_Wrap(ElementTD, "OnNextWave")) -- wave info
    CustomGameEventManager:RegisterListener( "etd_player_voted", Dynamic_Wrap(ElementTD, "OnPlayerVoted")) -- voting ui

    ------------------------------------------------------
    local base_game_mode = GameRules:GetGameModeEntity()
    base_game_mode:SetRecommendedItemsDisabled(true) -- no recommended items panel
    base_game_mode:SetFogOfWarDisabled(true) -- no fog
    base_game_mode:SetBuybackEnabled( false )
    base_game_mode:SetCameraDistanceOverride(1500) -- move the camera higher up
    base_game_mode:SetCustomGameForceHero( "npc_dota_hero_wisp" ) -- Skip hero pick screen
    ------------------------------------------------------

    -- Allow cosmetic swapping
    SendToServerConsole( "dota_combine_models 1" )

    -- Don't end the game if everyone is unassigned
    SendToServerConsole("dota_surrender_on_disconnect 0")

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

    for _, player in pairs(players) do

        -- loop over the player's towers
        for towerID, _ in pairs(GetPlayerData(player:GetPlayerID()).towers) do
            local tower = EntIndexToHScript(towerID)
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

function ElementTD:OnGameStateChange(keys)
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
        self.gameStartTriggers = self.gameStartTriggers + 1
        if self.gameStartTriggers < 2 then return end

        GameRules:SendCustomMessage("Welcome to <font color='#70EA72'>Element Tower Defense</font>!", 0, 0)
        
        self.gameStarted = true

        self:StartGame()
    end
end

-- let's start the actual game
-- call this after the players have been move to their proper spawn locations
function ElementTD:StartGame()
    print("ElementTD Started!")
    Timers:CreateTimer("StartGameDelay", {
        endTime = 3,

        callback = function()
            Log:info("The game has started!")
            
            if not SKIP_VOTING then
                CustomGameEventManager:Send_ServerToAllClients( "etd_toggle_vote_dialog", {visible = true} )
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

function ElementTD:OnNextWave( keys )
    local playerID = keys.PlayerID
    local data = GetPlayerData(playerID)
    if (data.waveObject and data.waveObject.creepsRemaining == 0) or data.nextWave == 1 then
        Timers:RemoveTimer("SpawnWaveDelay"..playerID)
        Log:info("Spawning wave " .. data.nextWave .. " for ["..playerID.."] ".. data.name)
        ShowMessage(playerID, "Wave " .. data.nextWave, 3)
        SpawnWaveForPlayer(playerID, data.nextWave) -- spawn dat wave
        WAVE_1_STARTED = true
    end
end

function ElementTD:EndGameForPlayer( playerID )
    local playerData = GetPlayerData(playerID)

    if playerData.completedWaves + 1 >= WAVE_COUNT and not EXPRESS_MODE then
        Log:info("Player "..playerID.." has been defeated on the boss wave "..playerData.nextWave..".")
        GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerData.name.."</font> has completed the game!", 0, 0)
    else
        Log:info("Player "..playerID.." has been defeated on wave "..playerData.nextWave..".")
        GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerData.name.."</font> has been defeated on wave "..playerData.nextWave.."!", 0, 0)
    end
    -- Clean up
    UpdatePlayerSpells(playerID)

    if playerData.elementalUnit ~= nil and not playerData.elementalUnit:IsNull() and playerData.elementalUnit:IsAlive() then
        print("Elemental Removed")
        playerData.elementalUnit:ForceKill(false)
    end
    for i,v in pairs(playerData.towers) do
        RemoveTower(EntIndexToHScript(i))
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
        print(#players, playerData.health, playerData.completedWaves)
        if playerData.health ~= 0 or (playerData.health ~= 0 and playerData.completedWaves < WAVE_COUNT and EXPRESS_MODE) then
            endGame = false
        end
    end
    local teamWinner = DOTA_TEAM_BADGUYS
    if #players == 1 then
        for k, ply in pairs(players) do
            local playerData = GetPlayerData(ply:GetPlayerID())
            -- Lost
            if (playerData.health == 0 and not EXPRESS_MODE and playerData.completedWaves < WAVE_COUNT) or (EXPRESS_MODE and playerData.health == 0) then
                if ply:GetTeamNumber() == teamWinner then
                    teamWinner = DOTA_TEAM_GOODGUYS
                end
            else -- Won
                teamWinner = ply:GetTeamNumber()
            end
        end
    else
        -- Wave > Difficulty > Score
        local winnerId = -1
        local compareWave = 0
        local compareScore = 0
        local compareDifficulty = "Normal"
        for k, ply in pairs(players) do
            local playerData = GetPlayerData(ply:GetPlayerID())
            if playerData.completedWaves > compareWave then
                winnerId = ply:GetPlayerID()
                compareWave = playerData.completedWaves
                compareScore = playerData.scoreObject.totalScore
                compareDifficulty = playerData.difficulty.difficultyName
            elseif playerData.completedWaves == compareWave then
                if playerData.difficulty.difficultyName == compareDifficulty then
                    if playerData.scoreObject.totalScore >  compareScore then
                        winnerId = ply:GetPlayerID()
                        compareWave = playerData.completedWaves
                        compareScore = playerData.scoreObject.totalScore
                        compareDifficulty = playerData.difficulty.difficultyName
                    end
                else
                    local diff = playerData.difficulty.difficultyName
                    if diff == "Insane" or (diff == "VeryHard" and (compareDifficulty == "Hard" or compareDifficulty == "Normal")) or (diff == "Hard" and compareDifficulty == "Normal") then
                        winnerId = ply:GetPlayerID()
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
    if endGame then
        Log:info("Game end condition reached. Ending game in 5 seconds.")
        GameRules:SendCustomMessage("Thank you for playing <font color='#70EA72'>Element Tower Defense</font>!", 0, 0)
        Timers:CreateTimer(5, function()
            GameRules:SetGameWinner( teamWinner )
            GameRules:SetSafeToLeave( true )
        end)
    end
end

function ElementTD:OnUnitSpawned(keys)
    local unit = EntIndexToHScript(keys.entindex)

    if unit:IsRealHero() then
        local hero = unit
        local playerID = hero:GetPlayerOwnerID()
        local player = PlayerResource:GetPlayer(playerID)
        CreateDataForPlayer(playerID)

        if playerID >= 0 then
            local playerData = GetPlayerData(playerID)
            playerData.name = PlayerResource:GetPlayerName(playerID)
            self:InitializeHero(player:GetPlayerID(), unit)
            self.playerSpawnIndexes[player:GetPlayerID()] = playerData.sector + 1
            self.availableSpawnIndex = self.availableSpawnIndex + 1

            -- reposition the camera
            --PlayerResource:SetCameraTarget(playerID, hero)
            --Timers:CreateTimer(1, function() PlayerResource:SetCameraTarget(playerID, nil) end)

            -- we must create the Elemental Summoner for this player
            local sector = playerData.sector + 1
            local summoner = CreateUnitByName("elemental_summoner", ElementalSummonerLocations[sector], false, nil, nil, hero:GetTeamNumber()) 
            summoner:SetOwner(hero)
            summoner:SetControllableByPlayer(playerID, true)
            summoner:SetAngles(0, 270, 0)
            summoner:AddItem(CreateItem("item_buy_pure_essence", summoner, summoner))

            GetPlayerData(playerID)["summoner"] = summoner
            ModifyLumber(playerID, 0)  -- updates summoner spells
            UpdatePlayerSpells(playerID)
        end
    end
end

-- initializes a player's hero
function ElementTD:InitializeHero(playerID, hero)
    print("OnInitHero PID:"..playerID)
    hero:AddNewModifier(nil, nil, "modifier_disarmed", {})
    hero:SetAbilityPoints(0)
    hero:SetMaxHealth(50)
    hero:SetBaseMaxHealth(50)
    hero:SetHealth(50)
    hero:SetBaseDamageMin(0)
    hero:SetBaseDamageMax(0)
    hero:SetGold(0, false)
    hero:SetGold(0, true)
    hero:SetModelScale(0.75)
    hero:AddNewModifier(nil, nil, "modifier_silence", {}) -- silence this player until break time is started

    -- Team location based colors
    local teamID = PlayerResource:GetTeam(playerID)
    PlayerResource:SetCustomPlayerColor(playerID, m_TeamColors[teamID][1], m_TeamColors[teamID][2], m_TeamColors[teamID][3])

    self.vPlayerIDToHero[playerID] = hero -- Store hero for player in here GetAssignedHero can be flakey

    local playerData = GetPlayerData(playerID)

    playerData.sector = TEAM_TO_SECTOR[hero:GetTeamNumber()]

    SCORING_OBJECTS[playerID] = ScoringObject(playerID)
    playerData.scoreObject = SCORING_OBJECTS[playerID]

    -- Teach building abilities
    for i=0,5 do
        local ability = hero:GetAbilityByIndex(i)
        if ability then
            ability:SetLevel(1)
        end
    end

    -- Give building items
    hero:AddItem(CreateItem("item_build_arrow_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_cannon_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_periodic_tower", hero, hero))

    UpdatePlayerSpells(playerID)
    UpdateScoreboard(playerID)
end

function ElementTD:EntityKilled(keys)
    local index = keys.entindex_killed
    local entity = EntIndexToHScript(index)
    local playerData = GetPlayerData(entity.playerID)

    if playerData and playerData.health == 0 then
        return
    end

    if entity.scriptObject and entity.scriptObject.OnDeath then
        entity.scriptObject:OnDeath()
    end

    if entity.isElemental then
        -- an elemental was killed :O
        Timers:RemoveTimer("MoveElemental"..index)
        Log:info(playerData.name .. " has killed a " .. entity.element .. " elemental level ".. entity.level)
        playerData.elementalActive = false
        playerData.elementalUnit = nil
        ModifyElementValue(entity.playerID, entity.element, 1)
        AddElementalTrophy(entity.playerID, entity.element)
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
        UpdateScoreboard(playerID)
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

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function ElementTD:OnConnectFull(keys)
    
    local entIndex = keys.index+1
    -- The Player entity of the joining user
    local ply = EntIndexToHScript(entIndex)

    -- The Player ID of the joining player
    local playerID = ply:GetPlayerID()

    table.insert(players, ply)

    -- Update the user ID table with this user
    self.vUserIds[keys.userid] = ply
    self.vPlayerUserIds[playerID] = keys.userid

end

function ElementTD:OnPlayerSelectedEntities( event )
    local pID = event.pID

    GameRules.SELECTED_UNITS[pID] = event.selected_entities

    -- This is for Building Helper to know which is the currently active builder
    local mainSelected = GetMainSelectedEntity(pID)
    local player = BuildingHelper:GetPlayerTable(pID)
    if IsValidEntity(mainSelected) and IsBuilder(mainSelected) then
        player.activeBuilder = mainSelected
    else
        if IsValidEntity(player.activeBuilder) then
            -- Clear ghost particles when swapping to a non-builder
            BuildingHelper:StopGhost(player.activeBuilder)
        end
    end
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

    local unit = EntIndexToHScript(units["0"])
    if unit and unit.skip then
        unit.skip = false
        return true
    end

    ------------------------------------------------
    --           Ability Multi Order              --
    ------------------------------------------------
    if abilityIndex and abilityIndex > 0 then
        local ability = EntIndexToHScript(abilityIndex)
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

             for _,entityIndex in pairs(entityList) do
                local caster = EntIndexToHScript(entityIndex)
                -- Make sure the original caster unit doesn't cast twice
                if caster and caster ~= unit and caster:HasItemInInventory(abilityName) then
                    local item = GetItemByName(caster, abilityName)
                    if item and item:IsFullyCastable() then

                        -- Only NO_TARGET
                        caster.skip = true
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = item:GetEntityIndex(), Queue = queue})
                    end
                end
            end
        end
    end


     ------------------------------------------------
    --              ClearQueue Order              --
    ------------------------------------------------
    -- Cancel queue on Stop and Hold
    if order_type == DOTA_UNIT_ORDER_STOP or order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
        for n, unit_index in pairs(units) do 
            local unit = EntIndexToHScript(unit_index)
            if IsBuilder(unit) then
                BuildingHelper:ClearQueue(unit)
            end
        end
        return true

    -- Cancel builder queue when casting non building abilities
    elseif (abilityIndex and abilityIndex ~= 0) and unit and IsBuilder(unit) then
        local ability = EntIndexToHScript(abilityIndex)
        if not IsBuildingAbility(ability) then
            BuildingHelper:ClearQueue(unit)
        end
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

    if damagetype == DAMAGE_TYPE_PHYSICAL then
        local original_damage = filterTable["damage"] --Post reduction
        local inflictor = filterTable["entindex_inflictor_const"]

        -- Deny autoattack damage on towers that are projectile-based
        if not inflictor and attacker.no_autoattack_damage then
            filterTable["damage"] = 0
            return true
        end
    end

    -- Cheat code
    if GameRules.WhosYourDaddy then
        local victimID = victim:GetPlayerOwnerID()
        local victimTeam = victim:GetTeamNumber()
        local attackerID = attacker:GetPlayerOwnerID()

        if GameRules.WhosYourDaddy then
            if attackerID and PlayerResource:IsValidPlayerID(attackerID) then
                filterTable["damage"] = victim:GetMaxHealth()
                filterTable["damagetype_const"] = DAMAGE_TYPE_PURE
            end
        end

        if victimID and PlayerResource:IsValidPlayerID(victimID) then
            filterTable["damage"] = 0
        end
    end

    return true
end

