modifier_health_bar_markers = class({})

function modifier_health_bar_markers:OnCreated( params )
    if IsClient() then
        self.original_health_marker = Convars:GetInt("dota_health_per_vertical_marker")
        local netTable = CustomNetTables:GetTableValue("elementals", tostring(self:GetParent():GetEntityIndex()))
        local health_marker = netTable and netTable.health_marker or 250
        Convars:SetInt("dota_health_per_vertical_marker", tonumber(health_marker))
    end
end

function modifier_health_bar_markers:OnDestroy( params )
    if IsClient() then
        Convars:SetInt("dota_health_per_vertical_marker", self.original_health_marker)
    end
end

function modifier_health_bar_markers:IsHidden()
    return true
end