modifier_not_on_minimap_for_enemies = class({})

function modifier_not_on_minimap_for_enemies:CheckState() 
  local state = {
      [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
  }

  return state
end

function modifier_not_on_minimap_for_enemies:IsHidden()
    return true
end