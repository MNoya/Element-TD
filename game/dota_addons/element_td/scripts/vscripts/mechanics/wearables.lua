function AdjustCosmetics( event )
    local unit = event.caster
    local ability = event.ability
    local unitName = unit:GetUnitName()

    Timers:CreateTimer(1, function()
        if unitName == "A_Dizzle" then
            Attachments:AttachProp(unit, "attach_attack1", "models/timebreaker.vmdl")
        elseif unitName == "Noya" then
            AddAnimationTranslate(unit, "abysm")
            unit:StartGesture(ACT_DOTA_IDLE)
        elseif unitName == "Quintinity" then
            AddAnimationTranslate(unit, "dualwield")
        elseif unitName == "villain" then         
            unit:AddNewModifier(unit, nil, "modifier_transparency", {})
        end
    end)
end