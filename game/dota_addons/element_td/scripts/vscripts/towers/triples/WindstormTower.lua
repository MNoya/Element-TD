-- Windstorm (Fire + Light + Water) 
-- This is a support tower. It has an ability that summons a tornado. Tornado lasts indefinitely. One tornado per tower. Tornado can be moved like a unit. 
-- Tornado slows down movement speed of all creeps by X% in an area of effect around it. 
-- Tornado also does X damage per second in an area of effect around it. Multiple tornadoes stack for damage but not slow.

WindstormTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "WindstormTower"
    },
nil)

function WindstormTower:SpawnTornado(keys)
    print("Spawn Tornado")
    if keys.target_points[1] then
        -- Clear exisiting tornado (only one exisit per tower at a time)
        self:RemoveTornado()

        self.ability:SetChanneling(true)
        self.ability:StartCooldown(self.cooldown)
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_tornado_summoned", {})

        self.tornado = CreateUnitByName( "windstorm_tornado", keys.target_points[1], false, self.tower, self.tower:GetOwner(), self.tower:GetTeamNumber() )
        self.tornado.isTornado = true
        self.tornado.tower = self.tower
        self.tornado:SetControllableByPlayer(self.tower:GetOwner():GetPlayerID(), true)
        self.tornado:AddNewModifier(nil, nil, "modifier_no_health_bar", {})

        local tornado_ability = self.tornado:FindAbilityByName("windstorm_tornado_slow")
        tornado_ability:SetLevel(self.tower:GetLevel())

        local playerData = GetPlayerData(self.tower:GetOwner():GetPlayerID())
        local sector = playerData.sector + 1
        local damage = GetAbilitySpecialValue("windstorm_tower_tornado", "damage")[self.tower:GetLevel()]

        if keys.target and keys.target:IsAlive() then
            Timers:CreateTimer(0.05, function()
                if self.tornado then
                    ExecuteOrderFromTable({
                        UnitIndex = self.tornado:entindex(),
                        OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
                        TargetIndex = keys.target:entindex(),
                        Position = nil,
                        Queue = false
                    })
                end
            end)
        end

        --create the tornado thinker
        Timers:CreateTimer(1, function()
            if IsValidEntity(self.tower) and IsValidEntity(self.tornado) then
                local pos = self.tornado:GetAbsOrigin()
                local bounds = SectorBounds[sector]

                local creeps = GetCreepsInArea(self.tornado:GetAbsOrigin(), self.aoe)
                for _,v in pairs(creeps) do
                    DamageEntity(v, self.tower, damage)
                end    

                if not (pos.x > bounds.left + 400 and pos.x < bounds.right - 400 and pos.y < bounds.top - 400 and pos.y > bounds.bottom + 400) then
                    print("Tornado being deleted for leaving sector.")
                    self:RemoveTornado()
                    return
                end
                return 1
            end
        end)

        self.tornadoTimer = Timers:CreateTimer(5, function()
            print("Timer Tornado Remove")
            self:RemoveTornado()
        end)        
    end
end

function WindstormTower:RemoveTornado(keys)
    self.ability:SetActivated(true)
    self.ability:SetChanneling(false)
    self.tower:RemoveModifierByName("modifier_tornado_summoned")
    if self.tornado then
        UTIL_Remove(self.tornado)
        self.tornado = nil
    end
    if self.tornadoTimer then
        Timers:RemoveTimer(self.tornadoTimer)
        self.tornadoTimer = nil
    end
end

function WindstormTower:OnDestroyed()
    self:RemoveTornado()
    if self.timer then
        Timers:RemoveTimer(self.timer)
    end
end

function WindstormTower:OnCreated()
    self.ability = AddAbility(self.tower, "windstorm_tower_tornado", self.tower:GetLevel())
    self.aoe = GetAbilitySpecialValue("windstorm_tower_tornado", "radius")
    self.cooldown = self.ability:GetCooldown(1)
    self.timer = Timers:CreateTimer(0.1, function()
        if IsValidEntity(self.tower) then
            if self.ability:IsFullyCastable() then
                local unit = GetTowerTarget(self.tower, TOWER_TARGETING_CLOSEST, self.aoe)
                if unit then
                    self.tower:CastAbilityOnTarget(unit, self.ability, self.tower:GetOwner():GetPlayerID())
                    return 5
                end
            end
            return 0.1
        end
    end)
end

function WindstormTower:OnAttackLanded(keys) end

function WindstormTower:TornadoTest(keys)
    print("tornado spawned")
end

RegisterTowerClass(WindstormTower, WindstormTower.className)