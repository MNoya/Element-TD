-- Laser (Darkness + Earth + Light)
-- This is a single target tower that does very high damage. The more creeps there are in an AoE around the target, the less damage this tower does to that target. 
-- So damage dealt is Base - X*Number of additional creeps. There should be a cap on damage loss. This tower is ideal for creeps that are moving alone.
LaserTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "LaserTower"
	},
nil);

function LaserTower:OnAttackStart(keys)
	self.dummy:CastAbilityOnTarget(keys.target, self.dummyAbility, 1);
	
	local damage = ApplyAbilityDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
	local creeps = GetCreepsInArea(keys.target:GetOrigin(), self.aoe);
	local creepCount = 0;

	for _, creep in pairs(creeps) do
		if IsValidEntity(creep) and creep:IsAlive() and creep:entindex() ~= keys.target:entindex() then
			creepCount = creepCount + 1;
		end
	end

	local reduction = creepCount * self.damage_reduction;
	if reduction > 0.7 then
		reduction = 0.7;
	end


	damage = damage * (1 - reduction);
	
	CreateTimer(DoUniqueString("LaserDamage"), DURATION, {
		duration = 0.2,
		callback = function()
			DamageEntity(keys.target, self.tower, damage);
		end
	});
end

function LaserTower:OnCreated()
	self.ability = AddAbility(self.tower, "laser_tower_laser", self.tower:GetLevel());
	
	local towerOrigin = self.tower:GetOrigin();
	local dummyOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));

	self.dummy = CreateUnitByName("tower_dummy", dummyOrigin, false, nil, nil, self.tower:GetTeam());
	self.dummy:SetAbsOrigin(dummyOrigin);
	self.dummy:SetOwner(self.tower:GetOwner());
	self.dummy:AddNewModifier(nil, nil, "modifier_invulnerable", {});
	self.dummy.dummyParent = self.tower;
	ApplyDummyPassive(self.dummy);
	
	self.dummyAbility = AddAbility(self.dummy, "laser_tower_laser_effect");
	self.aoe = GetAbilitySpecialValue("laser_tower_laser", "aoe");
	self.damage_reduction = GetAbilitySpecialValue("laser_tower_laser", "damage_reduction") / 100;
end

function LaserTower:OnAttackLanded(keys) end
RegisterTowerClass(LaserTower, LaserTower.className);