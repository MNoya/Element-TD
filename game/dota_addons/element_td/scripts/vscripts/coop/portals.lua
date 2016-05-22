function OpenCoopPortal()
    CoopPortal = Entities:FindByName(nil, "coop_portal")
    CoopPortal.particle = ParticleManager:CreateParticle("particles/custom/portals/coop_portal.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(CoopPortal.particle, 0, CoopPortal:GetAbsOrigin())
    UpdateCoopPortal(1)
    ShowArrowHelp()
end

function UpdateCoopPortal(wave)
    if not CoopPortal then OpenCoopPortal() end

    local element = string.gsub(creepsKV[WAVE_CREEPS[wave]].CreepAbility1, "_armor", "")
    ParticleManager:SetParticleControl(CoopPortal.particle, 15, GetElementColor(element))

    if CoopPortal.vortex then
        ParticleManager:DestroyParticle(CoopPortal.vortex, true)
    end

    if element ~= composite then
        CoopPortal.vortex = ParticleManager:CreateParticle("particles/custom/portals/"..element.."_vortex.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(CoopPortal.vortex, 0, CoopPortal:GetAbsOrigin())
    end
end

function CloseCoopPortal()
    local portal = Entities:FindByName(nil, "coop_portal")
    if portal and portal.particle then
        ParticleManager:DestroyParticle(portal.particle, true)
    end
end

function ShowArrowHelp()
    CoopPortal.arrows = {}

    local arrows = Entities:FindAllByName("arrow*")
    for _,v in pairs(arrows) do
        local names = split(v:GetName(), ",")
        local particleName = names[1]
        local lookup = Entities:FindByName(nil, names[2])
        
        local arrow = ParticleManager:CreateParticle("particles/custom/tutorial/"..particleName..".vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(arrow, 0, v:GetAbsOrigin())
        ParticleManager:SetParticleControl(arrow, 1, lookup:GetAbsOrigin())
        table.insert(CoopPortal.arrows, arrow)
    end
end

function CloseArrowHelp()
    local portal = Entities:FindByName(nil, "coop_portal")
    if portal and portal.arrows then
        for _,v in pairs(CoopPortal.arrows) do
            ParticleManager:DestroyParticle(v, true)
        end
        portal.arrows = nil
    end
end