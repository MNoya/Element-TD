-- Magic Tower class (Fire + Dark)
--  Every attack adds 20 range. Max of 30 stacks (+600 range). Resets on 2 seconds of no attack

MagicTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "MagicTower"
    },
nil)

function MagicTower:OnAttack(event)
    local tower = self.tower
    local ability = self.ability
    local modifierName = "modifier_magic_tower_attack_range"

    -- Applying refreshes the modifier
    ability:ApplyDataDrivenModifier(tower, tower, modifierName, {duration=self.duration})

    local stackCount = tower:GetModifierStackCount(modifierName, tower) or 0
    stackCount = stackCount == self.maxStacks and self.maxStacks or (stackCount + 1)

    tower:SetModifierStackCount(modifierName, tower, stackCount)
end

function MagicTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetBaseDamageMax()
    damage = ApplyAttackDamageFromModifiers(damage, self.tower)
    DamageEntity(target, self.tower, self.tower:GetBaseDamageMax())
    if IsCurrentlySelected(self.tower) then
        UpdateSelectedEntities()
    end
end

function OnMagicRangeDestroy(event)
    local tower = event.target
    if IsCurrentlySelected(tower) then
        UpdateSelectedEntities()
    end
end

function MagicTower:OnCreated()
    self.ability = AddAbility(self.tower, "magic_tower_range") 
    self.rangeStacks = 0
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")
    self.duration = self.ability:GetSpecialValueFor("duration")
end

RegisterTowerClass(MagicTower, MagicTower.className)    