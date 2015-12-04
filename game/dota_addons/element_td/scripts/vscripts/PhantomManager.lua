-- Phantom Unit Manager
-- for the ghost effect when placing towers

PhantomUnitManagers = {};

PhantomUnitManager = class({
	playerID = -1,
	currentAbility = "",
	phantomUnit = nil,
	phantomValidatorUnit = nil,

	constructor = function(self, playerID)
        self.playerID = playerID;
        self.sector = GetPlayerData(playerID).sector;
    end
},	
{}, nil);

function PhantomUnitManager:show(ability, team)
	self.currentAbility = ability:GetAbilityName();
	self:hide(ability);

	local towerClass = GetAbilityKeyValue(self.currentAbility, "OnSpellStart")["RunScript"]["tower"];
	self.phantomUnit = CreateUnitByName(towerClass, Vector(0, 0, 0), false, nil, nil, team);
	self.phantomUnit:AddNewModifier(nil, nil, "modifier_disarmed", {});
	self.phantomUnit:AddNewModifier(nil, nil, "modifier_invulnerable", {});
	self.phantomUnit:AddNewModifier(nil, nil, "modifier_phased", {});

	self.phantomValidatorUnit = CreateUnitByName("etd_phantom_validator", Vector(0, 0, 0), false, nil, nil, team);
	self.phantomValidatorUnit:AddNewModifier(nil, nil, "modifier_disarmed", {});
	self.phantomValidatorUnit:AddNewModifier(nil, nil, "modifier_invulnerable", {});
	self.phantomValidatorUnit:AddNewModifier(nil, nil, "modifier_phased", {});
	
end

function PhantomUnitManager:hide(ability)
	if self.currentAbility == ability:GetAbilityName() then
		if self.phantomUnit then
			UTIL_RemoveImmediate(self.phantomUnit);
			UTIL_RemoveImmediate(self.phantomValidatorUnit);
			self.phantomUnit = nil;
			self.phantomValidatorUnit = nil;
		end
	end
end

function PhantomUnitManager:update(v)
	local sector = self.sector + 1;
	local pos = FindClosestTowerPosition(sector, v, 96);
	local validPos = false;

	if pos then
		validPos = true;
		v = pos;
		v.z = 384;
	end

	if self.phantomUnit then
		self.phantomUnit:SetOrigin(v);
	end

	if self.phantomValidatorUnit then
		self.phantomValidatorUnit:SetOrigin(v + Vector(0, 0, 10));
		if validPos then
			self.phantomValidatorUnit:SetModel("models/tower_validator_green.vmdl");
			
		else
			self.phantomValidatorUnit:SetModel("models/tower_validator_red.vmdl");
		end
	end
end

------------------------------------------
function CreatePhantomUnitManager(playerID)
	PhantomUnitManagers[playerID] = PhantomUnitManager(playerID);
end

function GetPhantomUnitManager(playerID)
	return PhantomUnitManagers[playerID];
end

-- ability selected command
Convars:RegisterCommand("etd_ability_selected", function(cmdname, abilityIndex)
	local player = Convars:GetCommandClient();
	local playerData = GetPlayerData(player:GetPlayerID());
	local abilityName = SpellPages[playerData.page][abilityIndex + 1];
	local ability = player:GetAssignedHero():FindAbilityByName(abilityName);
	
	if IsValidEntity(ability) and abilityName ~= "show_tower_range" then
		--print("Player " .. player:GetPlayerID() .. " pressed ability " .. ability:GetAbilityName());
		GetPhantomUnitManager(player:GetPlayerID()):show(ability, player:GetTeamNumber());
	end

end, "", 0);

-- ability deselected command
Convars:RegisterCommand("etd_ability_deselected", function(cmdname, abilityIndex)
	local player = Convars:GetCommandClient();
	local playerData = GetPlayerData(player:GetPlayerID());
	local abilityName = SpellPages[playerData.page][abilityIndex + 1];
	local ability = player:GetAssignedHero():FindAbilityByName(abilityName);
	
	if IsValidEntity(ability) then
	    --print("Player " .. player:GetPlayerID() .. " deselected ability " .. ability:GetAbilityName());
	    GetPhantomUnitManager(player:GetPlayerID()):hide(ability);
	end

end, "", 0);

Convars:RegisterCommand("etd_update_pos", function(cmdname, x, y, z)
 	local player = Convars:GetCommandClient();
 	local pos = Vector(tonumber(x), tonumber(y), tonumber(z));
 	GetPhantomUnitManager(player:GetPlayerID()):update(pos);
end, "", 0);