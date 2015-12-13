-- Quake (Earth + Fire + Nature)
-- This is a single target tower. It has a 50% chance per attack to deal X damage in an area around the tower.

QuakeTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "QuakeTower"
    },
nil)
--
function QuakeTower:OnAttackStart(keys)
    if math.random(100) > self.chance then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_f.vpcf", PATTACH_ABSORIGIN, self.tower)
        ParticleManager:SetParticleControl(particle, 0, self.tower:GetAbsOrigin())

        local pulverizeDamage = ApplyAbilityDamageFromModifiers(self.aoeDamage, self.tower)
        local creeps = GetCreepsInArea(self.tower:GetOrigin(), self.aoe)
        for _, v in pairs(creeps) do
            if v:IsAlive() then
                DamageEntity(v, self.tower, pulverizeDamage)
            end
        end
    end
end

function QuakeTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetBaseDamageMax()
    damage = ApplyAttackDamageFromModifiers(damage, self.tower)
    DamageEntity(target, self.tower, damage)
end

function QuakeTower:OnCreated()
    self.ability = AddAbility(self.tower, "quake_tower_pulverize", self.tower:GetLevel())
    self.chance = GetAbilitySpecialValue("quake_tower_pulverize", "chance")
    self.aoeDamage = GetAbilitySpecialValue("quake_tower_pulverize", "damage")[self.tower:GetLevel()]
    self.aoe = GetAbilitySpecialValue("quake_tower_pulverize", "aoe")
end

RegisterTowerClass(QuakeTower, QuakeTower.className)