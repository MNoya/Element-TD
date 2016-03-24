-- Light tower class

LightTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "LightTower"
    },
nil)

function LightTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage);
end

function LightTower:OnCreated()
    self.ability = AddAbility(self.tower, "light_tower_intensity")
end

RegisterTowerClass(LightTower, LightTower.className)
