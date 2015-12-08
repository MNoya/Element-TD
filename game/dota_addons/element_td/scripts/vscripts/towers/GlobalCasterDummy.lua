if not GlobalCasterDummy then
    GlobalCasterDummy = {}
end

function GlobalCasterDummy:Init()
    GlobalCasterDummy.dummy = CreateUnitByName("global_caster_dummy", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_GOODGUYS); 

    AddAbility(GlobalCasterDummy.dummy, "dummy_passive_applier");
    AddAbility(GlobalCasterDummy.dummy, "support_tower_modifier_applier");
    AddAbility(GlobalCasterDummy.dummy, "player_movespeed_applier");
    AddAbility(GlobalCasterDummy.dummy, "creep_damage_block_applier");

    Log:info("Global Caster Dummy has been initialized");
end

function GlobalCasterDummy:ApplyModifierToTarget(target, abilityName, modifierName)
    if IsValidEntity(target) and target:IsAlive() then
        local ability = GlobalCasterDummy.dummy:FindAbilityByName(abilityName);
        ability:ApplyDataDrivenModifier(GlobalCasterDummy.dummy, target, modifierName, {}); 
    end
end

function ApplyDummyPassive(target)
    GlobalCasterDummy:ApplyModifierToTarget(target, "dummy_passive_applier", "modifier_dummy_passive");
    target:AddNewModifier(nil, nil, "modifier_invulnerable", {}); 
end

function ApplySupportModifier(tower)
    if IsSupportTower(tower) then
        GlobalCasterDummy:ApplyModifierToTarget(tower, "support_tower_modifier_applier", "modifier_support_tower");
    end
end

function ApplyArmorModifier(target, amount)
    GlobalCasterDummy:ApplyModifierToTarget(target, "creep_damage_block_applier", "modifier_creep_armor_buff");
    target:SetModifierStackCount("modifier_creep_armor_buff", GlobalCasterDummy.dummy:FindAbilityByName("creep_damage_block_applier"), amount);
end