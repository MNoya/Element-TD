function Dynamic_Wrap( mt, name )
    if Convars:GetFloat( 'developer' ) == 1 then
        local function w(...) return mt[name](...); end
        return w;
    else
        return mt[name];
    end
end

function import(script)
    local status, err = pcall(function()
        require(script);
    end);
    if not status then
        print("\n\nERROR: Failed to load script " .. script);
        print(err .. "\n\n");
    end
end

function ImportAllScripts()
    local status, err = pcall(function()
        import('util/util');
        import('util/class');
        import('util/log');
        import('util/popup');
        import('util/entityutils');
        import('commands/commands');
        
        import("towers/GlobalCasterDummy");
        import("towers/TowersManager");
        import("towers/towerevents");
        import("towers/BasicTower");
        import("towers/BasicTowerAOE");
        import("towers/CannonTower");

        -- dual towers
        import("towers/duals/MagicTower");
        import("towers/duals/DiseaseTower");
        import("towers/duals/MushroomTower");
        import("towers/duals/LifeTower");
        import("towers/duals/WellTower");
        import("towers/duals/BlacksmithTower");
        import("towers/duals/QuarkTower");
        import("towers/duals/ElectricityTower");
        import("towers/duals/FlameTower");
        import("towers/duals/VaporTower");
        import("towers/duals/PoisonTower");
        import("towers/duals/HydroTower");
        import("towers/duals/TrickeryTower");
        import("towers/duals/GunpowderTower");
        import("towers/duals/IceTower");

        -- triple towers
        import("towers/triples/MuckTower");
        import("towers/triples/GoldTower");
        import("towers/triples/WindstormTower");
        import("towers/triples/QuakeTower");
        import("towers/triples/EnchantmentTower");
        import("towers/triples/FloodingTower");
        import("towers/triples/LaserTower");
        import("towers/triples/HailTower");
        import("towers/triples/RunicTower");
        import("towers/triples/ImpulseTower");
        import("towers/triples/ObliterationTower");
        import("towers/triples/EphemeralTower");
        import("towers/triples/FlamethrowerTower");
        import("towers/triples/HasteTower");
        import("towers/triples/TorrentTower");
        import("towers/triples/NovaTower");
        import("towers/triples/PolarTower");
        import("towers/triples/JinxTower");
        import("towers/triples/RootsTower");
        import("towers/triples/ErosionTower");

        -- creep classes
        import("creeps/basic");
        import("creeps/creepevents");
        import("creeps/mechanical");
        import("creeps/undead");
        import("creeps/heal");
        import("creeps/fast");
        import("creeps/image");
        
        import("PhantomManager");
        import('wave');
        import('voting');
        import('interest');
        import('gamesettings');
        import('summoner');
    	import('constants');
        import('wavedata');
        import('elements');
        import('spells');
        import('towergrid');
        import('playerdata');
    	import('timers');
    	import('ElementTD');
    end);
end