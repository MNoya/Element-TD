-- Quintinity's EntityUtils

EntityUtils = {};

function EntityUtils:Load() 
	EntityUtils.unitKeyValues = {
		[1] = LoadKeyValues("scripts/npc/npc_units.txt"), 
		[2] = LoadKeyValues("scripts/npc/npc_units_custom.txt"), 
		[3] = LoadKeyValues("scripts/npc/npc_heroes.txt")
	};
	print("[EntityUtils] Loading finished");
end

function EntityUtils:Fix(entity)
	local entityKV, found = nil, false;
	for i = 1, #EntityUtils.unitKeyValues, 1 do
		if found then break end
		for k,v in pairs(EntityUtils.unitKeyValues[i]) do
			if k == entity:GetUnitName() then
				entityKV = v;
				found = true;
				break;
			end
		end
	end

	if not entityKV then
		print("[EntityUtils] Unable to load kv for " .. entity:GetUnitName());
		return;
	end

	entity.baseModelScale = tonumber(entityKV["ModelScale"]);
	entity.modelScale = entity.baseModelScale;
	----------------------------------
	function entity:GetBaseModelScale()
		return entity.baseModelScale;
	end

	function entity:GetModelScale()
		return entity.modelScale;
	end

	function entity:SetActualModelScale(scale, time)
		time = time or 0;
		local origScale = entity:GetModelScale();

		if time <= 0 then
			entity.modelScale = scale;
			entity:SetModelScale(scale);
		else
			local loops, totalLoops = 0, time / 0.05;
			local incr = (scale - origScale) / totalLoops;
			entity:SetContextThink("ScaleModel", function()
				entity.modelScale = entity.modelScale + incr;
				entity:SetModelScale(entity.modelScale);
				loops = loops + 1;
				if loops == totalLoops then
					return nil;
				end
				return 0.05;
			end, 0.05);
		end
	end
	-----------------------------------------
end