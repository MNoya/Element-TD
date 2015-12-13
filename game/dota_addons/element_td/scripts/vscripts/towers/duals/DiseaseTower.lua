-- Disease Tower class (Nature + Dark)
-- This is a tower which deals damage inversely proportional to the health of the target. 
-- So damage is equal to (Max HP/Current HP)*Base Damage.)
DiseaseTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "DiseaseTower"
    },
nil)    

function DiseaseTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetBaseDamageMax()    
    damage = ApplyAttackDamageFromModifiers(damage, self.tower)    
    damage = (target:GetMaxHealth() / target:GetHealth()) * damage     --do that disease stuff
    DamageEntity(target, self.tower, damage)    
end

function DiseaseTower:OnCreated()
    -- this ability is just for looks, it doesn't actually do anything :P
    AddAbility(self.tower, "disease_tower_soul_reaper")     
end

RegisterTowerClass(DiseaseTower, DiseaseTower.className)    