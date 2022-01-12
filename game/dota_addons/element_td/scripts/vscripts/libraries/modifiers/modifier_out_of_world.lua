modifier_out_of_world = class({})

if IsServer() then
    function modifier_out_of_world:CheckState() 
        local state = {
            [MODIFIER_STATE_OUT_OF_GAME] = true,
            [MODIFIER_STATE_PASSIVES_DISABLED] = true,
            [MODIFIER_STATE_PROVIDES_VISION] = false,
            [MODIFIER_STATE_STUNNED] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
        }

        return state
    end

    function modifier_out_of_world:OnCreated( params )
        local unit = self:GetParent()
        unit.originalDayVision = unit:GetDayTimeVisionRange()
        unit.originalNightVision = unit:GetDayTimeVisionRange()
        unit:SetDayTimeVisionRange(0)
        unit:SetNightTimeVisionRange(0)
    end

    function modifier_out_of_world:OnDestroy( params )
        local unit = self:GetParent()
        if unit.originalDayVision == nil or unit.originalNightVision == nil then
            unit.originalDayVision = 575
            unit.originalNightVision = 575
        end
        unit:SetDayTimeVisionRange(unit.originalDayVision)
        unit:SetNightTimeVisionRange(unit.originalNightVision)
    end
end