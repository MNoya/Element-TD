if not Rewards then
    Rewards = class({})
end

function Rewards:Load()
    Rewards.players = {}

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

        if obj and obj.players then
            for _,v in pairs(obj.players) do
                local data = {}
                data.tier = v.reward
                if v.model then
                    data.model = v.model
                    data.scale = v.scale
                end
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
    if reward and not reward.model then
        return false
    end

    return reward or DEVELOPERS[steamID32]
end

function Rewards:HandleHeroReplacement(hero)
    local playerID = hero:GetPlayerID()
    local reward = Rewards:PlayerHasCosmeticModel(playerID)

    if reward and reward.model then
        local newHero = Rewards:ReplaceWithFakeHero(playerID, hero)
        newHero:SetModel(reward.model)

        if reward.scale then
            newHero:SetModelScale(reward.scale)
        end

        UTIL_Remove(hero)
        return
    end

    -- Setup developer map unit
    local steamID32 = PlayerResource:GetSteamAccountID(playerID)
    local dev = DEVELOPERS[steamID32]
    if dev then
        print("Welcome "..dev)
        local unit = Entities:FindByName(nil, dev)
        if unit then
            local newHero = Rewards:ReplaceWithFakeHero(playerID, hero)

            --Rewards:SetCosmeticOverride(newHero, unit)
            Rewards:ApplyCustomWispParticles(newHero)

            UTIL_Remove(hero)
        end
    end
end

function Rewards:SetCosmeticOverride(hero, unit)
    hero.cosmetic_override = unit
    unit:SetAbsOrigin(hero:GetAbsOrigin())
    unit:SetForwardVector(hero:GetForwardVector())
    unit:AddNewModifier(nil, nil, "modifier_out_of_world", {})
    unit:SetParent(hero, "attach_hitloc")
    unit.customAnimations = {ACT_DOTA_ATTACK, ACT_DOTA_CAST_ABILITY_4}
    unit.customTranslation = "abysm"

    hero:SetModel(unit:GetModelName())
    hero:SetOriginalModel(unit:GetModelName())
    hero:RespawnUnit()
    hero:AddNoDraw()
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
    hero:RespawnUnit()
end

function Rewards:CustomAnimation(playerID, caster)
    local unit = caster.cosmetic_override or caster
    if unit.customAnimations then
        if unit.customTranslation then
            AddAnimationTranslate(unit, unit.customTranslation)
        end
        local animation = unit.customAnimations[RandomInt(1,#unit.customAnimations)]
        unit:StartGesture(animation)
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
