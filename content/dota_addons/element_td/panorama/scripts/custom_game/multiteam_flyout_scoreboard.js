"use strict";

var g_ScoreboardHandle = null;
var bActive = false

function SetFlyoutScoreboardVisible( bVisible )
{
	$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", bVisible );
	bActive = bVisible
	if ( bVisible )
	{
		ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );
		RefreshFlyoutScoreboard();
	}
	else
	{
		ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, false );
	}
}

function RefreshFlyoutScoreboard()
{
	$.Schedule(0.2, function(){
		ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );
		if (bActive)
			RefreshFlyoutScoreboard();
	});
}

(function()
{
	if ( ScoreboardUpdater_InitializeScoreboard === null ) { $.Msg( "WARNING: This file requires shared_scoreboard_updater.js to be included." ); }

	var scoreboardConfig =
	{
		"teamXmlName" : "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_team.xml",
		"playerXmlName" : "file://{resources}/layout/custom_game/multiteam_flyout_scoreboard_player.xml",
	};
	g_ScoreboardHandle = ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, $( "#TeamsContainer" ) );
	
	SetFlyoutScoreboardVisible( false );
	
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
})();
