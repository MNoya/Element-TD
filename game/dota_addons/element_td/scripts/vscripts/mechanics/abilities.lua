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

