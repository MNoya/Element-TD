-- ranking.lua
-- managers the fetching and displaying of player ranks
if not Ranking then
    Ranking = class({})
end

RANKING_URL = "http://hatinacat.com/leaderboard/data_request.php"

-- Generates list of ingame players and fetches their rankings
function Ranking:RequestInGamePlayerRanks()
    local leaderboard_type = EXPRESS_MODE and 1 or 0

    steamIDs = {} -- Stores all the steamIDs ingame

    -- Process steam IDs
    for _, playerID in pairs(playerIDs) do
        Ranking:New(playerID)
    end

    local concatSteamIDs = tableconcat(steamIDs, ",")
    local request = RANKING_URL .. "?req=player&ids=" .. concatSteamIDs .. "&lb=" .. leaderboard_type 

    -- Generate URL
    local req = CreateHTTPRequest('GET', request)
    Ranking:print('GET '..request)

    -- Send the request
    req:Send(function(res)
        if res.StatusCode ~= 200 or not res.Body then
            Ranking:print("Failed to contact ranking server.")
            return
        end

        -- Try to decode the result
        local obj, pos, err = json.decode(res.Body, 1, nil)

        -- Process the result
        if err then
            Ranking:print("Error in response : " .. err)
            return
        end

        if obj.result == 1 then
            Ranking:print("Retrieved player rankings!")
            for _,player in pairs(obj.players) do
                local playerID = Ranking:GetPlayerIDForSteamID(player.steamID)
                if Ranking[playerID] and not Ranking[playerID].score then              
                    local data = Ranking[playerID]
                    data.rank = player.rank
                    data.percentile = player.percentile
                    data.leaderboard = player.leaderboard
                    data.score = player.score

                    CustomNetTables:SetTableValue("rankings", tostring(playerID), data)
                end
            end
            Ranking:CreatePlayerRanks()
        else
            Ranking:print("Malformed request")
        end
    end)
end

function Ranking:New(playerID)
    -- Store the steamID for the player to get a direct reference
    local steamID = 34961594--PlayerResource:GetSteamAccountID(playerID)
    steamIDs[playerID] = steamID

    -- Initial values
    local ranking = {}
    ranking.steamID = steamID
    ranking.rank = 0
    ranking.percentile = 0
    ranking.leaderboard = 0
    ranking.sector = GetPlayerData(playerID).sector
    Ranking[playerID] = ranking
end

function Ranking:CreatePlayerRanks()
    CustomGameEventManager:Send_ServerToAllClients( "etd_create_ranks", {} )
end

function Ranking:ShowPlayerRanks()
    CustomGameEventManager:Send_ServerToAllClients( "etd_show_ranks", {} )
end

function Ranking:print(...)
    print("[Ranks] " .. ...)
end

function Ranking:GetPlayerIDForSteamID(steamID)
    return steamIDs[playerID] or 0---1
end

----------------------------------------------------
