-- CANNON TOWER
CannonTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "CannonTower"
    },
nil);

function CannonTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);
    
    local pos = target:GetOrigin();
    pos.z = pos.z + 64;

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_jakiro/jakiro_liquid_fire_explosion.vpcf", PATTACH_ABSORIGIN, target);
    ParticleManager:SetParticleControl(particle, 0, pos);
    ParticleManager:SetParticleControl(particle, 1, Vector(150, 260, 0));
    ParticleManager:ReleaseParticleIndex(particle); 
end

function CannonTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
end

RegisterTowerClass(CannonTower, CannonTower.className);