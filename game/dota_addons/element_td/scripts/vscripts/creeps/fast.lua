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

function CreepFast:CastHasteSpell(keys)
	local status, err = pcall(function()
		local creep = keys.caster;
		if creep then
			local ability = creep:FindAbilityByName("creep_ability_fast");
			creep:CastAbilityImmediately(ability, 1);
		end
	end);
	if not status then
		Log:error(err);
	end
end

-- Datadriven version because who needs wrappers anyway
function CastHasteSpell(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("creep_ability_fast")
	if ability and caster:IsAlive() then
		caster:CastAbilityImmediately(ability, 1)
	end
end


RegisterCreepClass(CreepFast, CreepFast.className);