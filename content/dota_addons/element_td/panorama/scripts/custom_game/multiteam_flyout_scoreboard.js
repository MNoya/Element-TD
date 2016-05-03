"use strict";

var g_ScoreboardHandle = null;
var nextPressActivatesScoreboard = true;

function SetFlyoutScoreboardVisible(bVisible)
{
	// Gotta skip the release button event
	if ( bVisible )
	{
		if (nextPressActivatesScoreboard)
		{
			// set values to true, and next press will deactivate
			ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, true );
			$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", true );			
			nextPressActivatesScoreboard = false
		}
		else
		{
			ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, false );
			$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", false );	
			nextPressActivatesScoreboard = true
		}
	}
}

function RefreshScoreboard()
{
	ScoreboardUpdater_SetScoreboardActive( g_ScoreboardHandle, !nextPressActivatesScoreboard );
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
	
	SetFlyoutScoreboardVisible(false); //Default hidden
	
	GameUI.CustomUIConfig().ToggleScoreboard = function() {
		SetFlyoutScoreboardVisible(true)
	}

    if (Game.IsCoop())
    {
        var root = $.GetContextPanel()
        HideAllTraverse(root, "ScoreContainer")
        //HideAllTraverse(root, "NetworthContainer")
        //HideAllTraverse(root, "TeamNetworthLabel")
        HideAllTraverse(root, "TeamScoreLabel")
        HideAllTraverse(root, "LivesContainer")
        HideAllTraverse(root, "TeamLives")
        HideAllTraverse(root, "KillsContainer")
        HideAllTraverse(root, "KillsRemaining")
        $.Schedule(2, function(){SetFlyoutScoreboardVisible(true)})
    }

	GameEvents.Subscribe( "etd_update_scoreboard", RefreshScoreboard );
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
})();

function HideAllTraverse(panel, id) {
    var nChild = panel.GetChildCount()
    for (var i = 0; i < nChild; i++) {
        var child = panel.GetChild(i)
        var n = child.GetChildCount()
        if (child.id == id)
            child.AddClass("Hide")

        if (n > 0)
            HideAllTraverse(child, id)
    };
}
