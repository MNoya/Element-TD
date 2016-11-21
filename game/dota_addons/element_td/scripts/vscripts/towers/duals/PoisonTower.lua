-- Poison Tower class (Water + Dark)
-- This is a splash attack tower. Every fourth attack has a massive splash compared to a normal attack

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
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage(target)

    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2)

    local creeps = GetCreepsInArea(target:GetAbsOrigin(), self.fullAOE)
    for _, creep in pairs(creeps) do
        self.ability:ApplyDataDrivenModifier(self.tower, creep, "modifier_contamination", {})
    end 

end

function PoisonTower:DealContaminationDamage(keys)
    local target = keys.target    
    local damage = ApplyAbilityDamageFromModifiers(self.damage_per_interval, self.tower)    
    DamageEntity(target, self.tower, damage)
end

--[[ Removed in 1.15
function PoisonTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage(target) 
    local attackFullAOE = self.fullAOE
    local attackHalfAOE = self.halfAOE

    self.attacks = self.attacks + 1    
    if self.attacks == 4 then
        self.attacks = 0    
        attackFullAOE = self.fullAOECrit
        attackHalfAOE = self.halfAOECrit
        target:EmitSound("Poison.Strike")

        local fxDuration = 1.5
        local particle = ParticleManager:CreateParticle("particles/custom/towers/poison/nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, Vector(attackFullAOE,fxDuration,attackFullAOE))

        local particleA = ParticleManager:CreateParticle("particles/custom/towers/poison/cast.vpcf", PATTACH_CUSTOMORIGIN, self.tower)    
        ParticleManager:SetParticleControl(particleA, 0, self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_mouth")))

        local damage_done = ApplyElementalDamageModifier(damage, GetDamageType(self.tower), GetArmorType(target))
        PopupDarkCriticalDamage(self.tower, math.floor(damage_done))
    end

    DamageEntitiesInArea(target:GetAbsOrigin(), attackHalfAOE, self.tower, damage / 2)    
    DamageEntitiesInArea(target:GetAbsOrigin(), attackFullAOE, self.tower, damage / 2)    
end
]]

function PoisonTower:OnCreated()
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_HIGHEST_HP})
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.ability = AddAbility(self.tower, "poison_tower_contamination", self.tower:GetLevel())
    self.modifier_name = "modifier_contamination"

    self.interval = 0.5 --taken from the modifier ThinkInterval value
    self.damage_per_interval = self.ability:GetLevelSpecialValueFor("damage_per_second", self.tower:GetLevel()-1) * self.interval


    --[[ Removed in 1.15
    self.attacks = 0
    self.fullAOECrit = GetAbilitySpecialValue("poison_tower_contamination", "crit_aoe_full")
    self.halfAOECrit = GetAbilitySpecialValue("poison_tower_contamination", "crit_aoe_half")
    ]]
end

RegisterTowerClass(PoisonTower, PoisonTower.className)    