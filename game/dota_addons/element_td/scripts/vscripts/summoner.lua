-- summoner.lua
-- manages the Elemental Summoner and Elementals

ElementalBaseHealth = {1000, 5000, 25000};
Particles = {
	light_elemental = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf",
};

function ModifyLumber(playerID, amount)
	GetPlayerData(playerID).lumber = GetPlayerData(playerID).lumber + amount;
	UpdateSummonerSpells(playerID);
	FireGameEvent("etd_update_lumber", {playerID = playerID, amount = GetPlayerData(playerID).lumber});
end

function UpdateSummonerSpells(playerID)
	local lumber = GetPlayerData(playerID).lumber;
	local summoner = GetPlayerData(playerID).summoner;
	local playerData = GetPlayerData(playerID);

	if playerData.elementalActive then
		for k, v in pairs(NPC_ABILITIES_CUSTOM) do
			if summoner:HasAbility(k) and v["LumberCost"]  then
				local ability = summoner:FindAbilityByName(k);
				ability:SetActivated(false);
				ability:SetLevel(playerData.elements[v["Element"]] + 1);
			end
		end
	else
		for k, v in pairs(NPC_ABILITIES_CUSTOM) do
			if summoner:HasAbility(k) and v["LumberCost"] then
				local ability = summoner:FindAbilityByName(k);
				ability:SetActivated(lumber >= v["LumberCost"] and playerData.elements[v["Element"]] < 3);
				ability:SetLevel(playerData.elements[v["Element"]] + 1);
			end
		end
	end
end

function BuyElement(playerID, element)
	local playerData = GetPlayerData(playerID);

	if playerData.lumber > 0 then
		ModifyLumber(playerID, -1);
		ModifyElementValue(playerID, element, 1);
	end
end

function SummonElemental(keys)
	local summoner = keys.caster;
	local playerID = summoner:GetOwner():GetPlayerID();
	local playerData = GetPlayerData(playerID);
	local element = GetUnitKeyValue(keys.Elemental, "Element");

	if not WAVE_1_STARTED then
		BuyElement(playerID, element);
		return;
	end

	playerData.elementalActive = true;
	ModifyLumber(playerID, -1);

	local elemental = CreateUnitByName(keys.Elemental, EntityStartLocations[playerData.sector + 1], true, nil, nil, DOTA_TEAM_NOTEAM);
	elemental:AddNewModifier(nil, nil, "modifier_phased", {});
	elemental["element"] = element;
	elemental["isElemental"] = true;
	elemental["playerID"] = playerID;
	elemental["class"] = keys.Elemental;

	playerData.elementalUnit = elemental;

	GlobalCasterDummy:ApplyModifierToTarget(elemental, "creep_damage_block_applier", "modifier_damage_block");
	ApplyArmorModifier(elemental, GetPlayerDifficulty(playerID):GetArmorValue() * 100);
	
	local level = playerData.elements[element] + 1;
	local health = ElementalBaseHealth[level] * math.pow(1.5, (math.floor(playerData.nextWave / 5) - 1));
	elemental:SetMaxHealth(health);
	elemental:SetBaseMaxHealth(health); -- This is needed to properly set the max health otherwise it won't work sometimes
	elemental:SetHealth(health);
	elemental:SetActualModelScale(elemental:GetModelScale() + ((level - 1) * 0.1));
	elemental:SetForwardVector(Vector(0, -1, 0));
	elemental:SetCustomHealthLabel(GetEnglishTranslation(keys.Elemental), ElementColors[element][1], ElementColors[element][2], ElementColors[element][3]);

	local particle = Particles[keys.Elemental];
	if particle then
		local h = ParticleManager:CreateParticle(particle, 2, elemental); 
		ParticleManager:SetParticleControlEnt(h, 0, elemental, 5, "attach_origin", elemental:GetOrigin(), true);
	end

	CreateTimer("MoveElemental" .. elemental:entindex(), INTERVAL, {
        loops = -1,
        interval = 1,
        executeImmediately = true,
        destination = EntityEndLocations[playerData.sector + 1],
        playerID = playerID,
        unit = elemental,

        callback = (function(timer)
            local entity = timer.unit;
        
            ExecuteOrderFromTable({
                UnitIndex = entity:entindex(),
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                Position = timer.destination
            });

            if dist2D(entity:GetOrigin(), timer.destination) <= 150 then
                local playerData = PlayerData[timer.playerID];

                playerData.health = playerData.health - 3;
                local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero();
                if hero:GetHealth() <= 3 then
                	playerData.health = 0;
                	hero:ForceKill(false);
					ElementTD:EndGameForPlayer(hero:GetPlayerID()); -- End the game for the dead player
                else
					hero:SetHealth(hero:GetHealth() - 3);
				end
                --Say(nil, playerData.name .. "'s Health: " .. playerData.health, false);

                FindClearSpaceForUnit(entity, EntityStartLocations[playerData.sector + 1], true) -- remove interp frames on client
                --entity:SetOrigin(EntityStartLocations[playerID + 1]);
                entity:SetForwardVector(Vector(0, -1, 0));
            end
        end)

    });
end