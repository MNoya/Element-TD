-- Electricity Tower class (Fire + Light)
-- Attack bounces up to three times with each bounce doing 20% less damage. 
-- A bounce targets the next closest creep within 500 range. If there are no creeps within that range, then there is no bounce.

ElectricityTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "ElectricityTower"
    },
nil)    


function ElectricityTower:OnAttack(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local teamNumber = caster:GetTeamNumber()
    local findType = FIND_CLOSEST

    local damage = self.damage
    local bounces = self.bounces

    local attach_point = "attach_attack1"
    if RollPercentage(50) then
        attach_point = "attach_attack2"
    end

    local start_position = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment(attach_point))
    self.tower:EmitSound("Electricity.Lightning")
    local current_position = self:CreateChainLightning(caster, start_position, target, damage)

    -- Every target struck by the chain is added to an entity index list
    local targetsStruck = {}
    targetsStruck[target:GetEntityIndex()] = true

    Timers:CreateTimer(self.time_between_bounces, function()  
        local units = FindUnitsInRadius(teamNumber, current_position, target, self.bounce_range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, 0, findType, true)

        if #units > 0 then

            -- Hit the first unit that hasn't been struck yet
            local bounce_target
            for _,unit in pairs(units) do
                local entIndex = unit:GetEntityIndex()
                if not targetsStruck[entIndex] then
                    bounce_target = unit
                    targetsStruck[entIndex] = true
                    break
                end
            end

            if bounce_target then
                damage = damage - (damage*self.decay)
                current_position = self:CreateChainLightning(caster, current_position, bounce_target, damage)

                -- decrement remaining spell bounces
                bounces = bounces - 1

                -- fire the timer again if spell bounces remain
                if bounces > 0 then
                    return self.time_between_bounces
                end
            end
        end
    end)
end

-- Creates a chain lightning on a start position towards a target. Also does sound, damage and popup
function ElectricityTower:CreateChainLightning( caster, start_position, target, damage )
    local target_position = target:GetAbsOrigin()
    local attach_hitloc = target:ScriptLookupAttachment("attach_hitloc")
    if attach_hitloc ~= 0 then
        target_position = target:GetAttachmentOrigin(attach_hitloc)
    else
        target_position.z = target_position.z + target:GetBoundingMaxs().z
    end

    local particle = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle,0, start_position)
    ParticleManager:SetParticleControl(particle,1, target_position)
    
    local dmg = ApplyAbilityDamageFromModifiers(damage, self.tower)    
    DamageEntity(target, self.tower, dmg)

    return target_position
end

function ElectricityTower:OnCreated()
    local level = tonumber(GetUnitKeyValue(self.tower.class, "Level"))
    self.ability = AddAbility(self.tower, "electricity_tower_arc_lightning_passive", level)
    self.damage = self.ability:GetLevelSpecialValueFor( "damage", level - 1 )
    self.bounces = self.ability:GetLevelSpecialValueFor( "jump_count", level - 1 )
    self.bounce_range = self.ability:GetLevelSpecialValueFor( "bounce_range", level - 1 )
    self.decay = self.ability:GetLevelSpecialValueFor( "damage_decrease", level - 1 ) * 0.01
    self.time_between_bounces = 0.2
    self.playerID = self.tower:GetPlayerOwnerID()
end

function ElectricityTower:OnAttackLanded(keys) end
RegisterTowerClass(ElectricityTower, ElectricityTower.className)    