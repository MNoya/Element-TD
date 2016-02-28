"use strict";

var free_towers = $("#free_towers")
var god_mode = $("#god_mode")

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

function ClearWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_clear_wave", {} );
}

function StopWavePressed() {
    GameEvents.SendCustomGameEventToServer( "sandbox_stop_wave", {} );
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
})();