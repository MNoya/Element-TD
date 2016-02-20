if not Precache then
    Precache = class({})
end

function Precache:Start()
    Precache.waves = {}
    Precache.towers = {}
    Precache.file = LoadKeyValues("scripts/kv/precache.kv")
end

function Precache:Load(unitName)
    PrecacheUnitByNameAsync(unitName, function(...) end)
end

function ElementTD:PrecacheWave(waveNumber)
    if not Precache.waves[waveNumber] then
        Precache.waves[waveNumber] = true

        Precache:Load(WAVE_CREEPS[waveNumber])
    end
end

function ElementTD:PrecacheBasics(number, level)
    local basics = Precache.file["Async"]["basics"]
    local load = basics[tostring(level)]

    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheDuals(number, level)
    local duals = Precache.file["Async"]["duals"]
    local load = duals[tostring(level)]

    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheTriples(number, level)
    local triples = Precache.file["Async"]["triples"]
    local load = triples[tostring(level)]

    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheTowerTable(table)
    for towerName,_ in pairs(table) do
        if not Precache.towers[towerName] then
            Precache.towers[towerName] = true

            Precache:Load(towerName)
        end
    end
end

-----------------------------------------------------------------------------------
-- Deprecated method, might be the cause for loading crashes if executed too early
function ElementTD:PerformAsyncPrecache()
    -- We have at least 30 seconds to load units&towers here
    local time = 30
    local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    local num_units = tablelength(units)
    local batch = math.ceil(num_units/time)
    local current_batch = 0
    Log:info("Loading "..num_units.." units, "..batch.." every seconds")

    for i=1,time do
        Timers:CreateTimer(i, function()
            local counter = 0
            for k,v in pairs(units) do
                if counter >= current_batch then
                    if counter < current_batch + batch then
                        PrecacheUnitByNameAsync(k, function(...) end)
                    end
                end
                counter = counter + 1
            end
            current_batch = current_batch + batch
        end)
    end
end

if not Precache.waves then Precache:Start() end