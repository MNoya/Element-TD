---------------------------------------------------------------------------
if not ElementTD then
    _G.ElementTD = class({})
end
---------------------------------------------------------------------------

local requires =
{
    -- libraries
    "libraries/timers",
    "libraries/popups",
    "libraries/notifications",
    "libraries/buildinghelper",

    -- mechanics
    "mechanics/selection",
    "mechanics/messages",
    "mechanics/keyvalues",

    -- utils
    "util/util",
    "util/class",
    "util/log",

    -- tower blueprints
    "towers/GlobalCasterDummy",
    "towers/TowersManager",
    "towers/towerevents",
    "towers/BasicTower",
    "towers/BasicTowerAOE",
    "towers/CannonTower",

    -- dual towers
    "towers/duals/MagicTower",
    "towers/duals/DiseaseTower",
    "towers/duals/MushroomTower",
    "towers/duals/LifeTower",
    "towers/duals/WellTower",
    "towers/duals/BlacksmithTower",
    "towers/duals/QuarkTower",
    "towers/duals/ElectricityTower",
    "towers/duals/FlameTower",
    "towers/duals/VaporTower",
    "towers/duals/PoisonTower",
    "towers/duals/HydroTower",
    "towers/duals/TrickeryTower",
    "towers/duals/GunpowderTower",
    "towers/duals/IceTower",

    -- triple towers
    "towers/triples/MuckTower",
    "towers/triples/GoldTower",
    "towers/triples/WindstormTower",
    "towers/triples/QuakeTower",
    "towers/triples/EnchantmentTower",
    "towers/triples/FloodingTower",
    "towers/triples/LaserTower",
    "towers/triples/HailTower",
    "towers/triples/RunicTower",
    "towers/triples/ImpulseTower",
    "towers/triples/ObliterationTower",
    "towers/triples/EphemeralTower",
    "towers/triples/FlamethrowerTower",
    "towers/triples/HasteTower",
    "towers/triples/TorrentTower",
    "towers/triples/NovaTower",
    "towers/triples/PolarTower",
    "towers/triples/JinxTower",
    "towers/triples/RootsTower",
    "towers/triples/ErosionTower",

    -- creep classes
    "creeps/basic",
    "creeps/creepevents",
    "creeps/mechanical",
    "creeps/undead",
    "creeps/heal",
    "creeps/fast",
    "creeps/image",
    "creeps/swarm",

    -- misc
    "wave",
    "voting",
    "interest",
    "gamesettings",
    "summoner",
    "constants",
    "wavedata",
    "elements",
    "spells",
    "towergrid",
    "playerdata",
    "developer",
    "ElementTD",
    "scoring",
}

for _, r in pairs(requires) do
    require(r)
end

function Precache(context)
    local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    local precache = LoadKeyValues("scripts/kv/precache.kv")

    for k, a in pairs(precache) do
        for _, v in pairs(a) do
            if k == "unit" then
                PrecacheUnitByNameAsync(v, function(...) end)
            else
                PrecacheResource(k, v, context)
            end
        end
    end

    for k, v in pairs(units) do
        PrecacheUnitByNameAsync(k, function(...) end)
    end
end

function Activate()
    
    Log:SetLogLevel(TRACE)
    
    ElementTD:InitGameMode()
end

