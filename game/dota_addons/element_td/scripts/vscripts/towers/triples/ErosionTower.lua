-- Erosion (Darkness + Fire + Water)
-- This is a support tower. It has a multi-shoot that hits all creeps in an area around the target (i.e. it's splash but looks fancy). 
-- Creeps hit are buffed. Buff increases damage taken by X%. It also does X damage per second. Buff lasts X seconds. 
-- Buff can stack for damage over time but not for the damage increase.

ErosionTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "ErosionTower"
    },
nil)

function ErosionTower:OnAcidDot(keys)
    local damage = ApplyAbilityDamageFromModifiers(self.dotDamage, self.tower)
    DamageEntity(keys.target, self.tower, damage)
end

function ErosionTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2)

    local entities = GetCreepsInArea(target:GetAbsOrigin(), self.halfAOE)
    for _,e in pairs(entities) do
        self.ability:ApplyDataDrivenModifier(self.tower, e, "modifier_acid_attack_damage_amp", {})
        local modifier = e:FindModifierByName("modifier_acid_attack_damage_amp")
        if modifier then
            modifier.damageAmp = self.damageAmp
        end
    end
end

function ErosionTower:OnCreated()
    self.modifierName = "modifier_acid_attack_damage_amp"
    self.ability = AddAbility(self.tower, "erosion_tower_acid_attack", self.tower:GetLevel())
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.dotDamage = GetAbilitySpecialValue("erosion_tower_acid_attack", "dot")[self.tower:GetLevel()]
    self.damageAmp = self.ability:GetLevelSpecialValueFor("damage_amp", self.ability:GetLevel()-1)
end

function ErosionTower:OnAttackStart(keys)
    local target = keys.target
    local creeps = GetCreepsInArea(target:GetOrigin(), self.fullAOE)
    for _, creep in pairs(creeps) do
        if creep:IsAlive() and creep:entindex() ~= target:entindex() then
            self.tower:PerformAttack(creep, false, false, true, true, true)
        end
    end
end

RegisterTowerClass(ErosionTower, ErosionTower.className)