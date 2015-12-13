-- Ephemeral Tower (Earth + Nature + Water)
-- This is a single target tower that loses damage over time. Every one second this tower attacks it loses X% damage from the base.
-- There is a cap on damage loss. After X seconds of not attacking damage is reset to full. 
-- Tower has ability that takes X seconds to cast that resets damage to full.
EphemeralTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "EphemeralTower"
    },
nil)

function EphemeralTower:ResetDamage(keys)
    Timers:RemoveTimer(self.timerName)
    self.currentDamageReduction = 0
    self.tower:SetBaseDamageMax(self.baseDamage)
    self.tower:SetBaseDamageMin(self.baseDamage)
    
    if self.particleActive then
        ParticleManager:DestroyParticle(self.particleID, false)
        self.particleActive = false
    end
end

function EphemeralTower:OnAttackStart(keys)
    if not self.particleActive then
        self.particleID = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", PATTACH_ABSORIGIN, self.tower)
        ParticleManager:SetParticleControl(self.particleID, 0, self.tower:GetAbsOrigin() + Vector(0, 0, 16))
        ParticleManager:SetParticleControl(self.particleID, 1, Vector(0, 0, 0))
        ParticleManager:SetParticleControl(self.particleID, 3, Vector(0, 0, 0))
        self.particleActive = true
    end

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_reset_damage", {})

    self.lastAttackTime = GameRules:GetGameTime()
    if not self.hasAttackThinker then 
        self.hasAttackThinker = true

        Timers:CreateTimer(1, function()
            if IsValidEntity(self.tower) then
                if GameRules:GetGameTime() - self.lastAttackTime <= 1 then
                    if self.currentDamageReduction < self.maxDamageReduction then
                        local newDamage    = self.tower:GetBaseDamageMax() - self.damageReductionPerAttack
                        self.tower:SetBaseDamageMax(newDamage)
                        self.tower:SetBaseDamageMin(newDamage)
                        self.currentDamageReduction = self.currentDamageReduction + self.damageReductionPerAttackPercent
                    elseif self.currentDamageReduction >= self.maxDamageReduction then
                        self:ResetDamage()
                    end
                end
                return 1
            end
        end)

    end
    
    Timers:RemoveTimer(self.timerName)
    Timers:CreateTimer(self.timerName, {
        endTime = self.resetTime,
        callback = function()
            self:ResetDamage({})
        end
    })
end

function EphemeralTower:OnDestroyed()
    Timers:RemoveTimer(self.timerName)
end

function EphemeralTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower)
    DamageEntity(target, self.tower, damage)
end

function EphemeralTower:OnCreated()
    self.ability = AddAbility(self.tower, "ephemeral_tower_phasing")
    self.baseDamage = self.tower:GetBaseDamageMax()

    self.damageReductionPerAttackPercent = GetAbilitySpecialValue("ephemeral_tower_phasing", "damage_reduction") -- 5%
    self.maxDamageReduction = GetAbilitySpecialValue("ephemeral_tower_phasing", "max_reduction")
    self.resetTime = GetAbilitySpecialValue("ephemeral_tower_phasing", "reset_time")

    self.currentDamageReduction = 0
    self.damageReductionPerAttack = self.damageReductionPerAttackPercent / 100 * self.baseDamage
    self.timerName = "EphemeralResetDamage" .. self.tower:entindex()
    self.hasAttackThinker = false
    self.lastAttackTime = nil
    self.particleActive = false
end

RegisterTowerClass(EphemeralTower, EphemeralTower.className)