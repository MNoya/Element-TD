modifier_invisible_etd = class({})

function modifier_invisible_etd:CheckState() 
  local state = {
      [MODIFIER_STATE_INVISIBLE] = true,
  }

  return state
end

function modifier_invisible_etd:IsHidden()
    return true
end