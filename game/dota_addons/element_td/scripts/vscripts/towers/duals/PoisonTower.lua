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
    local fullDamageAOE = self.fullAOE    

    if self.attacks == 3 then
        damage = damage * (self.damageMultiplier / 100)    
        self.attacks = 0    
        fullDamageAOE = 200

        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_venomousgale_explosion_flash_b.vpcf", PATTACH_ABSORIGIN, target)    
        ParticleManager:SetParticleControl(particle, 0, Vector(0, 0, 0))
        ParticleManager:SetParticleControl(particle, 3, target:GetOrigin())

        local particleA = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_ward_cast.vpcf", PATTACH_ABSORIGIN, self.tower)    
        ParticleManager:SetParticleControl(particleA, 0, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
        ParticleManager:SetParticleControl(particleA, 1, self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_hitloc")))

        PopupGreenCriticalDamage(self.tower, damage)
    end
    damage = ApplyAttackDamageFromModifiers(damage, self.tower)

    DamageEntitiesInArea(target:GetOrigin(), fullDamageAOE, self.tower, damage / 2)    
    DamageEntitiesInArea(target:GetOrigin(), fullDamageAOE / 2, self.tower, damage / 2)    
end

function PoisonTower:OnCreated()
    AddAbility(self.tower, "poison_tower_contamination")
    self.attacks = 0
    self.damageMultiplier = GetAbilitySpecialValue("poison_tower_contamination", "damage_mult")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
end

RegisterTowerClass(PoisonTower, PoisonTower.className)    