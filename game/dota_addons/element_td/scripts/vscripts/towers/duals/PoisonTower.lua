-- Poison Tower class (Water + Dark)
-- This is a splash attack tower. Every third attack this tower does massive damage compared to its base. So it goes normal attack, normal attack, super attack, normal attack etc..
-- Super attack should Base*X damage.

PoisonTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "PoisonTower"
    },
nil)    

function PoisonTower:OnAttackLanded(keys)
    self.attacks = self.attacks + 1    
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage() 
    local AOE = self.halfAOE

    if self.attacks == 4 then
        damage = damage * (self.damageMultiplier / 100)    
        self.attacks = 0    
        AOE = 300

        target:EmitSound("Poison.Strike")

        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_venomousgale_explosion_flash_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())

        local particleA = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_ward_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.tower)    
        ParticleManager:SetParticleControl(particleA, 0, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
        ParticleManager:SetParticleControl(particleA, 1, self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_hitloc")))

        local damage_done = ApplyElementalDamageModifier(damage, GetDamageType(self.tower), GetArmorType(target))
        PopupDarkCriticalDamage(self.tower, math.floor(damage_done))
    end

    DamageEntitiesInArea(target:GetAbsOrigin(), AOE, self.tower, damage / 2)    
    DamageEntitiesInArea(target:GetAbsOrigin(), AOE / 2, self.tower, damage / 2)    
end

function PoisonTower:OnCreated()
    AddAbility(self.tower, "poison_tower_contamination")
    self.attacks = 0
    self.damageMultiplier = GetAbilitySpecialValue("poison_tower_contamination", "damage_mult")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
end

RegisterTowerClass(PoisonTower, PoisonTower.className)    