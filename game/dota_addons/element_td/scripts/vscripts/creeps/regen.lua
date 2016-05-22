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
	self.maxRegen = creep:GetMaxHealth() * self.ability:GetSpecialValueFor("max_heal_pct") * 0.01
	self.healthPercent = self.ability:GetSpecialValueFor("bonus_health_regen") * 0.01
	self.tickTime = 0.5
	self.healthTick = creep:GetMaxHealth() * self.healthPercent * self.tickTime

	Timers:CreateTimer(self.tickTime, function()
		if not IsValidEntity(creep) or not creep:IsAlive() then return end
		
		if self.regenAmount <= self.maxRegen then
			if creep:GetHealth() > 0 and creep:GetHealth() ~= creep:GetMaxHealth() then
				self:RegenerateCreepHealth()
			end
			return self.tickTime
		else
			creep:RemoveModifierByName("creep_regen_modifier")
		end
	end)
end

function CreepRegen:RegenerateCreepHealth()
	local creep = self.creep
	creep:Heal(self.healthTick, nil)
	self.regenAmount = self.regenAmount + self.healthTick
end

RegisterCreepClass(CreepRegen, CreepRegen.className)