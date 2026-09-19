-- Bulky Creep class
CreepBulky = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
	},
	{
		className = "CreepBulky"
	},
CreepBasic);

function CreepBulky:OnSpawned()
	local creep = self.creep
	self.ability = self.creep:FindAbilityByName("creep_ability_bulky")
	local health_multiplier = self.ability:GetSpecialValueFor("bonus_health_pct") * 0.01
	local health = GetCreepHealth(creep)
	SetCreepMaxHealth(creep, health * health_multiplier)
	SetCreepHealth(creep, GetCreepMaxHealth(creep))
	creep:SetModelScale(creep:GetModelScale() * 1.7)
end

RegisterCreepClass(CreepBulky, CreepBulky.className)