"use strict";

var free_towers = $("#free_towers")
var god_mode = $("#god_mode")
var speed_up = $("#speed_up")
var pause = $("#pause")
var max_level = 3;
var min_level = 0;

function ToggleFreeTowers() {
    GameEvents.SendCustomGameEventToServer( "sandbox_toggle_free_towers", { "state": free_towers.checked } );
}

function ToggleGodMode() {
    GameEvents.SendCustomGameEventToServer( "sandbox_toggle_god_mode", { "state": god_mode.checked } );
}

function MaxElementsPressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_max_elements", {} );
}

function FullLifePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_full_life", {} );
}

function GetResources()
{
    var table = {};
    table['gold'] = $('#Gold').text;
    table['lumber'] = $('#Lumber').text;
    table['essence'] = $('#Essence').text;

    return table;
}

function UpdateResources()
{
    GameEvents.SendCustomGameEventToServer( "sandbox_set_resources", GetResources() );
}

function UpdateElements(msg) {
    $("#light_level").text = msg.light
    $("#dark_level").text = msg.dark
    $("#water_level").text = msg.water
    $("#fire_level").text = msg.fire
    $("#nature_level").text = msg.nature
    $("#earth_level").text = msg.earth
}

function ValueChange(name, amount)
{
    var panel = $("#"+name+"_level");
    if (panel !== null){
        var current_level = parseInt(panel.text)
        var new_level = current_level + parseInt(amount)
        if (new_level <= max_level && new_level >= min_level)
            panel.text = new_level
        else
            if (new_level < min_level)
                panel.text = min_level
            else
                panel.text = max_level
    }

    GameEvents.SendCustomGameEventToServer( "sandbox_set_element", {element : name, level : panel.text} );
}

function ClearWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_clear_wave", {} );
}

function StopWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_stop_wave", {} );
}

function Pause() {
    GameEvents.SendCustomGameEventToServer( "sandbox_pause", {"state": pause.checked} );
}

function SpeedUp() {
    GameEvents.SendCustomGameEventToServer( "sandbox_speed_up", {"state": speed_up.checked} );
}

function EndGame() {
    GameEvents.SendCustomGameEventToServer( "sandbox_end", {} );
}

function HoverEnableSandbox() {
    $("#New").AddClass('hide')
    if ($("#SandboxPanel").BHasClass('hide'))
        $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_mode_enable", "#sandbox_mode_tooltip");
    else
        $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_enable", "#sandbox_mode_on");
}

function EnableSandbox() {
    GameEvents.SendCustomGameEventToServer( "sandbox_enable", {} );
    $("#SandboxPanel").RemoveClass('hide')
    $("#CloseButton").AddClass('hide')
    $("#EnableSandboxText").style['color'] = 'gold;'
    $.DispatchEvent("DOTAShowTitleTextTooltip", $("#SandboxEnableButton"), "#sandbox_enable", "#sandbox_mode_on");
}

function Dismiss() {
    $("#SandboxEnablePanel").AddClass('hide')
}

function SandboxMakeVisible() {
    $("#SandboxEnablePanel").RemoveClass('hide')
}

(function () {
    GameEvents.Subscribe( "sandbox_mode_visible", SandboxMakeVisible);
    GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();