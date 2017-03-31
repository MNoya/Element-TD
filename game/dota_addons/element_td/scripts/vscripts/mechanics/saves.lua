if not Saves then
    Saves = class({})
end

function Saves:Init()
    Saves.url = "http://hatinacat.com/leaderboard/data_request.php?req=save"
    Saves.players = {}
    Saves.builders = {}
    Saves.grids = {}

    -- Translate each custom elemental builder to a number between 0-5
    Saves.builders["npc_dota_hero_skywrath_mage"] = 0
    Saves.builders["npc_dota_hero_faceless_void"] = 1
    Saves.builders["npc_dota_hero_mirana"] = 2
    Saves.builders["npc_dota_hero_warlock"] = 3
    Saves.builders["npc_dota_hero_enchantress"] = 4
    Saves.builders["npc_dota_hero_earthshaker"] = 5
end

function Saves:GetHeroNameForID(num)
    for heroName,id in pairs(Saves.builders) do
        if id == num then
            return heroName
        end
    end
    return "npc_dota_hero_wisp"
end

function Saves:SavePasses()
    ForAllPlayerIDs(function(playerID)
        Saves:SaveHasPass(playerID)
    end)
end

function Saves:SaveHasPass(playerID)
    local steamID = PlayerResource:GetSteamAccountID(playerID)
    local bHasPass = PlayerResource:HasCustomGameTicketForPlayerID(playerID) and 1 or 0
    local request = Saves.url .. "&id=" .. steamID .. "&save=1" .. "&pass=" .. bHasPass

    local req = CreateHTTPRequestScriptVM('GET', request)

    -- Send another request to get the player data
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        Saves:LoadData(playerID)
    end
    
    Saves:Send(req, function(obj)
        -- Success
        Saves:print("Successfully saved pass info ("..bHasPass..") for player " .. playerID)
    end)
end

function Saves:SaveBuilder(playerID, heroName)
    local steamID = PlayerResource:GetSteamAccountID(playerID)

    local current_builder = Saves.builders[heroName] or -1
    local request = Saves.url .. "&id=" .. steamID .. "&save=1" .. "&custom_builder=" .. current_builder

    local req = CreateHTTPRequest('GET', request)
    
    Saves:Send(req, function(obj)
        -- Success
        Saves:print("Successfully saved custom builder ("..current_builder..") for player " .. playerID)
    end)
end

function Saves:SaveGrid(playerID, bEnabled)
    local steamID = PlayerResource:GetSteamAccountID(playerID)
    local state = bEnabled and 1 or 0
    local request = Saves.url .. "&id=" .. steamID .. "&save=1" .. "&grid=" .. state

    local req = CreateHTTPRequest('GET', request)
    
    Saves:Send(req, function(obj)
        -- Success
        Saves:print("Successfully saved grid state ("..state..") for player " .. playerID)
    end)
end

function Saves:LoadData(playerID)
    local steamID = PlayerResource:GetSteamAccountID(playerID)
    local request = Saves.url .. "&id=" .. steamID

    local req = CreateHTTPRequest('GET', request)

    Saves:print("Loading player " .. playerID)
    Saves:Send(req, function(obj)
        -- Success
        if obj.save then
            if obj.save.custom_builder then
                local builderNum = tonumber(obj.save.custom_builder)
                if builderNum == -1 then
                    Saves:print("Player " .. playerID.. " will use a default builder")
                else
                    local steamID32 = PlayerResource:GetSteamAccountID(playerID)
                    local steamID64 = tostring(Rewards:ConvertID64(steamID32))
                    Rewards.players[steamID64] = Rewards.players[steamID64] or {}
                    Rewards.players[steamID64].hero = Saves:GetHeroNameForID(tonumber(obj.save.custom_builder))

                    Saves:print("Got a custom builder for player " .. playerID.. ": ".. Rewards.players[steamID64].hero)
                end
            end

            if obj.save.grid then
                local gridEnabled = tonumber(obj.save.grid)
                if gridEnabled == 1 then
                    Saves.grids[playerID] = true
                    Saves:print("Toggle Grid for Player " .. playerID)
                end
            end
        end
    end)
end

function Saves:ShouldEnableGrid(playerID)
    return Saves.grids[playerID]
end

function Saves:Send(req, callback)
    -- Send the request
    req:Send(function(res)
        if res.StatusCode ~= 200 or not res.Body then
            Saves:print("Failed to contact the saves server")
            return
        end

        -- Try to decode the result
        local obj, pos, err = json.decode(res.Body, 1, nil)

        -- Process the result
        if err then
            Saves:print("Error in response : " .. err)
            return
        end

        -- Feed the result into our callback
        callback(obj)
    end)
end

function Saves:print(...)
    print("[Saves] ".. ...)
end

if not Saves.url then Saves:Init() end