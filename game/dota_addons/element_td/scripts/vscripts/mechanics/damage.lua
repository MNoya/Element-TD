function DamageEntity(entity, attacker, damage, pure)
    if not entity or not entity:IsAlive() then return end
    
    if entity:HasModifier("modifier_invulnerable") then return end

    local original = damage
    if damage <= 0 then return end --pls no negative damage

    if not pure then
        -- Modify damage based on elements
        damage = ApplyElementalDamageModifier(damage, GetDamageType(attacker), GetArmorType(entity))
        local element = damage

        -- Increment damage based on debuffs
        damage = ApplyDamageAmplification(damage, entity, attacker)
        local amplified = damage
    end

    damage = math.ceil(damage) --round up to the nearest integer
            
    if GameRules.DebugDamage then
        local sourceName = attacker.class
        local targetName = entity.class
        print("[DAMAGE] " .. sourceName .. " deals " .. damage .. " to " .. targetName .. " [" .. entity:entindex() .. "]")
        if (original ~= damage) then
            print("[DAMAGE]  Original: "..original.." | Element: "..element.." | Amplified: "..amplified)
        end
    end

    
    local playerID = attacker:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    if playerData.godMode then
        damage = entity:GetMaxHealth()*2
    elseif playerData.zenMode then
        damage = 0
    end

    -- Temporal creeps backtrack to where they were some seconds ago, regaining HP
    if entity:HasModifier("modifier_time_lapse") then
        local timeLapse = entity:FindAbilityByName("creep_ability_time_lapse")
        if timeLapse and timeLapse:IsCooldownReady() and (entity:GetHealth()-damage)/entity:GetMaxHealth() <= timeLapse:GetSpecialValueFor("health_threshold")*0.01 and entity.scriptObject.Backtrack then
            entity.scriptObject:Backtrack()
            return 0
        end
    end

    local overkillDamage = 0
    if entity:GetHealth() - damage <= 0 then
        overkillDamage = damage - entity:GetHealth()

        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        local goldBounty = entity:GetGoldBounty()

        -- Gold Tower
        if attacker.scriptClass == "GoldTower" and entity:IsAlive() and entity:GetGoldBounty() > 0 then
            goldBounty = attacker.scriptObject:ModifyGold(goldBounty)
            local extra_gold = goldBounty - entity:GetGoldBounty()
            
            playerData.goldTowerEarned = playerData.goldTowerEarned + extra_gold

            local origin = entity:GetAbsOrigin()
            origin.z = origin.z+128
            local particle = ParticleManager:CreateParticle("particles/custom/towers/gold/midas.vpcf", PATTACH_ABSORIGIN, entity)
            ParticleManager:SetParticleControl(particle, 0, origin)
            ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_attack1", attacker:GetAbsOrigin(), true)
            if extra_gold > 0 then
                PopupGoldGain(attacker, extra_gold)
            end
        end

        -- Flame Tower
        if entity.SunburnData and entity.SunburnData.StackCount > 0 then
            CreateSunburnRemnant(entity)
        end
        
        if COOP_MAP then
            -- Split gold bounty with all players
            goldBounty = goldBounty / PlayerResource:GetPlayerCountWithoutLeavers()
            ForAllConnectedPlayerIDs(function(playerID)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:ModifyGold(goldBounty)
                end
            end)
        else
            hero:ModifyGold(goldBounty)
        end

        if not entity.isUndead then
            IncrementKillCount(attacker)
            if entity:GetUnitName() ~= "icefrog" then
                EmitSoundOnLocationForAllies(entity:GetOrigin(), "Gold.Coins", hero)
            end
        end

        entity:Kill(nil, attacker)
    else
        entity:SetHealth(entity:GetHealth() - damage)
    end

    return damage, math.max(0, overkillDamage)
end

function DamageEntitiesInArea(origin, radius, attacker, damage)
    local entities = GetCreepsInArea(origin, radius)
    for _,e in pairs(entities) do
        DamageEntity(e, attacker, damage)
    end
end
--------------------------------------------------------------
--------------------------------------------------------------

function ApplyDamageAmplification(damage, creep, tower)
    local newDamage = damage
    local amp = 0

    -- Erosion
    local erosionModifier = creep:FindModifierByName("modifier_acid_attack_damage_amp")
    if erosionModifier then
        amp = amp + erosionModifier.damageAmp
    end

    -- Enchantment
    local ffModifier = creep:FindModifierByName("modifier_faerie_fire")
    if ffModifier then
        local creeps = GetCreepsInArea(creep:GetAbsOrigin(), ffModifier.findRadius)
        if #creeps <= 3 then
            amp = amp + ffModifier.maxAmp
        else
            amp = amp + ffModifier.baseAmp
        end
    end

    -- Vengeance
    local vModifier = tower:FindModifierByName("modifier_vengeance_debuff")
    if vModifier then
        amp = amp + vModifier.damageReduction
    end

    newDamage = newDamage * (1+ amp*0.01)

    if GameRules.DebugDamage and amp ~= 0 then
        print("[DAMAGE] Amplified damage done to "..creep:GetUnitName().." damage of "..damage.." to "..newDamage.." due to an amplification of "..amp)
    end

    return round(newDamage)
end

-- Handles blacksmith damage increasing for abilities
function ApplyAbilityDamageFromModifiers(damage, attacker)
    local newDamage = damage
    local fire_up = attacker:FindModifierByName("modifier_fire_up")
    if fire_up then
        newDamage = newDamage + (damage * fire_up.damage_bonus * 0.01)
        if GameRules.DebugDamage then
            print("[DAMAGE] Increased "..attacker.class.." damage of "..damage.." to "..newDamage.." due to Fire Up modifier.")
        end
    end
    return round(newDamage)
end

-- applies the element damage modifier
function ApplyElementalDamageModifier(damage, inflictingElement, targetElement)
    if DamageModifiers[inflictingElement][targetElement] then
        return damage * DamageModifiers[inflictingElement][targetElement]
    else
        return damage
    end
end

-- returns a unit's elemental armor type
function GetArmorType(entity)
    for element, data in pairs(DamageModifiers) do
        if entity:HasAbility(element .. "_armor") then
            return element
        end
    end
    Log:warn("Could not find armor type for entity " .. entity:entindex())
    return "composite"
end

function GetDamageType(tower)
    local element = GetUnitKeyValue(tower.class, "DamageType")
    if element then
        return element
    else
        Log:warn("Unable to find damage type for " .. tower.class)
        return "composite"
    end
end