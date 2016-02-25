function CDOTA_BaseNPC:HasGroundAttack()
    local unitName = self:GetUnitName()
    return NPC_UNITS_CUSTOM[unitName] and NPC_UNITS_CUSTOM[unitName]["AttackGround"]
end

function CDOTA_BaseNPC:GetRangedProjectileName()
    local unitName = self:GetUnitName()
    return NPC_UNITS_CUSTOM[unitName] and NPC_UNITS_CUSTOM[unitName]["ProjectileModel"] or ""
end

function CDOTA_BaseNPC:GetAttackSound()
    local unitName = self:GetUnitName()
    return NPC_UNITS_CUSTOM[unitName] and NPC_UNITS_CUSTOM[unitName]["AttackSound"]
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

----------------------------------------------------------------------------------------------------
-- Point ground datariven ability
function AttackGround( event )
    local caster = event.caster
    local ability = event.ability
    local position = event.target_points[1]
    local start_time = caster:GetAttackAnimationPoint() -- Time to wait to fire the projectile

    ability:ToggleOn()

    -- Disable autoattack acquiring
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_attacking_ground", {})

    -- Time fake attacks
    ability.attack_ground_timer = Timers:CreateTimer(function()
        caster:StartGesture(ACT_DOTA_ATTACK)
        ability.attack_ground_timer_attack = Timers:CreateTimer(caster:TimeUntilNextAttack(), function()
            caster:AttackNoEarlierThan(1/caster:GetAttacksPerSecond() - start_time)

            local attackSound = caster:GetAttackSound()
            if attackSound then
                caster:EmitSound(attackSound)
            end

            if caster.scriptObject and caster.scriptObject.OnAttack then
                caster.scriptObject:OnAttack()
            end

            -- Create the projectile and deal damage on hit            
            AttackGroundPos(caster, position)
        end)

        local time = 1 / caster:GetAttacksPerSecond()   

        return  time
    end)
end


function StopAttackGround( event )
    local caster = event.caster
    local ability = event.ability

    caster:RemoveGesture(ACT_DOTA_ATTACK)
    if (ability.attack_ground_timer) then Timers:RemoveTimer(ability.attack_ground_timer) end
    if (ability.attack_ground_timer_attack) then Timers:RemoveTimer(ability.attack_ground_timer_attack) end
    caster:RemoveModifierByName("modifier_attacking_ground")

    ability:ToggleOff()
end