-- Heal Creep class
CreepHeal = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep;
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepHeal"
    },
CreepBasic);

function CreepHeal:HealNearbyCreeps(keys)
    local creep = self.creep;
    local aoe = keys.aoe;
    local heal_percent = keys.heal_amount / 100; 

    local entities = GetCreepsInArea(creep:GetOrigin(), aoe);
    for k, entity in pairs(entities) do
        if entity:GetHealth() > 0 then
            entity:Heal(entity:GetMaxHealth() * heal_percent, nil);
        end
    end
end

RegisterCreepClass(CreepHeal, CreepHeal.className);