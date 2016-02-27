"use strict";

var playerRankings = {};

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

function DisplayRanks( data )
{
    $.Msg("Retrieved Ranks")
    for (var player in data.data)
    {
        playerRankings[data.data[player].playerID] = data.data[player];
    }
    $.Msg(data.data);
    $.Msg(playerRankings);

    // Build ranking badge for each player
    for (var player in playerRankings) {
        var ply = playerRankings[player];
        if (ply.sector >= 0 && ply.sector < 8) {
            var container = $('#sector'+ply.sector);
            if (container !== null) {
                var playerPanel = $.CreatePanel( "Panel", $( '#sector'+ply.sector ), "_player_" + ply.playerID );
                playerPanel.BLoadLayout( "file://{resources}/layout/custom_game/ranking_player.xml", false, false );
                _SetTextSafe( playerPanel, "RankingPercentile", ply.percentile + "%");
                _SetTextSafe( playerPanel, "RankingRank", FormatRank(ply.rank));
                playerPanel.FindChildInLayoutFile( "RankingPlayer" ).AddClass(GetRankImage(ply.percentile)+"_percentile");
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

function FormatRank( rank )
{
    var fixed = 1;
    if (rank > 9999)
        fixed = 0;
    return rank > 999 ? +(rank/1000).toFixed(fixed) + 'k' : rank;
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
    if (data.toggle) {
        for (var player in playerRankings) {
            var ply = playerRankings[player];
            var panel = $('#_player_'+ply.playerID);
            var child = panel.FindChildInLayoutFile( "RankingPlayer" );
            child.RemoveClass("slideOut");
            child.RemoveClass("hidden");
            $.Schedule(10, function() { enabled = true; child.AddClass("hidden"); });
            $.Schedule(11, function() { child.AddClass("slideOut"); });
        }
    }
}

function Setup()
{

}

(function () {
    Setup();
    GameEvents.Subscribe( "etd_show_ranks", ShowRanks );
    GameEvents.Subscribe( "etd_display_ranks", DisplayRanks );
})();
