-- wrapper class for KeyValue driven creep events

function TriggerEvent(keys)
    CREEP_SCRIPT_OBJECTS[keys.caster:entindex()][keys.Event](CREEP_SCRIPT_OBJECTS[keys.caster:entindex()], keys);
end