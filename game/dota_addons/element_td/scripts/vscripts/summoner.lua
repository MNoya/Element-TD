-- summoner.lua
-- manages the Elemental Summoner and Elementals

ElementalBaseHealth = {1000, 5000, 25000}
Particles = {
    light_elemental = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf",
}

ExplosionParticles = {
    water = "particles/custom/elements/water/explosion.vpcf",
    fire = "particles/custom/elements/fire/explosion.vpcf",
    nature = "particles/custom/elements/nature/explosion.vpcf",
    earth = "particles/custom/elements/earth/explosion.vpcf",
    light = "particles/custom/elements/light/explosion.vpcf",
    dark = "particles/custom/elements/dark/explosion.vpcf",
}

TrailParticles = {
    water = "particles/econ/items/lion/fish_stick/fish_stick_spell_ambient.vpcf",
    fire = "particles/econ/courier/courier_trail_lava/courier_trail_lava.vpcf",
    nature = "particles/custom/elements/nature/courier_greevil_green_ambient_3.vpcf",
    earth = "particles/custom/elements/earth/trail.vpcf",
    light = "particles/econ/courier/courier_trail_05/courier_trail_05.vpcf",
    dark = "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf",
}

ElementalSounds = {
    water = "morphling_mrph_",
    water_S = 8,
    water_D = 12,
    fire = "lina_lina_",
    fire_S = 9,
    fire_D = 12,
    nature = "furion_furi_",
    nature_S = 3,
    nature_D = 11,
    earth = "tiny_tiny_",
    earth_S = 9,
    earth_D = 13,
    light = "keeper_of_the_light_keep_",
    light_S = 5,
    light_D = 15,
    dark = "nevermore_nev_",
    dark_S = 11,
    dark_D = 19,
}

function GetSoundNumber( max )
    local rand = math.random(max)
    local str = ""
    str = string.format("%02d", rand)
    return str
end

function ModifyLumber(playerID, amount)
    local playerData = GetPlayerData(playerID)
    playerData.lumber = playerData.lumber + amount
    UpdateSummonerSpells(playerID)
    if amount > 0 then
        PopupLumber(ElementTD.vPlayerIDToHero[playerID], amount)

        if playerData.elementalCount == 0 then
            Highlight(playerData.summoner)
        end

        if GameSettings.elementsOrderName == "AllPick" then
            SendLumberMessage(playerID, "#etd_lumber_add")
        end
    end

    local current_lumber = playerData.lumber
    local summoner = playerData.summoner
    if current_lumber > 0 then
        if not summoner.particle then
            local origin = summoner:GetAbsOrigin()
            local particleName = "particles/econ/courier/courier_trail_01/courier_trail_01.vpcf"
            summoner.particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, summoner, PlayerResource:GetPlayer(playerID))
            ParticleManager:SetParticleControl(summoner.particle, 0, Vector(origin.x, origin.y, origin.z+30))
            ParticleManager:SetParticleControl(summoner.particle, 15, Vector(255,255,255))
            ParticleManager:SetParticleControl(summoner.particle, 16, Vector(1,0,0))
        end        
    else
        if summoner.particle then
            ParticleManager:DestroyParticle(summoner.particle, false)
            summoner.particle = nil
        end
    end

    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_lumber", { lumber = current_lumber } )
    UpdateScoreboard(playerID)
end

function ModifyPureEssence(playerID, amount)
    GetPlayerData(playerID).pureEssence = GetPlayerData(playerID).pureEssence + amount
    UpdatePlayerSpells(playerID)
    if amount > 0 then
        PopupEssence(ElementTD.vPlayerIDToHero[playerID], amount)
        SendEssenceMessage(playerID, "#etd_essence_add")
    end
    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_pure_essence", { pureEssence = GetPlayerData(playerID).pureEssence } )
    UpdateScoreboard(playerID)
end

function UpdateSummonerSpells(playerID)
    local lumber = GetPlayerData(playerID).lumber
    local summoner = GetPlayerData(playerID).summoner
    local playerData = GetPlayerData(playerID)

    UpdateRunes(playerID)

    if EXPRESS_MODE and not playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local level = playerData.elements[v["Element"]] + 1
                local ability = summoner:FindAbilityByName(k)
                if level == 1 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 2 and playerData.completedWaves >= 6 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 3 and playerData.completedWaves >= 15 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                else
                    ability:SetActivated(false)
                end
                ability:SetLevel(level)
            end
        end
    elseif playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(false)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    else
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(lumber >= v["LumberCost"] and playerData.elements[v["Element"]] < 3)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    end
end

RUNES = {
    ["water"] = { model = "models/props_gameplay/rune_doubledamage01.vmdl", animation = "rune_doubledamage_anim" },
    ["fire"] = { model = "models/props_gameplay/rune_haste01.vmdl", animation = "rune_haste_idle" },
    ["nature"] = { model = "models/props_gameplay/rune_regeneration01.vmdl", animation = "rune_regeneration_anim" },
    ["earth"] = { model = "models/props_gameplay/rune_illusion01.vmdl", animation = "rune_illusion_idle" },
    ["light"] = { model = "models/props_gameplay/rune_arcane.vmdl", animation = "rune_arcane_idle" },
    ["dark"] = { model = "models/props_gameplay/rune_invisibility01.vmdl", animation = "rune_invisibility_idle" }
}

function UpdateRunes(playerID)
    local summoner = GetPlayerData(playerID).summoner
    local origin = summoner:GetAbsOrigin()
    local angle = 360/6
    local rotate_pos = origin + Vector(1,0,0) * 90
    summoner.runes = summoner.runes or {["water"] = {}, ["fire"] = {}, ["nature"] = {}, ["earth"] = {}, ["light"] = {}, ["dark"] = {}}

    local i = 0
    for element,value in pairs(summoner.runes) do
        local level = GetPlayerElementLevel(playerID, element)
        if level > 0 then
            local position = RotatePosition(origin, QAngle(0, angle*i, 0), rotate_pos)
            if not value.level then
                summoner.runes[element].props = CreateRune( element, position, level )
            elseif value.level ~= level then
                ClearRunes(summoner.runes[element].props)
                summoner.runes[element].props = CreateRune( element, position, level )
            end
            summoner.runes[element].level = level
        end
        i=i+1
    end   
end

function CreateRune( element, position, level )
    local angle = 360/level
    local rotate_pos = position + Vector(1,0,0) * 20
    local props = {}

    for i=1,level do
        local rune = SpawnEntityFromTableSynchronous("prop_dynamic", {model = RUNES[element].model, DefaultAnim = RUNES[element].animation})
        local pos = RotatePosition(position, QAngle(0, angle*(i-1), 0), rotate_pos)
        rune:SetModelScale(1-level*0.1)
        rune:SetAbsOrigin(pos)

        table.insert(props, rune)
    end

    return props
end

function ClearRunes( propsTable )
    for k,v in pairs(propsTable) do
        v:RemoveSelf()
    end
end

function BuyPureEssence( keys )
	local summoner = keys.caster
    local item = keys.ability
	local playerID = summoner:GetOwner():GetPlayerID()
	local playerData = GetPlayerData(playerID)
	local elements = playerData.elements

    if playerData.health == 0 then
        return
    end

	if playerData.lumber > 0 then
		local hasLvl3 = false
		local hasLvl1 = true
		for i,v in pairs(elements) do
			if v == 3 then -- if level 3 of element
				hasLvl3 = true
			end
			if v == 0 then
				hasLvl1 = false
			end
		end
		if hasLvl3 or hasLvl1 then
			ModifyLumber(playerID, -1)
			ModifyPureEssence(playerID, 1)
            playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
			Sounds:EmitSoundOnClient(playerID, "General.Buy")
            item:SetCurrentCharges(item:GetCurrentCharges()-1)
            if item:GetCurrentCharges() == 0 then
                item:RemoveSelf()
            end
		else
            Log:info("Player " .. playerID .. " does not meet the pure essence purchase requirements.")
            ShowWarnMessage(playerID, "#etd_essence_buy_warning")
		end
	else
        ShowWarnMessage(playerID, "#etd_need_more_lumber")
    end
end

function BuyElement(playerID, element)
    local playerData = GetPlayerData(playerID)

    if playerData.lumber > 0 then
        ModifyLumber(playerID, -1)
        ModifyElementValue(playerID, element, 1)

        AddElementalTrophy(playerID, element)
    end
end

function SummonElemental(keys)
    local summoner = keys.caster
    local playerID = summoner:GetOwner():GetPlayerID()
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

    if playerData.elementalCount == 0 or EXPRESS_MODE then
        BuyElement(playerID, element)
        return
    end

    playerData.elementalActive = true
    ModifyLumber(playerID, -1)

    local level = playerData.elements[element] + 1
    local name = keys.Elemental..level

    local elemental = CreateUnitByName(name, EntityStartLocations[playerData.sector + 1], true, nil, nil, DOTA_TEAM_NEUTRALS)
    elemental:AddNewModifier(nil, nil, "modifier_phased", {})
    elemental["element"] = element
    elemental["isElemental"] = true
    elemental["playerID"] = playerID
    elemental["class"] = keys.Elemental

    -- Trail effect
    local particle = ParticleManager:CreateParticle(TrailParticles[element], PATTACH_ABSORIGIN_FOLLOW, elemental)

    playerData.elementalUnit = elemental

    elemental:AddNewModifier(elemental, nil, "modifier_damage_block", {});
    --GlobalCasterDummy:ApplyModifierToTarget(elemental, "creep_damage_block_applier", "modifier_damage_block")
    --ApplyArmorModifier(elemental, GetPlayerDifficulty(playerID):GetArmorValue() * 100)
    
    local health = ElementalBaseHealth[level] * math.pow(1.5, (math.floor(playerData.nextWave / 5) - 1)) * difficulty:GetHealthMultiplier()
    local scale = elemental:GetModelScale() + ((level - 1) * 0.1)
    elemental:SetMaxHealth(health)
    elemental:SetBaseMaxHealth(health) -- This is needed to properly set the max health otherwise it won't work sometimes
    elemental:SetHealth(health)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(Vector(0, -1, 0))
    elemental:SetCustomHealthLabel(GetEnglishTranslation(keys.Elemental), ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
    elemental.level = level

    -- Adjust health bar
    CustomNetTables:SetTableValue("elementals", tostring(elemental:GetEntityIndex()), {health_marker=health/4})
    elemental:AddNewModifier(elemental, nil, "modifier_health_bar_markers", {})

    local particle = Particles[keys.Elemental]
    if particle then
        local h = ParticleManager:CreateParticle(particle, 2, elemental) 
        ParticleManager:SetParticleControlEnt(h, 0, elemental, 5, "attach_origin", elemental:GetOrigin(), true)
    end

    Sounds:EmitSoundOnClient(playerID, ElementalSounds[element].."spawn_"..GetSoundNumber(ElementalSounds[element.."_S"]), ply)

    Timers:CreateTimer(0.1, function()
        if not IsValidEntity(elemental) or not elemental:IsAlive() then return end
        
        local entity = elemental
        local destination = EntityEndLocations[playerData.sector + 1]

        ExecuteOrderFromTable({ UnitIndex = entity:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = destination, Queue = false })

        if dist2D(entity:GetOrigin(), destination) <= 150 then
            local playerData = PlayerData[playerID]

            playerData.health = playerData.health - 3
            local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
            if hero:GetHealth() <= 3 and hero:GetHealth() > 0 then
                playerData.health = 0
                hero:ForceKill(false)
                if playerData.completedWaves >= WAVE_COUNT and not EXPRESS_MODE then
                    playerData.scoreObject:UpdateScore( SCORING_GAME_CLEAR )
                else
                       playerData.scoreObject:UpdateScore( SCORING_WAVE_LOST )
                   end
                ElementTD:EndGameForPlayer(hero:GetPlayerID()) -- End the game for the dead player
            else
                hero:SetHealth(hero:GetHealth() - 3)
            end
            Sounds:EmitSoundOnClient(playerID, "ui.click_back")
            CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
            UpdateScoreboard(playerID)
            --Say(nil, playerData.name .. "'s Health: " .. playerData.health, false)

            FindClearSpaceForUnit(entity, EntityStartLocations[playerData.sector + 1], true)
            entity:SetForwardVector(Vector(0, -1, 0))
        end
        return 1
    end)
end

function AddElementalTrophy(playerID, element)
    local team = PlayerResource:GetTeam(playerID)
    local level = GetPlayerElementLevel(playerID, element)
    local unitName = element.."_elemental"..level
    local scale = GetUnitKeyValue(unitName, "ModelScale") + ((level - 1) * 0.1)
    local playerData = GetPlayerData(playerID)
    local summoner = playerData.summoner

    -- Elementals are placed from east to west X, at the same Y of the summoner
    playerData.elemCount = playerData.elemCount or 0 --Number of elementals killed
    local count = playerData.elemCount

    -- At 9 we make another row
    local Y = -100
    if count >= 9 then 
        Y = 100
        count = count - 9
    end

    local position = summoner:GetAbsOrigin() + Vector(750,Y,0) + count * Vector(120,0,0)
    playerData.elemCount = playerData.elemCount + 1

    local elemental = CreateUnitByName(unitName, position, false, nil, nil, team)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(Vector(0, -1, 0))

    elemental:AddNewModifier(elemental, nil, "modifier_disabled", {})
end