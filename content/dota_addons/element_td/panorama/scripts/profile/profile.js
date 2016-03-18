"use strict";

var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var friendsPanel = $("#RightPanel")
var friendsLoaded = false;

function GetPlayerFriends(playerID) {
    $.Msg("Getting player friends data...")
    var playerInfo = Game.GetPlayerInfo(playerID)
    var steamID = playerInfo.player_steamid

    var delay = 0
    var delay_per_panel = 0.1;
    $.AsyncWebRequest( friendsURL+steamID, { type: 'GET', 
        success: function( data ) {
            friendsLoaded = true;
            var info = JSON.parse(data);
            var players_info = info["players"]
            
            // Sort by rank
            players_info.sort(function(a, b) {
                return parseInt(a.rank) - parseInt(b.rank);
            });

            for (var i in players_info)
            {
                var callback = function( data )
                {
                    return function(){ CreateFriendPanel(data) }
                }( players_info[i] );

                $.Schedule( delay, callback )
                delay += delay_per_panel;
            }
        }
    })
}

function CreateFriendPanel(data) {
    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = GameUI.FormatScore(data.score)
    playerPanel.rank = GameUI.FormatRank(data.rank)
    playerPanel.percentile = GameUI.FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);
}

function ToggleProfile() {
    $("#MyProfile").ToggleClass("Hide")

    if (!friendsLoaded)
         GetPlayerFriends(Game.GetLocalPlayerID())
}

function MakeButtonVisible() {
    $("#MyProfile").SetHasClass("Hide", GameUI.PlayerHasProfile(Game.GetLocalPlayerID()))
}

(function () {
    $.Schedule(1, MakeButtonVisible)
})();