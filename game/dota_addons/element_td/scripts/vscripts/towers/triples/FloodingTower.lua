-- Flooding ( Water + Darkness + Nature )
-- Attack puts a buff at the point of impact. The buff does 120/600/3000 damage a second in a 400 AoE (full damage)
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
    local position = target:GetAbsOrigin() + Vector(0, 0, 64)

    -- Initial attack aoe
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, Vector(self.fullAOE, 0, 1))
    ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0))
    DamageEntitiesInArea(position, self.fullAOE, self.tower, self.damage)

    -- Repeat the effect for the duration
    local hits = self.duration
    Timers:CreateTimer(1, function()
        if hits > 0 then
            hits = hits - 1

            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide.vpcf", PATTACH_ABSORIGIN, self.tower)
            ParticleManager:SetParticleControl(particle, 0, position)
            ParticleManager:SetParticleControl(particle, 1, Vector(self.fullAOE, 0, 1))
            ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0))
            DamageEntitiesInArea(position, self.fullAOE, self.tower, self.damage)

            return 1
        end
    end)
end

function FloodingTower:OnCreated()
    self.ability = AddAbility(self.tower, "flooding_tower_flood")
    self.damage = GetAbilitySpecialValue("flooding_tower_flood", "splash_damage")[self.tower:GetLevel()]
    self.duration = GetAbilitySpecialValue("flooding_tower_flood", "duration")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.tower.no_autoattack_damage = true

    print(self.damage, self.duration, self.fullAOE)
end

RegisterTowerClass(FloodingTower, FloodingTower.className)