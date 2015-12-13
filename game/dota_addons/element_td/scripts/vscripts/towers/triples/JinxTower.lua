-- Jinx (Darkness + Fire + Nature)
-- This is a support tower. It has a splash attack which buffs creeps hit. Buff does X% of damage taken since being buffed initially (i.e. compares current HP to start HP). 
-- This happens every X/3 seconds. Buff lasts for X seconds. It may be helpful to think of this as Maledict from DotA.

JinxTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "JinxTower"
    },
nil)

function JinxTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetBaseDamageMax()
    DamageEntity(target, self.tower, damage)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_aoe.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(300, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle)
end

function JinxTower:OnMaledictApplied(keys)
    local target = keys.target
    target.MaledictData = {
        ["StartingHealth"] = target:GetHealth()
    }
    print("Starting Maledict at " .. target:GetHealth() .. " health. Time: " .. GameRules:GetGameTime())
end

function JinxTower:OnMaledictTick(keys)
    local target = keys.target
    local healthLost = target.MaledictData.StartingHealth - target:GetHealth()
    print("Maledict tick, lost " .. healthLost .. " health. Time: " .. GameRules:GetGameTime())
    if healthLost > 0 then
        local damage = math.floor((healthLost * (self.damageTakenToDamage / 100)) + 0.5)
        DamageEntity(target, self.tower, damage)
        print("Dealing " .. damage .. " damage")
    end
end


function JinxTower:OnCreated()
    self.ability = AddAbility(self.tower, "jinx_tower_maledict", self.tower:GetLevel())
    self.damageTakenToDamage = GetAbilitySpecialValue("jinx_tower_maledict", "damage_taken")[self.tower:GetLevel()]

    local p1 = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(p1, 2, self.tower:GetOrigin() + Vector(0, 0, 80))
    ParticleManager:SetParticleControl(p1, 0, Vector(0, 0, 0))

    local p2 = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_deathward_glow_b.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(p2, 2, self.tower:GetOrigin() + Vector(0, 0, 80))
    ParticleManager:SetParticleControl(p2, 0, Vector(0, 0, 0))
end

RegisterTowerClass(JinxTower, JinxTower.className)