if not CREEP_CLASSES then
	CREEP_CLASSES = {}
end

function RegisterCreepClass(class, name)
	if class and name then
		CREEP_CLASSES[name] = class
	elseif not class then
		Log:warn("Class " .. name .. " cannot be nil")
	elseif not name then
		Log:warn("Class name cannot be nil")
	end
end

-- Basic Creep class
CreepBasic = createClass({
		creep = nil,
		creepClass = "",

		constructor = function(self, creep, creepClass)
            self.creep = creep
            self.creepClass = creepClass or self.creepClass
        end
	},
	{
		className = "CreepBasic"
	},
nil)

function CreepBasic:OnSpawned()
end

function CreepBasic:OnDeath() 
end

RegisterCreepClass(CreepBasic, CreepBasic.className)