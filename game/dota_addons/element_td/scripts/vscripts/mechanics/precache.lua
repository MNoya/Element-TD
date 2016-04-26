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
    if not waveNumber then return end

    if not Precache.waves[waveNumber] then
        Log:info("Loading wave number "..waveNumber)
        Precache.waves[waveNumber] = true
        Precache:Load(WAVE_CREEPS[waveNumber])

        -- Check if this wave should also load towers
        local load_waves = Precache.file["Async"]["load_waves"]
        local load = load_waves["Classic"]
        if EXPRESS_MODE then load = load_waves["Express"] end
        if COOP_MAP then load = load_waves["Coop"] end

        local tower_wave_load = load[tostring(waveNumber+1)] --Check one wave in preparation
        if tower_wave_load then
            for tower_type,level in pairs(tower_wave_load) do
                if tower_type=="singles" then
                    ElementTD:PrecacheSingles(level)
                elseif tower_type=="duals" then
                    ElementTD:PrecacheDuals(level)
                elseif tower_type=="triples" then
                    ElementTD:PrecacheTriples(level)
                end
            end
        end
    end
end

-- Loads lvl 1 duals and lvl 1 triples, just in case
function ElementTD:ExpressPrecache(delay)
    delay = delay or 15
    ElementTD:PrecacheDuals(1)
    Timers:CreateTimer(delay, function()
        ElementTD:PrecacheTriples(1)
    end)
end

function ElementTD:PrecacheSingles(level)
    local singles = Precache.file["Async"]["singles"]
    local load = singles[tostring(level)]
    Log:info("Loading singles level "..level)
    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheDuals(level)
    local duals = Precache.file["Async"]["duals"]
    local load = duals[tostring(level)]
    Log:info("Loading duals level "..level)
    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheTriples(level)
    local triples = Precache.file["Async"]["triples"]
    local load = triples[tostring(level)]
    Log:info("Loading triples level "..level)
    ElementTD:PrecacheTowerTable(load)
end

function ElementTD:PrecacheTowerTable(table)
    local len = tablelength(table)
    local time_per_entry = 0.3
    local i = 0

    for towerName,_ in pairs(table) do
        if not Precache.towers[towerName] then
            Timers:CreateTimer(i*time_per_entry, function()
                Precache.towers[towerName] = true
                Precache:Load(towerName)
            end)
            i = i+1
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