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
    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
    self.currentDamageReduction = 0

    self.tower:RemoveModifierByName("modifier_reset_damage")
    self.tower:RemoveModifierByName("modifier_phasing_stack")

    self.hasAttackThinker = false
end

function EphemeralTower:OnAttack(keys)
    local phasing_base = self.tower:FindModifierByName("modifier_reset_damage")
    local phasing_stack = self.tower:FindModifierByName("modifier_phasing_stack")

    if phasing_base then
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_reset_damage", {})
    elseif phasing_stack then
        self.tower:RemoveModifierByName("modifier_reset_damage")
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_phasing_stack", {})
    elseif not phasing_stack and not phasing_base then
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_reset_damage", {})
    end

    self.lastAttackTime = GameRules:GetGameTime()
    if not self.hasAttackThinker then 
        self.hasAttackThinker = true

        self.timer = Timers:CreateTimer(2, function()
            if IsValidEntity(self.tower) then
                if GameRules:GetGameTime() - self.lastAttackTime <= 2 then
                    if self.currentDamageReduction < self.maxDamageReduction then
                        self.tower:RemoveModifierByName("modifier_reset_damage")
                        local phasing_stack = self.tower:FindModifierByName("modifier_phasing_stack")
                        if phasing_stack == nil then
                            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_phasing_stack", {})
                        end
                        self.currentDamageReduction = self.currentDamageReduction + self.damageReductionPerAttackPercent
                        self.tower:FindModifierByName("modifier_phasing_stack"):IncrementStackCount()
                        if self.currentDamageReduction == self.maxDamageReduction then
                            Timers:CreateTimer(2, function()
                                self:ResetDamage()
                            end)
                        end
                    end
                end
                return 2
            end
        end)

    end
    
    if self.resetTimer ~= nil then
        Timers:RemoveTimer(self.resetTimer)
    end
    self.resetTimer = Timers:CreateTimer(self.resetTime, function()
        self:ResetDamage({})  
    end)
end

function EphemeralTower:OnDestroyed()
    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
end

function EphemeralTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function EphemeralTower:OnCreated()
    self.ability = AddAbility(self.tower, "ephemeral_tower_phasing")
    self.baseDamage = self.tower:GetAverageTrueAttackDamage()

    self.damageReductionPerAttackPercent = math.abs(GetAbilitySpecialValue("ephemeral_tower_phasing", "damage_reduction")) -- 5%
    self.maxDamageReduction = GetAbilitySpecialValue("ephemeral_tower_phasing", "max_reduction")
    self.resetTime = GetAbilitySpecialValue("ephemeral_tower_phasing", "reset_time")

    self.currentDamageReduction = 0
    self.timer = nil
    self.resetTimer = nil
    self.hasAttackThinker = false
    self.lastAttackTime = nil
end

RegisterTowerClass(EphemeralTower, EphemeralTower.className)