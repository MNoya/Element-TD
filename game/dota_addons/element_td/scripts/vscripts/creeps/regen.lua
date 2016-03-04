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
	local ability = self.creep:FindAbilityByName("creep_ability_regen")
	self.maxRegen = ability:GetSpecialValueFor("max_heal_pct")

	Timers:CreateTimer(1, function()
		if not IsValidEntity(creep) or not creep:IsAlive() then return end
		
		self:RegenerateCreepHealth()
		return 1
	end)
end

function CreepRegen:RegenerateCreepHealth()
	local creep = self.creep
	local heal_percent = 3

	if creep:GetHealth() > 0 and creep:GetHealth() ~= creep:GetMaxHealth() and self.regenAmount <= creep:GetMaxHealth() then

		local healthPre = creep:GetHealth() 
		creep:Heal(creep:GetMaxHealth() * (heal_percent / self.maxRegen), nil)
		local healthPost = creep:GetHealth()
		self.regenAmount = self.regenAmount + (healthPost - healthPre)
	end
end

RegisterCreepClass(CreepRegen, CreepRegen.className)