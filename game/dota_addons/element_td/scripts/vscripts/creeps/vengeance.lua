-- Vengeance Creep class
-- Classic: 10, 17, 24, 29, 34, 42, 49

CreepVengeance = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepVengeance"
    },
CreepBasic);

function CreepVengeance:OnDeath(killer) 
    local creep = self.creep
    local ability = creep:FindAbilityByName("creep_ability_vengeance")
    local duration = ability:GetSpecialValueFor("duration")
    local aoe = ability:GetSpecialValueFor("aoe")
    local damage_reduction = ability:GetSpecialValueFor("damage_reduction")

    local enemy_towers = FindUnitsInRadius(creep:GetTeamNumber(), killer:GetAbsOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for _,tower in pairs(enemy_towers) do       
        local modifier = tower:FindModifierByName("modifier_vengeance_debuff")
        if not modifier then
            ability:ApplyDataDrivenModifier(tower, tower, "modifier_vengeance_debuff", {})
            modifier = tower:FindModifierByName("modifier_vengeance_debuff")
        end
        
        local stackCount = tower:GetModifierStackCount("modifier_vengeance_debuff", tower) + 1      
        if modifier then
            modifier:IncrementStackCount()
            modifier:SetDuration(duration, true)
            modifier.baseDamageReduction = damage_reduction
            modifier.damageReduction = modifier.baseDamageReduction * stackCount
        end

        ability:ApplyDataDrivenModifier(tower, tower, "modifier_vengeance_multiple", {duration=duration})
    end
   
    local particle = ParticleManager:CreateParticle("particles/custom/creeps/vengeance/death.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, killer:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, killer:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 2, Vector(aoe*1.5,1,1))
    ParticleManager:SetParticleControl(particle, 3, Vector(aoe*2,1,1))
end

-- A hidden modifier_vengeance_debuff runs out
function RemoveStack(event)
    local tower = event.target

    if tower:HasModifier("modifier_vengeance_debuff") then
        local stackCount = tower:GetModifierStackCount("modifier_vengeance_debuff", tower) - 1
        local modifier = tower:FindModifierByName("modifier_vengeance_debuff")
        if stackCount <= 0 then
            modifier:Destroy()
        else
            modifier:DecrementStackCount()
        end
        modifier.damageReduction = modifier.baseDamageReduction * stackCount
    end    
end

RegisterCreepClass(CreepVengeance, CreepVengeance.className)
