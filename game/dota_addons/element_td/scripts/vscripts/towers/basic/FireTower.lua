-- Fire tower class

FireTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "FireTower"
    },
nil)

function FireTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2)


    self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_blazeit", {})
end

function FireTower:DealBlazeDamage(keys)
    local target = keys.target    
    local damage = ApplyAbilityDamageFromModifiers(self.damage_per_interval, self.tower)    
    DamageEntity(target, self.tower, damage)
end

function FireTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.ability = AddAbility(self.tower, "fire_tower_blaze", self.tower:GetLevel())
    self.modifier_name = "modifier_blazeit" --420
    self.interval = 0.5 --taken from the modifier ThinkInterval value
    self.damage_per_interval = self.ability:GetLevelSpecialValueFor("damage_per_second", self.tower:GetLevel()-1) * self.interval

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_CLOSEST})
end

RegisterTowerClass(FireTower, FireTower.className)
