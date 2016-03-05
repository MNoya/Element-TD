-- Well Tower class (Nature + Water)
-- This is a support tower. It has an autocast ability which increases the speed (by a percentage) of non-support towers (this distinction is important). 
-- Autocast prefers targets with higher value (i.e. more powerful towers first).

WellTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "WellTower"
    },
nil)

-- the thinker function for the well_tower_spring_forward spell
function WellTower:SpringForwardThink()
    if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() and self.tower:GetHealthPercent() == 100 then
        
        -- find out the tower with the best BuffPriority to apply the buff
        local target = GetBuffTargetInRadius(self.tower, self.castRange, "modifier_spring_forward", self.level)

        if target then
            self.tower:CastAbilityOnTarget(target, self.ability, self.playerID)
        end
    end
end

function WellTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function WellTower:OnCreated()
    self.ability = AddAbility(self.tower, "well_tower_spring_forward", GetUnitKeyValue(self.towerClass, "Level"))
    self.castRange = self.ability:GetCastRange(self.tower:GetAbsOrigin(), self.tower)
    self.level = self.ability:GetLevel()
    self.ability:ToggleAutoCast() -- turn on autocast by default
    self.playerID = self.tower:GetOwner():GetPlayerID()
end

function WellTower:OnBuildingFinished()
    Timers:CreateTimer(math.random(0.03,0.2), function()
        if IsValidEntity(self.tower) then
            self:SpringForwardThink()
            return 1
        end
    end)
end

function WellTower:ApplyUpgradeData(data)
    if data.cooldown and data.cooldown > 1 then
        self.ability:StartCooldown(data.cooldown)
    end
    if data.autocast == false then
        self.ability:ToggleAutoCast()
    end
end

function WellTower:GetUpgradeData()
    return {
        cooldown = self.ability:GetCooldownTimeRemaining(), 
        autocast = self.ability:GetAutoCastState()
    }
end

RegisterTowerClass(WellTower, WellTower.className)