if not modifier_attack_targeting then
    modifier_attack_targeting = class({})
end

function modifier_attack_targeting:IsHidden()
    return true
end

if not IsServer() then return end

function modifier_attack_targeting:DeclareFunctions()
    return { MODIFIER_PROPERTY_DISABLE_AUTOATTACK, 
             MODIFIER_EVENT_ON_ATTACK }
end

function modifier_attack_targeting:GetDisableAutoAttack( params )
    return 1
end

function modifier_attack_targeting:OnCreated( params )
    local unit = self:GetParent()
    unit.target_type = params.target_type
    self:StartIntervalThink(0.03)
end

function modifier_attack_targeting:OnIntervalThink()
    local unit = self:GetParent()
    if unit:HasModifier("modifier_attack_disabled") then return end
    local findRadius = unit:GetAttackRange() + unit:GetHullRadius()
    local attackTarget = unit:GetAttackTarget()
    
    -- Find a new target, changing the target on every attack
    if unit:AttackReady() and not unit:IsAttacking() then
        local target = GetTowerTarget(unit, unit.target_type, findRadius)
        if target ~= attackTarget then
            unit:MoveToTargetToAttack(target)
        end
    end
end

function modifier_attack_targeting:OnAttack( params )
    if params.attacker == self:GetParent() then
        self:GetParent():Interrupt()
    end
end