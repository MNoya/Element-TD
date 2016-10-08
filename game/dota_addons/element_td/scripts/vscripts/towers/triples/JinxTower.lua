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
    target:EmitSound("Jinx.Cast")

    local creeps = GetCreepsInArea(target:GetOrigin(), self.maledictAOE)
    for _, creep in pairs(creeps) do 
        if not creep:HasModifier("modifier_jinx_maledict") then
            self.ability:ApplyDataDrivenModifier(self.tower, creep, "modifier_jinx_maledict", {})
        end
    end
    
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_aoe.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(self.maledictAOE, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle)
end

function JinxTower:OnMaledictApplied(keys)
    local target = keys.target
    target.MaledictData = {
        ["StartingHealth"] = target:GetHealth()
    }
end

function JinxTower:OnMaledictTick(keys)
    local target = keys.target
    local healthLost = target.MaledictData.StartingHealth - target:GetHealth()
    if healthLost > 0 then
        local damage = math.floor((healthLost * (self.damageTakenToDamage / 100)) + 0.5)
        local damage_done = DamageEntity(target, self.tower, damage)
        PopupDarkCriticalDamage(target, damage_done)
    end
end


function JinxTower:OnCreated()
    self.ability = AddAbility(self.tower, "jinx_tower_maledict", self.tower:GetLevel())
    self.maledictAOE = GetAbilitySpecialValue("jinx_tower_maledict", "aoe")
    self.damageTakenToDamage = GetAbilitySpecialValue("jinx_tower_maledict", "damage_taken")[self.tower:GetLevel()]
end

RegisterTowerClass(JinxTower, JinxTower.className)