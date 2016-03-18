"use strict";

var statsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=stats&id='
var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var friendsPanel = $("#FriendsContainer")
var friendsLoaded = false;
var friendsRank = 0

function GetStats() {
    $.Msg("Getting stats data...")
    var steamID = 66998815 //test value

    $.AsyncWebRequest( statsURL+steamID, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var player_info = info["player"]

            for (var i in player_info)
            {
                $.Msg(i, " ", player_info[i])
            }
        }
    })
}

function GetPlayerFriends(playerID) {
    $.Msg("Getting player friends data...")
    var steamID = GameUI.GetLocalPlayerSteamID()

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
    friendsRank++

    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = GameUI.FormatScore(data.score)
    playerPanel.friendRank = friendsRank
    playerPanel.rank = GameUI.FormatRank(data.rank)
    //playerPanel.percentile = GameUI.FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);

    var steamID = GameUI.GetLocalPlayerSteamID()
    if (steamID64 == steamID)
        playerPanel.AddClass("local")
}

function ToggleProfile() {
    $("#MyProfile").ToggleClass("Hide")

    GetStats()

    if (!friendsLoaded)
         GetPlayerFriends(Game.GetLocalPlayerID())
}

function MakeButtonVisible() {
    var bShowProfile = GameUI.PlayerHasProfile(Game.GetLocalPlayerID())
    $("#MyProfileToggleContainer").SetHasClass("Hide", !bShowProfile)
}

(function () {
    //$.Schedule(0.1, MakeButtonVisible)
})();