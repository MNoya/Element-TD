GameSettingsKV = LoadKeyValues("scripts/kv/gamesettings.kv");

DifficultyObject = createClass({
		constructor = function(self, difficultyName)
			self.difficultyName = difficultyName;
			self.data = GameSettingsKV.Difficulty[self.difficultyName];
		end
	},
{}, nil);

function DifficultyObject:GetBountyForWave(wave)
	return math.floor(math.pow(self.data.BaseBounty, wave - 1));
end

function DifficultyObject:GetWaveBreakTime(wave)
	local times = self.data.WaveTimers;
	for k, v in pairs(times) do
		local startNum = split(k, "-")[1];
		local endNum = split(k, "-")[2];
		if wave >= tonumber(startNum) and wave <= tonumber(endNum) then
			return v;
		end
	end
	Log:warn("Invalid wave number: " .. wave);
	return 0;
end

function DifficultyObject:GetHealthMultiplier()
	return tonumber(self.data.Health);
end

function DifficultyObject:GetArmorValue()
	return tonumber(self.data.Armor);
end





-- gamesettings.lua
-- manages custom games settings such as difficulty, gamemodes, creep order, and game length

GameSettings = {};
GameSettings.__index = GameSettings;
GameSettings.order = "Normal";
GameSettings.length = "";
GameSettings.elements = "";

DIFFICULTY_OBJECTS = {};
for df,_ in pairs(GameSettingsKV.Difficulty) do
	DIFFICULTY_OBJECTS[df] = DifficultyObject(df);
end

function GameSettings:SetDifficulty(playerID, difficulty)
	local playerData = GetPlayerData(playerID);
	playerData.difficulty = DIFFICULTY_OBJECTS[difficulty];
	Log:info("Set " .. GetPlayerName(playerID) .. "'s difficulty to " .. difficulty);
end


function GameSettings:GetGameLength()
	return GameSettings.length;
end

function GameSettings:SetGameLength(length)
	GameSettings.length = GameSettingsKV["GameLength"][length];
	if not GameSettings.length then
		Log:warn("Attempted to set unknown game length: " .. length .. ". Defaulting to Normal");
		GameSettings:SetGameLength("Normal");
		return;
	end
	for _,ply in pairs(players) do
		local playerID = ply:GetPlayerID();
		local playerData = GetPlayerData(playerID);
		local hero = ply:GetAssignedHero();

		hero:SetGold(0, false);
		hero:SetGold(GameSettings.length.Gold, true);
		ModifyLumber(playerID, GameSettings.length.Lumber);
		playerData.nextWave = GameSettings.length.Wave;

		if length == "Developer" then
			for e,_ in pairs(playerData.elements) do
				ModifyElementValue(playerID, e, 1);
			end
			DEV_MODE = true;
		end
	end
	Log:info("Set game length to " .. length);
end

function GameSettings:SetCreepOrder(order)
	if order ~= "Normal" and order ~= "Chaos" then
		Log:warn("Attempted to set invalid creep order: " .. order .. ". Defaulting to Normal");
		GameSettings:SetCreepOrder("Normal");
	else
		GameSettings.order = order;
		loadWaveData(order == "Chaos");
	end
end

local usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0};
local elements = {"water", "fire", "earth", "nature", "dark", "light"};
function getRandomElement(wave)
	local element = elements[math.random(#elements)];

	if (wave < 15 and usedElements[element] == 1) or (wave < 35 and usedElements[element] == 2) or usedElements[element] == 3 then
		return getRandomElement(wave);
	else
		usedElements[element] = usedElements[element] + 1;
		return element;
	end
end

function GameSettings:SetElementOrder(order)
	local randomseed = string.gsub(GetSystemTime(), ":", "") .. string.gsub(GetSystemDate(), "/", "");
	math.randomseed(tonumber(randomseed));
	math.random(); math.random(); math.random();

	GameSettings.elementsOrderName = order;
	GameSettings.elements = GameSettingsKV["ElementModes"][order];
	

	--same random, all players get the same element order
	if order == "SameRandom" then
		usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0};
		local elementsOrder = {};

		for i = 5, 55, 5 do
			local element = getRandomElement(i);
			print("[" .. i .. "] " .. element);
			elementsOrder[i] = element;
		end

		for _, player in pairs(players) do    
			print("Order for " .. GetPlayerName(player:GetPlayerID()));
			PrintTable(elementsOrder);
            GetPlayerData(player:GetPlayerID()).elementsOrder = elementsOrder;
        end

	--all random, all players their own element order
	elseif order == "AllRandom" then
		for _, player in pairs(players) do    
			usedElements = {["water"] = 0, ["fire"] = 0, ["earth"] = 0, ["nature"] = 0, ["dark"] = 0, ["light"] = 0};
			local elementsOrder = {};

			for i = 5, 55, 5 do
				local element = getRandomElement(i);
				--print("[" .. i .. "] " .. element);
				elementsOrder[i] = element;
			end

			print("Order for " .. GetPlayerName(player:GetPlayerID()));
			PrintTable(elementsOrder);
            GetPlayerData(player:GetPlayerID()).elementsOrder = elementsOrder;
        end
	end
end




----------------------------------------------------
----------------------------------------------------
----------------------------------------------------
