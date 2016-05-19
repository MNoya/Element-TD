creep_haste_modifier = class({})

function creep_haste_modifier:GetTexture()
    return "dark_seer_surge"
end

function creep_haste_modifier:GetEffectName()
    return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function creep_haste_modifier:GetEffectAttachType()
    return PATTACH_ABSORIGIN
end

function creep_haste_modifier:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end