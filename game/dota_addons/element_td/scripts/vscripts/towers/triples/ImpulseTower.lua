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

function ImpulseTower:OnAbilityToggle(keys)
    if self.tower:IsAlive() then
        self.tower.toggled = not self.tower.toggled
    end

    if self.tower:HasModifier("modifier_attack_targeting") then
        self.tower:RemoveModifierByName("modifier_attack_targeting")
    end

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {
        target_type = tonumber(keys.target_type), 
        keep_target = tonumber(keys.keep_target)
    })
end

function ImpulseTower:OnAttack(keys)
    keys.caster:EmitSound("Impulse.Attack")
end

function ImpulseTower:GetUpgradeData()
    return { 
        toggle = self.tower.toggled
    }
end

function ImpulseTower:ApplyUpgradeData(data)
    if data.toggle then
        self.tower.toggled = true
        self.ability:ToggleAbility()
    end
end

function ImpulseTower:OnAttackLanded(keys)
    local target = keys.target
    local distance = (self.tower:GetOrigin() - target:GetOrigin()):Length2D()
    local damage = (distance / 1000) * self.damageMult
    damage = ApplyAbilityDamageFromModifiers(damage, self.tower)
    
    if target:IsAlive() then
        PopupNatureDamage(target, math.floor(damage))
    end
    DamageEntity(target, self.tower, damage)
end

function ImpulseTower:OnCreated()
    self.ability = AddAbility(self.tower, "impulse_tower_impetus", self.tower:GetLevel())
    self.damageMult = GetAbilitySpecialValue("impulse_tower_impetus", "multiplier")[self.tower:GetLevel()]
    self.attackRange = tonumber(GetUnitKeyValue(self.towerClass, "AttackRange"))
    
    self:OnAbilityToggle({target_type = TOWER_TARGETING_FARTHEST}) -- set default targeting mode
    self.tower.toggled = false
end

RegisterTowerClass(ImpulseTower, ImpulseTower.className)