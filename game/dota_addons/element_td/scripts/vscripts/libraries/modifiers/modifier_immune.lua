modifier_attack_immune = class({})

function modifier_attack_immune:CheckState() 
  local state = {
      [MODIFIER_STATE_ATTACK_IMMUNE] = true,
      [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }

  return state
end

function modifier_attack_immune:IsHidden()
    return true
end