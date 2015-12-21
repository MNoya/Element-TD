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
        self.ability:SetChanneling(true)
        self.ability:SetActivated(false)

        local tornadoCaster = AddAbility(self.tower, "windstorm_tower_tornado_creator")
        self.tower:CastAbilityOnPosition(keys.target_points[1], tornadoCaster, 1)
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_tornado_summoned", {}) 
        
        Timers:CreateTimer("WaitForTornado"..self.tower:entindex(), {
            endTime = 0.2,
            callback = function()
                local entities = Entities:FindAllByClassnameWithin("npc_dota_base_additive", self.tower:GetOrigin(), 750)
                for _, tornado in pairs(entities) do
                    if not tornado.isTornado then

                        self.tornado = tornado
                        self.tornado.isTornado = true
                        self.tornado.tower = self.tower

                        self.tornado:RemoveAbility("tornado_tempest")
                        self.tornado:AddNewModifier(nil, nil, "modifier_invulnerable", {})
                        AddAbility(self.tornado, "windstorm_tornado_slow", self.tower:GetLevel())

                        tornadoCaster:SetHidden(true)
                        Timers:CreateTimer("DeleteCaster" .. self.tower:entindex(), {
                            endTime = 1,
                            callback = function()
                                self.tower:RemoveAbility("windstorm_tower_tornado_creator") 
                            end
                        })

                        local playerData = GetPlayerData(self.tower:GetOwner():GetPlayerID())
                        local sector = playerData.sector + 1
                        local damage = GetAbilitySpecialValue("windstorm_tower_tornado", "damage")[self.tower:GetLevel()]
                        local aoe = GetAbilitySpecialValue("windstorm_tower_tornado", "radius")

                        --create the tornado thinker
                        Timers:CreateTimer(1, function()
                            if IsValidEntity(self.tower) and IsValidEntity(self.tornado) then
                                local pos = self.tornado:GetAbsOrigin()
                                local bounds = SectorBounds[sector]

                                local creeps = GetCreepsInArea(self.tornado:GetAbsOrigin(), aoe)
                                for _,v in pairs(creeps) do
                                    DamageEntity(v, self.tower, damage)
                                end    

                                if not (pos.x > bounds.left + 400 and pos.x < bounds.right - 400 and pos.y < bounds.top - 400 and pos.y > bounds.bottom + 400) then
                                    print("Tornado being deleted for leaving sector.")
                                    UTIL_RemoveImmediate(self.tornado)
                                    self.ability:SetActivated(true)
                                    self.tower:RemoveModifierByName("modifier_tornado_summoned")
                                    return
                                end
                                return 1
                            end
                        end)
                    end
                end
            end
        })
    
        Timers:CreateTimer(5, function()
            self:RemoveTornado()
        end)        
    end
end

function WindstormTower:RemoveTornado(keys)
    print("Remove Tornado")
    self.ability:SetActivated(true)
    self.ability:SetChanneling(false)
    if self.tornado then
        UTIL_RemoveImmediate(self.tornado)
    end
end

function WindstormTower:OnDestroyed()
    if self.tornado then
        UTIL_RemoveImmediate(self.tornado)
    end
end

function WindstormTower:OnCreated()
    self.ability = AddAbility(self.tower, "windstorm_tower_tornado", self.tower:GetLevel())
end

function WindstormTower:OnAttackLanded(keys) end

function WindstormTower:TornadoTest(keys)
    print("tornado spawned")
end

RegisterTowerClass(WindstormTower, WindstormTower.className)