modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if not IsServer() then
        Convars:SetInt("r_farz", 10000)
    end
end

function modifier_client_convars:IsHidden()
    return true
end