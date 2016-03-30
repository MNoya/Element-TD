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
	local damage = self.tower:GetAverageTrueAttackDamage()
	DamageEntity(target, self.tower, damage);
end

function NatureTower:CreepKilled(keys)
	local target = keys.unit
	if target:entindex() ~= self.tower:entindex() then
		target:EmitSound("DOTA_Item.Tango.Activate")
		
		local particle = ParticleManager:CreateParticle("particles/custom/towers/nature/spore_explosion.vpcf", PATTACH_CUSTOMORIGIN, target)
		local origin = target:GetAbsOrigin()
		origin.z = origin.z+64
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, origin)
		ParticleManager:SetParticleControl(particle, 2, origin)
	    ParticleManager:ReleaseParticleIndex(particle)

	    DamageEntitiesInArea(target:GetOrigin(), self.aoe_full, self.tower, self.explosion_damage)   
	    DamageEntitiesInArea(target:GetOrigin(), self.aoe_half, self.tower, self.explosion_damage)  
    end 

end


function NatureTower:OnCreated()
	self.ability = AddAbility(self.tower, "nature_tower_spore_explosion", self.tower:GetLevel()) 
	self.explosion_damage = self.ability:GetSpecialValueFor("damage") / 2;
	self.aoe_full = self.ability:GetSpecialValueFor("aoe_full")
	self.aoe_half = self.ability:GetSpecialValueFor("aoe_half")
end

RegisterTowerClass(NatureTower, NatureTower.className)
