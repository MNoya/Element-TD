customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Flag Example
    statCollection:setFlags({ version = VERSION })

    -- Listen for changes in the current state
    ListenToGameEvent('game_rules_state_change', function(keys)
        local state = GameRules:State_Get()

        -- Send custom stats when the game ends
        if state == DOTA_GAMERULES_STATE_POST_GAME then

            -- Build game array
            local game = BuildGameArray()

            -- Build players array
            local players = BuildPlayersArray()

            -- Print the schema data to the console
            if statCollection.TESTING then
                PrintSchema(game, players)
            end

            -- Send custom stats
            if statCollection.HAS_SCHEMA then
                statCollection:sendCustom({ game = game, players = players })
            end
        end
    end, nil)
end

-------------------------------------

-- In the statcollection/lib/utilities.lua, you'll find many useful functions to build your schema.
-- You are also encouraged to call your custom mod-specific functions

-- Returns a table with our custom game tracking.
function BuildGameArray()
    local game = {}

    -- Add game values here as game.someValue = GetSomeGameValue()
    game.exp = EXPRESS_MODE
    game.ord = GameSettings.order
    game.hor = GameSettings.endless
    game.rnd = GameSettings.elementsOrderName
    game.str = START_TIME
    game.fin = END_TIME
    game.ver = VERSION
    return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    local host = GetListenServerHost()
    local hostID = -1
    if host then
        hostID = host:GetPlayerID()
    end
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                local playerData = GetPlayerData(playerID)

                table.insert(players, {
                    -- steamID32 required in here
                    steamID32 = PlayerResource:GetSteamAccountID(playerID),

                    nt = GetPlayerNetworth(playerID), --Sell value of towers + current gold
                    go = playerData.gold, --Unusued gold
                    lmb = playerData.lumber, --Unused lumber 
                    ess = playerData.pureEssence, --Unused essence
                    sec = sectorNames[playerData.sector], --Sector on the map
                    dif = playerData.difficulty.difficultyName, --Difficulty, should probably be a Game value
                    tow = playerData.tow or tablelength(playerData.towers), --Final tower count
                    ltk = playerData.TotalLifeTowerKills, --Total life gained from Life Towers
                    bos = playerData.bossWaves, --Total boss waves survived if any
                    wav = playerData.completedWaves, --Number of completed waves
                    sco = playerData.scoreObject.totalScore, --Final score
                    ts = playerData.towersSold, -- Num of towers sold
                    gl = playerData.goldLost, -- Gold loss from selling
                    ig = playerData.interestGold, -- Interest gold earned
                    gt = playerData.goldTowerEarned, -- Total gold earned from Money Towers
                    dur = playerData.duration, -- Total seconds from start to death/win
                    lh = PlayerResource:GetLastHits(playerID),
                    -- elo = playerData.elements -- Element Order
                    hst = playerID == hostID or 0, -- Is this player host
                    clr = playerData.victory, -- Did the player complete the game

                    -- misc
                    cln = playerData.scoreObject.cleanWaves, -- Amount of waves without leaks
                    u30 = playerData.scoreObject.under30,    -- Amount of waves completed under 30
                    ifc = playerData.iceFrogKills, -- Amount of ice frog kills
                    rnd = (IsPlayerUsingRandomMode( playerID ) and 1 or 0), -- Is player randoming elements

                    -- Levels of each element at the end
                    fir = playerData.elements.fire,
                    wat = playerData.elements.water,
                    nat = playerData.elements.nature,
                    ear = playerData.elements.earth,
                    lig = playerData.elements.light,
                    dar = playerData.elements.dark,

                    -- Combos
                    ec = playerData.elementalCount, -- Element Count, 0~6
                    fd = playerData.firstDual or "",      -- First 2 elements acquired, ordered
                    ft = playerData.firstTriple or "",    -- First 3 elements acquired, ordered
                    e1 = playerData.elementOrder[1] or "", -- 1st element acquired
                    e2 = playerData.elementOrder[2] or "", -- 2nd element acquired
                    e3 = playerData.elementOrder[3] or "", -- 3rd element acquired
                    e4 = playerData.elementOrder[4] or "", -- 4th element acquired
                    e5 = playerData.elementOrder[5] or "", -- 5th element acquired
                    e6 = playerData.elementOrder[6] or "", -- 6th element acquired
                    e7 = playerData.elementOrder[7] or "", -- 7th element acquired
                    e8 = playerData.elementOrder[8] or "", -- 8th element acquired
                    e9 = playerData.elementOrder[9] or "", -- 9th element acquired
                    e10 = playerData.elementOrder[10] or "", -- 10th element acquired
                    e11 = playerData.elementOrder[11] or "", -- 11th and last element acquired

                    -- Check if cheats were used
                    cheat = playerData.cheated or "",
                })
            end
        end
    end

    return players
end

-- Prints the custom schema, required to get an schemaID
function PrintSchema(gameArray, playerArray)
    print("-------- GAME DATA --------")
    DeepPrintTable(gameArray)
    print("\n-------- PLAYER DATA --------")
    DeepPrintTable(playerArray)
    print("-------------------------------------")
end

-- Write 'test_schema' on the console to test your current functions instead of having to end the game
if Convars:GetBool('developer') then
    Convars:RegisterCommand("test_schema", function() PrintSchema(BuildGameArray(), BuildPlayersArray()) end, "Test the custom schema arrays", 0)
end

-------------------------------------

-- If your gamemode is round-based, you can use statCollection:submitRound(bLastRound) at any point of your main game logic code to send a round
-- If you intend to send rounds, make sure your settings.kv has the 'HAS_ROUNDS' set to true. Each round will send the game and player arrays defined earlier
-- The round number is incremented internally, lastRound can be marked to notify that the game ended properly
function customSchema:submitRound(isLastRound)

    local winners = BuildRoundWinnerArray()
    local game = BuildGameArray()
    local players = BuildPlayersArray()

    statCollection:sendCustom({ game = game, players = players })

    isLastRound = isLastRound or false --If the function is passed with no parameter, default to false.
    return { winners = winners, lastRound = isLastRound }
end

-- A list of players marking who won this round
function BuildRoundWinnerArray()
    local winners = {}
    local current_winner_team = GameRules.Winner or 0 --You'll need to provide your own way of determining which team won the round
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
            end
        end
    end
    return winners
end

-------------------------------------