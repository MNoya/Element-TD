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

    local playerData = GetPlayerData(heroOwner:GetPlayerID())    
    playerData.LifeTowerKills = playerData.LifeTowerKills + self.pointsPerKill

    if playerData.health < 50 and playerData.LifeTowerKills >= 3 then --when health is less than 50
        playerData.LifeTowerKills = playerData.LifeTowerKills - 3

        AddOneLife(self.tower, self.ability, playerData)

    elseif playerData.health >= 50 and playerData.LifeTowerKills >= 9 then --when health is greater than or equal to 50
        playerData.LifeTowerKills = playerData.LifeTowerKills - 9

        AddOneLife(self.tower, self.ability, playerData)        
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

function AddOneLife(tower, ability, playerData)
    local hero = tower:GetOwner()

    playerData.health = playerData.health + 1
    playerData.TotalLifeTowerKills = playerData.TotalLifeTowerKills + 1

    if not hero:HasModifier("modifier_bonus_life") then
        hero:AddNewModifier(hero, nil, "modifier_bonus_life", {})
    end

    hero:CalculateStatBonus()
    local heal = playerData.health - hero:GetHealth()
    hero:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN, tower)
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 100, 100))

    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=hero:GetPlayerID(), health= hero:GetHealthPercent() } )
    UpdateScoreboard(hero:GetPlayerID())

    tower.life_counter = tower.life_counter + 1
    tower:SetModifierStackCount("modifier_life_tower_counter", tower, tower.life_counter)

    tower:EmitSound("Life.Gain")
end

function LifeTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage()
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
    self.tower:SetModifierStackCount("modifier_life_tower_current_kill_counter", nil, GetPlayerData(self.tower:GetPlayerOwnerID()).LifeTowerKills)
    self.tower.life_counter = 0
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})
end

RegisterTowerClass(LifeTower, LifeTower.className)    
