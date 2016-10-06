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
    self.tower:SetBaseAttackTime(self.startingBAT)
    self.soundEnable = true
    if self.particleMax then
        ParticleManager:DestroyParticle(self.particleMax, true)
        self.particleMax = nil
    end
end

function HasteTower:OnAttack(keys)
    self.tower:EmitSound("Haste.Attack")
    if self.wrathStacks < self.wrathCap then
        self.wrathStacks = self.wrathStacks + 1
    elseif self.soundEnable then
        self.soundEnable = false
        self.tower:EmitSound("Haste.Max")
        self.particleMax = ParticleManager:CreateParticle("particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf", PATTACH_ABSORIGIN, self.tower)
    end

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_wrath", {})
    self.tower:SetModifierStackCount("modifier_wrath", self.ability, self.wrathStacks)
    self.tower:SetBaseAttackTime(self.startingBAT - self.batStack * self.wrathStacks)

    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
    self.timer = Timers:CreateTimer(self.resetTime, function()
        self:ResetAttackSpeed()
    end)
end

function HasteTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)
end

function HasteTower:OnCreated()
    self.ability = AddAbility(self.tower, "haste_tower_wrath")
    self.wrathCap = GetAbilitySpecialValue("haste_tower_wrath", "cap")
    self.resetTime = GetAbilitySpecialValue("haste_tower_wrath", "reset_time")
    self.batStack = GetAbilitySpecialValue("haste_tower_wrath", "bat_decrease_stack")
    self.wrathStacks = 0
    self.timer = nil
    self.soundEnable = true
    self.startingBAT = self.tower:GetBaseAttackTime()
end

RegisterTowerClass(HasteTower, HasteTower.className)