if not Rewards then
    Rewards = class({})
end

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

function Rewards:PlayerHasCosmeticModel(playerID)
    local steamID32 = PlayerResource:GetSteamAccountID(playerID)
    local steamID64 = Rewards:ConvertID64(steamID32)

    local reward = Rewards.players[tostring(steamID64)]
    if reward and (not reward.tier or (reward.tier and reward.tier >= 10)) then
        return reward
    end

    -- Enable wisp set outside of dedis
    if not IsDedicatedServer() then
        return {tier=10}
    end

    return false
end

function Rewards:HandleHeroReplacement(hero)
    local playerID = hero:GetPlayerID()
    local reward = Rewards:PlayerHasCosmeticModel(playerID)
    if not reward then return end

    local newHero = Rewards:ReplaceWithFakeHero(playerID, hero)

    -- Models are based on a unit for precache async, and update the portrait
    if reward.model then
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
            Rewards:SetCosmeticOverride(newHero, unit, reward)

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

function Rewards:SetCosmeticOverride(hero, unit, reward)
    hero.cosmetic_override = unit
    unit:SetAbsOrigin(hero:GetAbsOrigin())
    if reward.scale then unit:SetModelScale(tonumber(reward.scale)) end
    unit:SetForwardVector(hero:GetForwardVector())
    unit:AddNewModifier(nil, nil, "modifier_out_of_world", {})
    unit:SetParent(hero, "attach_hitloc")

    Rewards:ApplyAnimations(unit, reward)
    Rewards:MovementAnimations(hero)

    -- Update portrait
    hero:SetModel("models/custom_wisp.vmdl")
    hero:SetOriginalModel("models/custom_wisp.vmdl")
end

function Rewards:ReplaceWithFakeHero(playerID, hero)
    local newHero = PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_abyssal_underlord", 0, 0)
    newHero.replaced = true
    return newHero
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
    end
end

function Rewards:MovementAnimations(hero)
    local unit = hero.cosmetic_override or hero.rider
    if not unit.runTimer then
        unit.runTimer = Timers:CreateTimer(function()
            if not IsValidEntity(unit) or not hero:IsAlive() then return end
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
