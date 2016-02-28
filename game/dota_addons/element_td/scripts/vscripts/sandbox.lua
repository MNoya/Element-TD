if not Sandbox then
    Sandbox = class({})
end

function Sandbox:Init()
    DEVELOPERS = {[66998815]="A_Dizzle",[86718505]="Noya",[8035838]="Karawasa",[34961594]="WindStrike",[84998953]="Quintinity",[59573794]="Azarak"}
    
    -- Enable Sandbox mode, single player or dev only, after a confirmation message
    CustomGameEventManager:RegisterListener("sandbox_enable", Dynamic_Wrap(Sandbox, "Enable"))

    -- Resources section
    CustomGameEventManager:RegisterListener("sandbox_toggle_free_towers", Dynamic_Wrap(Sandbox, "FreeTowers"))
    CustomGameEventManager:RegisterListener("sandbox_toggle_god_mode", Dynamic_Wrap(Sandbox, "GodMode"))
    CustomGameEventManager:RegisterListener("sandbox_max_elements", Dynamic_Wrap(Sandbox, "MaxElements"))
    CustomGameEventManager:RegisterListener("sandbox_full_life", Dynamic_Wrap(Sandbox, "FullLife"))
    CustomGameEventManager:RegisterListener("sandbox_set_resources", Dynamic_Wrap(Sandbox, "SetResources")) -- Gold/Lumber/Essence
    CustomGameEventManager:RegisterListener("sandbox_set_element", Dynamic_Wrap(Sandbox, "SetElement")) -- 6 elements

    -- Spawn section
    CustomGameEventManager:RegisterListener("sandbox_set_wave", Dynamic_Wrap(Sandbox, "SetWave"))
    CustomGameEventManager:RegisterListener("sandbox_spawn_wave", Dynamic_Wrap(Sandbox, "SpawnWave"))
    CustomGameEventManager:RegisterListener("sandbox_spawn_boss_wave", Dynamic_Wrap(Sandbox, "SpawnBossWave"))
    CustomGameEventManager:RegisterListener("sandbox_clear_wave", Dynamic_Wrap(Sandbox, "ClearWave"))
    CustomGameEventManager:RegisterListener("sandbox_stop_wave", Dynamic_Wrap(Sandbox, "StopWave"))

    -- Game
    CustomGameEventManager:RegisterListener("sandbox_speed_up", Dynamic_Wrap(Sandbox, "SpeedUp"))
    CustomGameEventManager:RegisterListener("sandbox_pause", Dynamic_Wrap(Sandbox, "Pause"))
    CustomGameEventManager:RegisterListener("sandbox_end", Dynamic_Wrap(Sandbox, "End"))
end

-- The sandbox enable button will only be visible in the test version, or on single player/developer presence.
function Sandbox:CheckPlayer(playerID)
    if not IsDedicatedServer() or PlayerResource:GetPlayerCount() == 1 or Sandbox:IsDeveloper(playerID) then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "sandbox_mode_visible", {})
    end
end

function Sandbox:Enable(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)

    if not playerData.sandBoxEnabled then
        playerData.sandBoxEnabled = true
        playerData.cheated = true
    else
        return
    end

    SendToServerConsole("sv_cheats 1")
    ElementTD:PrecacheAll()
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {
        text = {text = "#sandbox_enable", wave = waveNumber}, 
        class = "WaveMessage", 
        duration = duration
    })
end

function Sandbox:GetPlayerData(playerID)
    if not Sandbox.players[playerID] then
        Sandbox.players[playerID] = {}
    end
    return Sandbox.players[playerID]
end

function Sandbox:IsDeveloper(playerID)
    return DEVELOPERS[PlayerResource:GetSteamAccountID(playerID)] ~= nil
end

function Sandbox:FreeTowers(event)
    local playerID = event.PlayerID
    local state = event.state == 1
    local playerData = GetPlayerData(playerID)

    ShowSandboxToggleCommand(playerID, "#sandbox_free_towers", state)

    -- Set to 10k gold
    if state == true then
        SetCustomGold(playerID, math.max(11000, PlayerResource:GetGold(playerID)))
    end

    playerData.freeTowers = state
    UpdatePlayerSpells(playerID)
end

function Sandbox:GodMode(event)
    local playerID = event.PlayerID
    local state = event.state == 1

    ShowSandboxToggleCommand(playerID, "#sandbox_god_mode", state)

    GetPlayerData(playerID).godMode = state
end

function Sandbox:MaxElements(event)
    local playerID = event.PlayerID

    local playerData = GetPlayerData(playerID)
    for k,v in pairs (playerData.elements) do
        playerData.elements[k] = 3
    end

    UpdatePlayerSpells(playerID)
    UpdateElementsHUD(playerID)
    UpdateSummonerSpells(playerID)
    for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end
    UpdateScoreboard(playerID)

    ShowSandboxCommand(playerID, "Max Elements")
end

function Sandbox:FullLife(event)
    local playerID = event.PlayerID
    local value = 50
    local playerData = GetPlayerData(playerID)
    playerData.health = value

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero:HasModifier("modifier_bonus_life") then
        hero:AddNewModifier(hero, nil, "modifier_bonus_life", {})
    end

    hero:CalculateStatBonus()
    hero:SetHealth(value)
   
    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )

    ShowSandboxCommand(playerID, "Full Life")
end

function Sandbox:SetResources(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)
    local gold = tonumber(event.gold) or playerData.gold
    local lumber = tonumber(event.lumber) or playerData.lumber
    local essence = tonumber(event.essence) or playerData.pureEssence

    SetCustomGold(playerID, gold)
    SetCustomLumber(playerID, lumber)
    SetCustomEssence(playerID, essence)
end

function Sandbox:SetElement(event)
    local playerID = event.PlayerID
    local element = event.element
    local level = tonumber(event.level)
    local playerData = GetPlayerData(playerID)

    playerData.elements[element] = level

    UpdatePlayerSpells(playerID)
    UpdateElementsHUD(playerID)
    UpdateSummonerSpells(playerID)
    for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end
    UpdateScoreboard(playerID)

    ShowElementLevel(playerID, element, level)
end

function Sandbox:SetWave(event)
    local playerID = event.PlayerID
    local waveNumber = event.wave

    Sandbox:StopWave(playerID)
    GetPlayerData(playerID).nextWave = tonumber(waveNumber)
    GetPlayerData(playerID).completedWaves = tonumber(waveNumber) - 1
end

function Sandbox:SpawnWave(event)
    local playerID = event.PlayerID
    local waveNumber = event.wave
    waveNumber = waveNumber or GetPlayerData(playerID).nextWave

    Sandbox:StopWave(playerID)
    SpawnWaveForPlayer(playerID, tonumber(waveNumber))
end

function Sandbox:StopWave(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject

    ClosePortalForSector(playerID, playerData.sector+1, true)

    if wave and wave.spawnTimer then
        Timers:RemoveTimer(wave.spawnTimer)
        wave:SetOnCompletedCallback(function() end)
    end
end

function Sandbox:ClearWave(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject
    local creeps = wave.creeps

    if creeps then
        for k,v in pairs(creeps) do
            local unit = EntIndexToHScript(v)
            if IsValidEntity(unit) then
                unit:Kill(nil, hero)
            end
        end
    end

    local elemental = playerData.elementalUnit
    if elemental then elemental:Kill(nil, hero) end

    -- Complete the wave
    wave.endSpawnTime = GameRules:GetGameTime()
    wave:callback()
end

function Sandbox:SpeedUp(event)
    local fast = event.state == 1
    if fast then
        SendToServerConsole("host_timescale 3")
    else
        SendToServerConsole("host_timescale 1")
    end
end

function Sandbox:Pause(event)
    local pause = event.state == 1
    PauseGame(pause)
end

function Sandbox:End(event)
    local playerID = event.PlayerID

    GameRules:SetGameWinner(PlayerResource:GetTeam(playerID))
end

-- Forces a fast precache of everything to be able to build anything ASAP
function ElementTD:PrecacheAll()
    if EXPRESS_MODE then
        ElementTD:ExpressPrecache(5)
        ElementTD:PrecacheWave(2)
        ElementTD:PrecacheWave(5)
        ElementTD:PrecacheWave(11)
    else
        ElementTD:PrecacheWave(4)
        ElementTD:PrecacheWave(9)
        ElementTD:PrecacheWave(14)
        ElementTD:PrecacheWave(24)
    end
end

--------------------------------------------------------------------------

function ElementTD:ToggleDebugDamage()
    GameRules.DebugDamage = not GameRules.DebugDamage
    if GameRules.DebugDamage then
        Say(nil,"Debug Damage <font color='#ff0000'>ON</font>", false)
    else
        Say(nil,"Debug Damage <font color='#ff0000'>OFF</font>", false)
    end
end

function ElementTD:WhereIsTheWave(playerID)
    local playerData = GetPlayerData(playerID)
    local waveObject = playerData.waveObject

    if waveObject and waveObject.waveNumber and waveObject.waveNumber > 0 then
        print("=====================================")
        print("PlayerID: "..playerID.." - Wave: "..waveObject.waveNumber)
        print("Wave Started At: "..waveObject.startTime.." EndTime: "..waveObject.endTime) -- endTime should be 0
        print("-------------------------------------")
        print("Remaining: "..waveObject.creepsRemaining,"Leaks: "..waveObject.leaks,"Kills: "..waveObject.kills)
        for k,v in pairs(waveObject.creeps) do
            local creep = EntIndexToHScript(v)
            if IsValidEntity(creep) then
                print("["..k.."]","Alive:"..tostring(creep:IsAlive()))
                DebugDrawCircle(creep:GetAbsOrigin(), Vector(255,0,0), 1, 16, true, 5)
            else
                print("["..k.."]","Entity Not Valid!")
            end
        end
    end
end

if not DEVELOPERS then Sandbox:Init() end