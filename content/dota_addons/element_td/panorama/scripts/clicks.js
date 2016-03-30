"use strict";

function GetMouseTarget()
{
    var mouseEntities = GameUI.FindScreenEntities( GameUI.GetCursorPosition() )
    var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() )

    for ( var e of mouseEntities )
    {
        if ( !e.accurateCollision )
            continue
        return e.entityIndex
    }

    for ( var e of mouseEntities )
    {
        return e.entityIndex
    }

    return 0
}


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
    return (CustomNetTables.GetTableValue( "builders", entIndex.toString()) || Entities.GetUnitName(entIndex) == "npc_dota_hero_wisp")
}

function IsCustomBuilding( entityIndex ){
    var ability_building = Entities.GetAbilityByName( entityIndex, "ability_building")
    var ability_tower = Entities.GetAbilityByName( entityIndex, "ability_tower")
    if (ability_building != -1){
        //$.Msg(entityIndex+" IsCustomBuilding - Ability Index: "+ ability_building)
        return true
    }
    else if (ability_tower != -1){
        //$.Msg(entityIndex+" IsCustomBuilding Tower - Ability Index: "+ ability_tower)
        return true
    }
    else
        return false
}

var cameraDistance = 1500
GameUI.SetCameraDistance( cameraDistance )

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
    var CONSUME_EVENT = true;
    var CONTINUE_PROCESSING_EVENT = false;
    var LEFT_CLICK = (arg === 0)
    var RIGHT_CLICK = (arg === 1)
    var MID_CLICK = (arg === 2)

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
        else if (RIGHT_CLICK && IsCustomBuilding(mainSelected))
            if (GetMouseTarget() == 0)
                return CONSUME_EVENT;
    }

    if ( eventName === "wheeled" )
    {
        arg == 1 ? cameraDistance -= 10 : cameraDistance += 10;
        GameUI.SetCameraDistance( cameraDistance )
        return CONSUME_EVENT;  
    }

    return CONTINUE_PROCESSING_EVENT;
} );