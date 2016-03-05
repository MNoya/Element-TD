-- Enchantment Tower (Earth + Light + Nature)
-- This is a support tower. It has a splash attack. It has an autocast single target ability that buffs creeps. 
-- Buff increases damage taken by X%. Buff lasts X seconds. Buff does not stack.

EnchantmentTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "EnchantmentTower"
    },
nil)

function EnchantmentTower:FaerieFireThink()
    if self.ability:IsFullyCastable() and self.tower:GetHealthPercent() == 100 and self.ability:GetAutoCastState() then
        local creeps = GetCreepsInArea(self.tower:GetAbsOrigin(), self.range)
        local highestHealth = 0
        local theChosenOne = nil

        for _, creep in pairs(creeps) do
            if creep:IsAlive() and not creep:HasModifier("modifier_faerie_fire") and creep:GetHealth() > highestHealth then
                highesthealth = creep:GetHealth()
                theChosenOne = creep
            end
        end

        if theChosenOne then
            self.tower:CastAbilityOnTarget(theChosenOne, self.ability, 1)
        end
    end
end

function EnchantmentTower:OnFaerieFireCast(keys)
    local target = keys.target

    self.ability:ApplyDataDrivenModifier(self.tower, target, "modifier_faerie_fire", {})
    local modifier = target:FindModifierByName("modifier_faerie_fire")
    if modifier then
        modifier.findRadius = self.findRadius
        modifier.maxAmp = self.maxAmp 
        modifier.baseAmp = self.baseAmp
    end
    
    local playerID = self.tower:GetPlayerOwnerID()
    Sounds:EmitSoundOnClient(playerID, "Enchantment.Cast")

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return_thin.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, self.attackLoc)
    ParticleManager:SetParticleControl(particle, 1, target:GetOrigin())

    -- No cooldown sandbox option
    if GetPlayerData(self.tower:GetPlayerOwnerID()).noCD then
        self.ability:EndCooldown()
    end
end

function EnchantmentTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntitiesInArea(target:GetAbsOrigin(), self.fullAOE, self.tower, damage / 2)  
    DamageEntitiesInArea(target:GetAbsOrigin(), self.halfAOE, self.tower, damage / 2)
end

function EnchantmentTower:OnCreated()
    self.modifierName = "modifier_faerie_fire"

    self.attackLoc = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_hitloc"))
    self.range = tonumber(GetAbilityKeyValue("enchantment_tower_faerie_fire", "AbilityCastRange"))

    self.ability = AddAbility(self.tower, "enchantment_tower_faerie_fire", self.tower:GetLevel())
    Timers:CreateTimer(0.1, function()
        if IsValidEntity(self.tower) then
            self:FaerieFireThink()
            return 0.1
        end
    end)
    self.ability:ToggleAutoCast()

    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))

    self.findRadius = self.ability:GetLevelSpecialValueFor("amp_find_radius", self.ability:GetLevel()-1)
    self.maxAmp = self.ability:GetLevelSpecialValueFor("max_damage_amp", self.ability:GetLevel()-1)
    self.baseAmp = self.ability:GetLevelSpecialValueFor("base_damage_amp", self.ability:GetLevel()-1)
end

function EnchantmentTower:OnDestroyed() end

RegisterTowerClass(EnchantmentTower, EnchantmentTower.className)