-- Flooding (Darkness + Nature + Water)
-- This tower has two abilities. One increases splash radius, the other decreases splash radius. There are four splash increments, from no splash to huge splash. 
-- Larger splash reduces attack speed and vice versa.

FloodingTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "FloodingTower"
	},
nil);

function FloodingTower:ChangeSplash(keys)
	self.splashLevel = self.splashLevel + keys.Amount;
	self.abilityIncrease:SetLevel(self.splashLevel);
	self.abilityDecrease:SetLevel(self.splashLevel);

	if self.splashLevel == 1 then
		self.abilityDecrease:SetActivated(false);
	elseif self.splashLevel == 4 then
		self.abilityIncrease:SetActivated(false);
	else
		self.abilityIncrease:SetActivated(true);
		self.abilityDecrease:SetActivated(true);
	end
	
	self.tower:SetBaseAttackTime(self.batLevels[self.splashLevel]);
end

function FloodingTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
	local aoe = self.splashLevels[self.splashLevel];

	if aoe > 0 then
		DamageEntitiesInArea(target:GetOrigin(), aoe, self.tower, damage / 2)
		DamageEntitiesInArea(target:GetOrigin(), aoe / 2, self.tower, damage / 2)

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide.vpcf", PATTACH_ABSORIGIN, self.tower);
		ParticleManager:SetParticleControl(particle, 0, target:GetOrigin());
		ParticleManager:SetParticleControl(particle, 1, Vector(aoe, 0, 1));
		ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0));

	else
		DamageEntity(target, self.tower, damage);
	end
end

function FloodingTower:OnCreated()
	self.abilityDecrease = AddAbility(self.tower, "flooding_tower_decrease_splash");
	self.abilityIncrease = AddAbility(self.tower, "flooding_tower_increase_splash");

	self.abilityDecrease:SetActivated(false);

	self.splashLevel = 1;
	self.splashLevels = GetAbilitySpecialValue("flooding_tower_increase_splash", "splash_aoe");
	self.batLevels = GetAbilitySpecialValue("flooding_tower_increase_splash", "bat");
end

RegisterTowerClass(FloodingTower, FloodingTower.className);