-- Well Tower class (Nature + Water)
-- This is a support tower. It has an autocast ability which increases the speed (by a percentage) of non-support towers (this distinction is important). 
-- Autocast prefers targets with higher value (i.e. more powerful towers first).
WellTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "WellTower"
	},
nil);

-- the thinker function for the well_tower_spring_forward spell
function WellTower:SpringForwardThink()
	if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
		-- let's find a target to autocast on
		local towers = Entities:FindAllByClassnameWithin("npc_dota_tower", self.tower:GetOrigin(), self.ability:GetCastRange());
		local highestDamage = 0;
		local theChosenOne = nil;

		-- find out the tower with the highest damage. Is this a bad choosing algorithm?
		for _, tower in pairs(towers) do
			if IsTower(tower) and tower:GetOwner():GetPlayerID() == self.playerID and not IsSupportTower(tower) then
				if not tower:HasModifier("modifier_spring_forward") and tower:GetBaseDamageMax() >= highestDamage then
					highestDamage = tower:GetBaseDamageMax();
					theChosenOne = tower;
				end
			end
		end

		if theChosenOne then
			self.tower:CastAbilityOnTarget(theChosenOne, self.ability, 1);
		end
	end
end

-- called when the Spring Forward ability is cast
function WellTower:OnSpringForwardCast(keys)
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

	-- create the applier method
	target:RemoveModifierByName("modifier_spring_forward");
	self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_spring_forward", {}); 
end

function WellTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetBaseDamageMax();
	DamageEntity(target, self.tower, damage);
end

function WellTower:OnCreated()
	self.ability = AddAbility(self.tower, "well_tower_spring_forward", GetUnitKeyValue(self.towerClass, "Level"));
	self.ability:SetContextThink("SpringForwardThink", (function()
		self:SpringForwardThink();
		return 1;
	end), 1);
	self.ability:ToggleAutoCast();
	self.playerID = self.tower:GetOwner():GetPlayerID();
end

function WellTower:ApplyUpgradeData(data)
	if data.cooldown and data.cooldown > 1 then
		self.ability:StartCooldown(data.cooldown);
	end
end

function WellTower:GetUpgradeData()
	return {
		cooldown = self.ability:GetCooldownTimeRemaining(), 
		autocast = self.ability:GetAutoCastState()
	};
end

RegisterTowerClass(WellTower, WellTower.className);