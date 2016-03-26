"use strict";

var Root = $.GetContextPanel()
var rankingTopBar = $( '#RankingTopBar' );

function CreateRankings()
{
    LoadRankings()
    if (GameUI.Ranks === undefined)
        GameUI.Ranks = {}

    // Build ranking badge for each player
    for (var playerID in Root.playerRankings) {
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.sector >= 0 && playerRankInfo.sector < 8) {
            var container = $('#sector'+playerRankInfo.sector);
            if (container !== null) {
                if (playerRankInfo.rank != 0) {
                    var parent = $( '#sector'+playerRankInfo.sector )
                    GameUI.CreatePlayerRank(parent, playerRankInfo.percentile, playerRankInfo.rank, playerID )
                }
            }
        }
    }
}

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

function ShowRanks()
{
    for (var playerID in Root.playerRankings) {
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
})();