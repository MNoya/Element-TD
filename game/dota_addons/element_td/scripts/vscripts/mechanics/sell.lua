-- called when a sell_tower_x ability is cast
function SellTowerCast(keys)
    local tower = keys.caster

    if tower:GetHealth() == tower:GetMaxHealth() then -- only allow selling if the tower is fully built
        local hero = tower:GetOwner()
        local playerID = hero:GetPlayerID()
        local playerData = GetPlayerData(playerID)
        local goldCost = GetUnitKeyValue(tower.class, "TotalCost")
        local sellPercentage = tonumber(keys.SellAmount)
        local towerName = tower:GetUnitName()
        local refundAmount = round(goldCost * sellPercentage)

        -- Elemental Arrow/Cannon round up
        if (towerName:match("arrow") or towerName:match("cannon")) and not towerName:match("basic") then
            refundAmount = math.ceil(goldCost * sellPercentage)
        end

        if tower.isClone then
            RemoveClone(tower)
        else
            -- we must delete a random clone of this type
            if playerData.clones[tower.class] and tower:HasModifier("modifier_conjure_prevent_cloning") then
                RemoveRandomClone(playerData, tower.class)
            end
        end

        if tower.damageType and tower.damageType ~= "composite" then
            PlayElementalExplosion(tower.damageType, tower)
        end

        -- Remove random Blacksmith/Well buff when sold
        if tower.class == "blacksmith_tower" or tower.class == "well_tower" then
            RemoveRandomBuff(tower)
        end

        tower.sold = true
        if tower.scriptObject["OnDestroyed"] then
            tower.scriptObject:OnDestroyed()
        end

        -- Kills and hide the tower, so that its running timers can still execute until it gets removed by the engine
        tower:AddEffects(EF_NODRAW)
        ToggleGridForTower(tower)
        tower:ForceKill(true)
        playerData.towers[tower:entindex()] = nil -- remove this tower index from the player's tower list

        -- Grant the gold
        if sellPercentage > 0  then
            Sounds:EmitSoundOnClient(playerID, "Gold.CoinsBig")
            PopupAlchemistGold(tower, refundAmount)

            local coins = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, tower)
            ParticleManager:SetParticleControl(coins, 1, tower:GetAbsOrigin())

            -- Add gold
            hero:ModifyGold(refundAmount)

            -- If a tower costs a Pure Essence (Pure, Periodic), then that essence is refunded upon selling the tower.
            local essenceCost = GetUnitKeyValue(tower.class, "EssenceCost") or 0
            if essenceCost > 0 then
                ModifyPureEssence(playerID, essenceCost, true)
                PopupEssence(tower, essenceCost)
            end

            -- Add lost gold and towers sold
            local goldLost = goldCost - refundAmount
            playerData.goldLost = playerData.goldLost + goldLost
            playerData.towersSold = playerData.towersSold + 1
        end

        UpdateScoreboard(hero:GetPlayerID())
        Log:debug(playerData.name .. " has sold a tower")
        UpdatePlayerSpells(hero:GetPlayerID())
    end
end