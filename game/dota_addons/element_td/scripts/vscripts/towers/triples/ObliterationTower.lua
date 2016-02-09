-- Obliteration (Darkness + Light + Nature)
-- This is a long range single target tower. The projectile starts out faster than normal but slows down as it travels. 
-- As it travels the projectile gains more and more splash. If the projectile slows to a stop before hitting the target it explodes. 
-- Projectile starts at 0 splash and maxes out at X splash. Projectile should have a travel range longer than the tower's attack range. 
-- It may be good cosmetics to have the projectile grow as it travels.

ObliterationTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "ObliterationTower"
    },
nil)

function ObliterationTower:OnAttack(keys)
    local target = keys.target
    local caster = keys.caster

    local info = 
    {
        Target = target,
        Source = caster,
        Ability = keys.ability,
        EffectName = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf",
        iMoveSpeed = 900,
        vSourceLoc = caster:ScriptLookupAttachment("attach_attack1"),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, --DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
        bDrawsOnMinimap = false,
        bDodgeable = true,
        bIsAttack = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        flExpireTime = GameRules:GetGameTime() + 10,
        bProvidesVision = true,
        iVisionRadius = 400,
        iVisionTeamNumber = caster:GetTeamNumber()
    }
    projectile = ProjectileManager:CreateTrackingProjectile(info)
end

function ObliterationTower:OnProjectileHit(keys)
    local target = keys.target
    local distance = dist2D(target:GetAbsOrigin(), self.tower:GetAbsOrigin())
    local splashAOE = self.initialSplash + ((self.maxSplash-self.initialSplash)/self.attackRange) * distance
    local explosionParticle = ParticleManager:CreateParticle("particles/custom/towers/obliteration/impact_area.vpcf", PATTACH_CUSTOMORIGIN, keys.caster)
    ParticleManager:SetParticleControl(explosionParticle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(explosionParticle, 1, Vector(splashAOE, 0, 1))
    ParticleManager:SetParticleControl(explosionParticle, 2, Vector(0, 0, 0))
    ParticleManager:SetParticleControl(explosionParticle, 3, target:GetAbsOrigin())

    local entities = GetCreepsInArea(target:GetAbsOrigin(), splashAOE)
    for _, entity in pairs(entities) do
        local damage = self.tower:GetAverageTrueAttackDamage()
        DamageEntity(entity, self.tower, damage, self.tower)
    end
end

function ObliterationTower:OnCreated()
    self.ability = AddAbility(self.tower, "obliteration_tower_obliterate")
    self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))
    self.groundHeight = GetGroundPosition(self.tower:GetOrigin(), nil).z + 200
    self.projectiles = {}
    self.attackRange = self.tower:GetAttackRange()
    self.projDuration = GetAbilitySpecialValue("obliteration_tower_obliterate", "duration")
    self.maxSplash = GetAbilitySpecialValue("obliteration_tower_obliterate", "max_aoe")
    self.initialSplash = GetAbilitySpecialValue("obliteration_tower_obliterate", "initial_aoe")
end

function ObliterationTower:OnDestroyed()
    for id,_ in pairs(self.projectiles) do
        UTIL_Remove(EntIndexToHScript(id))
    end
end

function ObliterationTower:OnAttackLanded(keys) end
RegisterTowerClass(ObliterationTower, ObliterationTower.className)