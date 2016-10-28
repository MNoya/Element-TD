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
function QuakeTower:OnAttack(keys)
    self.attacks = self.attacks + 1    
    if self.attacks == 5 then
        self.attacks = 0    
        self.tower:EmitSound("Quake.Strike")

        local particle = ParticleManager:CreateParticle("particles/custom/towers/quake/shockwave.vpcf", PATTACH_ABSORIGIN, self.tower)
        ParticleManager:SetParticleControl(particle, 0, self.tower:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, Vector(self.aoe,1,1))

        local pulverizeDamage = ApplyAbilityDamageFromModifiers(self.aoeDamage, self.tower)
        local creeps = GetCreepsInArea(self.tower:GetOrigin(), self.aoe)
        for _, v in pairs(creeps) do
            if v:IsAlive() then
                DamageEntity(v, self.tower, (pulverizeDamage + (self.pct * 0.01 * v:GetHealth()))) 
            end
        end
    else
        Timers:CreateTimer(0.1, function()
            self.tower:EmitSound("Quake.Attack")
        end)
    end
end

function QuakeTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)
end

function QuakeTower:OnCreated()
    self.ability = AddAbility(self.tower, "quake_tower_pulverize", self.tower:GetLevel())
    self.attacks = 0
    self.aoeDamage = GetAbilitySpecialValue("quake_tower_pulverize", "damage")[self.tower:GetLevel()]
    self.aoe = GetAbilitySpecialValue("quake_tower_pulverize", "aoe")
    self.pct = GetAbilitySpecialValue("quake_tower_pulverize", "pct")[self.tower:GetLevel()]
    AddAnimationTranslate(self.tower, "enchant_totem")
end

RegisterTowerClass(QuakeTower, QuakeTower.className)