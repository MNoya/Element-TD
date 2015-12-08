-- Mushroom Tower class (Nature + Earth)
-- This is a tower which deals damage proportional to the health of the target. 
-- So damage is equal to (Current HP/Max HP)*Base Damage.)
-- Basically the opposite of a Disease Tower

MushroomTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "MushroomTower"
    },
nil);

function MushroomTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
    local creepsInHalfAOE = GetCreepsInArea(target:GetOrigin(), self.halfAOE);
    local creepsInFullAOE = GetCreepsInArea(target:GetOrigin(), self.fullAOE);
    
    local damages = {}; -- because slash damage is dealt in two instances, we need to calculate the correct damage beforehand
    for _,v in pairs(creepsInHalfAOE) do
        damages[v:entindex()] = damage * (1 + v:GetHealth() / v:GetMaxHealth());
    end


    for _,v in pairs(creepsInHalfAOE) do
        DamageEntity(v, self.tower, damages[v:entindex()] / 2);
    end
    for _,v in pairs(creepsInFullAOE) do
        DamageEntity(v, self.tower, damages[v:entindex()] / 2);
    end

end

function MushroomTower:OnCreated()
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    --this ability is just for looks, it doesn't actually do anything :P
    AddAbility(self.tower, "mushroom_tower_spore"); 
end

RegisterTowerClass(MushroomTower, MushroomTower.className);