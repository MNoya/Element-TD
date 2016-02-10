function ApplySlowLevel(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local level = ability and ability:GetLevel() or 1
    local modifier_name = event.Name..level

    ability:ApplyDataDrivenModifier(caster, target, modifier_name, {})
end

function RemoveSlowLevel(event)
    local target = event.target
    local ability = event.ability
    local level = ability and ability:GetLevel() or 1
    local modifier_name = event.Name..level

    target:RemoveModifierByName(modifier_name)
end