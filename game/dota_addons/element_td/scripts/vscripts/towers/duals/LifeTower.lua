-- Life Tower class (Nature + Light)
-- This tower gives you a life for every X number of creeps it kills. 
-- Counter is global so that the kills of ALL life towers count together.

LifeTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "LifeTower"
    },
nil)    

function LifeTower:CreepKilled(keys)
    local heroOwner = self.tower:GetOwner()
    if (keys.unit:GetTeamNumber() == heroOwner:GetTeamNumber()) then return end --Exit out of killing your own tower

    if COOP_MAP then 
        self:CreepKilledCoop(keys) 
        return 
    end

    local playerData = GetPlayerData(heroOwner:GetPlayerID())    
    local life_tower_kills = playerData.LifeTowerKills --used to revert the gain of stacks when on full life
    playerData.LifeTowerKills = playerData.LifeTowerKills + self.pointsPerKill

    -- Bulky creeps count as double the kills
    if keys.unit:HasAbility("creep_ability_bulky") then
        playerData.LifeTowerKills = playerData.LifeTowerKills + self.pointsPerKill
    end

    local maxHealth = 70
    if playerData.health < maxHealth and playerData.LifeTowerKills >= 24 then --when health is less than max
        playerData.LifeTowerKills = playerData.LifeTowerKills - 24

        AddOneLife(self.tower, playerData)

    elseif playerData.health >= maxHealth then --[[and playerData.LifeTowerKills >= 120 then --when health is greater than or equal to max
        --[[playerData.LifeTowerKills = playerData.LifeTowerKills - 120

        AddOneLife(self.tower, playerData)]]     
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_life_tower_full_health", {})
        playerData.LifeTowerKills = life_tower_kills
    end

    -- Update all tower counters
    local modifierName = "modifier_life_tower_current_kill_counter"
    for k,v in pairs(playerData.towers) do
        local tower = EntIndexToHScript(k)
        if IsValidEntity(tower) and tower.scriptClass == "LifeTower" then
            if not tower:HasModifier(modifierName) then
                self.ability:ApplyDataDrivenModifier(self.tower, self.tower, modifierName, {})
            end
            tower:SetModifierStackCount(modifierName, nil, playerData.LifeTowerKills)
        end
    end
    for _,tower in pairs(playerData.clones) do
        if IsValidEntity(tower) and tower.scriptClass == "LifeTower" then
            if not tower:HasModifier(modifierName) then
                self.ability:ApplyDataDrivenModifier(self.tower, self.tower, modifierName, {})
            end
            tower:SetModifierStackCount(modifierName, nil, playerData.LifeTowerKills)
        end
    end
end

function LifeTower:CreepKilledCoop(keys)
    local life_tower_kills = COOP_LIFE_TOWER_KILLS
    COOP_LIFE_TOWER_KILLS = COOP_LIFE_TOWER_KILLS + self.pointsPerKill

    if keys.unit:HasAbility("creep_ability_bulky") then
        COOP_LIFE_TOWER_KILLS = COOP_LIFE_TOWER_KILLS + self.pointsPerKill
    end

    local maxHealth = 140
    if COOP_HEALTH < maxHealth and COOP_LIFE_TOWER_KILLS >= 60 then --when health is less than max
        COOP_LIFE_TOWER_KILLS = COOP_LIFE_TOWER_KILLS - 60
        AddOneLifeCoop(self.tower)
    elseif COOP_HEALTH >= maxHealth then --[[and COOP_LIFE_TOWER_KILLS >= 120 then --when health is greater than or equal to max
        COOP_LIFE_TOWER_KILLS = COOP_LIFE_TOWER_KILLS - 120
        AddOneLifeCoop(self.tower)   ]] 

        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_life_tower_full_health", {})
        playerData.LifeTowerKills = life_tower_kills
    end

    -- Update all tower counters
    local modifierName = "modifier_life_tower_current_kill_counter"
    ForAllPlayerIDs(function(playerID)
        local playerData = GetPlayerData(playerID)
        
        for k,v in pairs(playerData.towers) do
            local tower = EntIndexToHScript(k)
            if IsValidEntity(tower) and tower.scriptClass == "LifeTower" then
                if not tower:HasModifier(modifierName) then
                    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, modifierName, {})
                end
                tower:SetModifierStackCount(modifierName, nil, COOP_LIFE_TOWER_KILLS)
            end
        end
        for _,tower in pairs(playerData.clones) do
            if IsValidEntity(tower) and tower.scriptClass == "LifeTower" then
                if not tower:HasModifier(modifierName) then
                    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, modifierName, {})
                end
                tower:SetModifierStackCount(modifierName, nil, COOP_LIFE_TOWER_KILLS)
            end
        end
    end)
    
end

function AddOneLife(tower, playerData)
    local hero = tower:GetOwner()

    playerData.health = playerData.health + 1
    playerData.TotalLifeTowerKills = playerData.TotalLifeTowerKills + 1
    UpdatePlayerHealth(hero:GetPlayerID())

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN, tower)
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 100, 100))

    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=hero:GetPlayerID(), health= hero:GetHealthPercent() } )
    UpdateScoreboard(hero:GetPlayerID())

    tower.life_counter = tower.life_counter + 1
    tower:SetModifierStackCount("modifier_life_tower_counter", tower, tower.life_counter)

    tower:EmitSound("Life.Gain")
end

function AddOneLifeCoop(tower)
    COOP_LIFE_TOWER_KILLS_TOTAL = COOP_LIFE_TOWER_KILLS_TOTAL + 1
    ForAllPlayerIDs(function(playerID)
        local playerData = GetPlayerData(playerID)
        playerData.health = playerData.health + 1

        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        UpdatePlayerHealth(playerID)
        
        CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId = playerID, health = hero:GetHealthPercent()})
        UpdateScoreboard(hero:GetPlayerID())
    end)
    
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN, tower)
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 100, 100))

    tower.life_counter = tower.life_counter + 1
    tower:SetModifierStackCount("modifier_life_tower_counter", tower, tower.life_counter)

    tower:EmitSound("Life.Gain")
end

function LifeTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)
end

function LifeTower:GetUpgradeData()
    local counter = self.tower.life_counter
    return { life_counter = counter }
end

function LifeTower:ApplyUpgradeData(data)
    if data.life_counter and data.life_counter > 0 then
        self.tower:SetModifierStackCount("modifier_life_tower_counter", self.tower, data.life_counter)
        self.tower.life_counter = data.life_counter
    end
end

function LifeTower:OnCreated()
    self.ability = AddAbility(self.tower, "life_tower_afterlife", self.tower:GetLevel())    
    self.pointsPerKill = GetAbilitySpecialValue("life_tower_afterlife", "points_per_kill")[self.tower:GetLevel()]    
    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_life_tower_counter", {})
    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_life_tower_current_kill_counter", {})
    self.playerID = self.tower:GetPlayerOwnerID()
    self.tower:SetModifierStackCount("modifier_life_tower_current_kill_counter", nil, GetPlayerData(self.playerID).LifeTowerKills)
    self.tower.life_counter = 0
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})

    -- Update tower damage when the player goes over max health
    local maxLives = GameSettings:GetMapSetting("Lives")
    Timers:CreateTimer(0.03, function()
        if not IsValidEntity(self.tower) or not self.tower:IsAlive() then return end

        if GetPlayerData(self.playerID).health <= maxLives then
            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_life_tower_full_health", {})
        else
            self.tower:RemoveModifierByName("modifier_life_tower_full_health")
        end
        return 1
    end)
end

RegisterTowerClass(LifeTower, LifeTower.className)    
