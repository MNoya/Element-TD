if not Rewards then
    Rewards = class({})
end

function Rewards:Init()
    Rewards.subscribed = true
    Rewards.reset = {}
    CustomGameEventManager:RegisterListener( "player_choose_custom_builder", Dynamic_Wrap(Rewards, 'OnPlayerChangeBuilder'))
    CustomGameEventManager:RegisterListener( "player_reset_builder", Dynamic_Wrap(Rewards, 'OnPlayerResetBuilder'))
end

function Rewards:OnPlayerChangeBuilder(event)
    local playerID = event.PlayerID
    local heroName = event.hero_name

    if GameRules:IsGamePaused() then 
        SendErrorMessage(playerID, "dota_hud_error_game_is_paused")
        return
    end

    -- If it's the same builder, ignore it
    local oldHero = PlayerResource:GetSelectedHeroEntity(playerID)
    if oldHero:GetUnitName() == heroName then return end

    -- Replace and handle wearables, animations, particles
    Rewards.reset[playerID] = true
    local newHero = Rewards:ReplaceHero(playerID, oldHero, heroName)
    RemoveAllWearables(newHero)
    UTIL_Remove(oldHero)

    -- Save choice
    Saves:SaveBuilder(playerID, heroName)
end

-- Goes back to Default Wisp/Custom Phoenix builder
function Rewards:OnPlayerResetBuilder(event)
    local playerID = event.PlayerID
    local oldHero = PlayerResource:GetSelectedHeroEntity(playerID)

    if GameRules:IsGamePaused() then 
        SendErrorMessage(playerID, "dota_hud_error_game_is_paused")
        return
    end

    -- If it's the same builder, ignore it
    if oldHero:GetUnitName() == "npc_dota_hero_wisp" or oldHero:GetUnitName() == "npc_dota_hero_phoenix" then return end

    local reward = Rewards:PlayerHasCosmeticModel(playerID)
    local heroName = (reward and reward.tier and reward.tier >= 10 and "npc_dota_hero_phoenix") or "npc_dota_hero_wisp"

    -- Replace and delegate to HandleHeroReplacement
    local newHero = Rewards:ReplaceHero(playerID, oldHero, heroName)
    newHero.reset = true
    UTIL_Remove(oldHero)

    if heroName == "npc_dota_hero_phoenix" then
        Rewards:ApplyCustomWispParticles(newHero)
    end

    -- Save default choice
    Saves:SaveBuilder(playerID, "npc_dota_hero_wisp")
end

function Rewards:WasHeroMarkedForReset(playerID)
    local bMarked = Rewards.reset[playerID] == true
    Rewards.reset[playerID] = true
    return bMarked
end

-- Pulls rewards.kv and eletd.com/reward_data.js
function Rewards:Load()
    Rewards.players = {}
    Rewards.file = LoadKeyValues("scripts/kv/rewards.kv")

    -- Take data from game files
    for steamID,values in pairs(Rewards.file) do
        Rewards.players[steamID] = values
        Rewards.players[steamID].tier = 25
    end

    local req = CreateHTTPRequest('GET', 'http://www.eletd.com/reward_data.js')
    
    -- Send the request
    req:Send(function(res)
        if res.StatusCode ~= 200 or not res.Body then
            print("[Rewards] Failed to contact rewards server.")
            return
        end

        -- Try to decode the result
        local obj, pos, err = json.decode(res.Body, 1, nil)

        -- Feed the result into our callback
        if err then
            print("[Rewards] Error in response : " .. err)
            return
        end

        -- Put the reward tiers in a nettable
        if obj and obj.players then
            for _,v in pairs(obj.players) do
                local data = Rewards.players[v.steamID] or {}                
                data.tier = v.reward
                Rewards.players[v.steamID] = data
                CustomNetTables:SetTableValue("rewards", v.steamID, data)
            end
        end
    end)
end

function Rewards:PlayerHasPass(playerID)
    return PlayerResource:HasCustomGameTicketForPlayerID(playerID) or Rewards.players[Rewards:ConvertID64(PlayerResource:GetSteamAccountID(playerID))] ~= nil
end

-- Checks if the player has a model change defined in local rewards file or in the request received in Load
function Rewards:PlayerHasCosmeticModel(playerID)
    local steamID32 = PlayerResource:GetSteamAccountID(playerID)
    local steamID64 = Rewards:ConvertID64(steamID32)

    local reward = Rewards.players[tostring(steamID64)]
    if reward and (not reward.tier or (reward.tier and reward.tier >= 10)) then
        return reward
    end

    -- Pass hero builder
    if reward and reward.hero then
        return reward
    end

    -- Enable wisp set outside of dedis
    --[[if not IsDedicatedServer() then
        return {tier=10}
    end]]

    return false
end

-- Resolves changing default wisp builder to another hero when the game starts
function Rewards:HandleHeroReplacement(hero)
    local playerID = hero:GetPlayerID()
    local reward = Rewards:PlayerHasCosmeticModel(playerID)
    if not reward then return end

    local hero_replacement = ((not hero.reset) and reward.hero) or "npc_dota_hero_phoenix"
    local newHero = Rewards:ReplaceHero(playerID, hero, hero_replacement)

    -- Main elemental heroes
    if reward.hero and not hero.reset then
        RemoveAllWearables(newHero)
        UTIL_Remove(hero)

    -- Models are based on a unit for precache async, and update the portrait
    elseif reward.model then
        PrecacheUnitByNameAsync(reward.model, function()
            local model = GetUnitKeyValue(reward.model, "Model")
            local scale = GetUnitKeyValue(reward.model, "ModelScale") or 1

            newHero:SetModel(model)
            newHero:SetOriginalModel(model)
            newHero:SetModelScale(scale)
            Rewards:ApplyAnimations(newHero, reward)

            -- Abilities to setup particles and attachments
            local ability1 = GetUnitKeyValue(reward.model, "Ability1")
            if ability1 then
                AddAbility(newHero, ability1)
                local ability2 = GetUnitKeyValue(reward.model, "Ability2")
                if ability2 then
                    AddAbility(newHero, ability2)
                end
            end

            UTIL_Remove(hero)
        end)

    -- Map Entity
    elseif reward.map_entity then
        local unit = Entities:FindByName(nil, reward.map_entity)
        if unit then
            unit.originalPos = unit:GetAbsOrigin()
            unit.originalAngles = unit:GetAngles()
            Rewards:SetCosmeticOverride(newHero, unit, reward)
            newHero.mapEntity = unit --Keep reference to revert back to the original Pos

            UTIL_Remove(hero)
        end

    -- Fake Unit (used for hero units with AttachWearables that aren't on the map)
    elseif reward.unit then
        PrecacheUnitByNameAsync(reward.unit, function()
            local unit = CreateUnitByNameAsync(reward.unit, hero:GetAbsOrigin(), false, newHero, nil, hero:GetTeamNumber(), 
            function(unit)
                if unit:IsHero() then
                    unit:SetPlayerID(playerID)
                    unit:SetControllableByPlayer(playerID, true)
                    unit:SetOwner(PlayerResource:GetPlayer(playerID))
                    unit:RespawnUnit()
                end
                Rewards:SetCosmeticOverride(newHero, unit, reward)

                -- Remove all abilities on the hero unit
                for i=0,15 do
                    local ability = unit:GetAbilityByIndex(i)
                    if ability then
                        ability:RemoveSelf()
                    end
                end

                -- Add any ability directly
                if reward.Ability then
                    Timers:CreateTimer(1, function()
                        AddAbility(unit, reward.Ability)
                    end)
                end

                UTIL_Remove(hero)
            end)
        end, playerID)
    
    -- Particle
    else
        Rewards:ApplyCustomWispParticles(newHero)
        UTIL_Remove(hero)
    end
end

function Rewards:ReplaceHero(playerID, oldHero, heroName)
    -- Keep the map entity
    if oldHero.mapEntity then
        oldHero.mapEntity:SetParent(nil, "")
        oldHero.mapEntity:RemoveModifierByName("modifier_out_of_world")
        oldHero.mapEntity:RemoveGesture(ACT_DOTA_RUN)
        oldHero.mapEntity:SetAbsOrigin(oldHero.mapEntity.originalPos)
        local angle = oldHero.mapEntity.originalAngles
        oldHero.mapEntity:SetAngles(angle.x, angle.y, angle.z)
    end

    oldHero:AddNoDraw()
    oldHero:ForceKill(true)

    -- Remove parented units
    if oldHero.cosmetic_override and not oldHero.mapEntity then
        UTIL_Remove(oldHero.cosmetic_override)
    end
    if oldHero.rider then
        UTIL_Remove(oldHero.rider)
    end
    RemoveElementalOrbs(playerID)

    -- Take the grid item so it doesn't get destroyed
    local playerData = GetPlayerData(playerID)
    if playerData and playerData.toggle_grid_item then
        playerData.toggle_grid_item_old = oldHero:Script_TakeItem(playerData.toggle_grid_item)
    end

    local newHero = PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)

    --- Add Cosmetics
    if NPC_HEROES_CUSTOM[heroName] then
        local cosmetic_ability = NPC_HEROES_CUSTOM[heroName]["CosmeticAbility"]
        if cosmetic_ability then
            newHero.cosmetic_ability = AddAbility(newHero, cosmetic_ability)
        end

         -- Add BuildAnimation or RiderBuildAnimation
        if NPC_HEROES_CUSTOM[heroName]["BuildAnimation"] then
            newHero.BuildAnimations = split(NPC_HEROES_CUSTOM[heroName]["BuildAnimation"], ",")
        elseif NPC_HEROES_CUSTOM[heroName]["RiderBuildAnimation"] then
            newHero.RiderBuildAnimations = split(NPC_HEROES_CUSTOM[heroName]["RiderBuildAnimation"], ",")
        end
    end

    -- Update ownership
    if playerData then
        if playerData.towers then
            for towerIndex, _ in pairs(playerData.towers) do
                local tower = EntIndexToHScript(towerIndex)
                if IsValidEntity(tower) and tower.scriptObject then
                    tower:SetOwner(newHero)
                end
            end
        end
        if playerData.summoner then
            playerData.summoner:SetOwner(newHero)
        end
    end

    -- Update abilities and orbs
    UpdatePlayerSpells(playerID)
    Timers(1, function()
        UpdateElementOrbs(playerID)
    end)

    newHero:SetBaseMaxHealth(GameSettings:GetMapSetting("Lives"))
    newHero:SetMaxHealth(GameSettings:GetMapSetting("Lives"))
    newHero:SetHealth(GetPlayerData(playerID).health)
    return newHero
end

-- Stores animation data on the unit
function Rewards:ApplyAnimations(unit, data)
    if data.build_animation then
        unit.build_animation = tonumber(data.build_animation)
    end
    if data.rare_animation then
        unit.rare_animation = tonumber(data.rare_animation)
        unit.rare_chance = data.rare_chance and tonumber(data.rare_chance) or 50
    end
    if data.animation_translate then
        AddAnimationTranslate(unit, data.animation_translate)
    end
end

-- Starts the necessary magic to have a
function Rewards:SetCosmeticOverride(hero, unit, reward)
    hero.cosmetic_override = unit
    unit:SetAbsOrigin(hero:GetAbsOrigin())
    if reward.scale then unit:SetModelScale(tonumber(reward.scale)) end
    unit:SetForwardVector(hero:GetForwardVector())
    unit:AddNewModifier(nil, nil, "modifier_out_of_world", {})
    unit:SetParent(hero, "attach_hitloc")

    if reward.precache_unit then
        PrecacheUnitByNameAsync(reward.precache_unit, function(...) end)
    end

    Rewards:ApplyAnimations(unit, reward)
    if unit.runTimer then
        Timers:RemoveTimer(unit.runTimer)
        unit.runTimer = nil
    end
    Rewards:MovementAnimations(hero)

    -- Update portrait
    hero:SetModel("models/custom_wisp.vmdl")
    hero:SetOriginalModel("models/custom_wisp.vmdl")
end

function Rewards:ApplyCustomWispParticles(hero)
    if hero.ambient then
        ParticleManager:DestroyParticle(hero.ambient, true)
        hero.ambient = nil
    end

    hero.ambient = ParticleManager:CreateParticle("particles/custom/wisp/wisp_ambient.vpcf", PATTACH_CUSTOMORIGIN, hero)
    ParticleManager:SetParticleControlEnt(hero.ambient, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)

    -- Update portrait
    hero:SetModel("models/custom_wisp.vmdl")
    hero:SetOriginalModel("models/custom_wisp.vmdl")
end

-- Used right after starting a building placement
function Rewards:CustomAnimation(playerID, caster)
    local unit = caster.cosmetic_override or caster

    if unit.build_animation then
        unit:RemoveGesture(ACT_DOTA_RUN)
        unit:RemoveGesture(ACT_DOTA_IDLE)
        if unit.rare_animation and RollPercentage(unit.rare_chance) then
            StartAnimation(unit, {duration=2, activity=unit.rare_animation, rate=1})
        else
            StartAnimation(unit, {duration=2, activity=unit.build_animation, rate=1})
        end
        unit.wait_for_animation = true
        return
    end

    local animationList = caster.BuildAnimations or caster.RiderBuildAnimations
    if animationList then
        local random_anim = tonumber(animationList[RandomInt(1, #animationList)])
        if caster.BuildAnimations then
            caster:StartGesture(random_anim)
        else
            caster.rider:StartGesture(random_anim)
        end
    end
end

-- Repeated timer to fake childs Run/Idle animations based on movement of the main hero
function Rewards:MovementAnimations(hero)
    if not IsValidEntity(hero) then return end
    local unit = hero.cosmetic_override or hero.rider
    if not unit.runTimer then
        unit.runTimer = Timers:CreateTimer(function()
            if not IsValidEntity(unit) or not IsValidEntity(hero) or not hero:IsAlive() then return end

            if unit.wait_for_animation then
                unit.wait_for_animation = false
                return 1
            end
            if hero:IsIdle() then
                unit:RemoveGesture(ACT_DOTA_RUN)
                unit:StartGesture(ACT_DOTA_IDLE)
            else
                unit:RemoveGesture(ACT_DOTA_IDLE)
                unit:StartGesture(ACT_DOTA_RUN)
            end
            return 0.1
        end)
    end
end

function Rewards:ConvertID64( steamID32 )
    return '765'..(steamID32 + 61197960265728)
end

if not Rewards.subscribed then Rewards:Init() end