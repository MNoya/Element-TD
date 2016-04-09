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
        local maxHealth = GameSettings:GetMapSetting("Lives")

        if playerData.health > maxHealth then
            local healthBonus = (playerData.health - maxHealth)
            local heal = playerData.health - hero:GetHealth()
            hero:Heal(heal, nil)
            return healthBonus
        else
            hero:SetBaseMaxHealth(maxHealth)
            hero:SetMaxHealth(maxHealth)
            hero:SetHealth(playerData.health)
            return 0
        end
    end
end

function modifier_bonus_life:IsHidden()
    return true
end