-- Dark tower class

DarkTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
	},
	{
		className = "DarkTower"
	},
nil)

function DarkTower:OnAttackLanded(keys)
	local target = keys.target
	local damage = self.tower:GetAverageTrueAttackDamage(target)
	
	local __, overkillDamage = DamageEntity(target, self.tower, damage)
	if overkillDamage and overkillDamage > 0 then

		local validTargets = {}
		local creeps = GetCreepsInArea(target:GetAbsOrigin(), self.aoe)
		for _, creep in pairs(creeps) do
			if creep:IsAlive() and creep:entindex() ~= target:entindex() then
				table.insert(validTargets, creep)
			end
		end 

		if #validTargets > 0 then
			local newTarget = validTargets[math.random(#validTargets)]
			self.overkillDamageTable[newTarget:entindex()] = overkillDamage
			--Log:debug("Overkill damage for entity " .. newTarget:entindex() .. " is " .. overkillDamage)

			ProjectileManager:CreateTrackingProjectile({
				Target = newTarget,
				Source = caster,
				Ability = self.ability,
				EffectName = "particles/custom/towers/dark/attack.vpcf",
				iMoveSpeed = self.overkillProjectileSpeed,
				vSourceLoc = target:GetAbsOrigin(),
				bReplaceExisting = false,
				flExpireTime = GameRules:GetGameTime() + 10,
			})
		end
	end
end

function DarkTower:OnProjectileHit(keys)
	local target = keys.target
	
	if target:IsAlive() then
		local overkillDamage = self.overkillDamageTable[target:entindex()]
		if overkillDamage then
			--Log:debug("Dealing " .. overkillDamage ..  " overkill damage to " .. target:entindex())
			self.overkillDamageTable[target:entindex()] = nil
			DamageEntity(target, self.tower, overkillDamage, true)
		end
	end
end


function DarkTower:OnCreated()
	self.ability = AddAbility(self.tower, "dark_tower_overkill") 
	self.aoe = GetAbilitySpecialValue("dark_tower_overkill", "aoe")
	self.overkillDamageTable = {}
	self.overkillProjectileSpeed = self.tower:GetProjectileSpeed() / 2
end

RegisterTowerClass(DarkTower, DarkTower.className)
