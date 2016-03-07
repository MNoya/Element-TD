-- Quark Tower class (Earth + Light)
-- Tower with single target that gains damage every time it attacks. Does not cap. Damage gain resets upon attacking a different target.
QuarkTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "QuarkTower"
    },
nil)    

function QuarkTower:OnAttackStart(keys)
    local target = keys.target

    if target:entindex() == self.targetEntIndex then
        self.consecutiveAttacks = self.consecutiveAttacks + 1
        if self.consecutiveAttacks > self.maxStacks then
            self.consecutiveAttacks = self.maxStacks
        end

        local attackDamage = self.baseDamage
        local newDamage = attackDamage * math.pow(self.damageIncrease, self.consecutiveAttacks)
        self.tower:SetBaseDamageMax(newDamage)
        self.tower:SetBaseDamageMin(newDamage)
        
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_quantum_beam_indicator", {})    
        self.tower:SetModifierStackCount("modifier_quantum_beam_indicator", self.ability, self.consecutiveAttacks)
    else
        self.targetEntIndex = target:entindex()    
        self.tower:SetBaseDamageMin(self.baseDamage)    
        self.tower:SetBaseDamageMax(self.baseDamage)    
        self.tower:RemoveModifierByName("modifier_quantum_beam_indicator")    
        self.consecutiveAttacks = 0    
    end
end

function QuarkTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetAbsOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetAbsOrigin(), self.fullAOE, self.tower, damage / 2);

    local attacks = self.consecutiveAttacks < 4 and self.consecutiveAttacks or 4
    if attacks > 0 then
        local particleName = "particles/units/heroes/hero_chen/chen_cast_"..attacks..".vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
        PopupLightDamage(self.tower, math.floor(damage))
    end
end

function QuarkTower:OnCreated()
    self.ability = AddAbility(self.tower, "quark_tower_quantum_beam")     
    self.baseDamage = self.tower:GetBaseDamageMax()    
    self.targetEntIndex = 0    
    self.consecutiveAttacks = 0
    self.maxStacks = ability:GetSpecialValueFor("max_stacks")
    self.damageIncrease = 1+tonumber(self.ability:GetSpecialValueFor("bonus_damage"))*0.01
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_HIGHEST_HP, keep_target=true})
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
end

RegisterTowerClass(QuarkTower, QuarkTower.className)    