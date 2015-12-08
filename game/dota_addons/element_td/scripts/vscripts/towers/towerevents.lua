-- wrapper class for KeyValue driven tower events

function TriggerEvent(keys)
    if keys.caster then
        local obj = keys.caster.scriptObject;
        if not obj then
            Log:warn(keys.caster:GetUnitName() .." does not have a script object!");
            return;
        end
        if not obj[keys.Event] then
            Log:warn(obj.className.." does not have an event called "..keys.Event.."!");
            return;
        end
        obj[keys.Event](obj, keys);
    end
end