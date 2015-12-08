-- Ice (Light + Water)
-- Each attack is a linear ball of ice. Does damage if it hits creeps, double damage if the creep is hit by the middle. 
-- Explodes after travelling a certain distance.
IceTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "IceTower"
    },
nil);

function IceTower:OnAttackStart(keys)
    local targetEntity = keys.target;
    local targetPos = targetEntity:GetAbsOrigin();
    local proj = CreateUnitByName("hydro_tower_projectile", self.projOrigin, false, nil, nil, self.tower:GetTeam());

    proj:SetAbsOrigin(self.projOrigin);
    proj:SetOwner(self.tower:GetOwner());
    proj:AddNewModifier(nil, nil, "modifier_invulnerable", {});
    proj:AddNewModifier(nil, nil, "modifier_phased", {});
    ApplyDummyPassive(proj);
    proj.parent = self.tower;
    proj.startOrigin = self.projOrigin;
    proj.hitByInner = {};
    proj.hitByOuter = {};
    self.projectiles[proj:entindex()] = 1;

    local direction = (targetPos - self.projOrigin):Normalized();
    proj.velocity = direction * 25;
    proj.velocity.z = 0;
    proj.target = targetEntity;
    proj.targetPos = targetEntity:GetAbsOrigin();
    proj.particleEffect = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_main.vpcf", PATTACH_ABSORIGIN_FOLLOW, proj);
    ParticleManager:SetParticleControl(proj.particleEffect, 0, Vector(0, 0, 0));
    ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin());

    proj:SetContextThink("ProjectileThinker" .. proj:entindex(), (function()
        local pos = proj:GetAbsOrigin();

        pos.x = pos.x + proj.velocity.x;
        pos.y = pos.y + proj.velocity.y;
        local groundPos = GetGroundPosition(pos, nil);
        groundPos.z = groundPos.z + 128;
        proj:SetAbsOrigin(groundPos);
        ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin());

        ------------------------------
        -- deal damage to creeps
        local creeps = GetCreepsInArea(proj:GetOrigin(), 150);
        for _, creep in pairs(creeps) do
            if IsValidEntity(creep) then
                if not proj.hitByOuter[creep:entindex()] then
                    DamageEntity(creep, self.tower, self.damage);
                    proj.hitByOuter[creep:entindex()] = true;
                end
            end
        end
        local creeps2 = GetCreepsInArea(proj:GetOrigin(), 100);
        for _, creep in pairs(creeps2) do
            if IsValidEntity(creep) then
                if not proj.hitByInner[creep:entindex()] then
                    DamageEntity(creep, self.tower, self.damage);
                    proj.hitByInner[creep:entindex()] = true;
                end     
            end
        end
        -------------------------------------------
    
        local distance = dist2D(proj.startOrigin, pos);
        if distance >= 1000 then
            DamageEntitiesInArea(proj:GetOrigin(), self.aoe, self.tower, self.damage * 2);
            
            local explosionParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_explode.vpcf", PATTACH_ABSORIGIN, self.tower);
            ParticleManager:SetParticleControl(explosionParticle, 0, Vector(0, 0, 0));
            ParticleManager:SetParticleControl(explosionParticle, 3, proj:GetAbsOrigin());

            self.projectiles[proj:entindex()] = nil;
            UTIL_RemoveImmediate(proj);
            return;
        end
        return 0.01;
    end), 0.01);
end

function IceTower:OnCreated()
    self.ability = AddAbility(self.tower, "ice_tower_ice_blast", self.tower:GetLevel());
    self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));
    self.damage = GetAbilitySpecialValue("ice_tower_ice_blast", "damage")[self.tower:GetLevel()];
    self.aoe = GetAbilitySpecialValue("ice_tower_ice_blast", "aoe");
    self.projectiles = {};
end

function IceTower:OnDestroyed()
    for id,_ in pairs(self.projectiles) do
        UTIL_RemoveImmediate(EntIndexToHScript(id));
    end
end

function IceTower:OnAttackLanded(keys) end
RegisterTowerClass(IceTower, IceTower.className);