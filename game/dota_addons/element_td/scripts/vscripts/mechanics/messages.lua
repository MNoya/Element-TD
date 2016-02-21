function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function SendLumberMessage( pID, string )
    Notifications:Bottom(pID, {text=string, style={color='#008000', ['font-weight']='bold'}, duration=4})
    Sounds:EmitSoundOnClient(pID,"ui.inv_drop_wood")
end

function SendElementalMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#FFFFFF', ['font-weight']='bold'}, duration=4})
    Sounds:EmitSoundOnClient(pID,"General.PingWarning")
end

function SendEssenceMessage( pID, string )
    Notifications:Bottom(pID, {text=string, style={color='#FFFFFF', ['font-weight']='bold'}, duration=4})
    Sounds:EmitSoundOnClient(pID,"Rune.Haste")
end

function ShowMessage(playerID, msg, duration)
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {text=msg, style={["font-size"]="70px"}, duration=duration})
end

function ShowElementAcquiredMessage( playerID, element, level )
    local elem_color = rgbToHex(GetElementColor(element))
    Notifications:Bottom(playerID, {text="Acquired "..firstToUpper(element).." level "..tostring(level).."!", style={["font-weight"]="bold",["font-size"]="30px",color=elem_color},duration=5})
end

function ShowWaveBreakTimeMessage(playerID, waveNumber, breakTime, duration)
    Notifications:ClearTop(playerID)

    if waveNumber == 56 then
        ShowFirstBossWaveMessage(playerID)
        return
    end

    Notifications:Top(playerID, {text="Wave "..waveNumber.." in "..breakTime.." seconds", class="WaveBreakTime", duration=duration})
    
    local element = string.gsub(creepsKV[WAVE_CREEPS[waveNumber]].Ability1, "_armor", "") or "composite"
    local elem_color = rgbToHex(GetElementColor(element))
    local abilityName = creepsKV[WAVE_CREEPS[waveNumber]].Ability2

    Notifications:Top(playerID, {text=firstToUpper(element), style={["margin"]="-15px 15px 0px 15px",["font-size"]="30px",color=elem_color, ["font-weight"]="bold"}, duration=duration})
    if abilityName and abilityName ~= "" then
        Notifications:Top(playerID, {text="#"..abilityName, style={["margin"]="-15px 15px 0px 0px",["font-size"]="30px",color=elem_color, ["font-weight"]="bold"}, continue=true, duration=duration})    
        Notifications:Top(playerID, {ability=abilityName, style={["border-radius"]="48px", border="2px solid black", width="48px", height="48px", ["margin"]="-13px 0px 0px 0px"}, continue=true, duration=duration})
    end
end

function ShowFirstBossWaveMessage( playerID )
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {text="Boss Wave in 60 seconds", class="WaveBreakTime", duration=10})
    local elem_color = rgbToHex(GetElementColor("composite"))

    Notifications:Top(playerID, {text=firstToUpper("composite"), style={["margin"]="-15px 15px 0px 15px",["font-size"]="30px",color=elem_color, ["font-weight"]="bold"}, duration=10})
    Notifications:Top(playerID, {image="file://{images}/spellicons/osfrog.png", style={width="48px", height="48px", ["margin"]="-5px 0px 0px 0px"}, duration=10})
end

function ShowWaveSpawnMessage(playerID, waveNumber, duration)
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {text="Wave "..waveNumber.." -", class="WaveMessage", duration=duration})

    local element = string.gsub(creepsKV[WAVE_CREEPS[waveNumber]].Ability1, "_armor", "") or "composite"
    local elem_color = rgbToHex(GetElementColor(element))
    local abilityName = creepsKV[WAVE_CREEPS[waveNumber]].Ability2

    Notifications:Top(playerID, {text=firstToUpper(element), style={["margin"]="0px 15px 0px 15px",color=elem_color}, class="WaveMessage", continue=true, duration=duration})
    if abilityName and abilityName ~= "" then
        if abilityName ~= "creep_ability_boss" then
            Notifications:Top(playerID, {text="#"..abilityName, style={["margin-right"]="15px",color=elem_color}, class="WaveMessage", continue=true, duration=duration})    
            Notifications:Top(playerID, {ability=abilityName, style={["border-radius"]="64px", border="2px solid black"; width="60px", height="60px"}, continue=true, duration=duration})
        else
            Notifications:Top(playerID, {image="file://{images}/spellicons/osfrog.png", style={width="48px", height="48px", ["margin"]="-13px 0px 0px 0px"}, continue=true, duration=duration})
        end
    end
end

function ShowBossWaveMessage(playerID, waveNumber)
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {image="file://{images}/spellicons/osfrog.png", class="IcefrogFaceNoSpace", duration=5})
    Notifications:Top(playerID, {text="Boss Wave "..waveNumber, class="BossWaveMessage", continue=true, duration=5})
    Notifications:Top(playerID, {image="file://{images}/spellicons/osfrog.png", class="IcefrogFaceNoSpace", continue=true, duration=5})    
end

function ShowWarnMessage(playerID, msg, duration)
    duration = duration or 2
    Notifications:ClearBottom(playerID)
    Notifications:Bottom(playerID, {text=msg, style={color='#E62020'}, duration=duration})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(playerID))
end