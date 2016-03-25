"use strict";

var Root = $.GetContextPanel()
var rankingTopBar = $( '#RankingTopBar' );

// Process and store rankings
function LoadRankings() {
    var rankings = CustomNetTables.GetAllTableValues( "rankings" )
    Root.playerRankings = {}

    for (var playerID in rankings)
    {
        Root.playerRankings[playerID] = rankings[playerID].value;
        $.Msg("Player "+playerID+" info: ",Root.playerRankings[playerID])
    }
}

function CreateRankings()
{
    LoadRankings()

    // Build ranking badge for each player
    for (var playerID in Root.playerRankings) {
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.sector >= 0 && playerRankInfo.sector < 8) {
            var container = $('#sector'+playerRankInfo.sector);
            if (container !== null) {
                if (playerRankInfo.rank != 0) {
                    var parent = $( '#sector'+playerRankInfo.sector )
                    GameUI.CreatePlayerRank(parent, playerRankInfo.percentile, playerRankInfo.rank, "Player_" + playerID + "_Rank" )
                }
            }
        }
    }
}

function HideRank()
{
    $("#RankingPlayer").AddClass("slideOut");
    $("#RankingPlayer").AddClass("hidden");
}

function ShowRank()
{
    $("#RankingPlayer").RemoveClass("slideOut");
    $("#RankingPlayer").RemoveClass("hidden");
}

function ShowRanks()
{
    $.Msg(Root.playerRankings)
    for (var playerID in Root.playerRankings) {
        $.Msg(playerID)
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.rank != 0) {
            $.Msg(playerRankInfo)
            var panel = $("#Player_" + playerID + "_Rank");
            var child = panel.FindChildInLayoutFile( "RankingPlayer" );
            child.RemoveClass("slideOut");
            child.RemoveClass("hidden");
            $.Schedule(10, function() { child.AddClass("hidden"); });
            $.Schedule(11, function() { child.AddClass("slideOut"); });
        }
    }
}

(function () {
    GameEvents.Subscribe( "etd_show_ranks", ShowRanks );
    GameEvents.Subscribe( "etd_create_ranks", CreateRankings );

    // Reconnection
    $.Schedule(0.1, function()
    {
        CreateRankings()
    })
})();