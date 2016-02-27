if not Sandbox then
    Sandbox = class({})
end

function Sandbox:Init()
    DEVELOPERS = {[66998815]="A_Dizzle",[86718505]="Noya",[8035838]="Karawasa",[34961594]="WindStrike",[84998953]="Quintinity",[59573794]="Azarak"}
    
    -- Enable Sandbox mode, single player or dev only, after a confirmation message
    CustomGameEventManager:RegisterListener("Sandbox_enable", Dynamic_Wrap(Sandbox, "Enable"))

    -- Resources section
    CustomGameEventManager:RegisterListener("Sandbox_toggle_free_towers", Dynamic_Wrap(Sandbox, "FreeTowers"))
    CustomGameEventManager:RegisterListener("Sandbox_toggle_god_mode", Dynamic_Wrap(Sandbox, "GodMode"))
    CustomGameEventManager:RegisterListener("Sandbox_max_elements", Dynamic_Wrap(Sandbox, "MaxElements"))
    CustomGameEventManager:RegisterListener("Sandbox_set_resources", Dynamic_Wrap(Sandbox, "SetResources")) -- Gold/Lumber/Essence/Lives
    CustomGameEventManager:RegisterListener("Sandbox_set_elements", Dynamic_Wrap(Sandbox, "SetElements")) -- 6 elements

    -- Spawn section
    CustomGameEventManager:RegisterListener("Sandbox_set_wave", Dynamic_Wrap(Sandbox, "SetWave"))
    CustomGameEventManager:RegisterListener("Sandbox_spawn_wave", Dynamic_Wrap(Sandbox, "SpawnWave"))
    CustomGameEventManager:RegisterListener("Sandbox_spawn_boss_wave", Dynamic_Wrap(Sandbox, "SpawnBossWave"))
    CustomGameEventManager:RegisterListener("Sandbox_clear", Dynamic_Wrap(Sandbox, "Clear"))
    CustomGameEventManager:RegisterListener("Sandbox_stop", Dynamic_Wrap(Sandbox, "Stop"))

    -- Pause & End
    CustomGameEventManager:RegisterListener("Sandbox_pause", Dynamic_Wrap(Sandbox, "Pause"))
    CustomGameEventManager:RegisterListener("Sandbox_end", Dynamic_Wrap(Sandbox, "End"))
end

function Sandbox:Enable(event)
    -- body
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

    ShowSandboxCommand(playerID, "Free Towers", state)

    GetPlayerData(playerID).freeTowers = state
    UpdatePlayerSpells(playerID)
end

function Sandbox:GodMode(event)
    local playerID = event.PlayerID
    local state = event.state == 1

    ShowSandboxCommand(playerID, "God Mode", state)

    GetPlayerData(playerID).godMode = state
end

-----------------------------------------------

function ElementTD:GiveLumber(playerID, value)
    value = value or 1
    
    ModifyLumber(playerID, tonumber(value))
    UpdatePlayerSpells(playerID)
end

function ElementTD:GiveEssence(playerID, value)
    value = value or 1
    
    ModifyPureEssence(playerID, tonumber(value))
    UpdatePlayerSpells(playerID)
end

function ElementTD:SpawnWave(playerID, waveNumber)
    waveNumber = waveNumber or GetPlayerData(playerID).nextWave

    ElementTD:StopWaves(playerID)
    SpawnWaveForPlayer(playerID, tonumber(waveNumber))
end

function ElementTD:SetWave(playerID, value)
    value = value or 1

    ElementTD:StopWaves(playerID)
    GetPlayerData(playerID).nextWave = tonumber(value)
    GetPlayerData(playerID).completedWaves = tonumber(value) - 1
end

function ElementTD:SetGold(playerID, value)
    value = value or 1

    local playerData = GetPlayerData(playerID)
    playerData.gold = tonumber(value)
    PlayerResource:SetGold(playerID, tonumber(value), true)
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "etd_update_gold", { gold = playerData.gold } )
end

function ElementTD:SetLives(playerID, value)
    value = tonumber(value) or 50
    local playerData = GetPlayerData(playerID)
    playerData.health = value

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero:HasModifier("modifier_bonus_life") then
        hero:AddNewModifier(hero, nil, "modifier_bonus_life", {})
    end

    hero:CalculateStatBonus()
    hero:SetHealth(value)
   
    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
end

function ElementTD:StopWaves(playerID)
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject

    ClosePortalForSector(playerID, playerData.sector+1, true)

    if wave and wave.spawnTimer then
        Timers:RemoveTimer(wave.spawnTimer)
        wave:SetOnCompletedCallback(function() end)
    end
end

function ElementTD:ClearWave(playerID)
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
    wave:callback()

end

function ElementTD:SetElementLevel(playerID, elem, level)
    level = level or 1
    ModifyElementValue(playerID, elem, level)
end

function ElementTD:Synergy(playerID)
    ModifyElementValue(playerID, "water", 3)
    ModifyElementValue(playerID, "fire", 3)
    ModifyElementValue(playerID, "nature", 3)
    ModifyElementValue(playerID, "earth", 3)
    ModifyElementValue(playerID, "light", 3)
    ModifyElementValue(playerID, "dark", 3)

    UpdateElementsHUD(playerID)
    UpdatePlayerSpells(playerID)
    UpdateSummonerSpells(playerID)
end

function ElementTD:Dev(playerID)
    ElementTD:Synergy(playerID)
    ElementTD:WhosYourDaddy(playerID)
    ElementTD:GiveLumber(playerID, 20)
    ElementTD:GiveEssence(playerID, 10)
    ElementTD:SetGold(playerID, 999999)

    if EXPRESS_MODE then
        ElementTD:ExpressPrecache()
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

function ElementTD.ToggleDebugDamage()
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