function RelocatePlayer(trigger)
    local activator = trigger.activator
    local playerID = activator:IsRealHero() and activator:GetPlayerID()

    if playerID and PlayerResource:IsValidPlayerID(playerID) then
        if not Sandbox:IsDeveloper(playerID) then      
            local playerData = GetPlayerData(playerID)
            local sector = playerData.sector + 1
            activator:SetAbsOrigin(SpawnLocations[sector])

            ExecuteOrderFromTable({
                UnitIndex = activator:entindex(),
                OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
            })
       end
    end
end

function IsInsideSector(pos, sector)
    local bounds = COOP_MAP and CoopBounds or SectorBounds[sector]
    return (pos.x > bounds.left and pos.x < bounds.right and pos.y < bounds.top and pos.y > bounds.bottom)
end