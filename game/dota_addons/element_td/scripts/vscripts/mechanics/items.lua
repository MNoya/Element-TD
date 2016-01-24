-- Returns the item handle on the units inventory
function GetItemByName( unit, item_name )
    for i=0,15 do
        local item = unit:GetItemInSlot(i)
        if item and item:GetAbilityName() == item_name then
            return item
        end
    end
    return nil
end

-- Applies a modifier from item_apply_modifiers
function ApplyModifier( unit, modifierName )
    GameRules.Applier:ApplyDataDrivenModifier(unit, unit, modifierName, {})
end