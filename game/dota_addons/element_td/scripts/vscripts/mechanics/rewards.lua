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
                local data = {}
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
    if reward and reward.tier and reward.tier >= 10 then
        return reward
    end

    return false
end

function Rewards:HandleHeroReplacement(hero)
    local playerID = hero:GetPlayerID()
    local reward = Rewards:PlayerHasCosmeticModel(playerID)
    if not reward then
        return
    end

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
        return
    end

    -- Map Entity
    if reward.map_entity then
        local unit = Entities:FindByName(nil, reward.map_entity)
        if unit then
        
            Rewards:SetCosmeticOverride(newHero, unit, reward)

            UTIL_Remove(hero)
            return
        end
    end

    -- Fake Unit (used for hero units with AttachWearables that aren't on the map)
    if reward.unit then
        PrecacheUnitByNameAsync(reward.unit, function()
            local unit = CreateUnitByName(reward.unit, hero:GetAbsOrigin(), false, nil, nil, hero:GetTeamNumber())
            Rewards:SetCosmeticOverride(newHero, unit, reward)
            UTIL_Remove(hero)
        end, playerID)
        return
    end

    -- Particle
    Rewards:ApplyCustomWispParticles(newHero)
    UTIL_Remove(hero)
end

-- Stores animation data on the unit
function Rewards:ApplyAnimations(unit, data)
    if data.build_animation then
        unit.build_animation = tonumber(data.build_animation)
    end
    if data.rare_animation then
        unit.rare_animation = tonumber(data.rare_animation)
    end
    if data.animation_translate then
        AddAnimationTranslate(unit, data.animation_translate)
    end
end

function Rewards:SetCosmeticOverride(hero, unit, reward)
    hero.cosmetic_override = unit
    unit:SetAbsOrigin(hero:GetAbsOrigin())
    unit:SetForwardVector(hero:GetForwardVector())
    unit:AddNewModifier(nil, nil, "modifier_out_of_world", {})
    unit:SetParent(hero, "attach_hitloc")

    Rewards:ApplyAnimations(unit, reward)

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
        if unit.rare_animation and RollPercentage(75) then
            unit:StartGesture(unit.rare_animation)
        else
            unit:StartGesture(unit.build_animation)
        end
    end
end

local move_orders = {[DOTA_UNIT_ORDER_MOVE_TO_POSITION]=true,[DOTA_UNIT_ORDER_MOVE_TO_TARGET]=true,[DOTA_UNIT_ORDER_ATTACK_MOVE]=true,[DOTA_UNIT_ORDER_CAST_POSITION]=true,[DOTA_UNIT_ORDER_PATROL]=true,[DOTA_UNIT_ORDER_ATTACK_TARGET]=true}
local stop_orders = {[DOTA_UNIT_ORDER_HOLD_POSITION]=true,[DOTA_UNIT_ORDER_STOP]=true}
function Rewards:HandleAnimationOrder(hero, order_type)
    local unit = hero.cosmetic_override
    if move_orders[order_type] then
        if not unit.runTimer then
            unit:RemoveGesture(ACT_DOTA_IDLE)
            unit.runTimer = Timers:CreateTimer(function()
                if unit and IsValidEntity(unit) and not hero:IsIdle() then
                    unit:StartGesture(ACT_DOTA_RUN)
                    return 0.1
                else
                    unit:RemoveGesture(ACT_DOTA_RUN)
                    unit.runTimer = nil
                end
                unit:StartGesture(ACT_DOTA_IDLE)
            end)
        end
    elseif stop_orders[order_type] then
        if unit.runTimer then
            Timers:RemoveTimer(unit.runTimer)
            unit.runTimer = nil
        end
        unit:RemoveGesture(ACT_DOTA_RUN)
    end
    unit:StartGesture(ACT_DOTA_IDLE)
end

function Rewards:ConvertID64( steamID32 )
    return '765'..(steamID32 + 61197960265728)
end
