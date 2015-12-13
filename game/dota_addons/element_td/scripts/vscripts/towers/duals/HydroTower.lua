-- Hydro Tower class (Water + Earth)
-- This tower has a slow and non-homing projectile that does splash damage upon impact. Tower has an ability that makes it attack a point over and over again.
HydroTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HydroTower"
    },
nil)

function HydroTower:ChooseTarget(keys)
    if keys.target_points[1] then
        self.fixedTarget = keys.target_points[1]

        local resetAbility = AddAbility(self.tower, "hydro_tower_reset_target") 
        self.tower:SwapAbilities("hydro_tower_reset_target", "hydro_tower_choose_target", true, true)
        self.tower:RemoveAbility("hydro_tower_choose_target")

        resetAbility:StartCooldown(2)
        self.tower:AddNewModifier(nil, nil, "modifier_disarmed", {})
        self.attackTimer = Timers:CreateTimer(1, function()
            if IsValidEntity(self.tower) then
                self:ShootProjectileAt(self.fixedTarget)
                return 1
            end
        end)
    end
end

function HydroTower:ResetTarget(keys)
    self.tower:RemoveModifierByName("modifier_disarmed")
    Timers:RemoveTimer(self.attackTimer)

    local chooseAbility = AddAbility(self.tower, "hydro_tower_choose_target") 
    self.tower:SwapAbilities("hydro_tower_reset_target", "hydro_tower_choose_target", true, true)
    self.tower:RemoveAbility("hydro_tower_reset_target")
    chooseAbility:StartCooldown(2)
end

function HydroTower:OnAttackStart(keys)
    self:ShootProjectileAt(keys.target:GetAbsOrigin())
end

function HydroTower:ShootProjectileAt(targetPos)
    local projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))

    local projectile = {id = DoUniqueString("HydroTowerProjectile")}
    projectile.direction = (targetPos - projOrigin):Normalized()
    projectile.velocity = projectile.direction * 20
    projectile.target = targetPos
    projectile.origin = projOrigin

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_illusory_orb_main.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, Vector(0, 0, 0))
    ParticleManager:SetParticleControl(particle, 3, projectile.origin)

    Timers:CreateTimer(function()
        if not IsValidEntity(self.tower) then return end
        
        local pos = projectile.origin
        pos.x = pos.x + projectile.velocity.x
        pos.y = pos.y + projectile.velocity.y
        pos.z = pos.z + projectile.velocity.z
        projectile.origin = pos
        ParticleManager:SetParticleControl(particle, 3, pos)

        local distance = (projectile.target - pos):Length()
        if distance <= 50 then
            ParticleManager:DestroyParticle(particle, true)

            -- create explosion particle effect
            local e_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_illusory_orb_explode.vpcf", PATTACH_ABSORIGIN, self.tower)
            ParticleManager:SetParticleControl(e_particle, 0, Vector(0, 0, 0))
            ParticleManager:SetParticleControl(e_particle, 3, projectile.origin) -- position

            --deal aoe damage
            local damage = ApplyAbilityDamageFromModifiers(self.splashDamage[self.tower:GetLevel()], self.tower)
            DamageEntitiesInArea(pos, 400, self.tower, damage / 4)
            DamageEntitiesInArea(pos, 250, self.tower, damage / 4)
            DamageEntitiesInArea(pos, 125, self.tower, damage / 2)
            return
        end
        return 0.01
    end)
end

function HydroTower:OnCreated()
    self.ability = AddAbility(self.tower, "hydro_tower_ability") 
    AddAbility(self.tower, "hydro_tower_choose_target") 

    self.splashDamage = GetAbilitySpecialValue("hydro_tower_ability", "splash_damage")
    self.splashAOE = GetAbilitySpecialValue("hydro_tower_ability", "splash_aoe")

    self.targetingType = HYDRO_AUTO_TARGET
    self.fixedTarget = Vector(0, 0, 0)
end

function HydroTower:OnAttackLanded(keys) end

RegisterTowerClass(HydroTower, HydroTower.className)