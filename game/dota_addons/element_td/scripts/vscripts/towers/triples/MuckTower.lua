-- Muck Tower class (Dark + Earth + Water)
-- This is a a support tower. It has a splash damage attack. All creeps hit by the splash get a buff. Buff slows down movement speed by X%. 
-- Buff does not stack. Buff lasts X seconds.

MuckTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "MuckTower"
    },
nil);

function MuckTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);

    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);
end

function MuckTower:OnCreated()
    self.ability = AddAbility(self.tower, "muck_tower_sludge_passive", self.tower:GetLevel()); 
    self.slowAOE = GetAbilitySpecialValue("muck_tower_sludge_passive", "aoe");
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
end

RegisterTowerClass(MuckTower, MuckTower.className);