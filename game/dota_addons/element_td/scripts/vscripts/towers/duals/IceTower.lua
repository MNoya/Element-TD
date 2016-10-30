-- Ice (Light + Water)
-- Each attack is a linear ball of ice. Does damage if it hits creeps, double damage if the creep is hit by the middle. 
-- Explodes after travelling a certain distance.
IceTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "IceTower"
    },
nil)    

function IceTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetAverageTrueAttackDamage(target)
	DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
	DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);


		local particle = ParticleManager:CreateParticle("particles/custom/towers/ice/attack.vpcf", PATTACH_CUSTOMORIGIN, target)
		local origin = target:GetAbsOrigin()
		origin.z = origin.z + 64
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, origin)
		ParticleManager:SetParticleControl(particle, 2, origin)
	    ParticleManager:ReleaseParticleIndex(particle)

	local time = GameRules:GetGameTime()
    if not target.ice_tower_stun or time >= target.ice_tower_stun+self.threshold_duration then
        self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_ice_tower_stun", {duration=self.ministun_duration})
        target.ice_tower_stun = GameRules:GetGameTime()
    end
end

function IceTower:OnCreated()
	self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
	self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.ability = AddAbility(self.tower, "ice_tower_ice_blast", self.tower:GetLevel())
    self.ministun_duration = self.ability:GetSpecialValueFor("ministun_duration")
    self.threshold_duration = 0.9
end

--[[ Removed in 1.15
function IceTower:OnAttack(keys)
    local target = keys.target
    local origin = keys.origin or (target and target:GetAbsOrigin())
    if not origin then return end

    local projectileTable = {
        Ability = self.ability,
        EffectName = "particles/custom/towers/ice/projectile.vpcf",
        vSpawnOrigin = self.projOrigin,
        fDistance = self.distance,
        fStartRadius = self.aoe_start,
        fEndRadius = self.aoe_end,
        Source = self.tower,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        bProvidesVision = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
    }
   
    local diff = origin - self.tower:GetAbsOrigin()
    diff.z = 0
    projectileTable.vVelocity = diff:Normalized() * self.projectile_speed

    ProjectileManager:CreateLinearProjectile( projectileTable )

    self.tower:EmitSound("Ice.Cast")
end

function IceTower:OnProjectileHit(keys)
    local damage = ApplyAbilityDamageFromModifiers(self.damage, self.tower)
    local target = keys.target
    DamageEntity(target, self.tower, damage)
    local particleName = "particles/econ/items/keeper_of_the_light/kotl_weapon_arcane_staff/keeper_base_attack_arcane_staff_explosion_b.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, self.tower)
    ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
end

function IceTower:OnCreated()
    self.ability = AddAbility(self.tower, "ice_tower_ice_blast", self.tower:GetLevel())    
    self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))    
    self.damage = GetAbilitySpecialValue("ice_tower_ice_blast", "damage")[self.tower:GetLevel()]
    self.aoe_start = GetAbilitySpecialValue("ice_tower_ice_blast", "aoe_start")
    self.aoe_end = GetAbilitySpecialValue("ice_tower_ice_blast", "aoe_end")
    self.distance = GetAbilitySpecialValue("ice_tower_ice_blast", "distance")
    self.projectile_speed = GetAbilitySpecialValue("ice_tower_ice_blast", "projectile_speed")

    -- Deny autoattack damage through damage filter
    self.tower.no_autoattack_damage = true

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
]]

RegisterTowerClass(IceTower, IceTower.className)    