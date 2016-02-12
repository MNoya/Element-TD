-- Basic Tower AOE class, for towers that do simple splash damage
BasicTowerAOE = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "BasicTowerAOE"
	},
nil);

function BasicTowerAOE:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetAverageTrueAttackDamage()
	DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
	DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);
end

function BasicTowerAOE:OnAttack(keys) end

function BasicTowerAOE:OnCreated()
	self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
	self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
end

RegisterTowerClass(BasicTowerAOE, BasicTowerAOE.className);