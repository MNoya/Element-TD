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
    local health = creep:GetHealth()
    creep:SetMaxHealth(health * health_multiplier)
    creep:SetBaseMaxHealth(health * health_multiplier)
    creep:SetHealth(creep:GetMaxHealth() * health_multiplier)
    creep:SetModelScale(creep:GetModelScale() * 2)
end

RegisterCreepClass(CreepBulky, CreepBulky.className)