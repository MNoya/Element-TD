"use strict";

var TIMER_REFRESH = 0.05;

var waveinfo = $( "#WaveInfo" );
var button = $( '#StartWave' );
var currentWave = $( '#CurrentWaveLabel' );
var nextWave = $( '#NextWaveLabel' );
var currentAbility1 = $( "#CurrentAbility1" ); //Element
var currentAbility2 = $( "#CurrentAbility2" ); //Skill
var currentAbility3 = $( "#CurrentAbility3" ); //Skill 2 (Challenge mode)
var nextAbility1 = $( "#NextAbility1" );
var nextAbility2 = $( "#NextAbility2" );
var nextAbility3 = $( "#NextAbility3" );
var countdown = $( '#Countdown' );
var clock = $( '#Clock' );

var timerDuration = 0;
var startTime = 0;

var m_QueryUnit = -1;

var abilityModeSetup = false; //have we updated the gui with ability mode changes?

function Setup() {
	waveinfo.visible = false;
	button.visible = false;
	currentAbility1.abilityname = "";
	currentAbility2.abilityname = "";
	currentAbility3.abilityname = "";
	nextAbility1.abilityname = "";
	nextAbility2.abilityname = "";
	nextAbility3.abilityname = "";
	currentAbility1.visible = false;
	currentAbility2.visible = false;
	currentAbility3.visible = false;
	nextAbility1.visible = false;
	nextAbility2.visible = false;
	nextAbility3.visible = false;
	currentWave.text = "";
	nextWave.text = "";
}

function UpdateWaveInfo( table ) {
	clock.text = "";
	
	if (!abilityModeSetup) {
		abilityModeSetup = true;
		if (CustomNetTables.GetTableValue("gameinfo", "abilitiesMode").value === "Challenge") {
			waveinfo.style["width"] = "388px";
			button.style["margin-right"] = "410px";
		}
	}

	$.Msg(table.nextWave," ",table.nextAbility1 || ""," ",table.nextAbility2 || "", " ",table.nextAbility3 || "");
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

	if (nextAbility3.abilityname != "") {
		currentAbility3.abilityname = nextAbility3.abilityname;
		currentAbility3.visible = true;
	}
	else
		currentAbility3.visible = false;

	// Stop
	if (table.nextWave == "end")
	{
		nextWave.text = "";
		nextAbility1.abilityname = "";
		nextAbility1.visible = false;
		nextAbility2.abilityname = "";
		nextAbility2.visible = false;
		nextAbility3.abilityname = "";
		nextAbility3.visible = false;
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

	if (table.nextAbility3 === undefined || table.nextAbility3 == "") {
		nextAbility3.abilityname = "";
		nextAbility3.visible = false;
	}
	else {
		nextAbility3.abilityname = table.nextAbility3;
		nextAbility3.visible = true;
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

var waveSpawnTime
var clockRunning
var fastThreshold = 30

// Starts an increasing clock timer to show how much time has passed since the wave finished spawning
function StartWaveClock(msg) {
	clockRunning = true
	fastThreshold = parseInt(msg.threshold)
	waveSpawnTime = Game.GetGameTime()
	UpdateWaveClock()
}

function UpdateWaveClock() {
    var time = Game.GetGameTime() - waveSpawnTime;

    if (time <= fastThreshold) {
    	if (time <= fastThreshold - fastThreshold/6) {
    		clock.RemoveClass("Slow")
    		clock.RemoveClass("Close")
    		clock.AddClass("Fast")
    	} else {
    		clock.RemoveClass("Fast")
    		clock.RemoveClass("Slow")
    		clock.AddClass("Close")
    	}
    } else {
    	clock.AddClass("Slow")
    	clock.RemoveClass("Fast")
    	clock.RemoveClass("Close")
    }

    clock.text = FormatClockTime(time);
    if (clockRunning)
    	$.Schedule(TIMER_REFRESH, UpdateWaveClock)
}

function FormatClockTime(time) {
	var seconds = time.toFixed(0)
    var minutes = Math.floor(seconds / 60)
    var text = minutes+":"

    seconds = seconds % 60

    // Add leading zero
    if (seconds < 10)
    	text = text+"0"

    return String(text+seconds)
}

function UpdateWaveTimer( table ) {
	waveinfo.visible = true;
	clockRunning = false;
	clock.text = "";

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
  	GameEvents.Subscribe( "etd_start_wave_clock", StartWaveClock );
})();