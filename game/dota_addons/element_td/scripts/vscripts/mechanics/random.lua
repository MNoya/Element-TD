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
    if COOP_MAP then
        if element ~= "pure" and randomPreventionCoop(usedElements, element) then
            return getRandomElement(wave)
        elseif ((wave < 5 and usedElements[element] == 1) or (wave < 25 and usedElements[element] == 2) or usedElements[element] == 3) then
            return getRandomElement(wave)
        else
            usedElements[element] = usedElements[element] + 1
            return element
        end
    else
        -- express mode
        if EXPRESS_MODE and ((wave < 3 and usedElements[element] == 1) or (wave < 12 and usedElements[element] == 2) or usedElements[element] == 3 ) then
            return getRandomElement(wave)
        -- classic mode
        elseif not EXPRESS_MODE and ((wave < 10 and usedElements[element] == 1) or (wave < 30 and usedElements[element] == 2) or (wave >= 45 and usedElements[element] == 0) or (usedElements[element] == 3)) then
            return getRandomElement(wave)
        else
            --print(wave, element) -- for testing
            usedElements[element] = usedElements[element] + 1
            return element
        end
    end
end
--
-- Limit coop Random to 3 elements
function randomPreventionCoop(used, target)
    if PlayerResource:GetPlayerCount() == 1 then return randomPreventionClassic(used,target) end

    local num = 0
    for k,v in pairs(used) do
        if v > 0 and v ~= "pure" then
            num = num + 1
        end
    end

    return num > 3 and used[target] == 0
end

-- Reduce the chance of getting 6 element random
function randomPreventionClassic(used, target)
    local num = 0
    for k,v in pairs(used) do
        if v > 0 and v ~= "pure" then
            num = num + 1
        end
    end

    if num == 4 and used[target] == 0 then
        return RollPercentage(70)
    elseif num == 5 then
        return RollPercentage(40)
    end
end

function getNumberOfElementsInSequence( seq )
    local t = {}
    for _,value in pairs(seq) do
        if type(value) == "table" then
            for _, value2 in pairs(value) do
                if value2~="pure" and not tableContains(t, value2) then
                    table.insert(t, value2)
                end
            end

        elseif value~="pure" and not tableContains(t, value) then
            table.insert(t, value)
        end
    end
    return #t
end

function testRandom( iterCount )
    print("Generating "..iterCount.." random element sequences:")
    local counts = {}
    for i = 1, iterCount do
        local sequence = getRandomElementOrder()
        local s = ""
        for k,v in pairs(sequence) do
            if k == 0 then
                s = s..sequence[k][0]
                if sequence[k][1] then
                    s = s..","..sequence[k][1]
                end
            else
                s = s..","..v
            end
        end

        local count = getNumberOfElementsInSequence(sequence)
        counts[count] = counts[count] and counts[count] + 1 or 1
    end

    for k,v in pairs(counts) do
        print(k.."-element random sequences: "..v.." ("..math.floor(v/iterCount*100).."%)")
    end
end
--testRandom(10)

function testRandomRoll( iterCount)
    print("Generating "..iterCount.." random orders:")
    local counts = {}
    for i = 1, iterCount do
        local order = getRandomElementOrder()
        DeepPrintTable(usedElements)
    end
end
--testRandomRoll(5)

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

