-- Impulse (Fire + Nature + Water)
-- This is a long range tower which deals damage proportional to the distance its projectile travels. 
-- The longer the distance, the more damage.
ImpulseTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "ImpulseTower"
    },
nil)

function ImpulseTower:OnAttackStart(keys)
end

function ImpulseTower:OnAttackLanded(keys)
    local target = keys.target
    local distance = (self.tower:GetOrigin() - target:GetOrigin()):Length2D()
    local damage = (distance / 1000) * self.damageMult
    damage = ApplyAbilityDamageFromModifiers(damage, self.tower)
    
    if target:IsAlive() then
        PopupLightDamage(target, math.floor(damage))
    end
    DamageEntity(target, self.tower, damage)
end

function ImpulseTower:OnCreated()
    self.ability = AddAbility(self.tower, "impulse_tower_impetus", self.tower:GetLevel())
    self.damageMult = GetAbilitySpecialValue("impulse_tower_impetus", "multiplier")[self.tower:GetLevel()]
    self.attackRange = tonumber(GetUnitKeyValue(self.towerClass, "AttackRange"))
end

RegisterTowerClass(ImpulseTower, ImpulseTower.className)