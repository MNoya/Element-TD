-- leaderboard.lua
-- managers the fetching and displaying of leaderboard ranks
if not Leaderboard then
    Leaderboard = class({})
end

LEADERBOARD_URL = "http://hatinacat.com/leaderboard/data_request.php"

LB_CLASSIC = 0
LB_EXPRESS = 2
LB_FROGS = 3
LB_COOP = 4

MAX_RANKS = 100

function Leaderboard:Init()
    Leaderboard.state = {} --Stores the current leaderboard state
    CustomGameEventManager:RegisterListener("etd_leaderboard_request", Dynamic_Wrap(Leaderboard, 'RequestLeaderboard'))
    CustomGameEventManager:RegisterListener("etd_profile_stats_request", Dynamic_Wrap(Leaderboard, 'RequestProfileStats'))
    CustomGameEventManager:RegisterListener("etd_profile_friends_request", Dynamic_Wrap(Leaderboard, 'RequestProfileFriends'))
    CustomGameEventManager:RegisterListener("etd_profile_avatar_request", Dynamic_Wrap(Leaderboard, 'RequestProfileAvatar'))
    CustomGameEventManager:RegisterListener("etd_player_save_request", Dynamic_Wrap(Leaderboard, 'RequestPlayerSave'))
end

function Leaderboard:HttpRequest(url, callback)
    -- Generate URL
    local req = CreateHTTPRequestScriptVM('GET', url)
    Leaderboard:print('GET '..url)

    -- Send the request
    req:Send(function(res)
        if res.StatusCode ~= 200 or not res.Body then
            Leaderboard:print("Failed to contact leaderboard server.")
            callback(false)
            return
        end

        -- Try to decode the result
        local obj, pos, err = json.decode(res.Body, 1, nil)

        -- Process the result
        if err then
            Leaderboard:print("Error in response : " .. err)
            callback(false)
            return false
        end

        callback(obj)
    end)
end

function Leaderboard:RequestLeaderboard(event)
    local playerID = event.PlayerID
    local leaderboard_type = event.leaderboard_type

    PrintTable(event)

    local request = LEADERBOARD_URL .. "?req=leaderboard&top=" .. MAX_RANKS .. "&lb=" .. leaderboard_type 

    Leaderboard:HttpRequest(request, function(res)
        if res and res.result == 1 then
            Leaderboard:print("Retrieved leaderboard " .. leaderboard_type .. " rankings!")
            res.type = leaderboard_type
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_leaderboard_ranks", res)
        else
            Leaderboard:print("Malformed request")
        end
    end)
end

function Leaderboard:RequestProfileStats(event)
    local playerID = event.PlayerID
    local steamID = event.steam_id

    local request = LEADERBOARD_URL .. "?req=stats&raw=1&id=" .. steamID 

    Leaderboard:HttpRequest(request, function(res)
        if res and res.result == 1 then
            Leaderboard:print("Retrieved profile stats for " .. steamID)
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_profile_stats", res)
        else
            Leaderboard:print("Malformed request")
        end
    end)
end

function Leaderboard:RequestProfileFriends(event)
    local playerID = event.PlayerID
    local steamID = event.steam_id
    local leaderboard_type = event.leaderboard_type

    local request = LEADERBOARD_URL .. "?req=friends&id=" .. steamID .. "&lb=" .. leaderboard_type

    Leaderboard:HttpRequest(request, function(res)
        if res and res.result == 1 then
            Leaderboard:print("Retrieved profile friends for " .. steamID)
            res.type = leaderboard_type
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_profile_friends", res)
        else
            Leaderboard:print("Malformed request")
        end
    end)
end

function Leaderboard:RequestProfileAvatar(event)
    local playerID = event.PlayerID
    local steamID = event.steam_id

    local request = LEADERBOARD_URL .. "?req=stats&id=" .. steamID 

    Leaderboard:HttpRequest(request, function(res)
        if res and res.result == 1 then
            Leaderboard:print("Retrieved profile avatar stats for " .. steamID)
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_profile_avatar_stats", res)
        else
            Leaderboard:print("Malformed request")
        end
    end)
end

function Leaderboard:RequestPlayerSave(event)
    local playerID = event.PlayerID
    local steamID = event.steam_id

    local request = LEADERBOARD_URL .. "?req=save&id=" .. steamID 

    Leaderboard:HttpRequest(request, function(res)
        if res and res.result == 1 then
            Leaderboard:print("Retrieved player save for " .. steamID)
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_player_save", res)
        else
            Leaderboard:print("Malformed request")
        end
    end)
end

function Leaderboard:print(...)
    print("[Leaderboard] " .. ...)
end

if not Leaderboard.state then Leaderboard:Init() end

----------------------------------------------------
