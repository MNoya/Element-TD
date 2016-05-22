function UpdateElementOrbs(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero then return end
    local orb_path = "particles/custom/orbs/"
    local distance = hero:GetUnitName() == "npc_dota_hero_wisp" and 80 or 100

    if not hero.orbit_entities then
        hero.orbit_entities = {}
        hero.orb_count = 0
    end

    -- Clear orbs
    if hero.orb_count > 0 then
        for i=1,hero.orb_count do
            UTIL_Remove(hero.orbit_entities[i])
        end
    end

    -- Build list
    local elements = {}
    local playerData = GetPlayerData(playerID)
    for k,v in pairs(playerData.elements) do
        if v > 0 and k ~="pure" then
            table.insert(elements, k)
        end
    end

    hero.orb_count = #elements
    if hero.orb_count < 6 then
       hero.orb_count = hero.orb_count + 1
    end

    -- Recreate orbs
    for k=1,#elements do
        local ent = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/props_gameplay/red_box.vmdl"})
        local angle = 360 / hero.orb_count
        local origin = hero:GetAbsOrigin()
        local rotate_pos = origin + Vector(1,0,0) * distance
        local pos = RotatePosition(origin, QAngle(0, angle*k, 0), rotate_pos)
        pos.z = pos.z + 90
        ent:SetAbsOrigin(pos)
        ent:SetParent(hero, "attach_hitloc")
        ent:AddEffects(EF_NODRAW)
        hero.orbit_entities[k] = ent

        -- Create particle attached to the entity
        local particleName = orb_path.."orb_"..elements[k]..".vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, ent)
        ParticleManager:SetParticleControlEnt(particle, 3, ent, PATTACH_POINT_FOLLOW, "attach_hitloc", ent:GetAbsOrigin(), true)
    end
end

function RemoveElementalOrbs(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero and hero.orbit_entities then
        for i=1,hero.orb_count do
            UTIL_Remove(hero.orbit_entities[i])
        end
    end
end