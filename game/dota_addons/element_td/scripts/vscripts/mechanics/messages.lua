function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function SendLumberMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#008000', ['font-weight']='bold'}, duration=4})
    Sounds:EmitSoundOnClient(pID,"ui.inv_drop_wood")
end

function SendElementalMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#FFFFFF', ['font-weight']='bold'}, duration=4})
    Sounds:EmitSoundOnClient(pID,"General.PingWarning")
end

function SendEssenceMessage( pID, string )
    Notifications:ClearBottom(pID)
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
    ShowMessage(playerID, "Wave "..waveNumber.." in "..breakTime.." seconds", duration)
    
    local element = string.gsub(creepsKV[WAVE_CREEPS[waveNumber]].Ability1, "_armor", "") or "composite"
    local elem_color = rgbToHex(GetElementColor(element))
    local abilityName = creepsKV[WAVE_CREEPS[waveNumber]].Ability2

    Notifications:Top(playerID, {text=firstToUpper(element), style={["margin"]="0px 15px 0px 15px",["font-size"]="50px",color=elem_color}, duration=duration})
    if abilityName and abilityName ~= "" then
        Notifications:Top(playerID, {text="#"..abilityName, style={["margin"]="0px 15px 0px 0px",["font-size"]="50px",color=elem_color}, continue=true, duration=duration})    
        Notifications:Top(playerID, {ability=abilityName, style={width="64px",height="64px"}, continue=true, duration=duration})
    end
end

function ShowWaveSpawnMessage(playerID, waveNumber, duration)
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {text="Wave "..waveNumber.." -", style={["font-size"]="60px"}, duration=duration})

    local element = string.gsub(creepsKV[WAVE_CREEPS[waveNumber]].Ability1, "_armor", "") or "composite"
    local elem_color = rgbToHex(GetElementColor(element))
    local abilityName = creepsKV[WAVE_CREEPS[waveNumber]].Ability2

    Notifications:Top(playerID, {text=firstToUpper(element), style={["margin"]="0px 15px 0px 15px",["font-size"]="60px",color=elem_color}, continue=true, duration=duration})
    if abilityName and abilityName ~= "" then
        Notifications:Top(playerID, {text="#"..abilityName, style={["margin-right"]="15px",["font-size"]="60px",color=elem_color}, continue=true, duration=duration})    
        Notifications:Top(playerID, {ability=abilityName, style={width="64px",height="64px"}, continue=true, duration=duration})
    end
end

function ShowWarnMessage(playerID, msg)
    Notifications:ClearBottom(playerID)
    Notifications:Bottom(playerID, {text=msg, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(playerID))
end