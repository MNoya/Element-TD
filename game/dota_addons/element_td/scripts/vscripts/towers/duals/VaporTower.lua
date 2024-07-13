-- Vapor Tower class (Fire + Water)
-- Non-targeting tower whose attack does 30/150/750 damage to creeps in 700 area around the tower.
-- The damage dealt increases the more creeps are in the AoE

VaporTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "VaporTower"
    },
nil)

function VaporTower:VaporWaveAttack()
    local creeps = GetCreepsInArea(self.tower:GetOrigin(), self.initialAOE)    
    local initial_damage = ApplyAbilityDamageFromModifiers(self.initialDamage[self.level], self.tower)    
    local damage_per_creep = ApplyAbilityDamageFromModifiers(self.damagePerCreep[self.level], self.tower)    
    local final_damage = initial_damage + (#creeps * damage_per_creep)

    if self.tower:GetHealthPercent() == 100 and #creeps > 0 then
        self.tower:StartGesture(ACT_DOTA_CAST_ABILITY_2) --crush
        self.ability:StartCooldown(1 / self.tower:GetAttacksPerSecond(false))

        self.tower:EmitSound("Vapor.Strike")

        for _,creep in pairs(creeps) do
            local particle = ParticleManager:CreateParticle("particles/custom/towers/vapor/tako.vpcf", PATTACH_ABSORIGIN, creep)     
            ParticleManager:SetParticleControl(particle, 1, Vector(self.initialAOE/4, 1, 1)) 

            DamageEntity(creep, self.tower, final_damage)    
        end
    end
end

function VaporTower:OnCreated()
    self.level = GetUnitKeyValue(self.towerClass, "Level")    
    local spellName = "vapor_tower_evaporate"
    self.ability = AddAbility(self.tower, spellName, self.level)        

    self.initialDamage = GetAbilitySpecialValue(spellName, "base_damage")    
    self.damagePerCreep = GetAbilitySpecialValue(spellName, "damage_per_creep")    
    self.initialAOE = GetAbilitySpecialValue(spellName, "aoe") + self.tower:GetHullRadius()
    self.playerID = self.tower:GetPlayerOwnerID()

    local time = 1 / self.tower:GetAttacksPerSecond(false)
    Timers:CreateTimer(time, function()
        if IsValidAlive(self.tower) then
            if self.ability:IsCooldownReady() then
                self:VaporWaveAttack()
            end
            return 0.1
        end
    end)
end

RegisterTowerClass(VaporTower, VaporTower.className)    