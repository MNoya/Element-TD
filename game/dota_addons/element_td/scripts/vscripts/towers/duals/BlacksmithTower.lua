-- Blacksmith Tower class (Fire + Earth)
-- This is a support tower. It has an autocast ability which increases the damage by a percentage of non-support towers. 
-- Damage increase applies to both attacks and abilities. Autocast prefers targets with higher value (i.e. more powerful towers first.
BlacksmithTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "BlacksmithTower"
    },
nil)    

-- the thinker function for the blacksmith_tower_fire_up spell
function BlacksmithTower:FireUpThink()
    if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
        
        -- find out the tower with the best BuffPriority to apply the buff
        local target = GetBuffTargetInRadius(self.tower, self.castRange, "modifier_fire_up", self.level)

        if target then
            self.tower:CastAbilityOnTarget(target, self.ability, self.playerID)
        end
    end
end


function BlacksmithTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)    
end

function BlacksmithTower:OnCreated()
    self.ability = AddAbility(self.tower, "blacksmith_tower_fire_up", GetUnitKeyValue(self.towerClass, "Level"))    
    self.castRange = self.ability:GetCastRange(self.tower:GetAbsOrigin(), self.tower)
    self.level = self.ability:GetLevel()
    self.ability:ToggleAutoCast() -- turn on autocast by default
    self.playerID = self.tower:GetOwner():GetPlayerID()    
end

function BlacksmithTower:OnBuildingFinished()
    Timers:CreateTimer(function()
        if IsValidEntity(self.tower) then
            self:FireUpThink()
            return 1
        end
    end)
end

function BlacksmithTower:ApplyUpgradeData(data)
    if data.cooldown and data.cooldown > 1 then
        self.ability:StartCooldown(data.cooldown)
    end
    if data.autocast == false then
        self.ability:ToggleAutoCast()
    end
end

function BlacksmithTower:GetUpgradeData()
    return {
        cooldown = self.ability:GetCooldownTimeRemaining(), 
        autocast = self.ability:GetAutoCastState()
    }    
end

RegisterTowerClass(BlacksmithTower, BlacksmithTower.className)