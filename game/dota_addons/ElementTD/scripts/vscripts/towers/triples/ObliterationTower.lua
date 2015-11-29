-- Obliteration (Darkness + Light + Nature)
-- This is a long range single target tower. The projectile starts out faster than normal but slows down as it travels. 
-- As it travels the projectile gains more and more splash. If the projectile slows to a stop before hitting the target it explodes. 
-- Projectile starts at 0 splash and maxes out at X splash. Projectile should have a travel range longer than the tower's attack range. 
-- It may be good cosmetics to have the projectile grow as it travels.

ObliterationTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "ObliterationTower";
	},
nil);

function ObliterationTower:OnAttackStart(keys)
	local targetEntity = keys.target;
	local targetPos = targetEntity:GetOrigin();
  	local proj = CreateUnitByName("hydro_tower_projectile", self.projOrigin, false, nil, nil, self.tower:GetTeam());

	proj:SetAbsOrigin(self.projOrigin);
  	proj:SetOwner(self.tower:GetOwner());
  	proj:AddNewModifier(nil, nil, "modifier_invulnerable", {});
  	proj:AddNewModifier(nil, nil, "modifier_phased", {});
 	
  	ApplyDummyPassive(proj);

  	proj.parent = self.tower;
  	proj.startOrigin = self.projOrigin;
  	proj.splashAOE = 0;
  	self.projectiles[proj:entindex()] = 1;

  	local direction = (targetPos - self.projOrigin):Normalized();
  	proj.speed = 40; -- initial speed
  	proj.velocity = direction * proj.speed;
  	proj.target = targetEntity;
  	proj.targetPos = targetEntity:GetOrigin();
  	proj.particleEffect = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, proj);
	
	ParticleManager:SetParticleControl(proj.particleEffect, 0, Vector(0, 0, 0));
	ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin());

	local totalLoops, curLoops = self.projDuration * 10, 0;
	local speedIncr = -(proj.speed / totalLoops);
	local splashIncr = self.maxSplash / totalLoops;

	-- Projectile Thinker 2 --
	proj:SetContextThink("ProjectileThinker2" .. proj:entindex(), function()
		proj.speed = proj.speed + speedIncr;
		proj.splashAOE = proj.splashAOE + splashIncr;
		if proj.splashAOE > self.maxSplash then
			proj.splashAOE = self.maxSplash;
		end

		local distanceToTarget = (proj.targetPos - proj:GetAbsOrigin()):Length2D();
		if proj.speed <= 15 or distanceToTarget <= 100 then
			proj.speed = 0;

			local dummyPos = GetGroundPosition(proj:GetAbsOrigin(), nil);
			dummyPos.z = dummyPos.z + 16;
			local dummy = CreateUnitByName("tower_dummy", dummyPos, false, nil, nil, self.tower:GetTeam());
			dummy:SetAbsOrigin(dummyPos);
			dummy:AddNewModifier(nil, nil, "modifier_invulnerable", {});
  			dummy:AddNewModifier(nil, nil, "modifier_phased", {});
 			ApplyDummyPassive(dummy);

			local explosionParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_ABSORIGIN, dummy);
	    	ParticleManager:SetParticleControl(explosionParticle, 0, dummyPos);
	    	ParticleManager:SetParticleControl(explosionParticle, 1, Vector(proj.splashAOE, 0, 1));
	    	ParticleManager:SetParticleControl(explosionParticle, 2, Vector(0, 0, 0));
	    	ParticleManager:SetParticleControl(explosionParticle, 3, dummyPos);

	    	local entities = GetCreepsInArea(dummyPos, proj.splashAOE);
        	for _, entity in pairs(entities) do
          		DamageEntity(entity, self.tower, ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower));
       		end

       		-- damage target even if aoe is too small
       		if distanceToTarget <= 100 and proj.splashAOE < distanceToTarget and IsValidEntity(proj.target) and proj.target:IsAlive() then
				DamageEntity(proj.target, self.tower, ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower));
       		end

	    	CreateTimer("DeleteDummy".. dummy:entindex(), DURATION, {
	    		duration = 2,
	    		callback = function(timer)
	    			UTIL_RemoveImmediate(dummy);
	    		end
	    	});

			self.projectiles[proj:entindex()] = nil;
			UTIL_RemoveImmediate(proj);
		end
		return 0.1;
	end, 0.1);
	----

	-- Projectile Thinker 1 --
	proj:SetContextThink("ProjectileThinker" .. proj:entindex(), (function()
	    local pos = proj:GetAbsOrigin();

	    if IsValidEntity(proj.target) and proj.target:IsAlive() then
      		proj.targetPos = proj.target:GetAbsOrigin();
    	end
    	proj.velocity = (proj.targetPos - pos):Normalized() * proj.speed;

	    pos.x = pos.x + proj.velocity.x;
	    pos.y = pos.y + proj.velocity.y;
	    pos.z = pos.z + proj.velocity.z;
	    if pos.z < self.groundHeight then
	    	pos.z = self.groundHeight;
	    end
	    proj:SetAbsOrigin(pos);
		ParticleManager:SetParticleControl(proj.particleEffect, 3, proj:GetAbsOrigin());
	    return 0.01;
	end), 0.01);
	----
end

function ObliterationTower:OnCreated()
	self.ability = AddAbility(self.tower, "obliteration_tower_obliterate");
	self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));
	self.groundHeight = GetGroundPosition(self.tower:GetOrigin(), nil).z + 200;
	self.projectiles = {};

	self.projDuration = GetAbilitySpecialValue("obliteration_tower_obliterate", "duration");
	self.maxSplash = GetAbilitySpecialValue("obliteration_tower_obliterate", "max_aoe");
end

function ObliterationTower:OnDestroyed()
	for id,_ in pairs(self.projectiles) do
		UTIL_RemoveImmediate(EntIndexToHScript(id));
	end
end

function ObliterationTower:OnAttackLanded(keys) end
RegisterTowerClass(ObliterationTower, ObliterationTower.className);