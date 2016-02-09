-- Laser (Darkness + Earth + Light)
-- Single target tower that does 6000/30000 damage with 900 range and 1 attack speed.
-- For each additional creep within 500 range of the target, damage will linearly drop by 10% per extra creep. Damage loss is capped at 70%. Damage type is Light.
-- Example is tower shoots creep. There are 3 creeps around the target. Tower does 4200 damage.

LaserTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "LaserTower"
    },
nil)

function LaserTower:OnAttack(keys)
    local damage = self.tower:GetAverageTrueAttackDamage()
    local creeps = GetCreepsInArea(keys.target:GetOrigin(), self.aoe)
    local creepCount = 0

    for _, creep in pairs(creeps) do
        if IsValidEntity(creep) and creep:IsAlive() and creep:entindex() ~= keys.target:entindex() then
            creepCount = creepCount + 1
        end
    end

    local reduction = creepCount * self.damage_reduction
    if reduction > self.damage_reduction_cap then
        reduction = self.damage_reduction_cap
    end

    damage = damage * (1 - reduction)
    PopupLightDamage(self.tower, math.floor(damage))
    DamageEntity(keys.target, self.tower, damage)
end

function LaserTower:OnCreated()
    self.ability = AddAbility(self.tower, "laser_tower_laser", self.tower:GetLevel())
    self.aoe = GetAbilitySpecialValue("laser_tower_laser", "aoe")
    self.damage_reduction = GetAbilitySpecialValue("laser_tower_laser", "damage_reduction") / 100
    self.damage_reduction_cap = GetAbilitySpecialValue("laser_tower_laser", "damage_reduction_cap")
end

function LaserTower:OnAttackLanded(keys) end
RegisterTowerClass(LaserTower, LaserTower.className)