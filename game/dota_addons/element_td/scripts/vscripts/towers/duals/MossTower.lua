-- Moss Tower class (Nature + Earth)
-- This is a tower which deals damage proportional to the health of the target. 
-- So damage is equal to (Current HP/Max HP)*Base Damage.)
-- Basically the opposite of a Disease Tower

MossTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "MossTower"
    },
nil)    

function MossTower:OnAttackLanded(keys)
    local target = keys.target    
    local damage = self.tower:GetAverageTrueAttackDamage()

    local popupDamage = damage * (1 + target:GetHealth() / target:GetMaxHealth())
    if target:IsAlive() then
        popupDamage = ApplyElementalDamageModifier(popupDamage, GetDamageType(self.tower), GetArmorType(target))
        PopupGreenCriticalDamage(self.tower, math.floor(popupDamage))
    end

    local creepsInHalfAOE = GetCreepsInArea(target:GetOrigin(), self.halfAOE)    
    local creepsInFullAOE = GetCreepsInArea(target:GetOrigin(), self.fullAOE)    
    
    local damages = {}     -- because slash damage is dealt in two instances, we need to calculate the correct damage beforehand
    for _,v in pairs(creepsInHalfAOE) do
        damages[v:entindex()] = damage * (1 + v:GetHealth() / v:GetMaxHealth())    
    end

    for _,v in pairs(creepsInHalfAOE) do
        DamageEntity(v, self.tower, damages[v:entindex()] / 2)    
    end
    for _,v in pairs(creepsInFullAOE) do
        DamageEntity(v, self.tower, damages[v:entindex()] / 2)    
    end

end

function MossTower:OnCreated()
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))    
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    AddAbility(self.tower, "moss_tower_spore")     
end

RegisterTowerClass(MossTower, MossTower.className)    