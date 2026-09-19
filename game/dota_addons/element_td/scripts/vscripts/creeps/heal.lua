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
		if GetCreepHealth(entity) > 0 then
			HealCreep(entity, GetCreepMaxHealth(entity) * heal_percent, nil);
			keys.ability:ApplyDataDrivenModifier(entity, entity, "heal_effect_modifier", {})
		end
	end
end

RegisterCreepClass(CreepHeal, CreepHeal.className);