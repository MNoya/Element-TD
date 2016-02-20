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
    "libraries/animations",
    "libraries/attachments",
    "libraries/buildinghelper",
    "statcollection/init",

    -- mechanics
    "mechanics/precache",
    "mechanics/selection",
    "mechanics/messages",
    "mechanics/keyvalues",
    "mechanics/items",
    "mechanics/sounds",
    "mechanics/gold",

    -- utils
    "util/util",
    "util/class",
    "util/log",

    -- tower blueprints
    "towers/TowersManager",
    "towers/towerevents",
    "towers/BasicTower",
    "towers/BasicTowerAOE",
    "towers/CannonTower",

    -- dual towers
    "towers/duals/MagicTower",
    "towers/duals/DiseaseTower",
    "towers/duals/MossTower",
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
    "towers/triples/TidalTower",
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
    "creeps/boss",

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
    "playerdata",
    "developer",
    "ElementTD",
    "scoring",
}

for _, r in pairs(requires) do
    require(r)
end

function Precache(context)
    local precache = LoadKeyValues("scripts/kv/precache.kv")

    for k, a in pairs(precache) do
        for _, v in pairs(a) do
            if k == "unit" then
                PrecacheUnitByNameSync(v, context)
            elseif k ~= "Async" then
                PrecacheResource(k, v, context)
            end
        end
    end
end

function Activate()
    Log:SetLogLevel(TRACE)
    ElementTD:InitGameMode()
    ElementTD.HasRunOnce = true
end

if ElementTD.HasRunOnce then
    ElementTD:OnScriptReload()
end