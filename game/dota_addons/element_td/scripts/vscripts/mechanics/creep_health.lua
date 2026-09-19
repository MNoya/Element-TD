-- Gameplay health stays in Lua once it outgrows the engine health bar. All
-- damage and spells use these helpers; the engine value is only a projection.
-- Cap the health-bar representation at the signed int32 maximum (2147483647).
CREEP_HEALTH_BAR_CAP = 2147483647

function GetCreepHealth(creep)
    if not creep:IsAlive() then return 0 end
    return creep.virtualHealth or creep:GetHealth()
end

function GetCreepMaxHealth(creep)
    return creep.virtualMaxHealth or creep:GetMaxHealth()
end

function GetCreepHealthPercent(creep)
    return GetCreepHealth(creep) / GetCreepMaxHealth(creep) * 100
end

function SetCreepHealth(creep, health)
    -- Match the integer health setters used before health compression.
    health = math.max(0, math.min(GetCreepMaxHealth(creep), math.floor(health)))
    if creep.virtualMaxHealth then
        creep.virtualHealth = health
        local displayed = math.ceil(health / creep.virtualMaxHealth * creep:GetMaxHealth())
        -- Positive gameplay health must always have a positive engine health bar.
        creep:SetHealth(math.min(creep:GetMaxHealth(), math.max(health > 0 and 1 or 0, displayed)))
    else
        creep:SetHealth(health)
    end
end

function SetCreepMaxHealth(creep, maxHealth)
    local health = GetCreepHealth(creep)
    maxHealth = math.max(1, math.floor(maxHealth))
    local engineMaxHealth = math.min(maxHealth, CREEP_HEALTH_BAR_CAP)
    creep.virtualMaxHealth = maxHealth > engineMaxHealth and maxHealth or nil
    creep.virtualHealth = nil
    creep:SetMaxHealth(engineMaxHealth)
    creep:SetBaseMaxHealth(engineMaxHealth)
    SetCreepHealth(creep, health)
end

function InitializeCreepHealth(creep, maxHealth)
    SetCreepMaxHealth(creep, maxHealth)
    SetCreepHealth(creep, GetCreepMaxHealth(creep))
end

function HealCreep(creep, amount, ability)
    if not creep:IsAlive() then return end
    if creep.virtualMaxHealth then
        SetCreepHealth(creep, GetCreepHealth(creep) + amount)
    else
        creep:Heal(amount, ability)
    end
end

-- Preserve the two pre-9e9473cf curves, including their different first waves.
-- Capture the result on the creep at spawn; never derive it from a live counter
-- while dealing damage or resurrecting a creep.
function GetBossMaxHealth(baseHealth, difficultyMultiplier, bossWave, coop)
    local growth = coop and math.pow(1.2, bossWave - 1) or math.pow(1.3, bossWave)
    return baseHealth * difficultyMultiplier * growth
end
