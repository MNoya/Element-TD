-- wrapper for script objects so that creeps can have multiple abilities

ClassWrapper = {};
ClassWrapper.__index = (function(tab, key)
	if Wrapper[func_name] ~= nil then
		return Wrapper[func_name]
	end

	if tab.cached_functions[func_name] then
		return tab.cached_functions[func_name];
	end

	local class_funcs = {};
	for name, class in pairs(tab.classes) do
		if class[func_name] ~= nil and type(class[func_name]) == "function" then
			table.insert(class_funcs, class[func_name]);
		end
	end

	if #class_funcs == 0 then
		Log:warn("[WARNING] No method found with name " .. func_name);
		return function() end;
	end

	local return_func = (function(...) 
		for _, f in pairs(class_funcs) do
			f(...);
		end
	end)

	tab.cached_functions[func_name] = return_func;
	return return_func;
end)

function ClassWrapper:Wrap(class)
	table.insert(self.classes, class)
end

function ClassWrapper:new()
	return setmetatable({
		classes = {},
		cached_functions = {}
	}, ClassWrapper)
end)

RegisterCreepClass(ClassWrapper, "ClassWrapper")