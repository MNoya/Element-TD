-- Quark Tower class (Earth + Light)
-- Tower with single target that gains damage every time it attacks. Does not cap. Damage gain resets upon attacking a different target.
QuarkTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "QuarkTower"
	},
nil);

function QuarkTower:OnAttackStart(keys)
	local target = keys.target;
	local damageIncrease = tonumber(self.ability:GetSpecialValueFor("bonus_damage"));
	if target:entindex() == self.targetEntIndex then
		local newDamage = self.tower:GetBaseDamageMax() + (self.tower:GetBaseDamageMax() * (damageIncrease / 100));
		self.tower:SetBaseDamageMax(newDamage);
		self.tower:SetBaseDamageMin(newDamage);
		self.consecutiveAttacks = self.consecutiveAttacks + 1;
		
		self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_quantum_beam_indicator", {});
		self.tower:SetModifierStackCount("modifier_quantum_beam_indicator", self.ability, self.consecutiveAttacks);

	else
		self.targetEntIndex = target:entindex();
		self.tower:SetBaseDamageMin(self.baseDamage);
		self.tower:SetBaseDamageMax(self.baseDamage);
		self.tower:RemoveModifierByName("modifier_quantum_beam_indicator");
		self.consecutiveAttacks = 0;
	end
end

function QuarkTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	damage = ApplyAttackDamageFromModifiers(damage, self.tower);
	DamageEntity(target, self.tower, damage);
end

function QuarkTower:OnCreated()
	self.ability = AddAbility(self.tower, "quark_tower_quantum_beam"); 
	self.baseDamage = self.tower:GetBaseDamageMax();
	self.targetEntIndex = 0;
	self.consecutiveAttacks = 0;
end

RegisterTowerClass(QuarkTower, QuarkTower.className);