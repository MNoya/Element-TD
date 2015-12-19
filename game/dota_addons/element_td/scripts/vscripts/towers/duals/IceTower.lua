-- Ice (Light + Water)
-- Each attack is a linear ball of ice. Does damage if it hits creeps, double damage if the creep is hit by the middle. 
-- Explodes after travelling a certain distance.
IceTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "IceTower"
    },
nil)    

function IceTower:OnAttackStart(keys)
    local targetEntity = keys.target    
    local targetPos = targetEntity:GetAbsOrigin()    
    local proj = CreateUnitByName("hydro_tower_projectile", self.projOrigin, false, nil, nil, self.tower:GetTeam())

    proj:SetAbsOrigin(self.projOrigin)    
    proj:SetOwner(self.tower:GetOwner())    
    proj:AddNewModifier(nil, nil, "modifier_invulnerable", {})    
    proj:AddNewModifier(nil, nil, "modifier_phased", {})    

     -- hopefully this works as intended
    proj:AddNewModifier(proj, nil, "modifier_out_of_world", {})    
      
    proj.parent = self.tower    
    proj.startOrigin = self.projOrigin    
    proj.hitByInner = {}    
    proj.hitByOuter = {}    
    self.projectiles[proj:entindex()] = 1    

    local direction = (targetPos - self.projOrigin):Normalized()    
    proj.velocity = direction * (self.projectile_speed/30)
    proj.velocity.z = 0    
    proj.target = targetEntity    
    proj.targetPos = targetEntity:GetAbsOrigin()    
    proj.particleEffect = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_main.vpcf", PATTACH_ABSORIGIN_FOLLOW, proj)
    ParticleManager:SetParticleControl(proj.particleEffect, 0, Vector(0, 0, 0))    
    ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin())    

    Timers:CreateTimer(function()
        if not IsValidEntity(self.tower) then return end

        local pos = proj:GetAbsOrigin()    
        local aoe = self.aoe_start + (dist2D(proj.startOrigin, pos)*((self.aoe_end-self.aoe_start)/self.distance))

        pos.x = pos.x + proj.velocity.x    
        pos.y = pos.y + proj.velocity.y    
        local groundPos = GetGroundPosition(pos, nil)    
        groundPos.z = groundPos.z + 128    
        proj:SetAbsOrigin(groundPos)    
        ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin())    

        ------------------------------
        -- deal damage to creeps
        local creeps = GetCreepsInArea(proj:GetOrigin(), aoe)    
        for _, creep in pairs(creeps) do
            if IsValidEntity(creep) then
                if not proj.hitByOuter[creep:entindex()] then
                    DamageEntity(creep, self.tower, self.damage)    
                    proj.hitByOuter[creep:entindex()] = true    
                end
            end
        end
        -------------------------------------------
    
        local distance = dist2D(proj.startOrigin, pos)    
        if distance >= self.distance then
            
            -- End Particle 

            self.projectiles[proj:entindex()] = nil    
            UTIL_Remove(proj)    
            return
        end
        return 0.01    
    end)
end

function IceTower:OnCreated()
    self.ability = AddAbility(self.tower, "ice_tower_ice_blast", self.tower:GetLevel())    
    self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))    
    self.damage = GetAbilitySpecialValue("ice_tower_ice_blast", "damage")[self.tower:GetLevel()]    
    self.aoe_start = GetAbilitySpecialValue("ice_tower_ice_blast", "aoe_start")
    self.aoe_end = GetAbilitySpecialValue("ice_tower_ice_blast", "aoe_end")
    self.distance = GetAbilitySpecialValue("ice_tower_ice_blast", "distance")
    self.projectile_speed = GetAbilitySpecialValue("ice_tower_ice_blast", "projectile_speed")
    self.projectiles = {}    
end

function IceTower:OnDestroyed()
    for id,_ in pairs(self.projectiles) do
        UTIL_Remove(EntIndexToHScript(id))    
    end
end

function IceTower:OnAttackLanded(keys) end
RegisterTowerClass(IceTower, IceTower.className)    