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
    local damage = self.tower:GetAverageTrueAttackDamage(target) * (1 + (0.5 * (target:GetHealth() / target:GetMaxHealth())))
	DamageEntity(target, self.tower, damage);

    local popupDamage = damage * (1 + (0.5 * (target:GetHealth() / target:GetMaxHealth())))
    if target:IsAlive() then
        popupDamage = ApplyElementalDamageModifier(popupDamage, GetDamageType(self.tower), GetArmorType(target))
        PopupGreenCriticalDamage(self.tower, math.floor(popupDamage))
    end

end

function MossTower:OnCreated()
    AddAbility(self.tower, "moss_tower_spore")
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_HIGHEST_HP}) 
end

RegisterTowerClass(MossTower, MossTower.className)    