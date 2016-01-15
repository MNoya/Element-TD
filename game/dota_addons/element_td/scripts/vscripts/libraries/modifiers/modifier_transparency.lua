modifier_transparency = class({})

function modifier_transparency:DeclareFunctions()
    return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL }
end

function modifier_transparency:GetModifierInvisibilityLevel(params)
    return 100
end

function modifier_transparency:IsHidden()
    return true
end