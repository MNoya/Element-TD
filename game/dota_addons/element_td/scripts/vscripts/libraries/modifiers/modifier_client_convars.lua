modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        self.original_deatheffect = Convars:GetInt("dota_camera_deatheffect")
        SendToConsole("dota_camera_deatheffect 0")

        self.original_auto_attack_mode = Convars:GetInt("dota_player_units_auto_attack_mode")
        SendToConsole("dota_player_units_auto_attack_mode 2") --Always

        self.original_summoned_units_auto_attack_mode = Convars:GetInt("dota_summoned_units_auto_attack_mode")
        SendToConsole("dota_summoned_units_auto_attack_mode -1") --Same as hero

        ListenToGameEvent('game_rules_state_change', function()
            local state = GameRules:State_Get()
            if state == 8 then --DOTA_GAMERULES_STATE_POST_GAME
                SendToConsole("dota_summoned_units_auto_attack_mode ".. self.original_deatheffect)
                SendToConsole("dota_player_units_auto_attack_mode ".. self.original_auto_attack_mode)
                SendToConsole("dota_summoned_units_auto_attack_mode ".. self.original_summoned_units_auto_attack_mode)
            end
        end, nil)
    end
end

function modifier_client_convars:IsHidden()
    return true
end

function modifier_client_convars:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end