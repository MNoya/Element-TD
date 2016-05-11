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

function ErosionTower:OnProjectileHitUnit(keys)
    self:OnAttackLanded({target = keys.target})
end

function ErosionTower:OnAttackLanded(keys)
    local target = keys.target

    self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_acid_attack_damage_amp", {})
    local modifier = target:FindModifierByName("modifier_acid_attack_damage_amp")
    if modifier then
        modifier.damageAmp = self.damageAmp
    end

    self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_acid_attack_dot", {})
    self:OnAcidDot({target=target})
end

function ErosionTower:OnCreated()
    self.ability = AddAbility(self.tower, "erosion_tower_acid_attack", self.tower:GetLevel())
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.dotDamage = GetAbilitySpecialValue("erosion_tower_acid_attack", "dot")[self.tower:GetLevel()]
    self.damageAmp = self.ability:GetLevelSpecialValueFor("damage_amp", self.ability:GetLevel()-1)
end

function ErosionTower:OnAttack(keys)
    local target = keys.target
    local creeps = GetCreepsInArea(target:GetOrigin(), self.fullAOE)
    for _, creep in pairs(creeps) do
        if creep:IsAlive() and creep:entindex() ~= target:entindex() then
            local info = 
            {
                Target = creep,
                Source = self.tower,
                Ability = keys.ability,
                EffectName = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf",
                iMoveSpeed = self.tower:GetProjectileSpeed(),
                vSourceLoc = self.tower:GetAbsOrigin(),
                bReplaceExisting = false,
                flExpireTime = GameRules:GetGameTime() + 10,
            }
            projectile = ProjectileManager:CreateTrackingProjectile(info)
        end
    end
end

RegisterTowerClass(ErosionTower, ErosionTower.className)