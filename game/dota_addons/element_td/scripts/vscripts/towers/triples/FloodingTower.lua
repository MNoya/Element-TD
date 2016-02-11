-- Flooding ( Water + Darkness + Nature )
-- Attack puts a buff at the point of impact. The buff does 120/600 damage a second in a 400 AoE (full damage)
-- centerd on the point of impact.
-- It lasts 5 seconds.
-- Single target tower, no damage, 900 range and 0.66 attack speed.
-- Buffs can stack indefinitely

FloodingTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "FloodingTower"
    },
nil)

function FloodingTower:OnAttackLanded(keys)
    local target = keys.target
    local position = target:GetAbsOrigin()

    -- Initial attack aoe
    local particle = ParticleManager:CreateParticle("particles/custom/towers/flooding/riptide.vpcf", PATTACH_ABSORIGIN, self.tower)
    local particleRadius = 250
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, Vector(particleRadius, particleRadius, particleRadius))
    ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0))

    local damage = ApplyAbilityDamageFromModifiers(self.damage, self.tower)
    DamageEntitiesInArea(position, self.fullAOE, self.tower, damage)

    -- Repeat the effect for the duration
    local hits = self.duration
    Timers:CreateTimer(1, function()
        if hits > 0 then
            hits = hits - 1
            DamageEntitiesInArea(position, self.fullAOE, self.tower, damage)

            return 1
        end
    end)
end

function FloodingTower:OnCreated()
    self.ability = AddAbility(self.tower, "flooding_tower_flood", self.tower:GetLevel())
    self.damage = GetAbilitySpecialValue("flooding_tower_flood", "splash_damage")[self.tower:GetLevel()]
    self.duration = GetAbilitySpecialValue("flooding_tower_flood", "duration")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.tower.no_autoattack_damage = true
end

RegisterTowerClass(FloodingTower, FloodingTower.className)