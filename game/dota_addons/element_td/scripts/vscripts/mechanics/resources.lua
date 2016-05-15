-- All gold is reliable. The gold value is stored on the playerData
function CDOTA_BaseNPC_Hero:ModifyGold(goldAmount)
    local hero = self
    local playerID = hero:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)

    if goldAmount < 0 and playerData.freeTowers then
        return
    end

    local goldGain = math.floor(goldAmount)
    local remainder = goldAmount - goldGain -- floating point component
    playerData.gold_remainder = playerData.gold_remainder + remainder -- accumulated
    if (playerData.gold_remainder >= 1) then
        playerData.gold_remainder = playerData.gold_remainder - 1
        goldGain = goldGain + 1
    end

    local newGold = tonumber(playerData.gold) + tonumber(goldGain)
    SetCustomGold(playerID, newGold)
end

function CDOTA_BaseNPC_Hero:GetGold()
    local hero = self
    local playerID = hero:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    return playerData.gold
end

function CDOTA_PlayerResource:GetGold(playerID)
    return GetPlayerData(playerID).gold
end

function CDOTA_PlayerResource:GetTotalGold()
    local totalGold = 0
    ForAllPlayerIDs(function(playerID)
        totalGold = totalGold + PlayerResource:GetGold(playerID)
    end)
    return totalGold
end

function SetCustomGold(playerID, amount)
    local playerData = GetPlayerData(playerID)
    local player = PlayerResource:GetPlayer(playerID)

    playerData.gold = amount

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
        hero:SetGold(0, false)
        hero:SetGold(playerData.gold, true) --This can go up to 99.999 gold, but the UI will still show bigger values
    end

    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "etd_update_gold", { gold = playerData.gold } )
    end
end

function ModifyLumber(playerID, amount)
    local playerData = GetPlayerData(playerID)

    SetCustomLumber(playerID, playerData.lumber + amount)

    if amount > 0 then
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        local summoner = playerData.summoner

        if hero then
            PopupLumber(hero, amount)
        end

        if summoner and playerData.elementalCount == 0 then
            Highlight(summoner, playerID)
        end

        if GameSettings.elementsOrderName == "AllPick" then
            SendLumberMessage(playerID, "#etd_lumber_add", amount)
        end
    end
end

function SetCustomLumber(playerID, amount)
    local playerData = GetPlayerData(playerID)

    playerData.lumber = amount
    UpdateSummonerSpells(playerID)    
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
        hero:SetAbilityPoints(playerData.lumber)
    end

    local current_lumber = playerData.lumber
    local summoner = playerData.summoner
    if summoner then
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

        local player = PlayerResource:GetPlayer(playerID)
        if player then
            CustomGameEventManager:Send_ServerToPlayer(player, "etd_update_lumber", { lumber = current_lumber, summoner = summoner:GetEntityIndex() } )
        end
    end

    UpdateScoreboard(playerID)
end

-- Essence
function ModifyPureEssence(playerID, amount, bSkipMessage)
    local playerData = GetPlayerData(playerID)
    SetCustomEssence(playerID, playerData.pureEssence + amount)    

    if amount > 0 and not bSkipMessage then
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if hero then
            PopupEssence(hero, amount)
        end
        SendEssenceMessage(playerID, "#etd_essence_add", amount)
    end
end

function SetCustomEssence(playerID, amount)
    local playerData = GetPlayerData(playerID)
    playerData.pureEssence = amount
    UpdatePlayerSpells(playerID)
    
    local player = PlayerResource:GetPlayer(playerID)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "etd_update_pure_essence", { pureEssence = playerData.pureEssence } )
    end
    UpdateScoreboard(playerID)
end

-- item_buy_pure_essence
function BuyPureEssence( keys )
    local summoner = keys.caster
    local item = keys.ability
    local playerID = summoner:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    local elements = playerData.elements

    if playerData.health == 0 then
        return
    end

    if playerData.lumber > 0 then
        ModifyLumber(playerID, -1)
        ModifyPureEssence(playerID, 1)
        playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
        playerData.pureEssencePurchase = playerData.pureEssencePurchase + 1
        Sounds:EmitSoundOnClient(playerID, "General.Buy")

        -- Track pure essence purchasing as part of the element order
        playerData.elementOrder[#playerData.elementOrder+1] = "Pure"
        
        -- Gold bonus to help stay valuable by comparison to getting an element upgrade (removed in 1.5)
        -- GivePureEssenceGoldBonus(playerID)

        if IsValidEntity(item) then
            item:SetCurrentCharges(item:GetCurrentCharges()-1)
            if item:GetCurrentCharges() == 0 then
                item:RemoveSelf()
            end
        end

        UpdateScoreboard(playerID)
    else
        ShowWarnMessage(playerID, "#etd_need_more_lumber")
    end
end

-- item_buy_pure_essence_disabled
function BuyPureEssenceWarn( event )
    local playerID = event.caster:GetPlayerOwnerID()

    if not CanPlayerBuyPureEssence(playerID) then
        Log:info("Player " .. playerID .. " does not meet the pure essence purchase requirements.")
        ShowWarnMessage(playerID, "#etd_essence_buy_warning", 4)
    end
end

function BuyLumberForEssence( event )
    local summoner = event.caster
    local item = event.ability
    local playerID = summoner:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    local elements = playerData.elements

    if playerData.health == 0 then
        return
    end

    if playerData.pureEssence > 0 then
        ModifyLumber(playerID, 1)
        ModifyPureEssence(playerID, -1)
        playerData.pureEssenceTotal = playerData.pureEssenceTotal - 1
        Sounds:EmitSoundOnClient(playerID, "General.Buy")

        item:RemoveSelf()
        UpdateScoreboard(playerID)
    else
        ShowWarnMessage(playerID, "#etd_need_more_essence")
    end
end

--item_buy_lumber_disabled
function BuyLumberWarn( event )
    local playerID = event.caster:GetPlayerOwnerID()

    if not CanPlayerBuy12thElement(playerID) then
        ShowWarnMessage(playerID, "#etd_lumber_buy_warning", 4)
    end
end

-- Bonus for trading lumber->essence
-- not used anymore since 1.5
function GivePureEssenceGoldBonus( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    local waveNumber = playerData.nextWave
    local difficultyBountyBonus = playerData.difficulty:GetBountyBonusMultiplier()
    local extra_gold
    if EXPRESS_MODE then
        extra_gold = round(math.pow(waveNumber+5, 2.3) * difficultyBountyBonus)
    else
        extra_gold = round(math.pow(waveNumber+5, 2) * difficultyBountyBonus)
    end
    PopupAlchemistGold(PlayerResource:GetSelectedHeroEntity(playerID), extra_gold)
    hero:ModifyGold(extra_gold, true, 0)
end

-- Directly adds the element
function BuyElement(playerID, element)
    local playerData = GetPlayerData(playerID)

    if playerData.lumber > 0 then
        ModifyLumber(playerID, -1)
        ModifyElementValue(playerID, element, 1)
        AddElementalTrophy(playerID, element, GetPlayerElementLevel(playerID, element))
        UpdatePlayerHealth(playerID)
    end
end