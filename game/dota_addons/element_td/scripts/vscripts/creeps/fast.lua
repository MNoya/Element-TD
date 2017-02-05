-- Fast Creep class
CreepFast = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
            self.creep = creep;
            self.creepClass = creepClass or self.creepClass
        end
	},
	{
		className = "CreepFast"
	},
CreepBasic);

-- Datadriven version because who needs wrappers anyway
function CastHasteSpell(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("creep_ability_fast") or caster:FindAbilityByName("creep_ability_fast_perma") or caster:FindAbilityByName("creep_ability_fast_super")
	if ability and caster:IsAlive() then
		caster:AddNewModifier(caster,ability,"creep_haste_modifier",{duration=ability:GetSpecialValueFor("duration")})
		ability:ApplyDataDrivenModifier(caster,caster,"creep_haste_delay",{duration=ability:GetSpecialValueFor("duration")})
	end
end


RegisterCreepClass(CreepFast, CreepFast.className);