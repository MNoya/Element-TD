-- Vapor Tower class (Fire + Water)
-- This tower's attack does X damage to every creep in X area around it. Then, it does X/2 damage for every creep hit initially in X/2 area around each creep.
--  Think "Aftershock" from DotA.

-- TODO: add particle effects

VaporTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "VaporTower"
    },
nil);

function VaporTower:OnAttackStart(keys)
    local creeps = GetCreepsInArea(self.tower:GetOrigin(), self.initialAOE);
    local initial_damage = ApplyAbilityDamageFromModifiers(self.initialDamage[self.level], self.tower);
    local aftershock_damage = ApplyAbilityDamageFromModifiers(self.aftershockDamage[self.level], self.tower);

    for _,creep in pairs(creeps) do
        if creep:IsAlive() then

            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_adaptive_strike.vpcf", PATTACH_ABSORIGIN, creep);
            ParticleManager:SetParticleControl(particle, 0, Vector(0, 0, 0));
            ParticleManager:SetParticleControl(particle, 1, GetGroundPosition(creep:GetAbsOrigin(), nil));
            ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0));

            DamageEntity(creep, self.tower, initial_damage);
            local aftershock_creeps = GetCreepsInArea(creep:GetOrigin(), self.aftershockAOE);

            for __, creep2 in pairs(aftershock_creeps) do
                if creep2:entindex() ~= creep:entindex() and creep2:IsAlive() then --don't damage self with aftershock
                    DamageEntity(creep2, self.tower, aftershock_damage);
                end
            end
        end
    end
end

function VaporTower:OnCreated()
    self.level = GetUnitKeyValue(self.towerClass, "Level");
    local spellName = "vapor_tower_evaporate"
    AddAbility(self.tower, spellName, self.level);    

    self.initialDamage = GetAbilitySpecialValue(spellName, "damage");
    self.aftershockDamage = GetAbilitySpecialValue(spellName, "aftershock_damage");
    self.initialAOE = GetAbilitySpecialValue(spellName, "aoe");
    self.aftershockAOE = GetAbilitySpecialValue(spellName, "aftershock_aoe");
end

function VaporTower:OnAttackLanded(keys) end
RegisterTowerClass(VaporTower, VaporTower.className);