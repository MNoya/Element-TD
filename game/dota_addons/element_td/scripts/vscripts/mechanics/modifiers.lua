-- OnCreated Datadriven modifier call to merge multiple modifiers together in a single visual stackable modifier
function StackModifier( event )
    local target = event.target
    local ability = event.ability
    local modifierName = event.ModifierName
    local modifierStack = event.ModifierStack

    local modifiers = target:FindAllModifiersByName(modifierName)
    local modifierCount = #modifiers
    if modifierCount == 0 then
        target:RemoveModifierByName(modifierStack)
    else
        local modifier = target:FindModifierByName(modifierStack)
        if not modifier then
            ability:ApplyDataDrivenModifier(target, target, modifierStack, {})
            modifier = target:FindModifierByName(modifierStack)
            if modifier then
                modifier:SetStackCount(modifierCount)
            end        
        else
            modifier:SetStackCount(modifierCount)
        end
    end
end