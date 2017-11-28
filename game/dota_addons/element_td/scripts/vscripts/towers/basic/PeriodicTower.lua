-- Periodic (Light + Darkness + Water + Fire + Nature + Earth)
-- Fires 6 different projectiles per attack, one of each different element.
-- Fires at up to 6 different targets.
-- If there's less than 6 different targets in range, multiple projectiles can hit the same target.

PeriodicTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "PeriodicTower"
    },
nil)

ELEMENTS_PERIODIC = {
    {particles = "particles/units/heroes/hero_oracle/oracle_base_attack.vpcf", element = "light"},
    {particles = "particles/custom/towers/dark/attack.vpcf", element = "dark"},
    {particles = "particles/custom/towers/water/attack.vpcf", element = "water"},
    {particles = "particles/units/heroes/hero_lina/lina_base_attack.vpcf", element = "fire"},
    {particles = "particles/units/heroes/hero_rubick/rubick_base_attack.vpcf", element = "nature"},
    {particles = "particles/neutral_fx/mud_golem_hurl_boulder.vpcf", element = "earth"},
}

function PeriodicTower:OnAttack(keys)
    local target = keys.target
    local caster = keys.caster
    local creeps = GetCreepsInArea(self.tower:GetAbsOrigin(), self.tower:GetAttackRange())
    local count = 1
    local repeated = false
    local element_select = self.element_select
    -- target projectile first
    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self:GetElementAbility(element_select),
        EffectName = ELEMENTS_PERIODIC[element_select].particles,
        iMoveSpeed = self.tower:GetProjectileSpeed(),
        vSourceLoc = caster:GetAbsOrigin(),
        bReplaceExisting = false,
        flExpireTime = GameRules:GetGameTime() + 10,
    })
    element_select = element_select + 1
    if element_select > 6 then
        element_select = 1
    end
    count = count + 1
    -- remaining projectiles
    if #creeps > 0 then
        repeat
            for _, creep in pairs(creeps) do
                -- Only include the initial target after doing a pass of the selected creeps
                if creep:IsAlive() and (creep:entindex() ~= target:entindex() or repeated) then
                    ProjectileManager:CreateTrackingProjectile({
                        Target = creep,
                        Source = caster,
                        Ability = self:GetElementAbility(element_select),
                        EffectName = ELEMENTS_PERIODIC[element_select].particles,
                        iMoveSpeed = self.tower:GetProjectileSpeed(),
                        vSourceLoc = caster:GetAbsOrigin(),
                        bReplaceExisting = false,
                        flExpireTime = GameRules:GetGameTime() + 10,
                    })
                    element_select = element_select + 1
                    if element_select > 6 then
                        element_select = 1
                    end
                    count = count + 1
                end
                if count > 6 then
                    break
                end
            end
            repeated = true
        -- Repeat until all 6 elements have be launched
        until count >= 6
    end
    -- rotate target element for each attack
    self.element_select = self.element_select + 1
    if self.element_select > 6 then
        self.element_select = 1
    end
end

function PeriodicTower:OnProjectileHit(keys)
    self:OnAttackLanded({target = keys.target, ability = keys.ability})
end

function PeriodicTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAbilityDamageFromModifiers(self.damage, self.tower)
    local ability_name = keys.ability:GetAbilityName()
    if ability_name == "periodic_tower_synergy_light" then
        DamageEntity(target, self.tower, damage, false, "light")
    elseif ability_name == "periodic_tower_synergy_dark" then
        DamageEntity(target, self.tower, damage, false, "dark")
    elseif ability_name == "periodic_tower_synergy_water" then
        DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage, "water")
    elseif ability_name == "periodic_tower_synergy_fire" then
        DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2, "fire")
        DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2, "fire")
    elseif ability_name == "periodic_tower_synergy_earth" then
        DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2, "earth")
        DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2, "earth")
    elseif ability_name == "periodic_tower_synergy_nature" then
        DamageEntity(target, self.tower, damage, false, "nature")
    end
end

function PeriodicTower:GetElementAbility(id)
    if id == 1 then
        return self.ability_light
    elseif id == 2 then
        return self.ability_dark
    elseif id == 3 then
        return self.ability_water
    elseif id == 4 then
        return self.ability_fire
    elseif id == 5 then
        return self.ability_nature
    elseif id == 6 then
        return self.ability_earth
    else
        return self.ability
    end
end

function PeriodicTower:OnCreated()
    self.ability = AddAbility(self.tower, "periodic_tower_synergy")
    self.ability_light = AddAbility(self.tower, "periodic_tower_synergy_light")
    self.ability_dark = AddAbility(self.tower, "periodic_tower_synergy_dark")
    self.ability_water = AddAbility(self.tower, "periodic_tower_synergy_water")
    self.ability_fire = AddAbility(self.tower, "periodic_tower_synergy_fire")
    self.ability_nature = AddAbility(self.tower, "periodic_tower_synergy_nature")
    self.ability_earth = AddAbility(self.tower, "periodic_tower_synergy_earth")
    self.element_select = 1
    self.damage = 40000
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
end

RegisterTowerClass(PeriodicTower, PeriodicTower.className)