-- manages the elemental summons
function SummonElemental(keys)
    local summoner = keys.caster
    local playerID = summoner:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    local element = GetUnitKeyValue(keys.Elemental.."1", "Element")
    local difficulty = playerData.difficulty

    if playerData.health == 0 then
        return
    end

    -- Explosion cast effect for each element
    local explosion = ParticleManager:CreateParticle(ExplosionParticles[element], PATTACH_CUSTOMORIGIN, summoner)
    local origin = summoner:GetAbsOrigin()
    origin.z = origin.z + 20
    ParticleManager:SetParticleControl(explosion, 0, origin)

    if EXPRESS_MODE or COOP_MAP or (playerData.freeElements > 0 and playerData.elements[element] < 2) then
        playerData.freeElements = math.max(playerData.freeElements - 1, 0) -- don't want this to go below 0 in express or co-op
        Sounds:PlayElementalDeathSound(playerID, element)
        BuyElement(playerID, element)
        return
    end

    playerData.elementalActive = true
    ModifyLumber(playerID, -1)

    local level = playerData.elements[element] + 1
    local name = keys.Elemental..level

    local marker_dummy = CreateUnitByName("tower_dummy", EntityStartLocations[playerData.sector + 1], false, nil, nil, PlayerResource:GetTeam(playerID))

    local elemental = CreateUnitByName(name, EntityStartLocations[playerData.sector + 1], true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not elemental then
        print("Failed to spawn ",name)
        return
    end
    elemental:AddNewModifier(nil, nil, "modifier_phased", {})
    elemental["element"] = element
    elemental["isElemental"] = true
    elemental["playerID"] = playerID
    elemental["class"] = keys.Elemental
    elemental.marker_dummy = marker_dummy

    -- Spawn sound
    Sounds:PlayElementalSpawnSound(playerID, elemental)

    -- Trail effect
    local particle = ParticleManager:CreateParticle(TrailParticles[element], PATTACH_ABSORIGIN_FOLLOW, elemental)

    playerData.elementalUnit = elemental
    
    -- Adjust health bar
    -- Every five waves elemental HP goes up by 50%. So if you summon a level 1 at wave 20 you get 1,519 HP.
    local health = ElementalBaseHealth[level] * math.pow(1.5, (math.floor(playerData.nextWave / 5))) * difficulty:GetHealthMultiplier()
    CustomNetTables:SetTableValue("elementals", tostring(elemental.marker_dummy:GetEntityIndex()), {health_marker=health/4})
    Timers:CreateTimer(0.03, function()
        marker_dummy:AddNewModifier(elemental.marker_dummy, nil, "modifier_health_bar_markers", {})
    end)

    local scale = elemental:GetModelScale()
    elemental:SetMaxHealth(health)
    elemental:SetBaseMaxHealth(health) -- This is needed to properly set the max health otherwise it won't work sometimes
    elemental:SetHealth(health)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(Vector(0, -1, 0))
    elemental.level = level

    -- create a script object for this entity
    if CHALLENGE_MODE then
        local wrapper = ClassWrapper:new() -- wrap single ability for convenience

        local abilityName = AbilitiesMode:GetRandomElementalAbilityName()    
        local scriptClassName = AbilitiesMode:GetClassNameFromAbility(abilityName)

        local scriptObject = CREEP_CLASSES[scriptClassName](elemental, name)  
        scriptObject.ability = AddAbility(elemental, abilityName)
        wrapper:Wrap(scriptClassName, scriptObject)

        elemental.scriptObject = wrapper
        CREEP_SCRIPT_OBJECTS[elemental:entindex()] = wrapper

        wrapper:OnSpawned()
    end

    local label = GetEnglishTranslation(keys.Elemental) or keys.Elemental
    if label then
        elemental:SetCustomHealthLabel(label, ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
    end

    -- Adjust slows multiplicatively
    elemental:AddNewModifier(elemental, nil, "modifier_slow_adjustment", {})

    local particle = Particles[keys.Elemental]
    if particle then
        local h = ParticleManager:CreateParticle(particle, 2, elemental) 
        ParticleManager:SetParticleControlEnt(h, 0, elemental, 5, "attach_origin", elemental:GetOrigin(), true)
    end

    -- Check towers precache as if the element is already acquired
    local potentialElements = shallowcopy(playerData.elements)
    potentialElements[element] = potentialElements[element] and potentialElements[element] + 1 or 1
    Precache:CheckTowers(potentialElements)

    Timers:CreateTimer(0.1, function()
        if not IsValidEntity(elemental) or not elemental:IsAlive() then
            elemental.marker_dummy:RemoveSelf()
            return 
        end
        
        local entity = elemental
        local destination = EntityEndLocations[playerData.sector + 1]

        ExecuteOrderFromTable({ UnitIndex = entity:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = destination, Queue = false })

        if (entity:GetAbsOrigin() - destination):Length2D() <= 100 then
            local playerData = PlayerData[playerID]

            -- Minus 3 lives
            ReduceLivesForPlayer(playerID, 3)

            Sounds:EmitSoundOnClient(playerID, "ui.click_back")
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
            UpdateScoreboard(playerID)
            --Say(nil, playerData.name .. "'s Health: " .. playerData.health, false)

            FindClearSpaceForUnit(entity, EntityStartLocations[playerData.sector + 1], true)
            entity:SetForwardVector(Vector(0, -1, 0))
        end
        return 0.1
    end)
end

function AddElementalTrophy(playerID, element, level)
    local team = PlayerResource:GetTeam(playerID)
    local unitName = element.."_elemental"..level
    local scale = GetUnitKeyValue(unitName, "ModelScale")
    local playerData = GetPlayerData(playerID)
    local summoner = playerData.summoner

    -- Classic: Elementals are placed from east to west X, 2 rows
    -- Coop: all in 1 row, orientation depends on the player placement on the map

    playerData.elemCount = playerData.elemCount or 0 --Number of elementals killed
    local count = playerData.elemCount
    local position
    local offset = Vector(0,0,0)
    local angle = Vector(0, -1, 0)

    if COOP_MAP then
        if playerID == 0 or playerID == 1 then
            offset = Vector(150,0,0)
        elseif playerID == 3 then
            offset = Vector(0,150,0)
            angle = Vector(1,0,0)
        elseif playerID == 2 then
            offset = Vector(0,-150,0)
            angle = Vector(-1,0,0)
        end

        position = summoner:GetAbsOrigin() + (1.5+count) * offset
    else
        -- At 6 we make another row
        local Y = -100
        if count >= 6 then 
            Y = 100
            count = count - 6
        end
        if Y == 100 then
            offset = Vector(75, 0, 0)
        end
        position = summoner:GetAbsOrigin() + Vector(750,Y,0) + count * Vector(150,0,0) + offset
    end

    playerData.elemCount = playerData.elemCount + 1

    local elemental = CreateUnitByName(unitName, position, false, nil, nil, team)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(angle)
    elemental:AddNewModifier(elemental, nil, "modifier_disabled", {})

    table.insert(playerData.elementTrophies, elemental)
end