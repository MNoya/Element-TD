---------------------------------------------------------------------------
if not ElementTD then
    _G.ElementTD = class({})
end
---------------------------------------------------------------------------

require('libraries/timers')
require('libraries/popups')
require('libraries/notifications')
require('libraries/buildinghelper')
require('mechanics/selection')
require('mechanics/messages')

require('util/util')
require('util/class')
require('util/log')
require('commands/commands')

require("towers/GlobalCasterDummy")
require("towers/TowersManager")
require("towers/towerevents")
require("towers/BasicTower")
require("towers/BasicTowerAOE")
require("towers/CannonTower")

-- dual towers
require("towers/duals/MagicTower")
require("towers/duals/DiseaseTower")
require("towers/duals/MushroomTower")
require("towers/duals/LifeTower")
require("towers/duals/WellTower")
require("towers/duals/BlacksmithTower")
require("towers/duals/QuarkTower")
require("towers/duals/ElectricityTower")
require("towers/duals/FlameTower")
require("towers/duals/VaporTower")
require("towers/duals/PoisonTower")
require("towers/duals/HydroTower")
require("towers/duals/TrickeryTower")
require("towers/duals/GunpowderTower")
require("towers/duals/IceTower")

-- triple towers
require("towers/triples/MuckTower")
require("towers/triples/GoldTower")
require("towers/triples/WindstormTower")
require("towers/triples/QuakeTower")
require("towers/triples/EnchantmentTower")
require("towers/triples/FloodingTower")
require("towers/triples/LaserTower")
require("towers/triples/HailTower")
require("towers/triples/RunicTower")
require("towers/triples/ImpulseTower")
require("towers/triples/ObliterationTower")
require("towers/triples/EphemeralTower")
require("towers/triples/FlamethrowerTower")
require("towers/triples/HasteTower")
require("towers/triples/TorrentTower")
require("towers/triples/NovaTower")
require("towers/triples/PolarTower")
require("towers/triples/JinxTower")
require("towers/triples/RootsTower")
require("towers/triples/ErosionTower")

-- creep classes
require("creeps/basic")
require("creeps/creepevents")
require("creeps/mechanical")
require("creeps/undead")
require("creeps/heal")
require("creeps/fast")
require("creeps/image")
require("creeps/swarm")

require('wave')
require('voting')
require('interest')
require('gamesettings')
require('summoner')
require('constants')
require('wavedata')
require('elements')
require('spells')
require('towergrid')
require('playerdata')
require('ElementTD')

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

