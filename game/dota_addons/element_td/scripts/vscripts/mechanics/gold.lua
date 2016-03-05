-- All gold is reliable. The gold value is stored on the playerData
function CDOTA_BaseNPC_Hero:ModifyGold(goldAmount)
    local hero = self
    local playerID = hero:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)

    if goldAmount < 0 and playerData.freeTowers then
        return
    end

    local newGold = tonumber(playerData.gold) + tonumber(goldAmount)
    SetCustomGold(playerID, newGold)
end

function CDOTA_BaseNPC_Hero:GetGold()
    local hero = self
    local playerID = hero:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    return playerData.gold
end

function CDOTA_PlayerResource:GetGold(playerID)
    return GetPlayerData(playerID).gold
end

function CDOTA_PlayerResource:ModifyGold(playerID, goldAmount)
    local playerData = GetPlayerData(playerID)    
    local newGold = tonumber(playerData.gold) + tonumber(goldAmount)
    SetCustomGold(playerID, newGold)
end

function SetCustomGold(playerID, amount )
    local playerData = GetPlayerData(playerID)
    local player = PlayerResource:GetPlayer(playerID)

    playerData.gold = amount

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
        hero:SetGold(0, false)
        hero:SetGold(playerData.gold, true) --This can go up to 99.999 gold, but the UI will still show bigger values
    end

    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "etd_update_gold", { gold = playerData.gold } )
    end
end