-- Hail (Darkness + Light + Water)
-- This is a long range single target tower. It can automatically activate an ability periodically that gives it multi-shoot. 
--This allows it to attack up to three targets at once doing full damage to each. 
-- Ability lasts a few seconds, and has a few second cooldown. Autocast can be toggled to prevent inopportune casting.

HailTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
    },
    {
        className = "HailTower";
    },
nil);

function HailTower:OnStormThink()
    if not self.tower:HasModifier("modifier_disarmed") then
        if self.ability:IsFullyCastable() and self.ability:GetAutoCastState() and #GetCreepsInArea(self.tower:GetOrigin(), self.tower:GetAttackRange()) > 0 then
            self.tower:CastAbilityImmediately(self.ability, 1);
        end
    end
end

function HailTower:OnAttackStart(keys)
    local target = keys.target;
    local creeps = GetCreepsInArea(target:GetOrigin(), 350);
    if self.tower:HasModifier("modifier_storm") then
        local targets = 0;
        for _, creep in pairs(creeps) do
            if creep:IsAlive() and creep:entindex() ~= target:entindex() then
                self.tower:PerformAttack(creep, false, false, true, true);

                local distance = (creep:GetOrigin() - self.attackOrigin):Length()
                local time = distance / self.projectileSpeed;
                Timers:CreateTimer(DoUniqueString("HailTowerDelay" .. creep:entindex()), {
                    endTime = time - 0.1,
                    callback = function()
                        self:OnAttackLanded({target_entities = {[1] = creep}});
                    end
                });

                targets = targets + 1;
                if targets == self.bonusTargets then
                    break;
                end
            end
        end
    end
end

function HailTower:OnStormCast(keys)
    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_storm", {});
end

function HailTower:OnAttackLanded(keys)
    local target = keys.target;
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower);
    DamageEntity(target, self.tower, damage);
end

function HailTower:OnCreated()
    self.ability = AddAbility(self.tower, "hail_tower_storm");
    self.ability:SetContextThink("StormThink", function()
        self:OnStormThink();
        return 1;
    end, 1);
    self.ability:ToggleAutoCast();
    self.projectileSpeed = tonumber(GetUnitKeyValue(self.towerClass, "ProjectileSpeed"));
    self.attackOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));
    self.bonusTargets = GetAbilitySpecialValue("hail_tower_storm", "targets") - 1;
end

RegisterTowerClass(HailTower, HailTower.className);