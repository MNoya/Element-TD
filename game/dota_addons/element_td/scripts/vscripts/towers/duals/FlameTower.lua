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
end

function FlameTower:OnCreated()
    self.level = GetUnitKeyValue(self.towerClass, "Level")    
    AddAbility(self.tower, "flame_tower_sunburn", self.level)    
    self.burnDamage = GetAbilitySpecialValue("flame_tower_sunburn", "damage")    
    self.burnAOE = GetAbilitySpecialValue("flame_tower_sunburn", "aoe")    
    self.sunburnDuration = GetAbilitySpecialValue("flame_tower_sunburn", "duration")
end

function FlameTower:OnAttack(keys)
    keys.caster:EmitSound("Flame.Attack")
end

function FlameTower:OnAttackLanded(keys) 
    local target = keys.target
    local damage = ApplyAbilityDamageFromModifiers(self.burnDamage[self.level], self.tower)
    local attack_damage = self.tower:GetAverageTrueAttackDamage(target)

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

    -- Main debuff damage tick, includes the main target
    DamageEntitiesInArea(target:GetAbsOrigin(), self.burnAOE, self.tower, damage)

    -- Attack damage
    DamageEntity(target, self.tower, attack_damage) 
end

function CreateSunburnRemnant(entity)
    local position = entity:GetAbsOrigin()

    local particle = ParticleManager:CreateParticle("particles/custom/towers/flame/remnant.vpcf", PATTACH_CUSTOMORIGIN, nil)    
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, position)
    ParticleManager:SetParticleControl(particle, 2, Vector(entity.SunburnData.AOE, 0, 0))
    ParticleManager:SetParticleControl(particle, 3, Vector(entity.SunburnData.AOE, 0, 0))
    ParticleManager:SetParticleControl(particle, 4, Vector(entity.SunburnData.AOE, 0, 0))

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
        return    
    end

    Timers:CreateTimer(remnantDuration, function()
        ParticleManager:DestroyParticle(particle, false)
    end)    
end

RegisterTowerClass(FlameTower, FlameTower.className)    