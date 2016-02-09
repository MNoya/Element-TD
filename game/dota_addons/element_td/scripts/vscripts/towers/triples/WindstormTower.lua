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
    if keys.target_points[1] then

        local baseTime = 5
        local newTime = 1 / self.tower:GetAttacksPerSecond()
        StartAnimation(self.tower, {duration=baseTime, activity=ACT_DOTA_TELEPORT, rate=0.5})
        
        self.ability:StartCooldown(1 / self.tower:GetAttacksPerSecond())

        local tornado = CreateUnitByName( "windstorm_tornado", keys.target_points[1], false, self.tower, self.tower:GetOwner(), self.tower:GetTeamNumber() )
        tornado.isTornado = true
        tornado.tower = self.tower
        tornado:SetControllableByPlayer(self.playerID, true)
        tornado:AddNewModifier(tornado, nil, "modifier_no_health_bar", {})

        local tornado_ability = tornado:FindAbilityByName("windstorm_tornado_slow")
        tornado_ability:SetLevel(self.tower:GetLevel())

        local playerData = GetPlayerData(self.playerID)
        local sector = playerData.sector + 1
        local damage = ApplyAbilityDamageFromModifiers(self.damage, self.tower)

        if keys.target and keys.target:IsAlive() then
            Timers:CreateTimer(0.05, function()
                if tornado then
                    ExecuteOrderFromTable({
                        UnitIndex = tornado:entindex(),
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
            if IsValidEntity(self.tower) and IsValidEntity(tornado) then
                local pos = tornado:GetAbsOrigin()
                local bounds = SectorBounds[sector]

                local creeps = GetCreepsInArea(tornado:GetAbsOrigin(), self.aoe)
                for _,v in pairs(creeps) do
                    DamageEntity(v, self.tower, damage)
                end    

                if not (pos.x > bounds.left + 400 and pos.x < bounds.right - 400 and pos.y < bounds.top - 400 and pos.y > bounds.bottom + 400) then
                    print("Tornado being deleted for leaving sector.")
                    tornado:RemoveSelf()
                    return
                end
                return 1
            end
        end)

        Timers:CreateTimer(self.duration, function()
            tornado:RemoveSelf()
        end)        
    end
end

function WindstormTower:OnCreated()
    self.ability = AddAbility(self.tower, "windstorm_tower_tornado", self.tower:GetLevel())
    self.aoe = GetAbilitySpecialValue("windstorm_tower_tornado", "radius")
    self.duration = GetAbilitySpecialValue("windstorm_tower_tornado", "duration")
    self.playerID = self.tower:GetPlayerOwnerID()
    self.damage = GetAbilitySpecialValue("windstorm_tower_tornado", "damage")[self.tower:GetLevel()]
    self.timer = Timers:CreateTimer(0.1, function()
        if IsValidEntity(self.tower) then
            if self.ability:IsFullyCastable() then
                local unit = GetTowerTarget(self.tower, TOWER_TARGETING_CLOSEST, self.aoe)
                if unit then
                    self.tower:CastAbilityOnTarget(unit, self.ability, self.playerID)
                    return 1 / self.tower:GetAttacksPerSecond()
                end
            end
            return 0.1
        end
    end)
end

function WindstormTower:OnAttackLanded(keys) end

RegisterTowerClass(WindstormTower, WindstormTower.className)