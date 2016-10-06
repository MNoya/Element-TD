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
    local location = target:GetAbsOrigin()
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntitiesInArea(location, self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(location, self.fullAOE, self.tower, damage / 2);

    Timers:CreateTimer(self.aftershockDelay, function()
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_death_rocks_b.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(particle, 0, location)

        local aftershockDamage = damage * self.aftershockDamage
        DamageEntitiesInArea(location, self.halfAOE, self.tower, aftershockDamage / 2);
        DamageEntitiesInArea(location, self.fullAOE, self.tower, aftershockDamage / 2);
    end)
end

--[[Old stun prevention
    local time = GameRules:GetGameTime()
    if not target.earth_tower_stun or time >= target.earth_tower_stun+self.threshold_duration then
        self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_earth_tower_stun", {duration=self.ministun_duration})
        target.earth_tower_stun = GameRules:GetGameTime()
    end
]]

function EarthTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.ability = AddAbility(self.tower, "earth_tower_aftershock")
    self.aftershockDamage = self.ability:GetSpecialValueFor("aftershock_damage_pct") * 0.01
    self.aftershockDelay = self.ability:GetSpecialValueFor("aftershock_delay")

    --self.ministun_duration = self.ability:GetSpecialValueFor("ministun_duration")
    --self.threshold_duration = 0.9
end

RegisterTowerClass(EarthTower, EarthTower.className)
