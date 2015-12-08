-- Life Tower class (Nature + Light)
-- This tower gives you a life for every X number of creeps it kills. 
-- Counter is global so that the kills of ALL life towers count together.

LifeTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "LifeTower"
    },
nil);

function LifeTower:CreepKilled(keys)
    local heroOwner = self.tower:GetOwner();
    local playerData = GetPlayerData(heroOwner:GetPlayerID());

    playerData.LifeTowerKills = playerData.LifeTowerKills + self.pointsPerKill;

    if playerData.health < 50 and playerData.LifeTowerKills >= 3 then --when health is less than 50
        playerData.LifeTowerKills = playerData.LifeTowerKills - 3;
        playerData.health = playerData.health + 1;
        heroOwner:SetHealth(playerData.health);

    elseif playerData.health >= 50 and playerData.LifeTowerKills >= 9 then --when health is greater than or equal to 50
        playerData.LifeTowerKills = playerData.LifeTowerKills - 9;
        playerData.health = playerData.health + 1;
    
        heroOwner:SetMaxHealth(playerData.health);
        heroOwner:SetHealth(playerData.health);
    end
end

function LifeTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = self.tower:GetBaseDamageMax();
    damage = ApplyAttackDamageFromModifiers(damage, self.tower);
    DamageEntity(target, self.tower, damage);
end

function LifeTower:OnCreated()
    AddAbility(self.tower, "life_tower_afterlife", self.tower:GetLevel());
    self.pointsPerKill = GetAbilitySpecialValue("life_tower_afterlife", "points_per_kill")[self.tower:GetLevel()];
end

RegisterTowerClass(LifeTower, LifeTower.className);
