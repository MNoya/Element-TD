-- Earth tower class

EarthTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "EarthTower"
    },
nil)

function EarthTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);
end

function EarthTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.ability = AddAbility(self.tower, "earth_tower_ability")
end

RegisterTowerClass(EarthTower, EarthTower.className)
