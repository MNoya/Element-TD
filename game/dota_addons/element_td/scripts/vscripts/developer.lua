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
    ["dev"] = function(...) ElementTD:Dev(...) end,                 -- Everything
    ["setlist"] = function(...) ElementTD:MakeSets(...) end,            -- Creates full AttachWearables entries by set names
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
    local playerData = GetPlayerData(playerID)
    playerData.health = tonumber(value)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    hero:SetHealth(tonumber(value))
    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
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

function ElementTD:Dev(playerID)
    ElementTD:Synergy(playerID)
    ElementTD:WhosYourDaddy(playerID)
    ElementTD:GreedIsGood(playerID, 999999)
end

function ElementTD:MakeSets()
    if not GameRules.modelmap then MapWearables() end

    -- Generate all sets for each hero
    local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
    local filePath = "../../dota_addons/element_td/scripts/AttachWearables.txt"
    local file = io.open(filePath, 'w')

    for k,v in pairs(heroes) do
        GenerateAllSetsForHero(file, k)
    end

    file:close()    
    
end

function GenerateAllSetsForHero( file, heroName )
    local indent = "    "
    file:write(indent..string.rep("/", 60).."\n")
    file:write(indent.."// Cosmetic Sets for "..heroName.."\n")
    file:write(indent..string.rep("/", 60).."\n")
    GenerateDefaultBlock(file, heroName)

    -- Find sets that match this hero
    for key,values in pairs(GameRules.items) do
        if values.name and values.used_by_heroes and values.prefab and values.prefab == "bundle" then
            if type(values.used_by_heroes) == "table" then
                for k,v in pairs(values.used_by_heroes) do
                    if k == heroName then
                        GenerateBundleBlock(file, values.name)
                    end
                end
            end
        end
    end
    file:write("\n")
end

function MapWearables()
    GameRules.items = LoadKeyValues("scripts/items/items_game.txt")['items']
    GameRules.modelmap = {}
    for k,v in pairs(GameRules.items) do
        if v.name and v.prefab ~= "loading_screen" then
            GameRules.modelmap[v.name] = k
        end
    end
end

function GenerateDefaultBlock( file, heroName )
    file:write("    \"Creature\"\n")
    file:write("    {\n")
    file:write("        \"AttachWearables\" ".."// Default "..heroName.."\n")
    file:write("        {\n")
    local defCount = 1
    for code,values in pairs(GameRules.items) do
        if values.name and values.prefab == "default_item" and values.used_by_heroes then
            for k,v in pairs(values.used_by_heroes) do
                if k == heroName then
                    local itemID = GameRules.modelmap[values.name]
                    GenerateItemDefLine( file, defCount, itemID, values.name )
                    defCount = defCount + 1
                end
            end
        end
    end
    file:write("        }\n")
    file:write("    }\n")
end
 
function GenerateBundleBlock( file, setname )
    local bundle = {}
    for code,values in pairs(GameRules.items) do
        if values.name and values.name == setname and values.prefab and values.prefab == "bundle" then
            bundle = values.bundle
        end
    end

    file:write("    \"Creature\"\n")
    file:write("    {\n")
    file:write("        \"AttachWearables\" ".."// "..setname.."\n")
    file:write("        {\n")
    local wearableCount = 1
    for k,v in pairs(bundle) do
        local itemID = GameRules.modelmap[k]
        if itemID then
            GenerateItemDefLine(file, wearableCount, itemID, k)
            wearableCount = wearableCount+1
        end
    end
    file:write("        }\n")
    file:write("    }\n")
end
 
function GenerateItemDefLine( file, i, itemID, comment )
    file:write("            \""..tostring(i).."\" { ".."\"ItemDef\" \""..itemID.."\" } // "..comment.."\n")
end