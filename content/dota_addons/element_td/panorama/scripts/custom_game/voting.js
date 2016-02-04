"use strict";

GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );			// Heroes and team score at the top of the HUD
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );	// flyout scoreboard
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );			// Endgame scoreboard

var gamesettings = {};

var votingUI = $( "#Voting" );
var voteResultsUI = $( '#VoteResults' );
var buttonVote = $( "#Vote" );
var buttonResults = $( "#ResultsButton" );
var info = $( '#Info' );
var votingLiveUI = $( '#VotingLive' );

var notVotedUI = $( '#NotVoted' );

var votingLiveNotVoted = $( '#NotVotedPlayers' );
var votingLiveHasVoted = $( '#HasVotedPlayers' );
var playerVotes = {};

var gamemodeDD = $( '#GamemodeDD' );
var difficultyDD = $( '#DifficultyDD' );
var elementDD = $( '#ElementsDD' );
var endlessDD = $( '#EndlessDD' );
var orderDD = $( '#OrderDD' );
var lengthDD = $( '#LengthDD' );

var gamemodeDesc = $( '#GamemodeDesc' );
var difficultyDesc = $( '#DifficultyDesc' );
var elementDesc = $( '#ElementsDesc' );
var endlessDesc = $( '#EndlessDesc' );
var orderDesc = $( '#OrderDesc' );
var lengthDesc = $( '#LengthDesc' );

var timer = $( '#Countdown' );

var gamemodeResults = $( '#GamemodeResult' );
var difficultyResults = $( '#DifficultyResult' );
var elementsResults = $( '#ElementsResult' );
var endlessResults = $( '#EndlessResult' );
var orderResults = $( '#OrderResult' );
var lengthResults = $( '#LengthResult' );

var gameModes = {};
var difficultyModes = {};
var elementModes = {};
var endlessModes = {};
var orderModes = {};
var lengthModes = {};

function Setup()
{
	voteResultsUI.visible = false;
	votingUI.visible = false;
	info.visible = false;
	votingLiveUI.visible = false;
	votingLiveUI.AddClass("hidden");
	UpdateNotVoted();
}

function ToggleVoteDialog( data )
{
	votingUI.visible = data.visible;
	if (Game.GetAllPlayerIDs().length > 1)
	{
		if (votingUI.visible)
		{
			votingLiveUI.visible = true;
			votingLiveUI.RemoveClass("hidden");
		}
		else
		{
			votingLiveUI.AddClass("hidden");
		}
	}

}

function Populate( data )
{
	gamesettings = data;

	//=Gamemodes Dropdown================================================================//
	for (var gm in gamesettings.GameModes)
	{
		var gamemode = gamesettings['GameModes'][gm];
		gameModes[parseInt(gamemode['Index'])] = [ gamemode['Name'], gamemode['Description'], gm ];
	}

	PopulateDropDown(gamemodeDD, gameModes);
	gamemodeDD.SetSelected(0);
	gamemodeDesc.text = $.Localize(gameModes[0][1]); // Default Competitive

	//=Difficulty Dropdown================================================================//
	for (var df in gamesettings.Difficulty)
	{
		var difficulty = gamesettings['Difficulty'][df];
		var desc = Math.round(parseFloat(difficulty.Health) * 100) + "% Creep Health, " + parseInt(difficulty.BaseBounty * 1000)/1000+ " Base Bounty (Express Mode: " + parseInt(difficulty.BaseBountyExpress * 1000)/1000+ " Base Bounty)";
		difficultyModes[parseInt(difficulty['Index'])] = [ difficulty['Name'], desc, df ];
	}

	PopulateDropDown(difficultyDD, difficultyModes);
	difficultyDD.SetSelected(0);
	difficultyDesc.text = $.Localize(difficultyModes[0][1]); // Default Normal

	//=Elements Dropdown================================================================//
	for (var ele in gamesettings.ElementModes)
	{
		var element = gamesettings['ElementModes'][ele];
		elementModes[parseInt(element['Index'])] = [ element['Name'], element['Description'], ele ];
	}

	PopulateDropDown(elementDD, elementModes);
	elementDD.SetSelected(0);
	elementDesc.text = $.Localize(elementModes[0][1]); // Default All Pick

	//=Endless Mode Dropdown
	for (var end in gamesettings.HordeMode)
	{
		var endless = gamesettings['HordeMode'][end];
		endlessModes[parseInt(endless['Index'])] = [ endless['Name'], endless['Description'], end ];
	}

	PopulateDropDown(endlessDD, endlessModes);
	endlessDD.SetSelected(0);
	endlessDesc.text = $.Localize(endlessModes[0][1]); // Default Normal

	//=Order Dropdown================================================================//
	for (var ord in gamesettings.CreepOrder)
	{
		var order = gamesettings['CreepOrder'][ord];
		orderModes[parseInt(order['Index'])] = [ order['Name'], order['Description'], ord ];
	}

	PopulateDropDown(orderDD, orderModes);
	orderDD.SetSelected(0);
	orderDesc.text = $.Localize(orderModes[0][1]); // Default Normal

	//=Length Dropdown================================================================//
	for (var lnth in gamesettings.GameLength)
	{
		var gameLength = gamesettings['GameLength'][lnth];
		var desc = "Start at wave " + gameLength.Wave + " with " + gameLength.Gold + " Gold and " + gameLength.Lumber + " Lumber."
		if (lnth == "Express")
			desc += " This mode has 30 waves and no boss.";
		lengthModes[parseInt(gameLength['Index'])] = [ gameLength['Name'], desc, lnth ];
	}

	PopulateDropDown(lengthDD, lengthModes);
	lengthDD.SetSelected(0);
	lengthDesc.text = $.Localize(lengthModes[0][1]); // Default Classic
}

function PopulateDropDown( DropDown, items )
{
	for (var item in items)
	{
		var label = $.CreatePanel("Label", DropDown, item);
		label.text = $.Localize(items[item][0]);
		DropDown.AddOption(label);
	}
}

function OnDropDownChanged( setting )
{
	if (setting == "gamemode")
		gamemodeDesc.text = $.Localize(gameModes[parseInt(gamemodeDD.GetSelected().id)][1]); 
	else if (setting == "difficulty")
		difficultyDesc.text = $.Localize(difficultyModes[parseInt(difficultyDD.GetSelected().id)][1]);
	else if (setting == "elements")
		elementDesc.text = $.Localize(elementModes[parseInt(elementDD.GetSelected().id)][1]);
	else if (setting == "endless")
		endlessDesc.text = e$.Localize(ndlessModes[parseInt(endlessDD.GetSelected().id)][1]);
	else if (setting == "order")
		orderDesc.text = $.Localize(orderModes[parseInt(orderDD.GetSelected().id)][1]);
	else if (setting == "length")
		lengthDesc.text = $.Localize(lengthModes[parseInt(lengthDD.GetSelected().id)][1]);
}

function UpdateVoteTimer( data )
{
	timer.text = data.time;
}

function UpdateNotVoted()
{
	var players = Game.GetAllPlayerIDs();
	$.Msg("IDs: " + players);
	votingLiveNotVoted.RemoveAndDeleteChildren();
	var position = 0;
	for (var playerID in players) {
		if (!playerVotes[playerID]) {
			var playerData = Game.GetPlayerInfo(parseInt(playerID));
			$.Msg(playerData);
			var notVoted = $.CreatePanel('DOTAAvatarImage', votingLiveNotVoted, '');
			notVoted.AddClass('VotingAvatar');
			notVoted.AddClass('NotVoted');
			notVoted.steamid = playerData.player_steamid;
			position += 1;
		}
	};
	if (position == 0)
	{
		notVotedUI.style['visibility'] = "collapse";
		$.Schedule(3, function(){votingLiveUI.visible = false;});
	}
}

function PlayerVoted( data )
{
	$.Msg(data);
	var playerID = data.playerID;
	var playerData = Game.GetPlayerInfo(parseInt(playerID));
	var vote = $.CreatePanel('Panel', votingLiveHasVoted, '');
	vote.AddClass('VotedPlayer');

	var avatar = $.CreatePanel('DOTAAvatarImage', vote, '');
	avatar.AddClass('VotingAvatar');
	avatar.steamid = playerData.player_steamid;

	var votes = $.CreatePanel('Panel', vote, '');
	votes.AddClass('VotedPlayerVotes');

	var gamemode = $.CreatePanel('Label', votes, '');
	gamemode.AddClass('PlayerVote');
	gamemode.text = $.Localize(data.gamemode.replace(/([a-z])([A-Z])/g, '$1 $2'));

	var difficulty = $.CreatePanel('Label', votes, '');
	difficulty.AddClass('PlayerVote');
	difficulty.text = $.Localize(data.difficulty.replace(/([a-z])([A-Z])/g, '$1 $2'));

	var elements = $.CreatePanel('Label', votes, '');
	elements.AddClass('PlayerVote');
	elements.text = $.Localize(data.elements.replace(/([a-z])([A-Z])/g, '$1 $2'));

	var endless = $.CreatePanel('Label', votes, '');
	endless.AddClass('PlayerVote');
	endless.text = $.Localize(data.endless.replace(/([a-z])([A-Z])/g, '$1 $2'));

	var order = $.CreatePanel('Label', votes, '');
	order.AddClass('PlayerVote');
	order.text = $.Localize(data.order.replace(/([a-z])([A-Z])/g, '$1 $2'));

	var length = $.CreatePanel('Label', votes, '');
	length.AddClass('PlayerVote');
	length.text = $.Localize(data.length.replace(/([a-z])([A-Z])/g, '$1 $2'));

	playerVotes[playerID] = true;
	votingLiveHasVoted.ScrollToBottom();
	UpdateNotVoted();
}

function ConfirmVote()
{
	Game.EmitSound("ui_generic_button_click");

	buttonVote.visible = false;
	info.visible = true;

	gamemodeDD.enabled = false;
	difficultyDD.enabled = false;
	elementDD.enabled = false;
	orderDD.enabled = false;
	lengthDD.enabled = false;

	var data = {};

	data['gamemodeVote'] = gameModes[parseInt(gamemodeDD.GetSelected().id)][2]; 
	data['difficultyVote'] = difficultyModes[parseInt(difficultyDD.GetSelected().id)][2];
	data['elementsVote'] = elementModes[parseInt(elementDD.GetSelected().id)][2];
	data['endlessVote'] = endlessModes[parseInt(endlessDD.GetSelected().id)][2];
	data['orderVote'] = orderModes[parseInt(orderDD.GetSelected().id)][2];
	data['lengthVote'] = lengthModes[parseInt(lengthDD.GetSelected().id)][2];

	var playerID = Players.GetLocalPlayer();

	GameEvents.SendCustomGameEventToServer( "etd_player_voted", { "PlayerID" : playerID, "data" : data } );
}

function ShowVoteResults( data )
{
	votingUI.visible = false;
	voteResultsUI.visible = true;
	votingLiveUI.AddClass("hidden");

	gamemodeResults.text = $.Localize(gamesettings['GameModes'][data.gamemode].Name);
	difficultyResults.text = $.Localize(gamesettings['Difficulty'][data.difficulty].Name);
	elementsResults.text = $.Localize(gamesettings['ElementModes'][data.elements].Name);
	endlessResults.text = $.Localize(gamesettings['HordeMode'][data.endless].Name);
	orderResults.text = $.Localize(gamesettings['CreepOrder'][data.order].Name);
	lengthResults.text = $.Localize(gamesettings['GameLength'][data.length].Name);
}

function ResultsClose()
{
	Game.EmitSound("ui_generic_button_click");
	voteResultsUI.visible = false;
	votingLiveUI.AddClass("hidden");
}

(function () {
	Setup();
	GameEvents.Subscribe( "etd_toggle_vote_dialog", ToggleVoteDialog );
  	GameEvents.Subscribe( "etd_update_vote_timer", UpdateVoteTimer );
  	GameEvents.Subscribe( "etd_populate_vote_table", Populate );
  	GameEvents.Subscribe( "etd_vote_display", PlayerVoted );
  	GameEvents.Subscribe( "etd_vote_results", ShowVoteResults );
})();