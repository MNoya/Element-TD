-- Mechanical Creep class
CreepMechanical = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepMechanical"
    },
CreepBasic)

function CreepMechanical:OnSpawned() 
    local creep = self.creep

    Timers:CreateTimer(math.random(3, 12), function()
        if not IsValidEntity(creep) or not creep:IsAlive() then return end

        creep:FindAbilityByName("creep_ability_mechanical"):ApplyDataDrivenModifier(creep, creep, "mechanical_buff", {})
        creep:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 3})

        return 9
    end)
end

RegisterCreepClass(CreepMechanical, CreepMechanical.className)