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

function CreepBoss:GetAbilityList()
    if GameSettings:IsChaos() then
        return 
        {
            [1]="creep_ability_bulky",
            [2]="creep_ability_heal",
            [3]="creep_ability_vengeance",
            [4]="creep_ability_undead",
            [5]="creep_ability_regen",
            [6]="creep_ability_fast",
            [7]="creep_ability_mechanical",
            [8]="creep_ability_time_lapse"
        }
    else
        return
        {
            [1]="creep_ability_heal",
            [2]="creep_ability_vengeance",
            [3]="creep_ability_undead",
            [4]="creep_ability_regen",
            [5]="creep_ability_fast",
            [6]="creep_ability_mechanical",
            [7]="creep_ability_time_lapse"
        }
    end
end

function CreepBoss:OnSpawned()
    local creep = self.creep
    creep:SetMaximumGoldBounty(0)
    creep:SetMinimumGoldBounty(0)
    creep:CreatureLevelUp(creep.waveObject.waveNumber-creep:GetLevel())

    -- Don't mark first-death undead as a killed score
    creep.real_icefrog = not creep.random_abilities or (creep.random_abilities and not creep.random_abilities["creep_ability_undead"])

    if creep:HasAbility("creep_ability_undead") then
        self.creep.isUndead = true
    end

    if creep:HasAbility("creep_ability_mechanical") then
        -- Mechanical
        Timers:CreateTimer(math.random(1, 6), function()
            if not IsValidEntity(creep) or not creep:IsAlive() then return end

            creep:Purge(false, true, false, true, true)

            local duration = 2
            creep:FindAbilityByName("creep_ability_mechanical"):ApplyDataDrivenModifier(creep, creep, "mechanical_buff", {duration=duration})

            return 8
        end)
    end

    if creep:HasAbility("creep_ability_regen") then
        self.regenAmount = 0
        self.maxRegen = creep:GetMaxHealth() * self.abilities["creep_ability_regen"]:GetSpecialValueFor("max_heal_pct") * 0.01
        self.healthPercent = self.abilities["creep_ability_regen"]:GetSpecialValueFor("bonus_health_regen") * 0.01
        self.healthTick = round(creep:GetMaxHealth() * self.healthPercent * 0.1)

        Timers:CreateTimer(0.1, function()
            if not IsValidEntity(creep) or not creep:IsAlive() then return end
            
            if self.regenAmount <= self.maxRegen then
                if creep:GetHealth() > 0 and creep:GetHealth() ~= creep:GetMaxHealth() then
                    self:RegenerateCreepHealth()
                end
                return 0.1
            else
                creep:RemoveModifierByName("creep_regen_modifier")
            end
        end)
    end

    if creep:HasAbility("creep_ability_bulky") then
        local health_multiplier = self.abilities["creep_ability_bulky"]:GetSpecialValueFor("bonus_health_pct") * 0.01
        local health = creep:GetHealth()
        creep:SetMaxHealth(health * health_multiplier)
        creep:SetBaseMaxHealth(health * health_multiplier)
        creep:SetHealth(creep:GetMaxHealth() * health_multiplier)
        creep:SetModelScale(creep:GetModelScale()*1.8)
    end

    if creep:HasAbility("creep_ability_time_lapse") then
        self.health_threshold = self.abilities["creep_ability_time_lapse"]:GetSpecialValueFor("health_threshold")
        self.backtrack_duration = self.abilities["creep_ability_time_lapse"]:GetSpecialValueFor("backtrack_duration")
        self.health = {}
        self.position = {}

        -- Initial cooldown
        self.abilities["creep_ability_time_lapse"]:StartCooldown(self.backtrack_duration)
        Timers:CreateTimer(self.backtrack_duration, function()
            if IsValidEntity(creep) and creep:IsAlive() and creep:HasAbility("creep_ability_time_lapse") then
                self.abilities["creep_ability_time_lapse"]:ApplyDataDrivenModifier(creep, creep, "modifier_time_lapse", {})
            end
        end)

        -- We only store values during the backtrack duration with 1 decimal point
        local i = string.format("%.1f", GameRules:GetGameTime())*10
        local think_interval = 0.1
        self.health[i] = creep:GetHealth()
        self.position[i] = creep:GetAbsOrigin()

        self.temporalTimer = Timers:CreateTimer(think_interval, function()
            if not IsValidEntity(self.creep) or not creep:IsAlive() then return end
            local time = string.format("%.1f", GameRules:GetGameTime())

            self.health[time] = creep:GetHealth()
            self.position[time] = creep:GetAbsOrigin()

            -- Forget the old value
            local backtrack_target_time = tostring(tonumber(time)-self.backtrack_duration)
            if self.health[backtrack_target_time] then
                self.health[backtrack_target_time] = nil
                self.position[backtrack_target_time] = nil
            end

            return think_interval
        end)    
    end
end

function CreepBoss:Backtrack()
    local time = string.format("%.1f", GameRules:GetGameTime())
    local backtrack_target_time = tostring(tonumber(time)-self.backtrack_duration)

    -- Approximate a value if we don't have an exact time stored
    if not self.health[backtrack_target_time] then
        local closest = 100
        for pTime,_ in pairs(self.health) do
            local diff = math.abs(tonumber(time)-tonumber(pTime))
            if diff < closest and diff >= self.backtrack_duration then
                closest = diff
                backtrack_target_time = pTime
            end
        end

        if not self.health[backtrack_target_time] then
            return
        end
    end

    local origin = self.creep:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle("particles/custom/creeps/temporal/timelapse.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, origin)

    self.creep:RemoveModifierByName("modifier_time_lapse") --This stops the ability from triggering again through the damage function
    self.creep:SetHealth(self.health[backtrack_target_time])
    self.creep:SetAbsOrigin(self.position[backtrack_target_time])
    self.abilities["creep_ability_time_lapse"]:SetHidden(true)
    Timers:RemoveTimer(self.temporalTimer)
   
    ParticleManager:SetParticleControl(particle, 2, self.position[backtrack_target_time])
end

function CreepBoss:RegenerateCreepHealth()
    local creep = self.creep
    creep:Heal(self.healthTick, nil)
    self.regenAmount = self.regenAmount + self.healthTick
end

-- Undead and Vengeance
function CreepBoss:OnDeath(killer)
    local playerData = GetPlayerData(self.creep.playerID)
    local creep = self.creep
    local playerID = creep.playerID
    local creepClass = self.creepClass

    if creep.random_abilities["creep_ability_undead"] then
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

    elseif creep.random_abilities["creep_ability_vengeance"] then
        local ability = self.abilities["creep_ability_vengeance"]
        local duration = ability:GetSpecialValueFor("duration")
        local aoe = ability:GetSpecialValueFor("aoe")
        local damage_reduction = ability:GetSpecialValueFor("damage_reduction")

        local enemy_towers = FindUnitsInRadius(creep:GetTeamNumber(), killer:GetAbsOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
        for _,tower in pairs(enemy_towers) do
            local modifier = tower:FindModifierByName("modifier_vengeance_debuff")
            if not modifier then
                tower:AddNewModifier(tower, nil, "modifier_vengeance_debuff", {})
                modifier = tower:FindModifierByName("modifier_vengeance_debuff")
            end
            
            local stackCount = tower:GetModifierStackCount("modifier_vengeance_debuff", tower) + 1
            if modifier then
                modifier:IncrementStackCount()
                modifier:SetDuration(duration, true)
                modifier.baseDamageReduction = damage_reduction
                modifier.damageReduction = modifier.baseDamageReduction * stackCount
            end

            tower:AddNewModifier(tower, nil, "modifier_vengeance_multiple", {duration=duration})
        end
       
        local particle = ParticleManager:CreateParticle("particles/custom/creeps/vengeance/death.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(particle, 0, killer:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, killer:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 2, Vector(aoe*1.5,1,1))
        ParticleManager:SetParticleControl(particle, 3, Vector(aoe*2,1,1))
    end
end

-- Undead
function CreepBoss:UndeadCreepRespawn()
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

    self:OnSpawned()

    if creep.bounty then
        creep:SetMaximumGoldBounty(creep.bounty)
        creep:SetMinimumGoldBounty(creep.bounty)       
    else
        local bounty = GameSettings:GetGlobalDifficulty():GetBountyForWave(wave)
        creep:SetMaximumGoldBounty(bounty)
        creep:SetMinimumGoldBounty(bounty)
    end

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