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
    self.keep_target = params.keep_target == 1
    self.change_on_leak = params.change_on_leak == 1
    self:StartIntervalThink(0.03)
end

function modifier_attack_targeting:OnIntervalThink()
    local unit = self:GetParent()
    if unit:HasModifier("modifier_disarmed") then return end
    local findRadius = unit:GetAttackRange() + unit:GetHullRadius()
    local attackTarget = unit:GetAttackTarget()

    -- Stop focusing targets after leaking
    if self.change_on_leak then
        if attackTarget and attackTarget.recently_leaked then
            unit:Interrupt()
        end
    end
    
    -- Find a new target, changing the target on every attack
    if unit:AttackReady() and not unit:IsAttacking() then
        local target = GetTowerTarget(unit, unit.target_type, findRadius)
        if target ~= attackTarget then
            unit:MoveToTargetToAttack(target)
        end
    end
end

-- Interrupt after each attack, unless the tower should focus target
function modifier_attack_targeting:OnAttack( params )
    if params.attacker == self:GetParent() then
        if not self:ShouldContinueAttacking() then
            self:GetParent():Interrupt()
        end
    end
end

function modifier_attack_targeting:ShouldContinueAttacking()
    local unit = self:GetParent()
    local attackTarget = unit:GetAttackTarget()

    -- Focus targets
    if self.keep_target then
        return true
    end

    -- No attack target or order
    if not attackTarget or not unit.orderTable then
        return false
    end

    -- Manually ordered to attack this target
    if unit.orderTable['order_type'] == DOTA_UNIT_ORDER_ATTACK_TARGET and unit.orderTable['entindex_target'] == attackTarget:GetEntityIndex() then
        return true
    end

    return false
end