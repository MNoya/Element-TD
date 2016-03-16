-- Hail (Darkness + Light + Water)
-- This is a long range single target tower. It can automatically activate an ability periodically that gives it multi-shoot. 
--This allows it to attack up to three targets at once doing full damage to each. 
-- Ability lasts a few seconds, and has a few second cooldown. Autocast can be toggled to prevent inopportune casting.

HailTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HailTower"
    },
nil)

function HailTower:OnAttack(keys)
    local target = keys.target
    local caster = keys.caster
    
    self.current_attacks = self.current_attacks + 1
    if self.current_attacks >= self.attacks_required then
        self.current_attacks = 0
        self.tower:EmitSound("Hail.Cast")
        local damage = self.tower:GetAverageTrueAttackDamage()

        local creeps = GetCreepsInArea(self.tower:GetAbsOrigin(), self.findRadius)
        for _, creep in pairs(creeps) do
            if creep:IsAlive() then
                local particle = ParticleManager:CreateParticle(self.particle_name, PATTACH_ABSORIGIN_FOLLOW, self.tower)
                ParticleManager:SetParticleControl(particle, 1, creep:GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(particle)

                DamageEntity(creep, self.tower, damage)
            end
        end
    end 

    self.tower:SetModifierStackCount("modifier_storm_passive", self.tower, self.attacks_required - self.current_attacks)
end

function HailTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function HailTower:ApplyUpgradeData(data)
    if data.current_attacks then
        self.current_attacks = data.current_attacks
        self.tower:SetModifierStackCount("modifier_storm_passive", self.tower, self.attacks_required - self.current_attacks)
    end
end

function HailTower:GetUpgradeData()
    return {
        current_attacks = self.current_attacks
    }
end

function HailTower:OnCreated()
    self.ability = AddAbility(self.tower, "hail_tower_storm")
    self.particle_name = "particles/econ/items/luna/luna_lucent_ti5_gold/luna_lucent_beam_moonfall_gold.vpcf";

    self.attacks_required = self.ability:GetSpecialValueFor("attacks_required")
    self.current_attacks = 0
    self.findRadius = self.tower:GetAttackRange() + self.tower:GetHullRadius()

    self.tower:SetModifierStackCount("modifier_storm_passive", self.tower, self.attacks_required)
end

RegisterTowerClass(HailTower, HailTower.className)