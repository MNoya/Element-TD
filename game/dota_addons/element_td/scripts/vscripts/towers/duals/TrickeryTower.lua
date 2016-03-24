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
    if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() and self.tower:GetHealthPercent() == 100 then
        
        -- find out the tower with the best BuffPriority to clone
        local target = GetCloneTargetInRadius(self.tower, self.castRange)

        if target then
            self.tower:CastAbilityOnTarget(target, self.ability, self.playerID)
        end
    end
end

-- Doesn't this duplicate the damage?
function TrickeryTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function TrickeryTower:OnBuildingFinished()
    Timers:CreateTimer(math.random(0.03,0.2), function()
        if IsValidEntity(self.tower) then
            self:ConjureThink()
            return 1
        end
    end)
end

function TrickeryTower:OnCreated()
    self.ability = AddAbility(self.tower, "trickery_tower_conjure", self.tower:GetLevel())
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

-- Globals
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

    clone:AddEffects(EF_NODRAW)
    clone:ForceKill(true) --This will call RemoveBuilding
end

function RemoveRandomClone( playerData, name )
    local clones = {}
    local i = 0
    for entindex,_ in pairs(playerData.clones[name]) do
        local clone = EntIndexToHScript(entindex)
        if IsValidEntity(clone) and clone:GetClassname() == "npc_dota_creature" and clone:IsAlive() then
            i = i + 1
            clones[i] = clone
        else
            playerData.clones[name][entindex] = nil
        end
    end

    if #clones > 0 then
        local ranIndex = RandomInt(1,i)
        local clone = clones[ranIndex]
        RemoveClone(clone)
    end
end

RegisterTowerClass(TrickeryTower, TrickeryTower.className)