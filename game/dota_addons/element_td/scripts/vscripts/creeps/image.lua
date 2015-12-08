-- Image Creep class
CreepImage = createClass({
        creep = nil,
        creepClass = "",

        constructor = function(self, creep, creepClass)
            self.creep = creep;
            self.creepClass = creepClass or self.creepClass
        end
    },
    {
        className = "CreepImage"
    },
CreepBasic);

function CreepImage:OnSpawned()
    self.ability = AddAbility(self.creep, "creep_ability_image");
end

function CreepImage:OnTakeDamage(keys)
    if self.creep:GetHealth() > 0 and self.ability and self.ability:IsFullyCastable() and not self.creep.isImage then
        self.ability:StartCooldown(10);
        local image = SpawnEntity(self.creep:GetUnitName(), self.creep.playerID, self.creep:GetOrigin());
        image.isImage = true;
        image:SetMaxHealth(self.creep:GetMaxHealth());
        image:SetBaseMaxHealth(self.creep:GetMaxHealth());
        image:SetDeathXP(0);
        image:SetHealth(self.creep:GetHealth());
        image:SetForwardVector(self.creep:GetForwardVector());
        AddAbility(image, "creep_ability_image");

        local playerData = GetPlayerData(self.creep.playerID)
        local destination = EntityEndLocations[playerData.sector + 1];

        image:SetContextThink("MoveUnit" .. image:entindex(), function()
            ExecuteOrderFromTable({
                UnitIndex = image:entindex(),
                OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                Position = destination
            });
            if (image:GetOrigin() - destination):Length2D() <= 150 then
                image:ForceKill(false);
            end
            return 0.5;
        end, 0);

        image:SetContextThink("ImageTimer", function()
            image:ForceKill(false);
            return nil;
        end, tonumber(keys.ImageDuration));

        if math.random(0, 1) == 0 then
            self.creep:CastAbilityOnTarget(image, self.ability, self.creep.playerID);
        else
            self.creep:CastAbilityOnTarget(self.creep, self.ability, self.creep.playerID);
        end
    end
end

function CreepImage:OnDeath()
    if self.creep.isImage then
        local particle = ParticleManager:CreateParticle("particles/generic_gameplay/illusion_killed.vpcf", PATTACH_ABSORIGIN, self.creep);
        ParticleManager:SetParticleControl(particle, 0, self.creep:GetOrigin());
        self.creep:SetModelScale(0);
    end
end

RegisterCreepClass(CreepImage, CreepImage.className);