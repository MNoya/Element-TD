-- Boss Creep class

CreepBoss = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepBoss"
    },
CreepBasic)

CreepBossAbilities = { [1]="creep_ability_mechanical", [2]="creep_ability_swarm", [3]="creep_ability_heal", [4]="creep_ability_undead", [5]="creep_ability_fast" }

function CreepBoss:OnSpawned()
    local creep = self.creep
    creep:SetMaximumGoldBounty(0)
    creep:SetMinimumGoldBounty(0)
    creep:CreatureLevelUp(creep.waveObject.waveNumber-creep:GetLevel())

    if creep.isSwarm then return end

    -- Choose an ability at random
    if not creep.isUndeadRespawn then
        local abilityName = CreepBossAbilities[RandomInt(1, #CreepBossAbilities)]
        creep.random_ability = abilityName
        AddAbility(creep, abilityName)
    end

    -- Don't mark swarm or first-death undead as a killed score
    creep.real_icefrog = creep.isUndeadRespawn or (creep.random_ability and creep.random_ability ~= "creep_ability_undead")

    if creep:HasAbility("creep_ability_mechanical") then
        -- Mechanical
        Timers:CreateTimer(math.random(1, 6), function()
            if not IsValidEntity(creep) or not creep:IsAlive() then return end

            creep:Purge(false, true, false, true, true)

            local duration = 2
            if creep.isSwarm then
                duration = 1
            end
            creep:FindAbilityByName("creep_ability_mechanical"):ApplyDataDrivenModifier(creep, creep, "mechanical_buff", {duration=duration})

            return 8
        end)
    end
end

-- Undead
function CreepBoss:OnDeath()
    local playerData = GetPlayerData(self.creep.playerID)
    local creep = self.creep
    local playerID = creep.playerID
    local creepClass = self.creepClass

    if creep.random_ability ~= "creep_ability_undead" then
        return
    end

    local newCreep = CreateUnitByName(creepClass, creep:GetAbsOrigin() , false, nil, nil, DOTA_TEAM_NEUTRALS)
    newCreep.class = creepClass
    newCreep.playerID = creep.playerID
    newCreep.waveObject = creep.waveObject
    newCreep.bounty = creep.bounty
    newCreep:CreatureLevelUp(newCreep.waveObject.waveNumber-newCreep:GetLevel())
    
    creep.waveObject:RegisterCreep(newCreep:entindex())
    creep.waveObject.creepsRemaining = creep.waveObject.creepsRemaining + 1 -- Increment creep count
    newCreep:AddNewModifier(newCreep, nil, "modifier_phased", {})
    newCreep:AddNewModifier(newCreep, nil, "modifier_invulnerable", {})
    newCreep:AddNewModifier(newCreep, nil, "modifier_invisible_etd", {})
    newCreep:AddNewModifier(newCreep, nil, "modifier_stunned", {})
    newCreep:AddNoDraw()
    newCreep.isUndeadRespawn = true

    newCreep:SetMaxHealth(creep:GetMaxHealth())
    newCreep:SetBaseMaxHealth(creep:GetMaxHealth())
    newCreep:SetForwardVector(creep:GetForwardVector())
    creep.scriptObject = self

    local undead_ability = newCreep:FindAbilityByName("creep_ability_undead")
    if undead_ability then
        undead_ability:SetHidden(true)
    end

    local particle = ParticleManager:CreateParticle("particles/generic_hero_status/death_tombstone.vpcf", PATTACH_ABSORIGIN, creep)
    ParticleManager:SetParticleControl(particle, 2, Vector(3,0,0))

    -- Respawn Timer
    Timers:CreateTimer(3, function()
        ParticleManager:DestroyParticle(particle, true)
        self:UndeadCreepRespawn()
    end)

    self.creep = newCreep
    CREEP_SCRIPT_OBJECTS[newCreep:entindex()] = self
end

-- Undead
function CreepBoss:UndeadCreepRespawn()
    local creep = self.creep
    local playerID = creep.playerID
    local playerData = GetPlayerData(playerID)
    local wave = creep.waveObject:GetWaveNumber()
    local creepClass = WAVE_CREEPS[wave]

    creep:RemoveNoDraw()
    creep:RemoveModifierByName("modifier_invulnerable")
    creep:RemoveModifierByName("modifier_invisible_etd")
    creep:RemoveModifierByName("modifier_stunned")

    self:OnSpawned()

    if creep.bounty then
        creep:SetMaximumGoldBounty(creep.bounty)
        creep:SetMinimumGoldBounty(creep.bounty)       
    else
        creep:SetMaximumGoldBounty(GetPlayerDifficulty(playerID):GetBountyForWave(wave))
        creep:SetMinimumGoldBounty(GetPlayerDifficulty(playerID):GetBountyForWave(wave))
    end

    creep:SetHealth(creep:GetMaxHealth() * 0.5) -- it spawns at a percentage of its max health
    CreateMoveTimerForCreep(creep, playerData.sector + 1) --create a timer for this creep so it continues walking to the destination

    local h = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_reincarnation.vpcf", PATTACH_CUSTOMORIGIN, creep) --play a cool particle effect :D
    ParticleManager:SetParticleControl(h, 0, creep:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(h, 0, creep, PATTACH_POINT_FOLLOW, "attach_hitloc", creep:GetOrigin(), true)
end

-- Swarm
function CreepBoss:OnTakeDamage(keys)   
    if self.creep:GetHealth() > 0 and self.creep:GetHealthPercent() <= 50 and not self.creep.isSwarm then
    
        if self.creep.random_ability ~= "creep_ability_swarm" then
            return
        end

        local swarm = SpawnEntity(self.creep:GetUnitName(), self.creep.playerID, self.creep:GetOrigin())
        swarm.class = creepClass
        swarm.playerID = self.creep.playerID
        swarm.waveObject = self.creep.waveObject
        self.creep.waveObject:RegisterCreep(swarm:entindex())
        self.creep.waveObject.creepsRemaining = self.creep.waveObject.creepsRemaining + 1 -- Increment creep count
        swarm.isSwarm = true
        local newMaxHealth = self.creep:GetMaxHealth()/2
        swarm:SetMaxHealth(newMaxHealth)
        swarm:SetBaseMaxHealth(newMaxHealth)
        swarm:SetHealth(newMaxHealth)
        swarm:SetDeathXP(0)
        swarm:SetForwardVector(self.creep:GetForwardVector())

        swarm.scriptObject:OnSpawned()        

        self.creep:SetMaxHealth(newMaxHealth)
        self.creep:SetBaseMaxHealth(newMaxHealth)
        self.creep:SetHealth(newMaxHealth)

        local newScale = self.creep:GetModelScale()*0.8

        self.creep:SetModelScale(newScale)
        swarm:SetModelScale(newScale)
        self.creep.isSwarm = true

        local playerID = self.creep.playerID
        local wave = self.creep.waveObject:GetWaveNumber()

        -- split the bounty between the two units even if it is an odd amount
        local bounty1 = GetPlayerDifficulty(playerID):GetBountyForWave(wave)
        local bounty2
        if bounty1 % 2 == 0 then
            bounty1 = bounty1 / 2
            bounty2 = bounty1
        else
            bounty1 = math.floor(bounty1 / 2)
            bounty2 = bounty1 + 1
        end

        self.creep.bounty = bounty1

        swarm.bounty = bounty2

        local playerData = GetPlayerData(playerID)
        CreateMoveTimerForCreep(swarm, playerData.sector + 1)
    end
end

-- Heal
function CreepBoss:HealNearbyCreeps(keys)
    local creep = self.creep;
    local aoe = keys.aoe;
    local ability = keys.ability
    local heal_percent = keys.heal_amount / 100;

    local entities = GetCreepsInArea(creep:GetOrigin(), aoe);
    for k, entity in pairs(entities) do
        if entity:GetHealth() > 0 then
            entity:Heal(entity:GetMaxHealth() * heal_percent, nil);
            if ability then
                ability:ApplyDataDrivenModifier(entity, entity, "heal_effect_modifier", {})
            end
        end
    end
end

RegisterCreepClass(CreepBoss, CreepBoss.className)