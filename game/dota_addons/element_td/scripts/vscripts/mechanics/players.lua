function ForAllPlayerIDs(callback)
    for playerID = 0, ETD_MAX_PLAYERS-1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            callback(playerID)
        end
    end
end

function ForAllConnectedPlayerIDs(callback)
    ForAllPlayerIDs(function(playerID)
        if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
            callback(playerID)
        end
    end)
end

function CDOTA_PlayerResource:GetPlayerCountWithoutLeavers()
    local count = 0
    ForAllPlayerIDs(function(playerID)
        if self:GetConnectionState(playerID) ~= DOTA_CONNECTION_STATE_ABANDONED then
            count = count + 1
        end
    end)
    return count
end