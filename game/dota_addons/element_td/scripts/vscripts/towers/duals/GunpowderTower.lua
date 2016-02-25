-- Gunpowder Tower class (Dark + Earth)
-- Splash damage tower that does 30/150/750 damage with 1500 range and 0.66 attack speed with 100/200 AoE.
-- Upon impact the projectile splits into four more projectiles that scatter in a diagonal pattern (100 range from center, so one top, one bottom, one on each side)
-- around the impact point. Additional projectiles have same damage/AoE.

GunpowderTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "GunpowderTower"    
    },
nil)    

function GunpowderTower:OnAttackLanded(keys) 
    local origin = keys.origin
    if not origin then
        return
    end
      
    local damage = ApplyAbilityDamageFromModifiers(self.splashDamage[self.tower:GetLevel()], self.tower)    
    DamageEntitiesInArea(origin, self.splashAOE, self.tower, damage)

    keys.caster:EmitSound("Gunpower.Explosion") 

    local particle = ParticleManager:CreateParticle("particles/custom/towers/gunpowder/shrapnel.vpcf", PATTACH_CUSTOMORIGIN, self.tower)    
    ParticleManager:SetParticleControl(particle, 0, origin)
    ParticleManager:SetParticleControl(particle, 1, Vector(self.splashAOE, 1, 1))
    Timers:CreateTimer(1, function() ParticleManager:DestroyParticle(particle, true) end)

    --spawn random explosions around the initial point, after a small delay
    local rotate_pos = origin + Vector(1,0,0) * 100
    for i = 1, 4 do          
        local pos = RotatePosition(origin, QAngle(0, 90*i, 0), rotate_pos)

        if IsValidEntity(self.tower) then
            local damage = ApplyAbilityDamageFromModifiers(self.splashDamage[self.tower:GetLevel()], self.tower)    
            DamageEntitiesInArea(pos, self.splashAOE, self.tower, damage)
        end
    end
end

function GunpowderTower:OnCreated()
  self.ability = AddAbility(self.tower, "gunpowder_tower_shrapnade", self.tower:GetLevel())     
  self.splashDamage = GetAbilitySpecialValue("gunpowder_tower_shrapnade", "damage")    
  self.splashAOE = GetAbilitySpecialValue("gunpowder_tower_shrapnade", "splash_aoe")    
  self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))
  self.towerRange = self.tower:GetAttackRange()

  Timers:CreateTimer(function() 
        if IsValidEntity(self.tower) and self.tower:IsAlive() then
            if not self.tower:HasModifier("modifier_attacking_ground") then
                local attackTarget = self.tower:GetAttackTarget() or self.tower:GetAggroTarget()
                if attackTarget then
                    local distanceToTarget = (self.tower:GetAbsOrigin() - attackTarget:GetAbsOrigin()):Length2D()
                    if distanceToTarget > self.towerRange then
                        self.tower:Interrupt()
                    end
                end
            end
            return 0.5
        end
    end)
end


RegisterTowerClass(GunpowderTower, GunpowderTower.className)    