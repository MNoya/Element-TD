-- Flame Tower class (Nature + Fire)
-- This tower's attack puts a buff on the target. The buff lasts a few seconds. 
-- The buff does damage each second to the creep but also in an area of effect around the creep. Buff stacks indefinitely. 
FlameTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "FlameTower"
    },
nil)    

function FlameTower:DealBurnDamage(keys)
    local target = keys.target    
    local damage = ApplyAbilityDamageFromModifiers(self.burnDamage[self.level], self.tower)    
    DamageEntitiesInArea(target:GetOrigin(), self.burnAOE, self.tower, damage)    
    --print("Sunburn damage tick: " .. GameRules:GetGameTime())    
end

function FlameTower:OnCreated()
    self.level = GetUnitKeyValue(self.towerClass, "Level")    
    AddAbility(self.tower, "flame_tower_sunburn", self.level)    
    self.burnDamage = GetAbilitySpecialValue("flame_tower_sunburn", "damage")    
    self.burnAOE = GetAbilitySpecialValue("flame_tower_sunburn", "aoe")    
    self.sunburnDuration = GetAbilitySpecialValue("flame_tower_sunburn", "duration")

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})
end

function FlameTower:OnAttackLanded(keys) 
    local target = keys.target    
    local damage = ApplyAbilityDamageFromModifiers(self.burnDamage[self.level], self.tower)
    DamageEntitiesInArea(target:GetAbsOrigin(), self.burnAOE, self.tower, damage)

    attack_damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)

    keys.caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
    
    if not target.SunburnData then
        target.SunburnData = {
            Stacks = {},
            StackCount = 0,
            AOE = self.burnAOE,
        }    
    end
    
    local stackID = DoUniqueString("SunburnStack")    

    target.SunburnData.Stacks[stackID] = {
        startTime = GameRules:GetGameTime(),
        duration = self.sunburnDuration,
        damage = damage,
        source = self.tower
    }    
    target.SunburnData.StackCount = target.SunburnData.StackCount + 1    

    Timers:CreateTimer(self.sunburnDuration, function()
        if IsValidEntity(target) and target.SunburnData then
            target.SunburnData.Stacks[stackID] = nil    
            target.SunburnData.StackCount = target.SunburnData.StackCount - 1    
        end
    end)    
end

function CreateSunburnRemnant(entity, team)
    local position = entity:GetAbsOrigin() + Vector(0, 0, 64)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameGuard_column.vpcf", PATTACH_CUSTOMORIGIN, nil)    
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, position)
    ParticleManager:SetParticleControl(particle, 3, Vector(1, 0, 0))  

    local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameGuard_fire_outer.vpcf", PATTACH_CUSTOMORIGIN, nil)    
    ParticleManager:SetParticleControl(particle2, 0, position)    
    ParticleManager:SetParticleControl(particle2, 1, position)
    ParticleManager:SetParticleControl(particle2, 2, Vector(10, 10, 10))    

    local stacks = 0    
    local remnantDuration = 0    

    for k, v in pairs(entity.SunburnData.Stacks) do
        local diff = v.duration - (GameRules:GetGameTime() - v.startTime)
        if diff > 1 and IsValidEntity(v.source) then
            local timeRemaining = math.floor(diff + 0.5)    
            if timeRemaining > remnantDuration then
                remnantDuration = timeRemaining    
            end
            local ticks = timeRemaining    

            Timers:CreateTimer(1, function()
                DamageEntitiesInArea(position, entity.SunburnData.AOE, v.source, v.damage)    
                ticks = ticks - 1    
                if ticks == 0 then
                    return nil    
                end
                return 1
            end)    

            stacks = stacks + 1    
        end
    end

    if stacks == 0 then
        ParticleManager:DestroyParticle(particle, true)    
        ParticleManager:DestroyParticle(particle2, true)     
        return    
    end

    Timers:CreateTimer(remnantDuration, function()
        ParticleManager:DestroyParticle(particle, false)    
        ParticleManager:DestroyParticle(particle2, false)
    end)    
end

RegisterTowerClass(FlameTower, FlameTower.className)    