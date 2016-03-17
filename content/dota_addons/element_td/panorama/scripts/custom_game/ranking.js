"use strict";

var Root = $.GetContextPanel()
var rankingTopBar = $( '#RankingTopBar' );
var enabled = false;

function _SetTextSafe( panel, childName, textValue )
{
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    childPanel.text = textValue;
}

function DisplayRanks()
{
    $.Msg("Diplaying Ranks")

    // Process and store rankings
    var rankings = CustomNetTables.GetAllTableValues( "rankings" )
    Root.playerRankings = {}
    for (var playerID in rankings)
    {
        Root.playerRankings[playerID] = rankings[playerID].value;
        $.Msg("Player "+playerID+" info: ",Root.playerRankings[playerID])
    }

    // Build ranking badge for each player
    for (var playerID in Root.playerRankings) {
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.sector >= 0 && playerRankInfo.sector < 8) {
            var container = $('#sector'+playerRankInfo.sector);
            if (container !== null) {
                if (playerRankInfo.rank != 0) {
                    var playerPanel = $.CreatePanel( "Panel", $( '#sector'+playerRankInfo.sector ), "Player_" + playerID + "_Rank" );
                    playerPanel.BLoadLayout( "file://{resources}/layout/custom_game/ranking_player.xml", false, false );
                    _SetTextSafe( playerPanel, "RankingPercentile", GameUI.FormatPercentile(playerRankInfo.percentile));
                    _SetTextSafe( playerPanel, "RankingRank", "#" + GameUI.FormatRank(playerRankInfo.rank));
                    playerPanel.FindChildInLayoutFile( "RankingPlayer" ).AddClass(GetRankImage(playerRankInfo.rank,playerRankInfo.percentile)+"_percentile");
                }
            }
        }
    }
}

function GetRankImage( rank, percentile )
{
    if (percentile <= 20)
        return "0";
    else if (percentile <= 40)
        return "20";
    else if (percentile <= 60)
        return "40";
    else if (percentile <= 80)
        return "60";
    else
        return "80";
}

function HideRank()
{
    if (enabled) {
        $("#RankingPlayer").AddClass("slideOut");
        $("#RankingPlayer").AddClass("hidden");
    }
}

function ShowRank()
{
    if (enabled) {
        $("#RankingPlayer").RemoveClass("slideOut");
        $("#RankingPlayer").RemoveClass("hidden");
    }
}

function ShowRanks( data )
{
    if (data.toggle) 
    {
        for (var playerID in Root.playerRankings) {
            var playerRankInfo = Root.playerRankings[playerID];
            if (playerRankInfo.rank != 0) {
                var panel = $("#Player_" + playerID + "_Rank");
                var child = panel.FindChildInLayoutFile( "RankingPlayer" );
                child.RemoveClass("slideOut");
                child.RemoveClass("hidden");
                $.Schedule(10, function() { enabled = true; child.AddClass("hidden"); });
                $.Schedule(11, function() { child.AddClass("slideOut"); });
            }
        }
    }
}

(function () {
    GameEvents.Subscribe( "etd_show_ranks", ShowRanks );
    GameEvents.Subscribe( "etd_display_ranks", DisplayRanks );
})();
