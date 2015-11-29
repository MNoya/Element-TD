-- Haste (Earth + Fire + Water)
-- Each time this tower attacks it gains X% attack speed. Speed bonus caps out after X attacks. 
-- Speed bonus resets after X seconds of not attacking.
HasteTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "HasteTower";
	},
nil);

function HasteTower:ResetAttackSpeed()
	for i = 1, self.wrathStacks, 1 do
		self.tower:RemoveModifierByName("modifier_wrath");
	end
	self.wrathStacks = 0;
	self.tower:RemoveModifierByName("modifier_wrath_indicator");
end

function HasteTower:OnAttackStart(keys)
	if self.wrathStacks < self.wrathCap then
		self.wrathStacks = self.wrathStacks + 1;
		self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_wrath", {});
	end

	if self.wrathStacks == 1 then
		self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_wrath_indicator", {});
	end

	self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_wrath_reset", {});
	self.tower:SetModifierStackCount("modifier_wrath_indicator", self.ability, self.wrathStacks);

	DeleteTimer(self.timerName);
	CreateTimer(self.timerName, DURATION, {
		duration = self.resetTime,
		callback = function(timer)
			self:ResetAttackSpeed();
		end
	});
end

function HasteTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
	DamageEntity(target, self.tower, damage);
end

function HasteTower:OnCreated()
	self.ability = AddAbility(self.tower, "haste_tower_wrath");
	self.wrathCap = GetAbilitySpecialValue("haste_tower_wrath", "cap");
	self.resetTime = GetAbilitySpecialValue("haste_tower_wrath", "reset_time");
	self.wrathStacks = 0;
	self.timerName = "HasteResetSpeed" .. self.tower:entindex();
end

RegisterTowerClass(HasteTower, HasteTower.className);