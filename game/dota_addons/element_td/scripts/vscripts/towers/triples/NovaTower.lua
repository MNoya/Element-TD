-- Nova (Fire + Light + Nature)
-- This is a support tower. Every time this tower attacks it does X damage in an area of effect around it. 
-- It also debuffs all creeps hit. Buff slows down movement speed by X%. Debuff does not stack. Debuff lasts X seconds.

NovaTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "NovaTower"
    },
nil)

function NovaTower:Explode()
    if GameRules:GetGameTime() - self.lastExplodeTime > 1 then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf", PATTACH_ABSORIGIN, self.tower)
        ParticleManager:SetParticleControl(particle, 0, self.tower:GetOrigin())
        ParticleManager:SetParticleControl(particle, 1, Vector(0, 0, 0))
        ParticleManager:ReleaseParticleIndex(particle)
        
        DamageEntitiesInArea(self.tower:GetOrigin(), self.aoe, self.tower, self.explodeDamage)
        self.lastExplodeTime = GameRules:GetGameTime()
    end
end

function NovaTower:OnCreated()
    self.ability = AddAbility(self.tower, "nova_tower_explode", self.tower:GetLevel())
    self.explodeDamage = GetAbilitySpecialValue("nova_tower_explode", "damage")[self.tower:GetLevel()]
    self.aoe = GetAbilitySpecialValue("nova_tower_explode", "aoe")
    self.lastExplodeTime = 0
end

function NovaTower:OnAttackLanded(keys) end
RegisterTowerClass(NovaTower, NovaTower.className)