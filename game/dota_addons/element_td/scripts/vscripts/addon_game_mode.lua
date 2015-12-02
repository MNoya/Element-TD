function Activate()
	ImportAllScripts();
	Log:SetLogLevel(TRACE);
	
	local addon = ElementTD:new();
	addon:InitGameMode();
end

function Kappa() end

function Precache(context)
	local units = LoadKeyValues("scripts/npc/npc_units_custom.txt");
	local precache = LoadKeyValues("scripts/kv/precache.kv");

	for _type, a in pairs(precache) do
		for _, v in pairs(a) do
			if _type == "unit" then
				PrecacheUnitByNameAsync(v, Kappa);
			else
				PrecacheResource(_type, v, context)
			end
		end
	end

	for k, v in pairs(units) do
		PrecacheUnitByNameAsync(k, Kappa);
	end

	--PrecacheResource("particle", "particles/nova/phoenix_supernova_reborn.vpcf", context);
end