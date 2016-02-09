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
    if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
        
        -- let's find a target to cast on
        local towers = FindUnitsInRadius(self.tower:GetTeamNumber(), self.tower:GetOrigin(), nil, self.castRange, 
                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
        local highestDamage = 0
        local theChosenOne = nil

        -- find out the tower with the highest dps
        for _, tower in pairs(towers) do
            if IsTower(tower) and tower:GetPlayerOwnerID() == self.playerID and not IsSupportTower(tower) and tower:IsAlive() and not tower.deleted then
                local dps = tower:GetAverageTrueAttackDamage() * tower:GetAttacksPerSecond()
                if dps >= highestDamage then
            
                    local modifier = tower:FindModifierByName("modifier_spring_forward")
                    if not modifier or self.level > modifier.level then 
                        highestDamage = dps
                        theChosenOne = tower
                    end

                end
            end
        end

        if not theChosenOne then
            for _, tower in pairs(towers) do
                if IsTower(tower) and tower:GetPlayerOwnerID() == self.playerID and tower:IsAlive() and not tower.deleted then
                    local dps = tower:GetAverageTrueAttackDamage() * tower:GetAttacksPerSecond()
                    if dps >= highestDamage then
                
                        local modifier = tower:FindModifierByName("modifier_spring_forward")
                        if not modifier or self.level > modifier.level then 
                            highestDamage = dps
                            theChosenOne = tower
                        end

                    end
                end
            end
        end

        if theChosenOne then
            self.tower:CastAbilityOnTarget(theChosenOne, self.ability, self.playerID)
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
    Timers:CreateTimer(function()
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