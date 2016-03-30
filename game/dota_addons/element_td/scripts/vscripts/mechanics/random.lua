-- item_random
function ItemRandomUse(event)
    local caster = event.caster
    local item = event.ability
    local playerID = caster:GetPlayerOwnerID()

    GameSettings:EnableRandomForPlayer(playerID)
end

usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0, ["pure"] = 0 }
elements = {"water", "fire", "earth", "nature", "dark", "light", "pure"}
function getRandomElement(wave)
    local element = elements[math.random(#elements)]

    -- Never random a Pure Essence unless there's enough to use it on a Periodic/Pure tower
    if element == "pure" then
        if usedElements[element] < 2 then
            local hasLvl3 = false
            local hasLvl1 = true
            for i,v in pairs(usedElements) do
                if v == 3 then -- if level 3 of element
                    hasLvl3 = true
                end
                if v == 0 then
                    hasLvl1 = false
                end
            end
            if hasLvl3 or hasLvl1 then
                usedElements[element] = usedElements[element] + 1
                return element
            else
                return getRandomElement(wave)
            end
        end
    end

    if EXPRESS_MODE and ((wave < 3 and usedElements[element] == 1) or (wave < 12 and usedElements[element] == 2) or usedElements[element] == 3 ) then
        return getRandomElement(wave)
    elseif not EXPRESS_MODE and ((wave < 10 and usedElements[element] == 1) or (wave < 30 and usedElements[element] == 2) or usedElements[element] == 3) then
        return getRandomElement(wave)
    else
        usedElements[element] = usedElements[element] + 1
        return element
    end
end


function getRandomElementOrder()
    usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0, ["pure"] = 0}
    local elementsOrder = {}
    local startingElements = {}
    local lumber = GameSettings.length.Lumber

    if EXPRESS_MODE then
        elementsOrder[0] = startingElements
        for i = 0, lumber - 1 do
            startingElements[i] = getRandomElement(0)
        end
        for i = 3, 27, 3 do
            local element = getRandomElement(i)
            elementsOrder[i] = element
        end
    else
        elementsOrder[0] = startingElements
        for i = 0, lumber - 1 do
            startingElements[i] = getRandomElement(0)
        end
        for i = 5, 50, 5 do
            local element = getRandomElement(i)
            elementsOrder[i] = element
        end
    end
    return elementsOrder
end

-- This creates a valid random sequence for an individual player to use in self-random (aka AllRandom) mode
function GetRandomElementForPlayerWave(playerID, wave, bExpress)    
    local playerData = GetPlayerData(playerID)
    if not playerData.elementsOrder then
        playerData.elementsOrder = getRandomElementOrder()
    end

    local order = playerData.elementsOrder

    for waveNumber,element in pairs(order) do
        if waveNumber == wave then
            if type(element)=="table" then
                if bExpress then
                    return order[waveNumber][1]
                else
                    return order[waveNumber][0]
                end
            else
                return order[waveNumber]
            end
        end
    end

    -- If it reaches here, we couldn't return anything, return one at random
    Log:warn("Error when assigning a Random element to player "..playerID.." from wave "..wave.."!")
    return GetRandomElementForWave(playerID, wave)
end

function GetRandomElementForWave(playerID, wave)
    local playerData = GetPlayerData(playerID)
    usedElements = {["water"] = playerData.elements["water"], ["fire"] = playerData.elements["fire"], ["earth"] = playerData.elements["earth"], ["nature"] = playerData.elements["nature"], ["dark"] = playerData.elements["dark"], ["light"] = playerData.elements["light"], ["pure"] = playerData.pureEssenceTotal}

    local element = getRandomElement(wave)

    return element
end