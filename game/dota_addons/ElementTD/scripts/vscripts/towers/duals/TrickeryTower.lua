-- Trickery Tower (Light + Dark)

TrickeryTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "TrickeryTower"
	},
nil);

function TrickeryTower:ConjureThink()
	if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
		-- let's find a target to autocast on
		local towers = Entities:FindAllByClassnameWithin("npc_dota_tower", self.tower:GetOrigin(), self.ability:GetCastRange());
		local highestDamage = 0;
		local theChosenOne = nil;

		-- find out the tower with the highest damage. Is this a bad choosing algorithm?
		for _, tower in pairs(towers) do
			if IsTower(tower) and tower:GetOwner():GetPlayerID() == self.playerID and not IsSupportTower(tower) and tower:GetHealth() == tower:GetMaxHealth() then
				if not tower:HasModifier("modifier_clone") and not tower:HasModifier("modifier_conjure_prevent_cloning") and tower:GetBaseDamageMax() >= highestDamage then
					highestDamage = tower:GetBaseDamageMax();
					theChosenOne = tower;
				end
			end
		end

		if theChosenOne then
			self.tower:CastAbilityOnTarget(theChosenOne, self.ability, self.playerID);
		end
	end
end

function TrickeryTower:CreateClone(target)
	local sector = self.playerID + 1;
	local clonePos = FindClosestTowerPosition(sector, target:GetOrigin(), 10000);
	local clone = CreateUnitByName(target.class, clonePos, false, nil, nil, target:GetTeam());
	local playerData = GetPlayerData(self.playerID);

	self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_conjure_prevent_cloning", {}); 

	RemoveTowerPosition(sector, clonePos);

	--set some variables
	clone.class = target.class;
	clone.element = GetUnitKeyValue(clone.class, "Element");
	clone.damageType = GetUnitKeyValue(clone.class, "DamageType");
	clone.isClone = true;
	clone.creatorClass = self;
	clone:SetRenderColor(0, 148, 255);

	clone:SetOwner(PlayerResource:GetPlayer(self.playerID):GetAssignedHero());
	clone:SetControllableByPlayer(self.playerID, true);

	-- create a script object for this tower
    local scriptClassName = GetUnitKeyValue(clone.class, "ScriptClass");
    if not scriptClassName then scriptClassName = "BasicTower"; end
    if TOWER_CLASSES[scriptClassName] then
	    local scriptObject = TOWER_CLASSES[scriptClassName](clone, clone.class);
	    clone.scriptClass = scriptClassName;
	    clone.scriptObject = scriptObject;
	    clone.scriptObject:OnCreated();
	else
	   	Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. clone.class);
   	end


	AddAbility(clone, "sell_tower_0");
	AddAbility(clone, clone.damageType .. "_passive");
	if GetUnitKeyValue(clone.class, "AOE_Full") and GetUnitKeyValue(clone.class, "AOE_Half") then
		AddAbility(clone, "splash_damage_orb");
	end

	--register this clone with the player
	GetPlayerData(self.playerID).towers[clone:entindex()] = clone.class;
	CreateDataForTower(clone, clone.class);
	if not playerData.clones[clone.class] then
		playerData.clones[clone.class] = {};
	end
	playerData.clones[clone.class][clone:entindex()] = clone:entindex();

	--do modifiers
	clone:RemoveModifierByName("modifier_tower_truesight_aura");
	clone:RemoveModifierByName("modifier_invulnerable");
	clone:AddNewModifier(nil, nil, "modifier_invulnerable", {});
	clone:AddNewModifier(nil, nil, "modifier_magic_immune", {});

	--set the tower's health to its damage
	if clone:GetBaseDamageMax() <= 0 then
        clone:SetMaxHealth(100);
    else
		clone:SetMaxHealth(clone:GetBaseDamageMax());
	end
    clone:SetHealth(clone:GetMaxHealth());

    -- apply the clone modifier to the clone
    self.ability:ApplyDataDrivenModifier(self.tower, clone, "modifier_clone", {});
	self.clones[clone:entindex()] = 1;

	local particle = ParticleManager:CreateParticle("particles/generic_gameplay/illusion_created.vpcf", PATTACH_ABSORIGIN, clone);
    ParticleManager:SetParticleControl(particle, 0, clone:GetAbsOrigin() + Vector(0, 0, 64));
end

function TrickeryTower:OnCloneExpire(keys)
	local clone = keys.target;
	local playerData = GetPlayerData(self.playerID);
	
	CreateIllusionKilledParticles(clone);
    if clone.scriptObject["OnDestroyed"] then
		clone.scriptObject:OnDestroyed();
	end

	GetPlayerData(self.playerID).towers[clone:entindex()] = nil; -- remove this tower index from the player's tower list
	AddTowerPosition(self.playerID + 1, clone:GetOrigin()); -- re-add this position to the list of valid locations
	playerData.clones[clone.class][clone:entindex()] = nil;
	self.clones[clone:entindex()] = nil;
    UTIL_RemoveImmediate(clone);
end

function TrickeryTower:OnConjureCast(keys)
	-- this spell doesn't actually apply the modifier itself because we need to validate the target first
	local target = keys.target;
	local playerID = self.tower:GetOwner():GetPlayerID();

	if not IsTower(target) then
		self.ability:EndCooldown();
		ShowWarnMessage(playerID, "Ability can only target towers!");
		return;
	end

	if target:GetOwner():GetPlayerID() ~= self.playerID then
		self.ability:EndCooldown();
		ShowWarnMessage(playerID, "Ability can only target your own towers!");
		return;
	end

	if IsSupportTower(target) then
		self.ability:EndCooldown();
		ShowWarnMessage(playerID, "Ability can't target support towers!");
		return;
	end

	if target:HasModifier("modifier_conjure_prevent_cloning") then
		self.ability:EndCooldown();
		ShowWarnMessage(playerID, "That tower has been recently cloned!");
		return;
	end

	if target.isClone then
		self.ability:EndCooldown();
		ShowWarnMessage(playerID, "You can't clone a clone!");
		return;
	end

	self:CreateClone(target);
end

function TrickeryTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	DamageEntity(target, self.tower, damage);
end

function TrickeryTower:OnCreated()
	self.ability = AddAbility(self.tower, "trickery_tower_conjure", self.tower:GetLevel());
	self.ability:SetContextThink("ConjureThink", (function()
		self:ConjureThink();
		return 1;
	end), 1);
	self.ability:ToggleAutoCast();
	self.playerID = self.tower:GetOwner():GetPlayerID();
	self.castRange = tonumber(GetAbilityKeyValue("trickery_tower_conjure", "AbilityCastRange"));
	self.clones = {};
end

function TrickeryTower:OnDestroyed()
	for k, v in pairs(self.clones) do
		self:OnCloneExpire({target = EntIndexToHScript(k)});
	end
end

function TrickeryTower:ApplyUpgradeData(data)
	if data.cooldown and data.cooldown > 1 then
		self.ability:StartCooldown(data.cooldown);
	end
end

function TrickeryTower:GetUpgradeData()
	return {
		cooldown = self.ability:GetCooldownTimeRemaining(), 
		autocast = self.ability:GetAutoCastState()
	};
end

function CreateIllusionKilledParticles(tower)
	local dummy = CreateUnitByName("conjure_tower_clone_dummy", tower:GetOrigin(), false, nil, nil, tower:GetTeam());
	local particleOrigin = tower:GetAbsOrigin();
	particleOrigin.z = particleOrigin.z + 75;
	dummy:SetAbsOrigin(particleOrigin);
	ApplyDummyPassive(dummy);
	
	local particle = ParticleManager:CreateParticle("particles/generic_gameplay/illusion_killed.vpcf", PATTACH_ABSORIGIN, dummy);
    ParticleManager:SetParticleControl(particle, 0, dummy:GetAbsOrigin());

    CreateTimer("DeleteCloneDummy"..dummy:entindex(), DURATION, {
    	duration = 2,
    	callback = function(t) 
    		UTIL_RemoveImmediate(dummy);
    	end
    });
end

RegisterTowerClass(TrickeryTower, TrickeryTower.className);