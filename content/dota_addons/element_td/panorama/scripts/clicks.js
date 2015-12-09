"use strict";

// Handle Right Button events
function OnRightButtonPressed()
{
    var iPlayerID = Players.GetLocalPlayer();
    var mainSelected = Players.GetLocalPlayerPortraitUnit(); 
    var mainSelectedName = Entities.GetUnitName( mainSelected )
    var cursor = GameUI.GetCursorPosition();
    var mouseEntities = GameUI.FindScreenEntities( cursor );
    mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex != mainSelected; } )
    
    var pressedShift = GameUI.IsShiftDown();

    // Builder Right Click
    if ( IsBuilder( mainSelected ) )
    {
        // Cancel BH
        if (!pressedShift) SendCancelCommand();
    }

    return false;
}

// Handle Left Button events
function OnLeftButtonPressed() {

    return false
}


function IsBuilder( entIndex ) {
    return (CustomNetTables.GetTableValue( "builders", entIndex.toString()))
}

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
    var CONSUME_EVENT = true;
    var CONTINUE_PROCESSING_EVENT = false;
    var LEFT_CLICK = (arg === 0)
    var RIGHT_CLICK = (arg === 1)

    if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
        return CONTINUE_PROCESSING_EVENT;

    var mainSelected = Players.GetLocalPlayerPortraitUnit()

    if ( eventName === "pressed" || eventName === "doublepressed")
    {
        // Builder Clicks
        if (IsBuilder(mainSelected))
            if (LEFT_CLICK) 
                return (state == "active") ? SendBuildCommand() : OnLeftButtonPressed();
            else if (RIGHT_CLICK) 
                return OnRightButtonPressed();

        if (LEFT_CLICK) 
            return OnLeftButtonPressed();
        else if (RIGHT_CLICK) 
            return OnRightButtonPressed(); 
        
    }
    return CONTINUE_PROCESSING_EVENT;
} );