-- Haste (Earth + Fire + Water)
-- Each time this tower attacks it gains X% attack speed. Speed bonus caps out after X attacks. 
-- Speed bonus resets after X seconds of not attacking.
HasteTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HasteTower"
    },
nil)

function HasteTower:ResetAttackSpeed()
    self.tower:RemoveModifierByName("modifier_wrath")
    self.wrathStacks = 0
end

function HasteTower:OnAttack(keys)
    if self.wrathStacks < self.wrathCap then
        self.wrathStacks = self.wrathStacks + 1
    end

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_wrath", {})
    self.tower:SetModifierStackCount("modifier_wrath", self.ability, self.wrathStacks)

    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
    self.timer = Timers:CreateTimer(self.resetTime, function()
        self:ResetAttackSpeed()
    end)
end

function HasteTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower)
    DamageEntity(target, self.tower, damage)
end

function HasteTower:OnCreated()
    self.ability = AddAbility(self.tower, "haste_tower_wrath")
    self.wrathCap = GetAbilitySpecialValue("haste_tower_wrath", "cap")
    self.resetTime = GetAbilitySpecialValue("haste_tower_wrath", "reset_time")
    self.wrathStacks = 0
    self.timer = nil
end

RegisterTowerClass(HasteTower, HasteTower.className)