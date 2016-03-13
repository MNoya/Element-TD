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
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)

    -- Refresh selection
    if PlayerResource:IsUnitSelected(self.playerID, self.tower) then
        local stacks = self.tower:GetModifierStackCount("modifier_magic_tower_attack_range", self.tower)
        if stacks ~= self.maxStacks then
            Selection:Refresh()
        end
    end
end

function OnMagicRangeDestroy(event)
    local tower = event.target
    if PlayerResource:IsUnitSelected(tower:GetPlayerOwnerID(), tower) then
        Selection:Refresh()
    end
end

function MagicTower:OnCreated()
    self.ability = AddAbility(self.tower, "magic_tower_range") 
    self.rangeStacks = 0
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")
    self.duration = self.ability:GetSpecialValueFor("duration")
    self.playerID = self.tower:GetPlayerOwnerID()
end

RegisterTowerClass(MagicTower, MagicTower.className)    