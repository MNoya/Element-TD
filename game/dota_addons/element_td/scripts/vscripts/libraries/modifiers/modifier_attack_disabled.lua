modifier_attack_disabled = class({})

function modifier_attack_disabled:CheckState() 
  local state = {
      [MODIFIER_STATE_DISARMED] = true,
  }

  return state
end

function modifier_attack_disabled:IsHidden()
    return true
end