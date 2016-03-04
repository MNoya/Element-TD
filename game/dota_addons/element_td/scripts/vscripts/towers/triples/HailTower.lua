-- Hail (Darkness + Light + Water)
-- This is a long range single target tower. It can automatically activate an ability periodically that gives it multi-shoot. 
--This allows it to attack up to three targets at once doing full damage to each. 
-- Ability lasts a few seconds, and has a few second cooldown. Autocast can be toggled to prevent inopportune casting.

HailTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HailTower"
    },
nil)

function HailTower:OnStormThink()
    if not self.tower:HasModifier("modifier_disarmed") then
        if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() and self.tower:GetHealthPercent() == 100 and #GetCreepsInArea(self.tower:GetAbsOrigin(), self.findRadius) > 0 then
            self.tower:CastAbilityImmediately(self.ability, 1)
        end
    end
end

function HailTower:OnAttack(keys)
    local target = keys.target
    local caster = keys.caster
    if self.tower:HasModifier("modifier_storm") then
        local targets = 0
        local creeps = GetCreepsInArea(target:GetAbsOrigin(), 350)
        for _, creep in pairs(creeps) do
            if creep:IsAlive() and creep:entindex() ~= target:entindex() then
                targets = targets + 1
                local info = 
                {
                    Target = creep,
                    Source = caster,
                    Ability = keys.ability,
                    EffectName = "particles/custom/towers/hail/attack.vpcf",
                    iMoveSpeed = self.tower:GetProjectileSpeed(),
                    vSourceLoc= caster:GetAbsOrigin(),
                    bReplaceExisting = false,
                    flExpireTime = GameRules:GetGameTime() + 10,
                }
                projectile = ProjectileManager:CreateTrackingProjectile(info)

                if targets == self.bonusTargets then
                    break
                end
            end
        end
    end
end

function HailTower:OnProjectileHit(keys)
    self:OnAttackLanded({target = keys.target})
end

function HailTower:OnStormCast(keys)
    self.tower:EmitSound("Hail.Cast")
    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_storm", {duration=self.duration})
end

function HailTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
end

function HailTower:ApplyUpgradeData(data)
    if data.cooldown and data.cooldown > 1 then
        self.ability:StartCooldown(data.cooldown)
    end
    if data.autocast == false then
        self.ability:ToggleAutoCast()
    end
end

function HailTower:GetUpgradeData()
    return {
        cooldown = self.ability:GetCooldownTimeRemaining(), 
        autocast = self.ability:GetAutoCastState()
    }
end

function HailTower:OnCreated()
    self.ability = AddAbility(self.tower, "hail_tower_storm")
    Timers:CreateTimer(0.1, function()
        if IsValidEntity(self.tower) then
            self:OnStormThink()
            return 0.1
        end
    end)
    self.ability:ToggleAutoCast()
    self.duration = self.ability:GetSpecialValueFor("duration")
    self.projectileSpeed = tonumber(GetUnitKeyValue(self.towerClass, "ProjectileSpeed"))
    self.attackOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))
    self.bonusTargets = GetAbilitySpecialValue("hail_tower_storm", "targets") - 1
    self.findRadius = self.tower:GetAttackRange() + self.tower:GetHullRadius()
end

RegisterTowerClass(HailTower, HailTower.className)