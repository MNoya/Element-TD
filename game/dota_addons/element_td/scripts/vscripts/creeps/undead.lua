-- Undead Creep class

CreepUndead = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepUndead"
    },
CreepBasic)

function CreepUndead:OnSpawned() 
    self.creep:SetMaximumGoldBounty(0)
    self.creep:SetMinimumGoldBounty(0)
    self.creep.isUndead = true
end

function CreepUndead:OnDeath()
    local creep = self.creep
    local playerID = creep.playerID
    local creepClass = self.creepClass

    local newCreep = CreateUnitByName(creepClass, creep:GetAbsOrigin() , false, nil, nil, DOTA_TEAM_NEUTRALS)
    newCreep.class = creepClass
    newCreep.playerID = creep.playerID or creep.sector
    newCreep.waveObject = creep.waveObject
    newCreep.waveNumber = creep.waveNumber
    newCreep.sector = creep.sector --coop only
    newCreep:CreatureLevelUp(newCreep.waveObject.waveNumber-newCreep:GetLevel())
    AddAbility(newCreep, creepsKV[creepClass].CreepAbility1) -- give armor ability

    local newEntIndex = newCreep:entindex()
    creep.waveObject:RegisterCreep(newEntIndex)
    creep.waveObject.creepsRemaining = creep.waveObject.creepsRemaining + 1 -- Increment creep count
    newCreep.entity_index = newEntIndex
    newCreep:AddNewModifier(nil, nil, "modifier_phased", {})
    newCreep:AddNewModifier(nil, nil, "modifier_invulnerable", {})
    newCreep:AddNewModifier(nil, nil, "modifier_invisible_etd", {})
    newCreep:AddNewModifier(nil, nil, "modifier_stunned", {})
    newCreep:AddNoDraw()
    newCreep:SetMaxHealth(creep:GetMaxHealth())
    newCreep:SetBaseMaxHealth(creep:GetMaxHealth())
    newCreep:SetForwardVector(creep:GetForwardVector())
    creep.scriptObject = self

    local particle = ParticleManager:CreateParticle("particles/generic_hero_status/death_tombstone.vpcf", PATTACH_ABSORIGIN, creep)
    ParticleManager:SetParticleControl(particle, 2, Vector(3,0,0))

    local undead_ability = newCreep:FindAbilityByName("creep_ability_undead")
    if undead_ability then
        undead_ability:SetHidden(true)
    end

    -- Respawn Timer
    Timers:CreateTimer(3, function()
        ParticleManager:DestroyParticle(particle, true)
        if not END_TIME then
            self:UndeadCreepRespawn()
        end
    end)

    self.creep = newCreep
    CREEP_SCRIPT_OBJECTS[newEntIndex] = self
end

function CreepUndead:UndeadCreepRespawn()
    local creep = self.creep
    local playerID = creep.playerID
    local playerData = GetPlayerData(playerID)
    local wave = creep.waveObject:GetWaveNumber()
    local creepClass = WAVE_CREEPS[wave]

    -- awful handling for awful issue
    if not IsValidEntity(creep) then
        if creep.entity_index then
            creep.waveObject:OnCreepKilled(creep.entity_index)
        end
        return
    end

    creep:RemoveNoDraw()
    creep:RemoveModifierByName("modifier_invulnerable")
    creep:RemoveModifierByName("modifier_invisible_etd")
    creep:RemoveModifierByName("modifier_stunned")

    local bounty = GameSettings:GetGlobalDifficulty():GetBountyForWave(wave)
    creep:SetMaximumGoldBounty(bounty)
    creep:SetMinimumGoldBounty(bounty)

    creep:SetHealth(creep:GetMaxHealth() * 0.5) -- it spawns at a percentage of its max health

    --create a timer for this creep so it continues walking to the destination
    if COOP_MAP then
        CreateMoveTimerForCreepCoop(creep, creep.sector)
    else
        CreateMoveTimerForCreep(creep, playerData.sector + 1)
    end

    local h = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_reincarnation.vpcf", PATTACH_CUSTOMORIGIN, creep) --play a cool particle effect :D
    ParticleManager:SetParticleControl(h, 0, creep:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(h, 0, creep, PATTACH_POINT_FOLLOW, "attach_hitloc", creep:GetOrigin(), true)

    -- Add to scoreboard count
    if playerData and playerData.remaining then
        playerData.remaining = playerData.remaining + 1
    end
    if playerID then
        UpdateScoreboard(playerID)
    end
end

RegisterCreepClass(CreepUndead, CreepUndead.className)