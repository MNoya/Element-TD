-- Nature tower class

NatureTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
	},
	{
		className = "NatureTower"
	},
nil)

function NatureTower:OnAttackLanded(keys)
	local target = keys.target;
	local base_damage = self.tower:GetAverageTrueAttackDamage(target)
	local damage = base_damage
	local num_creeps = 0

	local creeps = GetCreepsInArea(target:GetAbsOrigin(), self.ability_radius)
	for _, creep in pairs(creeps) do
		if creep:entindex() ~= target:entindex() and creep:IsAlive() then
			num_creeps = num_creeps + 1
			damage = damage + (base_damage * self.damage_increase)
		end
	end
	
	-- damage popup if it gains any bonus damage
	if damage > base_damage then
		PopupNatureDamage(self.tower, math.floor(damage))
	end

	-- make a cool particle effect if the damage is increased by at least 30%
	if num_creeps >= 3 then
		local particle = ParticleManager:CreateParticle("particles/custom/towers/nature/force_of_nature.vpcf", PATTACH_CUSTOMORIGIN, target)
		local origin = target:GetAbsOrigin()
		origin.z = origin.z + 64
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, origin)
		ParticleManager:SetParticleControl(particle, 2, origin)
	    ParticleManager:ReleaseParticleIndex(particle)
	end	

	DamageEntity(target, self.tower, math.floor(damage));
end

function NatureTower:OnCreated()
	self.ability = AddAbility(self.tower, "nature_tower_force_of_nature") 
	self.ability_radius = self.ability:GetSpecialValueFor("aoe")
	self.damage_increase = self.ability:GetSpecialValueFor("damage") / 100
end

RegisterTowerClass(NatureTower, NatureTower.className)
