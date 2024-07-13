-- entry point for all tower upgrades
function UpgradeTower(keys)
    local ability = keys.ability
    local tower = keys.caster
    local hero = tower:GetOwner()
    local newClass = keys.tower -- the class of the tower to upgrade to
    local cost = GetUnitKeyValue(newClass, "Cost") -- Old GetCostForTower(newClass)
    local playerID = hero:GetPlayerID()
    local playerData = GetPlayerData(playerID)
    local essenceCost = GetUnitKeyValue(newClass, "EssenceCost") or 0
    local playerEssence = GetPlayerData(playerID).pureEssence
    
    if not MeetsItemElementRequirements(ability, playerID) and not playerData.freeTowers then
        ShowWarnMessage(playerID, "Incomplete Element Requirements!")
    elseif essenceCost > playerEssence and not playerData.freeTowers then
        ShowWarnMessage(playerID, "You need 1 Essence! Buy it at the Elemental Summoner")
    elseif cost > hero:GetGold() and not playerData.freeTowers then
        ShowWarnMessage(playerID, "Not Enough Gold!")
    elseif tower:GetHealth() == tower:GetMaxHealth() then
        ability:RemoveSelf() --remove the item to prevent a case were the item could be cast twice on the same frame

        local index = tower:GetEntityIndex()
        if playerData.towers[index] then
            playerData.towers[index] = nil --remove it from the player's tower list
        else
            -- handles the edge case where 2 tower upgrades are spam-queued while upgrading
            return
        end

        if not playerData.freeTowers then
            hero:ModifyGold(-cost)
            ModifyPureEssence(playerID, -essenceCost)
        end

        local scriptClassName = GetUnitKeyValue(newClass, "ScriptClass") or "BasicTower"

        -- Keep buff data before replacing
        local buffData = GetBuffData(tower)
        local stacks = tower:GetModifierStackCount("modifier_kill_count", tower)
        local bWasCloned = tower:HasModifier("modifier_conjure_prevent_cloning")

        -- Replace the tower by a new one
        local newTower = BuildingHelper:UpgradeBuilding(tower, newClass)

        -- Add upgrade cancelling ability
        newTower.upgradedFrom = tower:GetUnitName()
        AddAbility(newTower, "cancel_construction")

        -- Set the new tower properties
        SetupTowerUpgrade(tower, newTower, buffData, stacks)

        -- Hide sell ability
        FindSellAbility(newTower):SetHidden(true)

        -- When you sell/upgrade a tower that has been cloned in the last 60 seconds, you lose a random clone of that tower type (this is to prevent abuse with 100% sell).
        -- we must delete a random clone of this type
        if playerData.clones[tower.class] and bWasCloned then
            RemoveRandomClone(playerData, tower.class)
        end

        -- Start the tower building animation
        if tower.scriptClass == scriptClassName then
            BuildTower(newTower, tower:GetModelScale())
        else
            BuildTower(newTower)
        end
    end
end

function MeetsRequirements(elements, req)
    for e, l in pairs(req) do
        if tonumber(l) > elements[e] then
            return false
        end
    end
    return true
end

function MeetsAbilityElementRequirements(name, playerID)
    local req = GetAbilityKeyValue(name, "Requirements")

    if req then
        local playerData = GetPlayerData(playerID)
        for e, l in pairs(req) do
            if tonumber(l) > playerData.elements[e] then
                return false
            end
        end
    end
    return true
end

function MeetsItemElementRequirements(upgrade_item, playerID)
    local name = upgrade_item:GetAbilityName()
    local req = GetItemKeyValue(name, "Requirements")

    if req then
        local playerData = GetPlayerData(playerID)
        for e, l in pairs(req) do
            if tonumber(l) > playerData.elements[e] then
                return false
            end
        end
    end
    return true
end

-- cancel_building
function CancelConstruction(event)
    local ability = event.ability
    local tower = event.caster
    local hero = tower:GetOwner()
    local playerID = hero:GetPlayerID()
    local playerData = GetPlayerData(playerID)
    local goldCost = GetUnitKeyValue(tower:GetUnitName(), "Cost")
    local essenceCost = GetUnitKeyValue(tower.class, "EssenceCost") or 0

    if tower.upgradedFrom then
        tower:Stop()

        local newClass = tower.upgradedFrom
        local buffData = GetBuffData(tower)
        local stacks = tower:GetModifierStackCount("modifier_kill_count", tower)

        -- Replace the tower by a new one
        local newTower = BuildingHelper:UpgradeBuilding(tower, newClass)
        SetupTowerUpgrade(tower, newTower, buffData, stacks)

        newTower:AddNewModifier(newTower, nil, "modifier_no_health_bar", {})

        -- Prevent the new tower from attacking earlier than the old tower could
        if tower.timeToAttack then
            newTower:AddNewModifier(nil, nil, "modifier_stunned", {duration=tower.timeToAttack})
        end

        newTower.scriptObject:OnBuildingFinished()
    else
        Sounds:EmitSoundOnClient(playerID, "Gold.CoinsBig") 
        PopupAlchemistGold(tower, goldCost)
        local coins = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_CUSTOMORIGIN, tower)
        ParticleManager:SetParticleControl(coins, 1, tower:GetAbsOrigin())

        if essenceCost > 0 then
            PopupEssence(tower, essenceCost)
        end

        if tower.damageType and tower.damageType ~= "composite" then
            PlayElementalExplosion(tower.damageType, tower)
        end

        tower:AddEffects(EF_NODRAW)
        ToggleGridForTower(tower)
        tower:Kill(null, false)
    end

    -- Gold
    hero:ModifyGold(goldCost)

    -- Essence
    if essenceCost > 0 then
        ModifyPureEssence(playerID, essenceCost, true)
    end

    -- Removal
    playerData.towers[tower:entindex()] = nil -- remove this tower index from the player's tower list
end

-- Setups tower items
function UpdateUpgrades(tower)
    local class = tower.class
    local playerID = tower:GetPlayerOwnerID()
    local data = GetPlayerData(playerID)
    local upgrades = NPC_UNITS_CUSTOM[class].Upgrades

    -- do not add items to a clone tower
    if tower:HasModifier("modifier_clone") then
        return
    end

    -- delete all items first
    for i = 0, 5, 1 do
        local item = tower:GetItemInSlot(i)
        if item then
            UTIL_Remove(item)
        end
    end

    -- Add small delay to fix items disappearing issue
    Timers:CreateTimer(0.01, function()
        -- now add them again
        if upgrades.Count then
            local count = tonumber(upgrades.Count)
            for i = 1, count, 1 do
                local upgrade = upgrades[tostring(i)]
                local cost = tonumber(NPC_UNITS_CUSTOM[upgrade].Cost)
                local suffix = ""

                -- Put a _disabled item if the requirement isn't met yet
                if NPC_UNITS_CUSTOM[upgrade].Requirements then
                    for element, level in pairs(NPC_UNITS_CUSTOM[upgrade].Requirements) do
                        if level > data.elements[element] then
                            suffix = "_disabled"
                        end
                    end
                end

                local item = CreateItem("item_upgrade_to_" .. upgrade .. suffix, nil, nil)
                tower:AddItem(item)
            end
        end
    end)
end

-- starts the tower building animation
function BuildTower(tower, baseScale)
    tower:RemoveModifierByName("modifier_invulnerable")
    tower:RemoveModifierByName("modifier_tower_truesight_aura")
    tower:AddNewModifier(nil, nil, "modifier_disarmed", {}) --towers are disarmed until they finish building
    tower:AddNewModifier(nil, nil, "modifier_stunned", {}) --towers are stunned until they finish building

    local buildTime = GetUnitKeyValue(tower.class, "BuildTime")
    if not buildTime then
        print(tower.class .. " does not have a build time!")
        buildTime = 1
    else
        buildTime = tonumber(buildTime)
    end

    -- No Cooldown in sandbox
    if GetPlayerData(tower:GetPlayerOwnerID()).noCD then
        buildTime = 0.05
    end

    local scale = tower:GetModelScale()
    baseScale = baseScale or (scale / 2) -- Start at the old size (if its the same model) or at half the end size
    local scaleIncrement = (scale - baseScale) / (buildTime * 20)

    tower:SetModelScale(baseScale)
    tower:SetMaxHealth(buildTime * 20)
    tower:SetBaseMaxHealth(buildTime * 20)
    tower:SetHealth(1)
    tower:SetHullRadius(HULL_RADIUS)

    -- create a timer to build up the tower slowly
    Timers:CreateTimer(0.05, function()
        if not IsValidEntity(tower) or not tower:IsAlive() then return end
        tower:SetHealth(tower:GetHealth() + 1)
        tower:SetModelScale(tower:GetModelScale() + scaleIncrement)

        if tower:GetHealth() == tower:GetMaxHealth() then
            tower:RemoveModifierByName("modifier_disarmed")
            tower:RemoveModifierByName("modifier_stunned")
            tower:AddNewModifier(nil, nil, "modifier_invulnerable", {})

            tower:SetMaxHealth(GetUnitKeyValue(tower.class, "TotalCost"))
            tower:SetBaseMaxHealth(GetUnitKeyValue(tower.class, "TotalCost"))

            tower:SetHealth(tower:GetMaxHealth())

            -- Remove building cancel ability
            tower:RemoveAbility("cancel_construction")

            -- Show sell ability
            local sell_ability = FindSellAbility(tower)
            if sell_ability then
                sell_ability:SetHidden(false)
            end

            tower.scriptObject:OnBuildingFinished()
            return
        end
        return 0.05
    end)
end

function SetupTowerUpgrade(tower, newTower, buffData, stacks)
    local playerID = tower:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    local scriptClassName = GetUnitKeyValue(newTower:GetUnitName(), "ScriptClass") or "BasicTower"
    local newClass = newTower:GetUnitName()
    local timeToAttack = tower:TimeUntilNextAttack() --Keep this time to prevent cancel-abuse

    -- Kill count is transfered if the tower is upgraded to one of the same type (single/dual/triple)
    InitializeKillCount(newTower)
    if scriptClassName == tower.scriptClass then
        TransferKillCount(stacks, newTower)
    end

    -- set some basic values to this tower from its KeyValues
    newTower.class = newClass
    newTower.element = GetUnitKeyValue(newClass, "Element")
    newTower.damageType = GetUnitKeyValue(newClass, "DamageType")

    -- New pedestal if one wasn't created already
    if not newTower.prop then
        local basicName = newTower.damageType.."_tower"
        local pedestalName = GetUnitKeyValue(basicName, "PedestalModel")
        local prop = BuildingHelper:CreatePedestalForBuilding(newTower, basicName, GetGroundPosition(newTower:GetAbsOrigin(), nil), pedestalName)
    end

    playerData.towers[newTower:entindex()] = newClass --add this tower to the player's tower list
    UpdateUpgrades(newTower) --update this tower's upgrades
    UpdatePlayerSpells(playerID) --update the player's spells

    local upgradeData = {}
    if tower.scriptObject and tower.scriptObject["GetUpgradeData"] then
        upgradeData = tower.scriptObject:GetUpgradeData()
    end

    -- Add sell ability
    if IsPlayerUsingRandomMode(playerID) then
        AddAbility(newTower, "sell_tower_100")
    elseif string.find(newTower.class, "arrow_tower") ~= nil or string.find(newTower.class, "cannon_tower") ~= nil then
        AddAbility(newTower, "sell_tower_98")
    else
        AddAbility(newTower, "sell_tower_90")
    end

    if string.match(newClass, "cannon_tower") then
        AddAbility(newTower, "attack_ground")
    end

    -- Apply render color
    if string.match(newClass, "arrow_tower") or string.match(newClass, "cannon_tower") then
        local color = ElementColors[split(newClass, "_")[1]]
        if color then
            newTower:SetRenderColor(color[1], color[2], color[3])
        end
    end

    -- create a script object for this tower
    if TOWER_CLASSES[scriptClassName] then
        local scriptObject = TOWER_CLASSES[scriptClassName](newTower, newClass)
        newTower.scriptClass = scriptClassName
        newTower.scriptObject = scriptObject
        newTower.scriptObject:OnCreated()
        if newTower.scriptObject["ApplyUpgradeData"] then
            newTower.scriptObject:ApplyUpgradeData(upgradeData)
        end
    else
        Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. newTower.class)
    end

    if timeToAttack > 0 then
        newTower.timeToAttack = timeToAttack
    end

    if IsSupportTower(newTower) then
        newTower:AddNewModifier(newTower, nil, "modifier_support_tower", {})
    end

    AddAbility(newTower, newTower.damageType .. "_passive")
    if GetUnitKeyValue(newClass, "AOE_Full") and GetUnitKeyValue(newClass, "AOE_Half") then
        AddAbility(newTower, "splash_damage_orb")
    end

    tower.deleted = true --mark the old tower for deletion

    if GetUnitKeyValue(newClass, "DisableTurning") then
        newTower:AddNewModifier(newTower, nil, "modifier_disable_turning", {})
    end

    Timers:CreateTimer(0.5, function()
        AddAbility(newTower, "ability_building")
    end)

    Timers:CreateTimer(0.03, function()
        ReapplyModifiers(newTower, buffData)
    end)

    Timers:CreateTimer(function()
        if PlayerResource:IsUnitSelected(playerID, tower) then
            PlayerResource:RemoveFromSelection(playerID, tower)
            PlayerResource:AddToSelection(playerID, newTower)
            PlayerResource:RefreshSelection()
        end
    end)
end