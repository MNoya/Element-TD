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
    local origin = target:GetAbsOrigin()

    local flooding = CreateUnitByName("tower_dummy", origin + Vector(0, 0, 64), false, nil, nil, self.tower:GetTeamNumber())    
    flooding:SetAbsOrigin(origin + Vector(0, 0, 64))
    flooding:AddNewModifier(flooding, nil, "modifier_out_of_world", {})
    flooding:AddNewModifier(flodding, nil, "modifier_no_health_bar", {})

    self.ability:ApplyDataDrivenModifier(self.tower, flooding, "modifier_flood", {})

    Timers:CreateTimer(self.duration + 1, function()
        UTIL_Remove(flooding)
    end)
end

function FloodingTower:OnFloodDot(keys)

    local target = keys.target

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(self.fullAOE, 0, 1))
    ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0))

    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, self.damage)
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