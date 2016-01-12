-- constants.lua
-- manages the initialization of constant values, such as spawn locations

if not SpawnLocations then
	SpawnLocations = {} -- array of vectors of the 8 player spawn locations
	EntityStartLocations = {}
	EntityEndLocations = {} -- array of the start and end locations for each player sector
	EntityEndEntities = {} 
	ElementalSummonerLocations = {} -- array of positions for elemental summoners
	SectorBounds = {}
end

function GenerateAllConstants()
	generateElementalSummonerLocations()
	generateSectorBounds()
	generateSpawnLocations()
	generateEntityLocations()
end

function generateElementalSummonerLocations()
	local defX = -6528
	local defY = 4352
	local defZ = 512
	local xIncr = 4096 -- distance between spawns on the x axis
	local yIncr = -5120 -- distance between spawns on the y axis

	for i = 1, 4, 1 do
		ElementalSummonerLocations[i] = Vector(defX + (xIncr * (i - 1)), defY, defZ)
		ElementalSummonerLocations[i + 4] = Vector(defX + (xIncr * (i - 1)), defY + yIncr, defZ)
	end
end

function generateSectorBounds()
	local defX = -8192
	local defY = 5120
	local xIncr = 4096 -- distance between spawns on the x axis
	local yIncr = -5120 -- distance between spawns on the y axis

	for i = 1, 4, 1 do
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

-- Generate spawn location data
function generateSpawnLocations()
	local defX = -6144 -- x-coord of the top-left spawn
	local defY = 2432 -- y-coord of the top-left spawn
	local defZ = 384 -- z-coord of the top-left spawn
	local xIncr = 4096 -- distance between spawns on the x axis
	local yIncr = -5120 -- distance between spawns on the y axis

	for i = 1, 4, 1 do
		SpawnLocations[i] = Vector(defX + (xIncr * (i - 1)), defY, defZ)
		SpawnLocations[i + 4] = Vector(defX + (xIncr * (i - 1)), defY + yIncr, defZ)
	end
end

function generateEntityLocations()
	local defX = -6912 -- x-coord of the top-left spawn
	local defY = 3968 + 300 -- y-coord of the top-left spawn
	local defZ =  0 -- z-coord of the top-left spawn
	local defX2 = -6144 -- x-coord of the top-left endpoint
	local xIncr = 4096
	local yIncr = -5245

	for i = 1, 4, 1 do
		local status, err = pcall(function()
			EntityStartLocations[i] = Vector(defX + (xIncr * (i - 1)), defY, defZ)
			EntityEndLocations[i] = Vector(defX2 + (xIncr * (i - 1)), defY, defZ)
			EntityStartLocations[i + 4] = Vector(defX + (xIncr * (i - 1)), defY + yIncr, defZ)
			EntityEndLocations[i + 4] = Vector(defX2 + (xIncr * (i - 1)), defY + yIncr, defZ)
		end)
		if not status then
			print("ERROR: " .. err)
		end
	end
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------