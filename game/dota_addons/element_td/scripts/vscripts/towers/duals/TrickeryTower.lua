-- Trickery Tower (Light + Dark)
--[[
    Single target tower that does 210/1050/5250 damage with 900 range and 1 attack speed.
    Autocast ability which creates a clone of non-support towers for 10/20/60 seconds. Clone appears in space closest to targeted tower. 
    Cooldown of 15 seconds. Autocast prefers towers with higher value.

    Clones sell for 0 gold. Clones can’t be upgraded. May only clone a tower if you haven’t cloned it in the last 60 seconds. 
    When you sell/upgrade a tower that has been cloned in the last 60 seconds, you lose a random clone of that tower type (this is to prevent abuse with 100% sell).

    Support tower. Damage type is Light. Note, a clone should be black and white perhaps to indicate it’s a clone.
]]

TrickeryTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "TrickeryTower"
    },
nil)

function TrickeryTower:ConjureThink()
    if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() and not self.tower:IsSilenced() then

        -- let's find a target to cast on
        local towers = FindUnitsInRadius(self.tower:GetTeamNumber(), self.tower:GetOrigin(), nil, self.castRange, 
                        DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
        local highestValue = 0
        local theChosenOne = nil

        -- find out the tower with the highest value
        for _, tower in pairs(towers) do
            if IsTower(tower) and tower:GetPlayerOwnerID() == self.playerID and not IsSupportTower(tower) and tower:IsAlive() and not tower.deleted then
                if not tower:HasModifier("modifier_clone") and not tower:HasModifier("modifier_conjure_prevent_cloning") then
                    local towerValue = GetUnitKeyValue(tower:GetUnitName(), "TotalCost")
                    if towerValue > highestValue then
                        highestValue = towerValue
                        theChosenOne = tower
                    end
                end
            end
        end

        if theChosenOne then
            self.tower:CastAbilityOnTarget(theChosenOne, self.ability, self.playerID)
        end
    end
end

-- Doesn't this duplicate the damage?
function TrickeryTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetBaseDamageMax()
    DamageEntity(target, self.tower, damage)
end

function TrickeryTower:OnCreated()
    self.ability = AddAbility(self.tower, "trickery_tower_conjure", self.tower:GetLevel())
    Timers:CreateTimer(function()
        if IsValidEntity(self.tower) then
            self:ConjureThink()
            return 1
        end
    end)
    self.ability:ToggleAutoCast()
    self.playerID = self.tower:GetOwner():GetPlayerID()
    self.castRange = tonumber(GetAbilityKeyValue("trickery_tower_conjure", "AbilityCastRange"))
    self.ability.clone_duration = self.ability:GetLevelSpecialValueFor("duration", self.ability:GetLevel() - 1)
    self.ability.clones = {}
end

-- All clones are killed when the tower is sold, but not when it's upgraded
function TrickeryTower:OnDestroyed()
    if self.tower.sold then
        for k, v in pairs(self.ability.clones) do
            local clone = EntIndexToHScript(k)
            if IsValidAlive(clone) then
                RemoveClone(clone)
            end
        end
    end
end

function TrickeryTower:ApplyUpgradeData(data)
    if data.cooldown and data.cooldown > 1 then
        self.ability:StartCooldown(data.cooldown)
    end
end

function TrickeryTower:GetUpgradeData()
    return {
        cooldown = self.ability:GetCooldownTimeRemaining(), 
        autocast = self.ability:GetAutoCastState()
    }
end


-- Global
function RemoveClone(clone)
    local ability = clone.ability -- The ability that created this clone
    local playerData = GetPlayerData(clone:GetPlayerOwnerID())
    local entIndex = clone:GetEntityIndex()
    
    -- Play particle
    local origin = clone:GetAbsOrigin()
    origin.z = origin.z + 75
    local particle = ParticleManager:CreateParticle("particles/custom/towers/trickery/illusion_killed.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, origin)

    -- Run OnDestroyed script
    if clone.scriptObject["OnDestroyed"] then
        clone.scriptObject:OnDestroyed()
    end

    -- Remove from tables
    playerData.towers[entIndex] = nil -- remove this tower index from the player's tower list
    playerData.clones[clone.class][entIndex] = nil
    if IsValidEntity(ability) then
        ability.clones[entIndex] = nil -- remove from the ability
    end

    RemoveTower(clone)
end

RegisterTowerClass(TrickeryTower, TrickeryTower.className)