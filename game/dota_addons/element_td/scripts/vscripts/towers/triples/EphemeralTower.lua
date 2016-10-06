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

    if self.tower.upgraded then
        return
    end

    self.current_stacks = 0

    self.tower:RemoveModifierByName("modifier_reset_damage")
    self.tower:RemoveModifierByName("modifier_phasing_stack")

    self.hasAttackThinker = false
end

function EphemeralTower:OnAttack(keys)
    local phasing_stack = self.tower:FindModifierByName("modifier_phasing_stack")

    local stacks

    -- At max stack count, stop counting
    if phasing_stack then
        stacks = phasing_stack:GetStackCount()
        if stacks == self.maxStacks then
            return
        end
    end

    if phasing_stack and self.lastAttackTime and GameRules:GetGameTime() - self.lastAttackTime <= 2 then
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_phasing_stack", {})
    end

    self.lastAttackTime = GameRules:GetGameTime()

    if not self.hasAttackThinker then 
        self.hasAttackThinker = true

        self.timer = Timers:CreateTimer(1, function()
            if IsValidEntity(self.tower) then
                if GameRules:GetGameTime() - self.lastAttackTime <= 2 then

                    if self.current_stacks < self.maxStacks then                        
                        local phasing_stack = self.tower:FindModifierByName("modifier_phasing_stack")
                        if not phasing_stack then
                            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_phasing_stack", {})
                        end
                        self.current_stacks = self.current_stacks + 1
                        self.tower:SetModifierStackCount("modifier_phasing_stack", self.tower, self.current_stacks)
                    end
                end
                return 1
            end
        end)
    end
end

function EphemeralTower:OnDestroyed()
    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
end

function EphemeralTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)
end

function EphemeralTower:ApplyUpgradeData(data)
    if data.current_stacks then
        self.current_stacks = data.current_stacks
        local phasing_stack = self.tower:FindModifierByName("modifier_phasing_stack")
        if not phasing_stack then
            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_phasing_stack", {})
        end
        self.tower:SetModifierStackCount("modifier_phasing_stack", self.tower, self.current_stacks)
    end
end

function EphemeralTower:GetUpgradeData()
    return {
        current_stacks = self.current_stacks
    }
end

function EphemeralTower:OnCreated()
    self.ability = AddAbility(self.tower, "ephemeral_tower_phasing")
    self.baseDamage = self.tower:GetAverageTrueAttackDamage(target)
    self.maxDamageReduction = GetAbilitySpecialValue("ephemeral_tower_phasing", "max_reduction")
    self.damageReductionPerAttackPercent = math.abs(GetAbilitySpecialValue("ephemeral_tower_phasing", "damage_reduction"))
    self.maxStacks = math.floor(self.maxDamageReduction/self.damageReductionPerAttackPercent)

    self.current_stacks = 0
    self.timer = nil
    self.hasAttackThinker = false
    self.lastAttackTime = nil
end

RegisterTowerClass(EphemeralTower, EphemeralTower.className)