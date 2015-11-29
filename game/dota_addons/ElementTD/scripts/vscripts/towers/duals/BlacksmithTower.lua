-- Blacksmith Tower class (Fire + Earth)
-- This is a support tower. It has an autocast ability which increases the damage by a percentage of non-support towers. 
-- Damage increase applies to both attacks and abilities. Autocast prefers targets with higher value (i.e. more powerful towers first.
BlacksmithTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "BlacksmithTower"
	},
nil);

function BlacksmithTower:FireUpThink()
	if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
		-- let's find a target to autocast on
		local towers = Entities:FindAllByClassnameWithin("npc_dota_tower", self.tower:GetOrigin(), self.ability:GetCastRange());
		local highestDamage = 0;
		local theChosenOne = nil;

		-- find out the tower with the highest damage. Is this a bad choosing algorithm?
		for _, tower in pairs(towers) do
			if IsTower(tower) and tower:GetOwner():GetPlayerID() == self.playerID and not IsSupportTower(tower) then
				if tower:GetBaseDamageMax() >= highestDamage then
					if not HasAnyModifier(tower, {"modifier_fire_up_1", "modifier_fire_up_2", "modifier_fire_up_3"}) then
						highestDamage = tower:GetBaseDamageMax();
						theChosenOne = tower;
					end
				end
			end
		end

		if theChosenOne then
			self.tower:CastAbilityOnTarget(theChosenOne, self.ability, 1);
		end
	end
end

function BlacksmithTower:OnFireUpCast(keys)
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

	target:RemoveModifierByName("modifier_fire_up_1");
	target:RemoveModifierByName("modifier_fire_up_2");
	target:RemoveModifierByName("modifier_fire_up_3");
	self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_fire_up_" .. self.ability:GetLevel(), {});
end

function BlacksmithTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	DamageEntity(target, self.tower, damage);
end

function BlacksmithTower:OnCreated()
	self.ability = AddAbility(self.tower, "blacksmith_tower_fire_up", GetUnitKeyValue(self.towerClass, "Level"));
	self.ability:SetContextThink("FireUpThink", (function()
		self:FireUpThink();
		return 1;
	end), 1);
	self.ability:ToggleAutoCast();
	self.playerID = self.tower:GetOwner():GetPlayerID();
end

function BlacksmithTower:ApplyUpgradeData(data)
	if data.cooldown and data.cooldown > 1 then
		self.ability:StartCooldown(data.cooldown);
	end
end

function BlacksmithTower:GetUpgradeData()
	return {
		cooldown = self.ability:GetCooldownTimeRemaining(), 
		autocast = self.ability:GetAutoCastState()
	};
end

RegisterTowerClass(BlacksmithTower, BlacksmithTower.className);
RegisterModifier("modifier_fire_up_1", {
	bonus_damage_percent = 15,
	bonus_ability_damage_percent = 15
});
RegisterModifier("modifier_fire_up_2", {
	bonus_damage_percent = 30,
	bonus_ability_damage_percent = 30
});
RegisterModifier("modifier_fire_up_3", {
	bonus_damage_percent = 90,
	bonus_ability_damage_percent = 90
});