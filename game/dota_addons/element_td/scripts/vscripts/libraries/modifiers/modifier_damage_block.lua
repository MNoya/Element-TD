--[[ 
    given to creeps and elements to block all normal damage so we can do
    custom damage calculations.
    Maybe in the future, damage filters would be a better solution?
]]--


modifier_damage_block = class({})

function modifier_damage_block:DeclareFunctions(params)
    return {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
    }
end

function modifier_damage_block:GetModifierPhysical_ConstantBlock()
    return 999999
end

function modifier_damage_block:GetAttributes(params)
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_damage_block:IsHidden()
    return true
end 