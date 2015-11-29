-- Flame Tower class (Nature + Fire)
-- This tower's attack puts a buff on the target. The buff lasts a few seconds. 
-- The buff does damage each second to the creep but also in an area of effect around the creep. Buff stacks indefinitely. 
FlameTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "FlameTower"
	},
nil);

function FlameTower:DealBurnDamage(keys)
	local target = keys.target;
	local damage = ApplyAbilityDamageFromModifiers(self.burnDamage[self.level], self.tower);
	DamageEntitiesInArea(target:GetOrigin(), self.burnAOE, self.tower, damage);
	--print("Sunburn damage tick: " .. GameRules:GetGameTime());
end

function FlameTower:OnCreated()
	self.level = GetUnitKeyValue(self.towerClass, "Level");
	AddAbility(self.tower, "flame_tower_sunburn", self.level);
	self.burnDamage = GetAbilitySpecialValue("flame_tower_sunburn", "damage");
	self.burnAOE = GetAbilitySpecialValue("flame_tower_sunburn", "aoe");
	self.sunburnDuration = GetAbilitySpecialValue("flame_tower_sunburn", "duration");
end

function FlameTower:OnAttackLanded(keys) 
	local target = keys.target;
	local damage = ApplyAbilityDamageFromModifiers(self.burnDamage[self.level], self.tower);
	DamageEntitiesInArea(target:GetOrigin(), self.burnAOE, self.tower, damage);
	
	if not target.SunburnData then
		target.SunburnData = {
			Stacks = {},
			StackCount = 0,
			AOE = self.burnAOE,
		};
	end
	
	local stackID = DoUniqueString("SunburnStack");

	target.SunburnData.Stacks[stackID] = {
		startTime = GameRules:GetGameTime(),
		duration = self.sunburnDuration,
		damage = damage,
		source = self.tower
	};
	target.SunburnData.StackCount = target.SunburnData.StackCount + 1;

	CreateTimer(stackID .. "Timer", DURATION, {
		duration = self.sunburnDuration,

		callback = function(timer) 
			if IsValidEntity(target) and target.SunburnData then
				target.SunburnData.Stacks[stackID] = nil;
				target.SunburnData.StackCount = target.SunburnData.StackCount - 1;
			end
		end

	});
end

function CreateSunburnRemnant(entity, team)
	local remnant = CreateUnitByName("tower_dummy", entity:GetAbsOrigin() + Vector(0, 0, 64), false, nil, nil, team);
	remnant:SetAbsOrigin(entity:GetAbsOrigin() + Vector(0, 0, 64));
	ApplyDummyPassive(remnant);

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameGuard_column.vpcf", PATTACH_ABSORIGIN, remnant);
    ParticleManager:SetParticleControl(particle, 0, remnant:GetAbsOrigin());
    ParticleManager:SetParticleControl(particle, 1, remnant:GetAbsOrigin());
    ParticleManager:SetParticleControl(particle, 2, Vector(0, 0, 0));
    ParticleManager:SetParticleControl(particle, 3, Vector(0, 0, 0));
    ParticleManager:SetParticleControl(particle, 4, Vector(0, 0, 0));

	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameGuard_fire_outer.vpcf", PATTACH_ABSORIGIN, remnant);
    ParticleManager:SetParticleControl(particle2, 0, Vector(0, 0, 0));
    ParticleManager:SetParticleControl(particle2, 1, remnant:GetAbsOrigin());
    ParticleManager:SetParticleControl(particle2, 2, Vector(0, 0, 0));

    local stacks = 0;
    local remnantDuration = 0;

    for k, v in pairs(entity.SunburnData.Stacks) do
    	local diff = v.duration - (GameRules:GetGameTime() - v.startTime)
    	if diff > 1 and IsValidEntity(v.source) then
    		local timeRemaining = math.floor(diff + 0.5);
    		if timeRemaining > remnantDuration then
    			remnantDuration = timeRemaining;
    		end
    		local ticks = timeRemaining;

    		remnant:SetContextThink(k, function()
				DamageEntitiesInArea(remnant:GetOrigin(), entity.SunburnData.AOE, v.source, v.damage);
    			ticks = ticks - 1;
    			if ticks == 0 then
    				return nil;
    			end
    			return 1;
    		end, 1);

    		stacks = stacks + 1;
    	end
    end

    if stacks == 0 then
    	ParticleManager:DestroyParticle(particle, true);
    	ParticleManager:DestroyParticle(particle2, true);
    	UTIL_RemoveImmediate(remnant);
    	return;
    end

    remnant:SetContextThink("SunburnRemnantLifetime", function()
    	ParticleManager:DestroyParticle(particle, false);
    	ParticleManager:DestroyParticle(particle2, false);
    	UTIL_RemoveImmediate(remnant);
    	return nil;
    end, remnantDuration);
end

RegisterTowerClass(FlameTower, FlameTower.className);