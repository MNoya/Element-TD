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

        AddOneLife(self.tower, playerData)

    elseif playerData.health >= 50 and playerData.LifeTowerKills >= 9 then --when health is greater than or equal to 50
        playerData.LifeTowerKills = playerData.LifeTowerKills - 9

        AddOneLife(self.tower, playerData)        
    end
end

function AddOneLife(tower, playerData)
    local hero = tower:GetOwner()

    playerData.health = playerData.health + 1

    if not hero:HasModifier("modifier_bonus_life") then
        hero:AddNewModifier(hero, nil, "modifier_bonus_life", {})
    end

    hero:CalculateStatBonus()
    local heal = playerData.health - hero:GetHealth()
    hero:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN, tower)
    ParticleManager:SetParticleControl(particle, 1, Vector(100, 100, 100))

    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=hero:GetPlayerID(), health= hero:GetHealthPercent() } )
end

function LifeTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetBaseDamageMax()    
    damage = ApplyAttackDamageFromModifiers(damage, self.tower)    
    DamageEntity(target, self.tower, damage)    
end

function LifeTower:OnCreated()
    AddAbility(self.tower, "life_tower_afterlife", self.tower:GetLevel())    
    self.pointsPerKill = GetAbilitySpecialValue("life_tower_afterlife", "points_per_kill")[self.tower:GetLevel()]    
end

RegisterTowerClass(LifeTower, LifeTower.className)    
