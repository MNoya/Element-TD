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
	local damage = self.tower:GetAverageTrueAttackDamage()
	DamageEntity(target, self.tower, damage);
end

function BasicTower:OnAttack(keys) end

function BasicTower:OnCreated()
    --self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_OLDER+TOWER_TARGETING_CLOSEST,keep_target=true,change_on_leak=true})
end

RegisterTowerClass(BasicTower, BasicTower.className);