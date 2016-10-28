-- Hydro Tower class (Water + Earth)
-- Single target tower that does 200/1000/5000 damage with 700 range and 1 attack speed.
-- Each attack has a 33% to mark the target with an effect. 1.5 seconds after being marked, the effect does 200/1000/5000 damage in 250 (full damage) AoE. 
-- Creep can be marked again if already marked. 

HydroTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "HydroTower"
    },
nil)

function HydroTower:OnAttackLanded(keys)
	local target = keys.target;
	local damage = self.tower:GetAverageTrueAttackDamage(target)
	DamageEntitiesInArea(target:GetOrigin(), self.aoe_half, self.tower, damage / 2);
	DamageEntitiesInArea(target:GetOrigin(), self.aoe_full, self.tower, damage / 2);
end

function HydroTower:CreepKilled(keys)
	local target = keys.unit
	if target:entindex() ~= self.tower:entindex() then
		self.tower:EmitSound("Hydro.Torrent")

		local torrent = ParticleManager:CreateParticle("particles/custom/towers/hydro/torrent_splash.vpcf", PATTACH_CUSTOMORIGIN, self.tower)
		ParticleManager:SetParticleControl(torrent, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(torrent, 1, target:GetAbsOrigin())
	end

	DamageEntitiesInArea(target:GetOrigin(), self.explosionAoE, self.tower, self.explosionDamage)
end

--[[ Removed in 1.15
function HydroTower:OnAttackLanded(keys)
    local caster = keys.caster
    local target = keys.target

    self.attacks = self.attacks + 1    
    if self.attacks == 3 then
        self.attacks = 0    
        self.ability:ApplyDataDrivenModifier(caster, target, "modifier_hydro_delay", {duration=self.delay})
    end

    -- The attack damage is applied a frame after, to ensure that the modifier triggers on death
    Timers:CreateTimer(function()
        local damage = self.tower:GetAverageTrueAttackDamage(target)
        DamageEntity(target, self.tower, damage)
    end)
end

function HydroTower:OnDelayEnd(keys)
    local target = keys.target
    local damage = ApplyAbilityDamageFromModifiers(self.splashDamage, self.tower)
    DamageEntitiesInArea(target:GetAbsOrigin(), self.splashAOE, self.tower, damage)

    self.tower:EmitSound("Hydro.Torrent")

    local torrent = ParticleManager:CreateParticle("particles/custom/towers/hydro/torrent_splash.vpcf", PATTACH_CUSTOMORIGIN, self.tower)
    ParticleManager:SetParticleControl(torrent, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(torrent, 1, target:GetAbsOrigin())
end
]]

function HydroTower:OnCreated()
    self.ability = AddAbility(self.tower, "hydro_tower_ability", self.tower:GetLevel())
    self.explosionDamage = self.ability:GetSpecialValueFor("damage");
    self.explosionAoE = self.ability:GetSpecialValueFor("aoe");
    self.aoe_full = self.ability:GetSpecialValueFor("aoe_full")
    self.aoe_half = self.ability:GetSpecialValueFor("aoe_half")
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_LOWEST_HP})

    --[[ Removed in 1.15
    self.attacks = 0
    self.splashDamage = self.ability:GetLevelSpecialValueFor("splash_damage", self.ability:GetLevel() - 1)
    self.splashAOE = GetAbilitySpecialValue("hydro_tower_ability", "splash_aoe")
    self.delay = GetAbilitySpecialValue("hydro_tower_ability", "delay")
	]]
end

RegisterTowerClass(HydroTower, HydroTower.className)