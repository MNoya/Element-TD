modifier_stunned = class({})

function modifier_stunned:CheckState() 
  local state = {
      [MODIFIER_STATE_STUNNED] = true,
  }

  return state
end

function modifier_stunned:IsHidden()
    return true
end