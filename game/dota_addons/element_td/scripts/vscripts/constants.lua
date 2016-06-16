-- constants.lua
-- manages the initialization of constant values, such as spawn locations

CreepsClass = "npc_dota_creep_neutral" -- all creeps have this baseclass

DamageModifiers = {
    composite = {
        --100% to all
    },
    fire = {
        nature = 2.0,
        water = 0.5,
        composite = 0.9
    },
    water = {
        fire = 2.0,
        dark = 0.5,
        composite = 0.9
    },
    nature = {
        earth = 2.0,
        fire = 0.5,
        composite = 0.9
    },
    earth = {
        light = 2.0,
        nature = 0.5,
        composite = 0.9
    },
    light = {
        dark = 2.0,
        earth = 0.5,
        composite = 0.9
    },
    dark = {
        water = 2.0,
        light = 0.5,
        composite = 0.9
    }
}

ElementColors = {
    composite = {255, 255, 255}, water = {1, 162, 255}, fire = {196, 0, 0}, nature = {0, 196, 0},
    earth = {212, 136, 15}, light = {229, 222, 35}, dark = {132, 51, 200}
}

-- Water #01A2FF
-- Fire #C40000
-- Nature #00C400
-- Earth #D4880F
-- Light #E5DE23
-- Dark #8733C8

ElementalBaseHealth = {600, 3000, 15000}
Particles = {
    light_elemental = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf",
}

ExplosionParticles = {
    water = "particles/custom/elements/water/explosion.vpcf",
    fire = "particles/custom/elements/fire/explosion.vpcf",
    nature = "particles/custom/elements/nature/explosion.vpcf",
    earth = "particles/custom/elements/earth/explosion.vpcf",
    light = "particles/custom/elements/light/explosion.vpcf",
    dark = "particles/custom/elements/dark/explosion.vpcf",
}

TrailParticles = {
    water = "particles/econ/items/lion/fish_stick/fish_stick_spell_ambient.vpcf",
    fire = "particles/econ/courier/courier_trail_lava/courier_trail_lava.vpcf",
    nature = "particles/custom/elements/nature/courier_greevil_green_ambient_3.vpcf",
    earth = "particles/custom/elements/earth/trail.vpcf",
    light = "particles/econ/courier/courier_trail_05/courier_trail_05.vpcf",
    dark = "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf",
}

ElementalSounds = {
    water_spawn = "Hero_Morphling.Replicate",
    water_death = "Hero_Morphling.Waveform",

    fire_spawn = "Ability.LightStrikeArray",
    fire_death = "Hero_Lina.DragonSlave",

    nature_spawn = "Hero_Furion.Teleport_Appear",
    nature_death = "Hero_Furion.TreantSpawn",

    earth_spawn = "Ability.TossImpact",
    earth_death = "Ability.Avalanche",

    light_spawn = "Hero_KeeperOfTheLight.ChakraMagic.Target",
    light_death = "Hero_KeeperOfTheLight.BlindingLight",

    dark_spawn = "Hero_Nevermore.RequiemOfSouls",
    dark_death = "Hero_Nevermore.Shadowraze",

    --[[water = "morphling_mrph_",
    water_S = 8,
    water_D = 12,
    fire = "lina_lina_",
    fire_S = 9,
    fire_D = 12,
    nature = "furion_furi_",
    nature_S = 3,
    nature_D = 11,
    earth = "tiny_tiny_",
    earth_S = 9,
    earth_D = 13,
    light = "keeper_of_the_light_keep_",
    light_S = 5,
    light_D = 15,
    dark = "nevermore_nev_",
    dark_S = 11,
    dark_D = 19,--]]
}


if not SpawnLocations then
    SpawnLocations = {} -- array of vectors of the 8 player spawn locations
    EntityStartLocations = {}
    EntityEndLocations = {} -- array of the start and end locations for each player sector
    EntityEndEntities = {} 
    ElementalSummonerLocations = {} -- array of positions for elemental summoners
    SectorBounds = {}
    SectorPortals = {}
end

function GenerateAllConstants()
    generateElementalSummonerLocations()
    generateSectorBounds()
    generateSpawnLocations()
    generateEntityLocations()
    generateSectorPortals()
    generateTowersNetTable()
end

function generateElementalSummonerLocations()
    for i = 1, 8 do
        local summoner = Entities:FindByName(nil, "summoner_"..i)
        if summoner then
            ElementalSummonerLocations[i] = summoner:GetAbsOrigin()
        end
    end
end

function generateSectorBounds()
    if COOP_MAP then
        CoopBounds = {
            left = -4000,
            right = 4000,
            top = 4000,
            bottom = -4000
        }
        return
    end

    local defX = -8192
    local defY = 5120
    local xIncr = 4096 -- distance between spawns on the x axis
    local yIncr = -5120 -- distance between spawns on the y axis

    for i=1,4 do
        SectorBounds[i] = {
            left = defX + (xIncr * (i - 1)),
            right = defX + (xIncr * i),
            top = defY,
            bottom = defY + yIncr
        }
        SectorBounds[i + 4] = {
            left = defX + (xIncr * (i - 1)),
            right = defX + (xIncr * i),
            top = defY + yIncr,
            bottom = defY + (yIncr * 2)
        }
    end
end

function generateSectorPortals()
    for i = 1, 8 do
        SectorPortals[i] = Entities:FindByName(nil, "portal_" .. i)
    end
end

function generateTowersNetTable()
    for unitName,values in pairs(NPC_UNITS_CUSTOM) do
        local AOE_Full = values["AOE_Full"]
        local AOE_Half = values["AOE_Half"]
        if AOE_Full then
            CustomNetTables:SetTableValue("towers", unitName, { AOE_Full = AOE_Full, AOE_Half = AOE_Half })
        end
    end
end

-- Generate spawn location data
function generateSpawnLocations()
    for i=1,8 do
        local spawn = Entities:FindByName(nil, "spawn_"..i)
        if spawn then
            SpawnLocations[i] = spawn:GetAbsOrigin()
        end
    end
end

function generateEntityLocations()
    for i=1,8 do
        local start_location = Entities:FindByName(nil, "start_location_"..i)
        local end_location = Entities:FindByName(nil, "end_location_"..i)

        if start_location then
            if end_location then
                EntityStartLocations[i] = start_location:GetAbsOrigin()
                EntityEndLocations[i] = end_location:GetAbsOrigin()
            else
                print("ERROR: Start Location "..i.." has no end!")
            end
        end
    end
end

function GetElementColor(element)
    return Vector(ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
end

function GetSoundNumber( max )
    local rand = math.random(max)
    local str = ""
    str = string.format("%02d", rand)
    return str
end


-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------