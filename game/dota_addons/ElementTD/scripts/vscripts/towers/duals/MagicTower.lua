-- Magic Tower class (Fire + Dark)
-- This tower has two abilities. One increases attack range, the other decreases attack range. 
-- There are five range increments, one for every range in the game. Longer range reduces damage and vice versa.
MagicTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "MagicTower"
	},
nil);

function MagicTower:ChangeRange(keys)
	self.rangeLevel = self.rangeLevel + tonumber(keys.Amount);
	self.increaseRangeAbility:SetLevel(self.rangeLevel);
	self.decreaseRangeAbility:SetLevel(self.rangeLevel);
	local newDamage = self.baseDamage - (self.baseDamage * (self.damageReduction[self.rangeLevel] / 100));
	self.tower:SetBaseDamageMin(newDamage);
	self.tower:SetBaseDamageMax(newDamage);
	
	if self.rangeLevel == 1 then
		self.decreaseRangeAbility:SetActivated(false);
		self.increaseRangeAbility:SetActivated(true);
	elseif self.rangeLevel == 5 then
		self.decreaseRangeAbility:SetActivated(true);
		self.increaseRangeAbility:SetActivated(false);
	else
		self.decreaseRangeAbility:SetActivated(true);
		self.increaseRangeAbility:SetActivated(true);
	end
end

function MagicTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	damage = ApplyAttackDamageFromModifiers(damage, self.tower);
	DamageEntity(target, self.tower, self.tower:GetBaseDamageMax());
end

function MagicTower:OnCreated()
	self.decreaseRangeAbility = AddAbility(self.tower, "magic_tower_decrease_range");
	self.increaseRangeAbility = AddAbility(self.tower, "magic_tower_increase_range");
	self.decreaseRangeAbility:SetActivated(false);

	self.rangeLevel = 1;
	self.baseDamage = self.tower:GetBaseDamageMax();
	self.baseRange = self.tower:GetAttackRange();

	self.damageReduction = GetAbilitySpecialValue("magic_tower_increase_range", "damage_reduction");
end

RegisterTowerClass(MagicTower, MagicTower.className);