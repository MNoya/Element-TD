if not modifier_kill_count then
    modifier_kill_count = class({})
end

function modifier_kill_count:GetTexture()
    return "towers/kill_count"
end