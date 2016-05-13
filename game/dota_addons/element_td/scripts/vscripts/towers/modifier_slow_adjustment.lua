if not modifier_slow_adjustment then
    modifier_slow_adjustment = class({})
end

function modifier_slow_adjustment:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, 
             MODIFIER_PROPERTY_MOVESPEED_MAX,
             MODIFIER_PROPERTY_MOVESPEED_LIMIT, }
end

function modifier_slow_adjustment:GetModifierMoveSpeed_Max( params ) return 750 end
function modifier_slow_adjustment:GetModifierMoveSpeed_Limit( params ) return 750 end

function modifier_slow_adjustment:IsHidden()
    return true
end

SLOWING_MODIFIERS = {"modifier_tornado_slow", "modifier_explode_slow", "modifier_gaias_wrath_slow", "modifier_sludge_slow"}
SLOWING_VALUES = {[1]=0.1,[2]=0.3}

function modifier_slow_adjustment:OnCreated(params)
    self.base_ms = 300
    self.haste_ms = string.match(GetMapName(), "element_td_coop") and 500 or 750
end

function modifier_slow_adjustment:GetModifierMoveSpeed_Absolute()
    local unit = self:GetParent()
    local movespeed = self.base_ms

    if unit:HasModifier("creep_haste_modifier") then
        return self.haste_ms
    end
    
    local slows = {}
    for _,name in pairs(SLOWING_MODIFIERS) do
        -- Each slow modifier has a 1/2 version to detect it in clientside. It's ugly but works
        local hasModifier1 = unit:HasModifier(name.."1")
        local hasModifier2 = unit:HasModifier(name.."2")

        if hasModifier2 then
            table.insert(slows, SLOWING_VALUES[2])
        elseif hasModifier1 then
            table.insert(slows, SLOWING_VALUES[1])
        end
    end

    if #slows > 0 then
        for _,value in pairs(slows) do
            movespeed = movespeed * (1-value)
        end
        movespeed = math.floor(movespeed + 0.5)
    end

    return movespeed
end
