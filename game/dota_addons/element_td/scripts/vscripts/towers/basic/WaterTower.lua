-- Water tower class

WaterTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "WaterTower"
    },
nil)

function WaterTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetAbsOrigin(), self.halfAOE, self.tower, damage / 2)
    DamageEntitiesInArea(target:GetAbsOrigin(), self.fullAOE, self.tower, damage / 2)

    self:StartBounce(target, self.maxBounces)
end

function WaterTower:StartBounce(original_target, remaining_bounces)

    -- Find a valid target to bounce to
    local next_target = FindBounceTarget(original_target, self.bounceRange)

    if next_target then
        -- Create a dummy and teach it the ability
        local dummy = CreateUnitByName("tower_dummy", original_target:GetAbsOrigin(), false, nil, nil, 0)
        local dummy_ability = AddAbility(dummy, "water_tower_water_bullet")
        dummy_ability.maxBounces = self.ability:GetSpecialValueFor("bounces")
        dummy_ability.bounceRange = self.ability:GetSpecialValueFor("bounce_range")
        dummy_ability.bounceSpeed = self.tower:GetProjectileSpeed() / 3
        dummy_ability.projectileName = "particles/units/heroes/hero_morphling/morphling_base_attack.vpcf"
        dummy_ability.bounceTable = {}
        dummy_ability.bounceCount = 1
        dummy_ability.original_ability = self.ability
        dummy_ability.tower = self.tower
        dummy_ability.damage = self.tower:GetAverageTrueAttackDamage()
        dummy_ability.halfAOE = self.halfAOE
        dummy_ability.fullAOE = self.fullAOE
        dummy_ability.dummy = dummy

        local sourceLoc = original_target:GetAbsOrigin()
        sourceLoc.z = sourceLoc.z + 32

        ProjectileManager:CreateTrackingProjectile({
            Target = next_target,
            Source = original_target,
            Ability = dummy_ability,
            EffectName = self.projectileName,
            iMoveSpeed = self.bounceSpeed,
            vSourceLoc = sourceLoc,
            bReplaceExisting = false,
            flExpireTime = GameRules:GetGameTime() + 10,
        })
    end
end

function FindBounceTarget(original_target, radius)
    local validTargets = {}
    local creeps = GetCreepsInArea(original_target:GetAbsOrigin(), radius)
    
    for _, creep in pairs(creeps) do
        if creep:IsAlive() and creep:entindex() ~= original_target:entindex() then
            table.insert(validTargets, creep)
        end
    end

    if #validTargets > 0 then
        return validTargets[math.random(#validTargets)]
    end
end

-- Datadriven bounce hit, check for next bounce
function OnBounceHit(event)
    local target = event.target
    local ability = event.ability
    local damage = ability.damage

    -- Handles the case where the bounce wasn't properly initialized
    if not damage or not IsValidEntity(ability.tower) then 
        UTIL_Remove(ability.dummy)
        return
    end

    DamageEntitiesInArea(target:GetAbsOrigin(), ability.halfAOE, ability.tower, damage / 2)
    DamageEntitiesInArea(target:GetAbsOrigin(), ability.fullAOE, ability.tower, damage / 2)

    if ability.bounceCount < ability.maxBounces then

        local next_target = FindBounceTarget(target, ability.bounceRange)

        if next_target then
            ability.bounceCount = ability.bounceCount + 1

            local sourceLoc = target:GetAbsOrigin()
            sourceLoc.z = sourceLoc.z + 32

            ProjectileManager:CreateTrackingProjectile({
                Target = next_target,
                Source = target,
                Ability = ability,
                EffectName = ability.projectileName,
                iMoveSpeed = ability.bounceSpeed,
                vSourceLoc = sourceLoc,
                bReplaceExisting = false,
                flExpireTime = GameRules:GetGameTime() + 10,
            })
        else
            UTIL_Remove(ability.dummy)
        end
    else
        UTIL_Remove(ability.dummy)
    end
end

function WaterTower:OnCreated()
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.dummies = {}
    self.ability = AddAbility(self.tower, "water_tower_water_bullet")
    self.maxBounces = self.ability:GetSpecialValueFor("bounces")
    self.bounceRange = self.ability:GetSpecialValueFor("bounce_range")
    self.bounceSpeed = self.tower:GetProjectileSpeed() / 3
    self.projectileName = "particles/units/heroes/hero_morphling/morphling_base_attack.vpcf" 
end

RegisterTowerClass(WaterTower, WaterTower.className)