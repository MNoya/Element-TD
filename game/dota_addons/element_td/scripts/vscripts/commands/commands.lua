function OnPlayerChatEvent(text, playerID)
	if DEV_MODE and text:sub(1, 1) == "-" and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		text = text:sub(2, #text);
		if startsWith(text, "spawncreep") then
			SpawnACreep(text, playerID);
		elseif startsWith(text, "pause") then
			TIMERS_PAUSED = true;
			Log:info("Paused all timers");
		elseif startsWith(text, "unpause") then
			TIMERS_PAUSED = false;
			Log:info("Unpaused all timers");
		elseif text == "testtower" then
			TestTower(text, playerID);
		end
		local playerData = GetPlayerData(playerID);
		for e, l in pairs(playerData.elements) do
			if text == e then
				ModifyElementValue(playerID, e, 1);
				break;
			end
		end
	end
end

function TestTower(text, playerID)
	local entity = SpawnEntity("timber_wolf", playerID, PlayerResource:GetPlayer(playerID):GetAssignedHero():GetOrigin());
	if entity then
		CreateTimer("TestTower", INTERVAL, {
	        loops  = -1,
	        interval = 0.3,
	        entity = entity,
	        callback = function(timer)
	            timer.entity:SetBaseDamageMax(2047);
	            timer.entity:SetBaseDamageMin(2047);
	        end
	    });
	end
end

-- -spawncreep <creep_name> [health]
function SpawnACreep(text, playerID)
	local args = split(text, " ");
	local entity;
	if args[2] then
		entity = SpawnEntity(args[2], playerID, PlayerResource:GetPlayer(playerID):GetAssignedHero():GetOrigin());
		RegisterCreep(entity, playerID);
		entity.scriptObject:OnSpawned();
	end
	if args[3] and entity then
		entity:SetMaxHealth(tonumber(args[3]));
		entity:SetHealth(tonumber(args[3]));
	end
end



----------------------------------------
function startsWith(str, strToFind) 
	for i = 1, #str, 1 do
		if str:sub(i, i) ~= strToFind:sub(i, i) then
			return false;
		end
		if i == #strToFind then
			return true;
		end
	end
	return false;
end