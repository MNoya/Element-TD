"use strict";

function EmitClientSound(msg)
{
    if (msg.sound){
        Game.EmitSound(msg.sound); 
    }
}

(function(){
    GameEvents.Subscribe( "emit_client_sound", EmitClientSound);
})()