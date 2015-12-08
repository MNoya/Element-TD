modifier_disabled = class({})

function modifier_disabled:CheckState() 
  local state = {
      [MODIFIER_STATE_INVULNERABLE] = true,
      [MODIFIER_STATE_PASSIVES_DISABLED] = true,
      [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
      [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
      [MODIFIER_STATE_STUNNED] = true,
      [MODIFIER_STATE_NO_HEALTH_BAR] = true
  }

  return state
end

function modifier_disabled:IsHidden()
    return true
end