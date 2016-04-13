"use strict";

var Root = $.GetContextPanel()
var rankingTopBar = $( '#RankingTopBar' );

function CreateRankings()
{
    LoadRankings()
    if (GameUI.Ranks === undefined)
        GameUI.Ranks = {}

    // Build ranking badge for each player
    for (var playerID in Root.playerRankings)
    {
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.sector >= 0 && playerRankInfo.sector < 8) {
            var container = $('#sector'+playerRankInfo.sector);
            if (container !== null && playerRankInfo.rank != 0) {
                GameUI.CreatePlayerRank(container, playerRankInfo.percentile, playerRankInfo.rank, playerID, playerRankInfo.sector)
            }
        }
    }
}

// Process and store rankings
function LoadRankings() {
    var playerIDs =  Game.GetAllPlayerIDs()
    Root.playerRankings = {}

    for (var i in playerIDs)
    {
        var playerID = playerIDs[i]
        var tableValue = CustomNetTables.GetTableValue("rankings", String(playerID))
        if (tableValue !== undefined)
        {
            Root.playerRankings[playerID] = tableValue;
            $.Msg("Player "+playerID+" info: ",Root.playerRankings[playerID])
        }
    }
}

function ShowRanks()
{
    var hideDelay = 10
    var slideDelay = 11
    for (var playerID in Root.playerRankings) {
        var playerRankInfo = Root.playerRankings[playerID];
        if (playerRankInfo.rank != 0) {

            var panel = $("#Player_" + playerID + "_Rank");
            var child = panel.FindChildInLayoutFile( "RankingPlayer" );
            child.RemoveClass("slideOut");
            child.RemoveClass("hidden");

            var hide = function( panel, playerID )
            {
                return function(){ panel.AddClass("hidden"); }
            }( child, playerID );

            var slideOut = function( panel, playerID )
            {
                return function(){ panel.AddClass("slideOut"); }
            }( child, playerID );

            $.Schedule( hideDelay, hide )
            $.Schedule( slideDelay, slideOut )
        }
    }
}

(function () {
    GameEvents.Subscribe( "etd_show_ranks", ShowRanks );
    GameEvents.Subscribe( "etd_create_ranks", CreateRankings );
})();