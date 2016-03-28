"use strict";

var Credits = $("#Supporters")
var Verify = $("#Verify")

function VerifyGame() {
    var game_recorded_info = CustomNetTables.GetTableValue("gameinfo", "game_recorded")
    if (game_recorded_info)
    {
        var recorded_state = game_recorded_info.value
        Verify.state = recorded_state
        if (recorded_state == "recorded")
        {
            Verify.style['background-color'] = "lime;"
            Verify.RemoveClass("scale");
            Verify.RemoveClass("fade");
            $.Schedule( 0.3, function() {
                $("#stem").RemoveClass("fade");
                $("#kick").RemoveClass("fade");
            })
            return
        }

        else if (recorded_state == "failed")
        {
            Verify.style['background-color'] = "red;"
            Verify.RemoveClass("scale");
            Verify.RemoveClass("fade");
            $.Schedule( 0.3, function() {
                $("#cross").RemoveClass("hide")
            })
            return
        }
    }

    $.Schedule(0.1, VerifyGame)
}

function ShowRecordedTooltip () {
    if (Verify.state == "recorded")
        $.DispatchEvent("DOTAShowTitleTextTooltip", Verify, "#recorded_title", "#recorded_tooltip");
    else if (Verify.state == "failed")
        $.DispatchEvent("DOTAShowTitleTextTooltip", Verify, "#recorded_fail_title", "#recorded_fail_tooltip");
}

function ShowEndCredits() {
    var delay = 0.2;
    var delay_per_panel = 0.2;
    var ids = CustomNetTables.GetAllTableValues( "rewards" )
    
    for (var i in ids)
    {
        var panel = CreateEndCredit(ids[i].key)
        panel.SetHasClass( "team_endgame", false );
        
        GameUI.ApplyPanelBorder(panel, ids[i].key)
        
        var callback = function( panel )
        {
            return function(){ panel.SetHasClass( "team_endgame", 1 ); }
        }( panel );
        $.Schedule( delay, callback )
        delay += delay_per_panel;
    }
}

function CreateEndCredit(steamid) {
    var playerPanel = $.CreatePanel("Panel", Credits, steamid)
    playerPanel.steamid = steamid
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/end_screen_credits.xml", false, false);
    return playerPanel
}

(function()
{
    GameEvents.Subscribe( "etd_game_recorded", VerifyGame );
    ShowEndCredits()
    if ( ScoreboardUpdater_InitializeScoreboard === null ) { $.Msg( "WARNING: This file requires shared_scoreboard_updater.js to be included." ); }

    var scoreboardConfig =
    {
        "teamXmlName" : "file://{resources}/layout/custom_game/multiteam_end_screen_team.xml",
        "playerXmlName" : "file://{resources}/layout/custom_game/multiteam_end_screen_player.xml",
    };

    var endScoreboardHandle = ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, $( "#TeamsContainer" ) );
    $.GetContextPanel().SetHasClass( "endgame", 1 );

    var teamInfoList = ScoreboardUpdater_GetSortedTeamInfoList( endScoreboardHandle );
    var delay = 0.2;
    var delay_per_panel = 1 / teamInfoList.length;
    var lastPanel
    for ( var teamInfo of teamInfoList )
    {
        var teamPanel = ScoreboardUpdater_GetTeamPanel( endScoreboardHandle, teamInfo.team_id );
        if (lastPanel !== undefined)
            teamPanel.GetParent().MoveChildAfter( teamPanel, lastPanel );

        lastPanel = teamPanel;

        GameUI.ApplyPanelBorder(teamPanel, Game.GetPlayerInfo(0).steamid )

        teamPanel.SetHasClass( "team_endgame", false );
        var callback = function( panel )
        {
            return function(){ panel.SetHasClass( "team_endgame", 1 ); }
        }( teamPanel );
        $.Schedule( delay, callback )
        delay += delay_per_panel;
    }

    var winningTeamId = Game.GetGameWinner();
    var winningTeamDetails = Game.GetTeamDetails( winningTeamId );
    var endScreenVictory = $( "#EndScreenVictory" );
    if ( endScreenVictory )
    {
        if (winningTeamDetails.team_id == DOTATeam_t.DOTA_TEAM_NEUTRALS)
        {
            endScreenVictory.text = $.Localize("custom_end_screen_defeat_message")
        }
        else
        {
            var winString = $.Localize( winningTeamDetails.team_name );
              
            // Adjust the endscreen to the player name if its a single player team
            var playersOnWinningTeam = Game.GetPlayerIDsOnTeam( winningTeamId )
            if (playersOnWinningTeam.length == 1)
            {
                var playerID = playersOnWinningTeam[0]
                winString = Players.GetPlayerName( playerID )
            }

            endScreenVictory.SetDialogVariable( "winning_team_name", winString );

            if ( GameUI.CustomUIConfig().team_colors )
            {
                var teamColor = GameUI.CustomUIConfig().team_colors[ winningTeamId ];
                teamColor = teamColor.replace( ";", "" );
                endScreenVictory.style.color = teamColor + ";";
            }
        }
    }

    var winningTeamLogo = $( "#WinningTeamLogo" );
    if ( winningTeamLogo )
    {
        var logo_xml = GameUI.CustomUIConfig().team_logo_large_xml;
        if ( logo_xml )
        {
          winningTeamLogo.SetAttributeInt( "team_id", winningTeamId );
          winningTeamLogo.BLoadLayout( logo_xml, false, false );
        }
    }

    $.Schedule(0.1, VerifyGame)
})();