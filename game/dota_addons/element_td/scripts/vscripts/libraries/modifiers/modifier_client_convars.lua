modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        self.original_deatheffect = Convars:GetInt("dota_camera_deatheffect")
        Convars:SetInt("dota_camera_deatheffect", 0)

        ListenToGameEvent('game_rules_state_change', function()
            local state = GameRules:State_Get()
            if state == 8 then --DOTA_GAMERULES_STATE_POST_GAME
                Convars:SetInt("dota_camera_deatheffect", self.original_deatheffect)
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