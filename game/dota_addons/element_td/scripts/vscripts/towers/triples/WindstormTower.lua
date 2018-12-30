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
    local baseTime = 5
    local newTime = 1 / self.tower:GetAttacksPerSecond()
    StartAnimation(self.tower, {duration=newTime, activity=ACT_DOTA_TELEPORT, rate=0.5*(baseTime/newTime)})
    
    self.next_tornado = GameRules:GetGameTime() + (1 / self.tower:GetAttacksPerSecond())

    self.tower:EmitSound("Windstorm.TornadoSpawn")

    local target = keys.target
    local position = keys.origin or (target and target:GetAbsOrigin())

    local tornado = CreateUnitByName( "windstorm_tornado", position, false, self.tower, self.tower:GetOwner(), self.tower:GetTeamNumber() )
    tornado.isTornado = true
    tornado.tower = self.tower
    tornado:SetControllableByPlayer(self.playerID, true)
    tornado:AddNewModifier(tornado, nil, "modifier_no_health_bar", {})

    local tornado_ability = tornado:FindAbilityByName("windstorm_tornado_slow")
    tornado_ability:SetLevel(self.tower:GetLevel())

    local playerData = GetPlayerData(self.playerID)
    local sector = playerData.sector + 1
    local damage = ApplyAbilityDamageFromModifiers(self.damage, self.tower)

    if target then
        self.tower:MoveToTargetToAttack(target)
    end

    if target and target:IsAlive() then
        Timers:CreateTimer(0.05, function()
            if tornado then
                ExecuteOrderFromTable({
                    UnitIndex = tornado:entindex(),
                    OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
                    TargetIndex = target:entindex(),
                    Position = nil,
                    Queue = false
                })
            end
        end)
    end

    --create the tornado thinker
    Timers:CreateTimer(1, function()
        if IsValidEntity(self.tower) and IsValidEntity(tornado) and tornado:IsAlive() then
            local pos = tornado:GetAbsOrigin()
            local bounds = SectorBounds[sector]

            local creeps = GetCreepsInArea(tornado:GetAbsOrigin(), self.aoe)
            for _,v in pairs(creeps) do
                DamageEntity(v, self.tower, damage)
            end    

            if not COOP_MAP and not (pos.x > bounds.left + 400 and pos.x < bounds.right - 400 and pos.y < bounds.top - 400 and pos.y > bounds.bottom + 400) then
                tornado:RemoveModifierByName("modifier_tornado_aura")
                tornado:ForceKill(true)
                return
            end
            return 1
        end
    end)

    Timers:CreateTimer(self.duration, function()
        tornado:RemoveModifierByName("modifier_tornado_aura")
        tornado:ForceKill(true)
    end)
end

function WindstormTower:OnBuildingFinished()
    Timers:CreateTimer(0.1, function()
        if IsValidEntity(self.tower) and self.tower:IsAlive() then
            if GameRules:GetGameTime() >= self.next_tornado and not self.tower:HasModifier("modifier_attacking_ground") then
                local unit = GetTowerTarget(self.tower, TOWER_TARGETING_CLOSEST, self.findRadius)
                if unit then
                    self:SpawnTornado({target=unit})
                    return 0.1
                end
            end
            return 0.1
        end
    end)
end

function WindstormTower:OnCreated()
    self.ability = AddAbility(self.tower, "windstorm_tower_tornado", self.tower:GetLevel())
    self.aoe = GetAbilitySpecialValue("windstorm_tower_tornado", "radius")
    self.findRadius = self.tower:GetAttackRange() + self.tower:GetHullRadius()
    self.duration = GetAbilitySpecialValue("windstorm_tower_tornado", "duration")
    self.playerID = self.tower:GetPlayerOwnerID()
    self.damage = GetAbilitySpecialValue("windstorm_tower_tornado", "damage")[self.tower:GetLevel()]
    self.next_tornado = GameRules:GetGameTime()

    Timers:CreateTimer(function() 
        if IsValidEntity(self.tower) and self.tower:IsAlive() then
            if not self.tower:HasModifier("modifier_attacking_ground") then
                local attackTarget = self.tower:GetAttackTarget() or self.tower:GetAggroTarget()
                if attackTarget then
                    local distanceToTarget = (self.tower:GetAbsOrigin() - attackTarget:GetAbsOrigin()):Length2D()
                    if distanceToTarget > self.tower:GetAttackRange() then
                        self.tower:Interrupt()
                    end
                end
            end
            return 0.5
        end
    end)
end

function WindstormTower:OnAttackLanded(keys) end

RegisterTowerClass(WindstormTower, WindstormTower.className)