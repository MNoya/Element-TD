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

function TorrentTower:OnAttackStart(keys)
    self.attacks = self.attacks + 1
    if self.attacks == 10 then
        self.attacks = 0
        if self.ability:GetLevel() < 10 then
            self.ability:SetLevel(self.ability:GetLevel() + 1)
            self.tower:SetModifierStackCount("modifier_douse_passive", self.ability, self.ability:GetLevel())
        end
    end
    if self.ability:GetLevel() == 10 and self.ability:IsFullyCastable() and self.ability:GetAutoCastState() then
        self.ability:StartCooldown(5)
        self:OnDouseCast()
    end
end

function TorrentTower:OnDouseCast(keys)
    local creeps = GetCreepsInArea(self.tower:GetOrigin(), self.aoe)
    for _,creep in pairs(creeps) do
        if creep:IsAlive() then
            local player = PlayerResource:GetPlayer(self.tower:GetOwner():GetPlayerID())
            local particle = ParticleManager:CreateParticleForPlayer("particles/units/heroes/hero_kunkka/kunkka_spell_torrent_splash.vpcf", PATTACH_ABSORIGIN, self.tower, player)
            ParticleManager:SetParticleControl(particle, 0, GetGroundPosition(creep:GetAbsOrigin(), nil))
            ParticleManager:ReleaseParticleIndex(particle)
            DamageEntity(creep, self.tower, self.douseDamage[self.ability:GetLevel()])
        end
    end
    self.ability:SetLevel(0)
    self.tower:SetModifierStackCount("modifier_douse_passive", self.ability, 0)
end

function TorrentTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower)
    DamageEntity(target, self.tower, damage)
end

function TorrentTower:OnCreated()
    self.ability = AddAbility(self.tower, "torrent_tower_douse_" .. self.tower:GetLevel())
    self.ability:SetLevel(0)

    Timers:CreateTimer(1, function()
        if IsValidEntity(self.tower) then
            self.tower:SetModifierStackCount("modifier_douse_passive", self.ability, 0)
            return nil
        end
    end)

    self.ability:ToggleAutoCast()

    self.aoe = GetAbilitySpecialValue("torrent_tower_douse_" .. self.tower:GetLevel(), "aoe")
    self.douseDamage = GetAbilitySpecialValue("torrent_tower_douse_" .. self.tower:GetLevel(), "damage")
    self.attacks = 0
end

RegisterTowerClass(TorrentTower, TorrentTower.className)