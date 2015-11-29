-- towergrid.lua
-- manages and stores tower location values

offset = 128; --distance in between towers
TowerGrids = {}; -- a table that holds a list of all towers, first by sector, then by grid
				--- EX: TowerGrids[3] is an array of all towergrids in sector 3. There are 8 sectors.

xIncr = 4096; -- distance between sectors on the x axis
yIncr = -5120; -- distance between sectors on the y axis


-- sector:int = which sector this grid is for
-- start:vector = the bottom left position of the grid, should be a tower origin spot
-- width:int = how many towers wide this grid is
-- height:int = how many towers high this grid is
-- this function adds all tile locations to the TowerGrid array for the specified sector
function CreateTowerGrid(sector, start, width, height) 
	local tiles = 0;
	for x = 0, width - 1, 1 do
		for y = 0, height - 1, 1 do
			tiles = tiles + 1;
			local xPos = start.x + (offset * x);
			local yPos = start.y + (offset * y);
			table.insert(TowerGrids[sector], Vector(xPos, yPos, 128));
		end
	end
	--print("Created tower grid with " .. tiles .. " tiles");
end

-- call this when the addon loads to generate all grids automatically, for all sectors
function GenerateAllTowerGrids()
	for i = 1, 4, 1 do
		TowerGrids[i] = {};
		TowerGrids[i + 4] = {};

		CreateTowerGrid(i, Vector(-7360 + (xIncr * (i - 1)), 3902, 128), 2, 2);				--The top left 2x2 square
		CreateTowerGrid(i + 4, Vector(-7360 + (xIncr * (i - 1)), 3902 + yIncr, 128), 2, 2); --

		CreateTowerGrid(i, Vector(-6592 + (xIncr * (i - 1)), 3392, 128), 2, 5);				--The top middle 2x5 rect
		CreateTowerGrid(i + 4, Vector(-6592 + (xIncr * (i - 1)), 3392 + yIncr, 128), 2, 5); --

		CreateTowerGrid(i, Vector(-6976 + (xIncr * (i - 1)), 3136, 128), 14, 2);			 --The middle 14x2 rect
		CreateTowerGrid(i + 4, Vector(-6976 + (xIncr * (i - 1)), 3136 + yIncr, 128), 14, 2); --

		CreateTowerGrid(i, Vector(-6976 + (xIncr * (i - 1)), 2752, 128), 2, 3);				--The middle left 2x3 rect
		CreateTowerGrid(i + 4, Vector(-6976 + (xIncr * (i - 1)), 2752 + yIncr, 128), 2, 3); --

		CreateTowerGrid(i, Vector(-5824 + (xIncr * (i - 1)), 3902, 128), 8, 2);				-- top right 8x2 rect
		CreateTowerGrid(i + 4, Vector(-5824 + (xIncr * (i - 1)), 3902 + yIncr, 128), 8, 2); 

		CreateTowerGrid(i, Vector(-7232 + (xIncr * (i - 1)), 1984, 128), 10, 2);				-- middle left 10x2 rect
		CreateTowerGrid(i + 4, Vector(-7232 + (xIncr * (i - 1)), 1984 + yIncr, 128), 10, 2); 

		CreateTowerGrid(i, Vector(-6208 + (xIncr * (i - 1)), 2240, 128), 2, 3);				-- very middle 2x3 rect
		CreateTowerGrid(i + 4, Vector(-6208 + (xIncr * (i - 1)), 2240 + yIncr, 128), 2, 3); 

		CreateTowerGrid(i, Vector(-6976 + (xIncr * (i - 1)), 1216, 128), 12, 2);			-- bottom 12x2 rect
		CreateTowerGrid(i + 4, Vector(-6976 + (xIncr * (i - 1)), 1216 + yIncr, 128), 12, 2); 

		CreateTowerGrid(i, Vector(-5440 + (xIncr * (i - 1)), 1216, 128), 2, 15);			-- middle 2x15 rect
		CreateTowerGrid(i + 4, Vector(-5440 + (xIncr * (i - 1)), 1216 + yIncr, 128), 2, 15); 
	end
end

-- find the closest tower position in the given sector and position, within maxDist
function FindClosestTowerPosition(sector, pos, maxDist)
	local towerPos = nil;
	for k, v in pairs(TowerGrids[sector]) do
		if not towerPos and dist2D(pos, v) <= maxDist then
			towerPos = v;
		elseif dist2D(pos, v) <= maxDist and dist2D(pos, v) < dist2D(towerPos, pos) then
			towerPos = v;
		end
	end
	return towerPos;
end

-- remove the given tower position from the given sector, to signify that towers can no longer be placed there
function RemoveTowerPosition(sector, pos)
	for k, v in pairs(TowerGrids[sector]) do
		if v.x == pos.x and v.y == pos.y then
			TowerGrids[sector][k] = nil;
			return;
		end
	end
end

-- adds the specified position to the specified sector's tower grid
function AddTowerPosition(sector, pos)
	table.insert(TowerGrids[sector], pos);
end