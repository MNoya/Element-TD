modifier_no_health_bar = class({})

function modifier_no_health_bar:CheckState() 
  local state = {
      [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }

  return state
end

function modifier_no_health_bar:IsHidden()
    return true
end

modifier_show_health_bar = class({})

function modifier_show_health_bar:CheckState() 
  local state = {
      [MODIFIER_STATE_NO_HEALTH_BAR] = false,
  }

  return state
end

function modifier_show_health_bar:GetPriority()
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_show_health_bar:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_show_health_bar:IsHidden()
    return true
end