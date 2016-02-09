-- Gold Tower (Fire + Earth + Light)
-- each kill gives bonus gold

GoldTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "GoldTower"
    },
nil)

function GoldTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function GoldTower:ModifyGold(gold)
    return math.floor(gold + (gold * (self.bonusGold / 100)) + 0.5)
end

function GoldTower:OnCreated()
    self.ability = AddAbility(self.tower, "gold_tower_arbitrage", self.tower:GetLevel())
    self.bonusGold = GetAbilitySpecialValue("gold_tower_arbitrage", "bonus_gold")[self.tower:GetLevel()]
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})
end

RegisterTowerClass(GoldTower, GoldTower.className)