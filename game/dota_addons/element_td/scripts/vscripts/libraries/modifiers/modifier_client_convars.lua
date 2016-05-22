modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        SendToConsole("dota_camera_deatheffect 0")
        SendToConsole("dota_player_units_auto_attack_mode 2") --Always
        SendToConsole("dota_summoned_units_auto_attack_mode -1") --Same as hero
    end
end

function modifier_client_convars:IsHidden()
    return true
end

function modifier_client_convars:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end