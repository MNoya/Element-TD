-- Electricity Tower class (Fire + Light)
-- shoots chain lightning :D

ElectricityTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "ElectricityTower"
	},
nil);


function ElectricityTower:OnAttackStart(keys)
	self.dummy:CastAbilityOnTarget(keys.target, self.dummyAbility, 1);
	self.nextDamage = self.lightningDamage[self.ability:GetLevel()];
end

function ElectricityTower:OnCreated()
	self.ability = AddAbility(self.tower, "electricity_tower_arc_lightning_passive", tonumber(GetUnitKeyValue(self.tower.class, "Level")));

	local towerOrigin = self.tower:GetOrigin();
	local dummyOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));

	self.dummy = CreateUnitByName("tower_dummy", dummyOrigin, false, nil, nil, self.tower:GetTeam());
	self.dummy:SetAbsOrigin(dummyOrigin);
	self.dummy:SetOwner(self.tower:GetOwner());
	self.dummy:AddNewModifier(nil, nil, "modifier_invulnerable", {});
	self.dummy.dummyParent = self.tower;

	-- hopefully this works as intended
	self.dummy:AddNewModifier(self.dummy, nil, "modifier_out_of_world", {})

	self.dummyAbility = AddAbility(self.dummy, "electricity_tower_arc_lightning");
	self.lightningDamage = GetAbilitySpecialValue("electricity_tower_arc_lightning_passive", "damage");

end

-- called just before the tower is destroyed
function ElectricityTower:OnDestroyed()
	UTIL_RemoveImmediate(self.dummy);
end

function ElectricityTower:OnLightningHitEntity(entity)
	local damage = ApplyAbilityDamageFromModifiers(self.nextDamage, self.tower);
	DamageEntity(entity, self.tower, damage);
	self.nextDamage = self.nextDamage * 0.9;
end

function ElectricityTower:OnAttackLanded(keys) end
RegisterTowerClass(ElectricityTower, ElectricityTower.className);