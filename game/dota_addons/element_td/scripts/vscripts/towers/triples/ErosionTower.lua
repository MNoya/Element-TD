-- Erosion (Darkness + Fire + Water)
-- This is a support tower. It has a multi-shoot that hits all creeps in an area around the target (i.e. it's splash but looks fancy). 
-- Creeps hit are buffed. Buff increases damage taken by X%. It also does X damage per second. Buff lasts X seconds. 
-- Buff can stack for damage over time but not for the damage increase.

ErosionTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "ErosionTower";
    },
nil);

function ErosionTower:OnDamageAmpExpire(keys)
    if keys.target:IsAlive() then
        RemoveDamageAmpModifierFromCreep(keys.target, self.modifierName);
        self.debuffedCreeps[keys.target:entindex()] = nil;
    end
end

function ErosionTower:OnAcidDot(keys)
    DamageEntity(keys.target, self.tower, self.dotDamage);
end

function ErosionTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = self.tower:GetBaseDamageMax();
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);

    local entities = GetCreepsInArea(target:GetOrigin(), self.halfAOE);
    for _,e in pairs(entities) do
         AddDamageAmpModifierToCreep(e, self.modifierName, self.damageAmp);
         self.debuffedCreeps[e:entindex()] = 1;
    end
end

function ErosionTower:OnCreated()
    self.modifierName = "modifier_acid_attack_damage_amp";
    self.debuffedCreeps = {};
    self.ability = AddAbility(self.tower, "erosion_tower_acid_attack", self.tower:GetLevel());
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.dotDamage = GetAbilitySpecialValue("erosion_tower_acid_attack", "dot")[self.tower:GetLevel()];
    self.damageAmp = GetAbilitySpecialValue("erosion_tower_acid_attack", "damage_amp")[self.tower:GetLevel()];
end

function ErosionTower:OnAttackStart(keys)
    local target = keys.target;
    local creeps = GetCreepsInArea(target:GetOrigin(), self.fullAOE);
    for _, creep in pairs(creeps) do
        if creep:IsAlive() and creep:entindex() ~= target:entindex() then
            self.tower:PerformAttack(creep, false, false, true, true);
        end
    end
end

function ErosionTower:OnDestroyed()
    for id,_ in pairs(self.debuffedCreeps) do
        local creep = EntIndexToHScript(id);
        if creep and IsValidEntity(creep) and creep:IsAlive() then
            creep:RemoveModifierByName(self.modifierName);
            RemoveDamageAmpModifierFromCreep(creep, self.modifierName);
        end
    end
end

RegisterTowerClass(ErosionTower, ErosionTower.className);