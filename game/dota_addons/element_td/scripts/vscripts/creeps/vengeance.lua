-- Vengeance Creep class
-- Classic: 10, 17, 24, 29, 34, 42, 49

CreepVengeance = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
	},
	{
		className = "CreepVengeance"
	},
CreepBasic);

function CreepVengeance:OnDeath(killer) 
	local creep = self.creep
	local ability = creep:FindAbilityByName("creep_ability_vengeance")

	-- TODO: add modifier to killer
end

RegisterCreepClass(CreepVengeance, CreepVengeance.className)
