-- Gold Tower (Fire + Earth + Light)
-- each kill gives bonus gold

GoldTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "GoldTower";
	},
nil);

function GoldTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
	DamageEntity(target, self.tower, damage);
end

function GoldTower:ModifyGold(gold)
	return math.floor(gold + (gold * (self.bonusGold / 100)) + 0.5);
end

function GoldTower:GetAttackOrigin()
	return self.attackOrigin;
end

function GoldTower:OnCreated()
	self.ability = AddAbility(self.tower, "gold_tower_arbitrage", self.tower:GetLevel());
	self.bonusGold = GetAbilitySpecialValue("gold_tower_arbitrage", "bonus_gold")[self.tower:GetLevel()];
	self.attackOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));
end

RegisterTowerClass(GoldTower, GoldTower.className);