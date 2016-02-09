-- Hydro Tower class (Water + Earth)
-- Single target tower that does 200/1000/5000 damage with 700 range and 1 attack speed.
-- Each attack has a 33% to mark the target with an effect. 1.5 seconds after being marked, the effect does 200/1000/5000 damage in 250 (full damage) AoE. 
-- Creep can be marked again if already marked. 

HydroTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HydroTower"
    },
nil)

function HydroTower:OnAttackLanded(keys)
    local caster = keys.caster
    local target = keys.target

    if RollPercentage(self.chance) then
        self.ability:ApplyDataDrivenModifier(caster, target, "modifier_hydro_delay", {duration=self.delay})
    end

    Timers:CreateTimer(function()
        local damage = ApplyAbilityDamageFromModifiers(self.splashDamage, self.tower)
        DamageEntity(target, self.tower, damage)
    end)
end

function HydroTower:OnDelayEnd(keys)
    local target = keys.target
    local damage = ApplyAbilityDamageFromModifiers(self.splashDamage, self.tower)
    DamageEntitiesInArea(target:GetAbsOrigin(), self.splashAOE, self.tower, damage)

    local torrent = ParticleManager:CreateParticle("particles/custom/towers/hydro/torrent_splash.vpcf", PATTACH_CUSTOMORIGIN, self.tower)
    ParticleManager:SetParticleControl(torrent, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(torrent, 1, target:GetAbsOrigin())
end

function HydroTower:OnCreated()
    self.ability = AddAbility(self.tower, "hydro_tower_ability")
    self.splashDamage = self.ability:GetLevelSpecialValueFor("splash_damage", self.ability:GetLevel() - 1)
    self.splashAOE = GetAbilitySpecialValue("hydro_tower_ability", "splash_aoe")
    self.chance = GetAbilitySpecialValue("hydro_tower_ability", "chance_pct")
    self.delay = GetAbilitySpecialValue("hydro_tower_ability", "delay")
end

RegisterTowerClass(HydroTower, HydroTower.className)