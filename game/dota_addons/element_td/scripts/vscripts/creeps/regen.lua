-- Regen Creep class
-- Regen waves
-- Classic: 8, 18, 22, 33, 37, 46, 52
-- Express: 4, 9, 12, 18, 20, 25, 28
CreepRegen = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
            self.regenAmount = 0
        end
	},
	{
		className = "CreepRegen"
	},
CreepBasic);

function CreepRegen:OnSpawned()
	local creep = self.creep
	self.ability = self.creep:FindAbilityByName("creep_ability_regen")
	self.maxRegen = self.ability:GetSpecialValueFor("max_heal_pct") * 0.01

	Timers:CreateTimer(1, function()
		if not IsValidEntity(creep) or not creep:IsAlive() then return end
		
		self:RegenerateCreepHealth()
		return 1
	end)
end

function CreepRegen:RegenerateCreepHealth()
	local creep = self.creep
	self.healthPercent = self.ability:GetSpecialValueFor("bonus_health_regen")

	if creep:GetHealth() > 0 and creep:GetHealth() ~= creep:GetMaxHealth() and self.regenAmount <= creep:GetMaxHealth()*self.maxRegen then

		local healthPre = creep:GetHealth() 
		creep:Heal(creep:GetMaxHealth() * (self.healthPercent / creep:GetMaxHealth()), nil)
		local healthPost = creep:GetHealth()
		self.regenAmount = self.regenAmount + (healthPost - healthPre)
	end
end

RegisterCreepClass(CreepRegen, CreepRegen.className)