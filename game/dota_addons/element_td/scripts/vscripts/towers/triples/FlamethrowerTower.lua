-- Flamethrower (Dark + Earth + Fire)
-- This tower has a splash damage attack that puts a buff on each creep hit. This buff lasts forever. 
-- When a creep with this buff dies, it does X*(Number of Stacks) damage in an area around it. Buff stacks indefinitely.

FlamethrowerTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "FlamethrowerTower"
    },
nil)

function FlamethrowerTower:OnNapalmCreepDied(keys)
    local unit = keys.unit
    local creeps = GetCreepsInArea(unit:GetOrigin(), self.napalmAOE)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak_explosion.vpcf", PATTACH_ABSORIGIN, self.tower)
    ParticleManager:SetParticleControl(particle, 0, Vector(0, 0, 0))
    ParticleManager:SetParticleControl(particle, 3, unit:GetOrigin())

    for _,creep in pairs(creeps) do
        DamageEntity(creep, self.tower, unit.napalmDamage) 
    end
end

function FlamethrowerTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetBaseDamageMax(), self.tower)
    local creepsHalf = GetCreepsInArea(target:GetOrigin(), self.aoeHalf)
    
    for _,creep in pairs(creepsHalf) do 
        DamageEntity(creep, self.tower, damage / 2) 
        self.ability:ApplyDataDrivenModifier(self.tower, creep, "modifier_napalm", {})

        if not creep.napalmDamage then
            creep.napalmDamage = self.napalmDamage
            creep.napalmStacks = 1
        else
            if self.tower:GetLevel() == 2 then
                creep.napalmDamage = creep.napalmDamage + (self.napalmDamage * 5)
                creep.napalmStacks = creep.napalmStacks + 5
            else
                creep.napalmDamage = creep.napalmDamage + self.napalmDamage
                creep.napalmStacks = creep.napalmStacks + 1
            end
        end

        creep:SetModifierStackCount("modifier_napalm", self.ability, creep.napalmStacks)
    end

    DamageEntitiesInArea(target:GetOrigin(), self.aoeFull, self.tower, damage / 2)
end

function FlamethrowerTower:OnCreated()
    self.ability = AddAbility(self.tower, "flamethrower_tower_napalm", self.tower:GetLevel())
    self.napalmDamage = GetAbilitySpecialValue("flamethrower_tower_napalm", "damage")[self.tower:GetLevel()]
    self.napalmAOE = GetAbilitySpecialValue("flamethrower_tower_napalm", "aoe")
    self.aoeHalf = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.aoeFull = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.attackOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"))
end

RegisterTowerClass(FlamethrowerTower, FlamethrowerTower.className)