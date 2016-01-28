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