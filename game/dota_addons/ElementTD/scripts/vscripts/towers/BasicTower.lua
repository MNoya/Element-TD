-- Basic Tower class
BasicTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "BasicTower"
	},
nil);

-- triggered when a normal attack lands
-- called from datadriven abilities, see the composite_passive spell
function BasicTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	damage = ApplyAttackDamageFromModifiers(damage, self.tower);
	DamageEntity(target, self.tower, damage);
end

function BasicTower:OnCreated() end

RegisterTowerClass(BasicTower, BasicTower.className);