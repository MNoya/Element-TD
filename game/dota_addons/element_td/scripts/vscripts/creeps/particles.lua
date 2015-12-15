function LavaSpawn( event )
    local target = event.target

    local particle = ParticleManager:CreateParticle("particles/custom/creeps/lava/ambient_esl.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function LavaSpawnDeath( event )
    local unit = event.unit

    local particle = ParticleManager:CreateParticle("particles/custom/creeps/lava/death_esl.vpcf", PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
end

function WindSpirit( event )
    local unit = event.unit

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_storm_death.vpcf", PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    unit:AddNoDraw()
end

function DeathProphet( event )
    local unit = event.unit

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_death.vpcf", PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    unit:AddNoDraw()
end

function HellSworn( event )
    local target = event.target

    local particle = ParticleManager:CreateParticle("particles/econ/items/warlock/warlock_hellsworn_construct/golem_hellsworn_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 7, target, PATTACH_POINT_FOLLOW, "attach_mane2", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 10, target, PATTACH_POINT_FOLLOW, "attach_attack1", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 11, target, PATTACH_POINT_FOLLOW, "attach_attack2", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 12, target, PATTACH_POINT_FOLLOW, "attach_mane2", target:GetAbsOrigin(), true)
end

function HellSwornDeath( event )
    local unit = event.unit

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_death.vpcf", PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
end

function IceFrog( event )
    local target = event.target

    local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_eye_r", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 2, target, PATTACH_POINT_FOLLOW, "attach_eye_l", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 15, Vector(0,191,255))

    local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)         

    --target:SetRenderColor(0, 191, 255)
                
end

function IceFrogDeath( event )
    local unit = event.unit

    local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_murrissey_the_smeevil/courier_murrissey_the_smeevil_death.vpcf", PATTACH_CUSTOMORIGIN, unit)
    ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
    
    --unit:StartGesture(ACT_DOTA_SPAWN)
end