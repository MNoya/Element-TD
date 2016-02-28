function RelocatePlayer(trigger)
    local activator = trigger.activator
    local playerID = activator:IsRealHero() and activator:GetPlayerID()

    if playerID and PlayerResource:IsValidPlayerID(playerID) then
        local playerData = GetPlayerData(playerID)
        local sector = playerData.sector + 1
        activator:SetAbsOrigin(ElementalSummonerLocations[sector])
    end
end

function IsInsideSector(pos, sector)
    local bounds = SectorBounds[sector]
    return (pos.x > bounds.left and pos.x < bounds.right and pos.y < bounds.top and pos.y > bounds.bottom)
end