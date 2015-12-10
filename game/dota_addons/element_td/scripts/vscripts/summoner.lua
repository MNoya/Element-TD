-- summoner.lua
-- manages the Elemental Summoner and Elementals

ElementalBaseHealth = {1000, 5000, 25000}
Particles = {
	light_elemental = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf",
}

function ModifyLumber(playerID, amount)
	GetPlayerData(playerID).lumber = GetPlayerData(playerID).lumber + amount
	UpdateSummonerSpells(playerID)
	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_lumber", { lumber = GetPlayerData(playerID).lumber } )
end

function ModifyPureEssence(playerID, amount)
	GetPlayerData(playerID).pureEssence = GetPlayerData(playerID).pureEssence + amount
	UpdatePlayerSpells(playerID)
	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_pure_essence", { pureEssence = GetPlayerData(playerID).pureEssence } )
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
	["light"] = { model = "models/props_gameplay/rune_goldxp.vmdl", animation = "rune_goldxp_anim" },
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
	local element = GetUnitKeyValue(keys.Elemental, "Element")

	if not WAVE_1_STARTED or EXPRESS_MODE then
		BuyElement(playerID, element)
		return
	end

	playerData.elementalActive = true
	ModifyLumber(playerID, -1)

	local elemental = CreateUnitByName(keys.Elemental, EntityStartLocations[playerData.sector + 1], true, nil, nil, DOTA_TEAM_NOTEAM)
	elemental:AddNewModifier(nil, nil, "modifier_phased", {})
	elemental["element"] = element
	elemental["isElemental"] = true
	elemental["playerID"] = playerID
	elemental["class"] = keys.Elemental

	playerData.elementalUnit = elemental

	GlobalCasterDummy:ApplyModifierToTarget(elemental, "creep_damage_block_applier", "modifier_damage_block")
	--ApplyArmorModifier(elemental, GetPlayerDifficulty(playerID):GetArmorValue() * 100)
	
	local level = playerData.elements[element] + 1
	local health = ElementalBaseHealth[level] * math.pow(1.5, (math.floor(playerData.nextWave / 5) - 1))
	local scale = elemental:GetModelScale() + ((level - 1) * 0.1)
	elemental:SetMaxHealth(health)
	elemental:SetBaseMaxHealth(health) -- This is needed to properly set the max health otherwise it won't work sometimes
	elemental:SetHealth(health)
	elemental:SetModelScale(scale)
	elemental:SetForwardVector(Vector(0, -1, 0))
	elemental:SetCustomHealthLabel(GetEnglishTranslation(keys.Elemental), ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
	elemental.level = level

	local particle = Particles[keys.Elemental]
	if particle then
		local h = ParticleManager:CreateParticle(particle, 2, elemental) 
		ParticleManager:SetParticleControlEnt(h, 0, elemental, 5, "attach_origin", elemental:GetOrigin(), true)
	end

	Timers:CreateTimer("MoveElemental" .. elemental:entindex(), {
		callback = function()
            local entity = elemental
            local destination = EntityEndLocations[playerData.sector + 1]

            ExecuteOrderFromTable({
                UnitIndex = entity:entindex(),
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                Position = destination
            })

            if dist2D(entity:GetOrigin(), destination) <= 150 then
                local playerData = PlayerData[playerID]

                playerData.health = playerData.health - 3
                local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
                if hero:GetHealth() <= 3 then
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
                --Say(nil, playerData.name .. "'s Health: " .. playerData.health, false)

                FindClearSpaceForUnit(entity, EntityStartLocations[playerData.sector + 1], true) -- remove interp frames on client
                --entity:SetOrigin(EntityStartLocations[playerID + 1])
                entity:SetForwardVector(Vector(0, -1, 0))
            end
			return 1
		end
	})
end

function AddElementalTrophy(playerID, element)
	local team = PlayerResource:GetTeam(playerID)
	local unitName = element.."_elemental"
    local level = GetPlayerElementLevel(playerID, element)
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
	elemental:SetCustomHealthLabel(GetEnglishTranslation(unitName), ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])

	elemental:AddNewModifier(elemental, nil, "modifier_disabled", {})
end