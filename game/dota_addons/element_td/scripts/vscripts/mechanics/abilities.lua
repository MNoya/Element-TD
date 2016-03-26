function CDOTABaseAbility:ToggleOn()
    if not self:GetToggleState() then
        self:ToggleAbility()
    end
end

function CDOTABaseAbility:ToggleOff()
    if self:GetToggleState() then
        self:ToggleAbility()
    end
end

function DebugMainSelectedAbilities( playerID )
    local ent = PlayerResource:GetMainSelectedEntity(playerID)
    local unit = EntIndexToHScript(ent)
    if unit then
        PrintAbilities(unit)
    end
end

function PrintAbilities( unit )
    print("List of Abilities in "..unit:GetUnitName())
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            local output = i.." - "..ability:GetAbilityName()
            if ability:IsHidden() then output = output.." (Hidden)" end
            print(output)
        end
    end
end