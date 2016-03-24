-- Fire tower class

FireTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "FireTower"
    },
nil)

function FireTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);
end

function FireTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.ability = AddAbility(self.tower, "fire_tower_blaze")
end

RegisterTowerClass(FireTower, FireTower.className)
