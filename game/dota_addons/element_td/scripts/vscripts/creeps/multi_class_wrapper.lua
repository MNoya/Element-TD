-- wrapper for script objects so that creeps can have multiple abilities

ClassWrapper = {}
ClassWrapper.__index = (function(tab, func_name)
	if ClassWrapper[func_name] ~= nil then
		return ClassWrapper[func_name]
	end

	if tab.cached_functions[func_name] then
		return tab.cached_functions[func_name]
	end

	local class_funcs = {}
	for name, class in pairs(tab.classes) do
		if class[func_name] ~= nil and type(class[func_name]) == "function" then
			Log:info("Found function " .. func_name .. " in " .. name)
			table.insert(class_funcs, {
				Function = class[func_name],
				Object = class
			})
		end
	end

	if #class_funcs == 0 then
		Log:warn("[WARNING] No method found with name " .. func_name)
		return function() end;
	end

	local return_func = (function(_, ...) 
		for _, f in pairs(class_funcs) do
			f.Function(f.Object, ...)
		end
	end)

	tab.cached_functions[func_name] = return_func
	return return_func
end)

function ClassWrapper:Wrap(name, instance)
	if self.classes[name] then
		Log:warn("Class wrapper already has wrapped class " .. name)
		return
	end
	self.classes[name] = instance
end

function ClassWrapper:new()
	return setmetatable({
		classes = {},
		cached_functions = {}
	}, ClassWrapper)
end

RegisterCreepClass(ClassWrapper, "ClassWrapper")