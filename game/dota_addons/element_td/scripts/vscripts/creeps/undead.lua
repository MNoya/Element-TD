-- Undead Creep class

CreepUndead = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
			self.creep = creep;
			self.creepClass = creepClass or self.creepClass
		end
	},
	{
		className = "CreepUndead"
	},
CreepBasic);

function CreepUndead:OnSpawned() 
	self.creep:SetMaximumGoldBounty(0);
	self.creep:SetMinimumGoldBounty(0);
end

function CreepUndead:OnDeath()
	local creep = self.creep;
	local playerID = creep.playerID;
	local creepClass = self.creepClass;

	local newCreep = CreateUnitByName(creepClass, creep:GetAbsOrigin() , false, nil, nil, DOTA_TEAM_NOTEAM);
	newCreep.class = creepClass;
	newCreep.playerID = creep.playerID;
	newCreep.waveObject = creep.waveObject;
	creep.waveObject:RegisterCreep(newCreep:entindex());
	creep.waveObject.creepsRemaining = creep.waveObject.creepsRemaining + 1 -- Increment creep count
	newCreep:AddNewModifier(newCreep, nil, "modifier_phased", {});
	newCreep:AddNewModifier(newCreep, nil, "modifier_invulnerable", {});
	newCreep:AddNewModifier(newCreep, nil, "modifier_invisible", {});
	if newCreep:HasModifier("creep_undead_reanimate") then
		newCreep:RemoveAbility("creep_undead_reanimate"); --don't allow this new creep to respawn
	end
	newCreep:SetMaxHealth(creep:GetMaxHealth());
	newCreep:SetBaseMaxHealth(creep:GetMaxHealth());
	newCreep:SetForwardVector(creep:GetForwardVector())
	creep.scriptObject = self;

	newCreep:SetContextThink("RespawnThinker", function()
		self:UndeadCreepRespawn()
		return nil;
	end, 3);

	self.creep = newCreep;
	CREEP_SCRIPT_OBJECTS[newCreep:entindex()] = self;
end

function CreepUndead:UndeadCreepRespawn()
	local creep = self.creep;
	local playerID = creep.playerID;
	local playerData = GetPlayerData(playerID);
	local wave = creep.waveObject:GetWaveNumber();
	local creepClass = WAVE_CREEPS[wave];

	creep:RemoveAbility("creep_ability_undead");
	creep:RemoveModifierByName("modifier_invisible");
	creep:RemoveModifierByName("modifier_invulnerable");

	creep:SetMaximumGoldBounty(GetPlayerDifficulty(playerID):GetBountyForWave(wave));
	creep:SetMinimumGoldBounty(GetPlayerDifficulty(playerID):GetBountyForWave(wave));

	creep:SetHealth(creep:GetMaxHealth() * 0.5); -- it spawns at a percentage of its max health
	CreateMoveTimerForCreep(creep, playerData.sector + 1); --create a timer for this creep so it continues walking to the destination

	local h = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_reincarnation.vpcf", 2, creep); --play a cool particle effect :D
	ParticleManager:SetParticleControlEnt(h, 0, creep, 5, "attach_hitloc", creep:GetOrigin(), true);
end

RegisterCreepClass(CreepUndead, CreepUndead.className);