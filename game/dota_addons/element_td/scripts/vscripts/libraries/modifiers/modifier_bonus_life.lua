modifier_bonus_life = class({})

function modifier_bonus_life:DeclareFunctions()
    local funcs = { MODIFIER_PROPERTY_HEALTH_BONUS, }
    return funcs
end

function modifier_bonus_life:GetModifierHealthBonus( params )
    if IsServer() then
        local hero = self:GetParent()
        local playerID = hero:GetPlayerID()
        local playerData = GetPlayerData(playerID)

        if playerData.health > 50 then
            local healthBonus = (playerData.health - 50)
            local heal = playerData.health - hero:GetHealth()
            hero:Heal(heal, nil)
            return healthBonus
        else
            hero:SetBaseMaxHealth(50)
            hero:SetMaxHealth(50)
            hero:SetHealth(playerData.health)
            return 0
        end
    end
end

function modifier_bonus_life:IsHidden()
    return true
end