function ApplySlowLevel(event)
    local caster = event.caster
    local ability = event.ability
    local level = ability and ability:GetLevel() or 1
    local modifier_name = event.Name .. level

    for _, entity in pairs(event.target_entities) do
        ability:ApplyDataDrivenModifier(caster, entity, event.Name, {}) -- base modifier (i.e. modifier_explode_slow)
        ability:ApplyDataDrivenModifier(caster, entity, modifier_name, {}) -- hacky sub-modifier (i.e. modifier_explode_slow2)
    end
end
