function CDOTA_BaseNPC:HasGroundAttack()
    local unitName = self:GetUnitName()
    return NPC_UNITS_CUSTOM[unitName] and NPC_UNITS_CUSTOM[unitName]["AttackGround"]
end

function CDOTA_BaseNPC:GetRangedProjectileName()
    local unitName = self:GetUnitName()
    return NPC_UNITS_CUSTOM[unitName] and NPC_UNITS_CUSTOM[unitName]["ProjectileModel"] or ""
end


-- Attack Ground for Artillery attacks, redirected from FilterProjectile
function AttackGroundPos(attacker, position)
    local speed = attacker:GetProjectileSpeed()
    local projectile = ParticleManager:CreateParticle(attacker:GetRangedProjectileName(), PATTACH_CUSTOMORIGIN, attacker)
    ParticleManager:SetParticleControl(projectile, 0, attacker:GetAttachmentOrigin(attacker:ScriptLookupAttachment("attach_attack1")))
    ParticleManager:SetParticleControl(projectile, 1, position)
    ParticleManager:SetParticleControl(projectile, 2, Vector(speed, 0, 0))
    ParticleManager:SetParticleControl(projectile, 3, position)

    local distanceToTarget = (attacker:GetAbsOrigin() - position):Length2D()
    local time = distanceToTarget/speed
    Timers:CreateTimer(time, function()
        -- Destroy the projectile
        ParticleManager:DestroyParticle(projectile, false)

        -- Deal attack damage
        if attacker.scriptObject and attacker.scriptObject.OnAttackLanded then
            attacker.scriptObject:OnAttackLanded({caster=attacker, origin=position})
        end
    end)
end