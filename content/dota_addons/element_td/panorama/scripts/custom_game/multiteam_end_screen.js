"use strict";

var Credits = $("#Supporters")
var Verify = $("#Verify")
var Spinner = $("#Loading")

var RecordingTimeoutSeconds = 20;
var RecordingTimeout = null;

function UpdateRecordedState(info) {
    if (!info || (info.value !== "recorded" && info.value !== "failed" && info.value !== "timed_out"))
        return;

    // A late confirmation may replace a timeout; stale messages cannot undo success.
    if (Verify.state === "recorded" || Verify.state === info.value ||
        (Verify.state === "failed" && info.value === "timed_out"))
        return;

    Verify.state = info.value;
    if (RecordingTimeout !== null) {
        $.CancelScheduled(RecordingTimeout);
        RecordingTimeout = null;
    }

    var recorded = info.value === "recorded";
    Spinner.AddClass("hide");
    Verify.style['background-color'] = recorded ? "lime" : "red";
    Verify.RemoveClass("scale");
    Verify.RemoveClass("fade");
    $("#stem").SetHasClass("fade", !recorded);
    $("#kick").SetHasClass("fade", !recorded);
    $("#cross").SetHasClass("hide", recorded);
    $("#RecordingTimeoutBadge").SetHasClass("hide", info.value !== "timed_out");
}

function VerifyGame(info) {
    // Events carry their own result and can arrive before the net table replicates.
    UpdateRecordedState(info || CustomNetTables.GetTableValue("gameinfo", "game_recorded"));
}

function ShowRecordedTooltip () {
    if (Verify.state == "recorded")
        $.DispatchEvent("DOTAShowTitleTextTooltip", Verify, "#recorded_title", "#recorded_tooltip");
    else if (Verify.state == "timed_out")
        $.DispatchEvent("DOTAShowTitleTextTooltip", Verify, "#recorded_timeout_title", "#recorded_timeout_tooltip");
    else if (Verify.state == "failed")
        $.DispatchEvent("DOTAShowTitleTextTooltip", Verify, "#recorded_fail_title", "#recorded_fail_tooltip");
}

function ShowEndCredits() {
    var delay = 0.2;
    var delay_per_panel = 0.2;
    var ids = CustomNetTables.GetAllTableValues( "rewards" )
    
    for (var i in ids)
    {
        var steamID64 = ids[i].key
        var tier = ids[i].value["tier"]
        if (tier >= 2) {
            var panel = CreateEndCredit(steamID64)
            panel.SetHasClass( "team_endgame", false );
            
            GameUI.ApplyPanelBorder(panel, steamID64)
            GameUI.SetupAvatarTooltip(panel.FindChildInLayoutFile("AvatarImage"), $.GetContextPanel(), steamID64)
            
            var callback = function( panel )
            {
                return function(){ panel.SetHasClass( "team_endgame", 1 ); }
            }( panel );
            $.Schedule( delay, callback )
            delay += delay_per_panel;
        }
    }
}

function CreateEndCredit(steamid) {
    var playerPanel = $.CreatePanel("Panel", Credits, steamid)
    playerPanel.steamid = steamid
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/end_screen_credits.xml", false, false);
    return playerPanel
}

function UpdateWinString (endScreenVictory, winningTeamId) {
    var winningTeamDetails = Game.GetTeamDetails( winningTeamId );

    endScreenVictory.SetDialogVariable( "winning_team_name", $.Localize( "#" + winningTeamDetails.team_name ) );

    var winString = $.Localize( "#" + winningTeamDetails.team_name );
              
    // Adjust the endscreen to the player name if its a single player team
    var playersOnWinningTeam = Game.GetPlayerIDsOnTeam( winningTeamId )
    if (playersOnWinningTeam.length == 1)
    {
        var playerID = playersOnWinningTeam[0]
        winString = Players.GetPlayerName( playerID )
    }

    if (Game.IsCoop() && playersOnWinningTeam.length>1)
        endScreenVictory.text = $.Localize("#cooperative_victory")
    else
        endScreenVictory.SetDialogVariable( "winning_team_name", winString );

    if ( GameUI.CustomUIConfig().team_colors )
    {
        var teamColor = GameUI.CustomUIConfig().team_colors[ winningTeamId ];
        teamColor = teamColor.replace( ";", "" );
        endScreenVictory.style.color = teamColor + ";";
    }
}

(function()
{
    GameEvents.Subscribe( "etd_game_recorded", VerifyGame );
    CustomNetTables.SubscribeNetTableListener("gameinfo", function(tableName, key, data) {
        if (key === "game_recorded")
            UpdateRecordedState(data);
    });
    // Panorama keeps this deadline even if server simulation stops after the match.
    RecordingTimeout = $.Schedule(RecordingTimeoutSeconds, function() {
        RecordingTimeout = null;
        VerifyGame();
        if (!Verify.state)
            UpdateRecordedState({value: "timed_out"});
    });
    VerifyGame();
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

        if (teamPanel === null)
        {
            $.Msg("Something went wrong, got no team panel for team "+teamInfo.team_id)
            continue
        }

        if (lastPanel !== undefined)
            teamPanel.GetParent().MoveChildAfter( teamPanel, lastPanel );

        lastPanel = teamPanel;
        teamPanel.SetHasClass( "team_endgame", false );

        var playerIDs = Game.GetPlayerIDsOnTeam(teamInfo.team_id)
        for (var i in playerIDs)
        {
            var playerID = playerIDs[i]
            var steamID64 = Game.GetPlayerInfo(playerID).player_steamid
            $.Msg(Game.GetPlayerInfo(playerID))
            GameUI.ApplyPanelBorder(teamPanel, steamID64)
            GameUI.SetupAvatarTooltip(teamPanel.FindChildTraverse("AvatarImage"), $.GetContextPanel(), steamID64)
        }

        var callback = function( panel )
        {
            return function(){ panel.SetHasClass( "team_endgame", 1 ); }
        }( teamPanel );
        $.Schedule( delay, callback )
        delay += delay_per_panel;
    }

    var winningTeamId = Game.GetGameWinner();
    var endScreenVictory = $( "#EndScreenVictory" );
    if ( endScreenVictory )
    {
        var winningTeamDetails = Game.GetTeamDetails( winningTeamId );
        if (winningTeamDetails.team_id == DOTATeam_t.DOTA_TEAM_NEUTRALS)
            endScreenVictory.text = $.Localize("#custom_end_screen_defeat_message")
        else
            UpdateWinString(endScreenVictory, winningTeamId)
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

})();