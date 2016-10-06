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
    local damage = self.tower:GetAverageTrueAttackDamage(target)
--    damage = damage * ((target:GetMaxHealth() + target:GetHealth()) / target:GetHealth())
    damage = damage * (target:GetMaxHealth() / target:GetHealth()) * (1 + (target:GetMaxHealth() / target:GetHealth()) / 8)

    if target:IsAlive() then
        local damage_done = DamageEntity(target, self.tower, damage)
        PopupHPRemovalDamage(self.tower, math.floor(damage_done))
    end
end

function DiseaseTower:OnCreated()
    -- this ability is just for looks, it doesn't actually do anything :P
    AddAbility(self.tower, "disease_tower_soul_reaper")

    local level = self.tower:GetLevel()
    local particleName
    if level == 1 then
        particleName = "particles/units/heroes/hero_undying/undying_tombstone_ambient.vpcf"
    elseif level == 2 then
        particleName = "particles/econ/items/undying/undying_manyone/undying_pale_tombstone_ambient.vpcf"
    elseif level == 3 then
        particleName = "particles/econ/items/undying/undying_manyone/undying_pale_gold_tombstone_ambient.vpcf"
    end
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, self.tower)
    ParticleManager:SetParticleControlEnt(particle, 0, self.tower, PATTACH_POINT_FOLLOW, "attach_origin", self.tower:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self.tower, PATTACH_POINT_FOLLOW, "attach_origin", self.tower:GetAbsOrigin(), true)

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})
end

RegisterTowerClass(DiseaseTower, DiseaseTower.className)    