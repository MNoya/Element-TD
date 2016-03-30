"use strict";

var TIMER_REFRESH = 0.05;

var waveinfo = $( "#WaveInfo" );
var button = $( '#StartWave' );
var currentWave = $( '#CurrentWaveLabel' );
var nextWave = $( '#NextWaveLabel' );
var currentAbility1 = $( "#CurrentAbility1" ); //Element
var currentAbility2 = $( "#CurrentAbility2" ); //Skill
var nextAbility1 = $( "#NextAbility1" );
var nextAbility2 = $( "#NextAbility2" );
var countdown = $( '#Countdown' );

var timerDuration = 0;
var startTime = 0;

var m_QueryUnit = -1;

function Setup() {
	waveinfo.visible = false;
	button.visible = false;
	currentAbility1.abilityname = "";
	currentAbility2.abilityname = "";
	nextAbility1.abilityname = "";
	nextAbility2.abilityname = "";
	currentAbility1.visible = false;
	currentAbility2.visible = false;
	nextAbility1.visible = false;
	nextAbility2.visible = false;
	currentWave.text = "";
	nextWave.text = "";
}

function UpdateWaveInfo( table ) {
	$.Msg(table.nextWave," ",table.nextAbility1 || ""," ",table.nextAbility2 || "");
	currentWave.text = nextWave.text;

	if (nextAbility1.abilityname != "") {
		currentAbility1.abilityname = nextAbility1.abilityname;
		currentAbility1.visible = true;
	}
	else
		currentAbility1.visible = false;

	if (nextAbility2.abilityname != "") {
		currentAbility2.abilityname = nextAbility2.abilityname;
		currentAbility2.visible = true;
	}
	else
		currentAbility2.visible = false;

	// Stop
	if (table.nextWave == "end")
	{
		nextWave.text = "";
		nextAbility1.abilityname = "";
		nextAbility1.visible = false;
		nextAbility2.abilityname = "";
		nextAbility2.visible = false;
		return
	}

	if (table.nextWave != "")
		nextWave.text = "Wave " + table.nextWave;
	else
		nextWave.text = "";

	if (table.bossWave !== undefined)
		nextWave.text = "Boss Wave " + table.bossWave;

	if (table.nextAbility1 === undefined || table.nextAbility1 == "") {
		nextAbility1.abilityname = "";
		nextAbility1.visible = false;
	}
	else{
		nextAbility1.abilityname = table.nextAbility1;
		nextAbility1.visible = true;
	}

	if (nextAbility1.abilityname != "")
		nextAbility1.visible = true;
	if (table.nextAbility2 === undefined || table.nextAbility2 == "") {
		nextAbility2.abilityname = "";
		nextAbility2.visible = false;
	}
	else {
		nextAbility2.abilityname = table.nextAbility2;
		nextAbility2.visible = true;
	}
}

function UpdateTimer() {
	var time = Game.GetGameTime() - startTime;
	var remaining = Math.ceil(timerDuration - time);

	if (remaining >= 0)
		countdown.text = remaining;

	if (time < timerDuration)
		$.Schedule(TIMER_REFRESH, function(){UpdateTimer();});
	else {
		countdown.text = 0;
		button.visible = false;
		$.Schedule(1, function(){countdown.text = "";});
	}
}

function UpdateWaveTimer( table ) {
	waveinfo.visible = true;
	button.visible = table.button;
	timerDuration = table.time;
	startTime = Game.GetGameTime();
	UpdateTimer();
}

function OnStartNextWave( table ) {
	$.Msg('OnStartNextWave');
	Game.EmitSound("ui_generic_button_click");
	button.visible = false;
	// End timer
	timerDuration = 0;
	startTime = Game.GetGameTime();
	var PlayerID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer( "next_wave", { "PlayerID" : PlayerID } );
}

function FadeIn() {
	button.AddClass("FadeIn");
}

function FadeOut() {
	button.RemoveClass("FadeIn");
}

// Ability tooltip stuff
function AbilityShowTooltip( ability ) {
	var abilityButton = $( '#' + ability );
	var abilityName = abilityButton.abilityname;
	// If you don't have an entity, you can still show a tooltip that doesn't account for the entity
	//$.DispatchEvent( "DOTAShowAbilityTooltip", abilityButton, abilityName );
	
	// If you have an entity index, this will let the tooltip show the correct level / upgrade information
	$.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", abilityButton, abilityName, m_QueryUnit );
}

function AbilityHideTooltip( ability ) {
	var abilityButton = $( '#' + ability );
	$.DispatchEvent( "DOTAHideAbilityTooltip", abilityButton );
}

(function () {
	if ( CustomNetTables.GetTableValue("gameinfo", "voting_finished") === undefined)
		Setup();
  	else
  		GameEvents.SendCustomGameEventToServer( "request_wave_info", {} );

  	GameEvents.Subscribe( "etd_update_wave_timer", UpdateWaveTimer );
  	GameEvents.Subscribe( "etd_next_wave_info", UpdateWaveInfo );
})();