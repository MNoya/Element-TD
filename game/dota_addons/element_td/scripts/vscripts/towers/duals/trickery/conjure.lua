trickery_tower_conjure = class({})

LinkLuaModifier("modifier_clone", "towers/duals/trickery/modifier_clone", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_conjure_prevent_cloning", "towers/duals/trickery/modifier_conjure_prevent_cloning", LUA_MODIFIER_MOTION_NONE)

function trickery_tower_conjure:OnSpellStart()
    local caster = self:GetCaster() --The tower
    local target = self:GetCursorTarget()
    local playerID = caster:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)

    -- Prevent the targeted tower from getting cloned again for a duration
    target:AddNewModifier(caster, self, "modifier_conjure_prevent_cloning", {duration=60})

    self.tower:EmitSound("Trickery.Cast")
    
    local sector = playerID + 1
    local clonePos = BuildingHelper:FindClosestEmptyPositionNearby( target:GetAbsOrigin(), target.construction_size, 2000 )
    if not clonePos then
        Log:error("No Valid Position for Clone!")
        return
    end

    -- Create Tower Building
    local clone = BuildingHelper:PlaceBuilding(PlayerResource:GetPlayer(playerID), target.class, clonePos, 2, 0, 0)

    --set some variables
    clone.class = target.class
    clone.element = GetUnitKeyValue(clone.class, "Element")
    clone.damageType = GetUnitKeyValue(clone.class, "DamageType")
    clone.isClone = true
    clone.ability = self

    -- New pedestal if one wasn't created already
    if not clone.prop then
        local basicName = clone.damageType.."_tower"
        local pedestalName = GetUnitKeyValue(basicName, "PedestalModel")
        local prop = BuildingHelper:CreatePedestalForBuilding(clone, basicName, GetGroundPosition(clone:GetAbsOrigin(), nil), pedestalName)
    end

    -- keep well & blacksmith buffs
    local fire_up = target:FindModifierByName("modifier_fire_up")
    if fire_up then
        clone:AddNewModifier(fire_up:GetCaster(), fire_up:GetAbility(), "modifier_fire_up", {duration = fire_up:GetDuration()})
    end

    local spring_forward = target:FindModifierByName("modifier_spring_forward")
    if spring_forward then
        clone:AddNewModifier(spring_forward:GetCaster(), spring_forward:GetAbility(), "modifier_spring_forward", {duration = spring_forward:GetDuration()})
    end

    --color
    clone:SetRenderColor(0, 148, 255)
    local children = clone:GetChildren()
    for k,v in pairs(children) do
        if v:GetClassname() == "dota_item_wearable" then
            v:SetRenderColor(0, 148, 255)
        end
    end

    -- create a script object for this tower
    local scriptClassName = GetUnitKeyValue(clone.class, "ScriptClass")
    if not scriptClassName then scriptClassName = "BasicTower" end

    -- Add abilities
    AddAbility(clone, "ability_building")
    if GetUnitKeyValue(clone:GetUnitName(), "DisableTurning") then
        clone:AddNewModifier(clone, nil, "modifier_disable_turning", {})
    end
    AddAbility(clone, "sell_tower_0")
    
    if TOWER_CLASSES[scriptClassName] then
        local scriptObject = TOWER_CLASSES[scriptClassName](clone, clone.class)
        clone.scriptClass = scriptClassName
        clone.scriptObject = scriptObject
        clone.scriptObject:OnCreated()
    else
        Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. clone.class)
    end

    AddAbility(clone, clone.damageType .. "_passive")
    if GetUnitKeyValue(clone.class, "AOE_Full") and GetUnitKeyValue(clone.class, "AOE_Half") then
        AddAbility(clone, "splash_damage_orb")
    end

    -- Add the tower to the player data
    playerData.towers[clone:GetEntityIndex()] = target.class
    playerData.clones[clone.class] = playerData.clones[clone.class] or {} --init clone table of this tower name
    playerData.clones[clone.class][clone:GetEntityIndex()] = target.class -- add this clone
    UpdateScoreboard(playerID)

    -- apply the clone modifier to the clone
    clone:AddNewModifier(clone, nil, "modifier_no_health_bar", {})
    clone:AddNewModifier(caster, self, "modifier_clone", {duration=self.clone_duration})
    clone:AddNewModifier(caster, self, "modifier_kill", {duration=self.clone_duration})
    self.clones[clone:entindex()] = 1 --Clones for this particular tower ability

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/illusion_created.vpcf", PATTACH_ABSORIGIN, clone)
    ParticleManager:SetParticleControl(particle, 0, clone:GetAbsOrigin() + Vector(0, 0, 64))
end

--------------------------------------------------------------

function trickery_tower_conjure:CastFilterResultTarget(target)
    local result = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, self:GetCaster():GetTeamNumber())
    
    if result ~= UF_SUCCESS then
        return result
    end
    
    local bClone = target:HasModifier("modifier_clone")
    local bPreventCloning = target:HasModifier("modifier_conjure_prevent_cloning")
    local bSupportTower = target:HasModifier("modifier_support_tower")

    if bSupportTower or bClone or bPreventCloning then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function trickery_tower_conjure:GetCustomCastErrorTarget(target)
    local bClone = target:HasModifier("modifier_clone")
    local bPreventCloning = target:HasModifier("modifier_conjure_prevent_cloning")
    local bSupportTower = target:HasModifier("modifier_support_tower")

    if bSupportTower then
        return "#etd_error_support_tower"
    elseif bPreventCloning then
        return "#etd_error_recently_cloned"
    elseif bClone then
        return "#etd_error_cloned_tower"
    end

    return ""
end