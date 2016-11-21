-- Magic Tower class (Fire + Dark)
--  Every attack adds 20 range. Max of 30 stacks (+600 range). Resets on 2 seconds of no attack

MagicTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower    
            self.towerClass = towerClass or self.towerClass    
        end
    },
    {
        className = "MagicTower"
    },
nil)

function MagicTower:OnAttack(event)
    local tower = self.tower
    local ability = self.ability
    local modifierName = "modifier_magic_tower_attack_range"

    -- Applying refreshes the modifier
    ability:ApplyDataDrivenModifier(tower, tower, modifierName, {duration=self.duration})

    local stackCount = tower:GetModifierStackCount(modifierName, tower) or 0
    stackCount = stackCount == self.maxStacks and self.maxStacks or (stackCount + 1)

    tower:SetModifierStackCount(modifierName, tower, stackCount)
end

function MagicTower:OnAttackLanded(keys)
    local target = keys.target
	local damage = self.tower:GetAverageTrueAttackDamage(target)
	DamageEntitiesInArea(target:GetOrigin(), self.halfAOE, self.tower, damage / 2);
	DamageEntitiesInArea(target:GetOrigin(), self.fullAOE, self.tower, damage / 2);


		local particle = ParticleManager:CreateParticle("particles/custom/towers/magic/impactedict.vpcf", PATTACH_CUSTOMORIGIN, target)
		local origin = target:GetAbsOrigin()
		origin.z = origin.z + 64
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, origin)
		ParticleManager:SetParticleControl(particle, 2, origin)
	    ParticleManager:ReleaseParticleIndex(particle)


    -- Refresh selection
    if PlayerResource:IsUnitSelected(self.playerID, self.tower) then
        local stacks = self.tower:GetModifierStackCount("modifier_magic_tower_attack_range", self.tower)
        if stacks ~= self.maxStacks then
            PlayerResource:RefreshSelection()
        end
    end
end

function OnMagicRangeDestroy(event)
    local tower = event.target
    if PlayerResource:IsUnitSelected(tower:GetPlayerOwnerID(), tower) then
        PlayerResource:RefreshSelection()
    end
end

function MagicTower:OnCreated()
	self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"));
	self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"));
    self.ability = AddAbility(self.tower, "magic_tower_range") 
    self.rangeStacks = 0
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")
    self.duration = self.ability:GetSpecialValueFor("duration")
    self.playerID = self.tower:GetPlayerOwnerID()
end

RegisterTowerClass(MagicTower, MagicTower.className)    