-- CANNON TOWER
CannonTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
	},
	{
		className = "CannonTower"
	},
nil)

function CannonTower:OnAttack(keys)
    self.tower:EmitSound("Cannon.Launch")
end

function CannonTower:OnAttackLanded(keys)
    local origin = keys.origin
    if not origin then
        return
    end

	local damage = self.tower:GetAverageTrueAttackDamage()
	DamageEntitiesInArea(origin, self.halfAOE, self.tower, damage / 2)
	DamageEntitiesInArea(origin, self.fullAOE, self.tower, damage / 2)
	
	local pos = GetGroundPosition(origin, nil)
    local fx = GetExplosionFX(self.tower)
	local particle = ParticleManager:CreateParticle(fx, PATTACH_CUSTOMORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(200, 260, 0))
    ParticleManager:ReleaseParticleIndex(particle)
end

function CannonTower:OnCreated()
	self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
	self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))

    Timers:CreateTimer(function() 
        if IsValidEntity(self.tower) and self.tower:IsAlive() then
            if not self.tower:HasModifier("modifier_attacking_ground") then
                local attackTarget = self.tower:GetAttackTarget() or self.tower:GetAggroTarget()
                if attackTarget then
                    local distanceToTarget = (self.tower:GetAbsOrigin() - attackTarget:GetAbsOrigin()):Length2D()
                    if distanceToTarget > self.tower:GetAttackRange() then
                        self.tower:Interrupt()
                    end
                end
            end
            return 0.5
        end
    end)
end

RegisterTowerClass(CannonTower, CannonTower.className)