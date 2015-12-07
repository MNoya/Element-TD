NPC_UNITS_CUSTOM = LoadKeyValues("scripts/npc/npc_units_custom.txt")
NPC_ABILITIES_CUSTOM = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
NPC_ITEMS_CUSTOM = LoadKeyValues("scripts/npc/npc_items_custom.txt")
ADDON_ENGLISH = LoadKeyValues("resource/addon_english.txt")

-- helper function
function GetUnitKeyValue(unitName, key)
    if NPC_UNITS_CUSTOM[unitName] then
        if not NPC_UNITS_CUSTOM[unitName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. unitName)
        end
        return NPC_UNITS_CUSTOM[unitName][key]
    else
        --Log:warn("Unknown unit type: " .. tostring(unitName) .. " [Key: " .. key .. "]")
        return nil
    end
end

-- helper function
function GetAbilityKeyValue(abilityName, key)
    if NPC_ABILITIES_CUSTOM[abilityName] then
        if not NPC_ABILITIES_CUSTOM[abilityName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. abilityName)
        end
        return NPC_ABILITIES_CUSTOM[abilityName][key]
    else
        --Log:warn("Unknown ability: " .. tostring(abilityName) .. " [Key: " .. key .. "]")
        return nil
    end
end

function GetEnglishTranslation(key)
    return ADDON_ENGLISH.Tokens[key]
end

-- helper function
function GetItemKeyValue(itemName, key)
    if NPC_ITEMS_CUSTOM[itemName] then
        if not NPC_ITEMS_CUSTOM[itemName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. itemName)
        end
        return NPC_ITEMS_CUSTOM[itemName][key]
    else
        Log:warn("Unknown item: " .. tostring(itemName) .. " [Key: " .. key .. "]")
        return nil
    end
end

--helper function
function GetAbilitySpecialValue(abilityName, specialValue)
    if NPC_ABILITIES_CUSTOM[abilityName] then
        local kv = NPC_ABILITIES_CUSTOM[abilityName]
        if kv.AbilitySpecial then
            for k, v in pairs(kv.AbilitySpecial) do
                if v[specialValue] then
                    local result = nil
                    if string.find(v[specialValue], " ") then -- is this value an array?
                        result = split(v[specialValue], " ")
                        for k2, v2 in pairs(result) do
                            result[k2] = tonumber(v2)
                        end
                    else
                        result = tonumber(v[specialValue])
                    end
                    return result
                end
            end
        end
        return nil
    else
        Log:warn("Unknown ability: " .. tostring(abilityName) .. " [SpecialValue: " .. specialValue .. "]")
        return nil
    end
end