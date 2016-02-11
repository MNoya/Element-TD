-- Vapor Tower class (Fire + Water)
-- Non-targeting tower whose attack does 30/150/750 damage to creeps in 700 area around the tower. 
-- Then 0.5 seconds later it does 15/75/375 damage in 350 area around each creep hit.

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
    local aftershock_damage = ApplyAbilityDamageFromModifiers(self.aftershockDamage[self.level], self.tower)    

    if self.tower:GetHealthPercent() == 100 and #creeps > 0 then
        self.tower:StartGesture(ACT_DOTA_CAST_ABILITY_2) --crush
        self.ability:StartCooldown(1 / self.tower:GetAttacksPerSecond())

        Sounds:EmitSoundOnClient(self.playerID, "Vapor.Strike")

        for _,creep in pairs(creeps) do
            local particle = ParticleManager:CreateParticle("particles/custom/towers/vapor/tako.vpcf", PATTACH_ABSORIGIN, creep)     
            ParticleManager:SetParticleControl(particle, 1, Vector(self.initialAOE/4, 1, 1)) 

            DamageEntity(creep, self.tower, initial_damage)    

            Timers:CreateTimer(0.5, function()
                local aftershock_creeps = GetCreepsInArea(creep:GetAbsOrigin(), self.aftershockAOE)
                for __, creep2 in pairs(aftershock_creeps) do
                    if creep2:entindex() ~= creep:entindex() and creep2:IsAlive() then --don't damage self with aftershock
                        DamageEntity(creep2, self.tower, aftershock_damage)    
                    end
                end
            end)
        end
    end
end

function VaporTower:OnCreated()
    self.level = GetUnitKeyValue(self.towerClass, "Level")    
    local spellName = "vapor_tower_evaporate"
    self.ability = AddAbility(self.tower, spellName, self.level)        

    self.initialDamage = GetAbilitySpecialValue(spellName, "damage")    
    self.aftershockDamage = GetAbilitySpecialValue(spellName, "aftershock_damage")    
    self.initialAOE = GetAbilitySpecialValue(spellName, "aoe")+self.tower:GetHullRadius()
    self.aftershockAOE = GetAbilitySpecialValue(spellName, "aftershock_aoe")
    self.playerID = self.tower:GetPlayerOwnerID()

    local time = 1 / self.tower:GetAttacksPerSecond()
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