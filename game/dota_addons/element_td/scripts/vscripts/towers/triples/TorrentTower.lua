-- Torrent (Light + Nature + Water)
-- This is a single target tower. It has an ability that charges up every X attacks. Ability maxes out at level 10. 
-- Ability does damage in an area of effect around the tower. Ability is autocast that fires at level 10 but can be toggled off. 
-- Ability resets back to level 1 after being used.

TorrentTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "TorrentTower"
    },
nil)

function TorrentTower:ResetDamage(keys)
    if self.resetTimer then
        Timers:RemoveTimer(self.resetTimer)
    end
    self.tidalStacks = 0
    self.tower:RemoveModifierByName("modifier_tidal_splash_decay")
end

function TorrentTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetAverageTrueAttackDamage(), self.tower)

    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE - (self.tidalStacks * self.aoeDecay), self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE - (self.tidalStacks * (self.aoeDecay/2)), self.tower, damage / 2)

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_tidal_splash_decay", {})

    if self.tidalStacks < 20 then
        self.tidalStacks = self.tidalStacks + 1
        self.tower:SetModifierStackCount("modifier_tidal_splash_decay", self.ability, self.tidalStacks)
    end

    if self.resetTimer ~= nil then
        Timers:RemoveTimer(self.resetTimer)
    end
    self.resetTimer = Timers:CreateTimer(self.resetTime, function()
        self:ResetDamage({})
    end)
end

function TorrentTower:OnCreated()
    self.ability = AddAbility(self.tower, "tidal_tower_splash_decay", self.tower:GetLevel())
    self.aoeDecay = GetAbilitySpecialValue("tidal_tower_splash_decay", "aoe")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.douseDamage = GetAbilitySpecialValue("tidal_tower_splash_decay", "damage")
    self.resetTime = GetAbilitySpecialValue("tidal_tower_splash_decay", "reset_time")
    self.tidalStacks = 0
    self.resetTimer = nil
end

RegisterTowerClass(TorrentTower, TorrentTower.className)