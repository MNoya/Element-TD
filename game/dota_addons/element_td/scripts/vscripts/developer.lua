CHEAT_CODES = {
    ["greedisgood"] = function(...) ElementTD:GreedIsGood(...) end,     -- Gives you X gold and lumber
    ["lumber"] = function(...) ElementTD:GiveLumber(...) end,           -- Gives you X lumber
    ["whosyourdaddy"] = function(...) ElementTD:WhosYourDaddy(...) end, -- God Mode
    ["spawn"] = function(...) ElementTD:SpawnWave(...) end,             -- Spawns a certain wave by number, continues
    ["setwave"] = function(...) ElementTD:SetWave(...) end,             -- Sets the next current wave to spawn
    ["lives"] = function(...) ElementTD:SetLives(...) end,              -- Sets the current lives of the hero
    ["stop"] = function(...) ElementTD:StopWaves(...) end,              -- Stops spawning waves
    ["clear"] = function(...) ElementTD:ClearWave(...) end,             -- Kills the whole wave
    ["element"] = function(...) ElementTD:SetElementLevel(...) end,     -- Sets the level of an element
    ["synergy"] = function(...) ElementTD:Synergy(...) end,             -- Disable tech tree requirements
}

-- A player has typed something into the chat
function ElementTD:OnPlayerChat(keys)
    local text = keys.text
    local userID = keys.userid
    local playerID = self.vUserIds[userID] and self.vUserIds[userID]:GetPlayerID()
    if not playerID then return end

    -- Handle '-command'
    if StringStartsWith(text, "-") then
        text = string.sub(text, 2, string.len(text))
    end

    local input = split(text)
    local command = input[1]
    if CHEAT_CODES[command] then
        CHEAT_CODES[command](playerID, input[2], input[3])
    end
end

function ElementTD:GreedIsGood(playerID, value)
    value = value or 500
    
    PlayerResource:ModifyGold(playerID, tonumber(value), true, 0)
    ModifyLumber(playerID, tonumber(value))
    UpdatePlayerSpells(playerID)
    
    GameRules:SendCustomMessage("Cheat enabled!", 0, 0)
end

function ElementTD:GiveLumber(playerID, value)
    value = value or 1
    
    ModifyLumber(playerID, tonumber(value))
    UpdatePlayerSpells(playerID)
    
    GameRules:SendCustomMessage("Cheat enabled!", 0, 0)
end

function ElementTD:WhosYourDaddy()
    GameRules.WhosYourDaddy = not GameRules.WhosYourDaddy
    
    local message = GameRules.WhosYourDaddy and "Cheat enabled!" or "Cheat disabled!"
    GameRules:SendCustomMessage(message, 0, 0)
end

function ElementTD:SpawnWave(playerID, waveNumber)
    waveNumber = waveNumber or GetPlayerData(playerID).nextWave

    ElementTD:StopWaves(playerID)
    SpawnWaveForPlayer(playerID, tonumber(waveNumber))
end

function ElementTD:SetWave(playerID, value)
    value = value or 1

    ElementTD:StopWaves(playerID)
    GetPlayerData(playerID).nextWave = tonumber(value)
    GetPlayerData(playerID).completedWaves = tonumber(value) - 1
end

function ElementTD:SetLives(playerID, value)
    value = value or 50
    GetPlayerData(playerID).health = tonumber(value)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    hero:SetHealth(tonumber(value))
end

function ElementTD:StopWaves(playerID)
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject

    Timers:RemoveTimer(wave.spawnTimer)
    wave:SetOnCompletedCallback(function() end)
end

function ElementTD:ClearWave(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject
    local creeps = wave.creeps

    if creeps then
        for k,v in pairs(creeps) do
            local unit = EntIndexToHScript(v)
            if IsValidEntity(unit) then
                unit:Kill(nil, hero)
            end
        end
    end

    local elemental = playerData.elementalUnit
    if elemental then elemental:Kill(nil, hero) end

    -- Complete the wave
    wave:callback()

end

function ElementTD:SetElementLevel(playerID, elem, level)
    level = level or 1
    ModifyElementValue(playerID, elem, level)
end

function ElementTD:Synergy(playerID)
    ModifyElementValue(playerID, "water", 3)
    ModifyElementValue(playerID, "fire", 3)
    ModifyElementValue(playerID, "nature", 3)
    ModifyElementValue(playerID, "earth", 3)
    ModifyElementValue(playerID, "light", 3)
    ModifyElementValue(playerID, "dark", 3)

    UpdateElementsHUD(playerID)
    UpdatePlayerSpells(playerID)
    UpdateSummonerSpells(playerID)

    GameRules:SendCustomMessage("Cheat enabled!", 0, 0)
end