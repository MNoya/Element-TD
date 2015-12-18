function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function SendLumberMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#008000', ['font-weight']='bold'}, duration=4})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function SendElementalMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#FFFFFF', ['font-weight']='bold'}, duration=4})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function SendEssenceMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#FFFFFF', ['font-weight']='bold'}, duration=4})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end