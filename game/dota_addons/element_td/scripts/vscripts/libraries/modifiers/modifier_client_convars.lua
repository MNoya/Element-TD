modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        self:SetConVars()
        self:StartIntervalThink(10)
    end
end

function modifier_client_convars:SetConVars()
    SendToConsole("r_farz 10000")
end

function modifier_client_convars:OnIntervalThink()
    self:SetConVars()
end

function modifier_client_convars:IsHidden()
    return true
end

function modifier_client_convars:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end