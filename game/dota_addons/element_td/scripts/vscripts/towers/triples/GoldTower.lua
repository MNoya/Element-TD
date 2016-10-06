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

function GoldTower:OnAbilityToggle(keys)
    if self.tower:IsAlive() then
        self.tower.toggled = not self.tower.toggled
    end

    if self.tower:HasModifier("modifier_attack_targeting") then
        self.tower:RemoveModifierByName("modifier_attack_targeting")
    end

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {
        target_type = tonumber(keys.target_type), 
        keep_target = tonumber(keys.keep_target)
    })
end


function GoldTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage(target)
    DamageEntity(target, self.tower, damage)
end

function GoldTower:ModifyGold(gold)
    local bonus = math.floor((gold * (self.bonusGold / 100)) + 0.5)

    if bonus > 0 then
        self.tower.gold_counter = self.tower.gold_counter + bonus
        if not self.tower:HasModifier("modifier_gold_tower_counter") then
            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_gold_tower_counter", {})
        end

        self.tower:SetModifierStackCount("modifier_gold_tower_counter", self.tower, self.tower.gold_counter)
    end

    return gold + bonus
end


function GoldTower:GetUpgradeData()
    return { 
        gold_counter = self.tower.gold_counter,
        toggle = self.tower.toggled
    }
end

function GoldTower:ApplyUpgradeData(data)
    if data.gold_counter and data.gold_counter > 0 then
        self.tower.gold_counter = data.gold_counter
        self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_gold_tower_counter", {})
        self.tower:SetModifierStackCount("modifier_gold_tower_counter", self.tower, self.tower.gold_counter) 
    end

    if data.toggle then
        self.tower.toggled = true
        self.ability:ToggleAbility()
    end
end

function GoldTower:OnCreated()
    self.ability = AddAbility(self.tower, "gold_tower_arbitrage", self.tower:GetLevel())
    self.bonusGold = GetAbilitySpecialValue("gold_tower_arbitrage", "bonus_gold")[self.tower:GetLevel()]

    self:OnAbilityToggle({target_type = TOWER_TARGETING_LOWEST_HP}) -- set default targeting mode
    self.tower.toggled = false
    self.tower.gold_counter = 0
end

RegisterTowerClass(GoldTower, GoldTower.className)